# Project Progress — Car Content Pipeline

**Repo:** https://github.com/mjohnsonchung/CarContent
**Last updated:** 2026-05-20

---

## Status: In Setup — rclone config fix applied

---

## Completed

- [x] Created repo and pushed initial file structure to GitHub
- [x] `.github/workflows/download.yml` — daily 3am UTC + manual trigger, full pipeline
- [x] `scripts/download.sh` — yt-dlp loop with error handling and summary logging
- [x] `archive.txt` — empty dedup record, tracked by git
- [x] `creators.csv` — sample creator list with 5-column schema
- [x] `README.md` — setup guide (secrets, rclone, Google Sheet, testing)
- [x] Secrets added to GitHub repo (`RCLONE_CONFIG`, `SHEET_CSV_URL`)
- [x] Updated `creators.csv` schema: added `text_overlay` (TRUE/FALSE) column between `platform` and `notes`
- [x] Switched rclone config secret to base64-encoded (`RCLONE_CONFIG_B64`) with decode + verification step in workflow
- [x] Added "Write Instagram cookies" workflow step — decodes `IG_COOKIES_B64` secret to `/tmp/ig_cookies.txt`

---

## To Do

- [ ] Add `RCLONE_CONFIG_B64` secret to GitHub repo (base64-encode your rclone.conf)
- [ ] Add `IG_COOKIES_B64` secret to GitHub repo (base64-encode your Instagram cookies file)
- [ ] Set repo workflow permissions to **Read and write** (Settings → Actions → General)
- [ ] Test first manual workflow run (Actions tab → Run workflow)
- [ ] Verify rclone uploads appear in Google Drive under `CarContent/Raw/`
- [ ] Populate real creator URLs in Google Sheet
- [ ] Decide what to build with `text_overlay` field (overlay renderer, caption script, etc.)

---

## File Structure

```
CarContent/
├── .github/workflows/download.yml   # CI/CD — scheduled download job
├── scripts/download.sh              # yt-dlp loop over creators.csv
├── creators.csv                     # creator list (url, theme, platform, text_overlay, notes)
├── archive.txt                      # yt-dlp dedup log, committed after each run
└── README.md                        # setup instructions
```

---

## Notes

- `--max-downloads 3` and `duration < 90s` filters keep storage and runtime lean
- yt-dlp failures are non-fatal — script logs a warning and moves to the next URL
- `archive.txt` is committed with `[skip ci]` to avoid re-triggering the workflow
- Downloads are organised into subfolders by `theme` column on both local and Drive
