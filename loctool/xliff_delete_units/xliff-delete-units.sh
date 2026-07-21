#!/bin/bash

# xliff-delete-units.sh - Delete translation units from webOS XLIFF files using loctool select criteria

set -euo pipefail

SCRIPT_START_TIME=$(date +%s)

# Validate an option value: reject empty or flag-like ("-" prefixed) values.
#   $1 = flag name (for the error message)   $2 = value to check
require_value() {
    if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
        echo "Error: $1 requires a valid value." >&2
        exit 1
    fi
}

# Locate loctool: check npm standalone first, then pnpm workspace
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
XLIFF_STYLE=(-2 --xliffStyle webOS)

if [ -f "$SCRIPT_DIR/node_modules/.bin/loctool" ]; then
    LOCTOOL_BIN="$SCRIPT_DIR/node_modules/.bin/loctool"
    run_loctool() { "$LOCTOOL_BIN" "$@"; }
    echo "LOCTOOL: $LOCTOOL_BIN"
else
    LOCTOOL_JS=$(find "$SCRIPT_DIR/../../node_modules/.pnpm" -type f -path "*/loctool.js" | grep "/loctool@" | head -n 1)
    if [ -z "$LOCTOOL_JS" ] || [ ! -f "$LOCTOOL_JS" ]; then
        echo "Error: loctool not found. Please run pnpm install from the repo root."
        exit 1
    fi
    run_loctool() { node "$LOCTOOL_JS" "$@"; }
    echo "LOCTOOL: $LOCTOOL_JS"
fi

# -----------------------------------------------------------------------------
# Locale-wise serial select runner (intersection-based)
# - Scans locales from both:
#       <path>/<project_src>/*.xliff
#       <path>/<project_dst>/*.xliff
# - Only processes locales that exist in BOTH sides (intersection).
# - Logs locales that are missing on either side.
# - For each locale L, runs: node "$LOCTOOL" select ...
# - Default criteria selects: source="OK", key="menu_1", datatype="javascript"
# - Code/comments/logs in English per team convention.
# -----------------------------------------------------------------------------

show_help() {
  cat <<'USAGE'
Usage:
  xliff-delete-units.sh --inputPath <input-path> --outputPath <output-path> [--criteria "<criteria>" | --criteriaFile <excel-file>] [--dry-run]

Options support both formats: --option value, --option=value, and short forms

Options:
  -i|--inputPath     Base directory containing the input XLIFF files (required)
  -o|--outputPath    Directory where the output XLIFF files will be written (required)
  -c|--criteria      loctool select criteria string (mutually exclusive with --criteriaFile)
  -f|--criteriaFile  Excel file (.xlsx) to generate criteria list (mutually exclusive with --criteria)
  --dry-run          Do not execute loctool; just print planned actions.

Requirement:
  - Exactly one of --criteria or --criteriaFile must be specified.

Assumptions:
  - Locale files are named as "<locale>.xliff" under <inputPath>/<projectId>.
  - Output files are written to <outputPath>/<locale>.xliff.

Examples:
  xliff-delete-units.sh --inputPath ./input --outputPath ./output --criteria "source=^OK$,key=^OK$,datatype=^javascript$"
  xliff-delete-units.sh --inputPath ./input --outputPath ./output --criteriaFile criteria.xlsx
  xliff-delete-units.sh -i ./input -o ./output -f criteria.xlsx
  xliff-delete-units.sh -i=./input -o=./output -f=criteria.xlsx
USAGE
}

ensure_python_excel_deps() {
  if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 is required when using --criteriaFile."
    exit 1
  fi

  if ! python3 -m pip --version >/dev/null 2>&1; then
    echo "[INFO] pip is not available. Attempting to install pip with ensurepip..."
    if ! python3 -m ensurepip --upgrade --user >/dev/null 2>&1; then
      echo "Error: pip is required but could not be installed automatically."
      echo "Please install pip for python3 and re-run this command."
      exit 1
    fi

    if ! python3 -m pip --version >/dev/null 2>&1; then
      echo "Error: pip installation did not complete successfully."
      exit 1
    fi
  fi

  if python3 -c "import pandas, openpyxl" 2>/dev/null; then
    return 0
  fi

  echo "[INFO] Installing pandas and openpyxl for --criteriaFile support..."
  if ! python3 -m pip install --user pandas openpyxl; then
    echo "Error: Failed to install pandas/openpyxl. Please check your Python/pip setup."
    exit 1
  fi

  if ! python3 -c "import pandas, openpyxl" 2>/dev/null; then
    echo "Error: pandas/openpyxl still unavailable after installation."
    exit 1
  fi
}

