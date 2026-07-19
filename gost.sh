#!/usr/bin/env bash

# Wild GOST management panel — wraps native GOST v3 JSON config.
# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

CONFIG_FILE="/etc/gost/config.json"
GH_MIRRORS=("")

# Shared wizard state
USERNAME=""
PASSWORD=""
LISTENER_TYPE="tcp"
DIALER_TYPE="tcp"
WS_PATH=""
WS_HOST=""
TRANSPORT_LABEL=""

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

require_gost() {
    if [ ! -f /usr/local/bin/gost ]; then
        echo -e "${RED}GOST is not installed. Choose option 1 to install it first.${NC}"
        return 1
    fi
    ensure_config
}

ensure_config() {
    mkdir -p /etc/gost
    if [ ! -f "$CONFIG_FILE" ]; then
        echo '{"services":[],"chains":[],"log":{"level":"info"}}' > "$CONFIG_FILE"
    fi
}

restart_gost() {
    systemctl restart gost 2>/dev/null || true
}

gen_uuid() {
    if command -v uuidgen &>/dev/null; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    elif [ -f /proc/sys/kernel/random/uuid ]; then
        cat /proc/sys/kernel/random/uuid
    else
        openssl rand -hex 16 | sed 's/\(........\)\(....\)\(....\)\(....\)\(............\)/\1-\2-\3-\4-\5/'
    fi
}

check_dependencies() {
    if ! command -v curl &>/dev/null; then
        echo -e "${YELLOW}curl is not installed. Installing...${NC}"
        if command -v apt-get &>/dev/null; then
            apt-get update && apt-get install -y curl
        elif command -v yum &>/dev/null; then
            yum install -y curl
        fi
    fi
    if ! command -v jq &>/dev/null; then
        echo -e "${YELLOW}jq is not installed. Installing...${NC}"
        if command -v apt-get &>/dev/null; then
            apt-get update && apt-get install -y jq
        elif command -v yum &>/dev/null; then
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
WorkingDirectory=/etc/gost
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
        GH_MIRRORS=("https://gh-proxy.com/" "https://ghproxy.net/" "https://mirror.ghproxy.com/" "")
        echo -e "${YELLOW}Iran mode enabled: GitHub mirrors will be used for downloads.${NC}"
    else
        GH_MIRRORS=("")
    fi
}

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

    ensure_config
    create_systemd_service

    if [ -f "$0" ] && [ "$0" != "/usr/local/bin/gost-manage.sh" ]; then
        cp "$0" /usr/local/bin/gost-manage.sh
    else
        fetch_url "https://raw.githubusercontent.com/infowild/Wild-Gost/master/gost.sh" /usr/local/bin/gost-manage.sh \
            || echo -e "${YELLOW}Warning: could not refresh the management script from GitHub.${NC}"
    fi
    chmod +x /usr/local/bin/gost-manage.sh

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

# ---------- helpers ----------

validate_listen_port() {
    local port="$1"
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo -e "${RED}Invalid port!${NC}"
        return 1
    fi
    local port_exists
    port_exists=$(jq --arg port ":$port" '.services[]? | select(.addr == $port) | .name' "$CONFIG_FILE")
    if [ -n "$port_exists" ]; then
        echo -e "${RED}Port :$port is already used in the configuration!${NC}"
        return 1
    fi
    return 0
}

prompt_auth() {
    USERNAME=""
    PASSWORD=""
    local has_auth
    read -p "Enable authentication (username/password)? (y/n): " has_auth
    if [ "$has_auth" = "y" ] || [ "$has_auth" = "Y" ]; then
        read -p "Username: " USERNAME
        read -p "Password: " PASSWORD
        if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
            echo -e "${RED}Username and password cannot be empty!${NC}"
            return 1
        fi
    fi
    return 0
}

# Sets LISTENER_TYPE, WS_PATH, WS_HOST, TRANSPORT_LABEL
select_listener_transport() {
    LISTENER_TYPE="tcp"
    WS_PATH=""
    WS_HOST=""
    TRANSPORT_LABEL="TCP"
    echo -e "\n${CYAN}Select listener transport:${NC}"
    echo -e " 1) tcp          2) udp          3) tls          4) mtls"
    echo -e " 5) ws           6) wss          7) mws          8) mwss  ${GREEN}(anti-DPI mux)${NC}"
    echo -e " 9) kcp         10) quic        11) grpc        12) http2"
    echo -e "13) http3       14) h2          15) h3          16) ssh"
    echo -e "17) sshd        18) dtls        19) icmp        20) pht"
    echo -e "21) ohttp (obfs) 22) otls (obfs) 23) ftcp        24) mtcp"
    read -p "Your choice (1-24) [default: 1]: " tchoice
    [ -z "$tchoice" ] && tchoice="1"
    case $tchoice in
        1) LISTENER_TYPE="tcp"; TRANSPORT_LABEL="TCP" ;;
        2) LISTENER_TYPE="udp"; TRANSPORT_LABEL="UDP" ;;
        3) LISTENER_TYPE="tls"; TRANSPORT_LABEL="TLS" ;;
        4) LISTENER_TYPE="mtls"; TRANSPORT_LABEL="mTLS" ;;
        5) LISTENER_TYPE="ws"; TRANSPORT_LABEL="WS" ;;
        6) LISTENER_TYPE="wss"; TRANSPORT_LABEL="WSS" ;;
        7) LISTENER_TYPE="mws"; TRANSPORT_LABEL="MWS" ;;
        8) LISTENER_TYPE="mwss"; TRANSPORT_LABEL="MWSS" ;;
        9) LISTENER_TYPE="kcp"; TRANSPORT_LABEL="KCP" ;;
        10) LISTENER_TYPE="quic"; TRANSPORT_LABEL="QUIC" ;;
        11) LISTENER_TYPE="grpc"; TRANSPORT_LABEL="gRPC" ;;
        12) LISTENER_TYPE="http2"; TRANSPORT_LABEL="HTTP2" ;;
        13) LISTENER_TYPE="http3"; TRANSPORT_LABEL="HTTP3" ;;
        14) LISTENER_TYPE="h2"; TRANSPORT_LABEL="H2" ;;
        15) LISTENER_TYPE="h3"; TRANSPORT_LABEL="H3" ;;
        16) LISTENER_TYPE="ssh"; TRANSPORT_LABEL="SSH" ;;
        17) LISTENER_TYPE="sshd"; TRANSPORT_LABEL="SSHD" ;;
        18) LISTENER_TYPE="dtls"; TRANSPORT_LABEL="DTLS" ;;
        19) LISTENER_TYPE="icmp"; TRANSPORT_LABEL="ICMP" ;;
        20) LISTENER_TYPE="pht"; TRANSPORT_LABEL="PHT" ;;
        21) LISTENER_TYPE="ohttp"; TRANSPORT_LABEL="obfs-HTTP" ;;
        22) LISTENER_TYPE="otls"; TRANSPORT_LABEL="obfs-TLS" ;;
        23) LISTENER_TYPE="ftcp"; TRANSPORT_LABEL="FakeTCP" ;;
        24) LISTENER_TYPE="mtcp"; TRANSPORT_LABEL="mTCP" ;;
        *) echo -e "${RED}Invalid choice!${NC}"; return 1 ;;
    esac
    case "$LISTENER_TYPE" in
        ws|wss|mws|mwss)
            read -p "WebSocket path [default: /ws]: " WS_PATH
            [ -z "$WS_PATH" ] && WS_PATH="/ws"
            ;;
    esac
    return 0
}

