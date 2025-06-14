# Website Crawler Script

## Description

This Bash script is designed to recursively crawl the text content of web pages and save it to a structured text file. It prompts the user for a URL and optionally allows setting a maximum depth for crawling. The script downloads the website and all linked pages up to the specified depth, converting the content into plain text with clear URL separation. It features parallel processing, configurable timeouts, progress tracking, automatic robots.txt compliance, and interactive URL segment exclusion.

## Features

- Recursive website crawling with configurable depth
- **Interactive URL segment exclusion** (e.g., exclude `/en/`, `/fr/`, `/admin/` paths)
- Parallel processing of HTML files
- Structured HTML to plain text conversion with URL headers
- Clear separation of content by source URL
- Configurable timeouts and download settings
- Progress tracking during processing
- Automatic cleanup on interruption
- Detailed error handling and reporting
- Automatic robots.txt compliance
- Respects website crawling rules and restrictions
- Thread-safe parallel processing with structured output

## System Requirements

This script is designed for Unix-like systems (Linux, macOS). For Windows users, there are several options:

1. **Use Windows Subsystem for Linux (WSL)**:

   - Install WSL from the Microsoft Store
   - Follow the Linux installation instructions below
2. **Use Git Bash**:

   - Install Git for Windows which includes Git Bash
   - Follow the Linux installation instructions below
3. **Use Cygwin**:

   - Install Cygwin with the required packages
   - Follow the Linux installation instructions below

## How It Works

- The script loads configuration from `crawler_config.conf`
- It interactively prompts for the URL of the website to crawl
- Optionally allows setting a custom crawling depth (defaults to configuration value)
- **Prompts for URL segments to exclude from crawling** (useful for language versions, admin areas, etc.)
- Downloads and processes the website's robots.txt file
- Respects crawling rules specified in robots.txt
- Downloads all allowed pages of the specified domain up to the defined depth (excluding specified segments)
- Reconstructs original URLs from downloaded file paths
- Processes HTML files in parallel for better performance
- Filters out excluded URLs during processing
- Extracts and saves plain text content with structured formatting
- Each page's content is clearly separated with URL headers
- The generated text file includes the domain name and the current date
- Automatically cleans up temporary files after completion

## URL Segment Exclusion

The script now includes an interactive feature to exclude specific URL segments from crawling. This is particularly useful for:

- **Language versions**: Exclude `/en/`, `/fr/`, `/de/` to focus on a specific language
- **Admin areas**: Exclude `/admin/`, `/wp-admin/`, `/backend/`
- **User sections**: Exclude `/user/`, `/profile/`, `/account/`
- **API endpoints**: Exclude `/api/`, `/v1/`, `/rest/`
- **File directories**: Exclude `/downloads/`, `/assets/`, `/media/`

### How URL Exclusion Works:

1. After entering URL and depth, the script prompts for URL segments to exclude
2. Enter segments like `/en/`, `admin`, or `/api/v1/`
3. The script automatically normalizes segments (adds leading/trailing slashes)
4. Multiple segments can be added (press Enter with empty input to finish)
5. Exclusions are applied both during download and content processing
6. The output file header shows which segments were excluded

## Output Format

The script generates a structured text file with the following format:

```plaintext
====================================================== Website Crawl Ergebnisse für: example.com Erstellt am: 2025-06-14 15:32:10 Maximale Tiefe: 1 Ausgeschlossene URL-Segmente: /en/ /fr/ /admin/ ======================================================
### 
[https://example.com/](https://example.com/)
[Content of the main page]
### 
### 
[https://example.com/about/](https://example.com/about/)
[Content of the about page]
###
Ende des Crawl-Ergebnisses Verarbeitete Dateien: 25
======================================================

```


This structure makes it easy to:

- Identify which content belongs to which URL
- Navigate through the extracted content
- Analyze specific pages within the crawled website
- See which URL segments were excluded from the crawl

## Prerequisites

The script requires the following tools to be installed:

### For macOS:

1. **Install Homebrew**:

   - Open the Terminal and run `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` to install Homebrew.
2. **Install Wget**:

   - After installing Homebrew, enter `brew install wget` to install Wget.
3. **Install Pandoc**:

   - Run `brew install pandoc` to install Pandoc. Pandoc is required to convert HTML content into plain text.

### For Linux:

