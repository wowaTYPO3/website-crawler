#!/bin/bash

# URL und maximale Tiefe interaktiv abfragen
read -p "Bitte geben Sie die URL ein: " URL
read -p "Bitte geben Sie die maximale Tiefe ein (Standard ist 1): " MAX_DEPTH
MAX_DEPTH=${MAX_DEPTH:-1}

# Protokoll und Schrägstriche hinzufügen, falls nicht vorhanden
if ! [[ $URL =~ ^https?:// ]]; then
    URL="http://$URL"
fi

# Basisdomain extrahieren für den Dateinamen
base_domain=$(echo "$URL" | awk -F/ '{print $3}' | sed 's/[^a-zA-Z0-9]//g')

# Überprüfen, ob die Basisdomain extrahiert wurde
if [ -z "$base_domain" ]; then
  echo "Fehler beim Extrahieren der Domain aus der URL. Bitte überprüfen Sie die URL."
  exit 1
fi

# Aktuelles Datum für den Dateinamen
current_date=$(date +"%Y-%m-%d")

# Verzeichnis für heruntergeladene Inhalte
download_dir="downloaded_content"

# Ausgabedatei
output_file="${base_domain}_${current_date}.txt"

# Verzeichnis vorbereiten
mkdir -p "$download_dir"
> "$output_file"

# Die Webseite rekursiv herunterladen
echo "Lade Webseiten herunter..."
wget --recursive --level="$MAX_DEPTH" --convert-link --reject "index.html*,*.png,*.jpg,*.jpeg,*.gif,*.css,*.js,*.pdf,*.mp4" --no-parent --html-extension --restrict-file-names=windows --directory-prefix="$download_dir" "$URL"

# Alle heruntergeladenen HTML-Dateien verarbeiten
echo "Verarbeite heruntergeladene Inhalte..."
find "$download_dir" -name '*.html' | while read file; do
  pandoc -s -f html -t plain "$file" >> "$output_file"
done

# Verzeichnis mit heruntergeladenen Inhalten löschen
rm -rf "$download_dir"

echo "Der reine Inhalt wurde in $output_file gespeichert."
