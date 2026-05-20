#!/usr/bin/env bats

# test_xliff_delete_units.bats - Tests for xliff-delete-units.sh

setup() {
  rm -rf output_* 2>/dev/null || true
}

teardown() {
  rm -rf output_* 2>/dev/null || true
}

check_file_exists() {
  local test_name="$1"
  local filepath="$2"
  if [ ! -f "$filepath" ]; then
    echo "❌ $test_name -- Error: File not found -> $filepath"
    return 1
  fi
}

# Both files are normalized to always end with a newline before comparison
# to avoid false failures caused by "\ No newline at end of file" differences.
check_diff() {
  local test_name="$1"
  local file1="$2"
  local file2="$3"
  run diff <(sed -e '$a\' "$file1") <(sed -e '$a\' "$file2")
  if [ "$status" -ne 0 ]; then
    echo "❌ $test_name -- Error: diff failed between $file1 and $file2"
    echo "$output"
  fi
  [ "$status" -eq 0 ]
}

check_status() {
  local test_name="$1"
  local status="$2"
  if [ "$status" -ne 0 ]; then
    echo "❌ Error: Failed to run ./xliff-delete-units.sh $test_name ..."
    echo "$output"
  fi
  [ "$status" -eq 0 ]
}

# ── Happy path ────────────────────────────────────────────────────────────────

@test "Test - xliff-delete-units.sh --criteria" {
  local test_name="criteria"
  local CRITERIA="key=^More$,source=^More$,project=^adapp$,datatype=^javascript$"

  run ./xliff-delete-units.sh \
    --criteria "$CRITERIA" \
    --inputPath ./testfiles/localization-data \
    --outputPath ./output_criteria

  check_status $test_name $status

  # adapp: 'More' unit deleted — compare against Expected
  check_file_exists $test_name ./output_criteria/adapp/af-ZA.xliff
  check_file_exists $test_name ./output_criteria/adapp/am-ET.xliff
  check_file_exists $test_name ./output_criteria/adapp/ko-KR.xliff
  check_diff $test_name ./output_criteria/adapp/af-ZA.xliff ./testfiles/Expected/adapp/af-ZA.xliff
  check_diff $test_name ./output_criteria/adapp/am-ET.xliff ./testfiles/Expected/adapp/am-ET.xliff
  check_diff $test_name ./output_criteria/adapp/ko-KR.xliff ./testfiles/Expected/adapp/ko-KR.xliff

  # renewupdate: not targeted by this criteria — output must match input unchanged
  check_file_exists $test_name ./output_criteria/renewupdate/af-ZA.xliff
  check_file_exists $test_name ./output_criteria/renewupdate/am-ET.xliff
  check_file_exists $test_name ./output_criteria/renewupdate/ko-KR.xliff
  check_diff $test_name ./output_criteria/renewupdate/af-ZA.xliff ./testfiles/localization-data/renewupdate/af-ZA.xliff
  check_diff $test_name ./output_criteria/renewupdate/am-ET.xliff ./testfiles/localization-data/renewupdate/am-ET.xliff
  check_diff $test_name ./output_criteria/renewupdate/ko-KR.xliff ./testfiles/localization-data/renewupdate/ko-KR.xliff
}

@test "Test - xliff-delete-units.sh --criteriaFile" {
  local test_name="criteriaFile"

  run ./xliff-delete-units.sh \
    --criteriaFile ./testfiles/StringCT_sample.xlsx \
    --inputPath ./testfiles/localization-data \
    --outputPath ./output_criteriafile

  check_status $test_name $status

  # adapp: compare all locales against Expected
  check_file_exists $test_name ./output_criteriafile/adapp/af-ZA.xliff
  check_file_exists $test_name ./output_criteriafile/adapp/am-ET.xliff
  check_file_exists $test_name ./output_criteriafile/adapp/ko-KR.xliff
  check_diff $test_name ./output_criteriafile/adapp/af-ZA.xliff ./testfiles/Expected/adapp/af-ZA.xliff
  check_diff $test_name ./output_criteriafile/adapp/am-ET.xliff ./testfiles/Expected/adapp/am-ET.xliff
  check_diff $test_name ./output_criteriafile/adapp/ko-KR.xliff ./testfiles/Expected/adapp/ko-KR.xliff

  # renewupdate: compare all locales against Expected
  check_file_exists $test_name ./output_criteriafile/renewupdate/af-ZA.xliff
  check_file_exists $test_name ./output_criteriafile/renewupdate/am-ET.xliff
  check_file_exists $test_name ./output_criteriafile/renewupdate/ko-KR.xliff
  check_diff $test_name ./output_criteriafile/renewupdate/af-ZA.xliff ./testfiles/Expected/renewupdate/af-ZA.xliff
  check_diff $test_name ./output_criteriafile/renewupdate/am-ET.xliff ./testfiles/Expected/renewupdate/am-ET.xliff
  check_diff $test_name ./output_criteriafile/renewupdate/ko-KR.xliff ./testfiles/Expected/renewupdate/ko-KR.xliff
}

@test "Test - short options (-c -i -o)" {
  local test_name="short_options"
  local CRITERIA="key=^More$,source=^More$,project=^adapp$,datatype=^javascript$"

  run ./xliff-delete-units.sh \
    -c "$CRITERIA" \
    -i ./testfiles/localization-data \
    -o ./output_short

  check_status $test_name $status
  check_file_exists $test_name ./output_short/adapp/ko-KR.xliff
  check_diff $test_name ./output_short/adapp/ko-KR.xliff ./testfiles/Expected/adapp/ko-KR.xliff
}

@test "Test - equals format (--criteria=value --inputPath=value --outputPath=value)" {
  local test_name="equals_format"
  local CRITERIA="key=^More$,source=^More$,project=^adapp$,datatype=^javascript$"

  run ./xliff-delete-units.sh \
    --criteria="$CRITERIA" \
    --inputPath=./testfiles/localization-data \
    --outputPath=./output_eq

  check_status $test_name $status
  check_file_exists $test_name ./output_eq/adapp/ko-KR.xliff
  check_diff $test_name ./output_eq/adapp/ko-KR.xliff ./testfiles/Expected/adapp/ko-KR.xliff
}

@test "Test - --dry-run does not modify files" {
  local test_name="dry_run"
  local CRITERIA="key=^More$,source=^More$,project=^adapp$,datatype=^javascript$"

  run ./xliff-delete-units.sh \
    --criteria "$CRITERIA" \
    --inputPath ./testfiles/localization-data \
    --outputPath ./output_dryrun \
    --dry-run

  check_status $test_name $status

  # dry-run must copy files but NOT delete units — output equals input
  check_file_exists $test_name ./output_dryrun/adapp/ko-KR.xliff
  check_diff $test_name ./output_dryrun/adapp/ko-KR.xliff ./testfiles/localization-data/adapp/ko-KR.xliff
}

# ── Help ──────────────────────────────────────────────────────────────────────

@test "Test - no arguments shows help and exits 0" {
  run ./xliff-delete-units.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "Test - --help shows help and exits 0" {
  run ./xliff-delete-units.sh --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "--inputPath" ]]
  [[ "$output" =~ "--criteriaFile" ]]
}

