#!/bin/sh

# --- LibreELEC On-Demand Emulation Powerhouse ---
# Maintained at: https://github.com/shaw17/Kodi_Emulation
# Version 5.3 - Replaced EnableAddon command with direct database modification for reliability.

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

# --- Core Logic Functions ---

install_software() {
    echo "--- Installing Required Add-ons using Direct Placement Method---"
    
    TEMP_DIR="$KODI_USERDATA/temp"
    mkdir -p "$TEMP_DIR"
    mkdir -p "$KODI_ADDONS"

    # Install the Zach Morris repository for IAGL
    if [ ! -d "$KODI_ADDONS/repository.zachmorris" ]; then
        echo "Zach Morris Repository not found. Downloading and extracting directly..."
        REPO_URL_IAGL_REPO="https://github.com/zach-morris/repository.zachmorris/releases/download/1.0.4/repository.zachmorris-1.0.4.zip"
        ZIP_PATH_IAGL_REPO="$TEMP_DIR/iagl_repo.zip"
        
        wget -q -O "$ZIP_PATH_IAGL_REPO" "$REPO_URL_IAGL_REPO"
        if [ $? -eq 0 ]; then
            unzip -o -q "$ZIP_PATH_IAGL_REPO" -d "$KODI_ADDONS"
            echo "Zach Morris Repository extracted."
        else
            echo "ERROR: Failed to download the Zach Morris repository."
            rm -rf "$TEMP_DIR"
            return 1
        fi
    else
        echo "Zach Morris Repository already installed."
    fi

    # Install RetroArch from the Spleen1981 release page
    if [ ! -d "$KODI_ADDONS/game.retroarch" ]; then
        echo "RetroArch not found. Downloading and extracting directly..."
        REPO_URL_RA="https://github.com/spleen1981/retroarch-kodi-addon-CoreELEC/releases/download/v1.7.5/script.retroarch.launcher.Amlogic-ng.arm-v1.7.5.zip"
        ZIP_PATH_RA="$TEMP_DIR/retroarch.zip"
        
        wget -q -O "$ZIP_PATH_RA" "$REPO_URL_RA"
        if [ $? -eq 0 ]; then
            unzip -o -q "$ZIP_PATH_RA" -d "$KODI_ADDONS"
            echo "RetroArch extracted."
        else
            echo "ERROR: Failed to download the RetroArch add-on."
            rm -rf "$TEMP_DIR"
            return 1
        fi
    else
        echo "RetroArch already installed."
    fi
    
    # Install the Internet Archive Game Launcher add-on itself
    if [ ! -d "$KODI_ADDONS/plugin.program.iagl" ]; then
        echo "IAGL add-on not found. Downloading and extracting directly..."
        REPO_URL_IAGL_PLUGIN="https://github.com/zach-morris/plugin.program.iagl/releases/download/v3.1.2/plugin.program.iagl-3.1.2.zip"
        ZIP_PATH_IAGL_PLUGIN="$TEMP_DIR/iagl_plugin.zip"

        wget -q -O "$ZIP_PATH_IAGL_PLUGIN" "$REPO_URL_IAGL_PLUGIN"
        if [ $? -eq 0 ]; then
            unzip -o -q "$ZIP_PATH_IAGL_PLUGIN" -d "$KODI_ADDONS"
            echo "Internet Archive Game Launcher extracted."
        else
            echo "ERROR: Failed to download the IAGL plugin."
            rm -rf "$TEMP_DIR"
            return 1
        fi
    else
        echo "Internet Archive Game Launcher already installed."
    fi


    # Cleanup temporary download directory
    rm -rf "$TEMP_DIR"

    # Restart Kodi to make it detect the new addons
    echo "Restarting Kodi service to detect new addons..."
    systemctl restart kodi
    wait_for_kodi
    if [ $? -ne 0 ]; then return 1; fi
    
    # NEW METHOD: Directly modify the database to enable add-ons
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

    echo "--- Software installation check complete. ---"
}

configure_and_instruct() {
    echo "--- Final Configuration Steps ---"
    echo
    echo "The required software has been installed and enabled."
    echo "Now, please follow these final steps inside the Kodi interface:"
    echo
    echo "1.  START RETROARCH ONCE:"
    echo "    - Go to: Add-ons -> Game add-ons -> RetroArch"
    echo "    - Launch it once. Inside RetroArch, go to the Main Menu."
    echo "    - Select 'Online Updater'."
    echo "    - Update everything: Core Info Files, Assets, Controller Profiles, etc."
    echo "    - This is also where you can download the Cores (emulators) you need."
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
