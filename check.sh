#!/bin/bash

#================================================================
# Web 服务自动化检查脚本
# 功能：全面检测服务器上运行的 Web 服务
# 版本：2.1 - 兼容非 root 用户
#================================================================

# 移除 set -e，避免权限不足时直接退出
set +e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 输出分隔线
print_separator() {
    echo -e "${BLUE}================================================================${NC}"
}

# 输出标题
print_title() {
    echo -e "${GREEN}$1${NC}"
}

# 输出警告
print_warning() {
    echo -e "${YELLOW}[警告] $1${NC}"
}

# 输出错误
print_error() {
    echo -e "${RED}[错误] $1${NC}"
}

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -eq 0 ] 2>/dev/null || [ "$(id -u)" -eq 0 ] 2>/dev/null; then 
        IS_ROOT=1
        echo -e "${GREEN}[✓] 当前用户: root (完整权限)${NC}"
    else
        IS_ROOT=0
        print_warning "当前用户: $(whoami) (部分功能可能受限)"
    fi
    echo
}

# 检测监听端口和进程
check_listening_ports() {
    print_separator
    print_title "1. 监听端口和 Web 服务进程"
    print_separator
    
    echo -e "${BLUE}端口\t进程名\t\tPID\t用户\t\t命令${NC}"
    echo "------------------------------------------------------------"
    
    # 尝试多种方法检测端口
    if command -v ss >/dev/null 2>&1; then
        # 使用 ss，非 root 也能看到部分信息
        ss -lntp 2>/dev/null | grep LISTEN | grep -E ':(80|443|8080|8443|3000|4000|5000|8000|8888|9000|9090)' | while read line; do
            port=$(echo "$line" | awk '{print $4}' | awk -F: '{print $NF}')
            process_info=$(echo "$line" | grep -oP 'users:\(\(".*?"\)\)' 2>/dev/null | sed 's/users:((//' | sed 's/))//')
            
            if [ -n "$process_info" ]; then
                process_name=$(echo "$process_info" | cut -d'"' -f2)
                pid=$(echo "$process_info" | grep -oP 'pid=\K[0-9]+' 2>/dev/null)
                
                if [ -n "$pid" ]; then
                    user=$(ps -o user= -p "$pid" 2>/dev/null || echo "N/A")
                    cmd=$(ps -o cmd= -p "$pid" 2>/dev/null | cut -c1-40 || echo "N/A")
                    echo -e "$port\t$process_name\t\t$pid\t$user\t\t$cmd"
                fi
            else
                # 非 root 用户可能看不到进程信息，只显示端口
                echo -e "$port\t-\t\t-\t-\t\t(需要 root 权限查看)"
            fi
        done
    elif command -v netstat >/dev/null 2>&1; then
        netstat -lntp 2>/dev/null | grep LISTEN | grep -E ':(80|443|8080|8443|3000|4000|5000|8000|8888|9090)' | awk '{print $4"\t"$7}' | awk -F'[:/]' '{print $NF"\t"$1"\t"$2}' 2>/dev/null
    else
        # 如果没有 ss 和 netstat，尝试使用 lsof
        if command -v lsof >/dev/null 2>&1; then
            lsof -i -P -n 2>/dev/null | grep LISTEN | grep -E ':(80|443|8080|8443|3000|4000|5000|8000|8888|9090)' | awk '{print $9"\t"$1"\t"$2"\t"$3}' | sed 's/*://'
        else
            print_error "未找到 ss、netstat 或 lsof 命令"
        fi
    fi
    
    # 额外检查：通过进程查找 web 服务
    echo
    echo -e "${BLUE}通过进程名检测到的 Web 服务:${NC}"
    ps aux 2>/dev/null | grep -E 'nginx|apache|httpd|node|python.*flask|python.*django|java.*tomcat' | grep -v grep | awk '{print $1"\t"$2"\t"$11}' | head -10
    echo
}

