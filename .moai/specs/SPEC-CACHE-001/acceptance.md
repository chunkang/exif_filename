# SPEC-CACHE-001: Acceptance Criteria

## Traceability

| Field | Value |
|-------|-------|
| SPEC ID | SPEC-CACHE-001 |
| Document | Acceptance Criteria |
| Related | spec.md, plan.md |

---

## Test Environment

- Bash 4.0+ with associative array support
- Sample EXIF images with GPS coordinates
- Mock geocoding service (for unit tests)
- Real geocoding service (for integration tests)

---

## Acceptance Criteria

### AC-001: Cache Hit for Identical Coordinates

**Priority**: High
**Requirement**: R2.1, R2.2

**Scenario**: Same coordinates processed multiple times

```gherkin
Given the geocoding cache is initialized
  And a file with GPS coordinates (35.6892, 139.6917) has been processed
  And the location "Shibuya, Tokyo" was cached for these coordinates
When a second file with identical coordinates (35.6892, 139.6917) is processed
Then the system shall return "Shibuya, Tokyo" from cache
  And no geocoding API call shall be made
  And the cache hit counter shall increment by 1
```

**Verification Method**:
- Process two files with identical coordinates
- Verify only one API call is made
- Check cache hit counter equals 1

---

### AC-002: Cache Hit for Coordinates Within 50m

**Priority**: High
**Requirement**: R2.2, R3.1

**Scenario**: Nearby coordinates within same grid cell

```gherkin
Given the geocoding cache is initialized
  And a file with GPS coordinates (35.6892, 139.6917) has been processed
  And the location "Shibuya, Tokyo" was cached
When a second file with coordinates (35.6894, 139.6918) is processed
  And these coordinates are within 50 meters of the cached location
  And these coordinates fall within the same 0.0005-degree grid cell
Then the system shall return "Shibuya, Tokyo" from cache
  And no geocoding API call shall be made
```

**Verification Method**:
- Calculate grid cells for both coordinate pairs
- Verify same grid cell key is generated
- Confirm single API call for multiple files

**Test Data**:
| Coordinate 1 | Coordinate 2 | Distance | Same Grid |
|--------------|--------------|----------|-----------|
| 35.6892, 139.6917 | 35.6894, 139.6918 | ~25m | Yes |
| 35.6890, 139.6915 | 35.6893, 139.6918 | ~45m | Yes |

---

### AC-003: Cache Miss for Coordinates Beyond 50m

**Priority**: High
**Requirement**: R2.3

**Scenario**: Distant coordinates requiring separate geocoding

```gherkin
Given the geocoding cache is initialized
  And a file with GPS coordinates (35.6892, 139.6917) has been processed
  And the location "Shibuya, Tokyo" was cached
When a second file with coordinates (35.6900, 139.6925) is processed
  And these coordinates are beyond 50 meters from the cached location
  And these coordinates fall in a different grid cell
Then the system shall make a new geocoding API call
  And the cache miss counter shall increment by 1
  And the new result shall be stored in cache
```

**Verification Method**:
- Process files with coordinates in different grid cells
- Verify separate API calls are made
- Check both locations are cached independently

**Test Data**:
| Coordinate 1 | Coordinate 2 | Distance | Same Grid |
|--------------|--------------|----------|-----------|
| 35.6892, 139.6917 | 35.6900, 139.6925 | ~100m | No |
| 35.6890, 139.6915 | 35.6920, 139.6950 | ~400m | No |

---

### AC-004: Performance Improvement Verification

**Priority**: Medium
**Requirement**: R2.4

**Scenario**: Batch processing with clustered photos

```gherkin
Given a directory containing 10 photo files
  And all files have GPS coordinates within 50m of each other
  And all coordinates map to the same grid cell
When the directory is processed
Then only 1 geocoding API call shall be made
  And all 10 files shall receive the same location name
  And cache statistics shall show 9 hits and 1 miss
  And processing time shall be reduced compared to non-cached processing
```

**Verification Method**:
- Create test directory with 10 photos at same location
- Count actual API calls made
- Verify cache statistics
- Measure processing time improvement

