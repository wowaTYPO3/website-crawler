# Website Crawler Script

## Description
This Bash script is designed to recursively crawl the text content of web pages and save it to a text file. It prompts the user for a URL and a maximum depth for crawling, then downloads the website and all linked pages up to the specified depth, converting the content into plain text.

## How It Works
- The script interactively prompts for the URL of the website to crawl and the maximum crawling depth.
- It downloads all pages of the specified domain up to the defined depth.
- The plain text content of these pages is extracted and saved to a text file.
- The generated text file includes the domain name and the current date.
- After crawling and extracting the content, the directory containing the downloaded HTML files is deleted.

## Prerequisites
The script was developed and tested on MacOS. To ensure that it works, the tools wget and pandoc must be installed.  
To use the script on a Mac, the following steps are required:

1. **Install Homebrew**:
    - Open the Terminal and run `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` to install Homebrew.

2. **Install Wget**:
    - After installing Homebrew, enter `brew install wget` to install Wget.

3. **Install Pandoc**:
    - Run `brew install pandoc` to install Pandoc. Pandoc is required to convert HTML content into plain text.

## Usage
1. **Clone the Repository**:
    - Use `git clone [Repository-URL]` to clone the repository containing this script.

2. **Run the Script**:
    - Open the Terminal and navigate to the script directory.
    - Enter `chmod +x website_crawler.sh` to make the script executable.
    - Start the script with `./website_crawler.sh`.
    - Follow the instructions in the Terminal to input the URL and the maximum crawling depth.

## Note
- Ensure you have permission to crawl the content of the target website.
- Observe the `robots.txt` file of the target website, which may contain guidelines for crawling.
