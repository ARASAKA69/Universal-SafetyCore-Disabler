#!/system/bin/sh
#
# Universal SafetyCore Disabler 
# By ARASAKA
# Version 1.0
#
# Credits:
# Big Thanks to @daboynb for providing us the placeholder application (https://github.com/daboynb/Safetycore-placeholder)
#
# Big Thanks to 5ec1cff for providing us the Standalone app of the KSUWebUI for non KSU Users (https://github.com/5ec1cff/KsuWebUIStandalone/releases/tag/v1.0)
#
#
#


ui_print() {
  sleep 0.1
  echo " > $1"
}

print_status() {
  [ "$1" -eq 0 ] && echo "   [✓] $2" || echo "   [X] $2"
}

abort_install() {
  ui_print " "
  ui_print "FATAL: $1"
  echo "ERROR:Installation failed: $1" > "$MODPATH/status.log"
  sed -i "/^description=/ s/$/ ❌ Status: Failed/" "$MODPATH/module.prop"
  exit 1
}

# Define module variables
MODULE_ID="SafetyCoreDisabler"
MODPATH_FINAL="/data/adb/modules/$MODULE_ID"
PACKAGE_NAME="com.google.android.safetycore"
PLACEHOLDER_APK="$MODPATH/common/Safetycore-placeholder.apk"
OFFICIAL_APKM="$MODPATH/common/Safetycore-official.apkm"
METHOD_FILE="$MODPATH/install_method"
STATUS_FILE="$MODPATH/status.log"
PROP_FILE="$MODPATH/module.prop"

# --- Installation Start ---

echo ""
echo "========================================="
echo "      
██╗░░░██╗░██████╗░█████╗░██████╗░
██║░░░██║██╔════╝██╔══██╗██╔══██╗
██║░░░██║╚█████╗░██║░░╚═╝██║░░██║
██║░░░██║░╚═══██╗██║░░██╗██║░░██║
╚██████╔╝██████╔╝╚█████╔╝██████╔╝
░╚═════╝░╚═════╝░░╚════╝░╚═════╝░"
echo "      Universal SafetyCore Disabler       "
echo "                By ARASAKA                "
echo "========================================="
echo ""
ui_print "In a world of constant data collection,"
sleep 1
ui_print "ARASAKA believes in digital sovereignty."
sleep 0.5
ui_print "This module is a statement: the only one"
ui_print "analyzing your data should be YOU."
echo ""
sleep 3
ui_print "This module will universally Uninstall"
sleep 0.5
ui_print "Google SafetyCore and will install"
sleep 0.5
ui_print "a placeholder app with no function."
echo ""
sleep 1
ui_print "This module will also prevent PlayStore"
sleep 0.5
ui_print "from auto-updating it. You have"
sleep 1
ui_print "THE FULL CONTROL!"
 
echo ""
sleep 2

ui_print "Performing pre-flight checks..."
if ! [ -f "$PLACEHOLDER_APK" ] || ! [ -f "$OFFICIAL_APKM" ]; then
  abort_install "placeholder.apk or official.apkm missing from module's common folder!"
fi
print_status 0 "Required APKs found."
sleep 1
echo ""
ui_print "Searching for SafetyCore package..."
CURRENT_PACKAGE_NAME=$(pm list packages | grep -i 'safetycore' | head -n 1 | cut -d':' -f2)

if [ -z "$CURRENT_PACKAGE_NAME" ]; then
  ui_print "INFO: SafetyCore package not found on this device."
  echo "INACTIVE:App not found on system." > "$STATUS_FILE"
  sed -i "/^description=/ s/$/ ℹ️ Status: Inactive/" "$PROP_FILE"
  ui_print "Installation complete. No action was needed."
  exit 0
fi
sleep 1
ui_print "Found package: $CURRENT_PACKAGE_NAME"
BASE_APK_PATH=$(pm path "$CURRENT_PACKAGE_NAME" | grep "base.apk" | sed 's/package://g')
print_status 0 "Found application at specified path."
sleep 1
echo ""

INSTALL_LOG=""
case "$BASE_APK_PATH" in
  /system*|/product*|/vendor*)
    INSTALL_METHOD="SYSTEM"
    echo "$INSTALL_METHOD" > "$METHOD_FILE"
    ui_print "App is a System App. Using Magisk overlay method."
    MODULE_SYS_PATH="$MODPATH/system/priv-app/SafetyCore"
    mkdir -p "$MODULE_SYS_PATH"
    cp "$PLACEHOLDER_APK" "$MODULE_SYS_PATH/SafetyCore.apk"
    INSTALL_LOG="ACTIVE: SafetyCore Replaced with Placeholder non Functional app used PrivApp Method. To revert, please uninstall this module from the Magisk app and reboot."
    print_status 0 "System overlay configured."
    ;;
  /data/app*)
    INSTALL_METHOD="USER"
    echo "$INSTALL_METHOD" > "$METHOD_FILE"
    ui_print "Found App as User App!"
    ui_print "Using Uninstall/Install method."
    APP_DIR=$(dirname "$BASE_APK_PATH")
    # Backup directory just in case
    mv "$APP_DIR" "$APP_DIR.bak"
    if [ $? -ne 0 ]; then
      abort_install "Failed to backup original app!"
    fi
    echo ""
    ui_print "Uninstalling original app..."
    pm uninstall "$CURRENT_PACKAGE_NAME" >/dev/null 2>&1
    ui_print "Original app uninstalled."
    ui_print "Signature is cleared."
    echo ""
    ui_print "Installing placeholder now..."
    sleep 1
    pm install -r "$PLACEHOLDER_APK" >/dev/null 2>&1
    if pm path $PACKAGE_NAME >/dev/null 2>&1; then
      INSTALL_LOG="ACTIVE: SafetyCore Replaced with Placeholder non Functional app used UserApp Method. Use the WebUI to revert simply hit Play button on Module inside Module list"
      print_status 0 "Placeholder installed successfully."
    else
      # Restore on failure
      mv "$APP_DIR.bak" "$APP_DIR"
      INSTALL_LOG="ERROR:Failed to install placeholder."
      abort_install "Placeholder installation failed. Restoring original."
    fi
    ;;
  *)
    abort_install "Unknown application path: $BASE_APK_PATH"
    ;;
esac

echo "$INSTALL_LOG" > "$STATUS_FILE"
sed -i "/^description=/ s/$/ ✅ Status: Active/" "$PROP_FILE"
# Link files for WebUI access
ln -sfn "$MODPATH_FINAL" "$MODPATH/webroot/module_files"

echo ""
ui_print "Installation complete!"
echo ""
ui_print "Reboot your device to apply changes!"
echo ""
sleep 1
echo "===============[ WEBUI INFO ]==============="
echo ""
sleep 1
ui_print "Use the Action button in Magisk to"
sleep 0.5
ui_print "easily open the new WebUI."
echo ""
sleep 1
ui_print "Our module auto-installs a standalone"
sleep 0.5
ui_print "WebUI if your device doesn't have one."
echo ""
sleep 1
ui_print "Inside the WebUI, you can uninstall"
sleep 0.5
ui_print "& revert SafetyCore with one click."

echo ""
echo "===============[ WEBUI INFO ]==============="
echo ""
echo ""
echo ""
echo ""

