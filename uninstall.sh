#!/usr/bin/env bash
# ==============================================================================
#  ✧ RoxyOS: Uninstaller / System Restore Script ✧
#  Restores standard upstream GNOME and default boot settings on Arch Linux
# ==============================================================================

set -e

RED='\033[1;31m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
NC='\033[0m'

echo -e "${CYAN}=== Restoring Upstream Default Desktop & Boot Configuration ===${NC}"

# Identify target user
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
else
    REAL_USER="$USER"
    USER_HOME="$HOME"
fi

run_as_user() {
    if [ -n "$SUDO_USER" ]; then
        sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$REAL_USER")/bus" "$@"
    else
        "$@"
    fi
}

# 1. Restore GRUB
if [ -f /etc/default/grub.bak.roxyos ]; then
    echo "-> Restoring /etc/default/grub from backup..."
    sudo cp /etc/default/grub.bak.roxyos /etc/default/grub
else
    echo "-> Resetting GRUB theme in /etc/default/grub..."
    sudo sed -i 's|^GRUB_THEME=.*||' /etc/default/grub
fi

if command -v update-grub &>/dev/null; then
    sudo update-grub
elif command -v grub-mkconfig &>/dev/null; then
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# 2. Restore Plymouth
if command -v plymouth-set-default-theme &>/dev/null; then
    echo "-> Resetting Plymouth theme to bgrt..."
    sudo plymouth-set-default-theme -R bgrt 2>/dev/null || sudo plymouth-set-default-theme -R spinner 2>/dev/null || true
fi

# 3. Restore /etc/os-release
if [ -f /etc/os-release.bak.roxyos ]; then
    echo "-> Restoring /etc/os-release..."
    sudo cp /etc/os-release.bak.roxyos /etc/os-release
fi

# 4. Stop and disable theme sync daemon
run_as_user systemctl --user stop roxy-theme-sync.service 2>/dev/null || true
run_as_user systemctl --user disable roxy-theme-sync.service 2>/dev/null || true
sudo rm -f /usr/local/bin/roxy-theme-sync
rm -f "$USER_HOME/.config/systemd/user/roxy-theme-sync.service"

# 5. Disable Extensions
run_as_user gnome-extensions disable roxy-topbar-badge@mushoku.local 2>/dev/null || true
run_as_user gnome-extensions disable mouse-tail@lanesun.anlbrain.com 2>/dev/null || true

# 6. Reset GNOME interface defaults
run_as_user gsettings reset org.gnome.shell.extensions.user-theme name 2>/dev/null || true
run_as_user gsettings reset org.gnome.desktop.interface cursor-theme 2>/dev/null || true
run_as_user gsettings reset org.gnome.desktop.interface cursor-size 2>/dev/null || true
run_as_user gsettings reset org.gnome.desktop.interface icon-theme 2>/dev/null || true
run_as_user gsettings reset org.gnome.desktop.sound theme-name 2>/dev/null || true

echo -e "${GREEN}✔ Default system settings successfully restored!${NC}"
