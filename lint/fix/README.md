# fix

Report-driven auto-fix scripts for localization data.

Each script takes an **ilib-lint category HTML report** (the per-rule result
pages produced by `execute-lint.sh` / published under
`http://i18n.lge.com/ilib-lint/<run>/categories/`) plus the **localization-data
root**, and rewrites the affected `<target>` texts in the xliff files in place.

All scripts share the same conventions:

- **`LOCDATA_PATH`** is a required positional argument (apps are its
  subdirectories), matching `execute-lint.sh`.
- **`--report`** is a **local HTML file path**. The fix scripts do not download
  anything themselves — fetch the report first with `fetch-report.sh` (see
  below). This keeps responsibilities clear: `fetch-report.sh` downloads, the
  fix script fixes.
- **Dry-run by default.** Nothing is written until you pass `--apply`.
- **`--limit-app APP`** restricts processing to a single app directory.

## Downloading a report

The reports live on the lint server under:

```
http://i18n.lge.com/ilib-lint/<run>/categories/<category>-result.html
                               ~~~~~                ~~~~~~~~
                               run label            e.g. ellipsis_mismatch
```

`<run>` changes every time lint is run (e.g. `temp-sentence-ending-main22`), so
there is no stable default — always grab the current one.

Use `fetch-report.sh`, which builds the URL and downloads it:

```bash
# builds http://i18n.lge.com/ilib-lint/<run>/categories/<category>-result.html
./fetch-report.sh run=<run> category=ellipsis_mismatch
#   -> saves ./ellipsis_mismatch-result.html

# custom output path, or pass a full URL directly
./fetch-report.sh run=<run> category=ellipsis_mismatch output=/tmp/report.html
./fetch-report.sh url=http://i18n.lge.com/ilib-lint/<run>/categories/ellipsis_mismatch-result.html
```

Or plain `curl` if you prefer:

```bash
curl -s "http://i18n.lge.com/ilib-lint/<run>/categories/ellipsis_mismatch-result.html" \
    -o ellipsis_mismatch-result.html
```

The ellipsis report is large (tens of MB); the download can take a while.
`fetch-report.sh` defaults to a 600 s timeout — raise it with `maxtime=` (or
`curl --max-time`) and retry if needed.

Downloaded reports (`*-result.html`) are git-ignored (see `.gitignore` in this
directory), so they will not be accidentally committed to the repo.

## Scripts

| Script | Lint rule / category | What it does |
|--------|----------------------|---------------|
| `fetch-report.sh` | (any) | Downloads a category report HTML from the lint server to a local file. |
| `fix-ellipsis.py` | `resource-sentence-ending` / `ellipsis_mismatch` | Trailing `...` (U+002E ×3) → `…` (U+2026) in targets. |

## Usage

```bash
cd lint/fix

# 0) Download the report first (see "Downloading a report" above)
./fetch-report.sh run=<run> category=ellipsis_mismatch
#   -> ./ellipsis_mismatch-result.html

# 1) Dry-run (preview) against the local report file
python3 fix-ellipsis.py ~/Source/swp/localization-data --report ./ellipsis_mismatch-result.html

# 2) Preview one app, and list sources that could not be matched
python3 fix-ellipsis.py ~/Source/swp/localization-data --report ./ellipsis_mismatch-result.html \
    --limit-app account-billing --show-unmatched

# 3) Apply the changes
python3 fix-ellipsis.py ~/Source/swp/localization-data --report ./ellipsis_mismatch-result.html --apply

# 4) Review and commit in the localization-data repo
cd ~/Source/swp/localization-data && git diff --stat
```

## `fix-ellipsis.py` details

**Scope.** Only trailing `...` (exactly three dots) → `…`. The ellipsis report
also contains other end-punctuation corrections (`.`→`…`, `!`→`…`, the reverse
`…`→`...`, etc.); those are intentionally left untouched. Targets ending in four
or more dots (`....`, `.....`) are also skipped and reported as unmatched.

**Matching.** A segment is fixed only when its `<source>` text matches a
reported Source for that app/file **and** its `<target>` ends with exactly
`...`. The xliff unit `name` attribute is not used (the report shows the Source
as the Key when a unit has no name).

**Safety.** Only `<target>` content is rewritten; `<source>`, indentation, and
all other XML structure are preserved (output stays well-formed). Trailing
whitespace before the dots is kept.

**Progress output.** The report is large, so the script prints `Loading report`
and `Parsing report` lines, then a live progress bar while it walks the files:

```
Loading report (35.2 MB): ./ellipsis_mismatch-result.html ...
Parsing report ...
  [####################----------]  68%  4050/5966 files  (15300 changed)
```

The bar is written to **stderr** and only appears on an interactive terminal, so
redirecting stdout to a file (`> out.txt`) keeps the output clean. A per-file
sample diff (first 15 changes) and the final `SUMMARY` go to stdout.

## Adding a new fix script

Follow `fix-ellipsis.py` as the template:

1. Parse the category report with `parse_report()` style helpers to collect the
   in-scope `(App, File, Source)` set.
2. Match segments by `<source>` text plus the specific target condition for the
   rule; rewrite only `<target>`.
3. Keep dry-run the default; gate writes behind `--apply`.
4. Add a row to the Scripts table above.
