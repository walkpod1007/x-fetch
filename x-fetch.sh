#!/bin/bash
# x-fetch.sh：貼 X（Twitter）連結，抓貼文／長文／圖片／影片，並做圖片 OCR、影片逐字稿、留言表。
# 用法：x-fetch.sh <X 網址> [--out DIR] [--no-media] [--no-ocr] [--transcript] [--no-comments] [--keep-video]
#                          [--no-embeds] [--comment-pages N] [--lang xx]
# exit：0 全成功／1 部分失敗（見 REPORT.md）／2 抓不到貼文／3 參數錯／130・143 被中斷
# 這支只負責補齊 PATH 與轉交，邏輯全在同資料夾的 x_fetch.py。bash 3.2 相容（macOS 內建版本）。
set -u
# 解開 symlink（macOS 的 readlink 沒有 -f，手動跟）：透過 symlink 呼叫也找得到 x_fetch.py
SRC="${BASH_SOURCE[0]:-$0}"
while [ -h "$SRC" ]; do
  D="$(cd "$(dirname "$SRC")" && pwd)"
  SRC="$(readlink "$SRC")"
  case "$SRC" in /*) ;; *) SRC="$D/$SRC" ;; esac
done
DIR="$(cd "$(dirname "$SRC")" && pwd)"
# 補上常見的安裝位置（Homebrew、pipx 的 ~/.local/bin）；使用者原本的 PATH 優先。
# 背景執行（cron、launchd）或 env -i 時 PATH 常常很短，找不到 tesseract／ffmpeg／mlx_whisper 多半是這個原因。
EXTRA="/opt/homebrew/bin:/usr/local/bin"
[ -n "${HOME:-}" ] && EXTRA="$EXTRA:$HOME/.local/bin"
export PATH="${PATH:-/usr/bin:/bin}:$EXTRA"
PY="$(command -v python3 || true)"
if [ -z "$PY" ]; then
  echo "找不到 python3（需要 3.9 以上）" >&2
  exit 3
fi
if [ ! -f "$DIR/x_fetch.py" ]; then
  echo "找不到 x_fetch.py（應該和 x-fetch.sh 放在同一個資料夾：${DIR}）" >&2
  exit 3
fi
exec "$PY" "$DIR/x_fetch.py" "$@"
