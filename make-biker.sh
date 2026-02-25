#!/usr/bin/env bash

# BikerOS ISO Builder Script v1.0
# Written by Grok (xAI) - February 2026
# This is a complete, self-contained Bash script to build a custom Arch Linux ISO for BikerOS.
# It automates:
#   - Installing archiso if needed
#   - Creating a temporary profile directory
#   - Populating all necessary files (packages, scripts, configs)
#   - Building the ISO with mkarchiso
#
# Requirements:
#   - Run on an Arch Linux system (or Arch-based like EndeavourOS)
#   - Root privileges (uses sudo)
#   - Internet connection for pacman
#   - Enough disk space (~10-20 GB free in /tmp or your work dir)
#
# Usage:
#   1. Save this as build-bikeros.sh
#   2. chmod +x build-bikeros.sh
#   3. ./build-bikeros.sh
#   4. The ISO will be in out/ directory
#
# Notes:
#   - This builds a basic MVP: Arch + KDE Plasma + packages + basic security + plymouth splash.
#   - Advanced stuff like full VISO AI app, custom visor animation, atomic updates – not included here (too complex for single script; needs manual dev).
#   - Theme: Basic dark + orange accents via skel configs.
#   - After install, run post-install scripts manually for full customization.
#   - Test in VM first!

set -e  # Exit on error

# Variables
WORK_DIR="${HOME}/biker-os-build"
PROFILE_DIR="${WORK_DIR}/biker-profile"
OUT_DIR="${WORK_DIR}/out"
ISO_NAME="biker-os-$(date +%Y%m%d).iso"

# Step 1: Install archiso and dependencies if not present
echo "Installing archiso and git if needed..."
sudo pacman -Syu --noconfirm --needed archiso git base-devel

