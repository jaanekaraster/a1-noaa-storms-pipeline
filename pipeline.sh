#!/usr/bin/env bash
#
# pipeline.sh — Download a year of NOAA Storm Events, convert to GeoParquet.
#
# Usage:   ./pipeline.sh [YEAR]
# Example: ./pipeline.sh 2024
#
# Requires: bash, curl, gunzip, ogr2ogr (GDAL >= 3.5)

set -euo pipefail

# -----------------------------------------------------------------------------
# Config
# -----------------------------------------------------------------------------

# Year to pull. Override by passing as the first argument.
YEAR="${1:-2024}"

# NOAA file naming pattern. The "c{CREATED_DATE}" portion changes when NOAA
# republishes a year. Look at https://www.ncei.noaa.gov/data/storm-events/files/
# and update CREATED_DATE for the year you want.

# Cases for various years and matching created_date structures
if [ "$YEAR" -eq 2024 ]; then
    CREATED_DATE="20260421"
elif [ "$YEAR" -gt 2024 ]; then
    echo "You're only allowed to query up to 2024"
    exit 1
elif [ "$YEAR" -lt 1950 ]; then
    echo "NOAA only has data for years 1950-present; try again."
    exit 1
else 
    CREATED_DATE="20260323"
    echo "Querying for year $YEAR..."
fi

# BASE_URL="https://www.ncei.noaa.gov/data/storm-events/files" # Changed to updated version below
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

echo ""
echo "================================================================"
echo "  Processing ${YEAR}"
echo "================================================================"

# Use curl to download URL into RAW_GZ; follow redirects (-L), add progress bar (--progress-bar), write to RAW_GZ filepath (-o), exit non-zero on HTTP errors (4xx/5xx) (--fail)
if [ -f $RAW_GZ ]; then
    # Skip the file if it already exists
    echo "⏭️  Already downloaded: $FILE_NAME"
else
    echo "⬇️  Downloading $FILE_NAME..."
    curl -L --progress-bar --fail -o "$RAW_GZ" "$URL"
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

echo "[3/4] Decompressing"

if [-f $RAW_CSV]; then
    # Skip the file if it already exists
    echo "⏭️  CSV already exists: $FILE_NAME"
else
    # Decompress RAW_GZ into RAW_CSV; use -k to keep the original .gz so the pipeline can rerun
    gunzip -k "$RAW_GZ"
    # gunzip -c "$RAW_GZ" > "$RAW_CSV" (also possible, but less elegant)
fi

# -----------------------------------------------------------------------------
# Step 4: Convert CSV to GeoParquet
# -----------------------------------------------------------------------------

echo "[4/4] Converting to GeoParquet"
# Use ogr2ogr to convert RAW_CSV into a GeoParquet file at OUT_PARQUET.
# Use -f Parquet for the output format, and set WGS 84 (EPSG:4326) using `-a_srs`.
# The CSV uses BEGIN_LON / BEGIN_LAT for the storm start point. ogr2ogr can
# pick those up by passing the column names with -oo:
#   -oo X_POSSIBLE_NAMES=BEGIN_LON
#   -oo Y_POSSIBLE_NAMES=BEGIN_LAT

ogr2ogr -f Parquet "$OUT_PARQUET" "$RAW_CSV" \
    -oo X_POSSIBLE_NAMES=BEGIN_LON \
    -oo Y_POSSIBLE_NAMES=BEGIN_LAT \
    -a_srs EPSG:4326

# Mark completed
echo "Done. Output: ${OUT_PARQUET}"
echo "Open it in DuckDB:"
echo "  duckdb -c \"INSTALL spatial; LOAD spatial; SELECT COUNT(*) FROM read_parquet('${OUT_PARQUET}');\""
