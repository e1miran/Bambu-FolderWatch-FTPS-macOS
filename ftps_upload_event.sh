#!/bin/bash

WATCH_DIR="[DIRECTORY_TO_WATCH]"
ARCHIVE_DIR="[DIRECTORY_TO_WATCH]/uploaded"

HOSTS=(
  "ftps://bblp:[PRINTER_ACCESS_CODE]@[PRINTER_IP_PRINTER_1]:990/"
  "ftps://bblp:[PRINTER_ACCESS_CODE]@[PRINTER_IP_PRINTER_2]:990/"
)

HOST_NAMES=(
  "[FRIENDLY_NAME_PRINTER_1]"
  "[FRIENDLY_NAME_PRINTER_2]"
)

LOG_FILE="$HOME/ftps_upload.log"
RETRIES=3
RETRY_DELAY=2

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$LOG_FILE"
}

upload_file() {
  local f="$1"
  local filename
  filename=$(basename "$f")

  [ -f "$f" ] || return

  # Skip hidden files (starting with .)
  [[ "$filename" == .* ]] && return

  log "EVENT: detected $filename"

  # Wait for file to finish writing
  local prev_size=-1
  while true; do
    local size
    size=$(stat -f%z "$f" 2>/dev/null) || return
    [ "$size" -eq "$prev_size" ] && break
    prev_size=$size
    sleep 1
  done

  log "File stable: $filename"

  # Prompt user for destination choice
  local choice
  choice=$(osascript -e "button returned of (display dialog \"Upload $filename to:\" buttons {\"[FRIENDLY_NAME_PRINTER_1]\", \"[FRIENDLY_NAME_PRINTER_2]\", \"Both\"} default button \"Both\")" 2>/dev/null)
  
  if [ -z "$choice" ]; then
    log "User cancelled upload for $filename"
    return
  fi

  log "User selected: $choice"

  local all_success=true
  local hosts_to_use=()

  case "$choice" in
    "[FRIENDLY_NAME_PRINTER_1]")
      hosts_to_use=("${HOSTS[0]}")
      ;;
    "[FRIENDLY_NAME_PRINTER_2]")
      hosts_to_use=("${HOSTS[1]}")
      ;;
    "Both")
      hosts_to_use=("${HOSTS[@]}")
      ;;
  esac

  for host in "${hosts_to_use[@]}"; do
    local success=false

    for ((i=1; i<=RETRIES; i++)); do
      log "Uploading $filename to $host (attempt $i)"

      if /usr/bin/curl --ftp-pasv --insecure \
        --fail --silent --show-error \
        -T "$f" "$host"; then
        log "SUCCESS: $filename -> $host"
        success=true
        break
      else
        log "FAIL: $filename -> $host (attempt $i)"
        sleep $((RETRY_DELAY * i))
      fi
    done

    $success || all_success=false
  done

  if $all_success; then
    mkdir -p "$ARCHIVE_DIR"
    
    # Add timestamp to archived filename
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local base="${filename%.*}"
    local ext="${filename##*.}"
    local archived_name="${base}_${timestamp}.${ext}"
    
    mv "$f" "$ARCHIVE_DIR/$archived_name"
    log "Archived: $archived_name"
    osascript -e "display notification \"$filename uploaded successfully\" with title \"FTPS Upload Success\"" 2>/dev/null
  else
    log "UPLOAD FAILED: $filename"
    osascript -e "display notification \"$filename had upload failures\" with title \"FTPS Upload Warning\"" 2>/dev/null
  fi
}

# Scan the watch directory for .gcode and .3mf files only, excluding hidden files and the uploaded subdirectory
while IFS= read -r -d '' f; do
  upload_file "$f"
done < <(find "$WATCH_DIR" -maxdepth 1 -type f ! -name ".*" \( -iname "*.gcode" -o -iname "*.3mf" \) -print0)