# SPEC-CACHE-001: Implementation Plan

## Traceability

| Field | Value |
|-------|-------|
| SPEC ID | SPEC-CACHE-001 |
| Document | Implementation Plan |
| Related | spec.md, acceptance.md |

---

## Overview

Implement a session-based geocoding cache with proximity detection to reduce redundant API calls when processing photos taken at similar locations.

---

## Implementation Phases

### Phase 1: Cache Infrastructure (Primary Goal)

**Objective**: Establish core caching mechanism with grid-based coordinate normalization.

**Tasks**:

1. **T1.1**: Add cache initialization function
   - Create `init_geocode_cache()` function
   - Declare associative array `GEOCODE_CACHE`
   - Initialize hit/miss counters
   - Call from script initialization section

2. **T1.2**: Implement coordinate normalization
   - Create `normalize_coordinates()` function
   - Input: latitude, longitude (decimal degrees)
   - Output: normalized grid key "lat,lon"
   - Grid size: 0.0005 degrees (~55m cells)

3. **T1.3**: Create cache lookup/store functions
   - `cache_lookup()`: Check if grid key exists
   - `cache_store()`: Store geocoding result
   - Return cached value or empty string

**Success Criteria**:
- Cache structures initialize without errors
- Coordinate normalization produces consistent keys
- Cache operations complete in <1ms

---

### Phase 2: Cache-Aware Geocoding (Primary Goal)

**Objective**: Integrate cache with existing geocoding function.

**Tasks**:

1. **T2.1**: Wrap `geocode_coordinates()` with cache layer
   - Check cache before calling Python geocoder
   - Store new results after successful geocoding
   - Increment hit/miss counters appropriately

2. **T2.2**: Update `process_file()` function
   - Pass raw coordinates to cache-aware geocoder
   - Handle cache hit path (skip Python call)
   - Handle cache miss path (existing behavior)

3. **T2.3**: Add cache statistics output
   - Display hits/misses at end of processing
   - Calculate and show hit rate percentage
   - Only show when processing multiple files

**Success Criteria**:
- Identical coordinates return cached result
- Cache misses trigger normal geocoding
- Statistics accurately reflect cache behavior

---

### Phase 3: Two-Pass Directory Processing (Secondary Goal)

**Objective**: Optimize batch processing with coordinate pre-collection.

**Tasks**:

1. **T3.1**: Modify `process_directory()` for two-pass approach
   - Pass 1: Collect coordinates from all files
   - Build unique grid cell set
   - Pass 2: Geocode unique cells, apply results

2. **T3.2**: Implement coordinate collection pass
   - Extract GPS without full file processing
   - Store file-to-grid-cell mapping
   - Identify unique grid cells needing geocoding

3. **T3.3**: Implement geocoding and application pass
   - Batch geocode unique grid cells
   - Apply cached results to mapped files
   - Complete remaining file processing

**Success Criteria**:
- Two-pass reduces total geocoding calls
- File processing order preserved
- No functional regression in output

---

### Phase 4: Edge Cases and Optimization (Final Goal)

**Objective**: Handle edge cases and optimize performance.

**Tasks**:

1. **T4.1**: Handle grid boundary edge cases
   - Consider coordinates near grid cell edges
   - Implement tolerance for boundary proximity
   - Test with coordinates at cell boundaries

2. **T4.2**: Add memory management
   - Implement cache size monitoring
   - Add safeguard for excessive entries (>10000)
   - Ensure <1MB memory footprint

3. **T4.3**: Add debug/disable flag
   - `--no-cache` flag to bypass caching
   - Useful for debugging and testing
   - Document in help text

**Success Criteria**:
- Edge cases handled gracefully
- Memory usage stays under limit
- Debug flag works correctly

---

## Technical Approach

### Algorithm: Grid-Based Proximity Detection

```
50 meters ≈ 0.00045 degrees at equator
Using 0.0005 degree grid cells (~55m) provides:
- Sufficient coverage for 50m proximity requirement
- Simple integer-based grid calculation
- Efficient hash key generation

Coordinate Normalization:
  normalized_lat = floor(lat / 0.0005) * 0.0005
  normalized_lon = floor(lon / 0.0005) * 0.0005

Example:
  Input:  35.6892, 139.6917 (Tokyo)
  Grid:   35.6890, 139.6915
  Key:    "35.6890,139.6915"
```

### Data Flow

```
File → EXIF Extract → GPS Coords → Normalize → Cache Check
                                                    ↓
                                         [Hit] → Use Cached
                                         [Miss] → Geocode → Store → Use Result
```

### Integration Strategy

1. **Minimal Disruption**: Wrap existing functions rather than rewrite
2. **Backward Compatible**: Single file processing unchanged
3. **Progressive Enhancement**: Two-pass only for directory mode
4. **Graceful Degradation**: Cache failures fall back to direct geocoding

---

## Architecture Design

### New Functions

| Function | Purpose | Location |
|----------|---------|----------|
| `init_geocode_cache()` | Initialize cache structures | After global variables |
| `normalize_coordinates()` | Grid cell calculation | Before `geocode_coordinates()` |
| `cache_lookup()` | Check cache for result | Helper function |
| `cache_store()` | Store geocoding result | Helper function |
| `print_cache_stats()` | Display statistics | End of processing |

### Modified Functions

| Function | Change Type | Description |
|----------|-------------|-------------|
| `geocode_coordinates()` | Enhancement | Add cache check/store |
| `process_file()` | Minor | Use cache-aware geocoder |
| `process_directory()` | Major | Two-pass processing |

### Data Structures

```bash
# Global cache (session-scoped)
declare -A GEOCODE_CACHE    # Key: "lat,lon" → Value: "location"
declare -i CACHE_HITS=0      # Counter for cache hits
declare -i CACHE_MISSES=0    # Counter for cache misses

# File-to-grid mapping (directory processing)
declare -A FILE_GRID_MAP    # Key: "filepath" → Value: "lat,lon"
declare -A UNIQUE_GRIDS     # Set of unique grid cells
```

---

## Risk Mitigation

| Risk | Mitigation Strategy |
|------|---------------------|
| Grid boundary misses | Use floor() consistently, accept ~55m granularity |
| Memory overflow | Limit cache to 10000 entries, warn on overflow |
| Performance regression | Benchmark before/after, optimize hot paths |
| Coordinate precision | Validate input has 4+ decimal places |

---

## Testing Strategy

1. **Unit Tests**: Individual function testing
2. **Integration Tests**: End-to-end with sample photos
3. **Performance Tests**: Benchmark with 100+ files
4. **Regression Tests**: Ensure existing functionality preserved

---

## Definition of Done

- [ ] All phases implemented and tested
- [ ] Cache reduces geocoding calls by 50%+ for clustered photos
- [ ] Memory usage under 1MB
- [ ] No regression in existing functionality
- [ ] Documentation updated
- [ ] All acceptance criteria passing
