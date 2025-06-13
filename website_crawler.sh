#!/bin/bash

# --- Funktion: Prüfe, ob ein bestimmtes Programm installiert ist ---
function check_command() {
  command -v "$1" &>/dev/null
}

# --- Funktion: Zeige Fortschritt an ---
function show_progress() {
  local current=$1
  local total=$2
  local percentage=$((current * 100 / total))
  echo -ne "\rFortschritt: $percentage% ($current/$total)"
}

# --- Funktion: Fehlerbehandlung ---
function handle_error() {
  local error_msg=$1
  echo "Fehler: $error_msg"
  rm -rf "$download_dir"
  exit 1
}

# --- Funktion: Lade Konfiguration ---
function load_config() {
  local config_file="crawler_config.conf"
  if [ ! -f "$config_file" ]; then
    handle_error "Konfigurationsdatei '$config_file' nicht gefunden."
  fi

  # Lade Konfiguration
  source "$config_file"

  # Erstelle Ausgabeverzeichnis
  mkdir -p "$OUTPUT_DIR" || handle_error "Konnte Ausgabeverzeichnis nicht erstellen."
}

# --- Funktion: Verarbeite eine einzelne HTML-Datei ---
function process_html_file() {
  local file=$1
  local output_file=$2
  if ! pandoc -s -f html -t plain "$file" >> "$output_file"; then
    echo "Fehler bei der Konvertierung von $file" >&2
  fi
}

# --- Funktion: Extrahiere Domain aus URL ---
function extract_domain() {
  local url=$1
  echo "$url" | awk -F/ '{print $3}'
}

