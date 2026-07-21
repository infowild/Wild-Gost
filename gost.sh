#!/usr/bin/env bash

# Wild GOST management panel — wraps native GOST v3 JSON config.
# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

CONFIG_FILE="/etc/gost/config.json"
ANTIFILTER_STATE="/etc/gost/wild-antifilter.json"
DECOY_DIR="/var/www/wild-gost-decoy"
GH_MIRRORS=("")

# Shared wizard state
USERNAME=""
PASSWORD=""
LISTENER_TYPE="tcp"
DIALER_TYPE="tcp"
WS_PATH=""
WS_HOST=""
TRANSPORT_LABEL=""
TLS_CERT_FILE=""
TLS_KEY_FILE=""

if [[ "$EUID" -ne '0' ]]; then
    echo -e "${RED}Error: You must run this script as root (use sudo).${NC}"
    exit 1
fi

show_banner() {
    local ver=""
    if [ -x /usr/local/bin/gost ]; then
        ver=$(/usr/local/bin/gost -V 2>/dev/null | head -n1 | tr -d '\r' | cut -c1-48)
    fi
    echo ""
    echo -e "${CYAN}  ╭──────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}  │${NC}                                                      ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}   ${BOLD}${MAGENTA}██╗    ██╗██╗██╗     ██████╗${NC}                     ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}   ${BOLD}${MAGENTA}██║    ██║██║██║     ██╔══██╗${NC}                    ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}   ${BOLD}${MAGENTA}██║ █╗ ██║██║██║     ██║  ██║${NC}                    ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}   ${BOLD}${MAGENTA}██║███╗██║██║██║     ██║  ██║${NC}                    ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}   ${BOLD}${MAGENTA}╚███╔███╔╝██║███████╗██████╔╝${NC}                    ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}    ${BOLD}${MAGENTA}╚══╝╚══╝ ╚═╝╚══════╝╚═════╝${NC}                     ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}                                                      ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}      ${BOLD}${GREEN}██████╗  ██████╗ ███████╗████████╗${NC}            ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}     ${BOLD}${GREEN}██╔════╝ ██╔═══██╗██╔════╝╚══██╔══╝${NC}            ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}     ${BOLD}${GREEN}██║  ███╗██║   ██║███████╗   ██║${NC}               ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}     ${BOLD}${GREEN}██║   ██║██║   ██║╚════██║   ██║${NC}               ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}     ${BOLD}${GREEN}╚██████╔╝╚██████╔╝███████║   ██║${NC}               ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}      ${BOLD}${GREEN}╚═════╝  ╚═════╝ ╚══════╝   ╚═╝${NC}               ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}                                                      ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}   ${YELLOW}${BOLD}◆${NC} ${BOLD}Easy Tunnel Management${NC}                           ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}   ${DIM}GOST v3  ·  Anti-Filter  ·  Multi-location${NC}        ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}   ${DIM}github.com/infowild/Wild-Gost${NC}                     ${CYAN}│${NC}"
    echo -e "${CYAN}  │${NC}                                                      ${CYAN}│${NC}"
    echo -e "${CYAN}  ╰──────────────────────────────────────────────────────╯${NC}"
    if [ -n "$ver" ]; then
        echo -e "  ${BLUE}${ver}${NC}"
    fi
    echo ""
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

# Return 0 if user chose back/cancel (0, q, Q, b, B)
is_back_choice() {
    case "$1" in
        0|q|Q|b|B|back|Back) return 0 ;;
        *) return 1 ;;
    esac
}

# read into REPLY_VALUE; return 1 if user wants back
prompt_or_back() {
    local prompt="$1"
    REPLY_VALUE=""
    read -p "$prompt (0=Back): " REPLY_VALUE
    if is_back_choice "$REPLY_VALUE"; then
        echo -e "${YELLOW}Cancelled / going back.${NC}"
        return 1
    fi
    return 0
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

# Sanitize a display name into a GOST-safe id (letters/digits/._-).
sanitize_name() {
    local raw="$1"
    local out
    out=$(echo "$raw" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')
    [ -z "$out" ] && out="cfg"
    echo "$out"
}

prompt_config_name() {
    # Sets REPLY_VALUE to sanitized name. Arg1=prompt label, Arg2=optional default raw name.
    local label="${1:-Config name}"
    local def_raw="${2:-}"
    local raw slug
    if [ -n "$def_raw" ]; then
        prompt_or_back "$label [$def_raw]" || return 1
        raw="$REPLY_VALUE"
        [ -z "$raw" ] && raw="$def_raw"
    else
        prompt_or_back "$label (required, e.g. sanaei-home)" || return 1
        raw="$REPLY_VALUE"
    fi
    if [ -z "$raw" ]; then
        echo -e "${RED}Name cannot be empty!${NC}"
        return 1
    fi
    slug=$(sanitize_name "$raw")
    REPLY_VALUE="$slug"
    echo -e "${CYAN}Using id: ${YELLOW}$slug${NC}"
    return 0
}

build_chain_multi_nodes() {
    # $1 chain name, $2 nodes JSON array, $3 optional strategy (round|rand|fifo|hash)
    local chain_name="$1"
    local nodes_json="$2"
    local strategy="${3:-}"
    if [ -n "$strategy" ]; then
        jq -n --arg name "$chain_name" --argjson nodes "$nodes_json" --arg st "$strategy" \
            '{name: $name, hops: [{name: "hop-0", nodes: $nodes}], selector: {strategy: $st, maxFails: 1, failTimeout: "30s"}}'
    else
        jq -n --arg name "$chain_name" --argjson nodes "$nodes_json" \
            '{name: $name, hops: [{name: "hop-0", nodes: $nodes}]}'
    fi
}

build_chain_node_json() {
    # Build one hop node object. Args: node_name addr connector user pass dialer path host
    local node_name="$1" node_addr="$2" connector_type="$3" username="$4" password="$5"
    local dialer_type="${6:-tcp}" ws_path="${7:-}" ws_host="${8:-}"
    local dialer_json connector_json
    dialer_json=$(build_dialer_json "$dialer_type" "$ws_path" "$ws_host")
    if [ -n "$username" ] && [ -n "$password" ]; then
        connector_json=$(jq -n --arg t "$connector_type" --arg u "$username" --arg p "$password" \
            '{type: $t, auth: {username: $u, password: $p}}')
    else
        connector_json=$(jq -n --arg t "$connector_type" '{type: $t}')
    fi
    jq -n --arg n "$node_name" --arg a "$node_addr" --argjson c "$connector_json" --argjson d "$dialer_json" \
        '{name: $n, addr: $a, connector: $c, dialer: $d}'
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
    echo -e " 0) Back"
    read -p "Your choice (0-24) [default: 1]: " tchoice
    [ -z "$tchoice" ] && tchoice="1"
    is_back_choice "$tchoice" && return 1
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
    echo -e " 0) Back"
    read -p "Your choice (0-24) [default: 6]: " tchoice
    [ -z "$tchoice" ] && tchoice="6"
    is_back_choice "$tchoice" && return 1
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
    local cert="${3:-$TLS_CERT_FILE}"
    local key="${4:-$TLS_KEY_FILE}"
    local base
    case "$ltype" in
        ws|wss|mws|mwss)
            base=$(jq -n --arg t "$ltype" --arg p "${path:-/ws}" '{type: $t, metadata: {path: $p}}')
            ;;
        *)
            base=$(jq -n --arg t "$ltype" '{type: $t}')
            ;;
    esac
    case "$ltype" in
        tls|mtls|wss|mwss|https|http2|http3|h2|h3|quic|grpc|otls)
            if [ -n "$cert" ] && [ -n "$key" ] && [ -f "$cert" ] && [ -f "$key" ]; then
                echo "$base" | jq --arg c "$cert" --arg k "$key" '. + {tls: {certFile: $c, keyFile: $k}}'
                return 0
            fi
            ;;
    esac
    echo "$base"
}

build_dialer_json() {
    local dtype="$1"
    local path="$2"
    local host="$3"
    # Arg4 optional: "insecure" → tls.secure=false (default for anti-filter / self-signed)
    local insecure="${4:-}"
    case "$dtype" in
        tls|utls|mtls)
            if [ -n "$host" ]; then
                if [ "$insecure" = "insecure" ]; then
                    jq -n --arg t "$dtype" --arg h "$host" '{type: $t, tls: {serverName: $h, secure: false}}'
                else
                    jq -n --arg t "$dtype" --arg h "$host" '{type: $t, tls: {serverName: $h}}'
                fi
            else
                if [ "$insecure" = "insecure" ]; then
                    jq -n --arg t "$dtype" '{type: $t, tls: {secure: false}}'
                else
                    jq -n --arg t "$dtype" '{type: $t}'
                fi
            fi
            ;;
        ws|wss|mws|mwss)
            if [ "$insecure" = "insecure" ] && [[ "$dtype" == wss || "$dtype" == mwss ]]; then
                jq -n --arg t "$dtype" --arg p "${path:-/ws}" --arg h "$host" '
                    {type: $t,
                     metadata: ({path: $p} + (if $h != "" then {host: $h} else {} end)),
                     tls: ({secure: false} + (if $h != "" then {serverName: $h} else {} end))}
                '
            else
                jq -n --arg t "$dtype" --arg p "${path:-/ws}" --arg h "$host" '
                    {type: $t, metadata: ({path: $p} + (if $h != "" then {host: $h} else {} end))}
                '
            fi
            ;;
        grpc|quic|otls|http2|http3|h2|h3)
            if [ "$insecure" = "insecure" ]; then
                jq -n --arg t "$dtype" --arg h "$host" '
                    {type: $t, tls: ({secure: false} + (if $h != "" then {serverName: $h} else {} end))}
                '
            elif [ -n "$host" ]; then
                jq -n --arg t "$dtype" --arg h "$host" '{type: $t, tls: {serverName: $h}}'
            else
                jq -n --arg t "$dtype" '{type: $t}'
            fi
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
    echo -e "${CYAN}--- Add Proxy ---${NC}"
    echo -e " 1) SOCKS5     2) SOCKS4     3) HTTP       4) HTTP2"
    echo -e " 5) HTTP3      6) Relay      7) Shadowsocks 8) Auto"
    echo -e " 9) SNI       10) SSHD      11) MASQUE    12) Serial"
    echo -e " 0) Back"
    read -p "Choice: " pchoice
    is_back_choice "$pchoice" && return 0

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

    prompt_or_back "Listening port (e.g. 1080 or 443)" || return 0
    port="$REPLY_VALUE"
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
    echo -e "1) TCP  2) UDP  0) Back"
    read -p "Choice: " proto
    is_back_choice "$proto" && return 0
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
    echo -e "${YELLOW}Enter 0 at any prompt to go back.${NC}"
    local tunnel_port entry_port hostname tid name svc
    prompt_or_back "Tunnel listen port (e.g. 8421)" || return 0
    tunnel_port="$REPLY_VALUE"
    validate_listen_port "$tunnel_port" || return 1
    prompt_or_back "Public entrypoint port (e.g. 8420)" || return 0
    entry_port="$REPLY_VALUE"
    if [[ ! "$entry_port" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid entry port!${NC}"; return 1
    fi
    prompt_or_back "Ingress hostname (e.g. app.example.com)" || return 0
    hostname="$REPLY_VALUE"
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
    echo -e "${YELLOW}Enter 0 at any prompt to go back.${NC}"
    local tid server_addr target proto handler_type name svc chain_name
    prompt_or_back "Tunnel ID (UUID from server)" || return 0
    tid="$REPLY_VALUE"
    [ -z "$tid" ] && { echo -e "${RED}Tunnel ID required!${NC}"; return 1; }
    prompt_or_back "Public tunnel server host:port" || return 0
    server_addr="$REPLY_VALUE"
    [[ ! "$server_addr" =~ ^[^[:space:]:]+:[0-9]+$ ]] && { echo -e "${RED}Invalid address!${NC}"; return 1; }
    prompt_or_back "Local target to expose (host:port)" || return 0
    target="$REPLY_VALUE"
    [[ ! "$target" =~ ^[^[:space:]:]+:[0-9]+$ ]] && { echo -e "${RED}Invalid target!${NC}"; return 1; }
    echo -e "1) rtcp (TCP)  2) rudp (UDP)  0) Back"
    read -p "Choice: " proto
    is_back_choice "$proto" && return 0
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
    while true; do
        echo -e "\n${CYAN}--- Reverse Tunnel ---${NC}"
        echo -e "1) Server (public)"
        echo -e "2) Client (behind NAT)"
        echo -e "0) Back"
        read -p "Choice: " c
        case $c in
            1) setup_reverse_tunnel_server ;;
            2) setup_reverse_tunnel_client ;;
            0|q|Q|b|B) return 0 ;;
            *) echo -e "${RED}Invalid!${NC}" ;;
        esac
    done
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

# ---------- transport presets / TLS / decoy / anti-filter ----------

