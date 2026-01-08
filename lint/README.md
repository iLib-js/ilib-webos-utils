# lint
It provides a script to lint localization data and generate an HTML report.

## execute-lint.sh

execute-lint.sh is a Bash script that runs ilib-lint
 on all subdirectories of a specified localization data directory and generates a consolidated HTML lint report from the results.

## Example Directory Structure
```bash
project-root/
├── execute-lint.sh
├── ilib-lint-config.json
├── convertHtml/
│   └── convertHtml.js
├── jsonOutput/        # Generated during execution (auto-removed)
└── tmp/               # Final HTML output directory
```

## Prerequisites
Ensure the following are installed:
* Bash (macOS / Linux recommended)
* Node.js (v14 or later)
* npx

Note: Before running the script, make sure to install the project dependencies by running:
```bash
npm install
```
This ensures that all required Node packages (including ilib-lint) are available.

## Usage
```bash
./execute-lint.sh <LOCDATA_PATH> [OUTPUT_PATH]
```
### Example
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