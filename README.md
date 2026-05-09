# Bambu-FolderWatch-FTPS-macOS
Scripts to upload files to Bambu Lab printers from OrcaSlicer or similar. Used in LAN mode. 

__Use at your own risk: This service was vibe-coded using AI. The owner of this repo may not be able to provide support if it does not work in your case.__

# What This Service Does

This service monitors a particular folder directory on your macOS system watching for newly saved files. When using "Export plate sliced file" or "Export all sliced file" in OrcaSlicer, save the .3mf files to that monitored folder.

Once the service detects a new file:

- It will display a pop-up message allowing you to select which Bambu printers on your network (as configured in the shell script) to upload the file to via FTPS
- Place the file in an archive folder
- Make multiple attempts to upload
- Provide a notification on failure or on successful upload

# Installation Guide

The guide explains how to install and configure the macOS FTPS folder watcher service.

The project includes:

- `ftps_upload_event.sh` — FTPS upload script
- `ftps_wrapper.c` — lightweight wrapper used by `launchd`
- `com.ftps.uploader.plist` — LaunchAgent configuration

---

# Requirements

- macOS
- Xcode Command Line Tools
- `curl` (included with macOS)

---

# 1. Install Xcode Command Line Tools

Open Terminal and run:

```bash
xcode-select --install
```

If already installed, macOS will display a message indicating that the tools are already present.

---

# 2. Create Installation Directories

Create the required directories:

```bash
mkdir -p ~/bin
```

---

# 3. Copy Files

Copy the project files into place.

## Shell Script

Copy:

```text
ftps_upload_event.sh
```

To:

```text
~/bin/ftps_upload_event.sh
```

---

## C Wrapper

Copy:

```text
ftps_wrapper.c
```

To:

```text
~/bin/ftps_wrapper.c
```

---

## LaunchAgent

Copy:

```text
com.ftps.uploader.plist
```

To:

```text
~/Library/LaunchAgents/com.ftps.uploader.plist
```

---

# 4. Edit Configuration Placeholders

Edit the following files and update any placeholders:

## In `ftps_upload_event.sh`
Set the placeholders to directories and printer information specific to your installation.
The current code is set up for 2 printers and a pop-up message appears to select either printer or both to upload the file.
In your configuration you can add additional printers or remove as needed.

Update:

```bash
WATCH_DIR="[DIRECTORY_TO_WATCH]"
ARCHIVE_DIR="[DIRECTORY_TO_WATCH]/uploaded"
```

```bash
HOST_NAMES=(
  "[FRIENDLY_NAME_PRINTER_1]"
  "[FRIENDLY_NAME_PRINTER_2]"
)
```

```bash
{\"[FRIENDLY_NAME_PRINTER_1]\", \"[FRIENDLY_NAME_PRINTER_2]\", \"Both\"}
```

```bash
case "$choice" in
  "[FRIENDLY_NAME_PRINTER_1]")
    hosts_to_use=("${HOSTS[0]}")
    ;;
  "[FRIENDLY_NAME_PRINTER_2]")
    hosts_to_use=("${HOSTS[1]}")
    ;;
  "Both")
```

---

## In `com.ftps.uploader.plist`

Update with your actual macOS username:

```xml
<string>/Users/[USERNAME]/bin/ftps_wrapper</string>
```

Update with your watch directory:

```xml
<string>[DIRECTORY_TO_WATCH]</string>
```

## In `ftps_wrapper.c`

Update with your actual macOS username:

```bash
"/Users/[USERNAME]/bin/ftps_upload_event.sh"
```

---

# 5. Compile the Wrapper

Open Terminal and run:

```bash
gcc ~/bin/ftps_wrapper.c -o ~/bin/ftps_wrapper
```

This creates the executable:

```text
~/bin/ftps_wrapper
```

---

# 6. Make Scripts Executable

Run:

```bash
chmod +x ~/bin/ftps_upload_event.sh
chmod +x ~/bin/ftps_wrapper
```

---

# 7. Load the LaunchAgent

Load the service:

```bash
launchctl load ~/Library/LaunchAgents/com.ftps.uploader.plist
```

Anytime a change is made to the script files reload this service using:

```bash
launchctl unload ~/Library/LaunchAgents/com.ftps.uploader.plist
launchctl load ~/Library/LaunchAgents/com.ftps.uploader.plist
```

---

# 8. To Verify the Service Is Running

Run:

```bash
launchctl list | grep com.ftps.uploader
```

You should see output similar to:

```text
12345    0    com.ftps.uploader
```

---

# 10. Monitor Logs

The uploader writes logs to:

```text
~/ftps_upload.log
```

View logs live:

```bash
tail -f ~/ftps_upload.log
```

---

# 11. Automatic Startup

The LaunchAgent should run automatically:

- at login
- after reboot
- in the background without opening Terminal

---

# Troubleshooting

## To Test the Automation

Create a test file in the watched folder:

__Example:__
```bash
touch ~/Documents/gcode/Bambu/test.txt
```

You should see upload activity appear in the log.

---


## Service Not Running

Reload the LaunchAgent:

```bash
launchctl unload ~/Library/LaunchAgents/com.ftps.uploader.plist
launchctl load ~/Library/LaunchAgents/com.ftps.uploader.plist
```

---

## Permission Denied

Re-run:

```bash
chmod +x ~/bin/ftps_upload_event.sh
chmod +x ~/bin/ftps_wrapper
```

---

## No Uploads Occurring

Check:

- FTPS server IP addresses
- FTPS usernames/passwords
- watched folder path
- firewall/network access

---

## View LaunchAgent Errors

Check:

```bash
cat /tmp/ftps_upload.err
```

and:

```bash
cat /tmp/ftps_upload.out
```

---

# Notes

- The service uses FTPS via `curl`
- Uploads are processed automatically in the background
- macOS notifications are generated for upload success/failure
- Multiple FTPS destinations are supported

