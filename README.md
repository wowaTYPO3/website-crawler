# Website Crawler Skript

## Beschreibung
Dieses Bash-Skript dient dazu, den Textinhalt von Webseiten rekursiv zu crawlen und in einer Textdatei zu speichern. Es fragt den Benutzer nach einer URL und einer maximalen Tiefe für das Crawling, lädt dann die Webseite und alle verbundenen Seiten bis zur angegebenen Tiefe herunter und konvertiert den Inhalt in reinen Text.

## Funktionsweise
- Das Skript fragt interaktiv nach der URL der zu crawlenden Webseite und der maximalen Crawling-Tiefe.
- Es lädt alle Seiten der angegebenen Domain bis zur festgelegten Tiefe herunter.
- Der reine Textinhalt dieser Seiten wird extrahiert und in einer Textdatei gespeichert.
- Die erzeugte Textdatei enthält den Namen der Domain und das aktuelle Datum.
- Nach dem Crawlen und Extrahieren der Inhalte wird das Verzeichnis mit den heruntergeladenen HTML-Dateien gelöscht.

## Voraussetzungen
Um das Skript auf einem Mac zu verwenden, sind folgende Schritte erforderlich:

1. **Installieren von Homebrew**:
   - Öffne das Terminal und führe `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` aus, um Homebrew zu installieren.

2. **Installieren von Wget**:
   - Nach der Installation von Homebrew gib `brew install wget` ein, um Wget zu installieren.

3. **Installieren von Pandoc**:
   - Führe `brew install pandoc` aus, um Pandoc zu installieren. Pandoc wird benötigt, um HTML-Inhalte in reinen Text zu konvertieren.

## Verwendung
1. **Klonen des Repositorys**:
   - Verwende `git clone [Repository-URL]`, um das Repository zu klonen, das dieses Skript enthält.

2. **Ausführen des Skripts**:
   - Öffne das Terminal und navigiere zum Verzeichnis des Skripts.
   - Gib `chmod +x website_crawler.sh` ein, um das Skript ausführbar zu machen.
   - Starte das Skript mit `./website_crawler.sh`.
   - Folge den Anweisungen im Terminal, um die URL und die maximale Crawling-Tiefe einzugeben.

## Hinweis
- Stelle sicher, dass du die Erlaubnis hast, den Inhalt der Ziel-Webseite zu crawlen.
- Beachte die Datei `robots.txt` der Ziel-Webseite, die Anweisungen zum Crawlen enthält.
