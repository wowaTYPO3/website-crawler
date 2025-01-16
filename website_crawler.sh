#!/bin/bash

# --- Funktion: Prüfe, ob ein bestimmtes Programm installiert ist ---
function check_command() {
  command -v "$1" &>/dev/null
}

# --- Wichtige Tools checken ---
missing_tools=()

if ! check_command "wget"; then
  missing_tools+=("wget")
fi

if ! check_command "pandoc"; then
  missing_tools+=("pandoc")
fi

if [ ${#missing_tools[@]} -ne 0 ]; then
  echo "Fehlende Tools: ${missing_tools[*]}"
  echo "Bitte installiere die oben genannten Befehle, bevor du fortfährst."
  exit 1
fi

# --- URL und Tiefe abfragen ---
read -p "Gib die URL an: " URL
read -p "Gib die maximale Tiefe ein (Standard: 1): " MAX_DEPTH
MAX_DEPTH=${MAX_DEPTH:-1}

# --- URL auf Protokoll prüfen ---
if ! [[ $URL =~ ^https?:// ]]; then
  URL="http://$URL"
fi

# --- Optional: Teste Erreichbarkeit via spider ---
echo "Prüfe Erreichbarkeit der Seite..."
if ! wget --spider --quiet "$URL"; then
  echo "URL scheint nicht erreichbar zu sein. Bitte überprüfe die Eingabe."
  exit 1
fi

# --- Basisdomain extrahieren ---
base_domain=$(echo "$URL" | awk -F/ '{print $3}' | sed 's/[^a-zA-Z0-9]//g')
if [ -z "$base_domain" ]; then
  echo "Fehler beim Extrahieren der Domain. Bitte checke deine URL."
  exit 1
fi

# --- Dateiname ---
current_date=$(date +"%Y-%m-%d")
output_file="${base_domain}_${current_date}.txt"

# --- Verzeichnis für Downloads ---
download_dir="downloaded_content"
mkdir -p "$download_dir"

# --- Trap einrichten, um auch bei Abbruch aufzuräumen ---
trap "rm -rf '$download_dir'; echo 'Downloads wurden aufgeräumt.'; exit 1" INT TERM

# --- Lege die Ausgabedatei an (vorher leeren) ---
> "$output_file"

# --- Starte den Download ---
echo "Lade Inhalte herunter..."
wget \
  --recursive \
  --level="$MAX_DEPTH" \
  --convert-links \
  --reject="index.html*,*.png,*.jpg,*.webp.*.jpeg,*.gif,*.css,*.js,*.pdf,*.mp4" \
  --no-parent \
  --html-extension \
  --restrict-file-names=windows \
  --directory-prefix="$download_dir" \
  --user-agent="Mozilla/5.0 (compatible; MyCustomCrawler/1.0)" \
  --wait=1 \
  --random-wait \
  "$URL"

# --- HTML-Dateien einsammeln ---
echo "Verarbeite HTML-Dateien mit pandoc..."
find "$download_dir" -type f -name '*.html' | while read file; do
  pandoc -s -f html -t plain "$file" >> "$output_file"
done

# --- Downloads löschen ---
rm -rf "$download_dir"

echo "Fertig. Du findest den Textinhalt in der Datei '$output_file'."
