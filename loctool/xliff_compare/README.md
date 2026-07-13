# xliff-compare.sh

This Bash script compares two directories of webOS XLIFF files and writes differences to categorized output folders.
It uses loctool compare to detect modified, added, and deleted translation units.

## Features

- Compare two XLIFF directory trees (`from` and `to`).
- Categorize results into `modified`, `added`, and `deleted`.
- Preserve app/locale relative paths in output.
- Support long options, short options, and equals format.

## Requirements

- Node.js >= 20
- loctool >= 2.33.1 (installed locally via `pre-requisite.sh`; the `compare` command requires 2.33.1 or later)

## Setup (one-time)

```bash
./pre-requisite.sh    # installs Node.js (via NVM if needed), loctool, and bats
```

## Usage

```bash
./xliff-compare.sh --from <FROM_DIR> --to <TO_DIR> --output <OUTPUT_DIR>
```

### Options

- `--from`, `-f`: Directory containing baseline XLIFF files (`app/lang.xliff`).
- `--to`, `-t`: Directory containing target XLIFF files (same structure).
- `--output`, `-o`: Directory where comparison results are written.
- `--help`, `-h`: Show usage help.

### Option Formats

- Space-separated: `--from ./from --to ./to --output ./out`
- Equals format: `--from=./from --to=./to --output=./out`
- Short options: `-f ./from -t ./to -o ./out`

## Output Structure

The script writes result files under:

- `<OUTPUT_DIR>/modified/<app>/<locale>.xliff`: Units changed between `from` and `to`.
- `<OUTPUT_DIR>/added/<app>/<locale>.xliff`: Units only in `to`.
- `<OUTPUT_DIR>/deleted/<app>/<locale>.xliff`: Units only in `from`.

## Behavior Notes

- Both `FROM_DIR` and `TO_DIR` must exist and contain at least one `.xliff` file.
- Files only in `to` are copied to `added`.
- Files only in `from` are copied to `deleted`.
- Files in both are compared using `loctool compare` with `-2 --xliffStyle webOS`.

## Example

```bash
./xliff-compare.sh --from ./lang_v1 --to ./lang_v2 --output ./changes
```

## Testing with Bats

`pre-requisite.sh` installs bats-core. Run the tests with:

```bash
bats test-xliff-compare.bats
```

## Notes

- The script validates that both `FROM_DIR` and `TO_DIR` exist and contain at least one `.xliff` file before running the comparison
- The output directory is automatically created if it does not exist
- All file paths can be relative or absolute
