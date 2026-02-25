#!/usr/bin/env bash

# Custom DualBoot Builder Script v1.0
# By Grok (xAI) - February 2026
# Builds Arch Linux ISO with preinstalled apps: VS Code, GitHub Desktop, Notepad++, VirtualBox, Brave.
# CodePen as desktop shortcut. LibreOffice instead of MS 365 (legal alternative).
# For Windows dual boot: Install Windows first, then this ISO on separate partition.
# Notes: No MS 365 without key (illegal without license). Use trial or buy.

set -e  # Exit on error

# Variables
WORK_DIR="${HOME}/dualboot-build"
PROFILE_DIR="${WORK_DIR}/dual-profile"
OUT_DIR="${WORK_DIR}/out"
ISO_NAME="CustomDualBoot-Arch-v1-$(date +%Y%m%d).iso"

# Step 1: Install archiso if needed
echo "Installing archiso..."
sudo pacman -Syu --noconfirm --needed archiso git base-devel

# Step 2: Setup profile
echo "Setting up profile..."
mkdir -p "${PROFILE_DIR}"
cp -r /usr/share/archiso/configs/releng/* "${PROFILE_DIR}/"

# Step 3: Packages list (including your apps)
echo "Writing packages..."
cat << EOF > "${PROFILE_DIR}/packages.x86_64"
# Base
linux linux-firmware linux-headers mkinitcpio grub efibootmgr systemd

# Desktop: KDE Plasma
plasma-meta kde-applications-meta sddm

# Networking & Security
networkmanager wireguard-tools firejail apparmor ufw tpm2-tools sbctl cryptsetup

# Apps you requested
code  # VS Code
virtualbox virtualbox-host-modules-arch
brave-browser
wine winetricks  # For Notepad++ via Wine
libreoffice-fresh  # Legal alternative to MS 365
git base-devel  # For AUR

# Utils
plymouth plymouth-theme-spinner htop neofetch kitty
EOF

# Step 4: Profiledef.sh
echo "Writing profiledef..."
cat << EOF > "${PROFILE_DIR}/profiledef.sh"
#!/usr/bin/env bash
iso_name="custom-dualboot-arch"
iso_label="CustomDual_v1"
iso_publisher="Itay Shmolovitz <itay@shmolovitz.com>"
iso_application="Custom DualBoot Arch"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('uefi-x64.grub.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
EOF

# Step 5: Pacman.conf with multilib
echo "Writing pacman.conf..."
cat << EOF > "${PROFILE_DIR}/pacman.conf"
[options]
Architecture = auto
CheckSpace
SigLevel    = Required DatabaseOptional

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF

# Step 6: Customize script (install AUR apps, setup shortcuts, etc.)
echo "Writing customize_airootfs.sh..."
cat << EOF > "${PROFILE_DIR}/airootfs/root/customize_airootfs.sh"
#!/usr/bin/env bash
set -e -u -x

# Update
pacman -Syu --noconfirm

# Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Syu --noconfirm

# Install AUR helper (yay)
pacman -S --noconfirm base-devel git
su -c 'git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si --noconfirm' -s /bin/sh nobody
rm -rf /tmp/yay

# AUR apps: GitHub Desktop, Notepad++ (via Wine)
yay -S --noconfirm github-desktop notepad-plus-plus

# CodePen shortcut (website)
mkdir -p /etc/skel/Desktop
cat << SHORTCUT > /etc/skel/Desktop/CodePen.desktop
[Desktop Entry]
Type=Application
Name=CodePen
Exec=brave https://codepen.io/
Icon=brave-browser
Terminal=false
SHORTCUT
chmod +x /etc/skel/Desktop/CodePen.desktop

# Enable services
systemctl enable sddm NetworkManager apparmor ufw

# Plymouth
plymouth-set-default-theme -R spinner
sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block encrypt plymouth filesystems keyboard fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

# Basic theme (dark + orange)
mkdir -p /etc/skel/.config
cat << THEME > /etc/skel/.config/plasmarc
[General]
ColorScheme=BreezeDark
accentColor=#FF5500
THEME

# UFW default closed
ufw default deny incoming
ufw default allow outgoing
ufw enable

# Cleanup
pacman -Scc --noconfirm

echo "Custom ISO ready! For dual boot: Install Windows first, then this on separate partition."
echo "For MS 365: Install manually with license after setup."
EOF

chmod +x "${PROFILE_DIR}/airootfs/root/customize_airootfs.sh"

# Step 7: Build ISO
echo "Building ISO... (10-60 min)"
cd "${PROFILE_DIR}"
sudo mkarchiso -v -w "${WORK_DIR}/work" -o "${OUT_DIR}" .
echo "ISO at ${OUT_DIR}/${ISO_NAME}"

echo "Done! Test in VM. For Windows: See guide below."
