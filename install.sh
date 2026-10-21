#!/usr/bin/env bash
# ==============================================================================
#  ✧ RoxyOS: Mushoku Tensei System Suite Installer ✧
#  Target Platform: Arch Linux / Linux (GNOME 44+)
# ==============================================================================

set -e

# ANSI Color Palette
CYAN='\033[1;36m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Identify target user (handles sudo execution)
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
else
    REAL_USER="$USER"
    USER_HOME="$HOME"
fi

banner() {
    echo -e "${CYAN}"
    echo "  ╔═══════════════════════════════════════════════════════════════╗"
    echo "  ║        ✧  RoxyOS: Mushoku Tensei System Suite  ✧              ║"
    echo "  ║             Arch Linux & GNOME Transformation                 ║"
    echo "  ╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() {
    echo -e "${CYAN}✦ [INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✔ [SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}▲ [WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}✖ [ERROR]${NC} $1"
}

run_as_user() {
    if [ -n "$SUDO_USER" ]; then
        sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$REAL_USER")/bus" "$@"
    else
        "$@"
    fi
}

check_dependencies() {
    log_info "Verifying required packages on Arch Linux..."

    # Check pacman
    if ! command -v pacman &>/dev/null; then
        log_error "This installer targets Arch Linux systems with 'pacman'."
        exit 1
    fi

    local REQUIRED_PKGS=(
        gnome-shell
        gnome-control-center
        gnome-shell-extensions
        fastfetch
        papirus-icon-theme
        plymouth
        grub
        xorg-xcursorgen
        python
        python-gobject
        glib2
        imagemagick
    )

    local MISSING_PKGS=()
    for pkg in "${REQUIRED_PKGS[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            MISSING_PKGS+=("$pkg")
        fi
    done

    # Check GTK theme package (adw-gtk-theme or adw-gtk3)
    if ! pacman -Qi adw-gtk-theme &>/dev/null && ! pacman -Qi adw-gtk3 &>/dev/null; then
        MISSING_PKGS+=("adw-gtk-theme")
    fi

    if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
        log_info "The following missing packages are required: ${MISSING_PKGS[*]}"
        log_info "Installing missing dependencies via pacman..."
        sudo pacman -S --needed --noconfirm "${MISSING_PKGS[@]}" || {
            log_warn "Some packages may need AUR installation or manual approval. Continuing..."
        }
    else
        log_success "All prerequisite packages are installed!"
    fi
}

install_wallpapers() {
    log_info "Installing wallpapers to /usr/share/backgrounds/mushoku-tensei..."
    sudo mkdir -p /usr/share/backgrounds/mushoku-tensei
    sudo cp -r "$SCRIPT_DIR/wallpapers/"* /usr/share/backgrounds/mushoku-tensei/

    log_info "Setting active wallpapers for $REAL_USER..."
    run_as_user gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/mushoku-tensei/roxy_vibrant.png'
    run_as_user gsettings set org.gnome.desktop.background picture-uri-dark 'file:///usr/share/backgrounds/mushoku-tensei/roxy_dark.png'
    run_as_user gsettings set org.gnome.desktop.screensaver picture-uri 'file:///usr/share/backgrounds/mushoku-tensei/roxy_dark.png'
    log_success "Wallpapers installed and configured."
}

install_shell_themes() {
    log_info "Installing GNOME Shell themes (Dark & Light)..."
    sudo mkdir -p /usr/share/themes
    sudo cp -r "$SCRIPT_DIR/themes/roxy-shell" /usr/share/themes/
    sudo cp -r "$SCRIPT_DIR/themes/roxy-shell-light" /usr/share/themes/

    # Also install locally for user
    mkdir -p "$USER_HOME/.themes"
    cp -r "$SCRIPT_DIR/themes/roxy-shell" "$USER_HOME/.themes/"
    cp -r "$SCRIPT_DIR/themes/roxy-shell-light" "$USER_HOME/.themes/"
    chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.themes"

    # Enable User Themes GNOME extension
    run_as_user gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.user-theme name "roxy-shell"
    log_success "Shell themes installed."
}

install_cursors() {
    log_info "Installing bespoke Aqua Heartia cursor theme..."
    sudo mkdir -p /usr/share/icons
    sudo cp -r "$SCRIPT_DIR/icons/roxy-magic-cursor" /usr/share/icons/

    mkdir -p "$USER_HOME/.local/share/icons"
    cp -r "$SCRIPT_DIR/icons/roxy-magic-cursor" "$USER_HOME/.local/share/icons/"
    chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.local/share/icons"

    run_as_user gsettings set org.gnome.desktop.interface cursor-theme "roxy-magic-cursor"
    run_as_user gsettings set org.gnome.desktop.interface cursor-size 32
    log_success "Cursor theme deployed and activated (32px)."
}