select_transport_preset() {
    LISTENER_TYPE="tcp"
    DIALER_TYPE="tcp"
    WS_PATH=""
    WS_HOST=""
    TRANSPORT_LABEL="Plain TCP"
    echo -e "\n${CYAN}Anti-DPI transport preset:${NC}"
    echo -e "1) MWSS   ${GREEN}(recommended — TLS+WS+mux)${NC}"
    echo -e "2) WSS    (TLS + WebSocket)"
    echo -e "3) TLS"
    echo -e "4) uTLS   (client fingerprint spoof; dialer=utls, listener=tls)"
    echo -e "5) otls   (obfs-TLS)"
    echo -e "6) KCP    (UDP + FEC, lossy links)"
    echo -e "7) QUIC"
    echo -e "8) gRPC"
    echo -e "9) TCP    (no encryption)"
    echo -e "10) Advanced (pick listener + dialer separately)"
    echo -e "0) Back"
    read -p "Choice [1]: " c
    [ -z "$c" ] && c="1"
    is_back_choice "$c" && return 1
    case $c in
        1) LISTENER_TYPE="mwss"; DIALER_TYPE="mwss"; TRANSPORT_LABEL="MWSS"
           read -p "WebSocket path [/ws]: " WS_PATH; [ -z "$WS_PATH" ] && WS_PATH="/ws"
           read -p "Host / SNI (optional): " WS_HOST ;;
        2) LISTENER_TYPE="wss"; DIALER_TYPE="wss"; TRANSPORT_LABEL="WSS"
           read -p "WebSocket path [/ws]: " WS_PATH; [ -z "$WS_PATH" ] && WS_PATH="/ws"
           read -p "Host / SNI (optional): " WS_HOST ;;
        3) LISTENER_TYPE="tls"; DIALER_TYPE="tls"; TRANSPORT_LABEL="TLS"
           read -p "SNI / serverName (optional): " WS_HOST ;;
        4) LISTENER_TYPE="tls"; DIALER_TYPE="utls"; TRANSPORT_LABEL="uTLS"
           read -p "SNI / serverName (optional): " WS_HOST ;;
        5) LISTENER_TYPE="otls"; DIALER_TYPE="otls"; TRANSPORT_LABEL="obfs-TLS" ;;
        6) LISTENER_TYPE="kcp"; DIALER_TYPE="kcp"; TRANSPORT_LABEL="KCP" ;;
        7) LISTENER_TYPE="quic"; DIALER_TYPE="quic"; TRANSPORT_LABEL="QUIC" ;;
        8) LISTENER_TYPE="grpc"; DIALER_TYPE="grpc"; TRANSPORT_LABEL="gRPC"
           read -p "SNI / serverName (optional): " WS_HOST ;;
        9) LISTENER_TYPE="tcp"; DIALER_TYPE="tcp"; TRANSPORT_LABEL="Plain TCP" ;;
        10)
           select_listener_transport || return 1
           select_dialer_transport || return 1
           TRANSPORT_LABEL="${LISTENER_TYPE}/${DIALER_TYPE}"
           ;;
        *) echo -e "${RED}Invalid!${NC}"; return 1 ;;
    esac
    return 0
}

prompt_tls_certs() {
    # Sets TLS_CERT_FILE / TLS_KEY_FILE. Arg1=domain for CN when generating.
    local domain="${1:-localhost}"
    local choice cert_dir
    TLS_CERT_FILE=""
    TLS_KEY_FILE=""
    echo -e "\n${CYAN}TLS certificate:${NC}"
    echo -e "1) Provide existing cert/key paths"
    echo -e "2) Generate self-signed (quick test)"
    echo -e "3) Skip (GOST auto / plain)"
    echo -e "0) Back"
    read -p "Choice [1]: " choice
    [ -z "$choice" ] && choice="1"
    is_back_choice "$choice" && return 1
    case $choice in
        1)
            prompt_or_back "Fullchain / cert.pem path" || return 1
            TLS_CERT_FILE="$REPLY_VALUE"
            prompt_or_back "Private key path" || return 1
            TLS_KEY_FILE="$REPLY_VALUE"
            if [ ! -f "$TLS_CERT_FILE" ] || [ ! -f "$TLS_KEY_FILE" ]; then
                echo -e "${RED}Cert or key file not found.${NC}"
                return 1
            fi
            ;;
        2)
            if ! command -v openssl &>/dev/null; then
                echo -e "${RED}openssl not found.${NC}"
                return 1
            fi
            cert_dir="/etc/gost/certs"
            mkdir -p "$cert_dir"
            TLS_CERT_FILE="$cert_dir/${domain}.crt"
            TLS_KEY_FILE="$cert_dir/${domain}.key"
            openssl req -x509 -newkey rsa:2048 -sha256 -days 825 -nodes \
                -keyout "$TLS_KEY_FILE" -out "$TLS_CERT_FILE" \
                -subj "/CN=$domain" \
                -addext "subjectAltName=DNS:$domain,DNS:*.$domain" 2>/dev/null \
            || openssl req -x509 -newkey rsa:2048 -sha256 -days 825 -nodes \
                -keyout "$TLS_KEY_FILE" -out "$TLS_CERT_FILE" \
                -subj "/CN=$domain"
            chmod 600 "$TLS_KEY_FILE"
            echo -e "${GREEN}Self-signed cert written to $TLS_CERT_FILE${NC}"
            ;;
        3) ;;
        *) echo -e "${RED}Invalid!${NC}"; return 1 ;;
    esac
    return 0
}

ensure_decoy_site() {
    local dir="${1:-$DECOY_DIR}"
    mkdir -p "$dir"
    if [ ! -f "$dir/index.html" ]; then
        cat > "$dir/index.html" <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Welcome</title>
  <style>
    body { font-family: Georgia, serif; max-width: 42rem; margin: 4rem auto; padding: 0 1.25rem;
           color: #1a1a1a; background: #f7f5f0; line-height: 1.6; }
    h1 { font-weight: 400; letter-spacing: 0.02em; }
    p { color: #444; }
    footer { margin-top: 3rem; font-size: 0.85rem; color: #888; }
  </style>
</head>
<body>
  <h1>It works</h1>
  <p>This site is under construction. Please check back later.</p>
  <footer>&copy; 2026</footer>
</body>
</html>
HTML
    fi
    echo "$dir"
}

save_antifilter_state() {
    local json="$1"
    mkdir -p "$(dirname "$ANTIFILTER_STATE")"
    echo "$json" | jq . > "$ANTIFILTER_STATE"
}

load_antifilter_state() {
    if [ -f "$ANTIFILTER_STATE" ]; then
        cat "$ANTIFILTER_STATE"
    else
        echo '{}'
    fi
}

print_foreign_node_oneliner() {
    local iran_addr="$1" tid="$2" transport="$3" path="$4" host="$5" target="$6" name="$7"
    echo -e "\n${CYAN}── Foreign node one-liner (run on exit server) ──${NC}"
    echo -e "${YELLOW}sudo wild gost${NC}  →  Add  →  Anti-Filter  →  Foreign node"
    echo -e "  Name       : ${GREEN}${name}${NC}"
    echo -e "  Iran addr  : ${GREEN}${iran_addr}${NC}"
    echo -e "  Tunnel ID  : ${GREEN}${tid}${NC}"
    echo -e "  Transport  : ${GREEN}${transport}${NC}"
    [ -n "$path" ] && echo -e "  WS path    : ${GREEN}${path}${NC}"
    [ -n "$host" ] && echo -e "  SNI/Host   : ${GREEN}${host}${NC}"
    echo -e "  Local target (Xray inbound): ${GREEN}${target}${NC}"
}

setup_decoy_service() {
    require_gost || return 1
    echo -e "${CYAN}--- Decoy / Fake Website ---${NC}"
    echo -e "Serves a normal-looking site so active probes see a webpage, not a proxy."
    local port mode dir name svc handler_json listener_json decoy_file knock user pass
    local decoy_dir
    decoy_dir=$(ensure_decoy_site)
    decoy_file="$decoy_dir/index.html"

    echo -e "1) File server (plain decoy site)"
    echo -e "2) HTTP proxy + probeResist file (needs auth; probe sees decoy HTML)"
    echo -e "3) HTTP proxy + probeResist code:404"
    echo -e "0) Back"
    read -p "Choice [1]: " mode
    [ -z "$mode" ] && mode="1"
    is_back_choice "$mode" && return 0

    prompt_or_back "Listen port [80]" || return 0
    port="$REPLY_VALUE"
    [ -z "$port" ] && port="80"
    validate_listen_port "$port" || return 1

    prompt_tls_certs "decoy.local" || return 0
    if [ -n "$TLS_CERT_FILE" ]; then
        LISTENER_TYPE="tls"
        TRANSPORT_LABEL="TLS"
    else
        LISTENER_TYPE="tcp"
        TRANSPORT_LABEL="TCP"
    fi

    case $mode in
        1)
            name="decoy-file-$port"
            handler_json=$(build_handler_json "file" "" "" "$(jq -n --arg d "$decoy_dir" '{dir: $d}')")
            ;;
        2|3)
            prompt_auth || return 1
            if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
                user="wild"; pass=$(openssl rand -hex 8 2>/dev/null || echo "changeme")
                USERNAME="$user"; PASSWORD="$pass"
                echo -e "${YELLOW}Auto auth: ${USERNAME} / ${PASSWORD}${NC}"
            fi
            read -p "Knock host for real 407 (optional, e.g. knock.local): " knock
            local meta
            if [ "$mode" = "2" ]; then
                meta=$(jq -n --arg pr "file:$decoy_file" --arg k "$knock" \
                    '{probeResist: $pr} + (if $k != "" then {knock: $k} else {} end)')
            else
                meta=$(jq -n --arg k "$knock" \
                    '{probeResist: "code:404"} + (if $k != "" then {knock: $k} else {} end)')
            fi
            name="decoy-http-$port"
            handler_json=$(build_handler_json "http" "$USERNAME" "$PASSWORD" "$meta")
            ;;
        *) echo -e "${RED}Invalid!${NC}"; return 1 ;;
    esac

    listener_json=$(build_listener_json "$LISTENER_TYPE" "" "$TLS_CERT_FILE" "$TLS_KEY_FILE")
    svc=$(jq -n --arg n "$name" --arg a ":$port" --argjson h "$handler_json" --argjson l "$listener_json" \
        --arg role "decoy" \
        '{name:$n,addr:$a,handler:$h,listener:$l,metadata:{role:$role}}')
    append_service "$svc"
    restart_gost
    echo -e "${GREEN}Decoy ready on :$port ($TRANSPORT_LABEL) → $decoy_dir${NC}"
}

