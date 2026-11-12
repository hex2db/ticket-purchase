#!/bin/bash
# 大麦 App 端抢票启动脚本（Windows / Git Bash）
#
# 与仓库里原有的 start_ticket_grabbing.sh 的区别：
#   1. 用项目内的 .venv-appium 解释器，不依赖系统 Python 或 poetry 虚拟环境
#   2. 不写死 macOS 路径
#   3. 会先检查 Appium 服务是否在跑
#
# 用法: ./start-grabbing.sh        交互确认后开始
#       ./start-grabbing.sh -y     跳过确认（脚本化调用）

set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY="$ROOT/.venv-appium/Scripts/python.exe"
CONFIG="$ROOT/damai_appium/config.jsonc"
SERVER="http://127.0.0.1:4723"
ADB="${ADB:-/d/Program Files/adb/platform-tools/adb}"

# 关键：本机环境若设置了 HTTP_PROXY，selenium 会把请求发给代理，
# 变成绝对 URL（POST http://127.0.0.1:4723/session/.../element），
# Appium 路由匹配不上会退化成原样转发，导致「selector is not present」。
export NO_PROXY="127.0.0.1,localhost,::1"
export no_proxy="$NO_PROXY"

if [ ! -x "$PY" ]; then
  echo "✗ 找不到虚拟环境: $PY"
  echo "  先执行: python -m venv .venv-appium && .venv-appium/Scripts/python -m pip install --no-cache-dir Appium-Python-Client"
  exit 1
fi

if ! curl -s --max-time 3 "$SERVER/status" | grep -q '"ready":true'; then
  echo "✗ Appium 未运行"
  echo "  先执行: ./appium-env/start-appium.sh"
  exit 1
fi
echo "✓ Appium 服务正常"

if [ ! -f "$CONFIG" ]; then
  echo "✗ 配置文件不存在: $CONFIG"
  exit 1
fi

echo ""
echo "当前配置:"
"$PY" - "$CONFIG" <<'EOF'
import json, sys
c = json.load(open(sys.argv[1], encoding="utf-8"))
print(f"  设备      {c.get('device_name', '(默认 emulator-5554)')}")
print(f"  城市      {c['city']}")
print(f"  票档序号  {c['price_index']}")
print(f"  观演人    {', '.join(c['users'])}  （{len(c['users'])} 张）")
print(f"  自动提交  {c['if_commit_order']}")
EOF

echo ""
echo "开始前请确认手机已：打开大麦 → 搜到目标演出 → 进入详情页"
if [ "$1" != "-y" ]; then
  read -r -p "确认开始抢票？(y/N): " reply
  case "$reply" in
    [Yy]*) ;;
    *) echo "已取消"; exit 1 ;;
  esac
fi

cd "$ROOT/damai_appium"

# 输入法保护：记录运行前的默认输入法，无论正常结束还是 Ctrl+C 都复原。
# 某些 Appium 能力（unicodeKeyboard）会把默认输入法切到 io.appium.settings/.UnicodeIME，
# 会话异常中断时来不及还原，手机上就再也打不出字——这里兜底。
if [ -x "$ADB" ]; then
  IME_BACKUP="$("$ADB" shell settings get secure default_input_method 2>/dev/null | tr -d '\r\n')"
  case "$IME_BACKUP" in
    ""|null|*UnicodeIME) IME_BACKUP="" ;;
  esac
  restore_ime() {
    if [ -n "$IME_BACKUP" ]; then
      CUR="$("$ADB" shell settings get secure default_input_method 2>/dev/null | tr -d '\r\n')"
      if [ "$CUR" != "$IME_BACKUP" ]; then
        "$ADB" shell ime set "$IME_BACKUP" >/dev/null 2>&1 && echo "✓ 输入法已恢复: $IME_BACKUP"
      fi
    fi
  }
  trap restore_ime EXIT INT TERM
fi

echo ""
echo "🚀 开始抢票..."
"$PY" damai_app_v2.py
RC=$?
echo ""
echo "退出码: $RC"
exit $RC
