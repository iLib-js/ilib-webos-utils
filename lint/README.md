# lint
It provides a script to lint localization data and generate an HTML report.  
execute-lint.sh is a Bash script that runs ilib-lint
on all subdirectories of a specified localization data directory and generates a consolidated HTML lint report from the results.

## Example Directory Structure
```bash
project-root/
├── execute-lint.sh
├── pre-requisite.sh
├── ilib-lint-config.json
├── convertHtml/
│   └── convertHtml.js
├── jsonOutput/        # Generated during execution (auto-removed)
└── tmp/               # Final HTML output directory
```

## Prerequisites (pre-requisite.sh)
This script automatically sets up the Node.js environment and prepares the system to run ilib-lint.   
It should be executed once before running the linting process or when setting up a new environment.

```bash
./pre-requisite.sh
```
This ensures that all required Node packages (including ilib-lint) are available.

## Execute the script (execute-lint.sh)

### Usage
```bash
./execute-lint.sh <LOCDATA_PATH> [output=OUTPUT_PATH] [target=TARGET_APP] [fixmode=FIX_MODE]
```
#### Example
```bash
./execute-lint.sh ~/Source/localization-data target=app1 output=RESULT fixmode=fix

    ~/Source/localization-data
    → Root directory containing localization data to be linted

    output=OUTPUT_PATH (optional)
    → Directory where the final HTML report will be generated
    → Default: ./tmp

    target=TARGET_APP (optional)
    → Specific app directory name to lint.
    → If provided, only this app will be processed.

    fixmode=FIX_MODE (optional)
    → Lint mode: 'overwrite' or 'fix'
    →    - overwrite: Use --overwrite option
    →    - fix: Use --fix --write options
    →    If not provided, no fix mode option will be passed.

```

#### Arguments

| Argument             | Required | Description                                                                 |
|----------------------|----------|-----------------------------------------------------------------------------|
| LOCDATA_PATH         | Yes      | Path to the root directory to be linted. All subdirectories (excluding .git) are processed individually. |
| output=OUTPUT_PATH   | No       | Directory where the final HTML report will be generated. Default: ./tmp      |
| target=TARGET_APP    | No       | Specific app directory name to lint. If provided, only this app will be processed. |
| fixmode=FIX_MODE     | No       | Lint mode: 'overwrite' (use --overwrite) or 'fix' (use --fix --write). If not provided, no fix mode option will be passed. |

## How It Works
1. Create (or clean) required output directories.
2. Change working directory to `LOCDATA_PATH`.
3. Iterate through each subdirectory.
4. Run ilib-lint with the predefined configuration.
5. Save lint results as JSON files.
6. Convert all JSON results into a consolidated HTML report.
7. Remove intermediate JSON output files.

## Help
To display usage instructions:
```bash
./execute-lint.sh -h
./execute-lint.sh --help
```