install_app_icons() {
    log_info "Injecting custom water-magic vector icons into Papirus..."
    local ICON_SIZES=("16x16" "22x22" "24x24" "32x32" "48x48" "64x64" "128x128" "scalable")
    local THEME_TARGETS=("/usr/share/icons/Papirus" "/usr/share/icons/Papirus-Dark" "$USER_HOME/.local/share/icons/Papirus" "$USER_HOME/.local/share/icons/Papirus-Dark")

    # Mapping from source clean SVGs to target icon names
    declare -A ICON_MAP=(
        ["start-here.svg"]="start-here distributor-logo archlinux-logo"
        ["system-file-manager.svg"]="system-file-manager nautilus nautilus-alt org.gnome.Nautilus"
        ["web-browser.svg"]="web-browser firefox firefox-developer-edition firefox-nightly org.mozilla.firefox google-chrome chromium"
        ["utilities-terminal.svg"]="utilities-terminal utilities-x-terminal org.gnome.Console org.gnome.Ptyxis org.gnome.Terminal"
        ["org.gnome.TextEditor.svg"]="org.gnome.TextEditor text-editor gedit"
        ["org.gnome.Settings.svg"]="org.gnome.Settings preferences-system preferences-desktop"
        ["system-software-install.svg"]="system-software-install org.gnome.Software pamac-manager"
        ["org.gnome.Music.svg"]="org.gnome.Music gnome-music"
        ["org.gnome.Snapshot.svg"]="org.gnome.Snapshot org.gnome.Camera cheese"
        ["org.gnome.Showtime.svg"]="org.gnome.Showtime org.gnome.Totem totem"
        ["org.gnome.Decibels.svg"]="org.gnome.Decibels sound-recorder"
        ["org.gnome.SimpleScan.svg"]="org.gnome.SimpleScan simple-scan"
        ["org.gnome.Loupe.svg"]="org.gnome.Loupe org.gnome.eog eog"
    )

    for theme_dir in "${THEME_TARGETS[@]}"; do
        if [ ! -d "$theme_dir" ]; then
            continue
        fi

        for src_file in "${!ICON_MAP[@]}"; do
            src_path="$SCRIPT_DIR/icons/apps/$src_file"
            if [ ! -f "$src_path" ]; then
                continue
            fi

            for target_name in ${ICON_MAP[$src_file]}; do
                for sz in "${ICON_SIZES[@]}"; do
                    dest_dir="$theme_dir/$sz/apps"
                    if [ -d "$dest_dir" ]; then
                        sudo cp "$src_path" "$dest_dir/$target_name.svg" 2>/dev/null || true
                    fi
                done
            done
        done
        sudo gtk-update-icon-cache -f -t "$theme_dir" 2>/dev/null || true
    done

    run_as_user gsettings set org.gnome.desktop.interface icon-theme "Papirus"
    log_success "App icons injected with alpha transparency."
}

install_branding_and_settings() {
    log_info "Integrating RoxyOS branding into upstream GNOME Settings (About Page)..."
    sudo mkdir -p /usr/share/pixmaps /usr/share/icons/hicolor/scalable/apps

    sudo cp "$SCRIPT_DIR/branding/roxyos-horizontal.svg" /usr/share/pixmaps/roxyos.svg
    sudo cp "$SCRIPT_DIR/branding/roxyos-horizontal.svg" /usr/share/pixmaps/roxyos-horizontal.svg
    sudo cp "$SCRIPT_DIR/branding/roxyos-horizontal.svg" /usr/share/pixmaps/archlinux-logo.svg 2>/dev/null || true
    sudo cp "$SCRIPT_DIR/branding/roxyos-horizontal.png" /usr/share/pixmaps/archlinux-logo.png 2>/dev/null || true
    sudo cp "$SCRIPT_DIR/branding/roxyos-square.svg" /usr/share/pixmaps/roxyos-square.svg

    sudo cp "$SCRIPT_DIR/branding/roxyos-horizontal.svg" /usr/share/icons/hicolor/scalable/apps/roxyos.svg
    sudo cp "$SCRIPT_DIR/branding/roxyos-horizontal.svg" /usr/share/icons/hicolor/scalable/apps/roxyos-logo.svg
    sudo cp "$SCRIPT_DIR/branding/roxyos-horizontal.svg" /usr/share/icons/hicolor/scalable/apps/distributor-logo.svg
    sudo cp "$SCRIPT_DIR/branding/roxyos-horizontal.svg" /usr/share/icons/hicolor/scalable/apps/archlinux-logo.svg

    sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true

    # Backup and configure /etc/os-release
    if [ ! -f /etc/os-release.bak.roxyos ]; then
        sudo cp /etc/os-release /etc/os-release.bak.roxyos
    fi

    # Update OS release fields
    sudo sed -i 's|^NAME=.*|NAME="RoxyOS"|' /etc/os-release
    sudo sed -i 's|^PRETTY_NAME=.*|PRETTY_NAME="RoxyOS (Mushoku Tensei Edition)"|' /etc/os-release
    if grep -q '^LOGO=' /etc/os-release; then
        sudo sed -i 's|^LOGO=.*|LOGO=roxyos|' /etc/os-release
    else
        echo 'LOGO=roxyos' | sudo tee -a /etc/os-release
    fi

    log_success "Upstream GNOME Settings branding updated."
}

