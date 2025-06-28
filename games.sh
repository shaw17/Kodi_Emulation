#!/bin/sh

# --- Curated Game Pack Definitions ---
# This file is sourced by emulation.sh.
# Format: "Console Name;System ID;Download URL;Size String"

GAMES_DB_VERSION="2025.06.28.1" # Tracks the version of this games list

# POSIX-compliant multi-line string definition. Each line is a record.
game_packs_data='SNES;snes;https://archive.org/download/top-100-snes-games/Top%20100%20SNES%20Games.zip;250MB
Sega Genesis;genesis;https://archive.org/download/top-100-genesis-games/Top%20100%20Genesis%20Games.zip;200MB
PlayStation;psx;https://archive.org/download/top-50-ps1-games-chd/Top%2050%20PS1%20Games%20(CHD).zip;15GB
Nintendo 64;n64;https://archive.org/download/top-50-n64-games/Top%2050%20N64%20Games.zip;1.5GB
NES;nes;https://archive.org/download/nes-classic-edition-romset/NES%20Classic%20Edition%20Romset.zip;50MB
Sega CD;segacd;https://archive.org/download/best-of-sega-cd/Best%20of%20Sega%20CD.zip;10GB
PC Engine/TG-16;pce;https://archive.org/download/best-of-pc-engine/Best%20of%20PC%20Engine.zip;150MB'