**Expected Results**:
| Metric | Without Cache | With Cache | Improvement |
|--------|---------------|------------|-------------|
| API Calls | 10 | 1 | 90% reduction |
| Processing Time | ~10s | ~2s | ~80% faster |

---

### AC-005: Memory Overhead Constraint

**Priority**: Medium
**Requirement**: R4.3

**Scenario**: Large batch processing memory usage

```gherkin
Given the geocoding cache is initialized
When 1000 unique grid cells are cached
  And each cache entry contains a location string up to 100 characters
Then the total memory overhead shall be less than 1MB
  And the system shall continue to operate normally
  And no memory warnings shall be displayed
```

**Verification Method**:
- Populate cache with 1000 entries
- Measure memory consumption
- Verify under 1MB threshold

**Memory Calculation**:
```
Per entry: ~150 bytes (key + value + overhead)
1000 entries: ~150KB
Safety margin: 500KB for counters and structures
Total: <1MB
```

---

### AC-006: Two-Pass Directory Processing

**Priority**: Medium
**Requirement**: R2.4

**Scenario**: Optimized batch processing

```gherkin
Given a directory containing 20 photo files
  And the files map to 5 unique grid cells
  And some files share the same grid cell
When the directory is processed with two-pass mode
Then Pass 1 shall collect all coordinates without geocoding
  And Pass 1 shall identify 5 unique grid cells
  And Pass 2 shall make exactly 5 geocoding API calls
  And all 20 files shall be renamed correctly
```

**Verification Method**:
- Create test directory with known coordinate distribution
- Trace two-pass execution
- Count API calls
- Verify all files processed correctly

---

### AC-007: Cache Statistics Display

**Priority**: Low
**Requirement**: R5.1

**Scenario**: Statistics output after batch processing

```gherkin
Given the geocoding cache is initialized
  And a directory with multiple files is processed
When processing completes
Then cache statistics shall be displayed
  And statistics shall include total cache hits
  And statistics shall include total cache misses
  And statistics shall include hit rate percentage
```

**Expected Output Format**:
```
Geocoding Cache Statistics:
  Cache Hits:   15
  Cache Misses: 3
  Hit Rate:     83.3%
```

---

### AC-008: No-Cache Flag Operation

**Priority**: Low
**Requirement**: R5.2

**Scenario**: Disable caching for debugging

```gherkin
Given the --no-cache flag is provided
When files are processed
Then no cache operations shall occur
  And every file shall trigger a geocoding API call
  And no cache statistics shall be displayed
```

**Verification Method**:
- Process files with --no-cache flag
- Verify API call count matches file count
- Confirm cache structures remain empty

---

## Quality Gates

### Functional Quality

- [ ] All 8 acceptance criteria passing
- [ ] No regression in existing EXIF renaming functionality
- [ ] Cache correctly handles edge cases (empty coords, invalid data)

### Performance Quality

- [ ] Cache lookup completes in <1ms
- [ ] Memory overhead <1MB for typical usage
- [ ] 50%+ reduction in API calls for clustered photos

### Code Quality

- [ ] Functions follow existing code style
- [ ] Comments explain cache algorithm
- [ ] Error handling for cache failures

---

## Test Scenarios Summary

| ID | Scenario | Priority | Status |
|----|----------|----------|--------|
| AC-001 | Identical coordinates cache hit | High | Pending |
| AC-002 | 50m proximity cache hit | High | Pending |
| AC-003 | Beyond 50m cache miss | High | Pending |
| AC-004 | Performance improvement | Medium | Pending |
| AC-005 | Memory constraint | Medium | Pending |
| AC-006 | Two-pass processing | Medium | Pending |
| AC-007 | Statistics display | Low | Pending |
| AC-008 | No-cache flag | Low | Pending |

---

## Definition of Done

- [ ] All High priority acceptance criteria passing
- [ ] All Medium priority acceptance criteria passing
- [ ] Code review completed
- [ ] Documentation updated
- [ ] No performance regression
- [ ] Memory usage verified under limit