# Sets DIALER_TYPE, WS_PATH, WS_HOST, TRANSPORT_LABEL (for chain dialer)
select_dialer_transport() {
    DIALER_TYPE="tcp"
    WS_PATH=""
    WS_HOST=""
    TRANSPORT_LABEL="TCP"
    echo -e "\n${CYAN}Select dialer / chain transport:${NC}"
    echo -e " 1) tcp   2) tls   3) ws    4) wss   5) mws   6) mwss ${GREEN}(recommended)${NC}"
    echo -e " 7) kcp   8) quic  9) grpc 10) http2 11) http3 12) h2"
    echo -e "13) h3   14) ssh  15) sshd 16) dtls  17) icmp  18) pht"
    echo -e "19) ohttp 20) otls 21) ftcp 22) mtcp 23) mtls  24) utls"
    read -p "Your choice (1-24) [default: 6]: " tchoice
    [ -z "$tchoice" ] && tchoice="6"
    case $tchoice in
        1) DIALER_TYPE="tcp"; TRANSPORT_LABEL="TCP" ;;
        2) DIALER_TYPE="tls"; TRANSPORT_LABEL="TLS" ;;
        3) DIALER_TYPE="ws"; TRANSPORT_LABEL="WS" ;;
        4) DIALER_TYPE="wss"; TRANSPORT_LABEL="WSS" ;;
        5) DIALER_TYPE="mws"; TRANSPORT_LABEL="MWS" ;;
        6) DIALER_TYPE="mwss"; TRANSPORT_LABEL="MWSS" ;;
        7) DIALER_TYPE="kcp"; TRANSPORT_LABEL="KCP" ;;
        8) DIALER_TYPE="quic"; TRANSPORT_LABEL="QUIC" ;;
        9) DIALER_TYPE="grpc"; TRANSPORT_LABEL="gRPC" ;;
        10) DIALER_TYPE="http2"; TRANSPORT_LABEL="HTTP2" ;;
        11) DIALER_TYPE="http3"; TRANSPORT_LABEL="HTTP3" ;;
        12) DIALER_TYPE="h2"; TRANSPORT_LABEL="H2" ;;
        13) DIALER_TYPE="h3"; TRANSPORT_LABEL="H3" ;;
        14) DIALER_TYPE="ssh"; TRANSPORT_LABEL="SSH" ;;
        15) DIALER_TYPE="sshd"; TRANSPORT_LABEL="SSHD" ;;
        16) DIALER_TYPE="dtls"; TRANSPORT_LABEL="DTLS" ;;
        17) DIALER_TYPE="icmp"; TRANSPORT_LABEL="ICMP" ;;
        18) DIALER_TYPE="pht"; TRANSPORT_LABEL="PHT" ;;
        19) DIALER_TYPE="ohttp"; TRANSPORT_LABEL="obfs-HTTP" ;;
        20) DIALER_TYPE="otls"; TRANSPORT_LABEL="obfs-TLS" ;;
        21) DIALER_TYPE="ftcp"; TRANSPORT_LABEL="FakeTCP" ;;
        22) DIALER_TYPE="mtcp"; TRANSPORT_LABEL="mTCP" ;;
        23) DIALER_TYPE="mtls"; TRANSPORT_LABEL="mTLS" ;;
        24) DIALER_TYPE="utls"; TRANSPORT_LABEL="uTLS" ;;
        *) echo -e "${RED}Invalid choice!${NC}"; return 1 ;;
    esac
    case "$DIALER_TYPE" in
        ws|wss|mws|mwss)
            read -p "WebSocket path [default: /ws]: " WS_PATH
            [ -z "$WS_PATH" ] && WS_PATH="/ws"
            read -p "Host / SNI (optional): " WS_HOST
            ;;
        tls|utls|mtls)
            read -p "TLS serverName / SNI (optional): " WS_HOST
            ;;
    esac
    return 0
}

build_listener_json() {
    local ltype="$1"
    local path="$2"
    case "$ltype" in
        ws|wss|mws|mwss)
            jq -n --arg t "$ltype" --arg p "${path:-/ws}" '{type: $t, metadata: {path: $p}}'
            ;;
        *)
            jq -n --arg t "$ltype" '{type: $t}'
            ;;
    esac
}

build_dialer_json() {
    local dtype="$1"
    local path="$2"
    local host="$3"
    case "$dtype" in
        tls|utls|mtls)
            if [ -n "$host" ]; then
                jq -n --arg t "$dtype" --arg h "$host" '{type: $t, tls: {serverName: $h}}'
            else
                jq -n --arg t "$dtype" '{type: $t}'
            fi
            ;;
        ws|wss|mws|mwss)
            jq -n --arg t "$dtype" --arg p "${path:-/ws}" --arg h "$host" '
                {type: $t, metadata: ({path: $p} + (if $h != "" then {host: $h} else {} end))}
            '
            ;;
        *)
            jq -n --arg t "$dtype" '{type: $t}'
            ;;
    esac
}

build_handler_json() {
    local htype="$1"
    local user="$2"
    local pass="$3"
    local extra_meta="$4" # optional JSON object string or empty

    if [ -n "$user" ] && [ -n "$pass" ]; then
        if [ -n "$extra_meta" ]; then
            jq -n --arg t "$htype" --arg u "$user" --arg p "$pass" --argjson m "$extra_meta" \
                '{type: $t, auth: {username: $u, password: $p}, metadata: $m}'
        else
            jq -n --arg t "$htype" --arg u "$user" --arg p "$pass" \
                '{type: $t, auth: {username: $u, password: $p}}'
        fi
    else
        if [ -n "$extra_meta" ]; then
            jq -n --arg t "$htype" --argjson m "$extra_meta" '{type: $t, metadata: $m}'
        else
            jq -n --arg t "$htype" '{type: $t}'
        fi
    fi
}

append_service() {
    local svc_json="$1"
    jq --argjson s "$svc_json" '.services += [$s]' "$CONFIG_FILE" > /tmp/gost_config_tmp.json \
        && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
}

append_chain() {
    local ch_json="$1"
    jq --argjson c "$ch_json" '.chains = ((.chains // []) + [$c])' "$CONFIG_FILE" > /tmp/gost_config_tmp.json \
        && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
}

append_named_array() {
    local key="$1"
    local item="$2"
    jq --arg k "$key" --argjson item "$item" '.[$k] = ((.[$k] // []) + [$item])' "$CONFIG_FILE" > /tmp/gost_config_tmp.json \
        && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
}

set_config_key() {
    local key="$1"
    local value_json="$2"
    jq --arg k "$key" --argjson v "$value_json" '.[$k] = $v' "$CONFIG_FILE" > /tmp/gost_config_tmp.json \
        && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
}

build_chain_json() {
    local chain_name="$1"
    local connector_type="$2"
    local node_addr="$3"
    local username="$4"
    local password="$5"
    local dialer_type="${6:-tcp}"
    local ws_path="${7:-}"
    local ws_host="${8:-}"
    local strategy="${9:-}" # optional: round|rand|fifo|hash

    local dialer_json connector_json hop_json
    dialer_json=$(build_dialer_json "$dialer_type" "$ws_path" "$ws_host")

    if [ -n "$username" ] && [ -n "$password" ]; then
        connector_json=$(jq -n --arg t "$connector_type" --arg u "$username" --arg p "$password" \
            '{type: $t, auth: {username: $u, password: $p}}')
    else
        connector_json=$(jq -n --arg t "$connector_type" '{type: $t}')
    fi

    hop_json=$(jq -n \
        --arg addr "$node_addr" \
        --argjson conn "$connector_json" \
        --argjson dialer "$dialer_json" \
        '{name: "hop-0", nodes: [{name: "node-0", addr: $addr, connector: $conn, dialer: $dialer}]}')

    if [ -n "$strategy" ]; then
        jq -n --arg name "$chain_name" --argjson hop "$hop_json" --arg st "$strategy" \
            '{name: $name, selector: {strategy: $st, maxFails: 1, failTimeout: "30s"}, hops: [$hop]}'
    else
        jq -n --arg name "$chain_name" --argjson hop "$hop_json" \
            '{name: $name, hops: [$hop]}'
    fi
}

