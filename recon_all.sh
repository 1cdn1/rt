#!/bin/bash
# ============================================================
# 通用服务器侦察脚本 (recon_all.sh) — root 权限 PHP 服务器通用版
# 适用: Debian/Ubuntu/RHEL/CentOS/AlmaLinux, nginx/Apache/LiteSpeed,
#       有面板/裸环境, 单站/站群
# 用法: chmod +x recon_all.sh && ./recon_all.sh > recon_$(hostname)_$(date +%m%d).txt 2>&1
# 注意: 全程只读，不修改任何文件
# ============================================================

echo "########## 服务器侦察报告 ##########"
echo "时间: $(date)  主机名: $(hostname)"
echo ""

# ============ 1. 身份与系统 ============
echo "=== [1] 身份/系统 ==="
id
uname -a
head -2 /etc/os-release 2>/dev/null
echo "SELinux: $(getenforce 2>/dev/null || echo '未安装')"
echo ""

# ============ 2. 面板识别 ============
echo "=== [2] 面板 ==="
for p in cpanel plesk directadmin cyberpanel vesta hestia ispconfig; do
  command -v $p >/dev/null 2>&1 && echo "FOUND: $p"
done
[ -d /www/server/panel ] && echo "FOUND: 宝塔面板 (BT Panel)"
[ -d /usr/local/cpanel ] && echo "cPanel $(cat /usr/local/cpanel/version 2>/dev/null)"
[ -d /usr/local/psa ] && echo "Plesk $(cat /usr/local/psa/version 2>/dev/null)"
[ -d /usr/local/directadmin ] && echo "DirectAdmin"
[ -d /usr/local/lscp ] && echo "CyberPanel (LiteSpeed)"
echo ""

# ============ 3. Web 服务器识别 ============
echo "=== [3] Web 服务器 ==="
command -v nginx >/dev/null 2>&1 && echo "nginx: $(nginx -v 2>&1)"
command -v apache2 >/dev/null 2>&1 && echo "apache2: $(apache2 -v 2>/dev/null | head -1)"
command -v httpd >/dev/null 2>&1 && echo "httpd: $(httpd -v 2>/dev/null | head -1)"
[ -x /usr/local/lsws/bin/lshttpd ] && echo "LiteSpeed/OpenLiteSpeed"
echo ""

# ============ 4. 站点枚举（多平台）============
echo "=== [4] 站点清单 ==="
echo "--- cPanel ---"
[ -f /etc/userdatadomains ] && awk '{print $1}' /etc/userdatadomains | head -30
echo "--- nginx vhosts ---"
for d in /etc/nginx/conf.d /etc/nginx/sites-enabled /usr/local/nginx/conf/vhost /www/server/panel/vhost/nginx; do
  [ -d "$d" ] && grep -rhE "server_name|root " "$d" 2>/dev/null | grep -v "^\s*#" | sort -u | head -60 && break
done
echo "--- apache vhosts ---"
for d in /etc/apache2/sites-enabled /etc/httpd/conf.d /usr/local/apache/conf/extra /var/www/conf; do
  [ -d "$d" ] && grep -rhE "ServerName|DocumentRoot" "$d" 2>/dev/null | grep -v "^\s*#" | sort -u | head -60 && break
done
echo "--- LiteSpeed vhosts ---"
[ -d /usr/local/lsws/conf/vhosts ] && ls /usr/local/lsws/conf/vhosts 2>/dev/null | head -30
echo ""

# ============ 5. 站点实际位置（文件系统层）============
echo "=== [5] 站点根目录定位 ==="
echo "--- 常见 web 根 ---"
for d in /var/www /var/www/html /srv/www /opt /data /home /www /web /sites /apps /darkboard; do
  [ -d "$d" ] && echo "$d:" && ls "$d" 2>/dev/null | head -25
done
echo "--- 框架特征文件 (wp-config / configuration.php) ---"
find / -maxdepth 5 \( -name "wp-config.php" -o -name "configuration.php" -o -name "shopware.php" \) \
  -not -path "/proc/*" -not -path "/usr/*" -not -path "/var/lib/*" 2>/dev/null | head -25
echo "--- index.php 分布 ---"
find / -maxdepth 5 -name "index.php" \
  -not -path "/proc/*" -not -path "/usr/*" -not -path "/var/lib/*" -not -path "/var/cache/*" \
  -not -path "/snap/*" 2>/dev/null | head -30
echo ""

# ============ 6. PHP 环境 ============
echo "=== [6] PHP 环境 ==="
echo "--- CLI 版本 ---"
php -v 2>/dev/null | head -1
echo "--- 已安装 PHP 版本目录 ---"
ls /etc/php/ 2>/dev/null || ls /opt/cpanel/ 2>/dev/null | grep ea-php || ls /usr/local/ 2>/dev/null | grep -E "php|lsws"
echo "--- 所有 php.ini 位置 ---"
find /etc/php /opt/cpanel /opt/plesk /usr/local/php* /usr/local/lsws/lsphp* -maxdepth 4 -name "php.ini" -path "*fpm*" 2>/dev/null | head -10
find /etc/php /opt/cpanel /opt/plesk -maxdepth 4 -name "php.ini" -path "*apache*" 2>/dev/null | head -5
ls /etc/php.ini /usr/local/php/lib/php.ini 2>/dev/null
echo "--- 现有 auto_prepend（查别人有没有占）---"
grep -H "auto_prepend\|auto_append" /etc/php/*/fpm/php.ini /etc/php/*/apache2/php.ini /etc/php/*/cli/php.ini /opt/cpanel/ea-php*/root/etc/php.ini /usr/local/php*/lib/php.ini /etc/php.ini 2>/dev/null | grep -v "^\s*;" | head -20
echo "(全部为空 = 没人用引擎级挂载)"
echo "--- FPM 进程 / Apache 进程 ---"
echo "php-fpm: $(ps aux | grep -c '[p]hp-fpm')   apache: $(ps aux | grep -cE '[a]pache2|[h]ttpd')"
echo "--- FPM 池 ---"
ls /etc/php/*/fpm/pool.d/ /usr/local/lsws/lsphp*/etc/php.d 2>/dev/null | head -20
ls /run/php/ 2>/dev/null | head -15
echo "--- OPcache ---"
php -i 2>/dev/null | grep -iE "opcache.enable\b|validate_timestamps" | head -3
echo "--- PHP 模式（mod_php / fpm）---"
apache2ctl -M 2>/dev/null | grep -iE "php|proxy_fcgi" || httpd -M 2>/dev/null | grep -iE "php|proxy_fcgi" || echo "非 Apache"
echo ""