setup_antifilter_iran_panel() {
    require_gost || return 1
    echo -e "${CYAN}--- Anti-Filter: Iran Panel (reverse) ---${NC}"
    echo -e "Foreign nodes dial THIS server. Users hit entry :443 by hostname/SNI."
    echo -e "Only Iran IP/domain is public — exit IPs stay hidden."
    echo -e "${YELLOW}Enter 0 at any prompt to go back.${NC}"

    if [ -f "$ANTIFILTER_STATE" ] && [ "$(jq -r '.role // empty' "$ANTIFILTER_STATE")" = "iran-panel" ]; then
        echo -e "${YELLOW}Existing panel state found. Continue will keep adding on top of config.${NC}"
        read -p "Continue anyway? (y/n) [y]: " cont
        [ -z "$cont" ] && cont="y"
        [ "$cont" != "y" ] && [ "$cont" != "Y" ] && return 0
    fi

    local domain tunnel_port entry_port decoy_port ingress_name tunnel_name decoy_name
    local tid node_name hostname target first_node_json state listener_json svc ingress decoy_dir
    local public_ip

    prompt_or_back "Panel domain (e.g. panel.example.com)" || return 0
    domain="$REPLY_VALUE"
    [ -z "$domain" ] && { echo -e "${RED}Domain required.${NC}"; return 1; }

    prompt_or_back "Tunnel control port (nodes dial this) [8443]" || return 0
    tunnel_port="$REPLY_VALUE"
    [ -z "$tunnel_port" ] && tunnel_port="8443"
    validate_listen_port "$tunnel_port" || return 1

    prompt_or_back "User entrypoint port [443]" || return 0
    entry_port="$REPLY_VALUE"
    [ -z "$entry_port" ] && entry_port="443"
    if [[ ! "$entry_port" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid entry port!${NC}"; return 1
    fi

    select_transport_preset || return 1
    echo -e "${YELLOW}Tip: if tunnel fails first time, rebuild both sides with TCP (preset 9), verify, then MWSS.${NC}"
    prompt_tls_certs "$domain" || return 0

    echo -e "\n${CYAN}Decoy website (recommended)${NC}"
    read -p "Enable decoy file server on port 80? (y/n) [y]: " want_decoy
    [ -z "$want_decoy" ] && want_decoy="y"
    decoy_port=""
    decoy_dir=$(ensure_decoy_site)

    # First node
    echo -e "\n${CYAN}First foreign node${NC}"
    prompt_config_name "Node name" "trk01" || return 0
    node_name="$REPLY_VALUE"
    hostname="${node_name}.${domain}"
    read -p "Hostname / SNI for this node [$hostname]: " hn
    [ -n "$hn" ] && hostname="$hn"
    prompt_or_back "Hint: Xray inbound on node (e.g. 127.0.0.1:2087) [127.0.0.1:2087]" || return 0
    target="$REPLY_VALUE"
    [ -z "$target" ] && target="127.0.0.1:2087"
    tid=$(gen_uuid)

    ingress_name="ingress-antifilter"
    tunnel_name="antifilter-tunnel"

    # Remove old antifilter objects with same names if re-run
    jq --arg ing "$ingress_name" --arg tn "$tunnel_name" \
        'del(.ingresses[]? | select(.name==$ing))
         | del(.services[]? | select(.name==$tn or (.metadata.role? == "antifilter-decoy")))' \
        "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"

    ingress=$(jq -n --arg n "$ingress_name" --arg h "$hostname" --arg e "$tid" \
        '{name: $n, rules: [{hostname: $h, endpoint: $e}]}')
    append_named_array "ingresses" "$ingress"

    listener_json=$(build_listener_json "$LISTENER_TYPE" "$WS_PATH" "$TLS_CERT_FILE" "$TLS_KEY_FILE")
    svc=$(jq -n \
        --arg n "$tunnel_name" --arg a ":$tunnel_port" --arg ep ":$entry_port" \
        --arg ing "$ingress_name" --argjson l "$listener_json" \
        --arg domain "$domain" --arg tr "$TRANSPORT_LABEL" \
        '{name:$n,addr:$a,handler:{type:"tunnel",metadata:{entrypoint:$ep,ingress:$ing}},listener:$l,
          metadata:{role:"antifilter-panel",domain:$domain,transport:$tr}}')
    append_service "$svc"

    if [ "$want_decoy" = "y" ] || [ "$want_decoy" = "Y" ]; then
        decoy_port="80"
        local port_busy
        port_busy=$(jq -r --arg p ":$decoy_port" '.services[]? | select(.addr == $p) | .name' "$CONFIG_FILE")
        if [ -z "$port_busy" ]; then
            decoy_name="antifilter-decoy-80"
            local dh dl
            dh=$(build_handler_json "file" "" "" "$(jq -n --arg d "$decoy_dir" '{dir: $d}')")
            dl=$(jq -n '{type:"tcp"}')
            svc=$(jq -n --arg n "$decoy_name" --arg a ":$decoy_port" --argjson h "$dh" --argjson l "$dl" \
                '{name:$n,addr:$a,handler:$h,listener:$l,metadata:{role:"antifilter-decoy"}}')
            append_service "$svc"
        else
            echo -e "${YELLOW}:80 already used by $port_busy — skip decoy listener (site still at $decoy_dir).${NC}"
            decoy_port=""
        fi
    fi

    first_node_json=$(jq -n --arg name "$node_name" --arg host "$hostname" --arg id "$tid" --arg t "$target" \
        '{name:$name,hostname:$host,tunnel_id:$id,target:$t}')

    public_ip=$(curl -4 -fsS --connect-timeout 5 ifconfig.me 2>/dev/null || curl -4 -fsS --connect-timeout 5 icanhazip.com 2>/dev/null || echo "<IRAN_IP>")

    state=$(jq -n \
        --arg role "iran-panel" --arg domain "$domain" \
        --argjson tport "$tunnel_port" --argjson eport "$entry_port" \
        --arg ingress "$ingress_name" --arg tunnel "$tunnel_name" \
        --arg tr "$TRANSPORT_LABEL" --arg lt "$LISTENER_TYPE" --arg dt "$DIALER_TYPE" \
        --arg path "$WS_PATH" --arg host "$WS_HOST" \
        --arg cert "$TLS_CERT_FILE" --arg key "$TLS_KEY_FILE" \
        --arg decoy "$decoy_dir" --arg dport "$decoy_port" \
        --arg ip "$public_ip" --argjson node "$first_node_json" \
        '{role:$role,domain:$domain,tunnel_port:$tport,entry_port:$eport,
          ingress:$ingress,tunnel_service:$tunnel,transport:$tr,
          listener:$lt,dialer:$dt,ws_path:$path,ws_host:$host,
          cert_file:$cert,key_file:$key,decoy_dir:$decoy,decoy_port:$dport,
          public_ip:$ip,nodes:[$node]}')
    save_antifilter_state "$state"
    restart_gost

    echo -e "\n${GREEN}Iran panel ready.${NC}"
    echo -e "  Domain       : ${YELLOW}$domain${NC}"
    echo -e "  Tunnel       : ${YELLOW}${public_ip}:$tunnel_port${NC} ($TRANSPORT_LABEL)"
    echo -e "  User entry   : ${YELLOW}:$entry_port${NC} (SNI/Host → node)"
    echo -e "  First node   : ${YELLOW}$node_name${NC} → hostname ${YELLOW}$hostname${NC}"
    [ -n "$decoy_port" ] && echo -e "  Decoy        : ${YELLOW}:$decoy_port${NC} → $decoy_dir"
    print_foreign_node_oneliner "${public_ip}:${tunnel_port}" "$tid" "$TRANSPORT_LABEL" "$WS_PATH" "${WS_HOST:-$domain}" "$target" "$node_name"
    echo -e "\n${DIM}Users connect to hostname $hostname on :$entry_port (TLS/HTTP with SNI).${NC}"
    echo -e "${DIM}Add more nodes: Add → Anti-Filter → Add node to panel${NC}"
}

setup_antifilter_add_node() {
    require_gost || return 1
    if [ ! -f "$ANTIFILTER_STATE" ] || [ "$(jq -r '.role // empty' "$ANTIFILTER_STATE")" != "iran-panel" ]; then
        echo -e "${RED}No Iran panel state. Run 'Iran panel' first.${NC}"
        return 1
    fi
    echo -e "${CYAN}--- Anti-Filter: Add node to Iran panel ---${NC}"
    local domain ingress_name node_name hostname tid target state node_json public_ip tunnel_port
    local transport path host

    domain=$(jq -r '.domain' "$ANTIFILTER_STATE")
    ingress_name=$(jq -r '.ingress' "$ANTIFILTER_STATE")
    tunnel_port=$(jq -r '.tunnel_port' "$ANTIFILTER_STATE")
    public_ip=$(jq -r '.public_ip // "<IRAN_IP>"' "$ANTIFILTER_STATE")
    transport=$(jq -r '.transport' "$ANTIFILTER_STATE")
    path=$(jq -r '.ws_path // empty' "$ANTIFILTER_STATE")
    host=$(jq -r '.ws_host // empty' "$ANTIFILTER_STATE")
    [ -z "$host" ] && host="$domain"

    prompt_config_name "Node name" || return 0
    node_name="$REPLY_VALUE"
    hostname="${node_name}.${domain}"
    read -p "Hostname / SNI [$hostname]: " hn
    [ -n "$hn" ] && hostname="$hn"
    prompt_or_back "Xray inbound hint on node [127.0.0.1:2087]" || return 0
    target="$REPLY_VALUE"
    [ -z "$target" ] && target="127.0.0.1:2087"
    tid=$(gen_uuid)

    if ! jq -e --arg n "$ingress_name" '.ingresses[]? | select(.name==$n)' "$CONFIG_FILE" >/dev/null; then
        echo -e "${RED}Ingress $ingress_name missing from config.json${NC}"
        return 1
    fi

    jq --arg n "$ingress_name" --arg h "$hostname" --arg e "$tid" \
        '(.ingresses[] | select(.name==$n) | .rules) += [{hostname:$h, endpoint:$e}]' \
        "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"

    node_json=$(jq -n --arg name "$node_name" --arg host "$hostname" --arg id "$tid" --arg t "$target" \
        '{name:$name,hostname:$host,tunnel_id:$id,target:$t}')
    state=$(jq --argjson node "$node_json" '.nodes += [$node]' "$ANTIFILTER_STATE")
    save_antifilter_state "$state"
    restart_gost

    echo -e "${GREEN}Node $node_name added → $hostname${NC}"
    print_foreign_node_oneliner "${public_ip}:${tunnel_port}" "$tid" "$transport" "$path" "$host" "$target" "$node_name"
}

setup_antifilter_foreign_node() {
    require_gost || return 1
    echo -e "${CYAN}--- Anti-Filter: Foreign node (reverse client) ---${NC}"
    echo -e "This server dials Iran. No public port needed on this host."
    echo -e "${YELLOW}Enter 0 at any prompt to go back.${NC}"

    local name tid server_addr target chain_name svc ch path host

    prompt_config_name "Node name" "node" || return 0
    name="$REPLY_VALUE"
    prompt_or_back "Tunnel ID (UUID from Iran panel)" || return 0
    tid="$REPLY_VALUE"
    [ -z "$tid" ] && { echo -e "${RED}Tunnel ID required!${NC}"; return 1; }
    prompt_or_back "Iran tunnel address (IP_or_host:port)" || return 0
    server_addr="$REPLY_VALUE"
    [[ ! "$server_addr" =~ ^[^[:space:]:]+:[0-9]+$ ]] && { echo -e "${RED}Invalid address!${NC}"; return 1; }
    prompt_or_back "Local target to expose (e.g. 127.0.0.1:2087)" || return 0
    target="$REPLY_VALUE"
    [[ ! "$target" =~ ^[^[:space:]:]+:[0-9]+$ ]] && { echo -e "${RED}Invalid target!${NC}"; return 1; }

    echo -e "\n${CYAN}Transport must match Iran panel${NC}"
    echo -e "${YELLOW}Tip: for first test use TCP (option 9). Then switch to MWSS.${NC}"
    select_transport_preset || return 1
    path="$WS_PATH"
    host="$WS_HOST"
    if [ -z "$host" ]; then
        read -p "SNI / Host for TLS (Iran domain, recommended if dialing by IP): " host
        WS_HOST="$host"
    fi

    # Remove previous antifilter node with same name to avoid duplicates
    jq --arg n "antifilter-node-$name" --arg c "chain-antifilter-$name" \
        'del(.services[]? | select(.name==$n)) | del(.chains[]? | select(.name==$c))' \
        "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"

    chain_name="chain-antifilter-$name"
    ch=$(jq -n --arg n "$chain_name" --arg addr "$server_addr" --arg tid "$tid" \
        --argjson dialer "$(build_dialer_json "$DIALER_TYPE" "$path" "$host" "insecure")" \
        '{name:$n,hops:[{name:"hop-0",nodes:[{name:"node-0",addr:$addr,
          connector:{type:"tunnel",metadata:{"tunnel.id":$tid}},dialer:$dialer}]}]}')
    append_chain "$ch"

    svc=$(jq -n --arg n "antifilter-node-$name" --arg c "$chain_name" --arg t "$target" \
        --arg tid "$tid" --arg addr "$server_addr" \
        '{name:$n,addr:":0",handler:{type:"rtcp"},listener:{type:"rtcp",chain:$c},
          forwarder:{nodes:[{name:"target",addr:$t}]},
          metadata:{role:"antifilter-node",tunnel_id:$tid,iran:$addr}}')
    append_service "$svc"

    local node_state
    node_state=$(jq -n --arg role "foreign-node" --arg name "$name" --arg tid "$tid" \
        --arg iran "$server_addr" --arg t "$target" --arg tr "$TRANSPORT_LABEL" \
        --arg path "$path" --arg host "$host" \
        '{role:$role,name:$name,tunnel_id:$tid,iran:$iran,target:$t,transport:$tr,ws_path:$path,ws_host:$host}')
    if [ ! -f "$ANTIFILTER_STATE" ] || [ "$(jq -r '.role // empty' "$ANTIFILTER_STATE")" != "iran-panel" ]; then
        save_antifilter_state "$node_state"
    fi

    restart_gost
    echo -e "${GREEN}Foreign node '$name' started → exposes $target via reverse tunnel.${NC}"
    echo -e "${DIM}Ensure local Xray/proxy is listening on $target.${NC}"
    echo -e "${YELLOW}Check logs: journalctl -u gost -n 50 --no-pager${NC}"
    echo -e "${YELLOW}If tunnel fails, run Anti-Filter → Doctor on both servers.${NC}"
}