@test "Test - -h shows help and exits 0" {
  run ./xliff-delete-units.sh -h
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

# ── Missing required options ──────────────────────────────────────────────────

@test "Test - missing --inputPath exits non-zero" {
  run ./xliff-delete-units.sh \
    --criteria "key=^More$" \
    --outputPath ./output_criteria
  [ "$status" -ne 0 ]
  [[ "$output" =~ "--inputPath" ]]
}

@test "Test - missing --outputPath exits non-zero" {
  run ./xliff-delete-units.sh \
    --criteria "key=^More$" \
    --inputPath ./testfiles/localization-data
  [ "$status" -ne 0 ]
  [[ "$output" =~ "--outputPath" ]]
}

@test "Test - missing --criteria and --criteriaFile exits non-zero" {
  run ./xliff-delete-units.sh \
    --inputPath ./testfiles/localization-data \
    --outputPath ./output_criteria
  [ "$status" -ne 0 ]
  [[ "$output" =~ "--criteria" ]]
}

@test "Test - --criteria and --criteriaFile together exits non-zero" {
  run ./xliff-delete-units.sh \
    --criteria "key=^More$" \
    --criteriaFile ./testfiles/StringCT_sample.xlsx \
    --inputPath ./testfiles/localization-data \
    --outputPath ./output_criteria
  [ "$status" -ne 0 ]
  [[ "$output" =~ "mutually exclusive" ]]
}

# ── Invalid input ─────────────────────────────────────────────────────────────

@test "Test - non-existent --inputPath exits non-zero" {
  run ./xliff-delete-units.sh \
    --criteria "key=^More$" \
    --inputPath ./nonexistent_dir \
    --outputPath ./output_criteria
  [ "$status" -ne 0 ]
}

@test "Test - --inputPath with no .xliff files exits non-zero" {
  mkdir -p /tmp/bats_empty_input_du
  run ./xliff-delete-units.sh \
    --criteria "key=^More$" \
    --inputPath /tmp/bats_empty_input_du \
    --outputPath ./output_criteria
  rmdir /tmp/bats_empty_input_du
  [ "$status" -ne 0 ]
  [[ "$output" =~ ".xliff" ]]
}

@test "Test - non-existent --criteriaFile exits non-zero" {
  run ./xliff-delete-units.sh \
    --criteriaFile ./nonexistent.xlsx \
    --inputPath ./testfiles/localization-data \
    --outputPath ./output_criteria
  [ "$status" -ne 0 ]
}

@test "Test - unknown option exits non-zero" {
  run ./xliff-delete-units.sh \
    --criteria "key=^More$" \
    --inputPath ./testfiles/localization-data \
    --outputPath ./output_criteria \
    --unknown
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Unknown" ]]
}
