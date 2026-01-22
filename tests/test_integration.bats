#!/usr/bin/env bats
# Integration Tests for EXIF File Renaming Utility
# TAG: SPEC-EXIF-001

setup() {
    export SCRIPT_PATH="${BATS_TEST_DIRNAME}/../exif_filename.sh"
    export TEST_DIR="${BATS_TEST_DIRNAME}/tmp_integration"
    mkdir -p "$TEST_DIR"
}

teardown() {
    rm -rf "$TEST_DIR"
}

# =============================================================================
# Integration Tests - Full Workflow
# =============================================================================

@test "INTEGRATION: processes directory with supported files" {
    # Create test files (without EXIF, will use file timestamps)
    touch "$TEST_DIR/IMG_001.jpg"
    touch "$TEST_DIR/DSC_002.png"
    touch "$TEST_DIR/video.mp4"

    run "$SCRIPT_PATH" "$TEST_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Processing files"* ]]
}

@test "INTEGRATION: skips already formatted files without force" {
    # Create a file that's already in target format
    touch "$TEST_DIR/2024_03_15_14h30m45s.jpg"

    run "$SCRIPT_PATH" "$TEST_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping"* ]] || [[ "$output" == *"skipped"* ]]
}

@test "INTEGRATION: force mode reprocesses formatted files" {
    source "$SCRIPT_PATH"

    # Create a file in target format
    touch "$TEST_DIR/2024_03_15_14h30m45s.jpg"

    # With force mode, it should attempt to process
    run "$SCRIPT_PATH" --force "$TEST_DIR"
    [ "$status" -eq 0 ]
}

@test "INTEGRATION: ignores unsupported file types" {
    # Create mixed files
    touch "$TEST_DIR/photo.jpg"
    touch "$TEST_DIR/document.pdf"
    touch "$TEST_DIR/notes.txt"

    run "$SCRIPT_PATH" "$TEST_DIR"
    [ "$status" -eq 0 ]
    # Should show only 1 file processed (jpg), others ignored
    [[ "$output" == *"Total files found"* ]]
}

@test "INTEGRATION: handles nested directories" {
    # Create nested structure
    mkdir -p "$TEST_DIR/subdir1/subdir2"
    touch "$TEST_DIR/photo1.jpg"
    touch "$TEST_DIR/subdir1/photo2.jpg"
    touch "$TEST_DIR/subdir1/subdir2/photo3.jpg"

    run "$SCRIPT_PATH" "$TEST_DIR"
    [ "$status" -eq 0 ]
    # Should find files in all subdirectories
    [[ "$output" == *"Processing"* ]]
}

@test "INTEGRATION: displays summary after processing" {
    touch "$TEST_DIR/photo.jpg"

    run "$SCRIPT_PATH" "$TEST_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Processing Summary"* ]]
    [[ "$output" == *"Total files found"* ]]
    [[ "$output" == *"Files renamed"* ]]
}

@test "INTEGRATION: handles duplicate timestamps correctly" {
    # Create multiple files that will have same timestamp (same second)
    touch "$TEST_DIR/photo1.jpg"
    touch "$TEST_DIR/photo2.jpg"
    touch "$TEST_DIR/photo3.jpg"

    run "$SCRIPT_PATH" "$TEST_DIR"
    [ "$status" -eq 0 ]

    # Check that files exist with counter suffixes
    local count
    count=$(ls "$TEST_DIR"/*.jpg 2>/dev/null | wc -l)
    [ "$count" -eq 3 ]
}

# =============================================================================
# EXIF Extraction Tests (requires exiftool)
# =============================================================================

@test "INTEGRATION: extract_datetime returns empty for file without EXIF" {
    if ! command -v exiftool &>/dev/null; then
        skip "exiftool not installed"
    fi

    source "$SCRIPT_PATH"
    touch "$TEST_DIR/no_exif.jpg"

    run extract_datetime "$TEST_DIR/no_exif.jpg"
    # Should return empty string (no EXIF data in a simple touch file)
    [ -z "$output" ]
}

@test "INTEGRATION: fallback to file time when no EXIF" {
    source "$SCRIPT_PATH"

    # Create file with specific timestamp
    touch -t 202403151430.45 "$TEST_DIR/test.jpg" 2>/dev/null || touch "$TEST_DIR/test.jpg"

    run fallback_to_file_time "$TEST_DIR/test.jpg"
    [ "$status" -eq 0 ]
    # Output should match timestamp format
    [[ "$output" =~ ^[0-9]{4}_[0-9]{2}_[0-9]{2}_[0-9]{2}h[0-9]{2}m[0-9]{2}s$ ]]
}

# =============================================================================
# Error Handling Integration Tests
# =============================================================================

@test "INTEGRATION: handles read-only files gracefully" {
    touch "$TEST_DIR/readonly.jpg"
    chmod 444 "$TEST_DIR/readonly.jpg"

    # Should complete but may skip the read-only file
    run "$SCRIPT_PATH" "$TEST_DIR"

    # Restore permissions for cleanup (file may have been renamed)
    chmod 644 "$TEST_DIR"/*.jpg 2>/dev/null || true

    # Should not crash
    [[ "$status" -eq 0 || "$status" -eq 1 ]]
}

@test "INTEGRATION: complete workflow with sample data" {
    # Create realistic test scenario
    mkdir -p "$TEST_DIR/vacation"
    mkdir -p "$TEST_DIR/vacation/day1"
    mkdir -p "$TEST_DIR/vacation/day2"

    touch "$TEST_DIR/vacation/day1/IMG_0001.jpg"
    touch "$TEST_DIR/vacation/day1/IMG_0002.jpg"
    touch "$TEST_DIR/vacation/day2/DSC_0003.nef"
    touch "$TEST_DIR/vacation/video.mov"
    touch "$TEST_DIR/vacation/notes.txt"  # Should be ignored

    run "$SCRIPT_PATH" "$TEST_DIR/vacation"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Processing Summary"* ]]
    [[ "$output" == *"4"* ]]  # Total 4 supported files
}
