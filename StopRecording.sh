#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="DouyinLiveRecorder"

confirm_stop() {
  if [[ -t 0 ]]; then
    read -r -p "确定要结束所有后台直播录制进程吗？ [y/N] " reply
  else
    reply="n"
  fi
  case "$reply" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

collect_patterns() {
  local patterns=()
  if [[ -e "$SCRIPT_DIR/$APP_NAME" ]]; then
    patterns+=("$SCRIPT_DIR/$APP_NAME")
  else
    patterns+=("$APP_NAME")
  fi
  if [[ -e "$SCRIPT_DIR/main.py" ]]; then
    patterns+=("$SCRIPT_DIR/main.py")
  fi
  printf '%s\n' "${patterns[@]}"
}

has_process() {
  local pattern="$1"
  pgrep -f "$pattern" >/dev/null 2>&1
}

kill_pattern() {
  local pattern="$1"
  if has_process "$pattern"; then
    pkill -f "$pattern" || true
    sleep 1
    if has_process "$pattern"; then
      pkill -9 -f "$pattern" || true
    fi
    return 0
  fi
  return 1
}

if ! confirm_stop; then
  echo "已取消结束录制操作"
  exit 0
fi

app_found="false"
while IFS= read -r pattern; do
  if has_process "$pattern"; then
    app_found="true"
    break
  fi
done < <(collect_patterns)

if [[ "$app_found" != "true" ]]; then
  echo "没有找到录制程序的进程"
  exit 1
fi

kill_pattern "ffmpeg"

echo "已成功结束正在录制直播的进程！"
echo "关闭此窗口10秒后自动停止录制程序"
sleep 10

while IFS= read -r pattern; do
  kill_pattern "$pattern" || true
done < <(collect_patterns)
