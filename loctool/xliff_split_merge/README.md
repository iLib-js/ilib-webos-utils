# xliff_split_merge.sh

This Bash script provides utilities for managing XLIFF files used in localization workflows.
It supports merging and splitting operations across multiple components and languages using the loctool.js utility.

## Features

- Merge: Combine current and input XLIFF files into a unified output.
- Merge by Language: Merge XLIFF files for the same language across multiple apps.
- Split by Component: Split merged XLIFF files into individual components.

## Requirements

- Node.js
- loctool.js (automatically located from ../../node_modules/.pnpm)

## Usage

```
./xliff_split_merge.sh <COMMAND> <INPUT_DIR> [OUTPUT_DIR] [CURRENT_DIR (only for merge)]
```

### Commands

#### 1. merge

Merges XLIFF files from INPUT_DIR with those in CURRENT_DIR, saving results to OUTPUT_DIR.

```
./xliff_split_merge.sh merge <INPUT_DIR> <OUTPUT_DIR> <CURRENT_DIR>
```

#### 2. merge_language

Merges XLIFF files for the same language across multiple apps in INPUT_DIR.

```
./xliff_split_merge.sh merge_language <INPUT_DIR> [OUTPUT_DIR]
```

If OUTPUT_DIR is not specified, it defaults to `<INPUT_DIR>--results`.

#### 3. split_component

Splits merged XLIFF files in INPUT_DIR into separate components and saves them to OUTPUT_DIR.

```
./xliff_split_merge.sh split_component <INPUT_DIR> [OUTPUT_DIR]
```

If OUTPUT_DIR is not specified, it defaults to `<INPUT_DIR>--results`.

## Directory Structure

- INPUT_DIR: Directory containing source .xliff files.
- OUTPUT_DIR: Directory where processed files will be saved.
- CURRENT_DIR: Directory containing current .xliff files (used only in merge).

## Notes

- The script automatically locates loctool.js from the pnpm node_modules directory.
- It ensures output directories are created if they do not exist.
- It skips merging if corresponding input files are missing.

## Example

```
./xliff_split_merge.sh merge_language ./localization-data ./output_merge_language
```

This merges all xliff files for each language across multiple apps in ./localization-data and saves them to ./output_merge_language.

## Testing with Bats

This script can be tested using bats-core, a Bash automated testing system.

### Installation

```
npm install -g bats
```

### Running Tests

```
bats test_xliff_split_merge.bats
```
