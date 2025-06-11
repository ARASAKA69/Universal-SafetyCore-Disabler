#!/system/bin/sh
#
# Universal SafetyCore Disabler - WebUI Launcher
# by ARASAKA
# Version 1.0
#

MODULE_ID="SafetyCoreDisabler"
MODPATH="/data/adb/modules/$MODULE_ID"
ORG_PATH="$PATH"
TMP_DIR="$MODPATH/common/tmp"
APK_PATH="$TMP_DIR/base.apk"

manual_download() {
    echo "$1"
    sleep 3
    am start -a android.intent.action.VIEW -d "https://github.com/5ec1cff/KsuWebUIStandalone/releases"
    exit 1
}

download() {
    PATH=/data/adb/magisk:/data/data/com.termux/files/usr/bin:$PATH
    if command -v curl >/dev/null 2>&1; then
        timeout 10 curl -Ls "$1"
    else
        timeout 10 busybox wget --no-check-certificate -qO- "$1"
    fi
    PATH="$ORG_PATH"
}

get_webui_host() {
    echo "- Downloading KSU WebUI Standalone..."
    mkdir -p "$TMP_DIR"
    API="https://api.github.com/repos/5ec1cff/KsuWebUIStandalone/releases/latest"
    ping -c 1 -w 5 raw.githubusercontent.com &>/dev/null || manual_download "! Error: Unable to connect to GitHub, please download manually."
    URL=$(download "$API" | grep -o '"browser_download_url": "[^"]*"' | cut -d '"' -f 4) || manual_download "! Error: Unable to get latest version, please download manually."
    download "$URL" > "$APK_PATH" || manual_download "! Error: APK download failed, please download manually."
    echo "- Installing WebUI Host App..."
    pm install -r "$APK_PATH" || { rm -f "$APK_PATH"; manual_download "! Error: WebUI Host installation failed, please download manually."; }
    echo "- Done."
    rm -rf "$TMP_DIR"
}


# --- Launching WebUI ---
echo "- Initializing SafetyCoreDisabler Control Panel..."

WEBUI_PACKAGE="io.github.a13e300.ksuwebui"
WEBUI_ACTIVITY=".WebUIActivity"
WEBUI_COMPONENT="$WEBUI_PACKAGE/$WEBUI_ACTIVITY"

if ! pm path "$WEBUI_PACKAGE" >/dev/null 2>&1; then
    echo "! Compatible WebUI Host App not found."
    get_webui_host
fi

echo "- Launching WebUI..."
am start -a android.intent.action.MAIN -n "$WEBUI_COMPONENT" -e id "$MODULE_ID"

echo "- Launch signal sent."
