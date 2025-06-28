#!/bin/sh

# --- LibreELEC On-Demand Emulation Powerhouse ---
# Maintained at: https://github.com/shaw17/Kodi_Emulation
# Version 2.6 - Implemented local file parsing for increased stability.

# --- Configuration ---
KODI_USERDATA="/storage/.kodi/userdata"
KODI_ADDONS="/storage/.kodi/addons"
ROMS_PATH="/storage/roms" # ROMs will be downloaded here temporarily
AEL_DATA_PATH="$KODI_USERDATA/addon_data/plugin.program.advanced.emulator.launcher"
HELPER_SCRIPT_PATH="$AEL_DATA_PATH/launch_game.sh"

# --- Helper Functions & Core Logic ---

install_emulation_software() {
    echo "--- Checking for essential software... ---"
    
    # Install RetroArch and AEL
    if [ ! -d "$KODI_ADDONS/game.retroarch" ]; then
        echo "RetroArch not found. Installing..."
        kodi-send --action="InstallAddon(game.retroarch)" > /dev/null 2>&1
    else
        echo "RetroArch already installed."
    fi

    if [ ! -d "$KODI_ADDONS/plugin.program.advanced.emulator.launcher" ]; then
        echo "Advanced Emulator Launcher not found. Installing..."
        kodi-send --action="InstallAddon(plugin.program.advanced.emulator.launcher)" > /dev/null 2>&1
    else
        echo "Advanced Emulator Launcher already installed."
    fi
    
    echo "--- Base software check complete. ---"
    sleep 3
}

# This function creates the helper script that AEL will call
create_helper_script() {
    echo "--- Creating AEL Helper Script... ---"
    mkdir -p "$AEL_DATA_PATH"
    
    cat > "$HELPER_SCRIPT_PATH" << EOL
#!/bin/sh
# This script is called by AEL to download a game, launch it, and then clean up.

ROM_URL="\$1"
SYSTEM_ID="\$2"
ROM_NAME=\$(basename "\$ROM_URL" | sed 's/%20/ /g') # Decode spaces for display
ROMS_PATH="/storage/roms/\$SYSTEM_ID"
LOCAL_ROM_FILE="\$ROMS_PATH/\$(basename "\$ROM_URL")" # Use original filename for download

mkdir -p "\$ROMS_PATH"

# Check if the ROM is already downloaded
if [ ! -f "\$LOCAL_ROM_FILE" ]; then
    echo "Downloading \$ROM_NAME..."
    wget -q -O "\$LOCAL_ROM_FILE" "\$ROM_URL"
fi

# Launch the game with RetroArch
/storage/.kodi/addons/game.retroarch/addon.sh -L /storage/.kodi/addons/game.libretro.\$SYSTEM_ID/libretro.so "\$LOCAL_ROM_FILE"

# Clean up the downloaded ROM after playing
echo "Cleaning up \$ROM_NAME..."
rm "\$LOCAL_ROM_FILE"
EOL

    chmod +x "$HELPER_SCRIPT_PATH"
    echo "Helper script created at $HELPER_SCRIPT_PATH"
}

