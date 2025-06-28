Kodi Emulation

This project provides a set of scripts to turn a standard LibreELEC (libreelec.tv) installation into a full-blown retro gaming powerhouse.

It automates the installation of necessary software, provides a curated list of "best-of" game packs from the Internet Archive, and integrates them directly into your Kodi interface.

Features
Automated Software Install: Automatically installs RetroArch and Advanced Emulator Launcher (AEL) via the Gamestarter repository.

Curated "Best-Of" Packs: A separate, easily updatable list of recommended game packs for popular consoles.

Intelligent Installation: Automatically downloads all game packs if you have enough disk space, or provides a manual selection menu if space is limited.

Resilient & Re-runnable: The script can be run multiple times. It checks for existing components and configurations before taking action, preventing duplication.

Self-Updating: Checks for new versions of the script and the game list directly from GitHub.

Seamless Kodi Integration: Automatically configures Advanced Emulator Launcher to create a "Games" menu on your Kodi home screen.

Boot to Games: Includes an option to make Kodi boot directly into your game collection.

Prerequisites
A running LibreELEC system.

An active internet connection.

SSH access to your LibreELEC device.

The One-Liner Command
To get started, SSH into your LibreELEC box and run the following command. This will download the necessary files and execute the main script.

wget -qO- https://raw.githubusercontent.com/shaw17/Kodi_Emulation/main/emulation.sh | bash

Note: The command above pipes the script directly to bash. For those who prefer to inspect the script before running, you can use this two-step process:

# First, download the scripts
wget https://raw.githubusercontent.com/shaw17/Kodi_Emulation/main/emulation.sh

wget https://raw.githubusercontent.com/shaw17/Kodi_Emulation/main/games.sh

# Make the main script executable
chmod +x emulation.sh

# Then run it
./emulation.sh

How It Works
The system is split into two files:

emulation.sh: The main engine that contains all the installation and configuration logic.

games.sh: A simple database of curated game packs. This can be updated by the community without touching the core script logic.

When you run the script, it will first check for updates to itself and the games list. It will then present a menu with several options, allowing you to perform a full installation or just specific tasks.

Disclaimer
Thiss script facilitates the download of content from the Internet Archive. The legality of downloading and playing copyrighted game ROMs varies by jurisdiction. It is your responsibility to ensure you have the legal right to use this content. This project is for educational purposes only.