1. **Install Wget**:

   ```bash
   sudo apt-get install wget  # For Debian/Ubuntu
   sudo yum install wget      # For RHEL/CentOS
   ```
2. **Install Pandoc**:

   ```bash
   sudo apt-get install pandoc  # For Debian/Ubuntu
   sudo yum install pandoc      # For RHEL/CentOS
   ```

## Configuration

The script uses a configuration file `crawler_config.conf` for various settings:

- `TIMEOUT`: Overall download timeout (default: 30 seconds)
- `CONNECT_TIMEOUT`: Connection timeout (default: 10 seconds)
- `MAX_DEPTH`: Default crawling depth (default: 1)
- `WAIT_TIME`: Wait time between downloads (default: 1 second)
- `RANDOM_WAIT`: Random wait time (default: 1 second)
- `MAX_PARALLEL_JOBS`: Maximum number of parallel processes (default: 4)
- `USER_AGENT`: User agent for requests (used for robots.txt compliance)
- `REJECT_PATTERNS`: File types to ignore
- `OUTPUT_DIR`: Output directory (default: "output")

## Usage

1. **Clone the Repository**:

   - Use `git clone [Repository-URL]` to clone the repository containing this script.
2. **Run the Script**:

   - Open the Terminal and navigate to the script directory.
   - Enter `chmod +x website_crawler.sh` to make the script executable.
   - Start the script with `./website_crawler.sh`.
   - Enter the URL when prompted
   - Optionally enter a custom crawling depth (press Enter for default)
   - **Configure URL segment exclusions** when prompted:
     ```
     Möchten Sie bestimmte URL-Segmente vom Crawling ausschließen? (z.B. /en/, /fr/, /admin/)
     Diese Funktion ist nützlich, um Sprachversionen oder bestimmte Bereiche zu ignorieren.

     URL-Segment zum Ausschließen eingeben (leer lassen zum Beenden): /en/
     Hinzugefügt: /en/
     URL-Segment zum Ausschließen eingeben (leer lassen zum Beenden): /fr/
     Hinzugefügt: /fr/
     URL-Segment zum Ausschließen eingeben (leer lassen zum Beenden): 

     Folgende URL-Segmente werden ausgeschlossen:
       - /en/
       - /fr/
     ```

The output file will be saved as `[domain]_[date].txt` in the configured output directory with structured content formatting.

## Example Use Cases for URL Exclusion

### 1. **Multilingual Websites**

Input segments: /en/, /fr/, /es/ Result: Only crawls the default language version

### 2. **E-commerce Sites**

Input segments: /checkout/, /cart/, /account/ Result: Focuses on product and information pages

### 3. **CMS Websites**

Input segments: /wp-admin/, /admin/, /login/ Result: Excludes administrative areas

### 4. **Documentation Sites**

Input segments: /v1/, /v2/, /legacy/ Result: Focuses on current version documentation

## Error Handling

The script includes comprehensive error handling:

- Checks for missing dependencies
- Validates input URL
- Tests website accessibility
- Handles robots.txt loading failures gracefully
- Performs automatic cleanup on interruption
- Provides detailed error messages
- Thread-safe processing prevents data corruption during parallel execution
- **Validates and normalizes URL exclusion patterns**

## Technical Features

- **URL Segment Filtering**: Advanced pattern matching for excluding specific URL segments
- **Interactive Configuration**: User-friendly prompts for customizing crawl behavior
- URL Reconstruction: Automatically reconstructs original URLs from downloaded file paths
- Structured Output: Each page's content is clearly separated with URL headers
- Thread-Safe Processing: Uses temporary files to ensure data integrity during parallel processing
- Progress Tracking: Real-time progress indication during HTML file processing
- Comprehensive Logging: Detailed header and footer information in output files
- **Regex Integration**: Combines user exclusions with robots.txt rules seamlessly

## Notes

- Ensure you have permission to crawl the content of the target website.
- The script automatically reads and respects the website's robots.txt file.
- If robots.txt cannot be loaded, the script will continue with default settings.
- The script automatically creates an output directory if it doesn't exist.
- Temporary files are automatically cleaned up, even if the script is interrupted.
- The User-Agent setting in the configuration file is used for robots.txt compliance.
- The structured output format makes it easy to process the results programmatically or manually.
- **URL segment exclusions work at both download and processing levels for maximum efficiency.**
- **Exclusion patterns are case-sensitive and support partial matching within URLs.**