# Defaults
INPUT_PATH=""
OUTPUT_PATH=""
CRITERIA=""
CRITERIA_FILE=""
DRY_RUN=false
CRITERIA_BY_PROJECT=""

# Parse args
if [ "$#" -eq 0 ]; then show_help; exit 0; fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    -i|--inputPath)
      require_value "$1" "${2:-}"; INPUT_PATH="$2"; shift 2 ;;
    -i=*|--inputPath=*)
      INPUT_PATH="${1#*=}"; require_value "${1%%=*}" "$INPUT_PATH"; shift ;;
    -o|--outputPath)
      require_value "$1" "${2:-}"; OUTPUT_PATH="$2"; shift 2 ;;
    -o=*|--outputPath=*)
      OUTPUT_PATH="${1#*=}"; require_value "${1%%=*}" "$OUTPUT_PATH"; shift ;;
    -c|--criteria)
      require_value "$1" "${2:-}"; CRITERIA="$2"; shift 2 ;;
    -c=*|--criteria=*)
      CRITERIA="${1#*=}"; require_value "${1%%=*}" "$CRITERIA"; shift ;;
    -f|--criteriaFile)
      require_value "$1" "${2:-}"; CRITERIA_FILE="$2"; shift 2 ;;
    -f=*|--criteriaFile=*)
      CRITERIA_FILE="${1#*=}"; require_value "${1%%=*}" "$CRITERIA_FILE"; shift ;;
    --dry-run)
      DRY_RUN=true; shift ;;
    -h|--help)
      show_help; exit 0 ;;
    *)
      echo "Error: Unknown argument: $1"
      echo "Use --help for usage information."
      exit 1
      ;;
  esac
done

if [ -z "$INPUT_PATH" ]; then
  echo "Error: --inputPath option is required."
  exit 1
fi
if [ -z "$OUTPUT_PATH" ]; then
  echo "Error: --outputPath option is required."
  exit 1
fi

if [ ! -d "$INPUT_PATH" ]; then
  echo "Error: Input path not found or is not a directory: $INPUT_PATH"
  exit 1
fi

# Validate that INPUT_PATH contains XLIFF files
if ! find "$INPUT_PATH" -type f -name "*.xliff" | grep -q .; then
  echo "Error: INPUT_PATH has no .xliff files: $INPUT_PATH"
  exit 1
fi

# Exactly one of --criteria or --criteriaFile must be specified
if [ -n "$CRITERIA" ] && [ -n "$CRITERIA_FILE" ]; then
  echo "Error: --criteria and --criteriaFile are mutually exclusive. Specify only one."
  exit 1
fi
if [ -z "$CRITERIA" ] && [ -z "$CRITERIA_FILE" ]; then
  echo "Error: One of --criteria or --criteriaFile must be specified."
  exit 1
fi

# If criteriaFile is given, check if it exists
if [ -n "$CRITERIA_FILE" ]; then
  if [ ! -f "$CRITERIA_FILE" ]; then
    echo "Error: Criteria file not found or inaccessible: $CRITERIA_FILE"
    exit 1
  fi
  echo "[INFO] Criteria file specified: $CRITERIA_FILE"
fi

# If criteriaFile is given, parse Excel and group by project
# Note: Using temporary file instead of process substitution for sh compatibility
if [ -n "$CRITERIA_FILE" ]; then
  ensure_python_excel_deps

  # Create a temp file for Python output
  TEMP_CRITERIA=$(mktemp)
  TEMP_CRITERIA_ERR=$(mktemp)
  python3 "$SCRIPT_DIR/parse_criteria_excel.py" "$CRITERIA_FILE" > "$TEMP_CRITERIA" 2> "$TEMP_CRITERIA_ERR" || {
    echo "Error: Failed to parse criteria file"
    echo "[parse_criteria_excel.py stderr]:"
    cat "$TEMP_CRITERIA_ERR"
    rm -f "$TEMP_CRITERIA" "$TEMP_CRITERIA_ERR"
    exit 1
  }
  rm -f "$TEMP_CRITERIA_ERR"

  # Store criteria by project in a temp file
  CRITERIA_BY_PROJECT=$(mktemp)

  current_project=""
  while IFS= read -r line; do
    echo "[DEBUG] line: '$line'"
    [ -z "$line" ] && continue
    # Check if line starts with [PROJECT:
    case "$line" in
      "[PROJECT:"*)
        current_project="${line#\[PROJECT: }"
        current_project="${current_project%\]}"
        echo "[DEBUG] current_project set: $current_project"
        ;;
      *)
        if [ -n "$current_project" ] && [ -n "$line" ]; then
          echo "[DEBUG] add to $current_project: $line"
          # Store project and criteria separated by "|"
          echo "$current_project|$line" >> "$CRITERIA_BY_PROJECT"
        fi
        ;;
    esac
  done < "$TEMP_CRITERIA"

  rm -f "$TEMP_CRITERIA"
