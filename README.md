# x-fetch

貼一個 X（Twitter）連結，把貼文、長文（X Articles）、原圖、影片、留言整理成一個資料夾，需要時再做圖片 OCR 與影片逐字稿。不登入、不帶 cookie，用的是社群維護的公開服務，所以哪天上游改版或關閉，它也會跟著失效（見「限制」）。

- 一支純 Python 標準函式庫的腳本，不需要 pip 裝任何東西就能抓貼文與圖片。
- 抓失敗不會弄壞你的舊資料：全程先寫進暫存目錄，成功才換進輸出資料夾。
- 也能當 [Claude Code](https://claude.com/claude-code) 的技能用（附 `SKILL.md`）。

## 能抓什麼

| 內容 | 拿得到嗎 | 備註 |
|---|---|---|
| 一般貼文（含超過 280 字的長貼文） | 全文、作者、時間、互動數 | 引用貼文、作者自己的串文續文也會一併整理 |
| X Articles（長文） | 全文，含小標、圖片位置、內嵌貼文 | 轉成 Markdown 放進 `post.md` |
| 圖片 | 原尺寸（`name=orig`） | 有替代文字就一起記下 |
| 影片 | 下載最高畫質的 mp4（預設只在要做逐字稿或加 `--keep-video` 時才下載） | 超過 30 分鐘或 500 MB 不下載，只給直連 |
| 圖片 OCR | 繁中＋英文 | 要裝 tesseract；純照片會被信心值濾掉 |
| 影片逐字稿 | 含時間碼 | **預設不開**，加 `--transcript`；要 `mlx_whisper`（只支援 Apple 晶片的 Mac），首次下載約 1.6 GB 的模型 |
| 留言 | **只拿得到一部分** | 依讚數約 35 則，再用搜尋端點翻頁；X 的搜尋本身不會吐出全部回覆，報告會寫「拿到 N 則／貼文顯示 M 則」 |

## 需求

必要：

- `python3`（3.9 以上；用 3.9 與 3.14 測過）。只用標準函式庫，不需要 curl，也不需要 pip 套件。

選配（沒裝就略過對應功能，不影響其他部分）：

| 工具 | 用途 | 安裝（macOS） |
|---|---|---|
| tesseract（含 `chi_tra`、`eng` 語言檔） | 圖片 OCR | `brew install tesseract tesseract-lang` |
| ffmpeg（含 ffprobe） | 量影片規格、抽音軌（逐字稿用） | `brew install ffmpeg` |
| mlx-whisper | 影片逐字稿，**預設不開**。首次執行會自動從 Hugging Face 下載約 1.6 GB 的模型，執行時佔用的記憶體約數 GB | `pipx install mlx-whisper` 或 `pip install mlx-whisper` |

## 安裝

1. 下載 `x-fetch-public.zip` 並解壓縮，會得到 `x-fetch/` 資料夾。
2. 確認 Python：`python3 --version`（要 3.9 以上）。要 OCR 就裝 tesseract，要逐字稿才裝 ffmpeg 與 mlx-whisper。
3. 試跑：

   ```bash
   cd x-fetch
   bash x-fetch.sh --help
   bash x-fetch.sh 'https://x.com/<帳號>/status/<編號>'
   ```

   Windows 沒有 bash，直接用 Python 跑：`python x_fetch.py --help`、`python x_fetch.py "https://x.com/<帳號>/status/<編號>"`（Windows 10、Python 3.12 實測過）。影片逐字稿在 Windows 跑不了，要另換轉錄工具（見「限制」）。

要當 Claude Code 技能用：把整個 `x-fetch/` 資料夾放進 `~/.claude/skills/`，然後對 Claude 說「幫我抓這則推文 <網址>」。

## 用法

```bash
bash x-fetch.sh '<X 網址>' [選項]
```

網址吃 `x.com`、`twitter.com`、`t.co`，帶 `?s=20` 之類的參數也行。

| 選項 | 作用 |
|---|---|
| `--out DIR` | 輸出資料夾（預設 `./x-fetch-out/<貼文編號>/`） |
| `--no-media` | 不下載圖片與影片（OCR、逐字稿也跟著不做） |
| `--no-ocr` | 不做圖片 OCR |
| `--transcript` | 做影片逐字稿（預設不做） |
| `--lang xx` | 逐字稿語言（如 `zh`、`en`），不給就讓 Whisper 自己判斷 |
| `--keep-video` | 影片下載後留檔（預設逐字稿做完就刪） |
| `--no-comments` | 不抓留言 |
| `--comment-pages N` | 留言搜尋最多翻 N 頁（預設 10） |
| `--no-embeds` | 長文裡的內嵌貼文只留連結，不逐則取內容 |

範例：

```bash
# 只要貼文與圖片，不要留言
bash x-fetch.sh 'https://x.com/<帳號>/status/<編號>' --no-comments --out ./out

# 影片貼文：下載影片並做逐字稿（英文），保留 mp4
bash x-fetch.sh 'https://x.com/<帳號>/status/<編號>' --transcript --lang en --keep-video
```

### 產物（都在 `--out` 資料夾）

| 檔案 | 內容 |
|---|---|
| `post.md` | 作者、時間、網址、全文（長文轉成 Markdown）、引用貼文、串文續文、互動數。**第三方寫的字都放在 `>` 引用區塊裡**，檔尾有一行 `<!-- x-fetch-end <12 碼> -->` 結尾標記 |
| `meta.json` | 上游 API 的原始回應 |
| `media/` | 原圖 `img_NN.*`；影片只在 `--keep-video` 時留 |
| `ocr.md` | 每張圖一節 |
| `transcript.md` | 每支影片一節，含時間碼 |
| `comments.csv` | 留言表（UTF-8 帶 BOM，Excel 直接開；開頭是 `= + - @` 的格子前面補了單引號，防公式注入） |
| `REPORT.md` | 每一步成功／失敗／降級、HTTP 碼、留言覆蓋率、耗時 |

時間一律轉成 UTC+8（台北時間）。**請先讀 `REPORT.md` 再用結果。**

### exit code

| 碼 | 意思 |
|---|---|
| 0 | 全部成功 |
| 1 | 部分失敗或降級（`REPORT.md` 會寫是哪一步） |
| 2 | 抓不到貼文（已刪、不公開、連結錯，或所有資料源都失敗） |
| 3 | 參數錯誤（不是 X 網址、選項不認得、`--out` 不能寫入、找不到 python3） |
| 130／143 | 被 Ctrl-C／TERM 中斷（`--out` 裡原有的成果一個字不動） |

### 環境變數

| 變數 | 預設 | 說明 |
|---|---|---|
| `X_FETCH_MAX_VIDEO_SEC` | 1800 | 影片超過幾秒就不下載 |
| `X_FETCH_MAX_VIDEO_MB` | 500 | 影片超過幾 MB 就不下載 |
| `X_FETCH_MAX_IMAGE_MB` | 50 | 單張圖上限 |
| `X_FETCH_IMAGE_TOTAL_SEC`／`X_FETCH_VIDEO_TOTAL_SEC` | 180／900 | 單張圖、單支影片的下載總時限（秒） |
| `X_FETCH_WHISPER_MODEL` | `mlx-community/whisper-large-v3-turbo` | 逐字稿用的模型 |
| `X_FETCH_FX`／`X_FETCH_VX`／`X_FETCH_XWEB` | 見下一節 | 換成自架的上游位址 |
| `X_FETCH_PDF_SCRIPT` | 不設 | 選配：第四層降級用的外部腳本，呼叫方式 `<腳本> <網址> <輸出文字檔>`（例如用 headless Chrome 印成 PDF 再轉文字）。不設就略過這一層 |

## 怎麼抓、失敗了怎麼辦

依序嘗試，前一層失敗才換下一層：

1. fxtwitter API（`api.fxtwitter.com`）：主資料源，貼文、長文、媒體、留言都靠它。
2. vxtwitter API（`api.vxtwitter.com`）：降級；只有貼文文字與媒體網址，長文只有預覽，沒有留言。
3. 純 HTTP 讀 `x.com` 頁面：降級；只有頁面可見文字。
4. 選配的外部 PDF 腳本（`X_FETCH_PDF_SCRIPT`）。

走降級來源時 exit 1，`post.md` 開頭會有警告。降級層讀到登入牆、錯誤頁、行銷頁會被辨識出來，當失敗而不是當正文。貼文真的不存在（404／400）時不降級，直接 exit 2。圖片與影片只下載 `https://*.twimg.com`（X 自家媒體網域），轉址的每一跳都再檢查一次。

節制：同一主機的請求間隔至少 2 秒；回 402／403／429 就對該主機停手，不重試、不換網址變體。

## 限制

- **依賴第三方服務。** fxtwitter／vxtwitter 是社群維護的服務，不是 X 官方介面；它們自己也要去讀 X。X 改版、加牆，或這些服務關閉、改版、限流，這支工具就會失效，不會有任何通知。整批 exit 2 或全部降級時，先拿一則確定存在的公開貼文重測，再判斷是服務掛了還是貼文本身的問題。
- **留言只是抽樣**，拿不到全部。要整串留言得走 X 官方 API（付費）。
- 一次一則、慢速的個人使用。大量或商用請改用 X 官方 API。
- 逐字稿目前只支援 `mlx_whisper`（Apple 晶片的 Mac）；其他平台用 `--transcript` 會在報告裡記失敗、exit 1。中文可能輸出簡體字，專有名詞可能聽錯，純音樂的影片可能吐出幻聽文字。
- OCR 只測過英文介面截圖與中文字圖；手寫、藝術字、影片燒進去的字幕沒測。
- 沒測過超長影片、直播、有年齡限制的貼文。
- 輸出時間固定為 UTC+8。

## 特別感謝

- **巴哲（[@WizerdBaChe](https://github.com/WizerdBaChe)）**：沒有他，我們根本不知道還有這條路。他把自己的 [media-fetch-pipeline](https://github.com/WizerdBaChe/media-fetch-pipeline)（MIT）和整理好的抓取流程分享出來，我們才從那裡開始研究，最後做成這個工具。本工具沒有直接沿用它的程式碼，但起點是他給的。
- **FxEmbed（舊稱 FixTweet）的作者 [dangeredwolf](https://github.com/dangeredwolf) 與所有貢獻者**：本工具抓貼文、長文、媒體、留言，靠的全是他們開放的 `api.fxtwitter.com`。
- **BetterTwitFix（vxtwitter）的作者 [dylanpdx](https://github.com/dylanpdx)**：降級資料源。

## 上游致謝

這個工具只是把下面這些服務與開源專案串起來，核心能力都是它們的。抓回來的貼文、圖片、影片、留言，**版權屬於原作者**；請遵守 X 的使用條款，並尊重原作者的意願，例如不要把別人的留言原文拿去對外發布。

| 專案／服務 | 本工具怎麼用它 | 網址 | 授權 |
|---|---|---|---|
| FxEmbed（舊稱 FixTweet；`api.fxtwitter.com`） | 主資料源：貼文、長文、媒體、留言 | https://github.com/FxEmbed/FxEmbed ；文件 https://docs.fxembed.com | MIT |
| BetterTwitFix（`api.vxtwitter.com`） | 降級資料源：貼文文字與媒體網址 | https://github.com/dylanpdx/BetterTwitFix | WTFPL |
| X（x.com、t.co、`*.twimg.com` 媒體網域） | 讀貼文頁面（第三層降級）、解 t.co 短網址、下載圖片與影片 | https://x.com ；使用條款 https://x.com/en/tos | 專有服務，受 X 使用條款約束 |
| Python 標準函式庫 | 全部程式邏輯 | https://www.python.org | PSF License |
| FFmpeg（`ffprobe`、`ffmpeg`） | 量圖片尺寸與影片規格、抽音軌 | https://ffmpeg.org | LGPL-2.1+（依編譯選項也可能是 GPL-2+） |
| Tesseract OCR | 圖片 OCR（`chi_tra+eng`） | https://github.com/tesseract-ocr/tesseract | Apache-2.0 |
| mlx-whisper（ml-explore／mlx-examples） | 影片逐字稿（`mlx_whisper` 指令） | https://github.com/ml-explore/mlx-examples/tree/main/whisper | MIT |
| OpenAI Whisper 與預設模型 `mlx-community/whisper-large-v3-turbo` | 語音辨識模型（轉換自 OpenAI 的 large-v3-turbo） | https://github.com/openai/whisper ；https://huggingface.co/mlx-community/whisper-large-v3-turbo | OpenAI Whisper：MIT；轉換版請以 Hugging Face 頁面標示為準 |

設計上另外參考了 [OWASP 的 CSV Injection 說明](https://owasp.org/www-community/attacks/CSV_Injection)（`comments.csv` 的防公式注入）。

## 免責聲明

本工具只讀取公開資料，並以「一次一則、慢速、不登入」的方式使用。作者不對上游服務的可用性、抓取結果的完整性或正確性負責，也不為使用者如何使用抓到的內容負責。請自行確認你的使用方式符合 X 的使用條款、當地法律，以及內容作者的意願。本工具與 X Corp.、FxEmbed、vxtwitter 等上游專案沒有任何隸屬或背書關係。

## 授權

MIT，見 `LICENSE`。

---

## English (short)

**x-fetch** takes an X (Twitter) post URL and saves the post text, X Articles (long-form), original-size images, videos and a sample of replies into a folder. It can also OCR images (tesseract) and transcribe videos (mlx-whisper, Apple Silicon only, opt-in with `--transcript`, downloads a ~1.6 GB model on first use). No login, no cookies: it reads through the community-run FxEmbed (`api.fxtwitter.com`) and vxtwitter services, so it breaks whenever those services or X change. Replies are only a sample, never the full thread.

Requires Python 3.9+ (standard library only). Usage: `bash x-fetch.sh 'https://x.com/<user>/status/<id>'` (on Windows: `python x_fetch.py "<url>"`). Exit codes: 0 ok, 1 partial/degraded, 2 post not found, 3 bad arguments. Read `REPORT.md` first. One post at a time, slowly; for bulk or commercial use, use the official X API. Fetched content belongs to its authors; please follow X's Terms of Service. Special thanks to Ba-Che ([@WizerdBaChe](https://github.com/WizerdBaChe)), whose [media-fetch-pipeline](https://github.com/WizerdBaChe/media-fetch-pipeline) and notes pointed us to this approach in the first place, and to [dangeredwolf](https://github.com/dangeredwolf) and the FxEmbed contributors, and [dylanpdx](https://github.com/dylanpdx) (BetterTwitFix), whose services do the real work. See the upstream credits table above (FxEmbed MIT, BetterTwitFix WTFPL, FFmpeg LGPL/GPL, Tesseract Apache-2.0, mlx-whisper MIT, OpenAI Whisper MIT). Licensed under MIT.
