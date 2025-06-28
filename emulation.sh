#!/bin/sh

# --- LibreELEC Resilient Emulation Powerhouse Script ---
# Maintained at: https://github.com/shaw17/Kodi_Emulation
# Version 1.3 - Added pre-run cleanup for temp files.

# --- Configuration ---
KODI_USERDATA="/storage/.kodi/userdata"
KODI_ADDONS="/storage/.kodi/addons"
ROMS_PATH="/storage/roms"
GAMES_DB_URL="https://raw.githubusercontent.com/shaw17/Kodi_Emulation/main/games.sh"
GAMES_DB_TEMP_FILE="/tmp/games.sh.$$"

# --- Fetch and Source the games database in real-time ---
echo "--- Fetching latest games list from GitHub... ---"

# Ensure no leftover temp file from a previous failed run exists
rm -f "$GAMES_DB_TEMP_FILE" 2>/dev/null

wget -qO "$GAMES_DB_TEMP_FILE" "$GAMES_DB_URL"
if [ $? -eq 0 ]; then
    . "$GAMES_DB_TEMP_FILE" # Use POSIX-compliant source operator
    rm "$GAMES_DB_TEMP_FILE" # Clean up after successful sourcing
else
    echo "ERROR: Failed to fetch the games list from GitHub."
    echo "Please check your internet connection and the repository status."
    rm "$GAMES_DB_TEMP_FILE" 2>/dev/null # Clean up on failure
    exit 1
fi

if [ -z "$game_packs_data" ]; then
    echo "ERROR: Games list is empty or could not be sourced correctly."
    exit 1
fi

# --- Helper Functions ---
parse_size_to_kb() {
    local size_str=$1
    local num=$(echo "$size_str" | sed -e 's/[a-zA-Z]//g' -e 's/ //g')
    local unit=$(echo "$size_str" | sed -e 's/[0-9\.]//g' -e 's/ //g' | tr '[:lower:]' '[:upper:]')
    
    local val=0
    if [ "$unit" = "GB" ]; then
        val=$(awk -v n="$num" 'BEGIN { print int(n * 1024 * 1024) }')
    elif [ "$unit" = "MB" ]; then
        val=$(awk -v n="$num" 'BEGIN { print int(n * 1024) }')
    elif [ "$unit" = "KB" ]; then
        val=$(awk -v n="$num" 'BEGIN { print int(n) }')
    fi
    echo $val
}

# --- Core Logic Functions ---