# 检测 Nginx 配置
check_nginx() {
    print_separator
    print_title "2. Nginx 配置信息"
    print_separator
    
    if command -v nginx >/dev/null 2>&1; then
        echo "Nginx 版本: $(nginx -v 2>&1 | cut -d'/' -f2)"
        
        # 尝试获取配置文件路径
        conf_path=$(nginx -V 2>&1 | grep -o 'conf-path=[^ ]*' | cut -d'=' -f2)
        if [ -n "$conf_path" ]; then
            echo "配置文件: $conf_path"
        fi
        echo
        
        echo -e "${BLUE}虚拟主机列表:${NC}"
        echo "------------------------------------------------------------"
        
        # 尝试读取配置，如果没权限则跳过
        if nginx -T >/dev/null 2>&1; then
            echo -e "域名\t\t\t监听端口\tSSL\t根目录"
            echo "------------------------------------------------------------"
            
            nginx -T 2>/dev/null | awk '
            /server {/,/}/ {
                if ($1 == "listen") {
                    port = $2;
                    gsub(/;/, "", port);
                    if (port ~ /ssl/) ssl = "是";
                    else ssl = "否";
                }
                if ($1 == "server_name") {
                    for(i=2; i<=NF; i++) {
                        domain = $i;
                        gsub(/;/, "", domain);
                        if (domain != "_") domains = domains domain " ";
                    }
                }
                if ($1 == "root") {
                    root = $2;
                    gsub(/;/, "", root);
                }
                if (/^}$/ && domains != "") {
                    printf "%s\t%s\t%s\t%s\n", domains, port, ssl, root;
                    domains = "";
                    port = "";
                    ssl = "";
                    root = "";
                }
            }'
        else
            print_warning "无权限读取 Nginx 配置，尝试查找配置文件..."
            
            # 尝试查找并读取配置文件
            for conf in /etc/nginx/nginx.conf /etc/nginx/sites-enabled/* /usr/local/nginx/conf/nginx.conf; do
                if [ -r "$conf" ] 2>/dev/null; then
                    echo "可读配置: $conf"
                    grep -E "server_name|listen|root" "$conf" 2>/dev/null | head -10
                fi
            done
        fi
        
        echo
        echo "Nginx 进程状态:"
        ps aux 2>/dev/null | grep nginx | grep -v grep || echo "无法查看进程信息"
    else
        print_warning "未检测到 Nginx"
    fi
    echo
}

# 检测 Apache 配置
check_apache() {
    print_separator
    print_title "3. Apache 配置信息"
    print_separator
    
    if command -v apache2 >/dev/null 2>&1 || command -v httpd >/dev/null 2>&1; then
        APACHE_CMD=$(command -v apache2 2>/dev/null || command -v httpd 2>/dev/null)
        
        if [ -n "$APACHE_CMD" ]; then
            echo "Apache 版本: $($APACHE_CMD -v 2>/dev/null | head -n1 || echo '无法获取')"
            echo
            
            echo -e "${BLUE}虚拟主机列表:${NC}"
            echo "------------------------------------------------------------"
            
            if command -v apachectl >/dev/null 2>&1; then
                apachectl -S 2>/dev/null | grep -E 'port|namevhost' | head -20 || print_warning "无权限读取 Apache 配置"
            elif command -v apache2ctl >/dev/null 2>&1; then
                apache2ctl -S 2>/dev/null | grep -E 'port|namevhost' | head -20 || print_warning "无权限读取 Apache 配置"
            fi
            
            echo
            echo "Apache 进程状态:"
            ps aux 2>/dev/null | grep -E 'apache2|httpd' | grep -v grep || echo "无法查看进程信息"
        fi
    else
        print_warning "未检测到 Apache"
    fi
    echo
}

# 检测其他 Web 服务
check_other_services() {
    print_separator
    print_title "4. 其他 Web 服务"
    print_separator
    
    # Tomcat
    if pgrep -f tomcat >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Tomcat${NC}"
        ps aux | grep tomcat | grep -v grep | head -3
        echo
    fi
    
    # Node.js
    if pgrep -f node >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Node.js 应用${NC}"
        ps aux | grep node | grep -v grep | head -5
        echo
    fi
    
    # Python Web 服务
    if pgrep -f "python.*\(flask\|django\|gunicorn\|uvicorn\)" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Python Web 应用${NC}"
        ps aux | grep -E 'flask|django|gunicorn|uvicorn' | grep -v grep | head -5
        echo
    fi
    
    # Docker 容器中的 Web 服务
    if command -v docker >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Docker 容器 Web 服务${NC}"
        docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}" 2>/dev/null | grep -E '80|443|8080' || echo "无相关容器"
        echo
    fi
}

# 检测 SSL 证书
check_ssl_certificates() {
    print_separator
    print_title "5. SSL/TLS 证书信息"
    print_separator
    
    # 查找常见证书位置
    cert_paths=(
        "/etc/nginx/ssl"
        "/etc/nginx/certs"
        "/etc/ssl/certs"
        "/etc/letsencrypt/live"
        "/etc/apache2/ssl"
        "/etc/httpd/ssl"
        "$HOME/.ssl"
        "$HOME/ssl"
    )
    
    found_certs=0
    for cert_path in "${cert_paths[@]}"; do
        if [ -d "$cert_path" ] && [ -r "$cert_path" ]; then
            echo "证书目录: $cert_path"
            find "$cert_path" -name "*.crt" -o -name "*.pem" 2>/dev/null | while read cert; do
                if [ -f "$cert" ] && [ -r "$cert" ]; then
                    echo "  证书: $cert"
                    openssl x509 -in "$cert" -noout -subject -dates 2>/dev/null | sed 's/^/    /' || echo "    (无法读取证书内容)"
                    found_certs=1
                fi
            done
        fi
    done
    
    if [ $found_certs -eq 0 ]; then
        print_warning "未找到可读的 SSL 证书或无访问权限"
    fi
    echo
}

# 检测 Web 根目录
check_web_roots() {
    print_separator
    print_title "6. Web 根目录和权限"
    print_separator
    
    web_roots=(
        "/var/www"
        "/usr/share/nginx"
        "/home/*/public_html"
        "/opt/*/webapps"
        "$HOME/www"
        "$HOME/public_html"
    )
    
    echo -e "${BLUE}目录\t\t\t权限\t所有者\t大小${NC}"
    echo "------------------------------------------------------------"
    
    found_roots=0
    for root_pattern in "${web_roots[@]}"; do
        # 使用 eval 来展开通配符
        for web_root in $(eval echo $root_pattern 2>/dev/null); do
            if [ -d "$web_root" ] && [ -r "$web_root" ]; then
                # 兼容 Linux 和 BSD 的 stat 命令
                perms=$(stat -c "%a" "$web_root" 2>/dev/null || stat -f "%Lp" "$web_root" 2>/dev/null || echo "N/A")
                owner=$(stat -c "%U:%G" "$web_root" 2>/dev/null || stat -f "%Su:%Sg" "$web_root" 2>/dev/null || echo "N/A")
                size=$(du -sh "$web_root" 2>/dev/null | cut -f1 || echo "N/A")
                echo -e "$web_root\t$perms\t$owner\t$size"
                found_roots=1
            fi
        done
    done
    
    if [ $found_roots -eq 0 ]; then
        print_warning "未找到常见的 Web 根目录或无访问权限"
    fi
    echo
}

