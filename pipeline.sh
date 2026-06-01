#!/usr/bin/env bash
#
# pipeline.sh — Download a year of NOAA Storm Events, convert to GeoParquet.
#
# Usage:   ./pipeline.sh [YEAR]
# Example: ./pipeline.sh 2024
#
# Requires: bash, curl, gunzip, ogr2ogr (GDAL >= 3.5)
#
# This is a starter scaffold. Read the comments. Replace the [TODO] markers
# with the actual logic. Do not change the structure unless you have a reason.

set -euo pipefail

# -----------------------------------------------------------------------------
# Config
# -----------------------------------------------------------------------------

# Year to pull. Override by passing as the first argument.
YEAR="${1:-2024}"

# NOAA file naming pattern. The "c{CREATED_DATE}" portion changes when NOAA
# republishes a year. Look at https://www.ncei.noaa.gov/data/storm-events/files/
# and update CREATED_DATE for the year you want.
CREATED_DATE="20260421"

# BASE_URL="https://www.ncei.noaa.gov/data/storm-events/files"
BASE_URL="https://www.ncei.noaa.gov/pub/data/swdi/stormevents/csvfiles/"
FILE_NAME="StormEvents_details-ftp_v1.0_d${YEAR}_c${CREATED_DATE}.csv.gz"
URL="${BASE_URL}/${FILE_NAME}"

RAW_DIR="data/raw"
PROCESSED_DIR="data/processed"
RAW_GZ="${RAW_DIR}/${FILE_NAME}"
RAW_CSV="${RAW_DIR}/${FILE_NAME%.gz}"
OUT_PARQUET="${PROCESSED_DIR}/storms_${YEAR}.parquet"

# -----------------------------------------------------------------------------
# Step 1: Set up directories
# -----------------------------------------------------------------------------
# Setup: Create output directories, set safe defaults with set-euo pipefail
# [TODO] Use mkdir -p to create RAW_DIR and PROCESSED_DIR. Both should be
# safe to call even if the directories already exist.

echo "[1/4] Setting up directories"

# Create data directory
mkdir -p "./data"
echo "Created main data directory"
mkdir -p $RAW_DIR
echo "Created raw directory at: $RAW_DIR"
mkdir -p $PROCESSED_DIR
echo "Created processed directory at: $PROCESSED_DIR"

# -----------------------------------------------------------------------------
# Step 2: Download the raw file
# -----------------------------------------------------------------------------

# Download: Pull NOAA storm events details CSV for target year using curl

echo "[2/4] Downloading ${FILE_NAME}"
# [TODO] Use curl to download URL into RAW_GZ. Suggested flags:
#   -L       follow redirects
#   -o       write to a specific output file path
#   --fail   exit non-zero on HTTP errors (4xx/5xx)
#
# Skip the download if the file already exists (idempotency).   

echo ""
echo "================================================================"
echo "  Processing ${YEAR}"
echo "================================================================"

if [ -f $RAW_GZ ]; then
    echo "⏭️  Already downloaded: $FILE_NAME"
else
    echo "⬇️  Downloading $FILE_NAME..."
    curl -L --progress-bar -o "$RAW_GZ" "$URL"
    echo $RAW_GZ

    # Guard against failed downloads
    FILE_SIZE=$(wc -c < $RAW_GZ | tr -d ' ')
        if [ "$FILE_SIZE" -lt 10000 ]; then
            echo "❌ ERROR: $GZ_FILE is only $FILE_SIZE bytes — download likely failed."
            echo "   Check that the filename is current at:"
            echo "   $BASE_URL/"
            rm $RAW_GZ
            exit 1
        fi
        echo "✅ Downloaded ($FILE_SIZE bytes compressed)"
fi

# -----------------------------------------------------------------------------
# Step 3: Decompress
# -----------------------------------------------------------------------------

# Extract: Decompress .gz archive to plain CSV
gunzip -k "$RAW_GZ" 
# Convert: Use ogr2ogr to convert CSV into single GeoParquet file with proper geometry and CRS
# Source: https://www.ncei.noaa.gov/data/storm-events/files/

# Let the user pick a year and created-date string and then run

# Output: Single file at data/processed/storms_{YEAR}.parquet
# create data if it doesn't exist yet)

echo "[3/4] Decompressing"
# [TODO] Use gunzip to decompress RAW_GZ into RAW_CSV.
# The -k flag keeps the original .gz so the pipeline can rerun.
# Skip this step if RAW_CSV already exists.

# -----------------------------------------------------------------------------
# Step 4: Convert CSV to GeoParquet
# -----------------------------------------------------------------------------

# Convert: Use ogr2ogr to convert CSV into single GeoParquet file with proper geometry and CRS
# Source: https://www.ncei.noaa.gov/data/storm-events/files/

# Let the user pick a year and created-date string and then run

# Output: Single file at data/processed/storms_{YEAR}.parquet
# create data if it doesn't exist yet)

echo "[4/4] Converting to GeoParquet"
# [TODO] Use ogr2ogr to convert RAW_CSV into a GeoParquet file at OUT_PARQUET.
#
# The CSV uses BEGIN_LON / BEGIN_LAT for the storm start point. ogr2ogr can
# pick those up if you tell it the column names with -oo:
#
#   -oo X_POSSIBLE_NAMES=BEGIN_LON
#   -oo Y_POSSIBLE_NAMES=BEGIN_LAT
#
# The data is in WGS 84 (EPSG:4326). Set that explicitly with -a_srs.
#
# Use -f Parquet for the output format.
#
# Tip: ask your AI pair (see R1.3 prompts 4 and 6) for the exact ogr2ogr
# command, then verify the flags against `ogr2ogr --help` before running.

echo "Done. Output: ${OUT_PARQUET}"
echo "Open it in DuckDB:"
echo "  duckdb -c \"INSTALL spatial; LOAD spatial; SELECT COUNT(*) FROM read_parquet('${OUT_PARQUET}');\""
