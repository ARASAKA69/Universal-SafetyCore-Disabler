#!/system/bin/sh
#
# Universal SafetyCore Disabler - Uninstaller for WEBUI
# by ARASAKA
# Version 1.0
#

# --- Set up module paths ---
MODULE_ID="SafetyCoreDisabler"
MODPATH="/data/adb/modules/$MODULE_ID"
FLAG_FILE="$MODPATH/REVERT_ON_REBOOT"
PACKAGE_NAME="com.google.android.safetycore"

echo "> USD Uninstaller Initialized..."
echo "> Stage 1: Uninstalling Placeholder..."

# uninstall the placeholder package
pm uninstall "$PACKAGE_NAME" >/dev/null 2>&1

# Verify if the uninstallation was successful
if pm path "$PACKAGE_NAME" >/dev/null 2>&1; then
    echo "[X] FAILED to uninstall the placeholder app."
    echo "This is likely due to a ROM security restriction."
    echo ""
    echo "--- ACTION REQUIRED ---"
    echo "Please manually uninstall the 'SafetyCore' app from your device's Settings -> Apps, and then try this process again."
    exit 1
fi

echo "[✓] Placeholder uninstalled successfully."
echo ""
echo "> Stage 2: Scheduling installation of official app..."

# Create flag file for service.sh after boot up.
touch "$FLAG_FILE"

if [ -f "$FLAG_FILE" ]; then
    echo ""
    echo "--- TASK SCHEDULED ---"
    echo "✅ The restoration of the official app has been scheduled."
    echo ""
    echo "Please REBOOT your device now."
    echo "The official app will be installed automatically during the next boot."
else
    echo "[X] ERROR: Could not schedule the restoration task."
fi
