
#!/usr/bin/env bash
set -e
trap 'echo "[ERROR] Script failed at line $LINENO"; exit 1' ERR

SCRIPT_START_TIME=$(date +%s)

# -----------------------------------------------------------------------------
# Resolve loctool path under pnpm node_modules and run via "node <loctool.js>"
# -----------------------------------------------------------------------------
LOCTOOL=$(find ../../node_modules/.pnpm -type f -path "*/loctool.js" | grep "/loctool@" | head -n 1)
echo "LOCTOOL: $LOCTOOL"

if [[ -z "${LOCTOOL:-}" || ! -f "$LOCTOOL" ]]; then
  echo "loctool.js not found."
  exit 1
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

usage() {
  cat <<'USAGE'
Usage:
  xliff-delete-units.sh --inputPath <input-path> --outputPath <output-path> [--criteria "<criteria>" | --criteriaFile <excel-file>] [--dry-run]

Options:
  -i|--inputPath     Base directory containing the input XLIFF files (required)
  -o|--outputPath    Directory where the output XLIFF files will be written (required)
  -c|--criteria      loctool select criteria string (at least one of --criteria or --criteriaFile is required)
  -f|--criteriaFile  Excel file (.xlsx) to generate criteria list (at least one of --criteria or --criteriaFile is required; overrides --criteria)
  --dry-run       Do not execute loctool; just print planned actions.

Requirement:
  - At least one of --criteria or --criteriaFile must be specified.

Assumptions:
  - Locale files are named as "<locale>.xliff" under <inputPath>/<projectId>.
  - Output files are written to <outputPath>/<locale>.xliff.

Examples:
  xliff-delete-units.sh --inputPath ./input --outputPath ./output --criteria "source=^OK$,key=^OK$,datatype=^javascript$"
  xliff-delete-units.sh --inputPath ./input --outputPath ./output --criteriaFile criteria.xlsx
  xliff-delete-units.sh -i ./input -o ./output -f criteria.xlsx
USAGE
}

# Defaults
CRITERIA=""
CRITERIA_FILE=""
DRY_RUN=false

# Parse args
if [[ $# -eq 0 ]]; then usage; exit 1; fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--inputPath) INPUT_PATH="$2"; shift 2 ;;
    -o|--outputPath) OUTPUT_PATH="$2"; shift 2 ;;
    -c|--criteria) CRITERIA="$2"; shift 2 ;;
    -f|--criteriaFile) CRITERIA_FILE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "[ERROR] Unknown argument: $1"
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$INPUT_PATH" || -z "$OUTPUT_PATH" ]]; then
  echo "--inputPath and --outputPath are required."
  exit 1
fi

if [[ ! -d "$INPUT_PATH" ]]; then
  echo "[ERROR] Input path not found or is not a directory: $INPUT_PATH"
  exit 1
fi

# Check if at least one of criteria or criteriaFile is given
if [[ -z "$CRITERIA" && -z "$CRITERIA_FILE" ]]; then
  echo "[ERROR] At least one of --criteria or --criteriaFile must be specified."
  exit 1
fi

# If criteriaFile is given, check if it exists
if [[ -n "$CRITERIA_FILE" ]]; then
  if [[ ! -f "$CRITERIA_FILE" ]]; then
    echo "[ERROR] Criteria file not found or inaccessible: $CRITERIA_FILE"
    exit 1
  fi
  echo "[INFO] Criteria file specified: $CRITERIA_FILE"
fi

# If criteriaFile is given, parse Excel and group by project
declare -A CRITERIA_MAP

if [[ -n "$CRITERIA_FILE" ]]; then
  current_project=""
  while IFS= read -r line; do
    echo "[DEBUG] line: '$line'"
    [[ -z "$line" ]] && continue
    if [[ "$line" =~ \[PROJECT:\ (.+)\] ]]; then
      current_project="${BASH_REMATCH[1]}"
      echo "[DEBUG] current_project set: $current_project"
      CRITERIA_MAP["$current_project"]=""
    elif [[ -n "$current_project" && -n "$line" ]]; then
      echo "[DEBUG] add to $current_project: $line"
      if [[ -z "${CRITERIA_MAP[$current_project]}" ]]; then
        CRITERIA_MAP["$current_project"]="$line"
      else
        CRITERIA_MAP["$current_project"]+=$'\n'"$line"
      fi
    fi
  done < <(python3 parse_criteria_excel.py "$CRITERIA_FILE")