install_emulation_software() {
    echo "--- Checking for essential software... ---"
    
    if [ ! -d "$KODI_ADDONS/repository.gamestarter" ]; then
        echo "Gamestarter repository not found. Installing..."
        GAMESTARTER_REPO_URL="https://github.com/bite-your-idols/Gamestarter/raw/master/repository.gamestarter/repository.gamestarter-3.0.zip"
        wget -q -P "$KODI_ADDONS/" "$GAMESTARTER_REPO_URL"
        kodi-send --action="InstallAddon(repository.gamestarter)" > /dev/null 2>&1
    else
        echo "Gamestarter repository already installed."
    fi
    
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

download_pack() {
    local pack_string="$1"
    
    local console_name=$(echo "$pack_string" | cut -d';' -f1)
    local system_id=$(echo "$pack_string" | cut -d';' -f2)
    local download_url=$(echo "$pack_string" | cut -d';' -f3)

    if [ -d "$ROMS_PATH/$system_id" ] && [ -n "$(ls -A "$ROMS_PATH/$system_id")" ]; then
        echo "Skipping '$console_name', directory already exists and is not empty."
        return
    fi
    
    echo "Downloading and extracting '$console_name'..."
    mkdir -p "$ROMS_PATH/$system_id"
    wget -q --show-progress -O "$ROMS_PATH/temp_pack.zip" "$download_url"
    unzip -o -q "$ROMS_PATH/temp_pack.zip" -d "$ROMS_PATH/$system_id/"
    rm "$ROMS_PATH/temp_pack.zip"
    echo "'$console_name' pack installed."
}

run_game_installer() {
    echo "--- Game Pack Installer ---"
    mkdir -p "$ROMS_PATH"
    
    total_size_kb=0
    # Use a POSIX-compliant loop to calculate total size
    echo "$game_packs_data" | while IFS=';' read -r _ _ _ size_str; do
        if [ -n "$size_str" ]; then
            size_kb=$(parse_size_to_kb "$size_str")
            total_size_kb=$((total_size_kb + size_kb))
        fi
    done
    
    available_space_kb=$(df -k /storage | awk 'NR==2 {print $4}')
    
    if [ "$available_space_kb" -gt "$total_size_kb" ]; then
        read -p "Sufficient space detected to install all packs. Proceed? (y/n): " confirm
        if [ "$confirm" = "y" ]; then
            echo "$game_packs_data" | while IFS= read -r pack; do
                if [ -n "$pack" ]; then download_pack "$pack"; fi
            done
            return
        fi
    fi

    echo "Manual selection mode. Choose a pack:"
    i=1
    echo "$game_packs_data" | while IFS= read -r line; do
        if [ -n "$line" ]; then
            console_name=$(echo "$line" | cut -d';' -f1)
            size_str=$(echo "$line" | cut -d';' -f4)
            printf "%d) %s (%s)\n" "$i" "$console_name" "$size_str"
            i=$((i+1))
        fi
    done
    
    read -p "Enter number: " choice
    pack_to_download=$(echo "$game_packs_data" | sed -n "${choice}p")
    
    if [ -n "$pack_to_download" ]; then
        download_pack "$pack_to_download"
    else
        echo "Invalid selection."
    fi
}

check_for_new_packs() {
    echo "--- Checking for new/uninstalled game packs... ---"
    new_packs_found=false
    
    echo "$game_packs_data" | while IFS= read -r pack; do
        if [ -n "$pack" ]; then
            system_id=$(echo "$pack" | cut -d';' -f2)
            console_name=$(echo "$pack" | cut -d';' -f1)

            if [ ! -d "$ROMS_PATH/$system_id" ] || [ -z "$(ls -A "$ROMS_PATH/$system_id")" ]; then
                if ! $new_packs_found; then
                    echo "Uninstalled game packs from the latest list are available!"
                    new_packs_found=true
                fi
                
                # Reading input inside a pipeline requires this workaround for some shells
                printf "Install the '%s' pack? (y/n): " "$console_name"
                read -r confirm < /dev/tty
                if [ "$confirm" = "y" ]; then
                    download_pack "$pack"
                fi
            fi
        fi
    done
    
    if ! $new_packs_found; then
        echo "Your game collection is up to date with the latest games list (v$GAMES_DB_VERSION)."
    fi
}

configure_kodi_integration() {
    echo "--- Configuring Kodi (AEL) Integration ---"
    AEL_DATA_PATH="$KODI_USERDATA/addon_data/plugin.program.advanced.emulator.launcher"
    mkdir -p "$AEL_DATA_PATH"
    LAUNCHERS_FILE="$AEL_DATA_PATH/launchers.xml"

    if [ ! -f "$AEL_DATA_PATH/categories.xml" ]; then
        cat > "$AEL_DATA_PATH/categories.xml" << EOL
<?xml version="1.0" encoding="UTF-8" standalone="yes"?><categories><category><id>a57e335e-63f5-42d6-a973-c15764d13e9a</id><name>Retro Games</name></category></categories>
EOL
    fi

    if [ ! -f "$LAUNCHERS_FILE" ]; then
        echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><launchers></launchers>' > "$LAUNCHERS_FILE"
    fi

    for system_dir in "$ROMS_PATH"/*/; do
        if [ -d "$system_dir" ] && [ -n "$(ls -A "$system_dir")" ]; then
            system_id=$(basename "$system_dir")
            
            if ! grep -q "<rompath>$ROMS_PATH/$system_id/</rompath>" "$LAUNCHERS_FILE"; then
                echo "Adding AEL launcher for system: $system_id"
                system_name=$(echo "$system_id" | tr '[:lower:]' '[:upper:]')
                launcher_id=$(date +%s%N)
                launcher_xml="    <launcher>\n        <id>$launcher_id</id>\n        <name>$system_name</name>\n        <application>/storage/.kodi/addons/game.retroarch/addon.sh</application>\n        <args>-L /storage/.kodi/addons/game.libretro.$system_id/libretro.so &quot;%rom%&quot;</args>\n        <rompath>$ROMS_PATH/$system_id/</rompath>\n        <romext>zip|smc|sfc|fig|swc|mgd|smd|gen|md|nes|n64|z64|psx|cue|iso|chd</romext>\n        <categoryid>a57e335e-63f5-42d6-a973-c15764d13e9a</categoryid>\n    </launcher>\n</launchers>"
                sed -i "s|</launchers>|$launcher_xml|g" "$LAUNCHERS_FILE"
            else
                echo "AEL launcher for $system_id already exists."
            fi
        fi
    done
    echo "AEL configuration check complete."
}

set_boot_to_games() {
    if grep -q "<startup><window>games</window></startup>" "$KODI_USERDATA/guisettings.xml"; then
        echo "Kodi is already set to boot into Games menu."
    else
        read -p "Set Kodi to boot directly into the Games menu? (y/n): " confirm
        if [ "$confirm" = "y" ]; then
            echo "Backing up and modifying guisettings.xml..."
            cp "$KODI_USERDATA/guisettings.xml" "$KODI_USERDATA/guisettings.xml.bak"
            sed -i 's|<startup.*>.*</startup>|<startup><window>games</window></startup>|g' "$KODI_USERDATA/guisettings.xml"
            echo "Kodi will now boot into the Games menu after restart."
        fi
    fi
}


# --- Main Menu ---
echo "--- LibreELEC Emulation Powerhouse Script ---"
echo "--- Using Games Database Version: $GAMES_DB_VERSION ---"

PS3="Select an option: "
options="Full_Install/Update_(Recommended) Check_for_New_Game_Packs Configure_Kodi_Integration_Only Set_Boot_to_Games_Only Exit"
select opt in $options
do
    case $opt in
        "Full_Install/Update_(Recommended)")
            install_emulation_software
            run_game_installer
            configure_kodi_integration
            set_boot_to_games
            echo "Full setup check complete! Please restart LibreELEC."
            break
            ;;
        "Check_for_New_Game_Packs")
            check_for_new_packs
            configure_kodi_integration
            echo "Game pack check complete!"
            break
            ;;
        "Configure_Kodi_Integration_Only")
            configure_kodi_integration
            echo "Kodi integration configured!"
            break
            ;;
        "Set_Boot_to_Games_Only")
            set_boot_to_games
            echo "Boot setting configured!"
            break
            ;;
        "Exit")
            break
            ;;
        *) echo "Invalid option $REPLY";;
    esac
done
