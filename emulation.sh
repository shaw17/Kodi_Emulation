#!/bin/bash

# --- LibreELEC Resilient Emulation Powerhouse Script ---
# Maintained at: https://github.com/shaw17/Kodi_Emulation

# --- Configuration ---
KODI_USERDATA="/storage/.kodi/userdata"
KODI_ADDONS="/storage/.kodi/addons"
ROMS_PATH="/storage/roms"
GITHUB_REPO_URL="https://raw.githubusercontent.com/shaw17/Kodi_Emulation/main"

# --- Source the games database ---
if [ -f "games.sh" ]; then
    source "games.sh"
else
    echo "games.sh not found. Please ensure it is in the same directory."
    exit 1
fi

# --- Helper Functions ---
parse_size_to_kb() {
    local size_str=$1; local num=$(echo "$size_str" | sed -e 's/[a-zA-Z]//g' -e 's/ //g'); local unit=$(echo "$size_str" | sed -e 's/[0-9\.]//g' -e 's/ //g' | tr '[:lower:]' '[:upper:]'); local val=0
    if [[ "$unit" == "GB" ]]; then val=$(awk -v n="$num" 'BEGIN { print int(n * 1024 * 1024) }'); elif [[ "$unit" == "MB" ]]; then val=$(awk -v n="$num" 'BEGIN { print int(n * 1024) }'); elif [[ "$unit" == "KB" ]]; then val=$(awk -v n="$num" 'BEGIN { print int(n) }'); fi
    echo $val
}

check_for_script_updates() {
    echo "--- Checking for script updates from GitHub... ---"
    # Fetch the latest version numbers from GitHub
    LATEST_SCRIPT_VERSION=$(wget -qO- "$GITHUB_REPO_URL/games.sh" | grep "SCRIPT_VERSION" | head -1 | cut -d'"' -f2)
    LATEST_GAMES_DB_VERSION=$(wget -qO- "$GITHUB_REPO_URL/games.sh" | grep "GAMES_DB_VERSION" | head -1 | cut -d'"' -f2)

    if [[ "$LATEST_SCRIPT_VERSION" != "$SCRIPT_VERSION" && ! -z "$LATEST_SCRIPT_VERSION" ]]; then
        read -p "A new version of the main script is available ($LATEST_SCRIPT_VERSION). Download now? (y/n): " confirm
        if [ "$confirm" == "y" ]; then
            wget -qO "emulation.sh.new" "$GITHUB_REPO_URL/emulation.sh"
            echo "New script downloaded to emulation.sh.new. Please exit and run the new script."
            exit 0
        fi
    fi

    if [[ "$LATEST_GAMES_DB_VERSION" != "$GAMES_DB_VERSION" && ! -z "$LATEST_GAMES_DB_VERSION" ]]; then
        read -p "A new games database is available ($LATEST_GAMES_DB_VERSION). Download now? (y/n): " confirm
        if [ "$confirm" == "y" ]; then
            wget -qO "games.sh" "$GITHUB_REPO_URL/games.sh"
            echo "Games database updated. The script will now use the new list."
            source "games.sh" # Re-source the newly downloaded file
        fi
    fi
     echo "--- Update check complete. ---"
}


