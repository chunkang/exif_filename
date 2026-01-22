#!/usr/bin/env bats
# Tests for Phase 4-5: File Operations
# TAG: SPEC-EXIF-001

setup() {
    export SCRIPT_PATH="${BATS_TEST_DIRNAME}/../exif_filename.sh"
    export TEST_DIR="${BATS_TEST_DIRNAME}/tmp"
    mkdir -p "$TEST_DIR"
}

teardown() {
    rm -rf "$TEST_DIR"
}

# =============================================================================
# Duplicate Resolution
# =============================================================================

@test "resolve_duplicate returns original name when no conflict" {
    source "$SCRIPT_PATH"

    run resolve_duplicate "2024_03_15_14h30m45s" "jpg" "$TEST_DIR"
    [ "$output" = "2024_03_15_14h30m45s.jpg" ]
}

@test "resolve_duplicate adds _1 when file exists" {
    source "$SCRIPT_PATH"

    touch "$TEST_DIR/2024_03_15_14h30m45s.jpg"

    run resolve_duplicate "2024_03_15_14h30m45s" "jpg" "$TEST_DIR"
    [ "$output" = "2024_03_15_14h30m45s_1.jpg" ]
}

@test "resolve_duplicate adds _2 when _1 exists" {
    source "$SCRIPT_PATH"

    touch "$TEST_DIR/2024_03_15_14h30m45s.jpg"
    touch "$TEST_DIR/2024_03_15_14h30m45s_1.jpg"

    run resolve_duplicate "2024_03_15_14h30m45s" "jpg" "$TEST_DIR"
    [ "$output" = "2024_03_15_14h30m45s_2.jpg" ]
}

@test "resolve_duplicate handles multiple duplicates" {
    source "$SCRIPT_PATH"

    touch "$TEST_DIR/2024_03_15_14h30m45s.jpg"
    touch "$TEST_DIR/2024_03_15_14h30m45s_1.jpg"
    touch "$TEST_DIR/2024_03_15_14h30m45s_2.jpg"
    touch "$TEST_DIR/2024_03_15_14h30m45s_3.jpg"

    run resolve_duplicate "2024_03_15_14h30m45s" "jpg" "$TEST_DIR"
    [ "$output" = "2024_03_15_14h30m45s_4.jpg" ]
}

# =============================================================================
# Filename Generation
# =============================================================================

@test "generate_new_filename creates correct format without location" {
    source "$SCRIPT_PATH"

    touch "$TEST_DIR/IMG_1234.jpg"

    run generate_new_filename "$TEST_DIR/IMG_1234.jpg" "2024_03_15_14h30m45s" ""
    [ "$output" = "$TEST_DIR/2024_03_15_14h30m45s.jpg" ]
}

@test "generate_new_filename includes location when provided" {
    source "$SCRIPT_PATH"

    touch "$TEST_DIR/vacation.jpg"

    run generate_new_filename "$TEST_DIR/vacation.jpg" "2024_03_15_14h30m45s" "Seoul_Seoul_KR"
    [ "$output" = "$TEST_DIR/2024_03_15_14h30m45s_Seoul_Seoul_KR.jpg" ]
}

@test "generate_new_filename converts extension to lowercase" {
    source "$SCRIPT_PATH"

    touch "$TEST_DIR/PHOTO.JPG"

    run generate_new_filename "$TEST_DIR/PHOTO.JPG" "2024_03_15_14h30m45s" ""
    [ "$output" = "$TEST_DIR/2024_03_15_14h30m45s.jpg" ]
}

@test "generate_new_filename handles duplicate" {
    source "$SCRIPT_PATH"

    touch "$TEST_DIR/IMG_1234.jpg"
    touch "$TEST_DIR/2024_03_15_14h30m45s.jpg"

    run generate_new_filename "$TEST_DIR/IMG_1234.jpg" "2024_03_15_14h30m45s" ""
    [ "$output" = "$TEST_DIR/2024_03_15_14h30m45s_1.jpg" ]
}

# =============================================================================
# File Rename Operations
# =============================================================================

@test "rename_file successfully renames a file" {
    source "$SCRIPT_PATH"

    touch "$TEST_DIR/original.jpg"

    run rename_file "$TEST_DIR/original.jpg" "$TEST_DIR/renamed.jpg"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/renamed.jpg" ]
    [ ! -f "$TEST_DIR/original.jpg" ]
}

@test "rename_file sets permissions to 664" {
    source "$SCRIPT_PATH"

    touch "$TEST_DIR/original.jpg"
    rename_file "$TEST_DIR/original.jpg" "$TEST_DIR/renamed.jpg"

    # Check permissions (rw-rw-r--)
    local perms
    perms=$(stat -f "%Lp" "$TEST_DIR/renamed.jpg" 2>/dev/null || stat -c "%a" "$TEST_DIR/renamed.jpg" 2>/dev/null)
    [ "$perms" = "664" ]
}

@test "rename_file preserves file content" {
    source "$SCRIPT_PATH"

    echo "test content" > "$TEST_DIR/original.txt"
    local original_checksum
    original_checksum=$(md5 -q "$TEST_DIR/original.txt" 2>/dev/null || md5sum "$TEST_DIR/original.txt" | cut -d' ' -f1)

    rename_file "$TEST_DIR/original.txt" "$TEST_DIR/renamed.txt"

    local new_checksum
    new_checksum=$(md5 -q "$TEST_DIR/renamed.txt" 2>/dev/null || md5sum "$TEST_DIR/renamed.txt" | cut -d' ' -f1)

    [ "$original_checksum" = "$new_checksum" ]
}

@test "rename_file fails for non-existent source" {
    source "$SCRIPT_PATH"

    run rename_file "$TEST_DIR/nonexistent.jpg" "$TEST_DIR/renamed.jpg"
    [ "$status" -eq 1 ]
}

# =============================================================================
# Special Characters Handling
# =============================================================================

@test "handles filenames with spaces" {
    source "$SCRIPT_PATH"

    touch "$TEST_DIR/my photo.jpg"

    run generate_new_filename "$TEST_DIR/my photo.jpg" "2024_03_15_14h30m45s" ""
    [ "$status" -eq 0 ]
    [ "$output" = "$TEST_DIR/2024_03_15_14h30m45s.jpg" ]
}

@test "handles filenames with parentheses" {
    source "$SCRIPT_PATH"

    touch "$TEST_DIR/photo (1).jpg"

    run generate_new_filename "$TEST_DIR/photo (1).jpg" "2024_03_15_14h30m45s" ""
    [ "$status" -eq 0 ]
}

@test "handles filenames with dashes" {
    source "$SCRIPT_PATH"

    touch "$TEST_DIR/photo-copy.jpg"

    run generate_new_filename "$TEST_DIR/photo-copy.jpg" "2024_03_15_14h30m45s" ""
    [ "$status" -eq 0 ]
}
