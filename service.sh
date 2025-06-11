#!/system/bin/sh
#
# Universal SafetyCore Disabler - With Boot-time Restore Service
# by ARASAKA
# Version 1.0
#


sleep 30

# --- Paths ---
MODPATH=${0%/*}
FLAG_FILE="$MODPATH/REVERT_ON_REBOOT"
LOG_FILE="$MODPATH/revert_log.txt"
PACKAGE_NAME="com.google.android.safetycore"
OFFICIAL_APKM="$MODPATH/common/Safetycore-official.apkm"
STATUS_FILE="$MODPATH/status.log"
PROP_FILE="$MODPATH/module.prop"

# --- Function to wait for package manager to be ready ---
wait_for_pm() {
    local timeout=60; local count=0;
    echo "Waiting for package manager to be ready..." >> "$LOG_FILE"
    while [ $count -lt $timeout ]; do
        if pm list packages >/dev/null 2>&1; then
            echo "Package manager ready after ${count}s" >> "$LOG_FILE"; return 0;
        fi
        sleep 1; count=$((count + 1));
    done
    echo "Package manager not ready after ${timeout}s" >> "$LOG_FILE"; return 1;
}

# --- Function to install APKM ---
install_apkm() {
    local apkm_file="$1"; local temp_dir="/data/local/tmp/apkm_install_$$";
    mkdir -p "$temp_dir"; echo "Extracting APKM to: $temp_dir" >> "$LOG_FILE";
    unzip -o "$apkm_file" -d "$temp_dir" >> "$LOG_FILE" 2>&1;
    if [ $? -ne 0 ]; then echo "[X] Failed to extract APKM" >> "$LOG_FILE"; rm -rf "$temp_dir"; return 1; fi
    local apk_files=$(find "$temp_dir" -name "*.apk" | sort);
    if [ -z "$apk_files" ]; then echo "[X] No APK files found" >> "$LOG_FILE"; rm -rf "$temp_dir"; return 1; fi
    local total_size=0; for apk in $apk_files; do local apk_size=$(stat -c %s "$apk"); total_size=$((total_size + apk_size)); done;
    echo "Total APK size: $total_size bytes" >> "$LOG_FILE";
    local session_id=""; local retry_count=0; local max_retries=3;
    while [ $retry_count -lt $max_retries ] && [ -z "$session_id" ]; do
        echo "Creating install session (attempt $((retry_count + 1)))" >> "$LOG_FILE";
        local session_output=$(pm install-create -S "$total_size" 2>&1);
        session_id=$(echo "$session_output" | grep -o '\[.*\]' | tr -d '[]');
        echo "Session creation output: $session_output" >> "$LOG_FILE";
        if [ -z "$session_id" ]; then retry_count=$((retry_count + 1)); sleep 2; fi
    done
    if [ -z "$session_id" ]; then echo "[X] Failed to create install session after $max_retries attempts" >> "$LOG_FILE"; rm -rf "$temp_dir"; return 1; fi
    echo "Created session: $session_id" >> "$LOG_FILE";
    local install_success=true; local apk_index=0;
    for apk_file in $apk_files; do
        local apk_name=$(basename "$apk_file"); local apk_size=$(stat -c %s "$apk_file");
        echo "Installing: $apk_name (${apk_size} bytes)" >> "$LOG_FILE";
        local write_success=false; local write_retry=0; local max_write_retries=2;
        while [ $write_retry -lt $max_write_retries ] && [ "$write_success" = false ]; do
            local write_output=$(pm install-write -S "$apk_size" "$session_id" "${apk_index}.apk" "$apk_file" 2>&1);
            if [ $? -eq 0 ]; then write_success=true; echo "✓ Successfully wrote $apk_name" >> "$LOG_FILE";
            else write_retry=$((write_retry + 1)); echo "⚠ Write attempt $write_retry failed for $apk_name: $write_output" >> "$LOG_FILE"; if [ $write_retry -lt $max_write_retries ]; then sleep 1; fi; fi
        done
        if [ "$write_success" = false ]; then echo "[X] Failed to write $apk_name after $max_write_retries attempts" >> "$LOG_FILE"; install_success=false; break; fi
        apk_index=$((apk_index + 1));
    done
    if [ "$install_success" = true ]; then
        local commit_output=$(pm install-commit "$session_id" 2>&1); echo "Commit output: $commit_output" >> "$LOG_FILE";
        if echo "$commit_output" | grep -q "Success"; then echo "✅ Installation committed successfully" >> "$LOG_FILE"; rm -rf "$temp_dir"; return 0;
        else echo "[X] Failed to commit installation" >> "$LOG_FILE"; rm -rf "$temp_dir"; return 1; fi
    else
        echo "Abandoning session due to write failures..." >> "$LOG_FILE"; pm install-abandon "$session_id" >> "$LOG_FILE" 2>&1; rm -rf "$temp_dir"; return 1;
    fi
}

# --- Main Logic ---
if [ -f "$FLAG_FILE" ]; then
    echo "--- ARASAKA Boot Restore Service ---" > "$LOG_FILE"; echo "Revert flag detected. Starting restoration at $(date)" >> "$LOG_FILE";
    if ! wait_for_pm; then
        echo "[X] Package manager not ready, aborting" >> "$LOG_FILE"; echo "ERROR:Package manager not ready during boot" > "$STATUS_FILE";
        sed -i 's/ [✅ℹ️❌] Status:.*//g' "$PROP_FILE"; sed -i "/^description=/ s/$/ ❌ Status: PM Not Ready/" "$PROP_FILE";
        rm -f "$FLAG_FILE"; exit 1;
    fi
    if [ ! -f "$OFFICIAL_APKM" ]; then
        echo "[X] APKM file not found: $OFFICIAL_APKM" >> "$LOG_FILE"; echo "ERROR:APKM file not found" > "$STATUS_FILE";
        sed -i 's/ [✅ℹ️❌] Status:.*//g' "$PROP_FILE"; sed -i "/^description=/ s/$/ ❌ Status: APKM Missing/" "$PROP_FILE";
        rm -f "$FLAG_FILE"; exit 1;
    fi
    echo "Installing official APKM bundle..." >> "$LOG_FILE";
    if install_apkm "$OFFICIAL_APKM"; then
        sleep 2;
        if pm path "$PACKAGE_NAME" >/dev/null 2>&1; then
            echo "✅ SUCCESS: Official app restored and verified." >> "$LOG_FILE";
            echo "INACTIVE:Official app has been restored. You can now safely uninstall this module from Magisk." > "$STATUS_FILE";
            sed -i 's/ [✅ℹ️❌] Status:.*//g' "$PROP_FILE";
            sed -i "/^description=/ s/$/ ℹ️ Status: Reverted to Official/" "$PROP_FILE";
        else
            echo "[X] Installation succeeded but package verification failed" >> "$LOG_FILE";
            echo "ERROR:Package not found after installation" > "$STATUS_FILE";
            sed -i 's/ [✅ℹ️❌] Status:.*//g' "$PROP_FILE"; sed -i "/^description=/ s/$/ ❌ Status: Verification Failed/" "$PROP_FILE";
        fi
    else
        echo "❌ FAILED: Could not restore official app automatically." >> "$LOG_FILE";
        echo "ERROR:Automatic restore failed. Check revert_log.txt for details." > "$STATUS_FILE";
        sed -i 's/ [✅ℹ️❌] Status:.*//g' "$PROP_FILE"; sed -i "/^description=/ s/$/ ❌ Status: Revert Failed/" "$PROP_FILE";
    fi
    rm -f "$FLAG_FILE"; echo "Process finished at $(date)." >> "$LOG_FILE";
fi