# This function dynamically fetches the PS1 game list and populates AEL
populate_psx_from_myrient() {
    local system_name="PlayStation (On-Demand)"
    local system_id="psx"
    local temp_html_file="/tmp/myrient_psx_page.html"
    
    echo "--- Creating launchers for $system_name ---"
    
    LAUNCHERS_FILE="$AEL_DATA_PATH/launchers.xml"
    if grep -q "<name>$system_name</name>" "$LAUNCHERS_FILE"; then
        echo "$system_name launchers already exist. Skipping."
        return
    fi

    echo "Fetching and parsing game list from Myrient... this may take a moment."
    BASE_URL="https://myrient.erista.me/files/Redump/Sony%20-%20PlayStation/"
    
    # Download the index page to a temporary local file first for stability
    wget -qO "$temp_html_file" "$BASE_URL"
    if [ ! -s "$temp_html_file" ]; then
        echo "Could not download the game list page from Myrient. Skipping."
        rm -f "$temp_html_file"
        return
    fi
    
    # A more compatible sed-based pipeline for extracting URLs from the local HTML file
    GAME_LIST=$(cat "$temp_html_file" | \
                sed -n 's/.*<a href="\([^"]*\)".*/\1/p' | \
                grep -E '\.(zip|7z|chd)$' | \
                grep -E '\((USA|En|Australia)\)' | \
                while read -r line; do echo "$BASE_URL$line"; done)
    
    # Clean up the temporary file immediately after use
    rm -f "$temp_html_file"

    if [ -z "$GAME_LIST" ]; then
        echo "Could not parse the game list for $system_name. The page format may have changed. Skipping."
        return
    fi
    
    # Create a new launcher category for this system in AEL
    launcher_id=$(date +%s%N)
    launcher_xml="    <launcher>\n        <id>$launcher_id</id>\n        <name>$system_name</name>\n        <application>$HELPER_SCRIPT_PATH</application>\n        <categoryid>a57e335e-63f5-42d6-a973-c15764d13e9a</categoryid>\n    </launcher>\n</launchers>"
    sed -i "s|</launchers>|$launcher_xml|g" "$LAUNCHERS_FILE"

    # Now add each game as a ROM for that launcher
    echo "Found games. Adding to AEL..."
    echo "$GAME_LIST" | while IFS= read -r rom_url; do
        if [ -n "$rom_url" ]; then
            rom_name=$(basename "$rom_url" | sed 's/%20/ /g' | sed -E 's/\.[^.]*$//')
            rom_id=$(date +%s%N)
            rom_xml="    <rom>\n        <id>$rom_id</id>\n        <name>$rom_name</name>\n        <rompath>$rom_url</rompath>\n        <args>&quot;$rom_url&quot; &quot;$system_id&quot;</args>\n        <launcherid>$launcher_id</launcherid>\n    </rom>\n</launchers>"
            sed -i "s|</launchers>|$rom_xml|g" "$LAUNCHERS_FILE"
        fi
    done
    echo "Finished adding PlayStation games to AEL."
}

configure_kodi_integration() {
    echo "--- Configuring On-Demand Kodi (AEL) Integration ---"
    mkdir -p "$AEL_DATA_PATH"
    LAUNCHERS_FILE="$AEL_DATA_PATH/launchers.xml"

    # Create base files if they don't exist
    if [ ! -f "$AEL_DATA_PATH/categories.xml" ]; then
        cat > "$AEL_DATA_PATH/categories.xml" << EOL
<?xml version="1.0" encoding="UTF-8" standalone="yes"?><categories><category><id>a57e335e-63f5-42d6-a973-c15764d13e9a</id><name>Retro Games</name></category></categories>
EOL
    fi
    if [ ! -f "$LAUNCHERS_FILE" ]; then
        echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><launchers></launchers>' > "$LAUNCHERS_FILE"
    fi

    # Populate the launchers for PS1
    populate_psx_from_myrient
    
    echo "AEL configuration check complete."
}


set_boot_to_games() {
    if grep -q "<startup><window>games</window></startup>" "$KODI_USERDATA/guisettings.xml"; then
        echo "Kodi is already set to boot into Games menu."
    else
        read -p "Set Kodi to boot directly into the Games menu? (y/n): " confirm < /dev/tty
        if [ "$confirm" = "y" ]; then
            echo "Backing up and modifying guisettings.xml..."
            cp "$KODI_USERDATA/guisettings.xml" "$KODI_USERDATA/guisettings.xml.bak"
            sed -i 's|<startup.*>.*</startup>|<startup><window>games</window></startup>|g' "$KODI_USERDATA/guisettings.xml"
            echo "Kodi will now boot into the Games menu after restart."
        fi
    fi
}


# --- Main Menu ---
echo "--- LibreELEC On-Demand Emulation Script ---"

while true; do
    echo
    echo "Please select an option:"
    echo "1) Full Install & Setup for PlayStation (On-Demand)"
    echo "2) Configure PS1 Launchers Only"
    echo "3) Set Boot to Games Only"
    echo "4) Exit"
    echo
    read -p "Enter your choice [1-4]: " choice < /dev/tty

    case $choice in
        1)
            install_emulation_software
            create_helper_script
            configure_kodi_integration
            set_boot_to_games
            echo "Full setup check complete! Please restart LibreELEC."
            break
            ;;
        2)
            create_helper_script
            configure_kodi_integration
            echo "Kodi integration configured!"
            break
            ;;
        3)
            set_boot_to_games
            echo "Boot setting configured!"
            break
            ;;
        4)
            echo "Exiting."
            break
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done
