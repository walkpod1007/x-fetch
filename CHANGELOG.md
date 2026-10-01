# Changelog

## 1.0.1 (2026-10-01)

- Windows 相容：啟動時不再因 `signal.SIGHUP` 崩潰（PR #1，感謝 @zaxardery8011-design 回報、修正並在 Windows 10 實測）；中斷或逾時收子行程時，沒有 `os.killpg` 的平台改用 `terminate()`／`kill()`。
- README 補 Windows 執行方式。

## 1.0.0 (2026-10-01)

- 初版：貼一個 X（Twitter）連結，抓貼文、長文（X Articles）、原圖、影片與留言樣本；選配 OCR 與影片逐字稿。
- First release.
