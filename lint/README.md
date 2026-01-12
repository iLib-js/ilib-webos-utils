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
./execute-lint.sh <LOCDATA_PATH> [OUTPUT_PATH]
```
#### Example
```bash
./execute-lint.sh ~/Source/localization-data RESULT

    ~/Source/localization-data
    → Root directory containing localization data to be linted

    RESULT
    → Directory where the final HTML report will be generated
```
#### Arguments
LOCDATA_PATH (Required)
* Path to the root directory to be linted
* All subdirectories (excluding .git) are processed individually

OUTPUT_PATH (Optional)
* Output directory for the final HTML report
* Default: ./tmp

## How It Works
1. Creates (or cleans) required output directories
2. Changes working directory to LOCDATA_PATH
3. Iterates through each subdirectory
4. Runs ilib-lint with a predefined configuration
5. Saves lint results as JSON files
6. Converts all JSON results into an HTML report
7. Removes intermediate JSON output

## Help
To display usage instructions:
```bash
./execute-lint.sh -h
./execute-lint.sh --help
```