#!/bin/sh

# --- Curated Game Pack Definitions ---
# This file is sourced by emulation.sh.
# Format: "Console Name;System ID;Download URL;Size String"

GAMES_DB_VERSION="2025.06.28.1" # Tracks the version of this games list

# POSIX-compliant multi-line string definition. Each line is a record.
game_packs_data='NES;nes;https://archive.org/download/nes100/nes%2B100.zip;491.2MB
SNES;snes;https://archive.org/download/snes100_202403/snes%2B100.zip;121.2MB
Sega Genesis;genesis;https://archive.org/download/genesis100_202403/genesis%2B100.zip;125.7MB
Sega Master System;mastersystem;https://archive.org/download/retro-roms-best-set/Sega%20-%20Master%20System.zip;7.4MB
Nintendo 64;n64;https://archive.org/download/retro-roms-best-set/Nintendo%20-%20N64.zip;1.4GB
Sega CD;segacd;https://archive.org/download/retro-roms-best-set/Sega%20-%20Sega%20CD.zip;5.9GB
PC Engine/TG-16;pce;https://archive.org/download/retro-roms-best-set/NEC%20-%20TurboGrafx-16.zip;18.6MB
PC Engine CD;pcecd;https://archive.org/download/retro-roms-best-set/NEC%20-%20TurboGrafx%20CD.zip;7.5GB
Game Boy;gb;https://archive.org/download/retro-roms-best-set/Nintendo%20-%20Game%20Boy.zip;17.1MB
Game Boy Color;gbc;https://archive.org/download/retro-roms-best-set/Nintendo%20-%20Game%20Boy%20Color.zip;66.9MB
Game Gear;gamegear;https://archive.org/download/retro-roms-best-set/Sega%20-%20Game%20Gear.zip;7.4MB
MAME;mame-libretro;https://archive.org/download/mame100bezels/mame%2B100%2Bbezels.zip;849.7MB
PlayStation (Top 50);psx;https://archive.org/download/ps1-rip-chd-ck/Top%2050%20PS1%20Games%20%28CHD%29.zip;16.3GB