setup_antifilter_doctor() {
    require_gost || return 1
    echo -e "${CYAN}--- Anti-Filter Doctor ---${NC}"
    local role iran_addr tunnel_port entry_port tid target hostname domain
    echo -e "1) This is Iran panel"
    echo -e "2) This is Foreign node"
    echo -e "0) Back"
    read -p "Choice: " side
    is_back_choice "$side" && return 0

    echo -e "\n${CYAN}[1] Service status${NC}"
    systemctl is-active gost 2>/dev/null || echo "gost not active"
    systemctl is-active gost --quiet 2>/dev/null && echo -e "${GREEN}gost: active${NC}" || echo -e "${RED}gost: NOT active${NC}"

    echo -e "\n${CYAN}[2] Config / state${NC}"
    if [ -f "$ANTIFILTER_STATE" ]; then
        jq -C . "$ANTIFILTER_STATE" 2>/dev/null || cat "$ANTIFILTER_STATE"
        role=$(jq -r '.role // empty' "$ANTIFILTER_STATE")
    else
        echo -e "${YELLOW}No $ANTIFILTER_STATE${NC}"
        role=""
    fi

    echo -e "\n${CYAN}[3] Listening ports (gost-related)${NC}"
    ss -lntp 2>/dev/null | grep -E 'gost|:443|:8443|:80 ' || netstat -lntp 2>/dev/null | grep gost || true

    echo -e "\n${CYAN}[4] Recent gost errors${NC}"
    journalctl -u gost -n 40 --no-pager 2>/dev/null | tail -n 40

    if [ "$side" = "1" ]; then
        tunnel_port=$(jq -r '.tunnel_port // 8443' "$ANTIFILTER_STATE" 2>/dev/null)
        entry_port=$(jq -r '.entry_port // 443' "$ANTIFILTER_STATE" 2>/dev/null)
        domain=$(jq -r '.domain // empty' "$ANTIFILTER_STATE" 2>/dev/null)
        echo -e "\n${CYAN}[5] Iran checks${NC}"
        echo -e "Tunnel port should be public: $tunnel_port"
        echo -e "Entry port (user SNI): $entry_port"
        echo -e "Ingress rules:"
        jq -r '.ingresses[]? | .rules[]? | "  \(.hostname) -> \(.endpoint)"' "$CONFIG_FILE" 2>/dev/null
        echo -e "\nFrom FOREIGN node test:  ${YELLOW}nc -vz <IRAN_IP> $tunnel_port${NC}"
        echo -e "User must connect with SNI/Host equal to an ingress hostname (e.g. trk01.$domain)."
    elif [ "$side" = "2" ]; then
        iran_addr=$(jq -r '.iran // empty' "$ANTIFILTER_STATE" 2>/dev/null)
        tid=$(jq -r '.tunnel_id // empty' "$ANTIFILTER_STATE" 2>/dev/null)
        target=$(jq -r '.target // empty' "$ANTIFILTER_STATE" 2>/dev/null)
        [ -z "$iran_addr" ] && iran_addr=$(jq -r '.services[]? | select(.metadata.role=="antifilter-node") | .metadata.iran // empty' "$CONFIG_FILE" | head -n1)
        [ -z "$tid" ] && tid=$(jq -r '.chains[]? | select(.name|startswith("chain-antifilter")) | .hops[0].nodes[0].connector.metadata["tunnel.id"] // empty' "$CONFIG_FILE" | head -n1)
        [ -z "$target" ] && target=$(jq -r '.services[]? | select(.metadata.role=="antifilter-node") | .forwarder.nodes[0].addr // empty' "$CONFIG_FILE" | head -n1)

        echo -e "\n${CYAN}[5] Foreign node checks${NC}"
        echo -e "Iran addr : ${YELLOW}${iran_addr:-unknown}${NC}"
        echo -e "Tunnel ID : ${YELLOW}${tid:-unknown}${NC}"
        echo -e "Local tgt : ${YELLOW}${target:-unknown}${NC}"

        if [ -n "$iran_addr" ]; then
            local hip hport
            hip="${iran_addr%:*}"; hport="${iran_addr##*:}"
            echo -e "\nConnectivity to Iran tunnel port:"
            if command -v nc &>/dev/null; then
                nc -vz -w 5 "$hip" "$hport" 2>&1 || true
            else
                timeout 5 bash -c "echo >/dev/tcp/$hip/$hport" 2>&1 && echo "TCP OK" || echo -e "${RED}TCP FAIL to $hip:$hport${NC}"
            fi
        fi
        if [ -n "$target" ]; then
            local tip tport
            tip="${target%:*}"; tport="${target##*:}"
            echo -e "\nLocal target listening?"
            ss -lntp 2>/dev/null | grep -E ":$tport\\b" || echo -e "${RED}Nothing listening on $target — start Xray/proxy there${NC}"
        fi
        echo -e "\nDialer in config:"
        jq -c '.chains[]? | select(.name|startswith("chain-antifilter")) | .hops[0].nodes[0].dialer' "$CONFIG_FILE" 2>/dev/null
    fi

    echo -e "\n${CYAN}[6] Common fixes${NC}"
    echo -e " • Transport Iran == Foreign (start with TCP to verify reverse, then MWSS)"
    echo -e " • Tunnel ID must match an ingress endpoint on Iran"
    echo -e " • Firewall: allow Iran tunnel port (default 8443) from foreign IP"
    echo -e " • User SNI/Host must match ingress hostname (not path like /trk01)"
    echo -e " • If dialing Iran by IP + TLS/MWSS: set SNI to panel domain"
    echo -e " • Local target (Xray) must be up on foreign node before testing users"
    echo -e "\n${YELLOW}Paste this Doctor output here if still broken.${NC}"
}

setup_antifilter_status() {
    echo -e "${CYAN}--- Anti-Filter status ---${NC}"
    if [ ! -f "$ANTIFILTER_STATE" ]; then
        echo -e "${YELLOW}No anti-filter state file ($ANTIFILTER_STATE).${NC}"
        return 0
    fi
    jq -C . "$ANTIFILTER_STATE" 2>/dev/null || cat "$ANTIFILTER_STATE"
    echo ""
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${CYAN}Config services with antifilter role:${NC}"
        jq -r '.services[]? | select(.metadata.role? | tostring | startswith("antifilter")) | "  - \(.name)  \(.addr)  \(.metadata.role)"' "$CONFIG_FILE"
        echo -e "${CYAN}Ingress rules:${NC}"
        jq -r '.ingresses[]? | select(.name|test("antifilter")) | .rules[]? | "  - \(.hostname) → \(.endpoint)"' "$CONFIG_FILE"
    fi
}

setup_antifilter_menu() {
    while true; do
        echo -e "\n${CYAN}--- Anti-Filter (Iran reverse) ---${NC}"
        echo -e "${GREEN}1) Iran panel${NC}     — reverse server + entry :443 + decoy"
        echo -e "${GREEN}2) Add node${NC}       — hostname/SNI → new foreign tunnel"
        echo -e "${GREEN}3) Foreign node${NC}   — exit server dials Iran (no public port)"
        echo -e "4) Decoy site only"
        echo -e "5) Status"
        echo -e "${YELLOW}6) Doctor${NC}         — diagnose broken tunnel"
        echo -e "0) Back"
        read -p "Choice: " c
        case $c in
            1) setup_antifilter_iran_panel ;;
            2) setup_antifilter_add_node ;;
            3) setup_antifilter_foreign_node ;;
            4) setup_decoy_service ;;
            5) setup_antifilter_status ;;
            6) setup_antifilter_doctor ;;
            0|q|Q|b|B) return 0 ;;
            *) echo -e "${RED}Invalid!${NC}" ;;
        esac
    done
}

# ---------- remote port forward (kept / enhanced) ----------

# (select_transport_preset defined above in anti-filter section)

setup_remote_port_forward_upstream() {
    require_gost || return 1
    echo -e "${CYAN}--- Add Upstream (Server B) ---${NC}"
    local port handler_choice handler_type udp_enabled name svc meta="" loc_label
    prompt_config_name "Name" "upstream" || return 0
    name="$REPLY_VALUE"
    prompt_or_back "Listen port (e.g. 443)" || return 0
    port="$REPLY_VALUE"
    validate_listen_port "$port" || return 1
    echo -e "1) Relay  2) SOCKS5  3) HTTP  0) Back"
    read -p "Choice [1]: " handler_choice
    [ -z "$handler_choice" ] && handler_choice="1"
    is_back_choice "$handler_choice" && return 0
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
        read -p "Enable UDP? (y/n) [n]: " udp_enabled
        if [ "$udp_enabled" = "y" ] || [ "$udp_enabled" = "Y" ]; then
            meta='{"udp":true}'
        fi
    fi
    if [ "$handler_type" = "relay" ] || [ "$handler_type" = "socks5" ]; then
        local bind_en
        read -p "Enable BIND? (y/n) [n]: " bind_en
        if [ "$bind_en" = "y" ] || [ "$bind_en" = "Y" ]; then
            if [ -n "$meta" ]; then meta=$(echo "$meta" | jq '. + {bind: true}'); else meta='{"bind":true}'; fi
        fi
    fi
    loc_label="$name"
    name="${loc_label}-${handler_type}-${LISTENER_TYPE}-${port}"
    local handler_json listener_json
    handler_json=$(build_handler_json "$handler_type" "$USERNAME" "$PASSWORD" "$meta")
    listener_json=$(build_listener_json "$LISTENER_TYPE" "$WS_PATH")
    svc=$(jq -n --arg n "$name" --arg a ":$port" --argjson h "$handler_json" --argjson l "$listener_json" \
        --arg loc "$loc_label" \
        '{name:$n,addr:$a,handler:$h,listener:$l,metadata:{wildName:$loc,role:"upstream"}}')
    append_service "$svc"
    restart_gost
    echo -e "${GREEN}Upstream '$loc_label' on :$port ($TRANSPORT_LABEL)${NC}"
}

setup_remote_port_forward_entry() {
    require_gost || return 1
    echo -e "${CYAN}--- Add Entry (Server A, single) ---${NC}"
    local port proto handler_type listener_type connector_type upstream_addr target name chain_name svc ch
    prompt_config_name "Name" "entry" || return 0
    name="$REPLY_VALUE"
    prompt_or_back "Listen port" || return 0
    port="$REPLY_VALUE"
    validate_listen_port "$port" || return 1
    echo -e "1) TCP  2) UDP  0) Back"
    read -p "Choice [1]: " proto
    [ -z "$proto" ] && proto="1"
    is_back_choice "$proto" && return 0
    case $proto in
        1) handler_type="tcp"; listener_type="tcp" ;;
        2) handler_type="udp"; listener_type="udp" ;;
        *) echo -e "${RED}Invalid!${NC}"; return 1 ;;
    esac
    echo -e "Connector: 1) relay  2) socks5  3) http  0) Back"
    read -p "Choice [1]: " c
    [ -z "$c" ] && c="1"
    is_back_choice "$c" && return 0
    case $c in
        1) connector_type="relay" ;;
        2) connector_type="socks5" ;;
        3) connector_type="http" ;;
        *) echo -e "${RED}Invalid!${NC}"; return 1 ;;
    esac
    select_transport_preset || return 1
    prompt_or_back "Upstream host:port (Server B)" || return 0
    upstream_addr="$REPLY_VALUE"
    [[ ! "$upstream_addr" =~ ^[^[:space:]:]+:[0-9]+$ ]] && { echo -e "${RED}Invalid!${NC}"; return 1; }
    prompt_auth || return 1
    prompt_or_back "Target on B (e.g. 127.0.0.1:8080)" || return 0
    target="$REPLY_VALUE"
    [[ ! "$target" =~ ^[^[:space:]:]+:[0-9]+$ ]] && { echo -e "${RED}Invalid!${NC}"; return 1; }

    chain_name="chain-${name}-${port}"
    local svc_name="${name}-p${port}"
    svc=$(jq -n --arg n "$svc_name" --arg a ":$port" --arg h "$handler_type" --arg l "$listener_type" \
        --arg c "$chain_name" --arg t "$target" --arg p "$port" --arg gn "$name" \
        '{name:$n,addr:$a,handler:{type:$h,chain:$c},listener:{type:$l},forwarder:{nodes:[{name:("target-"+$p),addr:$t}]},metadata:{wildName:$gn,role:"entry"}}')
    ch=$(build_chain_json "$chain_name" "$connector_type" "$upstream_addr" "$USERNAME" "$PASSWORD" \
        "$DIALER_TYPE" "$WS_PATH" "$WS_HOST")
    append_service "$svc"
    append_chain "$ch"
    restart_gost
    echo -e "${GREEN}[$name] :$port -> $upstream_addr -> $target ($TRANSPORT_LABEL)${NC}"
}

