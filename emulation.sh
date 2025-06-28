#!/bin/sh

# --- LibreELEC On-Demand Emulation Powerhouse ---
# Maintained at: https://github.com/shaw17/Kodi_Emulation
# Version 4.0 - Switched to Internet Archive Game Launcher (IAGL) method.

# --- Configuration ---
KODI_USERDATA="/storage/.kodi/userdata"
KODI_ADDONS="/storage/.kodi/addons"
IAGL_DATA_PATH="$KODI_USERDATA/addon_data/plugin.program.iagl"

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
    echo "--- Installing Required Add-ons... ---"
    
    wait_for_kodi
    if [ $? -ne 0 ]; then return 1; fi

    echo "Forcing Kodi to update its official repositories..."
    kodi-send --action="UpdateAddonRepositories" > /dev/null 2>&1
    echo "Waiting for repository update to complete (this may take a moment)..."
    sleep 20

    # Install the Zach Morris repository for IAGL
    if [ ! -d "$KODI_ADDONS/repository.zachmorris" ]; then
        echo "Zach Morris Repository not found. Installing..."
        REPO_URL="https://github.com/zach-morris/repository.zachmorris/raw/master/repository.zachmorris.zip"
        wget -q -P "$KODI_USERDATA/temp" "$REPO_URL"
        kodi-send --action="InstallAddon(repository.zachmorris)" > /dev/null 2>&1
        rm -rf "$KODI_USERDATA/temp"
        echo "Repository installed. Forcing another update..."
        kodi-send --action="UpdateAddonRepositories" > /dev/null 2>&1
        sleep 15
    else
        echo "Zach Morris Repository already installed."
    fi

    # Install IAGL from the new repository
    if [ ! -d "$KODI_ADDONS/plugin.program.iagl" ]; then
        echo "Internet Archive Game Launcher not found. Sending install command..."
        kodi-send --action="InstallAddon(plugin.program.iagl)" > /dev/null 2>&1
    else
        echo "Internet Archive Game Launcher already installed."
    fi
    
    # Install RetroArch from the official Kodi repository
    if [ ! -d "$KODI_ADDONS/game.retroarch" ]; then
        echo "RetroArch not found. Sending install command..."
        kodi-send --action="InstallAddon(game.retroarch)" > /dev/null 2>&1
    else
        echo "RetroArch already installed."
    fi

    echo "Add-on installation commands sent. Waiting for Kodi to process..."
    sleep 15
    echo "--- Software installation check complete. ---"
}

configure_and_instruct() {
    echo "--- Final Configuration Steps ---"
    echo
    echo "The required software has been installed."
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