prompt_optional_chain() {
    # Sets CHAIN_NAME empty or filled; appends chain if needed. Args: service_port
    local port="$1"
    CHAIN_NAME=""
    local has_up conn_choice connector_type up_addr
    read -p "Attach an upstream chain? (y/n): " has_up
    if [ "$has_up" != "y" ] && [ "$has_up" != "Y" ]; then
        return 0
    fi
    echo -e "Connector type:"
    echo -e "1) relay  2) socks5  3) socks4  4) http  5) http2  6) ss  7) sshd  8) forward  9) sni  10) tunnel"
    read -p "Choice (1-10): " conn_choice
    case $conn_choice in
        1) connector_type="relay" ;;
        2) connector_type="socks5" ;;
        3) connector_type="socks4" ;;
        4) connector_type="http" ;;
        5) connector_type="http2" ;;
        6) connector_type="ss" ;;
        7) connector_type="sshd" ;;
        8) connector_type="forward" ;;
        9) connector_type="sni" ;;
        10) connector_type="tunnel" ;;
        *) echo -e "${RED}Invalid!${NC}"; return 1 ;;
    esac
    select_dialer_transport || return 1
    read -p "Upstream address (host:port): " up_addr
    if [[ ! "$up_addr" =~ ^[^[:space:]:]+:[0-9]+$ ]]; then
        echo -e "${RED}Invalid address!${NC}"; return 1
    fi
    prompt_auth || return 1
    local strategy=""
    read -p "Load-balance strategy (empty=none / round/rand/fifo): " strategy
    CHAIN_NAME="chain-$port"
    local ch
    ch=$(build_chain_json "$CHAIN_NAME" "$connector_type" "$up_addr" "$USERNAME" "$PASSWORD" \
        "$DIALER_TYPE" "$WS_PATH" "$WS_HOST" "$strategy")
    append_chain "$ch"
    return 0
}

# ---------- add proxy service ----------

add_proxy_service() {
    require_gost || return 1
    echo -e "${CYAN}--- Add Proxy / Handler Service ---${NC}"
    echo -e " 1) SOCKS5     2) SOCKS4     3) HTTP       4) HTTP2"
    echo -e " 5) HTTP3      6) Relay      7) Shadowsocks 8) Auto"
    echo -e " 9) SNI       10) SSHD      11) MASQUE    12) Serial"
    read -p "Your choice (1-12): " pchoice

    local handler_type port name meta="" ss_method ss_password
    case $pchoice in
        1) handler_type="socks5" ;;
        2) handler_type="socks4" ;;
        3) handler_type="http" ;;
        4) handler_type="http2" ;;
        5) handler_type="http3" ;;
        6) handler_type="relay" ;;
        7) handler_type="ss" ;;
        8) handler_type="auto" ;;
        9) handler_type="sni" ;;
        10) handler_type="sshd" ;;
        11) handler_type="masque" ;;
        12) handler_type="serial" ;;
        *) echo -e "${RED}Invalid!${NC}"; return 1 ;;
    esac

    read -p "Listening port (e.g. 1080 or 443): " port
    validate_listen_port "$port" || return 1
    select_listener_transport || return 1

    if [ "$handler_type" = "ss" ]; then
        read -p "Shadowsocks method [aes-256-gcm]: " ss_method
        [ -z "$ss_method" ] && ss_method="aes-256-gcm"
        read -p "Shadowsocks password: " ss_password
        [ -z "$ss_password" ] && { echo -e "${RED}Password required!${NC}"; return 1; }
        meta=$(jq -n --arg m "$ss_method" --arg p "$ss_password" '{method: $m, password: $p}')
        USERNAME=""; PASSWORD=""
    elif [ "$handler_type" = "socks4" ] || [ "$handler_type" = "sni" ] || [ "$handler_type" = "auto" ] || [ "$handler_type" = "serial" ]; then
        USERNAME=""; PASSWORD=""
    else
        prompt_auth || return 1
        if [ "$handler_type" = "socks5" ]; then
            local udp_en
            read -p "Enable SOCKS5 UDP? (y/n): " udp_en
            if [ "$udp_en" = "y" ] || [ "$udp_en" = "Y" ]; then
                meta='{"udp":true}'
            fi
            read -p "Enable SOCKS5 BIND? (y/n): " udp_en
            if [ "$udp_en" = "y" ] || [ "$udp_en" = "Y" ]; then
                if [ -n "$meta" ]; then
                    meta=$(echo "$meta" | jq '. + {bind: true}')
                else
                    meta='{"bind":true}'
                fi
            fi
        fi
        if [ "$handler_type" = "relay" ]; then
            local bind_en
            read -p "Enable Relay BIND? (y/n): " bind_en
            if [ "$bind_en" = "y" ] || [ "$bind_en" = "Y" ]; then
                meta='{"bind":true}'
            fi
        fi
        if [ "$handler_type" = "http" ]; then
            local http_udp
            read -p "Enable HTTP UDP (udp-over-tcp)? (y/n): " http_udp
            if [ "$http_udp" = "y" ] || [ "$http_udp" = "Y" ]; then
                meta='{"udp":true}'
            fi
        fi
    fi

    prompt_optional_chain "$port" || return 1

    name="svc-$handler_type-$port"
    local handler_json listener_json svc
    handler_json=$(build_handler_json "$handler_type" "$USERNAME" "$PASSWORD" "$meta")
    if [ -n "$CHAIN_NAME" ]; then
        handler_json=$(echo "$handler_json" | jq --arg c "$CHAIN_NAME" '. + {chain: $c}')
    fi
    listener_json=$(build_listener_json "$LISTENER_TYPE" "$WS_PATH")
    svc=$(jq -n --arg n "$name" --arg a ":$port" --argjson h "$handler_json" --argjson l "$listener_json" \
        '{name: $n, addr: $a, handler: $h, listener: $l}')
    append_service "$svc"
    restart_gost
    echo -e "${GREEN}Service $name added ($handler_type / $TRANSPORT_LABEL).${NC}"
}

add_local_port_forward() {
    require_gost || return 1
    echo -e "${CYAN}--- Local Port Forward ---${NC}"
    local port target proto handler_type listener_type name svc
    echo -e "1) TCP  2) UDP"
    read -p "Choice: " proto
    case $proto in
        1) handler_type="tcp"; listener_type="tcp" ;;
        2) handler_type="udp"; listener_type="udp" ;;
        *) echo -e "${RED}Invalid!${NC}"; return 1 ;;
    esac
    read -p "Listen port: " port
    validate_listen_port "$port" || return 1
    read -p "Target host:port: " target
    [[ ! "$target" =~ ^[^[:space:]:]+:[0-9]+$ ]] && { echo -e "${RED}Invalid target!${NC}"; return 1; }

    prompt_optional_chain "$port" || return 1

    name="fwd-$handler_type-$port"
    if [ -n "$CHAIN_NAME" ]; then
        svc=$(jq -n --arg n "$name" --arg a ":$port" --arg h "$handler_type" --arg l "$listener_type" \
            --arg c "$CHAIN_NAME" --arg t "$target" --arg p "$port" \
            '{name:$n,addr:$a,handler:{type:$h,chain:$c},listener:{type:$l},forwarder:{nodes:[{name:("target-"+$p),addr:$t}]}}')
    else
        svc=$(jq -n --arg n "$name" --arg a ":$port" --arg h "$handler_type" --arg l "$listener_type" \
            --arg t "$target" --arg p "$port" \
            '{name:$n,addr:$a,handler:{type:$h},listener:{type:$l},forwarder:{nodes:[{name:("target-"+$p),addr:$t}]}}')
    fi
    append_service "$svc"
    restart_gost
    echo -e "${GREEN}Port forward $name -> $target added.${NC}"
}