setup_multi_port_location_entry() {
    require_gost || return 1
    echo -e "${CYAN}--- Add Entry (Server A, multi) ---${NC}"

    local group slug connector_type proto handler_type listener_type mode strategy offset
    local ports_raw targets_mode loc_count i loc_name loc_addr listen_port target_addr
    local nodes_json node_json chain_name svc_name svc ch created=0
    local locs_tmp ports_tmp

    prompt_config_name "Name" || return 0
    group="$REPLY_VALUE"
    slug="$group"

    echo -e "1) TCP  2) UDP  0) Back"
    read -p "Choice [1]: " proto
    [ -z "$proto" ] && proto="1"
    is_back_choice "$proto" && return 0
    case $proto in
        1) handler_type="tcp"; listener_type="tcp" ;;
        2) handler_type="udp"; listener_type="udp" ;;
        *) echo -e "${RED}Invalid!${NC}"; return 1 ;;
    esac

    echo -e "Connector: 1) relay  2) socks5  3) http  0) Back"
    read -p "Choice [1]: " c
    [ -z "$c" ] && c="1"
    is_back_choice "$c" && return 0
    case $c in
        1) connector_type="relay" ;;
        2) connector_type="socks5" ;;
        3) connector_type="http" ;;
        *) echo -e "${RED}Invalid!${NC}"; return 1 ;;
    esac

    select_transport_preset || return 1

    locs_tmp=$(mktemp)
    echo '[]' > "$locs_tmp"
    echo -e "\n${CYAN}Locations (Server B)${NC}"
    loc_count=0
    while true; do
        echo -e "\nLocation #$((loc_count+1))"
        prompt_or_back "Location name (e.g. US)" || { rm -f "$locs_tmp"; return 0; }
        loc_name=$(sanitize_name "$REPLY_VALUE")
        prompt_or_back "host:port" || { rm -f "$locs_tmp"; return 0; }
        loc_addr="$REPLY_VALUE"
        if [[ ! "$loc_addr" =~ ^[^[:space:]:]+:[0-9]+$ ]]; then
            echo -e "${RED}Invalid address!${NC}"
            continue
        fi
        prompt_auth || { rm -f "$locs_tmp"; return 1; }
        node_json=$(build_chain_node_json "node-$loc_name" "$loc_addr" "$connector_type" \
            "$USERNAME" "$PASSWORD" "$DIALER_TYPE" "$WS_PATH" "$WS_HOST")
        jq --argjson n "$node_json" --arg ln "$loc_name" --arg la "$loc_addr" \
            '. + [{loc: $ln, addr: $la, node: $n}]' "$locs_tmp" > "${locs_tmp}.n" && mv "${locs_tmp}.n" "$locs_tmp"
        loc_count=$((loc_count+1))
        echo -e "${GREEN}Added $loc_name ($loc_addr)${NC}"
        read -p "Add another location? (y/n) [n]: " more
        [ "$more" = "y" ] || [ "$more" = "Y" ] || break
    done
    if [ "$loc_count" -lt 1 ]; then
        echo -e "${RED}Need at least one location.${NC}"
        rm -f "$locs_tmp"
        return 1
    fi

    prompt_or_back "Ports (comma-separated, e.g. 8080,8443)" || { rm -f "$locs_tmp"; return 0; }
    ports_raw="$REPLY_VALUE"
    ports_tmp=$(mktemp)
    echo "$ports_raw" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -E '^[0-9]+$' > "$ports_tmp" || true
    if [ ! -s "$ports_tmp" ]; then
        echo -e "${RED}No valid ports.${NC}"
        rm -f "$locs_tmp" "$ports_tmp"
        return 1
    fi

    echo -e "Target: 1) 127.0.0.1:PORT  2) custom for all"
    read -p "Choice [1]: " targets_mode
    [ -z "$targets_mode" ] && targets_mode="1"
    local custom_target=""
    if [ "$targets_mode" = "2" ]; then
        prompt_or_back "Custom target host:port" || { rm -f "$locs_tmp" "$ports_tmp"; return 0; }
        custom_target="$REPLY_VALUE"
        [[ ! "$custom_target" =~ ^[^[:space:]:]+:[0-9]+$ ]] && {
            echo -e "${RED}Invalid target!${NC}"
            rm -f "$locs_tmp" "$ports_tmp"
            return 1
        }
    fi

    echo -e "Mode: 1) port per location  2) shared ports + selector"
    read -p "Choice [1]: " mode
    [ -z "$mode" ] && mode="1"
    strategy=""
    offset=10000
    if [ "$mode" = "1" ]; then
        read -p "Port offset [10000]: " offset
        [ -z "$offset" ] && offset=10000
        if [[ ! "$offset" =~ ^[0-9]+$ ]] || [ "$offset" -lt 1 ]; then
            echo -e "${RED}Invalid offset!${NC}"
            rm -f "$locs_tmp" "$ports_tmp"
            return 1
        fi
    else
        echo -e "Selector: 1) fifo  2) round  3) rand"
        read -p "Choice [1]: " sc
        [ -z "$sc" ] && sc="1"
        case $sc in
            1) strategy="fifo" ;;
            2) strategy="round" ;;
            3) strategy="rand" ;;
            *) strategy="fifo" ;;
        esac
    fi

    # Pre-validate listen ports
    local base_port loc_idx listen_list=""
    while read -r base_port; do
        [ -z "$base_port" ] && continue
        if [ "$mode" = "1" ]; then
            for ((loc_idx=0; loc_idx<loc_count; loc_idx++)); do
                listen_port=$((base_port + loc_idx * offset))
                if [ "$listen_port" -gt 65535 ]; then
                    echo -e "${RED}Port $listen_port exceeds 65535${NC}"
                    rm -f "$locs_tmp" "$ports_tmp"
                    return 1
                fi
                validate_listen_port "$listen_port" || { rm -f "$locs_tmp" "$ports_tmp"; return 1; }
                echo " $listen_list " | grep -q " $listen_port " && {
                    echo -e "${RED}Duplicate listen port $listen_port${NC}"
                    rm -f "$locs_tmp" "$ports_tmp"
                    return 1
                }
                listen_list="$listen_list $listen_port"
            done
        else
            validate_listen_port "$base_port" || { rm -f "$locs_tmp" "$ports_tmp"; return 1; }
            echo " $listen_list " | grep -q " $base_port " && {
                echo -e "${RED}Duplicate listen port $base_port${NC}"
                rm -f "$locs_tmp" "$ports_tmp"
                return 1
            }
            listen_list="$listen_list $base_port"
        fi
    done < "$ports_tmp"

    echo -e "\n${CYAN}Creating '$group'...${NC}"

    if [ "$mode" = "2" ]; then
        nodes_json=$(jq '[.[].node]' "$locs_tmp")
        chain_name="chain-${slug}-multi"
        ch=$(build_chain_multi_nodes "$chain_name" "$nodes_json" "$strategy")
        append_chain "$ch"
        while read -r base_port; do
            [ -z "$base_port" ] && continue
            if [ -n "$custom_target" ]; then
                target_addr="$custom_target"
            else
                target_addr="127.0.0.1:$base_port"
            fi
            svc_name="${slug}-p${base_port}"
            svc=$(jq -n --arg n "$svc_name" --arg a ":$base_port" --arg h "$handler_type" --arg l "$listener_type" \
                --arg c "$chain_name" --arg t "$target_addr" --arg p "$base_port" --arg gn "$group" --arg st "$strategy" \
                '{name:$n,addr:$a,handler:{type:$h,chain:$c},listener:{type:$l},forwarder:{nodes:[{name:("target-"+$p),addr:$t}]},metadata:{wildName:$gn,role:"entry-multi",mode:"selector",strategy:$st}}')
            append_service "$svc"
            created=$((created+1))
            echo -e "  ${GREEN}+${NC} $svc_name  :$base_port -> $target_addr"
        done < "$ports_tmp"
    else
        for ((loc_idx=0; loc_idx<loc_count; loc_idx++)); do
            loc_name=$(jq -r --argjson i "$loc_idx" '.[$i].loc' "$locs_tmp")
            loc_addr=$(jq -r --argjson i "$loc_idx" '.[$i].addr' "$locs_tmp")
            node_json=$(jq -c --argjson i "$loc_idx" '.[$i].node' "$locs_tmp")
            chain_name="chain-${slug}-${loc_name}"
            nodes_json=$(jq -n --argjson n "$node_json" '[$n]')
            ch=$(build_chain_multi_nodes "$chain_name" "$nodes_json" "")
            append_chain "$ch"
            while read -r base_port; do
                [ -z "$base_port" ] && continue
                listen_port=$((base_port + loc_idx * offset))
                if [ -n "$custom_target" ]; then
                    target_addr="$custom_target"
                else
                    target_addr="127.0.0.1:$base_port"
                fi
                svc_name="${slug}-${loc_name}-p${listen_port}"
                svc=$(jq -n --arg n "$svc_name" --arg a ":$listen_port" --arg h "$handler_type" --arg l "$listener_type" \
                    --arg c "$chain_name" --arg t "$target_addr" --arg p "$listen_port" \
                    --arg gn "$group" --arg ln "$loc_name" --arg la "$loc_addr" --arg bp "$base_port" \
                    '{name:$n,addr:$a,handler:{type:$h,chain:$c},listener:{type:$l},forwarder:{nodes:[{name:("target-"+$p),addr:$t}]},metadata:{wildName:$gn,role:"entry-multi",mode:"per-location",location:$ln,upstream:$la,basePort:($bp|tonumber)}}')
                append_service "$svc"
                created=$((created+1))
                echo -e "  ${GREEN}+${NC} $svc_name  :$listen_port ($loc_name) -> $target_addr"
            done < "$ports_tmp"
        done
    fi

    rm -f "$locs_tmp" "$ports_tmp"
    restart_gost
    echo -e "${GREEN}Created $created service(s) [$group / $TRANSPORT_LABEL]${NC}"
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
    while true; do
        echo -e "\n${CYAN}--- API / Metrics / Profiling ---${NC}"
        echo -e "1) Enable Web API"
        echo -e "2) Enable Prometheus metrics"
        echo -e "3) Enable profiling"
        echo -e "4) Disable API"
        echo -e "5) Disable metrics"
        echo -e "6) Disable profiling"
        echo -e "0) Back"
        read -p "Choice: " c
        case $c in
            1)
                local aport auser apass
                prompt_or_back "API listen port [18080]" || continue
                aport="$REPLY_VALUE"
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
                prompt_or_back "Metrics port [9000]" || continue
                mport="$REPLY_VALUE"
                [ -z "$mport" ] && mport="9000"
                set_config_key "metrics" "$(jq -n --arg a ":$mport" '{addr:$a, path:"/metrics"}')"
                restart_gost
                echo -e "${GREEN}Metrics on :$mport/metrics${NC}"
                ;;
            3)
                local pport
                prompt_or_back "Profiling port [6060]" || continue
                pport="$REPLY_VALUE"
                [ -z "$pport" ] && pport="6060"
                set_config_key "profiling" "$(jq -n --arg a ":$pport" '{addr:$a}')"
                restart_gost
                echo -e "${GREEN}Profiling on :$pport${NC}"
                ;;
            4) jq 'del(.api)' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"; restart_gost; echo -e "${GREEN}API disabled.${NC}" ;;
            5) jq 'del(.metrics)' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"; restart_gost; echo -e "${GREEN}Metrics disabled.${NC}" ;;
            6) jq 'del(.profiling)' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"; restart_gost; echo -e "${GREEN}Profiling disabled.${NC}" ;;
            0|q|Q|b|B) return 0 ;;
            *) echo -e "${RED}Invalid!${NC}" ;;
        esac
    done
}

manage_policies_menu() {
    while true; do
        echo -e "\n${CYAN}--- Advanced ---${NC}"
        echo -e "1) Bypass"
        echo -e "2) Admission"
        echo -e "3) Limiter"
        echo -e "4) API / Metrics"
        echo -e "5) Log level"
        echo -e "6) Show raw JSON"
        echo -e "0) Back"
        read -p "Choice: " c
        case $c in
            1) manage_bypass ;;
            2) manage_admission ;;
            3) manage_limiter ;;
            4) enable_api_metrics ;;
            5)
                require_gost || continue
                echo -e "1) info  2) debug  3) warn  4) error  0) Back"
                read -p "Choice: " lc
                is_back_choice "$lc" && continue
                local level="info"
                case $lc in 1) level="info" ;; 2) level="debug" ;; 3) level="warn" ;; 4) level="error" ;; *) echo -e "${RED}Invalid!${NC}"; continue ;; esac
                set_config_key "log" "$(jq -n --arg l "$level" '{level:$l}')"
                restart_gost
                echo -e "${GREEN}Log level: $level${NC}"
                ;;
            6) show_raw_config ;;
            0|q|Q|b|B) return 0 ;;
            *) echo -e "${RED}Invalid!${NC}" ;;
        esac
    done
}

add_more_services_menu() {
    while true; do
        echo -e "\n${CYAN}--- More ---${NC}"
        echo -e "1) DNS"
        echo -e "2) TUN / TAP / TUN2SOCKS"
        echo -e "3) File server"
        echo -e "4) Transparent redirect"
        echo -e "0) Back"
        read -p "Choice: " c
        case $c in
            1) add_dns_proxy ;;
            2) add_tun_service ;;
            3) add_file_server ;;
            4) add_transparent_redirect ;;
            0|q|Q|b|B) return 0 ;;
            *) echo -e "${RED}Invalid!${NC}" ;;
        esac
    done
}

add_service_menu() {
    require_gost || return 1
    while true; do
        echo -e "\n${CYAN}--- Add ---${NC}"
        echo -e "${GREEN}1) Anti-Filter${NC}  — Iran reverse panel / foreign node / decoy"
        echo -e "2) Upstream (Server B)"
        echo -e "3) Entry single (Server A)"
        echo -e "4) Entry multi-port / multi-location (Server A)"
        echo -e "5) Proxy (SOCKS/HTTP/SS/...)"
        echo -e "6) Local port forward"
        echo -e "7) Reverse tunnel (generic)"
        echo -e "8) More (DNS/TUN/File/Redirect)"
        echo -e "0) Back"
        read -p "Choice: " c
        case $c in
            1) setup_antifilter_menu ;;
            2) setup_remote_port_forward_upstream ;;
            3) setup_remote_port_forward_entry ;;
            4) setup_multi_port_location_entry ;;
            5) add_proxy_service ;;
            6) add_local_port_forward ;;
            7) setup_reverse_tunnel_menu ;;
            8) add_more_services_menu ;;
            0|q|Q|b|B) return 0 ;;
            *) echo -e "${RED}Invalid!${NC}" ;;
        esac
    done
}

# ---------- edit / delete / list ----------

