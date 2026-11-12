#!/bin/bash
# 预装 Appium 的三个辅助 APK（小米 HyperOS 必备）
#
# 背景：HyperOS 会拒绝 `adb install -g`（报 INSTALL_GRANT_RUNTIME_PERMISSIONS），
# 而 Appium 默认用 -g 安装辅助包，于是会话直接失败。这里改为不带 -g 手动装好，
# 再让 Appium 用 skipServerInstallation / skipSettingsAppReinstall 只使用不重装。
#
# 用法: ./appium-env/preinstall-appium-apks.sh [设备序列号]
#      设备只有一台时可省略序列号

set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_ANDROID_HOME="D:/Program Files/adb"
export ANDROID_HOME="${ANDROID_HOME:-$DEFAULT_ANDROID_HOME}"
ADB="$(cygpath -u "$ANDROID_HOME")/platform-tools/adb"
SERIAL="${1:-}"

if [ ! -x "$ADB" ]; then
  echo "✗ 找不到 adb: $ADB"
  exit 1
fi

ADB_DEV=("$ADB")
if [ -n "$SERIAL" ]; then
  ADB_DEV+=("-s" "$SERIAL")
fi

# 依赖目录（appium driver 安装位置）
DRV="$DIR/.appium/node_modules/appium-uiautomator2-driver"
SETTINGS_APK="$DRV/node_modules/io.appium.settings/apks/settings_apk-debug.apk"
SERVER_DIR="$DRV/node_modules/appium-uiautomator2-server/apks"
SERVER_APK="$(ls "$SERVER_DIR"/appium-uiautomator2-server-v*.apk 2>/dev/null | grep -v androidTest | head -1)"
TEST_APK="$SERVER_DIR/appium-uiautomator2-server-debug-androidTest.apk"

for f in "$SETTINGS_APK" "$SERVER_APK" "$TEST_APK"; do
  if [ ! -f "$f" ]; then
    echo "✗ 缺少 APK: $f"
    exit 1
  fi
done

echo "设备:"; "${ADB_DEV[@]}" devices | sed 's/^/  /'
echo ""

echo "→ io.appium.settings"
"${ADB_DEV[@]}" install -r "$SETTINGS_APK" | tail -1

echo "→ uiautomator2 server"
"${ADB_DEV[@]}" install -r "$SERVER_APK" | tail -1

echo "→ uiautomator2 server (test)"
"${ADB_DEV[@]}" install -r -t "$TEST_APK" | tail -1

echo ""
echo "复核:"
for p in io.appium.settings io.appium.uiautomator2.server io.appium.uiautomator2.server.test; do
  printf "  %-42s " "$p"
  "${ADB_DEV[@]}" shell pm path "$p" | head -1
done
