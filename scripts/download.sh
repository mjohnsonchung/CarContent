#!/usr/bin/env bash
# download.sh — iterate creators.csv and pull recent short videos via yt-dlp
set -euo pipefail

CREATORS_FILE="creators.csv"
ARCHIVE_FILE="archive.txt"
DOWNLOADS_DIR="downloads"
MAX_DOWNLOADS=3
MAX_DURATION=90
MIN_DURATION=3

# ── sanity checks ──────────────────────────────────────────────────────────────
if [[ ! -f "$CREATORS_FILE" ]]; then
  echo "ERROR: $CREATORS_FILE not found. Aborting."
  exit 1
fi

mkdir -p "$DOWNLOADS_DIR"

echo "========================================"
echo " Car Content Downloader"
echo " $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "========================================"

total=0
success=0
skipped=0
failed=0

# ── read CSV, skip header ──────────────────────────────────────────────────────
while IFS=',' read -r url theme platform text_overlay notes; do

  # skip the header row
  if [[ "$url" == "url" ]]; then
    continue
  fi

  # skip blank lines
  if [[ -z "$url" ]]; then
    continue
  fi

  total=$((total + 1))

  # strip surrounding whitespace / quotes
  url="$(echo "$url" | tr -d '"' | xargs)"
  theme="$(echo "$theme" | tr -d '"' | xargs)"
  platform="$(echo "$platform" | tr -d '"' | xargs)"

  echo ""
  echo "----------------------------------------"
  echo "  [${total}] URL      : $url"
  echo "       Theme    : $theme"
  echo "       Platform : $platform"
  echo "       Notes    : $notes"
  echo "----------------------------------------"

  output_dir="${DOWNLOADS_DIR}/${theme}"
  mkdir -p "$output_dir"

  COOKIES_FLAG=""
  EXTRACTOR_ARGS_FLAG=""
  MAX_DL=$MAX_DOWNLOADS
  if [[ "$platform" == "instagram" ]]; then
    COOKIES_FLAG="--cookies /tmp/ig_cookies.txt"
    EXTRACTOR_ARGS_FLAG="--extractor-args instagram:include_stories=False"
    MAX_DL=2
  fi

  # yt-dlp exits non-zero for many soft errors (geo-block, private video, etc.)
  # We capture the exit code so one failure doesn't abort the whole run.
  set +e
  yt-dlp \
    -v \
    $COOKIES_FLAG \
    $EXTRACTOR_ARGS_FLAG \
    --download-archive "$ARCHIVE_FILE" \
    --write-info-json \
    --max-downloads "$MAX_DL" \
    --match-filter "duration < ${MAX_DURATION} & duration > ${MIN_DURATION}" \
    --output "${output_dir}/%(uploader)s_%(id)s.%(ext)s" \
    --no-playlist \
    --ignore-errors \
    --retries 3 \
    --fragment-retries 3 \
    --socket-timeout 30 \
    "$url"
  exit_code=$?
  set -e

  if [[ $exit_code -eq 0 ]]; then
    echo "  SUCCESS: finished downloading from $url"
    success=$((success + 1))
  elif [[ $exit_code -eq 101 ]]; then
    # exit code 101 = max-downloads limit reached (expected)
    echo "  INFO: max-downloads ($MAX_DOWNLOADS) reached for $url"
    success=$((success + 1))
  else
    echo "  WARNING: yt-dlp exited with code $exit_code for $url — continuing."
    failed=$((failed + 1))
  fi

done < "$CREATORS_FILE"

echo ""
echo "========================================"
echo " Summary"
echo "   Total URLs processed : $total"
echo "   Succeeded            : $success"
echo "   Failed (non-fatal)   : $failed"
echo "========================================"

# Exit 0 even if some individual downloads failed; the workflow should still
# proceed to upload whatever was fetched and commit the archive.
exit 0