show_service_detail() {
    local index="$1"
    local name addr htype ltype chain target meta_json auth_user resolver bypass admission limiter
    local up_addr up_conn up_dial up_path up_host tunnel_id
    name=$(jq -r ".services[$index].name" "$CONFIG_FILE")
    addr=$(jq -r ".services[$index].addr" "$CONFIG_FILE")
    htype=$(jq -r ".services[$index].handler.type // \"-\"" "$CONFIG_FILE")
    ltype=$(jq -r ".services[$index].listener.type // \"-\"" "$CONFIG_FILE")
    chain=$(jq -r ".services[$index].handler.chain // .services[$index].listener.chain // empty" "$CONFIG_FILE")
    target=$(jq -r "[.services[$index].forwarder.nodes[]?.addr] | join(\", \") // \"-\"" "$CONFIG_FILE")
    [ -z "$target" ] && target="-"
    meta_json=$(jq -c ".services[$index].handler.metadata // {}" "$CONFIG_FILE")
    auth_user=$(jq -r ".services[$index].handler.auth.username // \"-\"" "$CONFIG_FILE")
    resolver=$(jq -r ".services[$index].resolver // \"-\"" "$CONFIG_FILE")
    bypass=$(jq -r ".services[$index].bypass // \"-\"" "$CONFIG_FILE")
    admission=$(jq -r ".services[$index].admission // \"-\"" "$CONFIG_FILE")
    limiter=$(jq -r ".services[$index].limiter // \"-\"" "$CONFIG_FILE")
    up_addr="-"; up_conn="-"; up_dial="-"; up_path="-"; up_host="-"; tunnel_id="-"
    if [ -n "$chain" ]; then
        up_addr=$(jq -r --arg c "$chain" '.chains[]? | select(.name==$c) | .hops[0].nodes[0].addr // "-"' "$CONFIG_FILE")
        up_conn=$(jq -r --arg c "$chain" '.chains[]? | select(.name==$c) | .hops[0].nodes[0].connector.type // "-"' "$CONFIG_FILE")
        up_dial=$(jq -r --arg c "$chain" '.chains[]? | select(.name==$c) | .hops[0].nodes[0].dialer.type // "-"' "$CONFIG_FILE")
        up_path=$(jq -r --arg c "$chain" '.chains[]? | select(.name==$c) | .hops[0].nodes[0].dialer.metadata.path // "-"' "$CONFIG_FILE")
        up_host=$(jq -r --arg c "$chain" '.chains[]? | select(.name==$c) | .hops[0].nodes[0].dialer.metadata.host // .hops[0].nodes[0].dialer.tls.serverName // "-"' "$CONFIG_FILE")
        tunnel_id=$(jq -r --arg c "$chain" '.chains[]? | select(.name==$c) | .hops[0].nodes[0].connector.metadata["tunnel.id"] // "-"' "$CONFIG_FILE")
    fi
    echo -e "${CYAN}--- Service detail ---${NC}"
    echo -e "Name            : $name"
    echo -e "Listen          : $addr"
    echo -e "Handler         : $htype"
    echo -e "Listener        : $ltype"
    echo -e "Handler auth    : $auth_user"
    echo -e "Handler meta    : $meta_json"
    echo -e "Forward target  : $target"
    echo -e "Resolver        : $resolver"
    echo -e "Bypass          : $bypass"
    echo -e "Admission       : $admission"
    echo -e "Limiter         : $limiter"
    echo -e "Chain           : ${chain:-none}"
    echo -e "Upstream addr   : $up_addr"
    echo -e "Upstream conn   : $up_conn"
    echo -e "Upstream dialer : $up_dial"
    echo -e "WS path / host  : $up_path / $up_host"
    echo -e "Tunnel ID       : $tunnel_id"
}

get_service_chain_name() {
    local index="$1"
    jq -r ".services[$index].handler.chain // .services[$index].listener.chain // empty" "$CONFIG_FILE"
}

ensure_chain_for_service() {
    local index="$1"
    local where="${2:-handler}" # handler|listener
    local chain
    chain=$(get_service_chain_name "$index")
    if [ -n "$chain" ]; then
        echo "$chain"
        return 0
    fi
    local port
    port=$(jq -r ".services[$index].addr" "$CONFIG_FILE" | tr -d ':')
    [ -z "$port" ] && port="0"
    chain="chain-edit-$port"
    local ch
    ch=$(build_chain_json "$chain" "relay" "127.0.0.1:1" "" "" "tcp" "" "")
    append_chain "$ch"
    if [ "$where" = "listener" ]; then
        jq --argjson i "$index" --arg c "$chain" \
            '.services[$i].listener.chain = $c' \
            "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
    else
        jq --argjson i "$index" --arg c "$chain" \
            '.services[$i].handler.chain = $c' \
            "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
    fi
    echo "$chain"
}

pick_handler_type() {
    echo -e "Handler types:"
    echo -e " 1) socks5   2) socks4   3) http    4) http2   5) http3"
    echo -e " 6) relay    7) ss       8) auto    9) sni    10) sshd"
    echo -e "11) masque  12) serial  13) tcp    14) udp   15) red"
    echo -e "16) redu    17) dns     18) file   19) tun   20) tap"
    echo -e "21) tungo   22) tunnel  23) rtcp   24) rudp  25) forward"
    echo -e " 0) Back"
    read -p "Choice: " hc
    is_back_choice "$hc" && return 1
    case $hc in
        1) HANDLER_PICK="socks5" ;;
        2) HANDLER_PICK="socks4" ;;
        3) HANDLER_PICK="http" ;;
        4) HANDLER_PICK="http2" ;;
        5) HANDLER_PICK="http3" ;;
        6) HANDLER_PICK="relay" ;;
        7) HANDLER_PICK="ss" ;;
        8) HANDLER_PICK="auto" ;;
        9) HANDLER_PICK="sni" ;;
        10) HANDLER_PICK="sshd" ;;
        11) HANDLER_PICK="masque" ;;
        12) HANDLER_PICK="serial" ;;
        13) HANDLER_PICK="tcp" ;;
        14) HANDLER_PICK="udp" ;;
        15) HANDLER_PICK="red" ;;
        16) HANDLER_PICK="redu" ;;
        17) HANDLER_PICK="dns" ;;
        18) HANDLER_PICK="file" ;;
        19) HANDLER_PICK="tun" ;;
        20) HANDLER_PICK="tap" ;;
        21) HANDLER_PICK="tungo" ;;
        22) HANDLER_PICK="tunnel" ;;
        23) HANDLER_PICK="rtcp" ;;
        24) HANDLER_PICK="rudp" ;;
        25) HANDLER_PICK="forward" ;;
        *) echo -e "${RED}Invalid!${NC}"; return 1 ;;
    esac
    return 0
}

pick_connector_type() {
    echo -e "Connector types:"
    echo -e " 1) relay  2) socks5  3) socks4  4) http  5) http2"
    echo -e " 6) ss     7) sshd    8) forward 9) sni  10) tunnel"
    echo -e "11) direct 12) tcp   13) serial 14) unix 15) masque"
    echo -e " 0) Back"
    read -p "Choice: " cc
    is_back_choice "$cc" && return 1
    case $cc in
        1) CONNECTOR_PICK="relay" ;;
        2) CONNECTOR_PICK="socks5" ;;
        3) CONNECTOR_PICK="socks4" ;;
        4) CONNECTOR_PICK="http" ;;
        5) CONNECTOR_PICK="http2" ;;
        6) CONNECTOR_PICK="ss" ;;
        7) CONNECTOR_PICK="sshd" ;;
        8) CONNECTOR_PICK="forward" ;;
        9) CONNECTOR_PICK="sni" ;;
        10) CONNECTOR_PICK="tunnel" ;;
        11) CONNECTOR_PICK="direct" ;;
        12) CONNECTOR_PICK="tcp" ;;
        13) CONNECTOR_PICK="serial" ;;
        14) CONNECTOR_PICK="unix" ;;
        15) CONNECTOR_PICK="masque" ;;
        *) echo -e "${RED}Invalid!${NC}"; return 1 ;;
    esac
    return 0
}

list_named_refs() {
    local key="$1"
    jq -r --arg k "$key" '.[$k] // [] | .[]?.name' "$CONFIG_FILE" 2>/dev/null
}