# ---------- reverse tunnel ----------

setup_reverse_tunnel_server() {
    require_gost || return 1
    echo -e "${CYAN}--- Reverse Tunnel SERVER (public) ---${NC}"
    local tunnel_port entry_port hostname tid name svc
    read -p "Tunnel listen port (e.g. 8421): " tunnel_port
    validate_listen_port "$tunnel_port" || return 1
    read -p "Public entrypoint port (e.g. 8420): " entry_port
    if [[ ! "$entry_port" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid entry port!${NC}"; return 1
    fi
    read -p "Ingress hostname (e.g. app.example.com): " hostname
    [ -z "$hostname" ] && { echo -e "${RED}Hostname required!${NC}"; return 1; }
    tid=$(gen_uuid)
    select_listener_transport || return 1

    local ingress
    ingress=$(jq -n --arg n "ingress-$tunnel_port" --arg h "$hostname" --arg e "$tid" \
        '{name: $n, rules: [{hostname: $h, endpoint: $e}]}')
    append_named_array "ingresses" "$ingress"

    name="tunnel-server-$tunnel_port"
    local listener_json
    listener_json=$(build_listener_json "$LISTENER_TYPE" "$WS_PATH")
    svc=$(jq -n --arg n "$name" --arg a ":$tunnel_port" --arg ep ":$entry_port" \
        --arg ing "ingress-$tunnel_port" --argjson l "$listener_json" \
        '{name:$n,addr:$a,handler:{type:"tunnel",metadata:{entrypoint:$ep,ingress:$ing}},listener:$l}')
    append_service "$svc"
    restart_gost

    echo -e "${GREEN}Reverse tunnel server ready.${NC}"
    echo -e "${CYAN}Save these for the CLIENT (behind NAT):${NC}"
    echo -e "  Tunnel ID   : ${YELLOW}$tid${NC}"
    echo -e "  Server addr : ${YELLOW}<THIS_IP>:$tunnel_port${NC}"
    echo -e "  Transport   : ${YELLOW}$TRANSPORT_LABEL${NC}"
    echo -e "  Hostname    : ${YELLOW}$hostname${NC}"
    echo -e "  Entrypoint  : ${YELLOW}:$entry_port${NC}"
}

setup_reverse_tunnel_client() {
    require_gost || return 1
    echo -e "${CYAN}--- Reverse Tunnel CLIENT (behind NAT) ---${NC}"
    local tid server_addr target proto handler_type name svc chain_name
    read -p "Tunnel ID (UUID from server): " tid
    [ -z "$tid" ] && { echo -e "${RED}Tunnel ID required!${NC}"; return 1; }
    read -p "Public tunnel server host:port: " server_addr
    [[ ! "$server_addr" =~ ^[^[:space:]:]+:[0-9]+$ ]] && { echo -e "${RED}Invalid address!${NC}"; return 1; }
    read -p "Local target to expose (host:port): " target
    [[ ! "$target" =~ ^[^[:space:]:]+:[0-9]+$ ]] && { echo -e "${RED}Invalid target!${NC}"; return 1; }
    echo -e "1) rtcp (TCP)  2) rudp (UDP)"
    read -p "Choice: " proto
    case $proto in
        1) handler_type="rtcp" ;;
        2) handler_type="rudp" ;;
        *) echo -e "${RED}Invalid!${NC}"; return 1 ;;
    esac
    select_dialer_transport || return 1

    chain_name="chain-tunnel-$(echo "$tid" | cut -c1-8)"
    local ch
    ch=$(jq -n --arg n "$chain_name" --arg addr "$server_addr" --arg tid "$tid" \
        --argjson dialer "$(build_dialer_json "$DIALER_TYPE" "$WS_PATH" "$WS_HOST")" \
        '{name:$n,hops:[{name:"hop-0",nodes:[{name:"node-0",addr:$addr,connector:{type:"tunnel",metadata:{"tunnel.id":$tid}},dialer:$dialer}]}]}')
    append_chain "$ch"

    name="reverse-$handler_type-$(echo "$tid" | cut -c1-8)"
    svc=$(jq -n --arg n "$name" --arg h "$handler_type" --arg c "$chain_name" --arg t "$target" \
        '{name:$n,addr:":0",handler:{type:$h},listener:{type:$h,chain:$c},forwarder:{nodes:[{name:"target",addr:$t}]}}')
    append_service "$svc"
    restart_gost
    echo -e "${GREEN}Reverse tunnel client $name started (exposes $target).${NC}"
}

setup_reverse_tunnel_menu() {
    echo -e "${CYAN}--- Reverse Proxy / Tunnel ---${NC}"
    echo -e "1) Server (public / ingress)"
    echo -e "2) Client (behind NAT / rtcp|rudp)"
    read -p "Choice: " c
    case $c in
        1) setup_reverse_tunnel_server ;;
        2) setup_reverse_tunnel_client ;;
        *) echo -e "${RED}Invalid!${NC}" ;;
    esac
}

# ---------- DNS / redirect / tun / file ----------

add_dns_proxy() {
    require_gost || return 1
    echo -e "${CYAN}--- DNS Proxy ---${NC}"
    local port upstream name svc resolver_name
    read -p "DNS listen port [53]: " port
    [ -z "$port" ] && port="53"
    validate_listen_port "$port" || return 1
    read -p "Upstream DNS (e.g. udp://8.8.8.8:53 or tls://1.1.1.1:853): " upstream
    [ -z "$upstream" ] && upstream="udp://8.8.8.8:53"
    echo -e "Listener: 1) dns/udp  2) tcp  3) tls (DoT-style listen)"
    read -p "Choice [1]: " lc
    [ -z "$lc" ] && lc="1"
    case $lc in
        1) LISTENER_TYPE="dns" ;;
        2) LISTENER_TYPE="tcp" ;;
        3) LISTENER_TYPE="tls" ;;
        *) LISTENER_TYPE="dns" ;;
    esac

    resolver_name="resolver-$port"
    local resolver
    resolver=$(jq -n --arg n "$resolver_name" --arg u "$upstream" \
        '{name: $n, nameservers: [{addr: $u}]}')
    append_named_array "resolvers" "$resolver"

    name="dns-$port"
    svc=$(jq -n --arg n "$name" --arg a ":$port" --arg r "$resolver_name" --arg l "$LISTENER_TYPE" \
        '{name:$n,addr:$a,resolver:$r,handler:{type:"dns"},listener:{type:$l}}')
    append_service "$svc"
    restart_gost
    echo -e "${GREEN}DNS proxy on :$port -> $upstream${NC}"
}

