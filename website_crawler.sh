#!/bin/bash

# --- Funktion: Prüfe, ob ein bestimmtes Programm installiert ist ---
function check_command() {
  command -v "$1" &>/dev/null
}

# --- Funktion: Abfrage von URL-Ausschlüssen ---
function get_url_exclusions() {
  local exclusions=()
  echo ""
  echo "Möchten Sie bestimmte URL-Segmente vom Crawling ausschließen? (z.B. /en/, /fr/, /admin/)"
  echo "Diese Funktion ist nützlich, um Sprachversionen oder bestimmte Bereiche zu ignorieren."
  echo ""

  while true; do
    read -p "URL-Segment zum Ausschließen eingeben (leer lassen zum Beenden): " segment

    # Wenn leer, beende die Schleife
    if [[ -z "$segment" ]]; then
      break
    fi

    # Normalisiere das Segment (füge führende und nachgestellte Slashes hinzu, falls nötig)
    if [[ ! "$segment" =~ ^/ ]]; then
      segment="/$segment"
    fi
    if [[ ! "$segment" =~ /$ ]]; then
      segment="$segment/"
    fi

    exclusions+=("$segment")
    echo "Hinzugefügt: $segment"
  done

  # Zeige zusammengefasste Ausschlüsse an
  if [[ ${#exclusions[@]} -gt 0 ]]; then
    echo ""
    echo "Folgende URL-Segmente werden ausgeschlossen:"
    for exclusion in "${exclusions[@]}"; do
      echo "  - $exclusion"
    done
    echo ""
  fi

  # Exportiere als globale Variable
  URL_EXCLUSIONS=("${exclusions[@]}")
}

# --- Funktion: Prüfe, ob URL ausgeschlossen werden soll ---
function is_url_excluded() {
  local url=$1

  # Wenn keine Ausschlüsse definiert sind, ist nichts ausgeschlossen
  if [[ ${#URL_EXCLUSIONS[@]} -eq 0 ]]; then
    return 1
  fi

  # Prüfe jedes Ausschlussmuster
  for exclusion in "${URL_EXCLUSIONS[@]}"; do
    if [[ "$url" == *"$exclusion"* ]]; then
      return 0  # URL ist ausgeschlossen
    fi
  done

  return 1  # URL ist nicht ausgeschlossen
}

# --- Funktion: Erstelle Reject-Regex für wget ---
function build_reject_regex() {
  if [[ ${#URL_EXCLUSIONS[@]} -eq 0 ]]; then
    return
  fi

  local regex_parts=()
  for exclusion in "${URL_EXCLUSIONS[@]}"; do
    # Escape spezielle Regex-Zeichen
    local escaped_exclusion=$(echo "$exclusion" | sed 's/[.*+?^${}()|[\]\\]/\\&/g')
    regex_parts+=("$escaped_exclusion")
  done

  # Kombiniere alle Teile mit OR-Operator
  EXCLUSION_REGEX=$(IFS="|"; echo "${regex_parts[*]}")
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

# --- Funktion: Rekonstruiere ursprüngliche URL aus Dateipfad ---
function reconstruct_url() {
  local file=$1
  local download_dir=$2

  # Entferne Download-Verzeichnis-Präfix
  local relative_path=${file#$download_dir/}

  # Behandle spezielle Fälle
  case "$relative_path" in
    */index.html)
      # index.html -> Verzeichnis-URL
      relative_path=${relative_path%/index.html}
      ;;
    *.html)
      # Entferne .html-Endung
      relative_path=${relative_path%.html}
      ;;
  esac

  # Konstruiere vollständige URL
  if [[ $relative_path == */* ]]; then
    echo "https://$relative_path"
  else
    echo "https://$relative_path/"
  fi
}

# --- Funktion: Verarbeite eine einzelne HTML-Datei mit strukturierter Ausgabe ---
function process_html_file_structured() {
  local file=$1
  local output_file=$2
  local download_dir=$3

  # Rekonstruiere die ursprüngliche URL
  local original_url=$(reconstruct_url "$file" "$download_dir")

  # Prüfe, ob URL ausgeschlossen werden soll
  if is_url_excluded "$original_url"; then
    echo "Überspringe ausgeschlossene URL: $original_url"
    return 0
  fi

  # Schreibe strukturierte Header mit Thread-Safety
  local temp_file=$(mktemp)
  {
    echo "###"
    echo "$original_url"
    echo ""

    # Konvertiere HTML zu Text
    if pandoc -s -f html -t plain "$file" 2>/dev/null; then
      echo ""
    else
      echo "Fehler bei der Konvertierung dieser Seite"
      echo ""
    fi

    echo "###"
    echo ""
  } > "$temp_file"

  # Füge sicher zur Hauptdatei hinzu (Thread-safe)
  cat "$temp_file" >> "$output_file"
  rm "$temp_file"
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
read -p "Nur diese URL crawlen (ohne Links zu folgen)? (j/n, Standard: n): " crawl_single
if [[ "$crawl_single" =~ ^[jJ]$ ]]; then
  MAX_DEPTH=0
  RECURSIVE_MODE=false
  echo "Modus: Nur einzelne URL wird gecrawlt"
else
  read -p "Gib die maximale Tiefe ein (Standard: $MAX_DEPTH): " user_depth
  MAX_DEPTH=${user_depth:-$MAX_DEPTH}
  RECURSIVE_MODE=true
fi

# --- URL-Ausschlüsse abfragen ---
get_url_exclusions

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

# --- Lade robots.txt ---
load_robots_txt "$base_domain"

# --- Starte den Download ---
echo "Lade Inhalte herunter..."

# Baue wget-Befehl auf
if [[ "$RECURSIVE_MODE" == true ]]; then
  wget_cmd="wget --recursive --level=\"$MAX_DEPTH\" --convert-links --reject=\"$REJECT_PATTERNS\" --no-parent --html-extension --restrict-file-names=windows --directory-prefix=\"$download_dir\" --user-agent=\"$USER_AGENT\" --wait=\"$WAIT_TIME\" --random-wait=\"$RANDOM_WAIT\" --timeout=\"$TIMEOUT\" --connect-timeout=\"$CONNECT_TIMEOUT\" --progress=dot:giga"
else
  # Nicht-rekursiver Modus: nur die angegebene URL herunterladen
  wget_cmd="wget --convert-links --reject=\"$REJECT_PATTERNS\" --html-extension --restrict-file-names=windows --directory-prefix=\"$download_dir\" --user-agent=\"$USER_AGENT\" --timeout=\"$TIMEOUT\" --connect-timeout=\"$CONNECT_TIMEOUT\" --progress=dot:giga"
fi

# Füge robots.txt-Regeln hinzu, falls vorhanden
if [ -f "$download_dir/robots_rules.txt" ] && [ -s "$download_dir/robots_rules.txt" ]; then
    reject_regex=$(cat "$download_dir/robots_rules.txt" | tr '\n' '|' | sed 's/|$//')
    if [ -n "$reject_regex" ]; then
        wget_cmd="$wget_cmd --reject-regex=\"$reject_regex\""
    fi
fi

# Füge URL-Ausschlüsse hinzu, falls vorhanden
build_reject_regex
if [[ -n "$EXCLUSION_REGEX" ]]; then
    if [[ "$wget_cmd" == *"--reject-regex="* ]]; then
        # Kombiniere mit bestehender Reject-Regex
        wget_cmd=$(echo "$wget_cmd" | sed "s/--reject-regex=\"\([^\"]*\)\"/--reject-regex=\"\1|$EXCLUSION_REGEX\"/")
    else
        # Füge neue Reject-Regex hinzu
        wget_cmd="$wget_cmd --reject-regex=\"$EXCLUSION_REGEX\""
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

# Erstelle Header für die Ausgabedatei
{
  echo "======================================================"
  echo "Website Crawl Ergebnisse für: $base_domain"
  echo "Erstellt am: $(date '+%Y-%m-%d %H:%M:%S')"
  if [[ "$RECURSIVE_MODE" == true ]]; then
    echo "Modus: Rekursiv (Maximale Tiefe: $MAX_DEPTH)"
  else
    echo "Modus: Einzelne URL (keine Links werden gefolgt)"
  fi
  if [[ ${#URL_EXCLUSIONS[@]} -gt 0 ]]; then
    echo "Ausgeschlossene URL-Segmente: ${URL_EXCLUSIONS[*]}"
  fi
  echo "======================================================"
  echo ""
} > "$output_file"

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

  # Starte die strukturierte Verarbeitung im Hintergrund
  process_html_file_structured "$file" "$output_file" "$download_dir" &

  # Speichere die Job-ID
  echo $! >> "$temp_jobs_file"
done

# Warte auf Abschluss aller Jobs
while read -r job_id; do
  wait "$job_id"
done < "$temp_jobs_file"

# Lösche temporäre Datei
rm -f "$temp_jobs_file"

# Füge Abschluss-Footer hinzu
{
  echo ""
  echo "======================================================"
  echo "Ende des Crawl-Ergebnisses"
  echo "Verarbeitete Dateien: $total_files"
  echo "======================================================"
} >> "$output_file"

echo -e "\nFertig. Du findest den strukturierten Textinhalt in der Datei '$output_file'."
rm -rf "$download_dir"
