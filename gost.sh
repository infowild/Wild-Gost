#!/usr/bin/env bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check Root User
if [[ "$EUID" -ne '0' ]]; then
    echo -e "${RED}خطا: برای اجرای این اسکریپت باید دسترسی root داشته باشید (اجرا به صورت sudo).${NC}"
    exit 1
fi

show_banner() {
    echo -e "${CYAN}============================================= ${NC}"
    echo -e "${GREEN}      اسکریپت مدیریت آسان و تونل‌زنی GOST      ${NC}"
    echo -e "${CYAN}============================================= ${NC}"
}

check_dependencies() {
    if ! command -v curl &> /dev/null; then
        echo -e "${YELLOW}ابزار curl نصب نیست. در حال نصب...${NC}"
        if command -v apt-get &> /dev/null; then
            apt-get update && apt-get install -y curl
        elif command -v yum &> /dev/null; then
            yum install -y curl
        fi
    fi
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}ابزار jq نصب نیست. در حال نصب...${NC}"
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

install_gost() {
    check_dependencies
    echo -e "${CYAN}در حال دریافت آخرین نسخه GOST...${NC}"
    latest_ver=$(curl -s https://api.github.com/repos/go-gost/gost/releases/latest | jq -r .tag_name)
    if [ -z "$latest_ver" ] || [ "$latest_ver" = "null" ]; then
        echo -e "${RED}خطا در دریافت نسخه جدید از گیت‌هاب.${NC}"
        return 1
    fi
    echo -e "${GREEN}آخرین نسخه یافت شد: $latest_ver${NC}"
    
    arch=$(uname -m)
    os="linux"
    cpu_arch=""
    case $arch in
        x86_64) cpu_arch="amd64" ;;
        aarch64|arm64) cpu_arch="arm64" ;;
        i686|i386) cpu_arch="386" ;;
        armv7*) cpu_arch="armv7" ;;
        *) echo -e "${RED}معماری سیستم شما پشتیبانی نمی‌شود: $arch${NC}"; return 1 ;;
    esac
    
    download_url=$(curl -s https://api.github.com/repos/go-gost/gost/releases/latest | jq -r ".assets[] | select(.name | contains(\"${os}\") and contains(\"${cpu_arch}\")) | .browser_download_url" | head -n 1)
    
    if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then
        echo -e "${RED}فایل دانلودی مناسب برای معماری شما پیدا نشد.${NC}"
        return 1
    fi
    
    echo -e "${CYAN}در حال دانلود از: $download_url${NC}"
    mkdir -p /tmp/gost_install
    curl -L "$download_url" -o /tmp/gost_install/gost.tar.gz
    tar -xzf /tmp/gost_install/gost.tar.gz -C /tmp/gost_install
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
    
    echo -e "${GREEN}نصب GOST با موفقیت انجام شد! نسخه: $latest_ver${NC}"
    /usr/local/bin/gost -V
}