install_extensions() {
    log_info "Installing GNOME Extensions (RoxyOS Topbar Badge & Mouse Trail)..."
    local EXT_USER_DIR="$USER_HOME/.local/share/gnome-shell/extensions"
    local EXT_SYS_DIR="/usr/share/gnome-shell/extensions"

    mkdir -p "$EXT_USER_DIR"
    sudo mkdir -p "$EXT_SYS_DIR"

    # 1. Top Bar Badge Extension
    cp -r "$SCRIPT_DIR/extensions/roxy-topbar-badge@mushoku.local" "$EXT_USER_DIR/"
    sudo cp -r "$SCRIPT_DIR/extensions/roxy-topbar-badge@mushoku.local" "$EXT_SYS_DIR/"

    # 2. Mouse Trail Extension
    if [ -d "$SCRIPT_DIR/extensions/mouse-tail@lanesun.anlbrain.com" ]; then
        cp -r "$SCRIPT_DIR/extensions/mouse-tail@lanesun.anlbrain.com" "$EXT_USER_DIR/"
        sudo cp -r "$SCRIPT_DIR/extensions/mouse-tail@lanesun.anlbrain.com" "$EXT_SYS_DIR/"
        # Compile schemas
        glib-compile-schemas "$EXT_USER_DIR/mouse-tail@lanesun.anlbrain.com/schemas" 2>/dev/null || true
    fi

    chown -R "$REAL_USER:$REAL_USER" "$EXT_USER_DIR"

    # Enable extensions for target user
    run_as_user gnome-extensions enable roxy-topbar-badge@mushoku.local 2>/dev/null || true
    run_as_user gnome-extensions enable mouse-tail@lanesun.anlbrain.com 2>/dev/null || true
    log_success "Extensions installed and enabled."
}

install_sound_theme() {
    log_info "Installing hydrological sound suite..."
    sudo mkdir -p /usr/share/sounds
    sudo cp -r "$SCRIPT_DIR/sounds/roxy" /usr/share/sounds/

    mkdir -p "$USER_HOME/.local/share/sounds"
    cp -r "$SCRIPT_DIR/sounds/roxy" "$USER_HOME/.local/share/sounds/"
    chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.local/share/sounds"

    run_as_user gsettings set org.gnome.desktop.sound theme-name "roxy"
    run_as_user gsettings set org.gnome.desktop.sound event-sounds true
    run_as_user gsettings set org.gnome.desktop.sound input-feedback-sounds true
    log_success "Sound suite installed."
}

install_gtk4_and_daemon() {
    log_info "Installing dynamic GTK4 styling and Theme Sync Daemon..."
    mkdir -p "$USER_HOME/.config/gtk-4.0"
    cp "$SCRIPT_DIR/config/gtk-4.0/gtk.css" "$USER_HOME/.config/gtk-4.0/gtk.css"

    sudo cp "$SCRIPT_DIR/config/scripts/roxy-theme-sync" /usr/local/bin/roxy-theme-sync
    sudo chmod +x /usr/local/bin/roxy-theme-sync

    mkdir -p "$USER_HOME/.config/systemd/user"
    cp "$SCRIPT_DIR/config/systemd/roxy-theme-sync.service" "$USER_HOME/.config/systemd/user/"

    chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.config"

    # Enable and start user service
    run_as_user systemctl --user daemon-reload 2>/dev/null || true
    run_as_user systemctl --user enable --now roxy-theme-sync.service 2>/dev/null || true
    log_success "GTK4 styling & roxy-theme-sync.service activated."
}

