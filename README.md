# exif_filename

A bash script that renames image and video files based on their EXIF metadata date and GPS location information.

## Features

- Renames files using EXIF DateTimeOriginal metadata
- Falls back to file creation/modification time when EXIF data is unavailable
- Extracts GPS coordinates and converts them to city/state/country names
- **Smart geocode caching** - Reuses location names for photos within ~50m of each other
- Handles duplicate filenames automatically
- Supports both macOS and Linux
- Auto-installs dependencies (exiftool, python-gazetteer/reverse_geocoder)

## Output Format

Files are renamed to: `YYYY_MM_DD_HHhMMmSSs[_City_State_Country].extension`

Examples:
- `2024_03_15_14h30m45s.jpg`
- `2024_03_15_14h30m45s_Seoul_Seoul_KR.jpg`
- `2024_03_15_14h30m45s_1.jpg` (duplicate handling)

## Supported File Types

**Images:** jpg, jpeg, png, tiff, tif, raw, cr2, cr3, nef, arw, sr2, rw2, orf, raf, dng, heic

**Videos:** mov, mp4

**GPS extraction supported for:** jpg, jpeg, heic, arw, cr2, cr3, dng, nef, rw2, orf, sr2, raf, raw, png, tif, tiff

## Usage

```bash
./exif_filename.sh [options] [target_folder]
```

### Arguments

| Argument | Description |
|----------|-------------|
| `target_folder` | Directory to process (default: current directory) |

### Options

| Option | Description |
|--------|-------------|
| `-f`, `--force` | Force processing of all files, including those already in the target format |
| `--no-cache` | Disable geocode caching (useful for debugging) |
| `-h`, `--help` | Display usage information and exit |

### Examples

```bash
# Process current directory
./exif_filename.sh

# Process a specific folder
./exif_filename.sh ~/Pictures/vacation

# Force re-process all files
./exif_filename.sh -f ~/Pictures

# Force process current directory
./exif_filename.sh --force
```

## Dependencies

- **exiftool** - Automatically installed via Homebrew (macOS) or apt/yum/dnf/pacman (Linux)
- **Python 3.6+** - Required for GPS reverse geocoding
- **python-gazetteer** - Primary geocoding library (boundary-based, more accurate)
- **reverse_geocoder** - Fallback geocoding library when Gazetteer unavailable
- **scipy** - Required dependency for python-gazetteer

## How It Works

1. Scans the target directory recursively for supported file types
2. Skips files already matching the target format (unless `--force` is used)
3. Extracts EXIF DateTimeOriginal; falls back to file timestamps if unavailable
4. For images with GPS data, extracts coordinates and performs reverse geocoding
   - Uses grid-based caching (~55m cells) to reuse location names for nearby photos
   - Reduces API calls by up to 90% for clustered photos (vacations, events)
5. Renames files with the formatted timestamp and optional location
6. Sets file permissions to 664
7. Handles naming conflicts by appending a counter suffix
8. Displays cache statistics (hits/misses) at the end of processing

## Testing

The project includes a comprehensive test suite using [bats-core](https://github.com/bats-core/bats-core):

```bash
# Install bats-core
brew install bats-core  # macOS
# or
apt install bats       # Linux

# Run all tests
bats tests/

# Run specific test file
bats tests/test_exif_extraction.bats
```

**Test Coverage:**
- Core infrastructure (argument parsing, OS detection)
- Dependency management (exiftool, Python libraries)
- EXIF extraction (timestamps, GPS coordinates)
- File operations (renaming, duplicate handling)
- Geocode caching (coordinate normalization, cache operations)
- Edge cases (special characters, permissions)
- Integration tests (end-to-end workflows)

## License

MIT