# Step 2: Create work directory and copy base releng profile
echo "Setting up profile directory..."
mkdir -p "${PROFILE_DIR}"
cp -r /usr/share/archiso/configs/releng/* "${PROFILE_DIR}/"

# Step 3: Populate packages.x86_64
echo "Writing packages list..."
cat << EOF > "${PROFILE_DIR}/packages.x86_64"
# Base system
linux
linux-firmware
linux-headers
mkinitcpio
grub
efibootmgr
os-prober
systemd
systemd-sysvcompat

# Desktop: KDE Plasma
plasma-meta
kde-applications-meta
sddm
sddm-kcm

# Networking
networkmanager
networkmanager-openvpn
wireguard-tools

# Security
firejail
apparmor
ufw
tpm2-tools
sbctl
systemd-cryptenroll
cryptsetup
luksmeta

# Theming & Fonts
ttf-jetbrains-mono
ttf-rajdhani
noto-fonts
noto-fonts-emoji
papirus-icon-theme
kvantum
qt5ct
kvantum-theme-materia  # Base for dark theme

# AI & Dev
ollama
python
python-pip
git
neovim
kitty
vscode  # From AUR later

# Gaming & Compatibility
steam
lutris
wine
wine-gecko
wine-mono
proton-ge-custom-bin  # AUR
waydroid

# Boot & Utils
plymouth
plymouth-theme-spinner
htop
neofetch
fastfetch
btop
yay  # AUR helper

# Multimedia & Others
spotify-launcher  # AUR example
kdenlive
vlc
EOF

# Step 4: Populate profiledef.sh
echo "Writing profiledef.sh..."
cat << EOF > "${PROFILE_DIR}/profiledef.sh"
#!/usr/bin/env bash

iso_name="biker-os"
iso_label="BikerOS_v1_0"
iso_publisher="Itay Shmolovitz <itay@shmolovitz.com>"
iso_application="BikerOS Custom Distro"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
work_dir="work"
out_dir="out"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito'
           'uefi-ia32.grub.esp' 'uefi-x64.grub.esp'
           'uefi-ia32.grub.eltorito' 'uefi-x64.grub.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86')
bootstrap_packages=()
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
)
EOF

# Step 5: Populate pacman.conf (enable multilib for wine/steam)
echo "Writing pacman.conf..."
cat << EOF > "${PROFILE_DIR}/pacman.conf"
[options]
HoldPkg     = pacman glibc
Architecture = auto
CheckSpace
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF

# Step 6: Populate customize_airootfs.sh - The main customization script
echo "Writing customize_airootfs.sh..."
cat << EOF > "${PROFILE_DIR}/airootfs/root/customize_airootfs.sh"
#!/usr/bin/env bash

set -e -u -x

# Update system
pacman -Syu --noconfirm

# Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Syu --noconfirm

# Install AUR helper (yay)
pacman -S --noconfirm --needed base-devel git
su -c 'git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si --noconfirm' -s /bin/sh nobody
rm -rf /tmp/yay

# Install AUR packages
yay -S --noconfirm heroic-games-launcher-bin proton-ge-custom-bin spotify-launcher visual-studio-code-bin

# Enable services
systemctl enable sddm
systemctl enable NetworkManager
systemctl enable apparmor
systemctl enable ufw

# Basic WireGuard setup (add your config later)
mkdir -p /etc/wireguard
# Example: echo "[Interface]\nAddress = 10.0.0.1/24\nPrivateKey = EXAMPLE" > /etc/wireguard/wg0.conf
# systemctl enable wg-quick@wg0

# Plymouth boot splash
plymouth-set-default-theme -R spinner
sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block encrypt plymouth filesystems keyboard fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

# Basic KDE theming via skel (for new users)
mkdir -p /etc/skel/.config
cat << THEME > /etc/skel/.config/plasmarc
[General]
ColorScheme=BreezeDark
accentColor=#FF5500
EOF

# Basic KDE color scheme file
mkdir -p /etc/skel/.local/share/color-schemes
cat << COLORS > /etc/skel/.local/share/color-schemes/BikerOS.colors
[ColorEffects:Disabled]
Color=#0A0A0A
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
Color=#1A1A2E
ColorAmount=0.025
ColorEffect=0
ContrastAmount=0.1
ContrastEffect=0
IntensityAmount=0
IntensityEffect=0

[Colors:Button]
BackgroundAlternate=#0A0A0A
BackgroundNormal=#0A0A0A
DecorationFocus=#FF5500
DecorationHover=#FFD700
ForegroundActive=#EFEFEF
ForegroundInactive=#EFEFEF
ForegroundLink=#FF5500
ForegroundNegative=#FFD700
ForegroundNeutral=#EFEFEF
ForegroundNormal=#EFEFEF
ForegroundPositive=#FF5500
ForegroundVisited=#FF5500

[Colors:Selection]
BackgroundAlternate=#FF5500
BackgroundNormal=#FF5500
DecorationFocus=#FF5500
DecorationHover=#FFD700
ForegroundActive=#EFEFEF
ForegroundInactive=#EFEFEF
ForegroundLink=#0A0A0A
ForegroundNegative=#0A0A0A
ForegroundNeutral=#EFEFEF
ForegroundNormal=#EFEFEF
ForegroundPositive=#0A0A0A
ForegroundVisited=#0A0A0A

[Colors:Tooltip]
BackgroundAlternate=#0A0A0A
BackgroundNormal=#0A0A0A
DecorationFocus=#FF5500
DecorationHover=#FFD700
ForegroundActive=#EFEFEF
ForegroundInactive=#EFEFEF
ForegroundLink=#FF5500
ForegroundNegative=#FFD700
ForegroundNeutral=#EFEFEF
ForegroundNormal=#EFEFEF
ForegroundPositive=#FF5500
ForegroundVisited=#FF5500

[Colors:View]
BackgroundAlternate=#0A0A0A
BackgroundNormal=#0A0A0A
DecorationFocus=#FF5500
DecorationHover=#FFD700
ForegroundActive=#EFEFEF
ForegroundInactive=#EFEFEF
ForegroundLink=#FF5500
ForegroundNegative=#FFD700
ForegroundNeutral=#EFEFEF
ForegroundNormal=#EFEFEF
ForegroundPositive=#FF5500
ForegroundVisited=#FF5500

[Colors:Window]
BackgroundAlternate=#0A0A0A
BackgroundNormal=#0A0A0A
DecorationFocus=#FF5500
DecorationHover=#FFD700
ForegroundActive=#EFEFEF
ForegroundInactive=#EFEFEF
ForegroundLink=#FF5500
ForegroundNegative=#FFD700
ForegroundNeutral=#EFEFEF
ForegroundNormal=#EFEFEF
ForegroundPositive=#FF5500
ForegroundVisited=#FF5500

[Colors:Complementary]
BackgroundAlternate=#1A1A2E
BackgroundNormal=#1A1A2E
DecorationFocus=#FF5500
DecorationHover=#FFD700
ForegroundActive=#EFEFEF
ForegroundInactive=#EFEFEF
ForegroundLink=#FF5500
ForegroundNegative=#FFD700
ForegroundNeutral=#EFEFEF
ForegroundNormal=#EFEFEF
ForegroundPositive=#FF5500
ForegroundVisited=#FF5500

[General]
Name=BikerOS
shading=0.9

[KDE]
contrast=0.2

[WM]
activeBackground=#0A0A0A
activeForeground=#EFEFEF
inactiveBackground=#1A1A2E
inactiveForeground=#EFEFEF
COLORS
THEME

# Fonts setup
cat << FONTS > /etc/skel/.config/fontconfig/fonts.conf
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <alias>
    <family>serif</family>
    <prefer><family>Rajdhani</family></prefer>
  </alias>
  <alias>
    <family>sans-serif</family>
    <prefer><family>Rajdhani</family></prefer>
  </alias>
  <alias>
    <family>monospace</family>
    <prefer><family>JetBrains Mono</family></prefer>
  </alias>
</fontconfig>
FONTS

# UFW basic firewall (all closed by default)
ufw default deny incoming
ufw default allow outgoing
ufw enable

# Clean up
pacman -Scc --noconfirm
rm -rf /var/cache/pacman/pkg/*

echo "BikerOS customization complete! After install, customize further."
EOF

# Make it executable
chmod +x "${PROFILE_DIR}/airootfs/root/customize_airootfs.sh"

# Step 7: Add basic skel for user (already in script above)

# Step 8: Build the ISO
echo "Building ISO... This may take 10-60 minutes."
cd "${PROFILE_DIR}"
sudo mkarchiso -v -w "${WORK_DIR}/work" -o "${OUT_DIR}" .
echo "ISO built! Find it at ${OUT_DIR}/${ISO_NAME}"

# Step 9: Cleanup (optional)
# rm -rf "${WORK_DIR}/work"

echo "Done! Boot the ISO in a VM to test. For full VISO AI, develop a separate app and add to /usr/share/applications."
echo "If errors, check logs or ask me for fixes. 🏍️💨"
