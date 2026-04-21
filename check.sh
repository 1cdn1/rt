#!/bin/bash

#================================================================
# Web 服务自动化检查脚本
# 功能：全面检测服务器上运行的 Web 服务
# 版本：2.0
#================================================================

set -e

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
    if [ "$EUID" -ne 0 ]; then 
        print_warning "建议使用 root 权限运行以获取完整信息"
    fi
}

# 检测监听端口和进程
check_listening_ports() {
    print_separator
    print_title "1. 监听端口和 Web 服务进程"
    print_separator
    
    echo -e "${BLUE}端口\t进程名\t\tPID\t用户\t\t命令${NC}"
    echo "------------------------------------------------------------"
    
    # 使用 ss 或 netstat 检测
    if command -v ss >/dev/null 2>&1; then
        ss -lntp 2>/dev/null | grep LISTEN | grep -E ':(80|443|8080|8443|3000|4000|5000|8000|8888|9000)' | while read line; do
            port=$(echo "$line" | awk '{print $4}' | awk -F: '{print $NF}')
            process_info=$(echo "$line" | grep -oP 'users:\(\(".*?"\)\)' | sed 's/users:((//' | sed 's/))//')
            
            if [ -n "$process_info" ]; then
                process_name=$(echo "$process_info" | cut -d'"' -f2)
                pid=$(echo "$process_info" | grep -oP 'pid=\K[0-9]+')
                
                if [ -n "$pid" ]; then
                    user=$(ps -o user= -p "$pid" 2>/dev/null || echo "N/A")
                    cmd=$(ps -o cmd= -p "$pid" 2>/dev/null | cut -c1-50 || echo "N/A")
                    echo -e "$port\t$process_name\t\t$pid\t$user\t\t$cmd"
                fi
            fi
        done
    elif command -v netstat >/dev/null 2>&1; then
        netstat -lntp 2>/dev/null | grep LISTEN | grep -E ':(80|443|8080|8443|3000|4000|5000|8000|8888|9000)' | awk '{print $4"\t"$7}' | awk -F'[:/]' '{print $NF"\t"$1"\t"$2}'
    else
        print_error "未找到 ss 或 netstat 命令"
    fi
    echo
}

# 检测 Nginx 配置
check_nginx() {
    print_separator
    print_title "2. Nginx 配置信息"
    print_separator
    
    if command -v nginx >/dev/null 2>&1; then
        echo "Nginx 版本: $(nginx -v 2>&1 | cut -d'/' -f2)"
        echo "配置文件: $(nginx -V 2>&1 | grep -o 'conf-path=[^ ]*' | cut -d'=' -f2)"
        echo
        
        echo -e "${BLUE}虚拟主机列表:${NC}"
        echo "------------------------------------------------------------"
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
        
        echo
        echo "Nginx 进程状态:"
        ps aux | grep nginx | grep -v grep
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
        APACHE_CMD=$(command -v apache2 || command -v httpd)
        
        echo "Apache 版本: $($APACHE_CMD -v | head -n1)"
        echo
        
        echo -e "${BLUE}虚拟主机列表:${NC}"
        echo "------------------------------------------------------------"
        
        if command -v apachectl >/dev/null 2>&1; then
            apachectl -S 2>/dev/null | grep -E 'port|namevhost' | head -20
        elif command -v apache2ctl >/dev/null 2>&1; then
            apache2ctl -S 2>/dev/null | grep -E 'port|namevhost' | head -20
        fi
        
        echo
        echo "Apache 进程状态:"
        ps aux | grep -E 'apache2|httpd' | grep -v grep
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
    )
    
    for cert_path in "${cert_paths[@]}"; do
        if [ -d "$cert_path" ]; then
            echo "证书目录: $cert_path"
            find "$cert_path" -name "*.crt" -o -name "*.pem" 2>/dev/null | while read cert; do
                if [ -f "$cert" ]; then
                    echo "  证书: $cert"
                    openssl x509 -in "$cert" -noout -subject -dates 2>/dev/null | sed 's/^/    /'
                fi
            done
        fi
    done
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
    )
    
    echo -e "${BLUE}目录\t\t\t权限\t所有者\t大小${NC}"
    echo "------------------------------------------------------------"
    
    for root_pattern in "${web_roots[@]}"; do
        for web_root in $root_pattern; do
            if [ -d "$web_root" ]; then
                perms=$(stat -c "%a" "$web_root" 2>/dev/null || stat -f "%Lp" "$web_root" 2>/dev/null)
                owner=$(stat -c "%U:%G" "$web_root" 2>/dev/null || stat -f "%Su:%Sg" "$web_root" 2>/dev/null)
                size=$(du -sh "$web_root" 2>/dev/null | cut -f1)
                echo -e "$web_root\t$perms\t$owner\t$size"
            fi
        done
    done
    echo
}

# 检测防火墙规则
check_firewall() {
    print_separator
    print_title "7. 防火墙规则 (Web 相关端口)"
    print_separator
    
    if command -v iptables >/dev/null 2>&1; then
        echo "iptables 规则:"
        iptables -L -n 2>/dev/null | grep -E '80|443|8080' || echo "无相关规则"
    fi
    
    if command -v firewall-cmd >/dev/null 2>&1; then
        echo
        echo "firewalld 规则:"
        firewall-cmd --list-all 2>/dev/null | grep -E 'services|ports'
    fi
    
    if command -v ufw >/dev/null 2>&1; then
        echo
        echo "UFW 状态:"
        ufw status 2>/dev/null | grep -E '80|443|8080'
    fi
    echo
}

# 生成摘要报告
generate_summary() {
    print_separator
    print_title "8. 检查摘要"
    print_separator
    
    echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "主机名: $(hostname)"
    echo "系统: $(uname -s) $(uname -r)"
    echo
    
    web_ports=$(ss -lntp 2>/dev/null | grep LISTEN | grep -E ':(80|443|8080|8443)' | wc -l)
    echo "活跃 Web 端口数: $web_ports"
    
    if command -v nginx >/dev/null 2>&1; then
        nginx_sites=$(nginx -T 2>/dev/null | grep -c "server_name" || echo 0)
        echo "Nginx 虚拟主机数: $nginx_sites"
    fi
    
    if pgrep -f node >/dev/null 2>&1; then
        node_processes=$(pgrep -f node | wc -l)
        echo "Node.js 进程数: $node_processes"
    fi
    
    echo
    print_separator
}

# 主函数
main() {
    clear
    echo -e "${GREEN}"
    echo "================================================================"
    echo "           Web 服务自动化检查工具 v2.0"
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
}

# 执行主函数
main