# --- Core Logic Functions (install_emulation_software, download_pack, etc.) ---
# These are the same as the previous "resilient" script version.
# For brevity, they are represented here, but you would paste the full functions.
install_emulation_software() { echo "--- Checking for essential software... ---"; if [ ! -d "$KODI_ADDONS/repository.gamestarter" ]; then echo "Gamestarter repository not found. Installing..."; GAMESTARTER_REPO_URL="https://github.com/bite-your-idols/Gamestarter/raw/master/repository.gamestarter/repository.gamestarter-3.0.zip"; wget -q -P "$KODI_ADDONS/" "$GAMESTARTER_REPO_URL"; kodi-send --action="InstallAddon(repository.gamestarter)" > /dev/null 2>&1; else echo "Gamestarter repository already installed."; fi; if [ ! -d "$KODI_ADDONS/game.retroarch" ]; then echo "RetroArch not found. Installing..."; kodi-send --action="InstallAddon(game.retroarch)" > /dev/null 2>&1; else echo "RetroArch already installed."; fi; if [ ! -d "$KODI_ADDONS/plugin.program.advanced.emulator.launcher" ]; then echo "Advanced Emulator Launcher not found. Installing..."; kodi-send --action="InstallAddon(plugin.program.advanced.emulator.launcher)" > /dev/null 2>&1; else echo "Advanced Emulator Launcher already installed."; fi; echo "--- Base software check complete. ---"; sleep 3; }
download_pack() { local pack_string="$1"; IFS=';' read -r -a pack_info <<< "$pack_string"; local console_name="${pack_info[0]}"; local system_id="${pack_info[1]}"; local download_url="${pack_info[2]}"; if [ -d "$ROMS_PATH/$system_id" ] && [ "$(ls -A $ROMS_PATH/$system_id)" ]; then echo "Skipping '$console_name', directory already exists and is not empty."; return; fi; echo "Downloading and extracting '$console_name'..."; mkdir -p "$ROMS_PATH/$system_id"; wget -q -O "$ROMS_PATH/temp_pack.zip" "$download_url"; unzip -o -q "$ROMS_PATH/temp_pack.zip" -d "$ROMS_PATH/$system_id/"; rm "$ROMS_PATH/temp_pack.zip"; echo "'$console_name' pack installed."; }
run_game_installer() { echo "--- Game Pack Installer ---"; mkdir -p "$ROMS_PATH"; total_size_kb=0; for pack in "${game_packs[@]}"; do IFS=';' read -r -a pack_info <<< "$pack"; size_kb=$(parse_size_to_kb "${pack_info[3]}"); total_size_kb=$((total_size_kb + size_kb)); done; available_space_kb=$(df -k /storage | awk 'NR==2 {print $4}'); if [ "$available_space_kb" -gt "$total_size_kb" ]; then read -p "Sufficient space detected to install all packs. Proceed? (y/n): " confirm; if [ "$confirm" == "y" ]; then for pack in "${game_packs[@]}"; do download_pack "$pack"; done; return; fi; fi; echo "Manual selection mode. Choose a pack:"; for i in "${!game_packs[@]}"; do IFS=';' read -r -a p <<< "${game_packs[$i]}"; printf "%d) %s (%s)\n" "$((i+1))" "${p[0]}" "${p[3]}"; done; read -p "Enter number: " choice; if [ "$choice" -gt 0 ] && [ "$choice" -le "${#game_packs[@]}" ]; then download_pack "${game_packs[$((choice-1))]}"; else echo "Invalid selection."; fi; }
check_for_updates() { echo "--- Checking for New Game Packs ---"; new_packs_found=false; for pack in "${game_packs[@]}"; do IFS=';' read -r -a pack_info <<< "$pack"; system_id="${pack_info[1]}"; if [ ! -d "$ROMS_PATH/$system_id" ] || [ -z "$(ls -A $ROMS_PATH/$system_id)" ]; then if ! $new_packs_found; then echo "New game packs are available in the script!"; new_packs_found=true; fi; read -p "Install the '${pack_info[0]}' pack? (y/n): " confirm; if [ "$confirm" == "y" ]; then download_pack "$pack"; fi; fi; done; if ! $new_packs_found; then echo "Your game collection is up to date with this script version ($GAMES_DB_VERSION)."; fi; }
configure_kodi_integration() { echo "--- Configuring Kodi (AEL) Integration ---"; AEL_DATA_PATH="$KODI_USERDATA/addon_data/plugin.program.advanced.emulator.launcher"; mkdir -p "$AEL_DATA_PATH"; LAUNCHERS_FILE="$AEL_DATA_PATH/launchers.xml"; if [ ! -f "$AEL_DATA_PATH/categories.xml" ]; then cat > "$AEL_DATA_PATH/categories.xml" << EOL; <?xml version="1.0" encoding="UTF-8" standalone="yes"?><categories><category><id>a57e335e-63f5-42d6-a973-c15764d13e9a</id><name>Retro Games</name></category></categories>; EOL; fi; if [ ! -f "$LAUNCHERS_FILE" ]; then echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><launchers></launchers>' > "$LAUNCHERS_FILE"; fi; for system_dir in "$ROMS_PATH"/*/; do if [ -d "$system_dir" ] && [ "$(ls -A $system_dir)" ]; then system_id=$(basename "$system_dir"); if ! grep -q "<rompath>$ROMS_PATH/$system_id/</rompath>" "$LAUNCHERS_FILE"; then echo "Adding AEL launcher for system: $system_id"; system_name=$(echo "$system_id" | tr '[:lower:]' '[:upper:]'); launcher_xml="    <launcher>\n        <id>$(uuidgen)</id>\n        <name>$system_name</name>\n        <application>/storage/.kodi/addons/game.retroarch/addon.sh</application>\n        <args>-L /storage/.kodi/addons/game.libretro.$system_id/libretro.so &quot;%rom%&quot;</args>\n        <rompath>$ROMS_PATH/$system_id/</rompath>\n        <romext>zip|smc|sfc|fig|swc|mgd|smd|gen|md|nes|n64|z64|psx|cue|iso|chd</romext>\n        <categoryid>a57e335e-63f5-42d6-a973-c15764d13e9a</categoryid>\n    </launcher>\n</launchers>"; sed -i "s|</launchers>|$launcher_xml|g" "$LAUNCHERS_FILE"; else echo "AEL launcher for $system_id already exists."; fi; fi; done; echo "AEL configuration check complete."; }
set_boot_to_games() { if grep -q "<startup><window>games</window></startup>" "$KODI_USERDATA/guisettings.xml"; then echo "Kodi is already set to boot into Games menu."; else read -p "Set Kodi to boot directly into the Games menu? (y/n): " confirm; if [ "$confirm" == "y" ]; then echo "Backing up and modifying guisettings.xml..."; cp "$KODI_USERDATA/guisettings.xml" "$KODI_USERDATA/guisettings.xml.bak"; sed -i 's|<startup.*>.*</startup>|<startup><window>games</window></startup>|g' "$KODI_USERDATA/guisettings.xml"; echo "Kodi will now boot into the Games menu after restart."; fi; fi; }


# --- Main Menu ---
echo "--- LibreELEC Resilient Emulation Setup (v$SCRIPT_VERSION) ---"
echo "--- Games Database Version: $GAMES_DB_VERSION ---"

check_for_script_updates

PS3="Select an option: "
options=("Full Install/Update (Recommended)" "Install/Update Game Packs Only" "Configure Kodi Integration Only" "Set Boot to Games Only" "Exit")
select opt in "${options[@]}"
do
    case $opt in
        "Full Install/Update (Recommended)")
            install_emulation_software
            run_game_installer
            configure_kodi_integration
            set_boot_to_games
            echo "Full setup check complete! Please restart LibreELEC."
            break
            ;;
        "Install/Update Game Packs Only")
            check_for_updates
            run_game_installer
            configure_kodi_integration
            echo "Game pack check complete!"
            break
            ;;
        "Configure Kodi Integration Only")
            configure_kodi_integration
            echo "Kodi integration configured!"
            break
            ;;
        "Set Boot to Games Only")
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
