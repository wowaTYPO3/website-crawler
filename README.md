# Website Crawler Script

## Description
This Bash script is designed to recursively crawl the text content of web pages and save it to a text file. It prompts the user for a URL and optionally allows setting a maximum depth for crawling. The script downloads the website and all linked pages up to the specified depth, converting the content into plain text. It features parallel processing, configurable timeouts, and progress tracking.

## Features
- Recursive website crawling with configurable depth
- Parallel processing of HTML files
- HTML to plain text conversion
- Configurable timeouts and download settings
- Progress tracking during processing
- Automatic cleanup on interruption
- Detailed error handling and reporting

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
- Downloads all pages of the specified domain up to the defined depth
- Processes HTML files in parallel for better performance
- Extracts and saves plain text content to a text file
- The generated text file includes the domain name and the current date
- Automatically cleans up temporary files after completion

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
- `USER_AGENT`: User agent for requests
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

The output file will be saved as `[domain]_[date].txt` in the configured output directory.

## Error Handling
The script includes comprehensive error handling:
- Checks for missing dependencies
- Validates input URL
- Tests website accessibility
- Performs automatic cleanup on interruption
- Provides detailed error messages

## Notes
- Ensure you have permission to crawl the content of the target website.
- Observe the `robots.txt` file of the target website, which may contain guidelines for crawling.
- The script automatically creates an output directory if it doesn't exist.
- Temporary files are automatically cleaned up, even if the script is interrupted.
