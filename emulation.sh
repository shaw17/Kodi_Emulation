#!/bin/sh

# --- LibreELEC On-Demand Emulation Powerhouse ---
# Maintained at: https://github.com/shaw17/Kodi_Emulation
# Version 5.7 - Automated RetroArch asset installation to prevent crashes.

# --- Configuration ---
KODI_USERDATA="/storage/.kodi/userdata"
KODI_ADDONS="/storage/.kodi/addons"
KODI_DB_FILE="$KODI_USERDATA/Database/Addons33.db" # Path to Kodi's addon database

# --- Helper Functions ---

wait_for_kodi() {
    echo "Waiting for Kodi process to be running..."
    local timeout=60
    while [ $timeout -gt 0 ]; do
        if pgrep -f "kodi.bin" >/dev/null; then
            echo "Kodi process is running. Waiting for services to start..."
            sleep 5
            return 0
        fi
        sleep 1
        timeout=$((timeout - 1))
    done
    echo "ERROR: Timed out waiting for Kodi process. Is it running?"
    return 1
}

enable_addons_in_db() {
    echo "Stopping Kodi to safely enable add-ons in the database..."
    systemctl stop kodi
    sleep 2

    if [ -f "$KODI_DB_FILE" ]; then
        echo "Enabling add-ons directly in Kodi's database..."
        sqlite3 "$KODI_DB_FILE" "UPDATE installed SET enabled=1 WHERE addonID IN ('repository.zachmorris', 'game.retroarch', 'plugin.program.iagl');"
    else
        echo "ERROR: Kodi database file not found. Cannot enable add-ons."
    fi
    
    echo "Restarting Kodi with add-ons enabled..."
    systemctl start kodi
    wait_for_kodi
}

# --- Core Logic Functions ---

install_software() {
    echo "--- Checking for Required Add-ons... ---"

    # If all components exist, just ensure they're enabled and exit the function.
    if [ -d "$KODI_ADDONS/repository.zachmorris" ] && \
       [ -d "$KODI_ADDONS/game.retroarch" ] && \
       [ -d "$KODI_ADDONS/plugin.program.iagl" ]; then
        echo "All required add-ons are already installed. Verifying they are enabled..."
        enable_addons_in_db
        echo "--- Software check complete. ---"
        return 0
    fi

    echo "One or more add-ons are missing. Starting installation process..."
    
    TEMP_DIR="$KODI_USERDATA/temp"
    mkdir -p "$TEMP_DIR"
    mkdir -p "$KODI_ADDONS"

    # Install the Zach Morris repository for IAGL
    if [ ! -d "$KODI_ADDONS/repository.zachmorris" ]; then
        echo "Zach Morris Repository not found. Downloading and extracting..."
        REPO_URL_IAGL_REPO="https://github.com/zach-morris/repository.zachmorris/releases/download/1.0.4/repository.zachmorris-1.0.4.zip"
        ZIP_PATH_IAGL_REPO="$TEMP_DIR/iagl_repo.zip"
        wget -q -O "$ZIP_PATH_IAGL_REPO" "$REPO_URL_IAGL_REPO" && unzip -o -q "$ZIP_PATH_IAGL_REPO" -d "$KODI_ADDONS" || { echo "ERROR: Failed to download or extract Zach Morris repository."; rm -rf "$TEMP_DIR"; return 1; }
        echo "Zach Morris Repository extracted."
    fi

    # Install RetroArch and its assets
    if [ ! -d "$KODI_ADDONS/game.retroarch" ]; then
        echo "RetroArch not found. Downloading and extracting..."
        REPO_URL_RA="https://github.com/spleen1981/retroarch-kodi-addon-CoreELEC/releases/download/v1.7.5/script.retroarch.launcher.Amlogic-ng.arm-v1.7.5.zip"
        ZIP_PATH_RA="$TEMP_DIR/retroarch.zip"
        wget -q -O "$ZIP_PATH_RA" "$REPO_URL_RA" && unzip -o -q "$ZIP_PATH_RA" -d "$KODI_ADDONS" || { echo "ERROR: Failed to download or extract RetroArch."; rm -rf "$TEMP_DIR"; return 1; }
        echo "RetroArch extracted."

        echo "Downloading and installing RetroArch assets to prevent crashes..."
        ASSETS_URL="http://buildbot.libretro.com/assets/frontend/assets.zip"
        ASSETS_ZIP_PATH="$TEMP_DIR/assets.zip"
        ASSETS_EXTRACT_PATH="$KODI_ADDONS/game.retroarch/resources/assets"
        mkdir -p "$ASSETS_EXTRACT_PATH"
        wget -q -O "$ASSETS_ZIP_PATH" "$ASSETS_URL" && unzip -o -q "$ASSETS_ZIP_PATH" -d "$ASSETS_EXTRACT_PATH" || { echo "ERROR: Failed to download or extract RetroArch assets."; rm -rf "$TEMP_DIR"; return 1; }
        echo "RetroArch assets installed."
    fi
    
    # Install the Internet Archive Game Launcher add-on
    if [ ! -d "$KODI_ADDONS/plugin.program.iagl" ]; then
        echo "IAGL add-on not found. Downloading and extracting..."
        # Corrected URL to latest version v4.0.4
        REPO_URL_IAGL_PLUGIN="https://github.com/zach-morris/plugin.program.iagl/releases/download/v4.04/plugin.program.iagl-4.0.4.zip"
        ZIP_PATH_IAGL_PLUGIN="$TEMP_DIR/iagl_plugin.zip"
        wget -q -O "$ZIP_PATH_IAGL_PLUGIN" "$REPO_URL_IAGL_PLUGIN" && unzip -o -q "$ZIP_PATH_IAGL_PLUGIN" -d "$KODI_ADDONS" || { echo "ERROR: Failed to download or extract IAGL plugin."; rm -rf "$TEMP_DIR"; return 1; }
        echo "Internet Archive Game Launcher extracted."
    fi

    # Cleanup temporary download directory
    rm -rf "$TEMP_DIR"

    # Restart Kodi to register new files before enabling them in the DB
    echo "Restarting Kodi to register new files..."
    systemctl restart kodi
    wait_for_kodi
    if [ $? -ne 0 ]; then
        echo "Failed to restart Kodi after extraction. Cannot proceed."
        return 1
    fi

    enable_addons_in_db
    echo "--- Software installation check complete. ---"
}