add_transparent_redirect() {
    require_gost || return 1
    echo -e "${CYAN}--- Transparent Redirect ---${NC}"
    echo -e "${YELLOW}Requires iptables/nftables REDIRECT/TPROXY rules on the host.${NC}"
    local port proto handler_type listener_type name svc
    echo -e "1) TCP redirect  2) UDP redirect"
    read -p "Choice: " proto
    case $proto in
        1) handler_type="red"; listener_type="red" ;;
        2) handler_type="redu"; listener_type="redu" ;;
        *) echo -e "${RED}Invalid!${NC}"; return 1 ;;
    esac
    read -p "Listen port (redirect target port): " port
    validate_listen_port "$port" || return 1
    prompt_optional_chain "$port" || return 1
    name="redirect-$port"
    if [ -n "$CHAIN_NAME" ]; then
        svc=$(jq -n --arg n "$name" --arg a ":$port" --arg h "$handler_type" --arg l "$listener_type" --arg c "$CHAIN_NAME" \
            '{name:$n,addr:$a,handler:{type:$h,chain:$c},listener:{type:$l}}')
    else
        svc=$(jq -n --arg n "$name" --arg a ":$port" --arg h "$handler_type" --arg l "$listener_type" \
            '{name:$n,addr:$a,handler:{type:$h},listener:{type:$l}}')
    fi
    append_service "$svc"
    restart_gost
    echo -e "${GREEN}Transparent redirect service $name added.${NC}"
}

add_tun_service() {
    require_gost || return 1
    echo -e "${CYAN}--- TUN / TAP / TUN2SOCKS ---${NC}"
    echo -e "1) TUN  2) TAP  3) TUNGO (TUN2SOCKS)"
    read -p "Choice: " c
    local handler_type name svc
    case $c in
        1) handler_type="tun" ;;
        2) handler_type="tap" ;;
        3) handler_type="tungo" ;;
        *) echo -e "${RED}Invalid!${NC}"; return 1 ;;
    esac
    read -p "Service name suffix [0]: " suffix
    [ -z "$suffix" ] && suffix="0"
    prompt_optional_chain "tun$suffix" || return 1
    name="$handler_type-$suffix"
    if [ -n "$CHAIN_NAME" ]; then
        svc=$(jq -n --arg n "$name" --arg h "$handler_type" --arg c "$CHAIN_NAME" \
            '{name:$n,addr:":0",handler:{type:$h,chain:$c},listener:{type:$h}}')
    else
        svc=$(jq -n --arg n "$name" --arg h "$handler_type" \
            '{name:$n,addr:":0",handler:{type:$h},listener:{type:$h}}')
    fi
    append_service "$svc"
    restart_gost
    echo -e "${GREEN}$handler_type service added. Configure routes/IP on the TUN interface as needed.${NC}"
}

add_file_server() {
    require_gost || return 1
    echo -e "${CYAN}--- File Server ---${NC}"
    local port dir name svc
    read -p "Listen port: " port
    validate_listen_port "$port" || return 1
    read -p "Directory to serve [/var/www]: " dir
    [ -z "$dir" ] && dir="/var/www"
    select_listener_transport || return 1
    prompt_auth || return 1
    name="file-$port"
    local handler_json listener_json
    handler_json=$(build_handler_json "file" "$USERNAME" "$PASSWORD" "$(jq -n --arg d "$dir" '{dir: $d}')")
    listener_json=$(build_listener_json "$LISTENER_TYPE" "$WS_PATH")
    svc=$(jq -n --arg n "$name" --arg a ":$port" --argjson h "$handler_json" --argjson l "$listener_json" \
        '{name:$n,addr:$a,handler:$h,listener:$l}')
    append_service "$svc"
    restart_gost
    echo -e "${GREEN}File server $name serving $dir on :$port${NC}"
}

# ---------- remote port forward (kept / enhanced) ----------

select_transport_preset() {
    # simplified preset for remote fwd: tcp/tls/wss/mwss
    LISTENER_TYPE="tcp"
    DIALER_TYPE="tcp"
    WS_PATH=""
    WS_HOST=""
    TRANSPORT_LABEL="Plain TCP"
    echo -e "\n${CYAN}Select transport layer (anti-DPI):${NC}"
    echo -e "1) Plain TCP          ${RED}- high DPI risk${NC}"
    echo -e "2) TLS                ${YELLOW}- encrypted${NC}"
    echo -e "3) WSS                ${YELLOW}- HTTPS WebSocket${NC}"
    echo -e "4) MWSS               ${GREEN}- recommended (mux)${NC}"
    echo -e "5) Full transport list (advanced)"
    read -p "Choice (1-5) [default: 4]: " c
    [ -z "$c" ] && c="4"
    case $c in
        1) LISTENER_TYPE="tcp"; DIALER_TYPE="tcp"; TRANSPORT_LABEL="Plain TCP" ;;
        2) LISTENER_TYPE="tls"; DIALER_TYPE="tls"; TRANSPORT_LABEL="TLS"
           read -p "SNI / serverName (optional): " WS_HOST ;;
        3) LISTENER_TYPE="wss"; DIALER_TYPE="wss"; TRANSPORT_LABEL="WSS"
           read -p "WebSocket path [/ws]: " WS_PATH; [ -z "$WS_PATH" ] && WS_PATH="/ws"
           read -p "Host / SNI (optional): " WS_HOST ;;
        4) LISTENER_TYPE="mwss"; DIALER_TYPE="mwss"; TRANSPORT_LABEL="MWSS"
           read -p "WebSocket path [/ws]: " WS_PATH; [ -z "$WS_PATH" ] && WS_PATH="/ws"
           read -p "Host / SNI (optional): " WS_HOST ;;
        5)
           echo -e "${CYAN}For Server B pick listener; for Server A pick dialer.${NC}"
           select_listener_transport || return 1
           DIALER_TYPE="$LISTENER_TYPE"
           ;;
        *) echo -e "${RED}Invalid!${NC}"; return 1 ;;
    esac
    return 0
}

setup_remote_port_forward_upstream() {
    require_gost || return 1
    echo -e "${CYAN}--- Server B: Upstream ---${NC}"
    local port handler_choice handler_type udp_enabled name svc meta=""
    read -p "Listening port (e.g. 443): " port
    validate_listen_port "$port" || return 1
    echo -e "1) Relay (recommended)  2) SOCKS5  3) HTTP"
    read -p "Choice: " handler_choice
    case $handler_choice in
        1) handler_type="relay" ;;
        2) handler_type="socks5" ;;
        3) handler_type="http" ;;
        *) echo -e "${RED}Invalid!${NC}"; return 1 ;;
    esac
    select_transport_preset || return 1
    prompt_auth || return 1
    udp_enabled="n"
    if [ "$handler_type" = "socks5" ] || [ "$handler_type" = "http" ]; then
        read -p "Enable UDP support? (y/n): " udp_enabled
        if [ "$udp_enabled" = "y" ] || [ "$udp_enabled" = "Y" ]; then
            meta='{"udp":true}'
        fi
    fi
    if [ "$handler_type" = "relay" ] || [ "$handler_type" = "socks5" ]; then
        local bind_en
        read -p "Enable BIND (for remote bind/rtcp)? (y/n): " bind_en
        if [ "$bind_en" = "y" ] || [ "$bind_en" = "Y" ]; then
            if [ -n "$meta" ]; then meta=$(echo "$meta" | jq '. + {bind: true}'); else meta='{"bind":true}'; fi
        fi
    fi
    name="upstream-$handler_type-$LISTENER_TYPE-$port"
    local handler_json listener_json
    handler_json=$(build_handler_json "$handler_type" "$USERNAME" "$PASSWORD" "$meta")
    listener_json=$(build_listener_json "$LISTENER_TYPE" "$WS_PATH")
    svc=$(jq -n --arg n "$name" --arg a ":$port" --argjson h "$handler_json" --argjson l "$listener_json" \
        '{name:$n,addr:$a,handler:$h,listener:$l}')
    append_service "$svc"
    restart_gost
    echo -e "${GREEN}Upstream ready. On Server A use same transport ($TRANSPORT_LABEL) and <IP>:$port${NC}"
}