add_tunnel() {
    if [ ! -f /usr/local/bin/gost ]; then
        echo -e "${RED}برنامه GOST نصب نیست. ابتدا گزینه 1 را برای نصب انتخاب کنید.${NC}"
        return 1
    fi
    
    echo -e "${CYAN}--- افزودن تونل جدید ---${NC}"
    read -p "پورت گوش دادن (مثلا 1080): " port
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo -e "${RED}پورت نامعتبر است!${NC}"
        return 1
    fi
    
    port_exists=$(jq --arg port ":$port" '.services[]? | select(.addr == $port) | .name' /etc/gost/config.json)
    if [ -n "$port_exists" ]; then
        echo -e "${RED}این پورت قبلاً در تنظیمات استفاده شده است!${NC}"
        return 1
    fi
    
    echo -e "نوع پروتکل ورودی را انتخاب کنید:"
    echo -e "1) SOCKS5"
    echo -e "2) HTTP"
    echo -e "3) Relay Server"
    echo -e "4) TCP Port Forwarding"
    echo -e "5) UDP Port Forwarding"
    echo -e "6) Shadowsocks (SS)"
    read -p "انتخاب شما (1-6): " proto_choice
    
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
            read -p "آیا احراز هویت (نام کاربری/رمز عبور) نیاز است؟ (y/n): " has_auth
            ;;
        2)
            handler_type="http"
            read -p "آیا احراز هویت (نام کاربری/رمز عبور) نیاز است؟ (y/n): " has_auth
            ;;
        3)
            handler_type="relay"
            read -p "آیا احراز هویت (نام کاربری/رمز عبور) نیاز است? (y/n): " has_auth
            ;;
        4)
            handler_type="tcp"
            read -p "آدرس مقصد برای فوروارد (مثلا 127.0.0.1:80 یا google.com:443): " forward_target
            if [ -z "$forward_target" ]; then
                echo -e "${RED}آدرس مقصد نمی‌تواند خالی باشد!${NC}"
                return 1
            fi
            ;;
        5)
            handler_type="udp"
            listener_type="udp"
            read -p "آدرس مقصد برای فوروارد (مثلا 127.0.0.1:53): " forward_target
            if [ -z "$forward_target" ]; then
                echo -e "${RED}آدرس مقصد نمی‌تواند خالی باشد!${NC}"
                return 1
            fi
            ;;
        6)
            handler_type="ss"
            read -p "نوع رمزنگاری Shadowsocks (پیش‌فرض aes-256-gcm): " ss_method
            [ -z "$ss_method" ] && ss_method="aes-256-gcm"
            read -p "رمز عبور Shadowsocks: " ss_password
            if [ -z "$ss_password" ]; then
                echo -e "${RED}رمز عبور نمی‌تواند خالی باشد!${NC}"
                return 1
            fi
            ;;
        *)
            echo -e "${RED}انتخاب نامعتبر!${NC}"
            return 1
            ;;
    esac
    
    if [ "$has_auth" = "y" ] || [ "$has_auth" = "Y" ]; then
        read -p "نام کاربری: " username
        read -p "رمز عبور: " password
        if [ -z "$username" ] || [ -z "$password" ]; then
            echo -e "${RED}نام کاربری و رمز عبور نمی‌توانند خالی باشند!${NC}"
            return 1
        fi
    fi
    
    if [ "$proto_choice" -eq 1 ] || [ "$proto_choice" -eq 2 ] || [ "$proto_choice" -eq 3 ]; then
        read -p "آیا تمایل دارید ترافیک را از یک پروکسی بالادستی (Upstream Chain) عبور دهید؟ (y/n): " has_upstream
        if [ "$has_upstream" = "y" ] || [ "$has_upstream" = "Y" ]; then
            read -p "آدرس پروکسی بالادستی (مثال: socks5://1.2.3.4:1080 یا relay+tls://5.6.7.8:8443): " upstream_node
            if [ -z "$upstream_node" ]; then
                echo -e "${RED}آدرس پروکسی بالادستی نمی‌تواند خالی باشد!${NC}"
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
    echo -e "${GREEN}تونل با موفقیت اضافه و راه‌اندازی شد!${NC}"
}

delete_tunnel() {
    if [ ! -f /usr/local/bin/gost ]; then
        echo -e "${RED}برنامه GOST نصب نیست.${NC}"
        return 1
    fi
    
    echo -e "${CYAN}--- حذف تونل ---${NC}"
    services_count=$(jq '.services | length' /etc/gost/config.json)
    if [ "$services_count" -eq 0 ]; then
        echo -e "${YELLOW}هیچ تونلی پیکربندی نشده است.${NC}"
        return 0
    fi
    
    echo -e "تونل مورد نظر برای حذف را انتخاب کنید:"
    for ((i=0; i<services_count; i++)); do
        name=$(jq -r ".services[$i].name" /etc/gost/config.json)
        addr=$(jq -r ".services[$i].addr" /etc/gost/config.json)
        type=$(jq -r ".services[$i].handler.type" /etc/gost/config.json)
        echo -e "$((i+1)) ) نام: $name | پورت: $addr | نوع: $type"
    done
    
    read -p "شماره تونل (1-$services_count): " choice
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$services_count" ]; then
        echo -e "${RED}شماره نامعتبر است!${NC}"
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
    echo -e "${GREEN}تونل $service_name با موفقیت حذف شد.${NC}"
}

list_tunnels() {
    if [ ! -f /usr/local/bin/gost ]; then
        echo -e "${RED}برنامه GOST نصب نیست.${NC}"
        return 1
    fi
    
    echo -e "${CYAN}--- لیست تونل‌های فعال ---${NC}"
    services_count=$(jq '.services | length' /etc/gost/config.json)
    if [ "$services_count" -eq 0 ]; then
        echo -e "${YELLOW}هیچ تونلی ثبت نشده است.${NC}"
        return 0
    fi
    
    echo -e "-------------------------------------------------------------------------------"
    printf "%-5s | %-20s | %-12s | %-12s | %-20s\n" "ردیف" "نام سرویس" "پورت ورودی" "پروتکل" "پروکسی بالادست"
    echo -e "-------------------------------------------------------------------------------"
    for ((i=0; i<services_count; i++)); do
        name=$(jq -r ".services[$i].name" /etc/gost/config.json)
        addr=$(jq -r ".services[$i].addr" /etc/gost/config.json)
        type=$(jq -r ".services[$i].handler.type" /etc/gost/config.json)
        chain=$(jq -r ".services[$i].handler.chain // \"ندارد\"" /etc/gost/config.json)
        if [ "$chain" != "ندارد" ]; then
            chain_addr=$(jq -r --arg ch "$chain" '.chains[]? | select(.name == $ch) | .hops[0].nodes[0].addr' /etc/gost/config.json)
            chain="$chain_addr"
        fi
        printf "%-5s | %-20s | %-12s | %-12s | %-20s\n" "$((i+1))" "$name" "$addr" "$type" "$chain"
    done
    echo -e "-------------------------------------------------------------------------------"
}

