# SPEC-CACHE-001: Geocode Location Caching with Proximity Detection

## Metadata

| Field | Value |
|-------|-------|
| SPEC ID | SPEC-CACHE-001 |
| Title | Geocode Location Caching with Proximity Detection |
| Status | Completed |
| Priority | Medium |
| Type | Enhancement (Performance Optimization) |
| Created | 2026-01-22 |
| Related SPECs | SPEC-EXIF-001 (depends on) |
| Lifecycle Level | spec-anchored |

---

## Environment

### Current System Context

- **Primary Script**: `exif_filename.sh` (729 LOC)
- **GPS Extraction**: `extract_gps_coords()` function (lines 388-399)
- **Geocoding**: `geocode_coordinates()` function (lines 406-462)
- **Processing**: `process_file()` and `process_directory()` (lines 551-640)

### Problem Statement

Each file triggers a new Python interpreter instance for geocoding, resulting in:
- Redundant API calls for photos taken at the same location
- Unnecessary network latency and API quota consumption
- No mechanism to reuse geocoding results for nearby coordinates

### Target Environment

- Bash shell with associative array support (Bash 4.0+)
- Existing reverse geocoding via Python/geopy
- File-based processing with EXIF metadata extraction

---

## Assumptions

### Technical Assumptions

| Assumption | Confidence | Risk if Wrong |
|------------|------------|---------------|
| GPS coordinates have sufficient decimal precision (4+ decimals) | High | Grid calculation inaccuracy |
| Bash associative arrays can handle 1000+ entries efficiently | Medium | Memory overflow on large batches |
| 50 meters proximity is acceptable accuracy for location naming | High | User dissatisfaction with location names |
| Photos in same session are often within 50m of each other | High | Cache hit rate lower than expected |

### Business Assumptions

| Assumption | Confidence | Risk if Wrong |
|------------|------------|---------------|
| Users process batches of photos from same location frequently | High | Feature provides limited value |
| Reducing geocoding calls improves user experience | High | Optimization not noticeable |

---

## Requirements

### R1: Ubiquitous Requirements (Always Active)

**R1.1** The system shall maintain a session-based in-memory cache for geocoding results.

**R1.2** The system shall use a grid-based coordinate normalization with 0.0005 degree precision (~55m cells).

**R1.3** The system shall preserve all existing geocoding functionality when cache misses occur.

### R2: Event-Driven Requirements (Trigger-Response)

**R2.1** WHEN coordinates are extracted from a file THEN the system shall check the proximity cache before making a geocoding API call.

**R2.2** WHEN a cache hit occurs (coordinates within 50m of cached location) THEN the system shall reuse the cached location name.

**R2.3** WHEN a cache miss occurs THEN the system shall perform geocoding and store the result in cache.

**R2.4** WHEN processing a directory THEN the system shall use two-pass processing:
- Pass 1: Collect and normalize all coordinates
- Pass 2: Geocode unique grid cells and apply results

### R3: State-Driven Requirements (Conditional)

**R3.1** IF the cache contains a proximity match for the current coordinates THEN the geocoding API call shall be skipped.

**R3.2** IF multiple files map to the same grid cell THEN all files shall receive the same location name.

**R3.3** IF processing in single-file mode THEN session cache shall still be utilized for subsequent calls within the same shell session.

### R4: Unwanted Requirements (Prohibited)

**R4.1** The system shall NOT persist cache between different shell sessions.

**R4.2** The system shall NOT modify the geocoding API interaction format or response parsing.

**R4.3** The system shall NOT exceed 1MB memory overhead for cache storage.

### R5: Optional Requirements (Nice-to-Have)

**R5.1** Where possible, display cache statistics (hits/misses) at end of batch processing.

**R5.2** Where possible, provide a flag to disable caching for debugging purposes.

---

## Specifications

### S1: Grid-Based Coordinate Normalization

**Algorithm**: Truncate coordinates to 4 decimal places (0.0001 degree precision for lookup key)

```
Grid Cell Size: 0.0005 degrees latitude/longitude
At equator: ~55.5 meters per cell
At 45 latitude: ~39 meters per cell (longitude compressed)

Normalization Formula:
  grid_lat = floor(latitude / 0.0005) * 0.0005
  grid_lon = floor(longitude / 0.0005) * 0.0005
  cache_key = "${grid_lat},${grid_lon}"
```

### S2: Cache Data Structure

```bash
# Bash associative array
declare -A GEOCODE_CACHE
# Key: "grid_lat,grid_lon" (normalized coordinates)
# Value: "location_name" (geocoded result)

# Statistics counters
CACHE_HITS=0
CACHE_MISSES=0
```

### S3: Two-Pass Directory Processing

**Pass 1 - Coordinate Collection**:
1. Iterate through all files in directory
2. Extract GPS coordinates from each file
3. Normalize coordinates to grid cells
4. Build unique grid cell set

**Pass 2 - Geocoding and Application**:
1. For each unique grid cell, perform single geocoding call
2. Store result in cache
3. Apply cached results to all files in that grid cell

### S4: Integration Points

| Function | Modification Type | Description |
|----------|------------------|-------------|
| `geocode_coordinates()` | Wrap with cache layer | Check cache before API call |
| `process_file()` | Minor modification | Pass coordinates to cache-aware geocoder |
| `process_directory()` | Major modification | Implement two-pass processing |
| New: `normalize_coordinates()` | Add function | Grid cell calculation |
| New: `init_geocode_cache()` | Add function | Initialize cache structures |

---

## Traceability

| Requirement | Test Scenario | Acceptance Criteria |
|-------------|---------------|---------------------|
| R1.1 | AC-001 | Cache initialized at session start |
| R2.1 | AC-002 | Cache checked before geocoding |
| R2.2 | AC-002, AC-003 | Cache hit returns stored value |
| R2.3 | AC-004 | Cache miss triggers API call |
| R3.1 | AC-003 | 50m proximity detection works |
| R4.3 | AC-005 | Memory overhead under 1MB |

---

## Dependencies

- **SPEC-EXIF-001**: Core EXIF extraction and file renaming functionality
- **External**: geopy Python library for reverse geocoding
- **External**: Nominatim or other geocoding service

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Grid boundary edge cases | Medium | Low | Use overlapping grid lookup |
| Large batch memory overflow | Low | Medium | Implement cache size limit |
| Coordinate precision loss | Low | Medium | Validate precision before caching |