setup_remote_port_forward_entry() {
    require_gost || return 1
    echo -e "${CYAN}--- Server A: Entry + Remote Forward ---${NC}"
    local port proto handler_type listener_type connector_type upstream_addr target name chain_name svc ch
    read -p "Listen port on this server: " port
    validate_listen_port "$port" || return 1
    echo -e "1) TCP  2) UDP"
    read -p "Choice: " proto
    case $proto in
        1) handler_type="tcp"; listener_type="tcp" ;;
        2) handler_type="udp"; listener_type="udp" ;;
        *) echo -e "${RED}Invalid!${NC}"; return 1 ;;
    esac
    echo -e "Upstream connector: 1) relay  2) socks5  3) http"
    read -p "Choice: " c
    case $c in
        1) connector_type="relay" ;;
        2) connector_type="socks5" ;;
        3) connector_type="http" ;;
        *) echo -e "${RED}Invalid!${NC}"; return 1 ;;
    esac
    select_transport_preset || return 1
    read -p "Server B host:port: " upstream_addr
    [[ ! "$upstream_addr" =~ ^[^[:space:]:]+:[0-9]+$ ]] && { echo -e "${RED}Invalid!${NC}"; return 1; }
    prompt_auth || return 1
    read -p "Target on B network (e.g. 127.0.0.1:80): " target
    [[ ! "$target" =~ ^[^[:space:]:]+:[0-9]+$ ]] && { echo -e "${RED}Invalid!${NC}"; return 1; }

    name="remote-fwd-$port"
    chain_name="chain-remote-$port"
    svc=$(jq -n --arg n "$name" --arg a ":$port" --arg h "$handler_type" --arg l "$listener_type" \
        --arg c "$chain_name" --arg t "$target" --arg p "$port" \
        '{name:$n,addr:$a,handler:{type:$h,chain:$c},listener:{type:$l},forwarder:{nodes:[{name:("target-"+$p),addr:$t}]}}')
    ch=$(build_chain_json "$chain_name" "$connector_type" "$upstream_addr" "$USERNAME" "$PASSWORD" \
        "$DIALER_TYPE" "$WS_PATH" "$WS_HOST")
    append_service "$svc"
    append_chain "$ch"
    restart_gost
    echo -e "${GREEN}Remote forward :$port -> $upstream_addr -> $target ($TRANSPORT_LABEL)${NC}"
}

setup_remote_port_forward() {
    require_gost || return 1
    echo -e "${CYAN}--- Remote Port Forward (Two-Server) ---${NC}"
    echo -e "${YELLOW}Prefer MWSS on port 443. Configure B first, then A.${NC}"
    echo -e "1) Server A (entry)  2) Server B (upstream)"
    read -p "Choice: " c
    case $c in
        1) setup_remote_port_forward_entry ;;
        2) setup_remote_port_forward_upstream ;;
        *) echo -e "${RED}Invalid!${NC}" ;;
    esac
}

# ---------- policies / api / metrics ----------

manage_bypass() {
    require_gost || return 1
    echo -e "${CYAN}--- Bypass ---${NC}"
    local name whitelist matchers_raw
    read -p "Bypass name [bypass-0]: " name
    [ -z "$name" ] && name="bypass-0"
    read -p "Whitelist mode? (y/n): " whitelist
    read -p "Matchers (comma-separated, e.g. *.example.com,10.0.0.0/8): " matchers_raw
    local wl="false"
    [ "$whitelist" = "y" ] || [ "$whitelist" = "Y" ] && wl="true"
    local item
    item=$(jq -n --arg n "$name" --argjson w "$wl" --arg m "$matchers_raw" \
        '{name:$n, whitelist:$w, matchers: ($m | split(",") | map(gsub("^\\s+|\\s+$";"")) | map(select(. != "")))}')
    append_named_array "bypasses" "$item"
    echo -e "${GREEN}Bypass $name saved. Attach it to a service via config edit or recreate service with bypass field.${NC}"
    echo -e "${CYAN}To attach to last service, enter service name (or empty to skip):${NC}"
    local svc_name
    read -p "Service name: " svc_name
    if [ -n "$svc_name" ]; then
        jq --arg s "$svc_name" --arg b "$name" \
            '(.services[] | select(.name==$s) | .bypass) = $b' "$CONFIG_FILE" > /tmp/gost_config_tmp.json \
            && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
        restart_gost
        echo -e "${GREEN}Attached bypass $name to $svc_name${NC}"
    fi
}

manage_admission() {
    require_gost || return 1
    echo -e "${CYAN}--- Admission ---${NC}"
    local name whitelist matchers_raw
    read -p "Admission name [admission-0]: " name
    [ -z "$name" ] && name="admission-0"
    read -p "Whitelist mode? (y/n): " whitelist
    read -p "Matchers (comma-separated IPs/CIDRs): " matchers_raw
    local wl="false"
    [ "$whitelist" = "y" ] || [ "$whitelist" = "Y" ] && wl="true"
    local item
    item=$(jq -n --arg n "$name" --argjson w "$wl" --arg m "$matchers_raw" \
        '{name:$n, whitelist:$w, matchers: ($m | split(",") | map(gsub("^\\s+|\\s+$";"")) | map(select(. != "")))}')
    append_named_array "admissions" "$item"
    read -p "Attach to service name (empty=skip): " svc_name
    if [ -n "$svc_name" ]; then
        jq --arg s "$svc_name" --arg a "$name" \
            '(.services[] | select(.name==$s) | .admission) = $a' "$CONFIG_FILE" > /tmp/gost_config_tmp.json \
            && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
        restart_gost
        echo -e "${GREEN}Attached admission $name to $svc_name${NC}"
    fi
}