install_cli_and_fastfetch() {
    log_info "Installing Fastfetch ANSI artwork and shell profiles..."
    mkdir -p "$USER_HOME/.config/fastfetch"
    cp "$SCRIPT_DIR/config/fastfetch/"* "$USER_HOME/.config/fastfetch/"

    # Zsh configuration
    if [ -f "$USER_HOME/.zshrc" ]; then
        if ! grep -q "RoxyOS" "$USER_HOME/.zshrc"; then
            cat "$SCRIPT_DIR/config/shell/zsh_snippet.zsh" >> "$USER_HOME/.zshrc"
        fi
    fi

    # Fish configuration
    if [ -d "$USER_HOME/.config/fish" ]; then
        mkdir -p "$USER_HOME/.config/fish"
        if [ ! -f "$USER_HOME/.config/fish/config.fish" ] || ! grep -q "RoxyOS" "$USER_HOME/.config/fish/config.fish"; then
            cat "$SCRIPT_DIR/config/shell/fish_snippet.fish" >> "$USER_HOME/.config/fish/config.fish"
        fi
    fi

    chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.config"
    log_success "Fastfetch and CLI configurations installed."
}

install_grub() {
    log_info "Configuring GRUB bootloader theme (mushoku-roxy)..."
    sudo mkdir -p /usr/share/grub/themes/mushoku-roxy
    sudo cp -r "$SCRIPT_DIR/boot/grub/mushoku-roxy/"* /usr/share/grub/themes/mushoku-roxy/

    if [ ! -f /etc/default/grub.bak.roxyos ]; then
        sudo cp /etc/default/grub /etc/default/grub.bak.roxyos
    fi

    sudo sed -i 's|^GRUB_THEME=.*|GRUB_THEME="/usr/share/grub/themes/mushoku-roxy/theme.txt"|' /etc/default/grub
    sudo sed -i 's|^GRUB_TIMEOUT_STYLE=.*|GRUB_TIMEOUT_STYLE=menu|' /etc/default/grub
    sudo sed -i 's|^GRUB_TIMEOUT=.*|GRUB_TIMEOUT=5|' /etc/default/grub

    if command -v update-grub &>/dev/null; then
        sudo update-grub
    elif command -v grub-mkconfig &>/dev/null; then
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
    log_success "GRUB bootloader theme applied."
}

install_plymouth() {
    log_info "Configuring Plymouth bootsplash theme..."
    sudo mkdir -p /usr/share/plymouth/themes/mushoku-roxy
    sudo cp -r "$SCRIPT_DIR/boot/plymouth/mushoku-roxy/"* /usr/share/plymouth/themes/mushoku-roxy/

    # Ensure plymouth hook is in /etc/mkinitcpio.conf for Arch Linux
    if [ -f /etc/mkinitcpio.conf ]; then
        if ! grep -q 'plymouth' /etc/mkinitcpio.conf; then
            log_info "Adding 'plymouth' hook to /etc/mkinitcpio.conf..."
            sudo sed -i 's|^HOOKS=(\(.*\))|HOOKS=(\1 plymouth)|' /etc/mkinitcpio.conf
        fi
    fi

    if command -v plymouth-set-default-theme &>/dev/null; then
        sudo plymouth-set-default-theme -R mushoku-roxy || true
    elif command -v mkinitcpio &>/dev/null; then
        sudo mkinitcpio -P || true
    fi
    log_success "Plymouth bootsplash theme configured."
}

main() {
    banner
    check_dependencies
    install_wallpapers
    install_shell_themes
    install_cursors
    install_app_icons
    install_branding_and_settings
    install_extensions
    install_sound_theme
    install_gtk4_and_daemon
    install_cli_and_fastfetch
    install_grub
    install_plymouth

    echo ""
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}  ✧ Installation Completed Successfully! ✧${NC}"
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "  ✦ Shell Theme:      roxy-shell (Dark) & roxy-shell-light (Light)"
    echo -e "  ✦ Cursors:          roxy-magic-cursor (Aqua Heartia, 32px)"
    echo -e "  ✦ App Icons:        Transparent water-magic vectors in Papirus"
    echo -e "  ✦ Settings:         Native GNOME Control Center with RoxyOS branding"
    echo -e "  ✦ Boot Theme:       GRUB & Plymouth (mushoku-roxy)"
    echo -e "  ✦ Fastfetch:        roxyfetch / fastfetch"
    echo -e "  ✦ Theme Daemon:     roxy-theme-sync.service (active)"
    echo ""
    echo -e "${YELLOW}Tip: Log out and log back in (or restart GNOME Shell) to apply all visual changes.${NC}"
}

main "$@"