configure_and_instruct() {
    echo "--- Final Configuration Steps ---"
    echo
    echo "The required software has been installed and enabled."
    echo "RetroArch assets have been pre-installed to prevent crashes."
    echo "Now, please follow these final steps inside the Kodi interface:"
    echo
    echo "1.  (OPTIONAL) UPDATE RETROARCH CORES:"
    echo "    - Go to: Add-ons -> Game add-ons -> RetroArch"
    echo "    - Launch it. Inside RetroArch, go to the Main Menu -> 'Online Updater'."
    echo "    - You can now use the 'Core Downloader' to get any specific emulators you need."
    echo "    - When finished, select 'Quit RetroArch' to return to Kodi."
    echo
    echo "2.  CONFIGURE IAGL:"
    echo "    - Go to: Add-ons -> Program add-ons -> Internet Archive Game Launcher"
    echo "    - Open its context menu (press 'C' on a keyboard) and select 'Settings'."
    echo "    - Go to the 'External Launchers' tab."
    echo "    - Change 'Launcher Type' to 'External'."
    echo
    echo "3.  RUN THE IAGL SETUP WIZARD:"
    echo "    - In the IAGL settings, go to the 'Setup Wizard' tab."
    echo "    - Select 'Execute Setup Wizard'."
    echo "    - For 'Do you have RetroArch installed?', select YES."
    echo "    - It should auto-detect the paths. Confirm them."
    echo "    - For 'Do you have an archive.org account?', you can select NO."
    echo
    echo "4.  YOU ARE READY!"
    echo "    - You can now open the Internet Archive Game Launcher add-on to browse and play games."
    echo
}

set_boot_to_iagl() {
    IAGL_STARTUP_STRING="<startup><window>programs</window><path>plugin.program.iagl</path></startup>"
    
    if grep -q "plugin.program.iagl" "$KODI_USERDATA/guisettings.xml"; then
        echo "Kodi is already set to boot into IAGL."
    else
        read -p "Set Kodi to boot directly into the Game Launcher? (y/n): " confirm < /dev/tty
        if [ "$confirm" = "y" ]; then
            echo "Stopping Kodi service to safely modify settings..."
            systemctl stop kodi
            sleep 2

            echo "Backing up and modifying guisettings.xml..."
            cp "$KODI_USERDATA/guisettings.xml" "$KODI_USERDATA/guisettings.xml.bak"
            sed -i "s|<startup.*>.*</startup>|$IAGL_STARTUP_STRING|g" "$KODI_USERDATA/guisettings.xml"
            
            echo "Restarting Kodi service..."
            systemctl start kodi
            echo "Kodi will now boot into the Internet Archive Game Launcher."
        fi
    fi
}


# --- Main Menu ---
echo "--- LibreELEC On-Demand Emulation Script (IAGL Method) ---"

while true; do
    echo
    echo "Please select an option:"
    echo "1) Full Install & Configuration"
    echo "2) Set Boot to Game Launcher Only"
    echo "3) Exit"
    echo
    read -p "Enter your choice [1-3]: " choice < /dev/tty

    case $choice in
        1)
            install_software
            configure_and_instruct
            break
            ;;
        2)
            set_boot_to_iagl
            break
            ;;
        3)
            echo "Exiting."
            break
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done