manage_limiter() {
    require_gost || return 1
    echo -e "${CYAN}--- Limiter ---${NC}"
    local name conn rate
    read -p "Limiter name [limiter-0]: " name
    [ -z "$name" ] && name="limiter-0"
    read -p "Max connections (empty=skip): " conn
    read -p "Rate limit e.g. 100KB (empty=skip): " rate
    local item
    item=$(jq -n --arg n "$name" --arg c "$conn" --arg r "$rate" '
        {name: $n}
        + (if $c != "" then {conn: ($c|tonumber)} else {} end)
        + (if $r != "" then {limits: [$r]} else {} end)
    ')
    append_named_array "limiters" "$item"
    read -p "Attach to service name (empty=skip): " svc_name
    if [ -n "$svc_name" ]; then
        jq --arg s "$svc_name" --arg l "$name" \
            '(.services[] | select(.name==$s) | .limiter) = $l' "$CONFIG_FILE" > /tmp/gost_config_tmp.json \
            && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
        restart_gost
        echo -e "${GREEN}Attached limiter $name to $svc_name${NC}"
    fi
}

enable_api_metrics() {
    require_gost || return 1
    echo -e "${CYAN}--- API / Metrics / Profiling ---${NC}"
    echo -e "1) Enable Web API"
    echo -e "2) Enable Prometheus metrics"
    echo -e "3) Enable profiling"
    echo -e "4) Disable API"
    echo -e "5) Disable metrics"
    echo -e "6) Disable profiling"
    read -p "Choice: " c
    case $c in
        1)
            local aport auser apass
            read -p "API listen port [18080]: " aport
            [ -z "$aport" ] && aport="18080"
            read -p "API username (optional): " auser
            read -p "API password (optional): " apass
            if [ -n "$auser" ]; then
                set_config_key "api" "$(jq -n --arg a ":$aport" --arg u "$auser" --arg p "$apass" \
                    '{addr:$a, pathPrefix:"/api", accesslog:true, auth:{username:$u,password:$p}}')"
            else
                set_config_key "api" "$(jq -n --arg a ":$aport" '{addr:$a, pathPrefix:"/api", accesslog:true}')"
            fi
            restart_gost
            echo -e "${GREEN}API enabled on :$aport${NC}"
            ;;
        2)
            local mport
            read -p "Metrics port [9000]: " mport
            [ -z "$mport" ] && mport="9000"
            set_config_key "metrics" "$(jq -n --arg a ":$mport" '{addr:$a, path:"/metrics"}')"
            restart_gost
            echo -e "${GREEN}Metrics on :$mport/metrics${NC}"
            ;;
        3)
            local pport
            read -p "Profiling port [6060]: " pport
            [ -z "$pport" ] && pport="6060"
            set_config_key "profiling" "$(jq -n --arg a ":$pport" '{addr:$a}')"
            restart_gost
            echo -e "${GREEN}Profiling on :$pport${NC}"
            ;;
        4) jq 'del(.api)' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"; restart_gost; echo -e "${GREEN}API disabled.${NC}" ;;
        5) jq 'del(.metrics)' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"; restart_gost; echo -e "${GREEN}Metrics disabled.${NC}" ;;
        6) jq 'del(.profiling)' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"; restart_gost; echo -e "${GREEN}Profiling disabled.${NC}" ;;
        *) echo -e "${RED}Invalid!${NC}" ;;
    esac
}

manage_policies_menu() {
    echo -e "${CYAN}--- Policies & Controls ---${NC}"
    echo -e "1) Bypass"
    echo -e "2) Admission"
    echo -e "3) Limiter"
    echo -e "4) API / Metrics / Profiling"
    echo -e "5) Set log level"
    read -p "Choice: " c
    case $c in
        1) manage_bypass ;;
        2) manage_admission ;;
        3) manage_limiter ;;
        4) enable_api_metrics ;;
        5)
            require_gost || return 1
            echo -e "1) info  2) debug  3) warn  4) error"
            read -p "Choice: " lc
            local level="info"
            case $lc in 1) level="info" ;; 2) level="debug" ;; 3) level="warn" ;; 4) level="error" ;; esac
            set_config_key "log" "$(jq -n --arg l "$level" '{level:$l}')"
            restart_gost
            echo -e "${GREEN}Log level: $level${NC}"
            ;;
        *) echo -e "${RED}Invalid!${NC}" ;;
    esac
}

# ---------- add service hub ----------

add_service_menu() {
    require_gost || return 1
    echo -e "${CYAN}--- Add Service / Tunnel ---${NC}"
    echo -e "1) Proxy server (SOCKS/HTTP/Relay/SS/HTTP2/HTTP3/SNI/SSHD/MASQUE/...)"
    echo -e "2) Local port forward (TCP/UDP + optional chain)"
    echo -e "3) Remote port forward (two-server)"
    echo -e "4) Reverse tunnel (NAT penetration)"
    echo -e "5) Transparent redirect"
    echo -e "6) DNS proxy (Do53 / DoT upstream)"
    echo -e "7) TUN / TAP / TUN2SOCKS"
    echo -e "8) File server"
    echo -e "9) Back"
    read -p "Choice (1-9): " c
    case $c in
        1) add_proxy_service ;;
        2) add_local_port_forward ;;
        3) setup_remote_port_forward ;;
        4) setup_reverse_tunnel_menu ;;
        5) add_transparent_redirect ;;
        6) add_dns_proxy ;;
        7) add_tun_service ;;
        8) add_file_server ;;
        9) return 0 ;;
        *) echo -e "${RED}Invalid!${NC}" ;;
    esac
}

# ---------- delete / list ----------

delete_tunnel() {
    require_gost || return 1
    echo -e "${CYAN}--- Remove Service ---${NC}"
    local services_count
    services_count=$(jq '.services | length' "$CONFIG_FILE")
    if [ "$services_count" -eq 0 ]; then
        echo -e "${YELLOW}No services configured.${NC}"
        return 0
    fi
    local i name addr type
    for ((i=0; i<services_count; i++)); do
        name=$(jq -r ".services[$i].name" "$CONFIG_FILE")
        addr=$(jq -r ".services[$i].addr" "$CONFIG_FILE")
        type=$(jq -r ".services[$i].handler.type" "$CONFIG_FILE")
        echo -e "$((i+1))) $name | $addr | $type"
    done
    read -p "Number to remove: " choice
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$services_count" ]; then
        echo -e "${RED}Invalid!${NC}"; return 1
    fi
    local index=$((choice-1))
    local service_name associated_chain
    service_name=$(jq -r ".services[$index].name" "$CONFIG_FILE")
    associated_chain=$(jq -r ".services[$index].handler.chain // .services[$index].listener.chain // empty" "$CONFIG_FILE")
    jq --arg name "$service_name" '.services |= map(select(.name != $name))' "$CONFIG_FILE" > /tmp/gost_config_tmp.json \
        && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
    if [ -n "$associated_chain" ]; then
        jq --arg chain "$associated_chain" '.chains |= map(select(.name != $chain))' "$CONFIG_FILE" > /tmp/gost_config_tmp.json \
            && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
    fi
    restart_gost
    echo -e "${GREEN}Removed $service_name${NC}"
}

list_tunnels() {
    require_gost || return 1
    echo -e "${CYAN}--- Services ---${NC}"
    local services_count
    services_count=$(jq '.services | length' "$CONFIG_FILE")
    if [ "$services_count" -eq 0 ]; then
        echo -e "${YELLOW}No services.${NC}"
    else
        printf "%-4s %-22s %-10s %-10s %-8s %-18s %-16s\n" "No." "Name" "Listen" "Handler" "Transport" "Upstream" "Target"
        echo "--------------------------------------------------------------------------------------------------------"
        local i name addr type chain forward_target listener_type upstream transport dialer_type
        for ((i=0; i<services_count; i++)); do
            name=$(jq -r ".services[$i].name" "$CONFIG_FILE")
            addr=$(jq -r ".services[$i].addr" "$CONFIG_FILE")
            type=$(jq -r ".services[$i].handler.type" "$CONFIG_FILE")
            chain=$(jq -r ".services[$i].handler.chain // .services[$i].listener.chain // empty" "$CONFIG_FILE")
            forward_target=$(jq -r ".services[$i].forwarder.nodes[0].addr // \"-\"" "$CONFIG_FILE")
            listener_type=$(jq -r ".services[$i].listener.type // \"-\"" "$CONFIG_FILE")
            upstream="-"; transport="$listener_type"
            if [ -n "$chain" ]; then
                upstream=$(jq -r --arg ch "$chain" '.chains[]? | select(.name==$ch) | .hops[0].nodes[0].addr' "$CONFIG_FILE")
                [ -z "$upstream" ] || [ "$upstream" = "null" ] && upstream="$chain"
                dialer_type=$(jq -r --arg ch "$chain" '.chains[]? | select(.name==$ch) | .hops[0].nodes[0].dialer.type // empty' "$CONFIG_FILE")
                [ -n "$dialer_type" ] && [ "$dialer_type" != "null" ] && transport="$dialer_type"
            fi
            printf "%-4s %-22s %-10s %-10s %-8s %-18s %-16s\n" "$((i+1))" "$name" "$addr" "$type" "$transport" "$upstream" "$forward_target"
        done
    fi
    echo -e "\n${CYAN}--- Other config sections ---${NC}"
    echo -e "Chains     : $(jq '.chains // [] | length' "$CONFIG_FILE")"
    echo -e "Bypasses   : $(jq '.bypasses // [] | length' "$CONFIG_FILE")"
    echo -e "Admissions : $(jq '.admissions // [] | length' "$CONFIG_FILE")"
    echo -e "Limiters   : $(jq '.limiters // [] | length' "$CONFIG_FILE")"
    echo -e "Resolvers  : $(jq '.resolvers // [] | length' "$CONFIG_FILE")"
    echo -e "Ingresses  : $(jq '.ingresses // [] | length' "$CONFIG_FILE")"
    echo -e "API        : $(jq -r '.api.addr // "off"' "$CONFIG_FILE")"
    echo -e "Metrics    : $(jq -r '.metrics.addr // "off"' "$CONFIG_FILE")"
    echo -e "Profiling  : $(jq -r '.profiling.addr // "off"' "$CONFIG_FILE")"
    echo -e "Config file: $CONFIG_FILE"
}