edit_handler_metadata() {
    local index="$1"
    local htype
    htype=$(jq -r ".services[$index].handler.type // empty" "$CONFIG_FILE")
    echo -e "${CYAN}--- Handler metadata (type: $htype) ---${NC}"
    echo -e "1) Shadowsocks method + password"
    echo -e "2) Toggle UDP (socks5/http)"
    echo -e "3) Toggle BIND (socks5/relay)"
    echo -e "4) File server directory"
    echo -e "5) Tunnel entrypoint (e.g. :8420)"
    echo -e "6) Tunnel ingress name"
    echo -e "7) Set custom metadata key=value"
    echo -e "8) Delete metadata key"
    echo -e "9) Clear all handler metadata"
    echo -e "0) Back"
    read -p "Choice: " mc
    case $mc in
        1)
            local method pass
            read -p "SS method [aes-256-gcm]: " method
            [ -z "$method" ] && method="aes-256-gcm"
            read -p "SS password: " pass
            [ -z "$pass" ] && { echo -e "${RED}Password required${NC}"; return 1; }
            jq --argjson i "$index" --arg m "$method" --arg p "$pass" '
                .services[$i].handler.metadata = ((.services[$i].handler.metadata // {}) + {method:$m, password:$p})
            ' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
            ;;
        2)
            local cur
            cur=$(jq -r ".services[$index].handler.metadata.udp // false" "$CONFIG_FILE")
            if [ "$cur" = "true" ]; then
                jq --argjson i "$index" 'del(.services[$i].handler.metadata.udp)' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                echo -e "${GREEN}UDP disabled${NC}"
            else
                jq --argjson i "$index" '
                    .services[$i].handler.metadata = ((.services[$i].handler.metadata // {}) + {udp:true})
                ' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                echo -e "${GREEN}UDP enabled${NC}"
            fi
            ;;
        3)
            local cur
            cur=$(jq -r ".services[$index].handler.metadata.bind // false" "$CONFIG_FILE")
            if [ "$cur" = "true" ]; then
                jq --argjson i "$index" 'del(.services[$i].handler.metadata.bind)' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                echo -e "${GREEN}BIND disabled${NC}"
            else
                jq --argjson i "$index" '
                    .services[$i].handler.metadata = ((.services[$i].handler.metadata // {}) + {bind:true})
                ' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                echo -e "${GREEN}BIND enabled${NC}"
            fi
            ;;
        4)
            local dir
            prompt_or_back "Directory path" || return 1
            dir="$REPLY_VALUE"
            jq --argjson i "$index" --arg d "$dir" '
                .services[$i].handler.metadata = ((.services[$i].handler.metadata // {}) + {dir:$d})
            ' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
            ;;
        5)
            local ep
            prompt_or_back "Entrypoint (e.g. :8420)" || return 1
            ep="$REPLY_VALUE"
            [[ "$ep" != :* ]] && ep=":$ep"
            jq --argjson i "$index" --arg e "$ep" '
                .services[$i].handler.metadata = ((.services[$i].handler.metadata // {}) + {entrypoint:$e})
            ' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
            ;;
        6)
            local ing
            prompt_or_back "Ingress name" || return 1
            ing="$REPLY_VALUE"
            jq --argjson i "$index" --arg g "$ing" '
                .services[$i].handler.metadata = ((.services[$i].handler.metadata // {}) + {ingress:$g})
            ' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
            ;;
        7)
            local key val
            prompt_or_back "Metadata key" || return 1
            key="$REPLY_VALUE"
            prompt_or_back "Metadata value" || return 1
            val="$REPLY_VALUE"
            jq --argjson i "$index" --arg k "$key" --arg v "$val" '
                .services[$i].handler.metadata = ((.services[$i].handler.metadata // {}) + {($k): $v})
            ' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
            ;;
        8)
            local key
            prompt_or_back "Metadata key to delete" || return 1
            key="$REPLY_VALUE"
            jq --argjson i "$index" --arg k "$key" 'del(.services[$i].handler.metadata[$k])' \
                "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
            ;;
        9)
            jq --argjson i "$index" 'del(.services[$i].handler.metadata)' \
                "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
            ;;
        0|q|Q|b|B) return 0 ;;
        *) echo -e "${RED}Invalid!${NC}"; return 1 ;;
    esac
    restart_gost
    echo -e "${GREEN}Handler metadata updated.${NC}"
}

attach_named_ref_to_service() {
    local index="$1"
    local field="$2" # resolver|bypass|admission|limiter
    local key_plural="$3"
    echo -e "Existing ${key_plural}:"
    local names
    names=$(list_named_refs "$key_plural")
    if [ -z "$names" ]; then
        echo -e "${YELLOW}None found. Create one in Policies menu first (or leave empty to clear).${NC}"
    else
        echo "$names" | nl -w2 -s') '
    fi
    prompt_or_back "Name to attach (empty=clear)" || return 1
    local ref="$REPLY_VALUE"
    if [ -z "$ref" ]; then
        jq --argjson i "$index" --arg f "$field" 'del(.services[$i][$f])' \
            "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
        echo -e "${GREEN}$field cleared.${NC}"
    else
        jq --argjson i "$index" --arg f "$field" --arg n "$ref" \
            '.services[$i][$f] = $n' \
            "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
        echo -e "${GREEN}$field set to $ref${NC}"
    fi
    restart_gost
}

edit_selected_service() {
    local index="$1"
    local chain new_val
    HANDLER_PICK=""
    CONNECTOR_PICK=""

    while true; do
        echo ""
        show_service_detail "$index"
        echo -e "\n${CYAN}Edit options (all protocols):${NC}"
        echo -e " 1) Service name"
        echo -e " 2) Listen address/port"
        echo -e " 3) Handler type (socks/http/relay/ss/tunnel/...)"
        echo -e " 4) Handler metadata (SS/UDP/BIND/file/tunnel/...)"
        echo -e " 5) Handler auth"
        echo -e " 6) Listener transport (+ path)"
        echo -e " 7) Forward target(s)"
        echo -e " 8) Attach/change handler chain"
        echo -e " 9) Attach/change listener chain (rtcp/rudp)"
        echo -e "10) Detach all chains from this service"
        echo -e "11) Upstream address"
        echo -e "12) Upstream connector type"
        echo -e "13) Upstream dialer/transport + path/SNI"
        echo -e "14) Upstream auth"
        echo -e "15) Upstream tunnel.id (reverse client)"
        echo -e "16) Attach resolver"
        echo -e "17) Attach bypass"
        echo -e "18) Attach admission"
        echo -e "19) Attach limiter"
        echo -e "20) Replace service JSON (advanced)"
        echo -e "21) Show raw JSON (service + chain)"
        echo -e " 0) Back"
        read -p "Choice: " ec
        case $ec in
            1)
                prompt_or_back "New service name" || continue
                new_val="$REPLY_VALUE"
                jq --argjson i "$index" --arg n "$new_val" '.services[$i].name = $n' \
                    "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                restart_gost
                echo -e "${GREEN}Name updated.${NC}"
                ;;
            2)
                prompt_or_back "New listen address (e.g. 2018 or :2018 or /path.sock)" || continue
                new_val="$REPLY_VALUE"
                if [[ "$new_val" =~ ^[0-9]+$ ]]; then
                    new_val=":$new_val"
                fi
                if [[ "$new_val" =~ ^:[0-9]+$ ]]; then
                    local conflict
                    conflict=$(jq --argjson i "$index" --arg p "$new_val" \
                        '.services | to_entries[] | select(.key != $i and .value.addr == $p) | .value.name' "$CONFIG_FILE")
                    if [ -n "$conflict" ]; then
                        echo -e "${RED}Address $new_val already used by $conflict${NC}"; continue
                    fi
                fi
                jq --argjson i "$index" --arg a "$new_val" '.services[$i].addr = $a' \
                    "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                restart_gost
                echo -e "${GREEN}Listen address updated to $new_val${NC}"
                ;;
            3)
                pick_handler_type || continue
                jq --argjson i "$index" --arg t "$HANDLER_PICK" '.services[$i].handler.type = $t' \
                    "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                # keep listener in sync for rtcp/rudp/red/redu/tun/tap/tungo/dns when useful
                case "$HANDLER_PICK" in
                    rtcp|rudp|red|redu|tun|tap|tungo|dns)
                        jq --argjson i "$index" --arg t "$HANDLER_PICK" '.services[$i].listener.type = $t' \
                            "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                        ;;
                esac
                restart_gost
                echo -e "${GREEN}Handler type set to $HANDLER_PICK${NC}"
                ;;
            4)
                edit_handler_metadata "$index" || true
                ;;
            5)
                prompt_auth || continue
                if [ -n "$USERNAME" ]; then
                    jq --argjson i "$index" --arg u "$USERNAME" --arg p "$PASSWORD" \
                        '.services[$i].handler.auth = {username:$u, password:$p}' \
                        "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                else
                    jq --argjson i "$index" 'del(.services[$i].handler.auth)' \
                        "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                fi
                restart_gost
                echo -e "${GREEN}Handler auth updated.${NC}"
                ;;
            6)
                select_listener_transport || continue
                local listener_json
                listener_json=$(build_listener_json "$LISTENER_TYPE" "$WS_PATH")
                # preserve existing listener.chain if any
                jq --argjson i "$index" --argjson l "$listener_json" '
                    .services[$i].listener = ($l + (if .services[$i].listener.chain then {chain:.services[$i].listener.chain} else {} end))
                ' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                restart_gost
                echo -e "${GREEN}Listener set to $TRANSPORT_LABEL${NC}"
                ;;
            7)
                echo -e "1) Set single target  2) Add target  3) Clear forwarder  0) Back"
                read -p "Choice: " fc
                is_back_choice "$fc" && continue
                case $fc in
                    1)
                        prompt_or_back "Target host:port" || continue
                        new_val="$REPLY_VALUE"
                        [[ ! "$new_val" =~ ^[^[:space:]:]+:[0-9]+$ ]] && { echo -e "${RED}Invalid!${NC}"; continue; }
                        jq --argjson i "$index" --arg t "$new_val" '
                            .services[$i].forwarder = {nodes:[{name:(.services[$i].forwarder.nodes[0].name // "target"), addr:$t}]}
                        ' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                        ;;
                    2)
                        prompt_or_back "Additional target host:port" || continue
                        new_val="$REPLY_VALUE"
                        [[ ! "$new_val" =~ ^[^[:space:]:]+:[0-9]+$ ]] && { echo -e "${RED}Invalid!${NC}"; continue; }
                        jq --argjson i "$index" --arg t "$new_val" '
                            .services[$i].forwarder.nodes = ((.services[$i].forwarder.nodes // []) + [{name:("target-"+($t|gsub(":";"-"))), addr:$t}])
                        ' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                        ;;
                    3)
                        jq --argjson i "$index" 'del(.services[$i].forwarder)' \
                            "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                        ;;
                    *) echo -e "${RED}Invalid!${NC}"; continue ;;
                esac
                restart_gost
                echo -e "${GREEN}Forwarder updated.${NC}"
                ;;
            8)
                chain=$(ensure_chain_for_service "$index" "handler")
                echo -e "${GREEN}Handler chain: $chain${NC}"
                ;;
            9)
                chain=$(ensure_chain_for_service "$index" "listener")
                echo -e "${GREEN}Listener chain: $chain${NC}"
                ;;
            10)
                jq --argjson i "$index" '
                    del(.services[$i].handler.chain) | del(.services[$i].listener.chain)
                ' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                restart_gost
                echo -e "${GREEN}Chains detached from service.${NC}"
                ;;
            11)
                chain=$(ensure_chain_for_service "$index")
                prompt_or_back "Upstream address (host:port)" || continue
                new_val="$REPLY_VALUE"
                [[ ! "$new_val" =~ ^[^[:space:]:]+:[0-9]+$ ]] && { echo -e "${RED}Invalid!${NC}"; continue; }
                jq --arg c "$chain" --arg a "$new_val" \
                    '(.chains[] | select(.name==$c) | .hops[0].nodes[0].addr) = $a' \
                    "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                restart_gost
                echo -e "${GREEN}Upstream address updated.${NC}"
                ;;
            12)
                chain=$(ensure_chain_for_service "$index")
                pick_connector_type || continue
                jq --arg c "$chain" --arg t "$CONNECTOR_PICK" \
                    '(.chains[] | select(.name==$c) | .hops[0].nodes[0].connector.type) = $t' \
                    "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                restart_gost
                echo -e "${GREEN}Connector set to $CONNECTOR_PICK${NC}"
                ;;
            13)
                chain=$(ensure_chain_for_service "$index")
                select_dialer_transport || continue
                local dialer_json
                dialer_json=$(build_dialer_json "$DIALER_TYPE" "$WS_PATH" "$WS_HOST")
                jq --arg c "$chain" --argjson d "$dialer_json" \
                    '(.chains[] | select(.name==$c) | .hops[0].nodes[0].dialer) = $d' \
                    "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                restart_gost
                echo -e "${GREEN}Dialer set to $TRANSPORT_LABEL${NC}"
                ;;
            14)
                chain=$(ensure_chain_for_service "$index")
                prompt_auth || continue
                if [ -n "$USERNAME" ]; then
                    jq --arg c "$chain" --arg u "$USERNAME" --arg p "$PASSWORD" '
                        (.chains[] | select(.name==$c) | .hops[0].nodes[0].connector.auth) = {username:$u, password:$p}
                    ' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                else
                    jq --arg c "$chain" '
                        del((.chains[] | select(.name==$c) | .hops[0].nodes[0].connector.auth))
                    ' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                fi
                restart_gost
                echo -e "${GREEN}Upstream auth updated.${NC}"
                ;;
            15)
                chain=$(ensure_chain_for_service "$index")
                prompt_or_back "Tunnel ID (UUID, empty=clear)" || continue
                new_val="$REPLY_VALUE"
                if [ -z "$new_val" ]; then
                    jq --arg c "$chain" '
                        del((.chains[] | select(.name==$c) | .hops[0].nodes[0].connector.metadata["tunnel.id"]))
                    ' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                else
                    jq --arg c "$chain" --arg tid "$new_val" '
                        (.chains[] | select(.name==$c) | .hops[0].nodes[0].connector.type) = "tunnel" |
                        (.chains[] | select(.name==$c) | .hops[0].nodes[0].connector.metadata) =
                            (((.chains[] | select(.name==$c) | .hops[0].nodes[0].connector.metadata) // {}) + {"tunnel.id": $tid})
                    ' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                fi
                restart_gost
                echo -e "${GREEN}Tunnel ID updated.${NC}"
                ;;
            16) attach_named_ref_to_service "$index" "resolver" "resolvers" ;;
            17) attach_named_ref_to_service "$index" "bypass" "bypasses" ;;
            18) attach_named_ref_to_service "$index" "admission" "admissions" ;;
            19) attach_named_ref_to_service "$index" "limiter" "limiters" ;;
            20)
                echo -e "${YELLOW}Paste full service JSON object, then press Ctrl+D (or end with a line containing only END)${NC}"
                local tmp_json="/tmp/gost_edit_svc_$$.json"
                if command -v timeout &>/dev/null; then
                    : # keep simple read loop
                fi
                local line buf=""
                while IFS= read -r line; do
                    [ "$line" = "END" ] && break
                    buf+="$line"$'\n'
                done
                if ! echo "$buf" | jq empty 2>/tmp/gost_jq_err.txt; then
                    echo -e "${RED}Invalid JSON${NC}"; cat /tmp/gost_jq_err.txt 2>/dev/null; continue
                fi
                echo "$buf" | jq -c . > "$tmp_json"
                jq --argjson i "$index" --slurpfile s "$tmp_json" '.services[$i] = $s[0]' \
                    "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                rm -f "$tmp_json"
                restart_gost
                echo -e "${GREEN}Service JSON replaced.${NC}"
                ;;
            21)
                chain=$(get_service_chain_name "$index")
                echo -e "${CYAN}--- Service JSON ---${NC}"
                jq --argjson i "$index" '.services[$i]' "$CONFIG_FILE"
                if [ -n "$chain" ]; then
                    echo -e "${CYAN}--- Chain JSON ---${NC}"
                    jq --arg c "$chain" '.chains[]? | select(.name==$c)' "$CONFIG_FILE"
                fi
                pause_help
                ;;
            0|q|Q|b|B) return 0 ;;
            *) echo -e "${RED}Invalid!${NC}" ;;
        esac
    done
}

edit_chain_menu() {
    require_gost || return 1
    while true; do
        local count
        count=$(jq '.chains // [] | length' "$CONFIG_FILE")
        echo -e "\n${CYAN}--- Edit Chain ---${NC}"
        if [ "$count" -eq 0 ]; then
            echo -e "${YELLOW}No chains.${NC}"
            return 0
        fi
        local i
        for ((i=0; i<count; i++)); do
            local n a t
            n=$(jq -r ".chains[$i].name" "$CONFIG_FILE")
            a=$(jq -r ".chains[$i].hops[0].nodes[0].addr // \"-\"" "$CONFIG_FILE")
            t=$(jq -r ".chains[$i].hops[0].nodes[0].connector.type // \"-\"" "$CONFIG_FILE")
            echo -e "$((i+1))) $n | $a | connector=$t"
        done
        echo -e "0) Back"
        read -p "Chain number: " choice
        is_back_choice "$choice" && return 0
        [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$count" ] && { echo -e "${RED}Invalid!${NC}"; continue; }
        local idx=$((choice-1))
        local cname
        cname=$(jq -r ".chains[$idx].name" "$CONFIG_FILE")
        # Fake a temp service index path: operate by chain name via ensure using a dummy edit loop
        echo -e "Editing chain: $cname"
        echo -e "1) Address  2) Connector  3) Dialer  4) Auth  5) Tunnel ID  6) Show JSON  0) Back"
        read -p "Choice: " cc
        case $cc in
            1)
                prompt_or_back "host:port" || continue
                jq --arg c "$cname" --arg a "$REPLY_VALUE" \
                    '(.chains[] | select(.name==$c) | .hops[0].nodes[0].addr) = $a' \
                    "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                restart_gost ;;
            2)
                pick_connector_type || continue
                jq --arg c "$cname" --arg t "$CONNECTOR_PICK" \
                    '(.chains[] | select(.name==$c) | .hops[0].nodes[0].connector.type) = $t' \
                    "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                restart_gost ;;
            3)
                select_dialer_transport || continue
                jq --arg c "$cname" --argjson d "$(build_dialer_json "$DIALER_TYPE" "$WS_PATH" "$WS_HOST")" \
                    '(.chains[] | select(.name==$c) | .hops[0].nodes[0].dialer) = $d' \
                    "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                restart_gost ;;
            4)
                prompt_auth || continue
                if [ -n "$USERNAME" ]; then
                    jq --arg c "$cname" --arg u "$USERNAME" --arg p "$PASSWORD" \
                        '(.chains[] | select(.name==$c) | .hops[0].nodes[0].connector.auth) = {username:$u,password:$p}' \
                        "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                else
                    jq --arg c "$cname" 'del((.chains[] | select(.name==$c) | .hops[0].nodes[0].connector.auth))' \
                        "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                fi
                restart_gost ;;
            5)
                prompt_or_back "Tunnel ID" || continue
                jq --arg c "$cname" --arg tid "$REPLY_VALUE" '
                    (.chains[] | select(.name==$c) | .hops[0].nodes[0].connector.type) = "tunnel" |
                    (.chains[] | select(.name==$c) | .hops[0].nodes[0].connector.metadata) =
                      (((.chains[] | select(.name==$c) | .hops[0].nodes[0].connector.metadata) // {}) + {"tunnel.id":$tid})
                ' "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                restart_gost ;;
            6) jq --arg c "$cname" '.chains[]? | select(.name==$c)' "$CONFIG_FILE"; pause_help ;;
            0|q|Q|b|B) continue ;;
            *) echo -e "${RED}Invalid!${NC}" ;;
        esac
        echo -e "${GREEN}Chain updated.${NC}"
    done
}