# 检测防火墙规则
check_firewall() {
    print_separator
    print_title "7. 防火墙规则 (Web 相关端口)"
    print_separator
    
    firewall_found=0
    
    if command -v iptables >/dev/null 2>&1; then
        echo "iptables 规则:"
        if iptables -L -n 2>/dev/null | grep -E '80|443|8080'; then
            firewall_found=1
        else
            if [ $IS_ROOT -eq 0 ]; then
                print_warning "需要 root 权限查看 iptables"
            else
                echo "无相关规则"
            fi
        fi
    fi
    
    if command -v firewall-cmd >/dev/null 2>&1; then
        echo
        echo "firewalld 规则:"
        if firewall-cmd --list-all 2>/dev/null | grep -E 'services|ports'; then
            firewall_found=1
        else
            print_warning "无法读取 firewalld 配置"
        fi
    fi
    
    if command -v ufw >/dev/null 2>&1; then
        echo
        echo "UFW 状态:"
        if ufw status 2>/dev/null | grep -E '80|443|8080'; then
            firewall_found=1
        else
            print_warning "无法读取 UFW 配置"
        fi
    fi
    
    if [ $firewall_found -eq 0 ]; then
        print_warning "未检测到防火墙或无权限查看"
    fi
    echo
}

# 生成摘要报告
generate_summary() {
    print_separator
    print_title "8. 检查摘要"
    print_separator
    
    echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "主机名: $(hostname 2>/dev/null || echo 'N/A')"
    echo "系统: $(uname -s 2>/dev/null || echo 'N/A') $(uname -r 2>/dev/null || echo '')"
    echo "当前用户: $(whoami 2>/dev/null || echo 'N/A')"
    echo
    
    # 统计 web 端口
    web_ports=$(ss -lntp 2>/dev/null | grep LISTEN | grep -E ':(80|443|8080|8443)' | wc -l 2>/dev/null || echo 0)
    echo "活跃 Web 端口数: $web_ports"
    
    # 统计 Nginx
    if command -v nginx >/dev/null 2>&1; then
        nginx_sites=$(nginx -T 2>/dev/null | grep -c "server_name" 2>/dev/null || echo "N/A")
        echo "Nginx 虚拟主机数: $nginx_sites"
    fi
    
    # 统计 Node.js
    if pgrep -f node >/dev/null 2>&1; then
        node_processes=$(pgrep -f node 2>/dev/null | wc -l || echo 0)
        echo "Node.js 进程数: $node_processes"
    fi
    
    # 统计 Python web 应用
    python_web=$(ps aux 2>/dev/null | grep -E 'flask|django|gunicorn|uvicorn' | grep -v grep | wc -l || echo 0)
    if [ $python_web -gt 0 ]; then
        echo "Python Web 进程数: $python_web"
    fi
    
    echo
    print_separator
}

# 主函数
main() {
    clear
    echo -e "${GREEN}"
    echo "================================================================"
    echo "           Web 服务自动化检查工具 v2.1"
    echo "           兼容 root 和普通用户权限"
    echo "================================================================"
    echo -e "${NC}"
    
    check_root
    check_listening_ports
    check_nginx
    check_apache
    check_other_services
    check_ssl_certificates
    check_web_roots
    check_firewall
    generate_summary
    
    echo -e "${GREEN}检查完成！${NC}"
    echo
    if [ $IS_ROOT -eq 0 ]; then
        echo -e "${YELLOW}提示: 使用 root 权限运行可获取更完整的信息${NC}"
        echo -e "${YELLOW}命令: sudo $0${NC}"
    fi
}

# 执行主函数
main "$@"