manage_service() {
    require_gost || return 1
    while true; do
        echo -e "\n${CYAN}--- System Service ---${NC}"
        echo -e "1) Status  2) Start  3) Stop  4) Restart  5) Logs  6) Back"
        read -p "Choice: " s_choice
        case $s_choice in
            1) systemctl status gost ;;
            2) systemctl start gost; echo -e "${GREEN}Started.${NC}" ;;
            3) systemctl stop gost; echo -e "${RED}Stopped.${NC}" ;;
            4) systemctl restart gost; echo -e "${GREEN}Restarted.${NC}" ;;
            5) echo -e "${CYAN}Ctrl+C to exit logs...${NC}"; journalctl -u gost -n 50 -f ;;
            6) break ;;
            *) echo -e "${RED}Invalid!${NC}" ;;
        esac
    done
}

uninstall_gost() {
    echo -e "${CYAN}--- Complete Uninstall ---${NC}"
    echo -e "${YELLOW}This removes binary, menu script, systemd unit, temp files,${NC}"
    echo -e "${YELLOW}AND /etc/gost (all tunnels, chains, policies, certs, API/metrics config).${NC}"
    read -p "Completely uninstall Wild GOST and wipe all related data? (y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "${YELLOW}Cancelled.${NC}"
        return 0
    fi

    echo -e "${CYAN}Stopping gost process...${NC}"
    if command -v systemctl &>/dev/null; then
        systemctl stop gost &>/dev/null || true
        systemctl kill gost &>/dev/null || true
        systemctl disable gost &>/dev/null || true
    fi
    # Force-kill leftover processes (service may have failed to stop)
    if command -v pkill &>/dev/null; then
        pkill -x gost &>/dev/null || true
        sleep 1
        pkill -9 -x gost &>/dev/null || true
    else
        # Fallback: kill by pattern if pkill is unavailable
        for pid in $(ps -eo pid,comm 2>/dev/null | awk '$2=="gost"{print $1}'); do
            kill "$pid" &>/dev/null || true
        done
        sleep 1
        for pid in $(ps -eo pid,comm 2>/dev/null | awk '$2=="gost"{print $1}'); do
            kill -9 "$pid" &>/dev/null || true
        done
    fi

    echo -e "${CYAN}Removing systemd unit and enable links...${NC}"
    rm -f /etc/systemd/system/gost.service
    rm -f /etc/systemd/system/multi-user.target.wants/gost.service
    rm -f /lib/systemd/system/gost.service
    rm -f /usr/lib/systemd/system/gost.service
    rm -rf /etc/systemd/system/gost.service.d
    if command -v systemctl &>/dev/null; then
        systemctl daemon-reload &>/dev/null || true
        systemctl reset-failed gost &>/dev/null || true
    fi

    echo -e "${CYAN}Removing binaries and menu commands...${NC}"
    rm -f /usr/local/bin/gost
    rm -f /usr/local/bin/gost-manage.sh
    rm -f /usr/local/bin/wild
    # Defensive: remove common alternate copies if present
    rm -f /usr/bin/gost-manage.sh /usr/bin/wild

    echo -e "${CYAN}Removing temporary files...${NC}"
    rm -f /tmp/gost_config_tmp.json
    rm -rf /tmp/gost_install
    rm -f /tmp/gost.tar.gz /tmp/gost_*.json 2>/dev/null || true

    echo -e "${CYAN}Removing configuration, tunnels, chains, policies, and certs...${NC}"
    # Always wipe /etc/gost so leftover tunnels/chains/bypass/admission/limiter/
    # resolvers/ingresses/api/metrics cannot survive uninstall.
    rm -rf /etc/gost

    echo -e "${CYAN}Verifying cleanup...${NC}"
    local leftover=0
    local path
    for path in \
        /usr/local/bin/gost \
        /usr/local/bin/gost-manage.sh \
        /usr/local/bin/wild \
        /etc/gost \
        /etc/systemd/system/gost.service \
        /etc/systemd/system/multi-user.target.wants/gost.service \
        /etc/systemd/system/gost.service.d \
        /tmp/gost_install \
        /tmp/gost_config_tmp.json
    do
        if [ -e "$path" ]; then
            echo -e "${RED}  Still present: $path${NC}"
            leftover=1
        fi
    done

    if command -v pgrep &>/dev/null && pgrep -x gost &>/dev/null; then
        echo -e "${RED}  gost process is still running${NC}"
        leftover=1
    fi

    if [ "$leftover" -eq 0 ]; then
        echo -e "${GREEN}Wild GOST was completely uninstalled. Nothing related remains.${NC}"
    else
        echo -e "${YELLOW}Uninstall finished, but some items could not be removed (see above).${NC}"
        echo -e "${YELLOW}Remove them manually if needed.${NC}"
    fi

    # Management script may have deleted itself from PATH; exit the stale menu.
    exit 0
}

show_raw_config() {
    require_gost || return 1
    echo -e "${CYAN}--- $CONFIG_FILE ---${NC}"
    jq . "$CONFIG_FILE" 2>/dev/null || cat "$CONFIG_FILE"
}

# ---------- main ----------

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
        echo -e "1) Install or Update GOST"
        echo -e "2) Add Service / Tunnel (all types)"
        echo -e "3) Remove a Service"
        echo -e "4) View Services & Config Summary"
        echo -e "5) Policies (Bypass / Admission / Limiter / API / Metrics)"
        echo -e "6) Manage System Service (Start/Stop/Logs)"
        echo -e "7) Show Raw Config JSON"
        echo -e "8) Completely Uninstall GOST"
        echo -e "9) Exit"
        echo -e "---------------------------------------------"
        read -p "Enter your choice (1-9): " choice
        case $choice in
            1) install_gost ;;
            2) add_service_menu ;;
            3) delete_tunnel ;;
            4) list_tunnels ;;
            5) manage_policies_menu ;;
            6) manage_service ;;
            7) show_raw_config ;;
            8) uninstall_gost ;;
            9) echo -e "${GREEN}Thanks for using Wild GOST. Bye!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid choice! Enter 1-9.${NC}" ;;
        esac
        echo -e "\nPress Enter to return to the menu..."
        read -r
        clear
    done
}

clear
main_menu
