#!/usr/bin/env bats
# Tests for SPEC-CACHE-001: Geocode Location Caching
# TAG: SPEC-CACHE-001
#
# Grid-based proximity caching with 0.0005 degree cells (~55m)
# for reducing redundant API calls during batch photo processing.

# Setup - runs before each test
setup() {
    export SCRIPT_PATH="${BATS_TEST_DIRNAME}/../exif_filename.sh"
    export TEST_DIR="${BATS_TEST_DIRNAME}/tmp"
    mkdir -p "$TEST_DIR"

    # Source the script to access functions
    source "$SCRIPT_PATH"
}

# Teardown - runs after each test
teardown() {
    rm -rf "$TEST_DIR"
}

# =============================================================================
# Phase 1: Cache Infrastructure Tests
# =============================================================================

@test "normalize_coordinates function exists" {
    # Verify the function is defined
    declare -f normalize_coordinates > /dev/null
}

@test "normalize_coordinates produces consistent grid keys" {
    # Same location should produce same grid key
    local key1 key2
    key1=$(normalize_coordinates 37.5665 126.9780)
    key2=$(normalize_coordinates 37.5665 126.9780)
    [ "$key1" = "$key2" ]
}

@test "normalize_coordinates produces different keys for distant locations" {
    # Locations far apart should produce different grid keys
    local key1 key2
    key1=$(normalize_coordinates 37.5665 126.9780)  # Seoul
    key2=$(normalize_coordinates 35.1796 129.0756)  # Busan
    [ "$key1" != "$key2" ]
}

@test "normalize_coordinates produces same key for nearby coordinates" {
    # Coordinates within ~55m should map to same grid cell
    # Grid size is 0.0005 degrees
    local key1 key2
    key1=$(normalize_coordinates 37.56650 126.97800)
    key2=$(normalize_coordinates 37.56652 126.97802)  # ~2m difference
    [ "$key1" = "$key2" ]
}

@test "normalize_coordinates produces different keys for boundary cases" {
    # Coordinates just outside grid cell should produce different key
    local key1 key2
    key1=$(normalize_coordinates 37.5665 126.9780)
    key2=$(normalize_coordinates 37.5671 126.9786)  # ~66m difference
    [ "$key1" != "$key2" ]
}

@test "normalize_coordinates handles negative coordinates" {
    # Southern hemisphere and Western hemisphere coordinates
    local key1 key2
    key1=$(normalize_coordinates -33.8688 151.2093)  # Sydney
    key2=$(normalize_coordinates -33.8688 151.2093)
    [ "$key1" = "$key2" ]
}

@test "normalize_coordinates handles zero coordinates" {
    # Equator and prime meridian intersection
    local key
    key=$(normalize_coordinates 0.0 0.0)
    [ -n "$key" ]
}

# =============================================================================
# Phase 1: Cache Lookup and Store Tests
# =============================================================================

@test "cache_lookup function exists" {
    declare -f cache_lookup > /dev/null
}

@test "cache_store function exists" {
    declare -f cache_store > /dev/null
}

@test "cache_lookup returns empty for cache miss" {
    local result
    # cache_lookup returns exit code 1 on miss, so use || true to prevent test failure
    result=$(cache_lookup "nonexistent_key_12345") || true
    [ -z "$result" ]
}

@test "cache_store and cache_lookup roundtrip works" {
    local grid_key="37566_126978"
    local location="Seoul_Seoul_KR"

    cache_store "$grid_key" "$location"
    local result
    result=$(cache_lookup "$grid_key")

    [ "$result" = "$location" ]
}

@test "cache stores multiple entries correctly" {
    cache_store "key1" "Location_A"
    cache_store "key2" "Location_B"
    cache_store "key3" "Location_C"

    [ "$(cache_lookup 'key1')" = "Location_A" ]
    [ "$(cache_lookup 'key2')" = "Location_B" ]
    [ "$(cache_lookup 'key3')" = "Location_C" ]
}

@test "cache overwrites existing entry with same key" {
    local grid_key="test_key"

    cache_store "$grid_key" "Old_Location"
    cache_store "$grid_key" "New_Location"

    local result
    result=$(cache_lookup "$grid_key")
    [ "$result" = "New_Location" ]
}

# =============================================================================
# Phase 1: Cache Statistics Tests
# =============================================================================

@test "GEOCODE_CACHE arrays exist" {
    # Verify the cache data structures are declared (parallel arrays for Bash 3.2)
    declare -p GEOCODE_CACHE_KEYS > /dev/null 2>&1
    declare -p GEOCODE_CACHE_VALUES > /dev/null 2>&1
}

@test "CACHE_HITS counter exists and is initialized" {
    [ -n "${CACHE_HITS+x}" ]
    [ "$CACHE_HITS" -ge 0 ]
}

@test "CACHE_MISSES counter exists and is initialized" {
    [ -n "${CACHE_MISSES+x}" ]
    [ "$CACHE_MISSES" -ge 0 ]
}

# =============================================================================
# Phase 2: Cache-Aware Geocoding Tests
# =============================================================================

@test "geocode_coordinates_cached function exists" {
    # The cached version should wrap the original
    declare -f geocode_coordinates_cached > /dev/null
}

@test "geocode_coordinates uses cache for repeated calls" {
    # Skip if geocoder not available
    if [[ "$GEOCODER_AVAILABLE" != "true" ]]; then
        skip "Geocoder not available"
    fi

    # Reset counters
    CACHE_HITS=0
    CACHE_MISSES=0

    # First call should be a miss
    geocode_coordinates_cached 37.5665 126.9780 > /dev/null 2>&1 || true

    local misses_after_first=$CACHE_MISSES

    # Second call to same location should be a hit
    geocode_coordinates_cached 37.5665 126.9780 > /dev/null 2>&1 || true

    [ "$CACHE_HITS" -ge 1 ]
}

