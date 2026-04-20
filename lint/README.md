# lint

Provides a script to lint localization data and generate HTML reports.  
`execute-lint.sh` runs `ilib-lint` on all subdirectories of a specified localization data directory and produces a consolidated HTML report.

## Directory Structure

```
lint/
├── execute-lint.sh          # Main script to run lint and generate HTML
├── pre-requisite.sh         # One-time setup script
├── ilib-lint-config.json    # ilib-lint configuration
├── convertHtml/
│   ├── convertHtml.js       # Converts JSON lint results to HTML
│   ├── case-filter.js       # Client-side filter for the total summary page
│   ├── rule-filter.js       # Client-side filter for individual app pages
│   └── style.css            # Shared stylesheet for all HTML reports
├── jsonOutput/              # Intermediate JSON results (auto-removed after conversion)
└── tmp/                     # Final HTML output directory (default)
```

## Prerequisites

Run once before the first use, or when setting up a new environment:

```bash
./pre-requisite.sh
```

This installs all required Node.js packages including `ilib-lint`.

## Usage

```bash
./execute-lint.sh <LOCDATA_PATH> [output=OUTPUT_PATH] [target=TARGET_APP] [fixmode=FIX_MODE] [version=VERSION] [jobs=N]
```

### Arguments

| Argument           | Required | Default | Description |
|--------------------|----------|---------|-------------|
| `LOCDATA_PATH`     | Yes      | —       | Root directory containing localization data. All subdirectories (excluding `.git`) are processed individually. |
| `output=PATH`      | No       | `./tmp` | Directory where the final HTML reports will be generated. |
| `target=APP`       | No       | —       | Lint only the specified app directory. If omitted, all subdirectories are processed. |
| `fixmode=MODE`     | No       | —       | `overwrite`: apply fixes in-place (`--overwrite`). `fix`: write fix files (`--fix --write`). |
| `version=LABEL`    | No       | —       | Version or submission label displayed at the top of every HTML report (e.g. `"Sprint 42 - 2026-04-17"`). |
| `jobs=N`           | No       | `4`     | Number of apps to lint in parallel. Increase for faster execution on multi-core machines. |

### Examples

```bash
# Lint all apps, output to ./tmp
./execute-lint.sh ~/Source/localization-data/

# Lint a single app, save to ./RESULT
./execute-lint.sh ~/Source/localization-data/ target=app1 output=RESULT

# Lint with fix mode and a version label
./execute-lint.sh ~/Source/localization-data/ output=RESULT fixmode=fix version="Sprint 42 - 2026-04-17"
```

### Help

```bash
./execute-lint.sh -h
```

## How It Works

1. Creates (or cleans) the intermediate `jsonOutput/` and final output directories.
2. Changes into `LOCDATA_PATH` and iterates through each subdirectory.
3. Runs `ilib-lint` per app and saves JSON results to `jsonOutput/`.
4. Converts all JSON results to HTML via `convertHtml/convertHtml.js`.
5. Removes the intermediate `jsonOutput/` directory.

## HTML Reports

### Total Summary — `0.total-result.html`

Aggregated view across all apps:

- **Stat cards** — Total Errors, Total Warnings, Total Issues, Apps with Issues
- **Issues by Rule** — per-rule violation count and description, sorted by count
- **App list** — per-app errors/warnings with a link to the individual report. Checkbox to show only apps with issues.

### Individual App — `{app}-result.html`

Per-app detail view:

- **Stat cards** — Errors, Warnings
- **Breakdown table** — counts broken down by files, modules, and lines
- **Rules** — checkboxes to filter the detail section by rule
- **Detailed Information** — one card per violation showing rule, file, key, source, target, description, link, and auto-fix status