else
  echo "--criteriaFile is required."
  exit 1
fi

# Log the parsed criteria map

# Simple log for criteria map, fail if empty
for project in "${!CRITERIA_MAP[@]}"; do
  echo "Project: $project"
  if [[ -z "${CRITERIA_MAP[$project]}" ]]; then
    echo "[ERROR] No criteria found for project: $project"
    exit 1
  fi
  IFS=$'\n' read -d '' -r -a CRITERIA_LIST <<< "${CRITERIA_MAP[$project]}" || true
  for CRITERIA_ITEM in "${CRITERIA_LIST[@]}"; do
    echo "  Criteria: $CRITERIA_ITEM"
  done
done

# Create a temporary working directory for processing in the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR=$(mktemp -d "$SCRIPT_DIR/tmp_xliff_delete.XXXXXXXX")
TEMP_INPUT_DIR="$TEMP_DIR/input"
 mkdir -p "$TEMP_INPUT_DIR"
# TEMP_OUTPUT_DIR="$TEMP_DIR/output"
# mkdir -p "$TEMP_OUTPUT_DIR"


# Copy the entire input directory to TEMP_INPUT_DIR
echo "[INFO] Copying input directory to TEMP_DIR"
cp -r "$INPUT_PATH"/* "$TEMP_INPUT_DIR"
echo "[INFO] Copy complete."

# Update processing logic to use TEMP_INPUT_DIR and TEMP_OUTPUT_DIR
for project in "${!CRITERIA_MAP[@]}"; do
  echo "[INFO] Processing project: $project"
  PROJECT_DIR="$TEMP_INPUT_DIR/$project"

  if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "[ERROR] Project directory not found: ${PROJECT_DIR}"
    continue
  fi

  # TEMP_PROJECT_OUTPUT_DIR="$TEMP_OUTPUT_DIR/$project"
  # mkdir -p "$TEMP_PROJECT_OUTPUT_DIR"

  if [[ -n "${CRITERIA_MAP[$project]+_}" ]]; then
    tmp_val="${CRITERIA_MAP[$project]}"
    IFS=$'\n' read -d '' -r -a CRITERIA_LIST <<< "$tmp_val" || true
    for CRITERIA_ITEM in "${CRITERIA_LIST[@]}"; do
      echo "[INFO] Processing criteria: $CRITERIA_ITEM"
      for file in "$PROJECT_DIR"/*.xliff; do
        echo "[INFO] Processing file: $file"
        locale="$(basename "$file" .xliff)"
        out_file="$file"

        if [[ $DRY_RUN == "true" ]]; then
          echo "[DRY] node \"$LOCTOOL\" select \"$CRITERIA_ITEM\" \"$file\" \"$out_file\" --prune -2 --xliffStyle webOS"
          continue
        fi

        node "$LOCTOOL" select "$CRITERIA_ITEM" "$file" "$out_file" --prune -2 --xliffStyle webOS
        echo "[INFO] Processed $file -> $out_file"
      done
    done
  fi
done


# Move TEMP_OUTPUT_DIR to the final output directory
echo "[INFO] Moving TEMP_INPUT_DIR to final output directory"
rm -rf "$OUTPUT_PATH"
cp -r "$TEMP_INPUT_DIR" "$OUTPUT_PATH"
echo "[INFO] Output move complete."

SCRIPT_END_TIME=$(date +%s)
SCRIPT_ELAPSED=$((SCRIPT_END_TIME - SCRIPT_START_TIME))
echo "[INFO] Completed. Elapsed time: ${SCRIPT_ELAPSED} seconds."
