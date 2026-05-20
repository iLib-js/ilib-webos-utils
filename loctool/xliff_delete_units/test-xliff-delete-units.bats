#!/usr/bin/env bats

# test-xliff-delete-units.bats - Tests for xliff-delete-units.sh

setup() {
  SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
  XLIFF_DELETE_UNITS_SH="$SCRIPT_DIR/xliff-delete-units.sh"
  TESTFILES_DIR="$SCRIPT_DIR/testfiles"
  OUTPUT_DIR_BASE="$SCRIPT_DIR/output_"
  rm -rf ${OUTPUT_DIR_BASE}* 2>/dev/null || true
}

teardown() {
  rm -rf ${OUTPUT_DIR_BASE}* 2>/dev/null || true
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

  run "$XLIFF_DELETE_UNITS_SH" \
    --criteria "$CRITERIA" \
    --inputPath "$TESTFILES_DIR/localization-data" \
    --outputPath "${OUTPUT_DIR_BASE}criteria"

  check_status $test_name $status

  # adapp: 'More' unit deleted — compare against Expected
  check_file_exists $test_name ${OUTPUT_DIR_BASE}criteria/adapp/af-ZA.xliff
  check_file_exists $test_name ${OUTPUT_DIR_BASE}criteria/adapp/am-ET.xliff
  check_file_exists $test_name ${OUTPUT_DIR_BASE}criteria/adapp/ko-KR.xliff
  check_diff $test_name ${OUTPUT_DIR_BASE}criteria/adapp/af-ZA.xliff "$TESTFILES_DIR/Expected/adapp/af-ZA.xliff"
  check_diff $test_name ${OUTPUT_DIR_BASE}criteria/adapp/am-ET.xliff "$TESTFILES_DIR/Expected/adapp/am-ET.xliff"
  check_diff $test_name ${OUTPUT_DIR_BASE}criteria/adapp/ko-KR.xliff "$TESTFILES_DIR/Expected/adapp/ko-KR.xliff"

  # renewupdate: not targeted by this criteria — output must match input unchanged
  check_file_exists $test_name ${OUTPUT_DIR_BASE}criteria/renewupdate/af-ZA.xliff
  check_file_exists $test_name ${OUTPUT_DIR_BASE}criteria/renewupdate/am-ET.xliff
  check_file_exists $test_name ${OUTPUT_DIR_BASE}criteria/renewupdate/ko-KR.xliff
  check_diff $test_name ${OUTPUT_DIR_BASE}criteria/renewupdate/af-ZA.xliff "$TESTFILES_DIR/localization-data/renewupdate/af-ZA.xliff"
  check_diff $test_name ${OUTPUT_DIR_BASE}criteria/renewupdate/am-ET.xliff "$TESTFILES_DIR/localization-data/renewupdate/am-ET.xliff"
  check_diff $test_name ${OUTPUT_DIR_BASE}criteria/renewupdate/ko-KR.xliff "$TESTFILES_DIR/localization-data/renewupdate/ko-KR.xliff"
}

@test "Test - xliff-delete-units.sh --criteriaFile" {
  local test_name="criteriaFile"

  run "$XLIFF_DELETE_UNITS_SH" \
    --criteriaFile "$TESTFILES_DIR/StringCT_sample.xlsx" \
    --inputPath "$TESTFILES_DIR/localization-data" \
    --outputPath "${OUTPUT_DIR_BASE}criteriafile"

  check_status $test_name $status

  # adapp: compare all locales against Expected
  check_file_exists $test_name ${OUTPUT_DIR_BASE}criteriafile/adapp/af-ZA.xliff
  check_file_exists $test_name ${OUTPUT_DIR_BASE}criteriafile/adapp/am-ET.xliff
  check_file_exists $test_name ${OUTPUT_DIR_BASE}criteriafile/adapp/ko-KR.xliff
  check_diff $test_name ${OUTPUT_DIR_BASE}criteriafile/adapp/af-ZA.xliff "$TESTFILES_DIR/Expected/adapp/af-ZA.xliff"
  check_diff $test_name ${OUTPUT_DIR_BASE}criteriafile/adapp/am-ET.xliff "$TESTFILES_DIR/Expected/adapp/am-ET.xliff"
  check_diff $test_name ${OUTPUT_DIR_BASE}criteriafile/adapp/ko-KR.xliff "$TESTFILES_DIR/Expected/adapp/ko-KR.xliff"

  # renewupdate: compare all locales against Expected
  check_file_exists $test_name ${OUTPUT_DIR_BASE}criteriafile/renewupdate/af-ZA.xliff
  check_file_exists $test_name ${OUTPUT_DIR_BASE}criteriafile/renewupdate/am-ET.xliff
  check_file_exists $test_name ${OUTPUT_DIR_BASE}criteriafile/renewupdate/ko-KR.xliff
  check_diff $test_name ${OUTPUT_DIR_BASE}criteriafile/renewupdate/af-ZA.xliff "$TESTFILES_DIR/Expected/renewupdate/af-ZA.xliff"
  check_diff $test_name ${OUTPUT_DIR_BASE}criteriafile/renewupdate/am-ET.xliff "$TESTFILES_DIR/Expected/renewupdate/am-ET.xliff"
  check_diff $test_name ${OUTPUT_DIR_BASE}criteriafile/renewupdate/ko-KR.xliff "$TESTFILES_DIR/Expected/renewupdate/ko-KR.xliff"
}

