#!/bin/bash
# 本地 Appium 启动脚本（Git Bash 用）
# 不依赖 npm 全局安装：直接跑 appium-env/node_modules 里的 appium
# 驱动目录也锁在 appium-env/.appium 内，不写用户主目录
#
# 用法:  ./appium-env/start-appium.sh [额外参数]

set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export APPIUM_HOME="$DIR/.appium"

# 本机 adb 所在位置（platform-tools 的上一级目录即 ANDROID_HOME）
# 换了 SDK 路径改这一行即可
DEFAULT_ANDROID_HOME="D:/Program Files/adb"
export ANDROID_HOME="${ANDROID_HOME:-$DEFAULT_ANDROID_HOME}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
# Git Bash 的 PATH 必须是 /d/... 形式，Windows 风格 D:/... bash 认不出来
export PATH="$(cygpath -u "$ANDROID_HOME")/platform-tools:$PATH"

echo "APPIUM_HOME  = $APPIUM_HOME"
echo "ANDROID_HOME = $ANDROID_HOME"
echo "adb          = $(command -v adb || echo '未找到，请检查路径')"
echo "Appium       = $DIR/node_modules/.bin/appium"
echo "监听         = http://127.0.0.1:4723  (Ctrl+C 停止)"
echo ""

exec "$DIR/node_modules/.bin/appium" \
  --port 4723 \
  --relaxed-security \
  --log-level info \
  "$@"