manage_service() {
    if [ ! -f /usr/local/bin/gost ]; then
        echo -e "${RED}برنامه GOST نصب نیست.${NC}"
        return 1
    fi
    
    while true; do
        echo -e "\n${CYAN}--- مدیریت وضعیت سرویس سیستم ---${NC}"
        echo -e "1) نمایش وضعیت سرویس (Status)"
        echo -e "2) شروع سرویس (Start)"
        echo -e "3) توقف سرویس (Stop)"
        echo -e "4) راه‌اندازی مجدد سرویس (Restart)"
        echo -e "5) مشاهده لاگ‌های سرویس (Logs)"
        echo -e "6) بازگشت به منوی اصلی"
        read -p "انتخاب شما (1-6): " s_choice
        
        case $s_choice in
            1)
                systemctl status gost
                ;;
            2)
                systemctl start gost
                echo -e "${GREEN}سرویس شروع به کار کرد.${NC}"
                ;;
            3)
                systemctl stop gost
                echo -e "${RED}سرویس متوقف شد.${NC}"
                ;;
            4)
                systemctl restart gost
                echo -e "${GREEN}سرویس مجدداً راه‌اندازی شد.${NC}"
                ;;
            5)
                echo -e "${CYAN}در حال نمایش لاگ‌های سرویس (برای خروج Ctrl+C را بزنید)...${NC}"
                journalctl -u gost -n 50 -f
                ;;
            6)
                break
                ;;
            *)
                echo -e "${RED}انتخاب نامعتبر!${NC}"
                ;;
        esac
    done
}

uninstall_gost() {
    read -p "آیا از حذف کامل GOST مطمئن هستید؟ (y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "${YELLOW}انصراف از حذف.${NC}"
        return 0
    fi
    
    echo -e "${CYAN}در حال توقف و غیرفعال‌سازی سرویس...${NC}"
    systemctl stop gost &>/dev/null
    systemctl disable gost &>/dev/null
    rm -f /etc/systemd/system/gost.service
    systemctl daemon-reload
    
    echo -e "${CYAN}در حال حذف فایل باینری...${NC}"
    rm -f /usr/local/bin/gost
    
    read -p "آیا می‌خواهید فایل‌های پیکربندی در /etc/gost نیز حذف شوند؟ (y/n): " delete_config
    if [ "$delete_config" = "y" ] || [ "$delete_config" = "Y" ]; then
        rm -rf /etc/gost
        echo -e "${GREEN}فایل‌های تنظیمات حذف شدند.${NC}"
    fi
    
    echo -e "${GREEN}حذف کامل GOST با موفقیت انجام شد.${NC}"
}

main_menu() {
    while true; do
        show_banner
        if [ -f /usr/local/bin/gost ]; then
            status_line=$(systemctl is-active gost 2>/dev/null)
            if [ "$status_line" = "active" ]; then
                echo -e "وضعیت نرم‌افزار: ${GREEN}نصب شده و فعال (Running)${NC}"
            else
                echo -e "وضعیت نرم‌افزار: ${YELLOW}نصب شده ولی غیرفعال (Stopped)${NC}"
            fi
        else
            echo -e "وضعیت نرم‌افزار: ${RED}نصب نشده است${NC}"
        fi
        echo -e "---------------------------------------------"
        echo -e "1) نصب یا بروزرسانی GOST (آخرین نسخه)"
        echo -e "2) افزودن یک تونل جدید"
        echo -e "3) حذف یک تونل موجود"
        echo -e "4) مشاهده لیست تونل‌های فعال"
        echo -e "5) مدیریت سرویس سیستم (Start / Stop / Restart / Logs)"
        echo -e "6) حذف کامل GOST از روی سرور"
        echo -e "7) خروج"
        echo -e "---------------------------------------------"
        read -p "گزینه مورد نظر خود را وارد کنید (1-7): " choice
        
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
                echo -e "${GREEN}با تشکر از استفاده شما. خروج.${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}انتخاب نامعتبر! لطفا عددی بین 1 تا 7 وارد کنید.${NC}"
                ;;
        esac
        echo -e "\nبرای بازگشت به منو دکمه Enter را فشار دهید..."
        read -r
        clear
    done
}

# Run menu loop
clear
main_menu
