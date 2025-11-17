#!/bin/bash

BACKUP_DIR="$HOME/.local/.backup" # Ordner, wo die Backups erstellt wird

SOURCE_DIRS=("$HOME/.config/") # Ordnern, die gebackup werden

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")  # Zeitformat: YYYYmmdd_HHMMSS
BACKUP_LOG="$BACKUP_DIR/backup.log" # Datei für Logs
CHECKSUM="$BACKUP_DIR/checksum.txt" # Datei, wo die Datei gehash wird, um Änderungen vom Datei zu erkennen

for FOLDER in ${SOURCE_DIRS[@]}; do
  FILES=$(find "$FOLDER" -type f) # Alle Dateien in einer Ordner, die gebackup werden
done

option=''

logging() {
  echo "$1" | sed "s/^/[$(date '+%Y-%m-%d %H:%M:%S')] /" >>$BACKUP_LOG # Logge es in einer Datei
  echo "$1"                                                            # Zeige es in den UI
}

modify_file_changes() {
  if [[ -e $CHECKSUM ]] && [[ $1 == 1 ]]; then # Wenn der erste Parameter eine 1 enthält und diese Datei existiert, lösche die Datei
    rm $CHECKSUM
  fi
  for file in ${FILES[@]}; do
    echo "$(sha256sum $file)" >>$CHECKSUM # Hashes erstellen und in den Hash-Datei hinzufügen
  done
}

create_backup() {
  logging '[*]  Backup wird erstellt'
  mkdir -p $BACKUP_DIR                                                                           # 1. Erstelle eine Backup Ordner, falls es nicht existiert
  tar -cJpPf "$BACKUP_DIR/backup_$TIMESTAMP.tar.xz" ${FILES[@]}                                  # 2. Erstelle eine Backup in den Backup Ordner
  logging "[OK] Backup erfolgreich erstellt: $BACKUP_DIR/backup_$TIMESTAMP.tar.xz" >>$BACKUP_LOG # 3. Logge diese Nachricht
  modify_file_changes 1                                                                          # 4. Erstelle eine neue Hash-Datei
}

look_for_file_changes() {
  check=0
  if ! [[ -e "$CHECKSUM" ]]; then                                        # Wenn ein Hash-Datei nicht existiert, erstelle eine neue Hash-Datei
    logging "[!]  Datei für die Erkennung von Änderung wird erstellt..." # Logge es auch
    modify_file_changes
  else # Schauen, ob alle Dateien Up-To-Date sind
    logging "[*]  Nach gelöschten/veränderten Datei suchen..."
    if sha256sum -c $CHECKSUM &>/dev/null; then # die mit den Hash-Datei vergleicht
      logging "[OK] Alle Dateien im Backup sind auf den neuesten Stand!"
    else # Wenn nicht alle Dateien Up-To-Date sind
      logging "$(sha256sum -c $CHECKSUM | grep -E 'FAILED|No such file')"
    fi
    logging '[*]  Suche nach neuen Dateien'
    for FILE in ${FILES[@]}; do
      if ! grep -q "$FILE$" $CHECKSUM; then
        logging "[!]  '$FILE' ist neu"
        check=1
      fi
    done
    if [[ $check == 0 ]]; then
      logging "[OK] Es gibt keine neuen Dateien"
    fi
  fi
}

# Selbsterklärend
echo "Backup erstellen"
while [[ "$option" != 'exit' ]]; do
  echo
  echo "create - Erstelle eine Backup"
  echo "check  - Suche nach Veränderung"
  echo "exit   - Schließe dieses Programm"
  echo
  read -p "Option: " option

  if [[ "$option" == 'create' ]]; then
    create_backup # Nutze Funktion 'create_backup'
  elif [[ "$option" == 'check' ]]; then
    look_for_file_changes # Nutze Funktion 'look_for_file_changes'
  elif [[ "$option" == 'exit' ]]; then
    : # Mach nichts
  else
    echo 'Das ist keine Option'
  fi

done