# --- Funktion: Lade robots.txt ---
function load_robots_txt() {
  local domain=$1
  local robots_url="https://${domain}/robots.txt"
  local robots_file="$download_dir/robots.txt"

  echo "Lade robots.txt von $domain..."
  if ! wget --quiet --timeout="$TIMEOUT" --connect-timeout="$CONNECT_TIMEOUT" "$robots_url" -O "$robots_file"; then
    echo "Warnung: robots.txt konnte nicht geladen werden."
    return 1
  fi

  # Erstelle temporäre Datei für die Regeln
  local rules_file="$download_dir/robots_rules.txt"
  > "$rules_file"

  # Verarbeite robots.txt
  local in_user_agent=false
  while IFS= read -r line; do
    # Überspringe Kommentare und Leerzeilen
    [[ $line =~ ^#.*$ ]] && continue
    [[ -z $line ]] && continue

    # Prüfe auf User-agent
    if [[ $line =~ ^User-agent:.* ]]; then
      if [[ $line =~ ^User-agent:\ *\* ]]; then
        in_user_agent=true
      else
        in_user_agent=false
      fi
    fi

    # Wenn wir im richtigen User-agent Block sind, verarbeite Disallow-Regeln
    if [[ $in_user_agent == true ]] && [[ $line =~ ^Disallow:.* ]]; then
      local path=${line#Disallow: }
      # Entferne führende Leerzeichen
      path=$(echo "$path" | sed 's/^[[:space:]]*//')
      # Wenn der Pfad leer ist, überspringe
      [[ -z $path ]] && continue
      # Escapen Sie spezielle Zeichen für den regulären Ausdruck
      path=$(echo "$path" | sed 's/[.*+?^${}()|[]/\\&/g')
      # Füge die Regel zur Datei hinzu
      echo "$path" >> "$rules_file"
    fi
  done < "$robots_file"

  # Wenn keine Regeln gefunden wurden, lösche die Datei
  if [[ ! -s "$rules_file" ]]; then
    rm -f "$rules_file"
  fi
}

# --- Funktion: Prüfe, ob eine URL erlaubt ist ---
function is_url_allowed() {
  local url=$1
  local rules_file="$download_dir/robots_rules.txt"

  # Wenn keine Regeln existieren, ist alles erlaubt
  [[ ! -f "$rules_file" ]] && return 0

  # Extrahiere den Pfad aus der URL
  local path=$(echo "$url" | awk -F/ '{print $4"/"$5"/"$6"/"$7"/"$8"/"$9"/"$10}')

  # Prüfe jede Regel
  while IFS= read -r rule; do
    if [[ $path == *"$rule"* ]]; then
      return 1
    fi
  done < "$rules_file"

  return 0
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
  handle_error "Fehlende Tools: ${missing_tools[*]}"
fi

# --- Lade Konfiguration ---
load_config

# --- URL und Tiefe abfragen ---
read -p "Gib die URL an: " URL
read -p "Gib die maximale Tiefe ein (Standard: $MAX_DEPTH): " user_depth
MAX_DEPTH=${user_depth:-$MAX_DEPTH}

# --- URL auf Protokoll prüfen ---
if ! [[ $URL =~ ^https?:// ]]; then
  URL="http://$URL"
fi

# --- Optional: Teste Erreichbarkeit via spider ---
echo "Prüfe Erreichbarkeit der Seite..."
if ! wget --spider --quiet --timeout="$TIMEOUT" --connect-timeout="$CONNECT_TIMEOUT" "$URL"; then
  handle_error "URL scheint nicht erreichbar zu sein. Bitte überprüfe die Eingabe."
fi

# --- Basisdomain extrahieren ---
base_domain=$(extract_domain "$URL")
if [ -z "$base_domain" ]; then
  handle_error "Fehler beim Extrahieren der Domain. Bitte checke deine URL."
fi

# --- Dateiname ---
current_date=$(date +"%Y-%m-%d")
output_file="$OUTPUT_DIR/${base_domain}_${current_date}.txt"

# --- Verzeichnis für Downloads ---
download_dir="$OUTPUT_DIR/downloaded_content"
mkdir -p "$download_dir" || handle_error "Konnte Download-Verzeichnis nicht erstellen."

# --- Trap einrichten, um auch bei Abbruch aufzuräumen ---
trap "rm -rf '$download_dir'; echo 'Downloads wurden aufgeräumt.'; exit 1" INT TERM

# --- Lege die Ausgabedatei an (vorher leeren) ---
> "$output_file" || handle_error "Konnte Ausgabedatei nicht erstellen."

# --- Lade robots.txt ---
load_robots_txt "$base_domain"

# --- Starte den Download ---
echo "Lade Inhalte herunter..."

# Baue wget-Befehl auf
wget_cmd="wget --recursive --level=\"$MAX_DEPTH\" --convert-links --reject=\"$REJECT_PATTERNS\" --no-parent --html-extension --restrict-file-names=windows --directory-prefix=\"$download_dir\" --user-agent=\"$USER_AGENT\" --wait=\"$WAIT_TIME\" --random-wait=\"$RANDOM_WAIT\" --timeout=\"$TIMEOUT\" --connect-timeout=\"$CONNECT_TIMEOUT\" --progress=dot:giga"

# Füge robots.txt-Regeln hinzu, falls vorhanden
if [ -f "$download_dir/robots_rules.txt" ] && [ -s "$download_dir/robots_rules.txt" ]; then
    reject_regex=$(cat "$download_dir/robots_rules.txt" | tr '\n' '|' | sed 's/|$//')
    if [ -n "$reject_regex" ]; then
        wget_cmd="$wget_cmd --reject-regex=\"$reject_regex\""
    fi
fi

# Führe wget aus
if eval "$wget_cmd \"$URL\""; then
    echo "Download erfolgreich abgeschlossen."
else
    # Prüfe, ob trotz Exit-Code Dateien heruntergeladen wurden
    downloaded_files=$(find "$download_dir" -name "*.html" | wc -l)
    if [ "$downloaded_files" -gt 0 ]; then
        echo "Warnung: wget meldete einen Fehler, aber $downloaded_files Dateien wurden heruntergeladen."
        echo "Fahre mit der Verarbeitung fort..."
    else
        handle_error "Download fehlgeschlagen - keine Dateien heruntergeladen."
    fi
fi

# --- HTML-Dateien einsammeln und parallel verarbeiten ---
echo -e "\nVerarbeite HTML-Dateien mit pandoc..."
html_files=($(find "$download_dir" -type f -name '*.html'))
total_files=${#html_files[@]}
current_file=0

# Erstelle temporäre Datei für die Job-Verwaltung
temp_jobs_file=$(mktemp)

# Verarbeite Dateien parallel
for file in "${html_files[@]}"; do
  ((current_file++))
  show_progress $current_file $total_files

  # Starte neuen Job, wenn die maximale Anzahl erreicht ist
  while [ $(jobs -p | wc -l) -ge "$MAX_PARALLEL_JOBS" ]; do
    sleep 0.1
  done

  # Starte die Verarbeitung im Hintergrund
  process_html_file "$file" "$output_file" &

  # Speichere die Job-ID
  echo $! >> "$temp_jobs_file"
done

# Warte auf Abschluss aller Jobs
while read -r job_id; do
  wait "$job_id"
done < "$temp_jobs_file"

# Lösche temporäre Datei
rm -f "$temp_jobs_file"

echo -e "\nFertig. Du findest den Textinhalt in der Datei '$output_file'."
rm -rf "$download_dir"
