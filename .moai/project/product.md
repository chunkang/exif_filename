# Product Overview

## Project Name

**exif_filename** - EXIF-Based File Renaming Utility

## Description

exif_filename is a command-line utility that automatically renames image and video files based on their EXIF metadata. The tool extracts timestamp information from photo and video files and optionally enriches filenames with GPS-derived location data, transforming disorganized media libraries into chronologically and geographically organized collections.

## Target Audience

### Primary Users

- **Photographers**: Professional and amateur photographers who need to organize large photo libraries from multiple cameras and devices
- **Digital Asset Managers**: Professionals responsible for maintaining organized media archives for organizations
- **Power Users**: Tech-savvy individuals who want automated, consistent file naming across their personal media collections

### Use Case Scenarios

- Consolidating photos from multiple devices (phones, cameras, drones) into a unified naming scheme
- Preparing media for archival storage with human-readable, sortable filenames
- Organizing vacation photos with automatic location tagging
- Building searchable media libraries where filenames indicate when and where photos were taken

## Core Features

### Timestamp Extraction

- Extracts EXIF DateTimeOriginal metadata from supported file types
- Intelligent fallback to file creation or modification timestamps when EXIF data is unavailable
- Consistent output format: `YYYY_MM_DD_HHhMMmSSs`

### GPS Location Integration

- Extracts GPS coordinates from EXIF metadata
- Performs reverse geocoding to convert coordinates to human-readable locations
- Appends city, state, and country information to filenames
- Output format with location: `YYYY_MM_DD_HHhMMmSSs_City_State_Country`

### Intelligent File Handling

- Recursive directory scanning for batch processing
- Automatic duplicate filename resolution with counter suffixes
- Skip files already in target format (configurable with force mode)
- Preserves original file extensions

### Cross-Platform Compatibility

- Full support for macOS and Linux environments
- Automatic dependency installation for both platforms
- Consistent behavior across operating systems

## Supported File Types

### Images

| Format | Extensions | GPS Support |
|--------|------------|-------------|
| JPEG | jpg, jpeg | Yes |
| PNG | png | Yes |
| TIFF | tiff, tif | Yes |
| RAW (Generic) | raw | Yes |
| Canon RAW | cr2, cr3 | Yes |
| Nikon RAW | nef | Yes |
| Sony RAW | arw, sr2 | Yes |
| Panasonic RAW | rw2 | Yes |
| Olympus RAW | orf | Yes |
| Fujifilm RAW | raf | Yes |
| Adobe DNG | dng | Yes |
| HEIC | heic | Yes |

### Videos

| Format | Extensions | GPS Support |
|--------|------------|-------------|
| QuickTime | mov | No |
| MPEG-4 | mp4 | No |

## Value Proposition

### Problem Solved

Media files from different devices use inconsistent naming conventions (IMG_1234.jpg, DSC_0001.jpg, 20240315_143045.jpg), making it difficult to:
- Sort files chronologically across multiple sources
- Identify when and where photos were taken from filenames
- Maintain organized archives over time

### Solution Provided

exif_filename transforms chaotic media collections into well-organized libraries with:
- **Chronological sorting**: Standardized timestamp format enables natural sorting
- **Location context**: Optional geographic information directly in filenames
- **Batch processing**: Process entire directories recursively with a single command
- **Zero data loss**: Original metadata preserved; only filenames change

### Key Benefits

1. **Time Savings**: Automate hours of manual file renaming work
2. **Consistency**: Uniform naming convention across all media files
3. **Searchability**: Find photos by date directly from file browser
4. **Portability**: Location information travels with the file, not dependent on database
5. **Simplicity**: Single command operation with sensible defaults

## Examples

### Before and After

| Original Filename | Renamed Filename |
|-------------------|------------------|
| IMG_4521.jpg | 2024_03_15_14h30m45s.jpg |
| DSC_0001.NEF | 2024_03_15_14h30m45s.nef |
| 20240315_143045.HEIC | 2024_03_15_14h30m45s_Seoul_Seoul_KR.heic |
| MVI_1234.MOV | 2024_03_15_14h35m12s.mov |

### Command Examples

```bash
# Basic usage - process current directory
./exif_filename.sh

# Process a specific folder
./exif_filename.sh ~/Pictures/vacation

# Force re-process all files (including already renamed)
./exif_filename.sh -f ~/Pictures

# Force process current directory
./exif_filename.sh --force
```

## Project Status

**Current Status**: Implementation complete

The project has been fully implemented following SPEC-EXIF-001 specifications:

- **Main script**: `exif_filename.sh` (729 lines of code)
- **Test suite**: 82 tests across 6 test files using bats-core
- **GPS geocoding**: Gazetteer (primary) with reverse_geocoder (fallback)
- **Quality**: TRUST 5 validated, ShellCheck clean

## License

MIT License - Free for personal and commercial use.