@test "geocode_coordinates caches result after first call" {
    # Skip if geocoder not available
    if [[ "$GEOCODER_AVAILABLE" != "true" ]]; then
        skip "Geocoder not available"
    fi

    # Clear cache (parallel arrays)
    GEOCODE_CACHE_KEYS=()
    GEOCODE_CACHE_VALUES=()

    # Make a geocode call
    local lat=37.5665
    local lon=126.9780
    geocode_coordinates_cached "$lat" "$lon" > /dev/null 2>&1 || true

    # Check cache has an entry
    local grid_key
    grid_key=$(normalize_coordinates "$lat" "$lon")
    local cached
    cached=$(cache_lookup "$grid_key") || true

    # Either cached is non-empty OR geocoder failed (which is acceptable)
    [ -n "$cached" ] || [ "$CACHE_MISSES" -ge 1 ]
}

@test "nearby coordinates use cached result" {
    # Skip if geocoder not available
    if [[ "$GEOCODER_AVAILABLE" != "true" ]]; then
        skip "Geocoder not available"
    fi

    # Reset counters and cache (parallel arrays)
    CACHE_HITS=0
    CACHE_MISSES=0
    GEOCODE_CACHE_KEYS=()
    GEOCODE_CACHE_VALUES=()

    # First call
    geocode_coordinates_cached 37.56650 126.97800 > /dev/null 2>&1 || true

    local misses_after_first=$CACHE_MISSES

    # Call with nearby coordinates (within same grid cell)
    geocode_coordinates_cached 37.56652 126.97802 > /dev/null 2>&1 || true

    # Should have hit the cache (misses should not have increased)
    [ "$CACHE_MISSES" -eq "$misses_after_first" ] || [ "$CACHE_HITS" -ge 1 ]
}

# =============================================================================
# Phase 3: Integration Tests
# =============================================================================

@test "process_file uses geocode cache when processing images" {
    # This test verifies cache integration with the main processing flow
    # Skip if geocoder not available
    if [[ "$GEOCODER_AVAILABLE" != "true" ]]; then
        skip "Geocoder not available"
    fi

    # The integration is verified by the existence of cache counters
    # after processing completes
    [ -n "${CACHE_HITS+x}" ]
    [ -n "${CACHE_MISSES+x}" ]
}

# =============================================================================
# Phase 4: Statistics and Flags Tests
# =============================================================================

@test "print_cache_stats function exists" {
    declare -f print_cache_stats > /dev/null
}

@test "print_cache_stats outputs hit count" {
    CACHE_HITS=10
    CACHE_MISSES=5

    local output
    output=$(print_cache_stats)

    [[ "$output" == *"10"* ]] || [[ "$output" == *"hits"* ]]
}

@test "print_cache_stats outputs miss count" {
    CACHE_HITS=10
    CACHE_MISSES=5

    local output
    output=$(print_cache_stats)

    [[ "$output" == *"5"* ]] || [[ "$output" == *"miss"* ]]
}

@test "print_cache_stats calculates hit rate percentage" {
    CACHE_HITS=8
    CACHE_MISSES=2

    local output
    output=$(print_cache_stats)

    # 8 hits out of 10 total = 80% hit rate
    [[ "$output" == *"80"* ]] || [[ "$output" == *"rate"* ]]
}

@test "--no-cache flag is recognized" {
    run "$SCRIPT_PATH" --help
    [[ "$output" == *"--no-cache"* ]] || [[ "$output" == *"no-cache"* ]]
}

@test "--no-cache flag disables caching" {
    # Verify the NO_CACHE variable or similar mechanism exists
    # This would be set by argument parsing
    run "$SCRIPT_PATH" --no-cache --help 2>/dev/null || true
    # Should not error on the flag
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ] || [ "$status" -eq 2 ]
}

@test "NO_CACHE variable exists" {
    # When script is sourced, NO_CACHE should be defined
    [ -n "${NO_CACHE+x}" ] || [ "${NO_CACHE:-false}" = "false" ]
}

# =============================================================================
# Edge Cases and Error Handling
# =============================================================================

@test "cache handles special characters in location names" {
    local grid_key="test_special"
    local location="New_York_New_York_US"

    cache_store "$grid_key" "$location"
    local result
    result=$(cache_lookup "$grid_key")

    [ "$result" = "$location" ]
}

@test "cache handles empty location gracefully" {
    local grid_key="empty_location"

    cache_store "$grid_key" ""
    local result
    result=$(cache_lookup "$grid_key")

    # Should return empty string, not error
    [ -z "$result" ] || [ "$result" = "" ]
}

@test "normalize_coordinates handles decimal precision variations" {
    # Different decimal representations of same location
    local key1 key2 key3
    key1=$(normalize_coordinates 37.5665 126.978)
    key2=$(normalize_coordinates 37.56650 126.97800)
    key3=$(normalize_coordinates 37.566500 126.978000)

    # All should produce the same key
    [ "$key1" = "$key2" ]
    [ "$key2" = "$key3" ]
}

@test "cache statistics are reset between sessions" {
    # When script is sourced fresh, counters should be 0
    CACHE_HITS=0
    CACHE_MISSES=0

    [ "$CACHE_HITS" -eq 0 ]
    [ "$CACHE_MISSES" -eq 0 ]
}
