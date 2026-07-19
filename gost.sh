#!/usr/bin/env bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Default: direct GitHub access (no mirror prefix).
# Overridden by select_server_location when Iran mode is chosen.
GH_MIRRORS=("")

# Check Root User
if [[ "$EUID" -ne '0' ]]; then
    echo -e "${RED}Error: You must run this script as root (use sudo).${NC}"
    exit 1
fi

show_banner() {
    echo -e "${MAGENTA}"
    cat <<'BANNER'
 __        ___ _     _    ____  ___  ____ _____
 \ \      / (_) | __| |  / ___|/ _ \/ ___|_   _|
  \ \ /\ / /| | |/ _` | | |  _| | | \___ \ | |
   \ V  V / | | | (_| | | |_| | |_| |___) || |
    \_/\_/  |_|_|\__,_|  \____|\___/|____/ |_|
BANNER
    echo -e "${NC}"
    echo -e "${CYAN}=============================================${NC}"
    echo -e "${GREEN}    Wild GOST - Easy Tunnel Management       ${NC}"
    echo -e "${CYAN}  https://github.com/infowild/Wild-Gost      ${NC}"
    echo -e "${CYAN}=============================================${NC}"
}

check_dependencies() {
    if ! command -v curl &> /dev/null; then
        echo -e "${YELLOW}curl is not installed. Installing...${NC}"
        if command -v apt-get &> /dev/null; then
            apt-get update && apt-get install -y curl
        elif command -v yum &> /dev/null; then
            yum install -y curl
        fi
    fi
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}jq is not installed. Installing...${NC}"
        if command -v apt-get &> /dev/null; then
            apt-get update && apt-get install -y jq
        elif command -v yum &> /dev/null; then
            yum install -y jq
        fi
    fi
}

create_systemd_service() {
    cat <<EOF > /etc/systemd/system/gost.service
[Unit]
Description=GO Simple Tunnel
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/gost -C /etc/gost/config.json
Restart=always
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable gost
    systemctl start gost
}

select_server_location() {
    echo -e "${CYAN}Where is this server located?${NC}"
    echo -e "1) Outside Iran (direct GitHub access)"
    echo -e "2) Iran (download through a GitHub mirror/proxy)"
    read -p "Your choice (1-2) [default: 1]: " loc_choice
    if [ "$loc_choice" = "2" ]; then
        # Mirror prefixes are tried in order until one works
        GH_MIRRORS=("https://gh-proxy.com/" "https://ghproxy.net/" "https://mirror.ghproxy.com/" "")
        echo -e "${YELLOW}Iran mode enabled: GitHub mirrors will be used for downloads.${NC}"
    else
        GH_MIRRORS=("")
    fi
}

# Fetch a URL, trying each mirror prefix until one succeeds
fetch_url() {
    local url="$1" output="$2" prefix
    for prefix in "${GH_MIRRORS[@]}"; do
        if [ -n "$output" ]; then
            curl -fL --connect-timeout 15 "${prefix}${url}" -o "$output" 2>/dev/null && return 0
        else
            curl -fsSL --connect-timeout 15 "${prefix}${url}" 2>/dev/null && return 0
        fi
    done
    return 1
}

install_gost() {
    check_dependencies
    select_server_location
    echo -e "${CYAN}Fetching the latest GOST release info...${NC}"
    release_json=$(fetch_url "https://api.github.com/repos/go-gost/gost/releases/latest")
    latest_ver=$(echo "$release_json" | jq -r .tag_name 2>/dev/null)
    if [ -z "$latest_ver" ] || [ "$latest_ver" = "null" ]; then
        echo -e "${RED}Failed to fetch the latest version from GitHub.${NC}"
        echo -e "${YELLOW}If you are on an Iranian server, re-run and choose option 2 (Iran) for mirror downloads.${NC}"
        return 1
    fi
    echo -e "${GREEN}Latest version found: $latest_ver${NC}"

    arch=$(uname -m)
    cpu_arch=""
    case $arch in
        x86_64) cpu_arch="amd64" ;;
        aarch64|arm64) cpu_arch="arm64" ;;
        i686|i386) cpu_arch="386" ;;
        armv7*) cpu_arch="armv7" ;;
        armv6*) cpu_arch="armv6" ;;
        armv5*) cpu_arch="armv5" ;;
        riscv64) cpu_arch="riscv64" ;;
        *) echo -e "${RED}Unsupported CPU architecture: $arch${NC}"; return 1 ;;
    esac

    # Exact-match the release asset (avoids amd64 accidentally matching amd64v3, etc.)
    download_url=$(echo "$release_json" | jq -r --arg cpu "$cpu_arch" \
        '.assets[] | select(.name | test("_linux_" + $cpu + "\\.tar\\.gz$")) | .browser_download_url' | head -n 1)

    if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then
        echo -e "${RED}No suitable download found for your architecture.${NC}"
        return 1
    fi

    echo -e "${CYAN}Downloading: $download_url${NC}"
    mkdir -p /tmp/gost_install
    if ! fetch_url "$download_url" /tmp/gost_install/gost.tar.gz; then
        echo -e "${RED}Download failed. Check your network access to GitHub (or its mirrors).${NC}"
        rm -rf /tmp/gost_install
        return 1
    fi
    if ! tar -xzf /tmp/gost_install/gost.tar.gz -C /tmp/gost_install; then
        echo -e "${RED}Failed to extract the downloaded archive.${NC}"
        rm -rf /tmp/gost_install
        return 1
    fi
    mv /tmp/gost_install/gost /usr/local/bin/gost
    chmod +x /usr/local/bin/gost
    rm -rf /tmp/gost_install

    # Init config
    mkdir -p /etc/gost
    if [ ! -f /etc/gost/config.json ]; then
        echo '{"services":[],"chains":[],"log":{"level":"info"}}' > /etc/gost/config.json
    fi

    # Setup service
    create_systemd_service

    # Install/refresh the management script in the system path.
    # $0 is not a regular file when run via `bash <(curl ...)`, so fall back
    # to downloading a fresh copy from the repository (self-update).
    if [ -f "$0" ] && [ "$0" != "/usr/local/bin/gost-manage.sh" ]; then
        cp "$0" /usr/local/bin/gost-manage.sh
    else
        fetch_url "https://raw.githubusercontent.com/infowild/Wild-Gost/master/gost.sh" /usr/local/bin/gost-manage.sh \
            || echo -e "${YELLOW}Warning: could not refresh the management script from GitHub.${NC}"
    fi
    chmod +x /usr/local/bin/gost-manage.sh

    # Create the wrapper script 'wild'
    cat <<'EOF' > /usr/local/bin/wild
#!/usr/bin/env bash
if [ "$1" = "gost" ]; then
    /usr/local/bin/gost-manage.sh
else
    echo "Unknown command. Did you mean 'wild gost'?"
fi
EOF
    chmod +x /usr/local/bin/wild

    echo -e "${GREEN}GOST installed successfully! Version: $latest_ver${NC}"
    echo -e "${GREEN}From now on you can open this menu anytime by typing ${YELLOW}wild gost${GREEN}.${NC}"
    /usr/local/bin/gost -V
}

add_tunnel() {
    if [ ! -f /usr/local/bin/gost ]; then
        echo -e "${RED}GOST is not installed. Choose option 1 to install it first.${NC}"
        return 1
    fi

    echo -e "${CYAN}--- Add New Tunnel ---${NC}"
    read -p "Listening port (e.g. 1080): " port
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo -e "${RED}Invalid port!${NC}"
        return 1
    fi

    port_exists=$(jq --arg port ":$port" '.services[]? | select(.addr == $port) | .name' /etc/gost/config.json)
    if [ -n "$port_exists" ]; then
        echo -e "${RED}This port is already used in the configuration!${NC}"
        return 1
    fi

    echo -e "Select the inbound protocol type:"
    echo -e "1) SOCKS5"
    echo -e "2) HTTP"
    echo -e "3) Relay Server"
    echo -e "4) TCP Port Forwarding"
    echo -e "5) UDP Port Forwarding"
    echo -e "6) Shadowsocks (SS)"
    read -p "Your choice (1-6): " proto_choice

    local name="service-$port"
    local handler_type=""
    local listener_type="tcp"
    local has_auth="n"
    local username=""
    local password=""
    local forward_target=""
    local ss_method="aes-256-gcm"
    local ss_password=""
    local has_upstream="n"
    local upstream_node=""
    local chain_name=""

    case $proto_choice in
        1)
            handler_type="socks5"
            read -p "Enable authentication (username/password)? (y/n): " has_auth
            ;;
        2)
            handler_type="http"
            read -p "Enable authentication (username/password)? (y/n): " has_auth
            ;;
        3)
            handler_type="relay"
            read -p "Enable authentication (username/password)? (y/n): " has_auth
            ;;
        4)
            handler_type="tcp"
            read -p "Forward target address (e.g. 127.0.0.1:80 or google.com:443): " forward_target
            if [ -z "$forward_target" ]; then
                echo -e "${RED}Target address cannot be empty!${NC}"
                return 1
            fi
            ;;
        5)
            handler_type="udp"
            listener_type="udp"
            read -p "Forward target address (e.g. 127.0.0.1:53): " forward_target
            if [ -z "$forward_target" ]; then
                echo -e "${RED}Target address cannot be empty!${NC}"
                return 1
            fi
            ;;
        6)
            handler_type="ss"
            read -p "Shadowsocks encryption method (default aes-256-gcm): " ss_method
            [ -z "$ss_method" ] && ss_method="aes-256-gcm"
            read -p "Shadowsocks password: " ss_password
            if [ -z "$ss_password" ]; then
                echo -e "${RED}Password cannot be empty!${NC}"
                return 1
            fi
            ;;
        *)
            echo -e "${RED}Invalid choice!${NC}"
            return 1
            ;;
    esac

    if [ "$has_auth" = "y" ] || [ "$has_auth" = "Y" ]; then
        read -p "Username: " username
        read -p "Password: " password
        if [ -z "$username" ] || [ -z "$password" ]; then
            echo -e "${RED}Username and password cannot be empty!${NC}"
            return 1
        fi
    fi

    if [ "$proto_choice" -eq 1 ] || [ "$proto_choice" -eq 2 ] || [ "$proto_choice" -eq 3 ]; then
        read -p "Route traffic through an upstream proxy chain? (y/n): " has_upstream
        if [ "$has_upstream" = "y" ] || [ "$has_upstream" = "Y" ]; then
            read -p "Upstream proxy address (e.g. socks5://1.2.3.4:1080 or relay+tls://5.6.7.8:8443): " upstream_node
            if [ -z "$upstream_node" ]; then
                echo -e "${RED}Upstream proxy address cannot be empty!${NC}"
                return 1
            fi
            chain_name="chain-$port"
        fi
    fi

    local new_service_json=""

    if [ "$handler_type" = "socks5" ] || [ "$handler_type" = "http" ] || [ "$handler_type" = "relay" ]; then
        if [ -n "$username" ] && [ -n "$password" ]; then
            new_service_json=$(jq -n \
                --arg name "$name" \
                --arg addr ":$port" \
                --arg handler "$handler_type" \
                --arg listener "$listener_type" \
                --arg user "$username" \
                --arg pass "$password" \
                '{name: $name, addr: $addr, handler: {type: $handler, auth: {username: $user, password: $pass}}, listener: {type: $listener}}')
        else
            new_service_json=$(jq -n \
                --arg name "$name" \
                --arg addr ":$port" \
                --arg handler "$handler_type" \
                --arg listener "$listener_type" \
                '{name: $name, addr: $addr, handler: {type: $handler}, listener: {type: $listener}}')
        fi

        if [ -n "$chain_name" ]; then
            new_service_json=$(echo "$new_service_json" | jq --arg chain "$chain_name" '.handler += {chain: $chain}')
        fi

    elif [ "$handler_type" = "tcp" ] || [ "$handler_type" = "udp" ]; then
        new_service_json=$(jq -n \
            --arg name "$name" \
            --arg addr ":$port" \
            --arg port "$port" \
            --arg handler "$handler_type" \
            --arg listener "$listener_type" \
            --arg target "$forward_target" \
            '{name: $name, addr: $addr, handler: {type: $handler}, listener: {type: $listener}, forwarder: {nodes: [{name: ("target-" + $port), addr: $target}]}}')

    elif [ "$handler_type" = "ss" ]; then
        new_service_json=$(jq -n \
            --arg name "$name" \
            --arg addr ":$port" \
            --arg method "$ss_method" \
            --arg password "$ss_password" \
            --arg listener "$listener_type" \
            '{name: $name, addr: $addr, handler: {type: "ss", metadata: {method: $method, password: $password}}, listener: {type: $listener}}')
    fi

    jq --argjson new_svc "$new_service_json" '.services += [$new_svc]' /etc/gost/config.json > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json /etc/gost/config.json

    if [ -n "$chain_name" ] && [ -n "$upstream_node" ]; then
        local new_chain_json=$(jq -n \
            --arg name "$chain_name" \
            --arg node_addr "$upstream_node" \
            '{name: $name, hops: [{name: "hop-0", nodes: [{name: "node-0", addr: $node_addr}]}]}')

        jq --argjson new_ch "$new_chain_json" '.chains += [$new_ch]' /etc/gost/config.json > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json /etc/gost/config.json
    fi

    systemctl restart gost
    echo -e "${GREEN}Tunnel added and started successfully!${NC}"
}

delete_tunnel() {
    if [ ! -f /usr/local/bin/gost ]; then
        echo -e "${RED}GOST is not installed.${NC}"
        return 1
    fi

    echo -e "${CYAN}--- Remove Tunnel ---${NC}"
    services_count=$(jq '.services | length' /etc/gost/config.json)
    if [ "$services_count" -eq 0 ]; then
        echo -e "${YELLOW}No tunnels are configured.${NC}"
        return 0
    fi

    echo -e "Select the tunnel to remove:"
    for ((i=0; i<services_count; i++)); do
        name=$(jq -r ".services[$i].name" /etc/gost/config.json)
        addr=$(jq -r ".services[$i].addr" /etc/gost/config.json)
        type=$(jq -r ".services[$i].handler.type" /etc/gost/config.json)
        echo -e "$((i+1)) ) Name: $name | Port: $addr | Type: $type"
    done

    read -p "Tunnel number (1-$services_count): " choice
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$services_count" ]; then
        echo -e "${RED}Invalid number!${NC}"
        return 1
    fi

    index=$((choice-1))
    service_name=$(jq -r ".services[$index].name" /etc/gost/config.json)
    associated_chain=$(jq -r ".services[$index].handler.chain // empty" /etc/gost/config.json)

    jq --arg name "$service_name" '.services |= map(select(.name != $name))' /etc/gost/config.json > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json /etc/gost/config.json

    if [ -n "$associated_chain" ]; then
        jq --arg chain "$associated_chain" '.chains |= map(select(.name != $chain))' /etc/gost/config.json > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json /etc/gost/config.json
    fi

    systemctl restart gost
    echo -e "${GREEN}Tunnel $service_name removed successfully.${NC}"
}

list_tunnels() {
    if [ ! -f /usr/local/bin/gost ]; then
        echo -e "${RED}GOST is not installed.${NC}"
        return 1
    fi

    echo -e "${CYAN}--- Active Tunnels ---${NC}"
    services_count=$(jq '.services | length' /etc/gost/config.json)
    if [ "$services_count" -eq 0 ]; then
        echo -e "${YELLOW}No tunnels are registered.${NC}"
        return 0
    fi

    echo -e "-------------------------------------------------------------------------------"
    printf "%-5s | %-20s | %-12s | %-12s | %-20s\n" "No." "Service Name" "Listen Port" "Protocol" "Upstream Proxy"
    echo -e "-------------------------------------------------------------------------------"
    for ((i=0; i<services_count; i++)); do
        name=$(jq -r ".services[$i].name" /etc/gost/config.json)
        addr=$(jq -r ".services[$i].addr" /etc/gost/config.json)
        type=$(jq -r ".services[$i].handler.type" /etc/gost/config.json)
        chain=$(jq -r ".services[$i].handler.chain // \"none\"" /etc/gost/config.json)
        if [ "$chain" != "none" ]; then
            chain_addr=$(jq -r --arg ch "$chain" '.chains[]? | select(.name == $ch) | .hops[0].nodes[0].addr' /etc/gost/config.json)
            chain="$chain_addr"
        fi
        printf "%-5s | %-20s | %-12s | %-12s | %-20s\n" "$((i+1))" "$name" "$addr" "$type" "$chain"
    done
    echo -e "-------------------------------------------------------------------------------"
}

manage_service() {
    if [ ! -f /usr/local/bin/gost ]; then
        echo -e "${RED}GOST is not installed.${NC}"
        return 1
    fi

    while true; do
        echo -e "\n${CYAN}--- System Service Management ---${NC}"
        echo -e "1) Show service status (Status)"
        echo -e "2) Start service (Start)"
        echo -e "3) Stop service (Stop)"
        echo -e "4) Restart service (Restart)"
        echo -e "5) View service logs (Logs)"
        echo -e "6) Back to main menu"
        read -p "Your choice (1-6): " s_choice

        case $s_choice in
            1)
                systemctl status gost
                ;;
            2)
                systemctl start gost
                echo -e "${GREEN}Service started.${NC}"
                ;;
            3)
                systemctl stop gost
                echo -e "${RED}Service stopped.${NC}"
                ;;
            4)
                systemctl restart gost
                echo -e "${GREEN}Service restarted.${NC}"
                ;;
            5)
                echo -e "${CYAN}Showing service logs (press Ctrl+C to exit)...${NC}"
                journalctl -u gost -n 50 -f
                ;;
            6)
                break
                ;;
            *)
                echo -e "${RED}Invalid choice!${NC}"
                ;;
        esac
    done
}

uninstall_gost() {
    read -p "Are you sure you want to completely uninstall GOST? (y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "${YELLOW}Uninstall cancelled.${NC}"
        return 0
    fi

    echo -e "${CYAN}Stopping and disabling the service...${NC}"
    systemctl stop gost &>/dev/null
    systemctl disable gost &>/dev/null
    rm -f /etc/systemd/system/gost.service
    # Remove the enable symlink defensively in case `systemctl disable` failed
    rm -f /etc/systemd/system/multi-user.target.wants/gost.service
    systemctl daemon-reload
    systemctl reset-failed gost &>/dev/null

    echo -e "${CYAN}Removing binary and commands...${NC}"
    rm -f /usr/local/bin/gost
    rm -f /usr/local/bin/gost-manage.sh
    rm -f /usr/local/bin/wild

    echo -e "${CYAN}Cleaning up temporary files...${NC}"
    rm -f /tmp/gost_config_tmp.json
    rm -rf /tmp/gost_install

    read -p "Do you also want to delete the configuration files in /etc/gost? (y/n): " delete_config
    if [ "$delete_config" = "y" ] || [ "$delete_config" = "Y" ]; then
        rm -rf /etc/gost
        echo -e "${GREEN}Configuration files deleted.${NC}"
    else
        echo -e "${YELLOW}Configuration kept at /etc/gost (remove manually with: rm -rf /etc/gost).${NC}"
    fi

    echo -e "${GREEN}GOST was completely uninstalled.${NC}"
    # The management script just removed itself from the system path,
    # so exit instead of returning to the (now stale) menu.
    exit 0
}

main_menu() {
    while true; do
        show_banner
        if [ -f /usr/local/bin/gost ]; then
            status_line=$(systemctl is-active gost 2>/dev/null)
            if [ "$status_line" = "active" ]; then
                echo -e "Software status: ${GREEN}Installed & Active (Running)${NC}"
            else
                echo -e "Software status: ${YELLOW}Installed but Inactive (Stopped)${NC}"
            fi
        else
            echo -e "Software status: ${RED}Not Installed${NC}"
        fi
        echo -e "---------------------------------------------"
        echo -e "1) Install or Update GOST (Latest Version)"
        echo -e "2) Add a New Tunnel"
        echo -e "3) Remove an Existing Tunnel"
        echo -e "4) View Active Tunnels List"
        echo -e "5) Manage System Service (Start / Stop / Restart / Logs)"
        echo -e "6) Completely Uninstall GOST"
        echo -e "7) Exit"
        echo -e "---------------------------------------------"
        read -p "Enter your choice (1-7): " choice

        case $choice in
            1)
                install_gost
                ;;
            2)
                add_tunnel
                ;;
            3)
                delete_tunnel
                ;;
            4)
                list_tunnels
                ;;
            5)
                manage_service
                ;;
            6)
                uninstall_gost
                ;;
            7)
                echo -e "${GREEN}Thanks for using Wild GOST. Bye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice! Please enter a number between 1 and 7.${NC}"
                ;;
        esac
        echo -e "\nPress Enter to return to the menu..."
        read -r
        clear
    done
}

# Run menu loop
clear
main_menu