edit_named_list_item() {
    local key="$1" # bypasses|admissions|limiters|resolvers|ingresses
    require_gost || return 1
    while true; do
        local count
        count=$(jq --arg k "$key" '.[$k] // [] | length' "$CONFIG_FILE")
        echo -e "\n${CYAN}--- Edit $key ---${NC}"
        if [ "$count" -eq 0 ]; then
            echo -e "${YELLOW}No items in $key.${NC}"
            return 0
        fi
        local i
        for ((i=0; i<count; i++)); do
            echo -e "$((i+1))) $(jq -r --arg k "$key" --argjson i "$i" '.[$k][$i].name // ("item-"+($i|tostring))' "$CONFIG_FILE")"
        done
        echo -e "0) Back"
        read -p "Item number: " choice
        is_back_choice "$choice" && return 0
        [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$count" ] && { echo -e "${RED}Invalid!${NC}"; continue; }
        local idx=$((choice-1))
        echo -e "1) Rename  2) Replace full JSON  3) Delete item  4) Show JSON  0) Back"
        read -p "Choice: " ac
        case $ac in
            1)
                prompt_or_back "New name" || continue
                jq --arg k "$key" --argjson i "$idx" --arg n "$REPLY_VALUE" '.[$k][$i].name = $n' \
                    "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                restart_gost; echo -e "${GREEN}Renamed.${NC}" ;;
            2)
                echo -e "${YELLOW}Paste JSON object, end with line END${NC}"
                local buf="" line
                while IFS= read -r line; do
                    [ "$line" = "END" ] && break
                    buf+="$line"$'\n'
                done
                echo "$buf" | jq empty 2>/dev/null || { echo -e "${RED}Invalid JSON${NC}"; continue; }
                echo "$buf" | jq -c . > /tmp/gost_edit_item.json
                jq --arg k "$key" --argjson i "$idx" --slurpfile s /tmp/gost_edit_item.json '.[$k][$i] = $s[0]' \
                    "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                rm -f /tmp/gost_edit_item.json
                restart_gost; echo -e "${GREEN}Replaced.${NC}" ;;
            3)
                jq --arg k "$key" --argjson i "$idx" '.[$k] |= (to_entries | map(select(.key != $i) | .value))' \
                    "$CONFIG_FILE" > /tmp/gost_config_tmp.json && mv /tmp/gost_config_tmp.json "$CONFIG_FILE"
                restart_gost; echo -e "${GREEN}Deleted.${NC}" ;;
            4)
                jq --arg k "$key" --argjson i "$idx" '.[$k][$i]' "$CONFIG_FILE"; pause_help ;;
            0|q|Q|b|B) continue ;;
            *) echo -e "${RED}Invalid!${NC}" ;;
        esac
    done
}

edit_service_menu() {
    require_gost || return 1
    while true; do
        echo -e "\n${CYAN}--- Edit ---${NC}"
        echo -e "1) Service"
        echo -e "2) Chain"
        echo -e "3) Bypass / Admission / Limiter / Resolver / Ingress"
        echo -e "0) Back"
        read -p "Choice: " c
        case $c in
            1)
                local services_count i name addr type
                services_count=$(jq '.services | length' "$CONFIG_FILE")
                if [ "$services_count" -eq 0 ]; then
                    echo -e "${YELLOW}No services.${NC}"
                    continue
                fi
                for ((i=0; i<services_count; i++)); do
                    name=$(jq -r ".services[$i].name" "$CONFIG_FILE")
                    addr=$(jq -r ".services[$i].addr" "$CONFIG_FILE")
                    type=$(jq -r ".services[$i].handler.type" "$CONFIG_FILE")
                    echo -e "$((i+1))) $name | $addr | $type"
                done
                echo -e "0) Back"
                read -p "Service number: " choice
                is_back_choice "$choice" && continue
                [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$services_count" ] && { echo -e "${RED}Invalid!${NC}"; continue; }
                edit_selected_service $((choice-1))
                ;;
            2) edit_chain_menu ;;
            3)
                echo -e "1) Bypass  2) Admission  3) Limiter  4) Resolver  5) Ingress  0) Back"
                read -p "Choice: " pc
                case $pc in
                    1) edit_named_list_item "bypasses" ;;
                    2) edit_named_list_item "admissions" ;;
                    3) edit_named_list_item "limiters" ;;
                    4) edit_named_list_item "resolvers" ;;
                    5) edit_named_list_item "ingresses" ;;
                    0|q|Q|b|B) ;;
                    *) echo -e "${RED}Invalid!${NC}" ;;
                esac
                ;;
            0|q|Q|b|B) return 0 ;;
            *) echo -e "${RED}Invalid!${NC}" ;;
        esac
    done
}

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
    echo -e "0) Back"
    read -p "Number to remove (0=Back): " choice
    if is_back_choice "$choice" || [ -z "$choice" ]; then
        echo -e "${YELLOW}Going back.${NC}"
        return 0
    fi
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
        local i name addr type chain forward_target listener_type upstream transport dialer_type node_n
        for ((i=0; i<services_count; i++)); do
            name=$(jq -r ".services[$i].name" "$CONFIG_FILE")
            addr=$(jq -r ".services[$i].addr" "$CONFIG_FILE")
            type=$(jq -r ".services[$i].handler.type" "$CONFIG_FILE")
            chain=$(jq -r ".services[$i].handler.chain // .services[$i].listener.chain // empty" "$CONFIG_FILE")
            forward_target=$(jq -r ".services[$i].forwarder.nodes[0].addr // \"-\"" "$CONFIG_FILE")
            listener_type=$(jq -r ".services[$i].listener.type // \"-\"" "$CONFIG_FILE")
            upstream="-"; transport="$listener_type"; node_n=0
            if [ -n "$chain" ]; then
                node_n=$(jq -r --arg ch "$chain" '.chains[]? | select(.name==$ch) | (.hops[0].nodes // []) | length' "$CONFIG_FILE")
                if [ "$node_n" -gt 1 ] 2>/dev/null; then
                    upstream=$(jq -r --arg ch "$chain" '
                        .chains[]? | select(.name==$ch) |
                        ((.hops[0].nodes | map(.addr) | join(",")) + " (" + ((.selector.strategy // "multi")|tostring) + ")")
                    ' "$CONFIG_FILE")
                else
                    upstream=$(jq -r --arg ch "$chain" '.chains[]? | select(.name==$ch) | .hops[0].nodes[0].addr' "$CONFIG_FILE")
                fi
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
    if [ -f "$ANTIFILTER_STATE" ]; then
        echo -e "Anti-Filter: ${GREEN}$(jq -r '.role // "?"' "$ANTIFILTER_STATE")${NC}  nodes=$(jq '.nodes // [] | length' "$ANTIFILTER_STATE" 2>/dev/null || echo 0)"
    fi
    echo -e "Config file: $CONFIG_FILE"
}

manage_service() {
    require_gost || return 1
    while true; do
        echo -e "\n${CYAN}--- Service ---${NC}"
        echo -e "1) Status  2) Start  3) Stop  4) Restart  0) Back"
        read -p "Choice: " s_choice
        case $s_choice in
            1) systemctl status gost --no-pager -l || true ;;
            2) systemctl start gost; echo -e "${GREEN}Started.${NC}" ;;
            3) systemctl stop gost; echo -e "${RED}Stopped.${NC}" ;;
            4) systemctl restart gost; echo -e "${GREEN}Restarted.${NC}" ;;
            0|q|Q|b|B) break ;;
            *) echo -e "${RED}Invalid!${NC}" ;;
        esac
    done
}

# ---------- logs ----------

logs_menu() {
    while true; do
        echo -e "\n${CYAN}--- Logs ---${NC}"
        echo -e "1) Live (follow)"
        echo -e "2) Last 100 lines"
        echo -e "3) Errors only"
        echo -e "4) Export to /tmp/gost-logs.txt"
        echo -e "5) Validate config"
        echo -e "6) Debug log level"
        echo -e "7) Info log level"
        echo -e "0) Back"
        read -p "Choice: " lc
        case $lc in
            1)
                echo -e "${CYAN}Ctrl+C to stop${NC}"
                journalctl -u gost -f --no-pager || true
                ;;
            2)
                journalctl -u gost -n 100 --no-pager || true
                pause_help
                ;;
            3)
                journalctl -u gost -n 300 --no-pager 2>/dev/null \
                    | grep -iE 'error|fail|fatal|panic|refused|denied|timeout|invalid|cannot|unable' \
                    || echo -e "${YELLOW}No errors found.${NC}"
                pause_help
                ;;
            4)
                local out="/tmp/gost-logs.txt"
                {
                    echo "===== Wild GOST $(date -Is 2>/dev/null || date) ====="
                    systemctl status gost --no-pager -l 2>&1 || true
                    echo ""
                    journalctl -u gost -n 500 --no-pager 2>&1 || true
                } > "$out"
                echo -e "${GREEN}Saved: $out${NC}"
                pause_help
                ;;
            5)
                if [ ! -f "$CONFIG_FILE" ]; then
                    echo -e "${RED}No config file.${NC}"
                elif jq empty "$CONFIG_FILE" 2>/tmp/gost_jq_err.txt; then
                    echo -e "${GREEN}JSON OK${NC} | services=$(jq '.services // [] | length' "$CONFIG_FILE") chains=$(jq '.chains // [] | length' "$CONFIG_FILE")"
                else
                    echo -e "${RED}JSON invalid:${NC}"
                    cat /tmp/gost_jq_err.txt 2>/dev/null
                fi
                rm -f /tmp/gost_jq_err.txt
                pause_help
                ;;
            6)
                require_gost || continue
                set_config_key "log" "$(jq -n '{level:"debug"}')"
                restart_gost
                echo -e "${GREEN}debug${NC}"
                ;;
            7)
                require_gost || continue
                set_config_key "log" "$(jq -n '{level:"info"}')"
                restart_gost
                echo -e "${GREEN}info${NC}"
                ;;
            0|q|Q|b|B) return 0 ;;
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
    # resolvers/ingresses/api/metrics/anti-filter state cannot survive uninstall.
    rm -rf /etc/gost
    rm -rf "$DECOY_DIR" 2>/dev/null || true

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

# ---------- menu ----------

pause_help() {
    echo -e "\n${YELLOW}Press Enter to continue...${NC}"
    read -r
}

main_menu() {
    while true; do
        show_banner
        if [ -f /usr/local/bin/gost ]; then
            status_line=$(systemctl is-active gost 2>/dev/null)
            if [ "$status_line" = "active" ]; then
                echo -e "Status: ${GREEN}Running${NC}"
            else
                echo -e "Status: ${YELLOW}Stopped${NC}"
            fi
        else
            echo -e "Status: ${RED}Not installed${NC}"
        fi
        echo -e "---------------------------------------------"
        echo -e "1) Install / Update"
        echo -e "2) Add"
        echo -e "3) Edit"
        echo -e "4) Remove"
        echo -e "5) List"
        echo -e "6) Service (start/stop/restart)"
        echo -e "7) Logs"
        echo -e "8) Advanced"
        echo -e "9) Uninstall"
        echo -e "0) Exit"
        echo -e "---------------------------------------------"
        read -p "Choice: " choice
        case $choice in
            1) install_gost ;;
            2) add_service_menu ;;
            3) edit_service_menu ;;
            4) delete_tunnel ;;
            5) list_tunnels ;;
            6) manage_service ;;
            7) logs_menu ;;
            8) manage_policies_menu ;;
            9) uninstall_gost ;;
            0|q|Q) echo -e "${GREEN}Bye.${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid choice.${NC}" ;;
        esac
        echo -e "\n${YELLOW}Press Enter...${NC}"
        read -r
        clear
    done
}

clear
main_menu
