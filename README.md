# NOAA Storms Pipeline

A one-command pipeline that downloads a year of NOAA Storm Events data,
converts it to GeoParquet, and lands it ready for analysis in DuckDB,
GeoPandas, or QGIS.

## What it does
# Let the user pick a year and created-date string and then run

# Output: Single file at data/processed/storms_{YEAR}.parquet
# create data if it doesn't exist yet)

`pipeline.sh` takes a year (default: 2024), pulls the raw `details` file
from NOAA's public archive, decompresses it, and converts it to a single
GeoParquet file at `data/processed/storms_{YEAR}.parquet`.

Total runtime: about 90 seconds for a typical year on a home internet
connection.

## The data

- **Source:** NOAA Storm Events Database (https://www.ncei.noaa.gov/data/storm-events/)
- **License:** Public domain (US federal data)
- **What's in it:** every recorded storm event in the United States for the
  given year, including type, location, and damages

## How to run it

Requires GDAL (for `ogr2ogr`) and standard Unix utilities (`curl`, `gunzip`).

\`\`\`bash
git clone https://github.com/{your-username}/noaa-storms-pipeline.git
cd noaa-storms-pipeline
chmod +x pipeline.sh
./pipeline.sh
\`\`\`

To run for a specific year:

\`\`\`bash
./pipeline.sh 2023
\`\`\`

## What I learned

[Two or three sentences. Be specific. What was harder than expected? What
would you do differently? This is the part hiring managers actually read.]

## Stack

- bash
- curl
- GDAL / ogr2ogr
- GeoParquet

## Evaluation Criteria
[ ] Repo is public on GitHub, URL works in incognito window
[ ] README.md follows template structure
[ ] What I Learned section is filled with specifics, not generics
[ ] `pipeline.sh` runs end-to-end on fresh clone, no manual
[ ] `pipeline.sh` starts with shebang and `set -euo pipefail`
[ ] Script is safe to rerun without breaking (creates dirs with mkdir -p, handles existing files)
[ ] `.gitignore` excludes `data/` so no raw downloads end up in the repo
[ ] Output GeoParquet opens cleanly in QGIS or DuckDB and has the right CRS
[ ] At least one comment in the script explains a non-obvious choice
[ ] Commit history is at least 3 commits with reasonable messages