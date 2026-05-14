# car-content-pipeline

Automated pipeline that pulls short-form car videos from YouTube and TikTok daily, deduplicates them, and syncs them to Google Drive — all via GitHub Actions.

---

## How It Works

1. A scheduled GitHub Actions workflow runs every day at **03:00 UTC**.
2. It downloads `creators.csv` from your Google Sheet (published as CSV).
3. For each creator URL, `yt-dlp` pulls up to **3 new videos** under 90 seconds that aren't already in `archive.txt`.
4. Downloaded files are uploaded to **Google Drive** via `rclone`.
5. The updated `archive.txt` is committed back to the repo so the next run knows what was already fetched.

---

## Required Secrets

Add these in your repo under **Settings → Secrets and variables → Actions → New repository secret**.

### `RCLONE_CONFIG`

The full text content of your `rclone.conf` file for a Google Drive remote named `gdrive`.

**How to generate it:**

```bash
# Install rclone locally
curl https://rclone.org/install.sh | sudo bash

# Run the interactive config wizard
rclone config
```

Follow the prompts:
- Choose `n` (new remote)
- Name it exactly **`gdrive`**
- Choose type **`drive`** (Google Drive)
- Leave client ID and secret blank (uses rclone's defaults)
- Choose scope **`drive`** (full access)
- Open the auth URL in a browser and grant access
- After auth completes, run `cat ~/.config/rclone/rclone.conf` and copy the entire output as the secret value.

The config will look something like:

```ini
[gdrive]
type = drive
scope = drive
token = {"access_token":"...","token_type":"Bearer","refresh_token":"...","expiry":"..."}
```

---

### `SHEET_CSV_URL`

The public CSV export URL of your Google Sheet that contains the creators list.

**How to publish your Google Sheet as CSV:**

1. Open your Google Sheet and add your creators (see [creators.csv format](#creatorscsv-format) below).
2. Go to **File → Share → Publish to web**.
3. In the dropdowns, select your sheet name and choose **Comma-separated values (.csv)**.
4. Click **Publish** and copy the URL shown.
5. Paste that URL as the secret value.

The URL will look like:
```
https://docs.google.com/spreadsheets/d/SHEET_ID/export?format=csv&gid=0
```

---

## `creators.csv` Format

The pipeline reads this file (or the live Google Sheet export) with these columns:

| Column     | Description                                              |
|------------|----------------------------------------------------------|
| `url`      | Channel or playlist URL (YouTube, TikTok, etc.)          |
| `theme`    | Used as the subfolder name inside `downloads/` and Drive |
| `platform` | Informational label (youtube, tiktok, instagram, etc.)   |
| `notes`    | Free-text notes, not used by the script                  |

Example:

```csv
url,theme,platform,notes
https://www.youtube.com/@MotorTrend,reviews,youtube,Motor Trend official channel
https://www.tiktok.com/@carwow,comparisons,tiktok,carwow short clips
```

Add or remove rows in your Google Sheet; the pipeline will pick up changes automatically on the next run.

---

## Google Drive Structure

Downloads are uploaded to:

```
My Drive/
└── CarContent/
    └── Raw/
        ├── reviews/
        │   └── MotorTrend_abc123.mp4
        └── comparisons/
            └── carwow_xyz789.mp4
```

The subfolder name matches the `theme` column in your sheet.

---

## Download Filters

The script uses these yt-dlp filters (edit `scripts/download.sh` to change):

| Setting           | Value | Reason                              |
|-------------------|-------|-------------------------------------|
| `--max-downloads` | 3     | Limits API calls and storage per run |
| `duration < 90`   | 90 s  | Short-form content only              |
| `duration > 3`    | 3 s   | Ignores thumbnails / stubs           |

---

## Testing with a Manual Run

1. Push all files to GitHub and set both secrets.
2. Go to **Actions → Download Car Content → Run workflow**.
3. Click **Run workflow** (green button).
4. Watch the live logs to verify each step succeeds.

If a creator URL fails, the script logs a warning and continues — it won't fail the entire workflow.

---

## Deduplication

`archive.txt` is a plain-text file maintained by yt-dlp. Each downloaded video ID is written to it so subsequent runs skip already-fetched content. This file is committed back to the repo after every successful workflow run.

To reset and re-download everything, clear `archive.txt` and push an empty file.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `rclone: command not found` | The rclone install step failed; check Actions log for curl errors |
| `403 Forbidden` on Sheet URL | Re-publish the sheet (File → Share → Publish to web) |
| Videos not uploading | Verify `RCLONE_CONFIG` has a remote named exactly `gdrive` |
| Everything re-downloads each run | `archive.txt` isn't being committed; check the git push step permissions |

For git push to work the workflow needs **write** permissions. Go to **Settings → Actions → General → Workflow permissions** and enable **Read and write permissions**.