fi

# Log the parsed criteria map
# Note: Simplified due to bash-specific array syntax limitations

# Create a temporary working directory for processing in the script's directory
TEMP_DIR=$(mktemp -d "$SCRIPT_DIR/tmp_xliff_delete.XXXXXXXX")
TEMP_INPUT_DIR="$TEMP_DIR/input"
mkdir -p "$TEMP_INPUT_DIR"

# Copy the entire input directory to TEMP_INPUT_DIR
echo "[INFO] Copying input directory to TEMP_DIR"
cp -r "$INPUT_PATH"/* "$TEMP_INPUT_DIR"
echo "[INFO] Copy complete."

# Process files with criteria
if [ -n "$CRITERIA" ]; then
  # Direct criteria string provided via -c option
  echo "[INFO] Processing with criteria: $CRITERIA"
  for file in "$TEMP_INPUT_DIR"/*/*.xliff; do
    if [ -f "$file" ]; then
      echo "[INFO] Processing file: $file"
      if [ "$DRY_RUN" = "true" ]; then
        echo "[DRY] run_loctool select \"$CRITERIA\" \"$file\" \"$file\" --prune ${XLIFF_STYLE[*]}"
      else
        run_loctool select "$CRITERIA" "$file" "$file" --prune "${XLIFF_STYLE[@]}"
        echo "[INFO] Processed $file"
      fi
    fi
  done
elif [ -n "$CRITERIA_FILE" ] && [ -f "$CRITERIA_BY_PROJECT" ]; then
  # Criteria from Excel file - process each criteria per project
  echo "[INFO] Processing with criteria from Excel file: $CRITERIA_FILE"

  # Read each project|criteria line and process
  while IFS='|' read -r project_name criteria_value; do
    if [ -z "$project_name" ] || [ -z "$criteria_value" ]; then
      continue
    fi

    project_dir="$TEMP_INPUT_DIR/$project_name"
    if [ -d "$project_dir" ]; then
      echo "[INFO] Processing project: $project_name with criteria: $criteria_value"
      # Process all .xliff files in this project directory
      for file in "$project_dir"/*.xliff; do
        if [ -f "$file" ]; then
          echo "[INFO] Processing file: $file"
          if [ "$DRY_RUN" = "true" ]; then
            echo "[DRY] run_loctool select \"$criteria_value\" \"$file\" \"$file\" --prune ${XLIFF_STYLE[*]}"
          else
            run_loctool select "$criteria_value" "$file" "$file" --prune "${XLIFF_STYLE[@]}"
            echo "[INFO] Processed $file"
          fi
        fi
      done
    else
      echo "[WARN] Project directory not found: $project_dir"
    fi
  done < "$CRITERIA_BY_PROJECT"

  rm -f "$CRITERIA_BY_PROJECT"
fi

# Move TEMP_INPUT_DIR to the final output directory
echo "[INFO] Moving TEMP_INPUT_DIR to final output directory"
rm -rf "$OUTPUT_PATH"
cp -r "$TEMP_INPUT_DIR" "$OUTPUT_PATH"
echo "[INFO] Output move complete."

# Cleanup
rm -rf "$TEMP_DIR"
[ -f "$CRITERIA_BY_PROJECT" ] && rm -f "$CRITERIA_BY_PROJECT"

SCRIPT_END_TIME=$(date +%s)
SCRIPT_ELAPSED=$((SCRIPT_END_TIME - SCRIPT_START_TIME))
echo "[INFO] Completed. Elapsed time: ${SCRIPT_ELAPSED} seconds."
