# xliff-delete-units.sh

This Bash script deletes translation units from XLIFF files using loctool select criteria.
It supports direct criteria input and Excel-based criteria input for project-specific processing.

## Features

- Delete by Criteria: Delete units matching a loctool criteria string.
- Delete by Criteria File: Read an Excel file and apply criteria grouped by project.
- Dry Run: Print planned actions without modifying output files.
- Flexible CLI: Supports long options, short options, and equals format.

## Requirements

- Node.js
- loctool (automatically located from local node_modules or ../../node_modules/.pnpm)
- Python 3 (required when using --criteriaFile)
- Python packages: pandas, openpyxl (required when using --criteriaFile)

## Usage

```
./xliff-delete-units.sh --inputPath <input-path> --outputPath <output-path> [--criteria "<criteria>" | --criteriaFile <excel-file>] [--dry-run]
```

### Options

- `-i`, `--inputPath`: Base directory containing input XLIFF files. (required)
- `-o`, `--outputPath`: Directory where processed XLIFF files will be written. (required)
- `-c`, `--criteria`: loctool select criteria string. (mutually exclusive with `--criteriaFile`)
- `-f`, `--criteriaFile`: Excel file (`.xlsx`) used to generate criteria list. (mutually exclusive with `--criteria`)
- `--dry-run`: Do not execute loctool. Only print planned commands.

### Constraints

- Exactly one of `--criteria` or `--criteriaFile` must be specified.

### Examples

#### 1. Delete units with direct criteria

```
./xliff-delete-units.sh --inputPath ./input --outputPath ./output --criteria "source=^OK$,key=^OK$,datatype=^javascript$"
```

#### 2. Delete units with Excel criteria file

```
./xliff-delete-units.sh --inputPath ./input --outputPath ./output --criteriaFile ./criteria.xlsx
```

#### 3. Short options

```
./xliff-delete-units.sh -i ./input -o ./output -f ./criteria.xlsx
```

#### 4. Equals format

```
./xliff-delete-units.sh -i=./input -o=./output -f=./criteria.xlsx
```

#### 5. Dry run

```
./xliff-delete-units.sh --inputPath ./input --outputPath ./output --criteria "key=^More$" --dry-run
```

## Input and Output Structure

- `INPUT_PATH`: Base directory containing project subdirectories with `.xliff` files.
- `OUTPUT_PATH`: Directory where processed files are copied after deletion.

### Assumptions

- Locale files are named as `<locale>.xliff` under `<inputPath>/<projectId>`.
- Output files are written under `<outputPath>/<projectId>/<locale>.xliff`.

## Notes

- The script copies input files to a temporary directory first, then applies deletion there.
- If `--criteriaFile` is used, `parse_criteria_excel.py` reads the Excel file and generates per-project criteria.
- Existing `OUTPUT_PATH` is removed and replaced with processed output.

## Testing with Bats

This script can be tested using bats-core.

### Installation

```
npm install -g bats
pip install pandas openpyxl
```

### Running Tests

```
bats test_xliff_delete_units.bats
```
