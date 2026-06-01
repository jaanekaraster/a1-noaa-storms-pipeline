# NOAA Storms Pipeline

A one-command pipeline that downloads a year of NOAA Storm Events data,
converts it to GeoParquet, and lands it ready for analysis in DuckDB,
GeoPandas, or QGIS.

## What it does

`pipeline.sh` takes a year (default: 2024), pulls the raw `details` file
from NOAA's public archive, decompresses it, and converts it to a single
GeoParquet file at `data/processed/storms_{YEAR}.parquet`.

Total runtime: about 90 seconds for a typical year on a home internet
connection.

## The data

- **Source:** NOAA Storm Events Database (https://www.ncei.noaa.gov/data/storm-events/)
- **License:** Public domain (US federal data)
- **What's in it:** Every recorded storm event in the United States for the
  given year, including type, location, and damages

## How to run it

Requires GDAL (for `ogr2ogr`) and standard Unix utilities (`curl`, `gunzip`).

\`\`\`bash
git clone https://github.com/jaanekaraster/a1-noaa-storms-pipeline.git
cd a1-noaa-storms-pipeline
chmod +x pipeline.sh
./pipeline.sh
\`\`\`

To run for a specific year:

\`\`\`bash
./pipeline.sh 2023
\`\`\`

## What I learned

When building a pipeline like this, it's essential to check your work at every step to make sure that the files are behaving as expected. 
- Initially, I noticed that the base URL given was not correct, so I researched and identified the most updated link that contained all the CSVs by year. 
- Another preprocessing step was needed to check the year that the user had chosen. I considered possible edge cases, such as if the user selects a year before 1950 or after 2024; additionally, 2024 and beyond featured "created dates" that were distinct from the other years. 
- The decompression step didn't work initially via WSL, so I tried using the `-c` flag rather than `-k`. It ended up being a file permissions issue, so I reverted to the `-k` flag for simplicity after resolving the permissions issue.

## Stack

- bash
- curl
- GDAL / ogr2ogr
- GeoParquet

## Evaluation Criteria
[ ] Repo is public on GitHub, URL works in incognito window

[x] README.md follows template structure

[x] What I Learned section is filled with specifics, not generics

[ ] `pipeline.sh` runs end-to-end on fresh clone, no manual

[x] `pipeline.sh` starts with shebang and `set -euo pipefail`

[x] Script is safe to rerun without breaking (creates dirs with mkdir -p, handles existing files)

[x] `.gitignore` excludes `data/` so no raw downloads end up in the repo

[x] Output GeoParquet opens cleanly in QGIS or DuckDB and has the right CRS

[x] At least one comment in the script explains a non-obvious choice

[x] Commit history is at least 3 commits with reasonable messages