#!/bin/bash

# --- Curated Game Pack Definitions ---
# This file is sourced by emulation.sh.
# It can be updated independently to add more game packs.
#
# Format: "Console Name;System ID;Download URL;Size String"
# - Console Name: Display name for the menu.
# - System ID: Short name for directories and libretro cores (e.g., snes, psx, n64).
# - Download URL: Direct link to the .zip archive.
# - Size String: Human-readable estimated size (e.g., 250MB, 15GB).

SCRIPT_VERSION="1.2" # Tracks changes to the script logic
GAMES_DB_VERSION="2025.06.28" # Tracks the version of this games list

declare -a game_packs=(
    "SNES;snes;https://archive.org/download/top-100-snes-games/Top%20100%20SNES%20Games.zip;250MB"
    "Sega Genesis;genesis;https://archive.org/download/top-100-genesis-games/Top%20100%20Genesis%20Games.zip;200MB"
    "PlayStation;psx;https://archive.org/download/top-50-ps1-games-chd/Top%2050%20PS1%20Games%20(CHD).zip;15GB"
    "Nintendo 64;n64;https://archive.org/download/top-50-n64-games/Top%2050%20N64%20Games.zip;1.5GB"
    "NES;nes;https://archive.org/download/nes-classic-edition-romset/NES%20Classic%20Edition%20Romset.zip;50MB"
    "Sega CD;segacd;https://archive.org/download/best-of-sega-cd/Best%20of%20Sega%20CD.zip;10GB"
    "PC Engine/TG-16;pce;https://archive.org/download/best-of-pc-engine/Best%20of%20PC%20Engine.zip;150MB"
)
