#!/bin/bash

# Enable exit on error
set -e

# Function to log messages
log() {
    local message="$1"
    sudo sh -c "echo \"$(date +'%Y-%m-%d %H:%M:%S') $message\" >> \"$LOG_FILE\""
}

# Function for displaying headers
display() {
    local header_text="$1"
    local DISPLAY_COMMAND="echo"

    if command -v figlet &> /dev/null; then
        DISPLAY_COMMAND="figlet"
    fi

    echo "--------------------------------------"
    $DISPLAY_COMMAND "$header_text"
    log "$header_text"
    echo "--------------------------------------"
}

# Check if Script is Run as Root
if [[ $EUID -ne 1000 ]]; then
    echo "You must be a normal user to run this script, please run ./install.sh" 2>&1
    exit 1
fi

USERNAME=$(id -u -n 1000)

if [[ "/home/$USERNAME" != "$HOME" ]]; then
    exit 1
fi

# Configuration
START=$(date +%s)
LOG_FILE="/var/log/installation.log"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
CRONTAB_ROOT="$SCRIPT_DIR/crontab/root"
mkdir -p "$HOME/.config/" "$HOME/Epitech"

# Define what you want to install
INSTALL_DOCKER=false
INSTALL_SFML=true
INSTALL_NCURSES=true
INSTALL_JAVA=true
INSTALL_C=true
INSTALL_PYTHON=true
INSTALL_JS=true
INSTALL_TS=true

# Update Submodule
git submodule update --init --recursive

# Update DNF configuration and system
sudo cp "$SCRIPT_DIR/dnf/dnf.conf" /etc/dnf/dnf.conf
sudo dnf update -y

# Install default apps
sudo dnf install -y htop vim curl figlet
sudo dnf group install development-tools

display "git"
sudo dnf install -y git

display "ZSH"
if ! command -v zsh &>/dev/null; then
    sudo dnf install -y zsh fontawesome-fonts    
fi
cp "$SCRIPT_DIR/zsh/.zshrc" "$HOME/.zshrc"
mkdir -p "$HOME/.zsh"
cp "$SCRIPT_DIR/zsh/alias.zsh" "$HOME/.zsh"
cp "$SCRIPT_DIR/zsh/env.zsh" "$HOME/.zsh"
touch "$HOME/.zsh/kubectl.zsh"

display "Start Flatpak"
sudo dnf install -y flatpak
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
log "End Flatpak"

# Install Rust
display "Start Rust"
if ! command -v cargo &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > /tmp/rust.sh
    chmod +x /tmp/rust.sh
    /tmp/rust.sh -y
    rm -f /tmp/rust.sh
    source "$HOME/.cargo/env"
fi
log "End Rust"

if [ "$INSTALL_JS" == true ]; then
    display "Start JS"
    sudo dnf install -y nodejs npm
    log "End JS"
fi

if [ "$INSTALL_TS" == true ]; then
    display "Start TS"
    sudo npm install -g typescript
    log "End TS"
fi

if [ "$INSTALL_SFML" == true ]; then
    display "Start SFML"
    sudo dnf install -y SFML-devel
    log "End SFML"
fi

if [ "$INSTALL_NCURSES" == true ]; then
    display "Start NCurses"
    sudo dnf install -y ncurses-devel
    log "End NCurses"
fi

if [ "$INSTALL_PYTHON" == true ]; then
    display "Start Python"
    sudo dnf install -y python3-pip
    log "End Python"
fi

if [ "$INSTALL_JAVA" == true ]; then
    display "Java Start"
    sudo dnf install -y java
    log "Java End"
fi

if [ "$INSTALL_C" == true ]; then
    display "C Start"
    "$SCRIPT_DIR/criterion/install_criterion.sh"
    log "C End"
fi

if [ "$INSTALL_DOCKER" == true ]; then
    display "Start Docker Engine"
    if ! command -v docker &>/dev/null; then
        sudo dnf -y install dnf-plugins-core
        sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        if ! getent group docker &>/dev/null; then
            echo "Creating group: docker"
            sudo groupadd docker
        fi
        sudo usermod -aG docker "$USER"
        sudo systemctl enable containerd.service
        sudo systemctl enable docker.service
    fi
    log "End Docker Engine"
fi

display "Start Terminal Emulators" # kitty
sudo dnf install -y kitty
mkdir -p "$HOME/.config/kitty/"
cp "$SCRIPT_DIR/kitty/kitty.conf" "$HOME/.config/kitty/"

# display "Start Modern replacement"
# cargo install eza fcp
# sudo npm install -g safe-rm
# sudo dnf install -y tldr bat ripgrep fzf fd-find
#log "End Modern replacement"

display "Start File Managers"

# Install yazi
if ! command -v yazi &>/dev/null; then
    cargo install --locked yazi-fm
fi

# Add font to terminal
sudo mkdir -p ~/.local/share/font/
sudo cp -r terminal_font/ ~/.local/share/font/

# Create folders
mkdir -p "$HOME/Github_Public_Profile/"
mkdir -p "$HOME/Project_Epitech/"
mkdir -p "$HOME/Personal_Project/"

display "Start Communication"

# Discord
if ! command -v Discord &>/dev/null; then
    sudo flatpak install -y flathub com.discordapp.Discord
fi

# Teams for Linux
if ! command -v teams-for-linux &>/dev/null; then
    sudo flatpak install -y flathub com.github.IsmaelMartinez.teams_for_linux
fi
log "End Communication"

display "Start Functional Program"

# TLP
sudo dnf install tlp tlp-rdw
sudo systemctl enable tlp.service
log "End tlp"

# Rofi
sudo dnf -y install rofi
log "End rofi"

# DNF plugins
sudo dnf install -y dnf-plugins-core

# Set keyboard shortcut
sudo xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>r" -n -t string -s "kitty"
sudo xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>f" -n -t string -s "rofi -show drun"

# Install VSCode
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf check-update
sudo dnf -y install code