@test "Test - short options (-c -i -o)" {
  local test_name="short_options"
  local CRITERIA="key=^More$,source=^More$,project=^adapp$,datatype=^javascript$"

  run "$XLIFF_DELETE_UNITS_SH" \
    -c "$CRITERIA" \
    -i "$TESTFILES_DIR/localization-data" \
    -o "${OUTPUT_DIR_BASE}short"

  check_status $test_name $status
  check_file_exists $test_name ${OUTPUT_DIR_BASE}short/adapp/ko-KR.xliff
  check_diff $test_name ${OUTPUT_DIR_BASE}short/adapp/ko-KR.xliff "$TESTFILES_DIR/Expected/adapp/ko-KR.xliff"
}

@test "Test - equals format (--criteria=value --inputPath=value --outputPath=value)" {
  local test_name="equals_format"
  local CRITERIA="key=^More$,source=^More$,project=^adapp$,datatype=^javascript$"

  run "$XLIFF_DELETE_UNITS_SH" \
    --criteria="$CRITERIA" \
    --inputPath="$TESTFILES_DIR/localization-data" \
    --outputPath="${OUTPUT_DIR_BASE}eq"

  check_status $test_name $status
  check_file_exists $test_name ${OUTPUT_DIR_BASE}eq/adapp/ko-KR.xliff
  check_diff $test_name ${OUTPUT_DIR_BASE}eq/adapp/ko-KR.xliff "$TESTFILES_DIR/Expected/adapp/ko-KR.xliff"
}

@test "Test - --dry-run does not modify files" {
  local test_name="dry_run"
  local CRITERIA="key=^More$,source=^More$,project=^adapp$,datatype=^javascript$"

  run "$XLIFF_DELETE_UNITS_SH" \
    --criteria "$CRITERIA" \
    --inputPath "$TESTFILES_DIR/localization-data" \
    --outputPath "${OUTPUT_DIR_BASE}dryrun" \
    --dry-run

  check_status $test_name $status

  # dry-run must copy files but NOT delete units — output equals input
  check_file_exists $test_name ${OUTPUT_DIR_BASE}dryrun/adapp/ko-KR.xliff
  check_diff $test_name ${OUTPUT_DIR_BASE}dryrun/adapp/ko-KR.xliff "$TESTFILES_DIR/localization-data/adapp/ko-KR.xliff"
}

# ── Help ──────────────────────────────────────────────────────────────────────

@test "Test - no arguments shows help and exits 0" {
  run "$XLIFF_DELETE_UNITS_SH"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "Test - --help shows help and exits 0" {
  run "$XLIFF_DELETE_UNITS_SH" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "--inputPath" ]]
  [[ "$output" =~ "--criteriaFile" ]]
}

@test "Test - -h shows help and exits 0" {
  run "$XLIFF_DELETE_UNITS_SH" -h
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

# ── Missing required options ──────────────────────────────────────────────────

@test "Test - missing --inputPath exits non-zero" {
  run "$XLIFF_DELETE_UNITS_SH" \
    --criteria "key=^More$" \
    --outputPath "${OUTPUT_DIR_BASE}criteria"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "--inputPath" ]]
}

@test "Test - missing --outputPath exits non-zero" {
  run "$XLIFF_DELETE_UNITS_SH" \
    --criteria "key=^More$" \
    --inputPath "$TESTFILES_DIR/localization-data"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "--outputPath" ]]
}

@test "Test - missing --criteria and --criteriaFile exits non-zero" {
  run "$XLIFF_DELETE_UNITS_SH" \
    --inputPath "$TESTFILES_DIR/localization-data" \
    --outputPath "${OUTPUT_DIR_BASE}criteria"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "--criteria" ]]
}

@test "Test - --criteria and --criteriaFile together exits non-zero" {
  run "$XLIFF_DELETE_UNITS_SH" \
    --criteria "key=^More$" \
    --criteriaFile "$TESTFILES_DIR/StringCT_sample.xlsx" \
    --inputPath "$TESTFILES_DIR/localization-data" \
    --outputPath "${OUTPUT_DIR_BASE}criteria"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "mutually exclusive" ]]
}

# ── Invalid input ─────────────────────────────────────────────────────────────

@test "Test - non-existent --inputPath exits non-zero" {
  run "$XLIFF_DELETE_UNITS_SH" \
    --criteria "key=^More$" \
    --inputPath ./nonexistent_dir \
    --outputPath "${OUTPUT_DIR_BASE}criteria"
  [ "$status" -ne 0 ]
}

@test "Test - --inputPath with no .xliff files exits non-zero" {
  mkdir -p /tmp/bats_empty_input_du
  run "$XLIFF_DELETE_UNITS_SH" \
    --criteria "key=^More$" \
    --inputPath /tmp/bats_empty_input_du \
    --outputPath "${OUTPUT_DIR_BASE}criteria"
  rmdir /tmp/bats_empty_input_du
  [ "$status" -ne 0 ]
  [[ "$output" =~ ".xliff" ]]
}

@test "Test - non-existent --criteriaFile exits non-zero" {
  run "$XLIFF_DELETE_UNITS_SH" \
    --criteriaFile ./nonexistent.xlsx \
    --inputPath "$TESTFILES_DIR/localization-data" \
    --outputPath "${OUTPUT_DIR_BASE}criteria"
  [ "$status" -ne 0 ]
}

@test "Test - unknown option exits non-zero" {
  run "$XLIFF_DELETE_UNITS_SH" \
    --criteria "key=^More$" \
    --inputPath "$TESTFILES_DIR/localization-data" \
    --outputPath "${OUTPUT_DIR_BASE}criteria" \
    --unknown
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Unknown" ]]
}
