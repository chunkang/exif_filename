#!/usr/bin/env bats
# Tests for Phase 3: EXIF Extraction
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
# File Type Detection
# =============================================================================

@test "is_supported_file returns true for jpg" {
    source "$SCRIPT_PATH"
    is_supported_file "photo.jpg"
}

@test "is_supported_file returns true for JPEG (uppercase)" {
    source "$SCRIPT_PATH"
    is_supported_file "photo.JPEG"
}

@test "is_supported_file returns true for png" {
    source "$SCRIPT_PATH"
    is_supported_file "screenshot.png"
}

@test "is_supported_file returns true for cr2 (Canon RAW)" {
    source "$SCRIPT_PATH"
    is_supported_file "IMG_1234.CR2"
}

@test "is_supported_file returns true for nef (Nikon RAW)" {
    source "$SCRIPT_PATH"
    is_supported_file "DSC_0001.NEF"
}

@test "is_supported_file returns true for heic" {
    source "$SCRIPT_PATH"
    is_supported_file "IMG_1234.HEIC"
}

@test "is_supported_file returns true for mov video" {
    source "$SCRIPT_PATH"
    is_supported_file "video.mov"
}

@test "is_supported_file returns true for mp4 video" {
    source "$SCRIPT_PATH"
    is_supported_file "video.MP4"
}

@test "is_supported_file returns false for unsupported type" {
    source "$SCRIPT_PATH"
    ! is_supported_file "document.pdf"
}

@test "is_supported_file returns false for txt" {
    source "$SCRIPT_PATH"
    ! is_supported_file "notes.txt"
}

# =============================================================================
# Video Detection
# =============================================================================

@test "is_video_file returns true for mov" {
    source "$SCRIPT_PATH"
    run is_video_file "video.mov"
    [ "$status" -eq 0 ]
}

@test "is_video_file returns true for mp4" {
    source "$SCRIPT_PATH"
    run is_video_file "video.mp4"
    [ "$status" -eq 0 ]
}

@test "is_video_file returns false for jpg" {
    source "$SCRIPT_PATH"
    run is_video_file "photo.jpg"
    [ "$status" -eq 1 ]
}

# =============================================================================
# Timestamp Fallback
# =============================================================================

@test "fallback_to_file_time returns formatted timestamp" {
    source "$SCRIPT_PATH"

    # Create a test file
    touch "$TEST_DIR/test_file.txt"

    run fallback_to_file_time "$TEST_DIR/test_file.txt"
    [ "$status" -eq 0 ]
    # Check output matches expected format: YYYY_MM_DD_HHhMMmSSs
    [[ "$output" =~ ^[0-9]{4}_[0-9]{2}_[0-9]{2}_[0-9]{2}h[0-9]{2}m[0-9]{2}s$ ]]
}

# =============================================================================
# Target Format Detection
# =============================================================================

@test "matches_target_format returns true for valid format" {
    source "$SCRIPT_PATH"
    run matches_target_format "2024_03_15_14h30m45s.jpg"
    [ "$status" -eq 0 ]
}

@test "matches_target_format returns true for format with location" {
    source "$SCRIPT_PATH"
    run matches_target_format "2024_03_15_14h30m45s_Seoul_Seoul_KR.jpg"
    [ "$status" -eq 0 ]
}

@test "matches_target_format returns true for format with counter" {
    source "$SCRIPT_PATH"
    run matches_target_format "2024_03_15_14h30m45s_1.jpg"
    [ "$status" -eq 0 ]
}

@test "matches_target_format returns true for format with location and counter" {
    source "$SCRIPT_PATH"
    run matches_target_format "2024_03_15_14h30m45s_Seoul_Seoul_KR_1.jpg"
    [ "$status" -eq 0 ]
}

@test "matches_target_format returns false for original camera name" {
    source "$SCRIPT_PATH"
    run matches_target_format "IMG_1234.jpg"
    [ "$status" -eq 1 ]
}

@test "matches_target_format returns false for DSC format" {
    source "$SCRIPT_PATH"
    run matches_target_format "DSC_0001.jpg"
    [ "$status" -eq 1 ]
}