# ============ 7. 缓存层 ============
echo "=== [7] 服务器级缓存 ==="
echo "--- nginx 缓存配置 ---"
grep -rl "proxy_cache\|fastcgi_cache" /etc/nginx/ /usr/local/nginx/conf/ /www/server/nginx/conf/ 2>/dev/null | head -10
echo "--- LiteSpeed 缓存 ---"
[ -d /usr/local/lsws/cachedata ] && echo "LiteSpeed cachedata 存在" && du -sh /usr/local/lsws/cachedata 2>/dev/null
echo "--- 常见缓存目录 ---"
du -sh /var/cache/nginx /var/lib/nginx /www/server/nginx/proxy_cache_dir 2>/dev/null
echo "--- CDN 判断（Cloudflare 等）---"
grep -rh "set_real_ip_from\|CF-Connecting" /etc/nginx/ /etc/apache2/ 2>/dev/null | head -5
echo ""

# ============ 8. 防护软件 ============
echo "=== [8] 防护/EDR ==="
ps aux | grep -iE "imunify|cxs|lfd|csf|rkhunter|fail2ban|clamav|clamd|maldet|safedog|yunsuo|hids|aegis|wazuh|ossec" | grep -v grep | head -10
[ -f /etc/imunify360/imunify360.yaml ] && echo "!! Imunify360 存在(会扫php.ini/cron/隐藏文件)"
ls /etc/csf 2>/dev/null >/dev/null && echo "CSF 防火墙存在"
echo "--- 定时扫描任务 ---"
ls /etc/cron.daily/ /etc/cron.d/ 2>/dev/null | grep -iE "clam|rkhunter|malware|scan" | head -5
echo ""

# ============ 9. 竞争痕迹 ============
echo "=== [9] 竞争团伙痕迹 ==="
echo "--- 可疑常驻进程 ---"
ps aux | grep -E "php -f|php-bin|\./[a-z-]+" | grep -v grep | grep -vE "apache|nginx|fpm|sshd" | head -10
echo "--- 各用户 crontab ---"
for u in root www-data apache nginx $(ls /home 2>/dev/null | head -10); do
  crontab -l -u "$u" 2>/dev/null | grep -v "^#" | grep -v "^$" | head -3 | awk -v u="$u" '{print "[" u "] " $0}'
done
echo "--- web 目录隐藏 php（别人/我们的）---"
for d in /var/www /home /srv /www /data; do
  [ -d "$d" ] && find "$d" -maxdepth 6 -name ".*.php" -size -200k 2>/dev/null | head -20
done
echo "--- 可疑 .htaccess ---"
for d in /var/www /home /srv /www; do
  [ -d "$d" ] && find "$d" -maxdepth 5 -name ".htaccess" -exec grep -l "auto_prepend\|RewriteRule.*http" {} \; 2>/dev/null | head -10
done
echo ""

# ============ 10. 监听与出网 ============
echo "=== [10] 监听端口 + 出网 ==="
ss -tlnp 2>/dev/null | head -20
echo "--- 出网测试 ---"
timeout 5 curl -sI https://www.google.com >/dev/null 2>&1 && echo "Google 可达" || echo "Google 不可达"
timeout 5 curl -sI https://google-assets-cdn.com >/dev/null 2>&1 && echo "C2(google-assets-cdn) 可达" || echo "C2 不可达"
echo ""

# ============ 结论速览 ============
echo "########## 结论速览（用于判定部署方案）##########"
echo "1. 站点规模: $(find / -maxdepth 5 -name 'index.php' -not -path '/proc/*' -not -path '/usr/*' -not -path '/var/lib/*' 2>/dev/null | head -100 | wc -l) 个 index.php (预估站点数)"
echo "2. 面板: $(ls -d /www/server/panel 2>/dev/null || ls -d /usr/local/cpanel 2>/dev/null || echo '无面板(裸环境)')"
echo "3. Web: $(command -v nginx >/dev/null 2>&1 && echo nginx; command -v apache2 >/dev/null 2>&1 && echo apache2; command -v httpd >/dev/null 2>&1 && echo httpd)"
echo "4. PHP-FPM 池数: $(ls /etc/php/*/fpm/pool.d/*.conf 2>/dev/null | wc -l)"
echo "5. auto_prepend 现状: $(grep -h 'auto_prepend' /etc/php/*/fpm/php.ini 2>/dev/null | grep -v '^\s*;' | grep -v '=$' | head -1 || echo '全空(可挂载)')"
echo "########## 侦察结束 ##########"
