#!/usr/bin/env bash

# BikerOS Final Builder Script - RiderCore v1.0 MVP (2026)
# Combines previous codes + realistic features from blueprint
# Features in ISO:
#   - Arch + KDE Plasma
#   - Dark theme + #FF5500 accent + Rajdhani / JetBrains Mono fonts
#   - Packages: WireGuard, Firejail, AppArmor, Ollama, Waydroid, Wine/Proton, Steam etc.
#   - Plymouth splash (spinner - custom visor later)
#   - Services enabled
#   - skel configs for new users
# Limitations noted in comments

set -e

WORK_DIR="${HOME}/bikeros-final"
PROFILE_DIR="${WORK_DIR}/rider-profile"
OUT_DIR="${WORK_DIR}/out"
ISO_NAME="BikerOS-RiderCore-v1.0-$(date +%Y%m%d).iso"

echo "מתקין archiso + deps..."
sudo pacman -Syu --noconfirm --needed archiso git base-devel cmake qt5-base

mkdir -p "${PROFILE_DIR}"
cp -r /usr/share/archiso/configs/releng/* "${PROFILE_DIR}/"

# packages.x86_64 - core + your blueprint apps
cat << EOF > "${PROFILE_DIR}/packages.x86_64"
linux linux-firmware linux-headers mkinitcpio grub efibootmgr systemd systemd-sysvcompat
plasma-meta kde-applications-meta sddm networkmanager pipewire wireplumber
wireguard-tools firejail apparmor ufw tpm2-tools sbctl cryptsetup luksmeta
ollama waydroid steam lutris heroic-games-launcher-bin retroarch
wine winetricks proton-ge-custom-bin kdenlive vlc kitty neovim git docker
ttf-rajdhani ttf-jetbrains-mono noto-fonts papirus-icon-theme kvantum qt5ct
plymouth plymouth-theme-spinner htop neofetch fastfetch btop
EOF

# profiledef.sh
cat << EOF > "${PROFILE_DIR}/profiledef.sh"
#!/usr/bin/env bash
iso_name="bikeros-ridercore"
iso_label="BikerOS_RiderCore_v1"
iso_publisher="Itay Shmolovitz <@YSmwlbyz89021>"
iso_application="BikerOS - Cockpit for Riders"
iso_version="1.0"
install_dir="arch"
buildmodes=('iso')
bootmodes=('uefi-x64.grub.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
EOF

# pacman.conf - multilib for Wine/Proton
cat << EOF > "${PROFILE_DIR}/pacman.conf"
[options]
Architecture = auto
CheckSpace
SigLevel = Required DatabaseOptional

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF

# customize_airootfs.sh - main magic
cat << 'EOF' > "${PROFILE_DIR}/airootfs/root/customize_airootfs.sh"
#!/usr/bin/env bash
set -e -u -x

pacman -Syu --noconfirm

# Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Syu --noconfirm

# Install yay for AUR
pacman -S --noconfirm --needed base-devel git
su -c 'git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si --noconfirm' -s /bin/sh nobody
rm -rf /tmp/yay

# AUR extras
yay -S --noconfirm proton-ge-custom-bin heroic-games-launcher-bin

# Enable services
systemctl enable sddm NetworkManager apparmor ufw

# Plymouth basic (visor animation needs custom theme dev later)
plymouth-set-default-theme -R spinner
sed -i 's/HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont plymouth block filesystems fsck)/HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont plymouth encrypt block filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

# Firewall default closed
ufw default deny incoming
ufw default allow outgoing
ufw --force enable

# HelmetUI basic: dark + #FF5500 accent + fonts
mkdir -p /etc/skel/.config /etc/skel/.local/share/color-schemes /etc/skel/.local/share/plasma/desktoptheme

# Simple color scheme file
cat << COLORS > /etc/skel/.local/share/color-schemes/BikerOS.colors
[General]
Name=BikerOS Dark Orange
accentColor=#FF5500
[Colors:Selection]
BackgroundNormal=#FF5500
ForegroundNormal=#EFEFEF
[Colors:Window]
BackgroundNormal=#0A0A0A
ForegroundNormal=#EFEFEF
COLORS

# plasmarc for Plasma
cat << PLASMA > /etc/skel/.config/plasmarc
[General]
ColorScheme=BikerOS
PLASMA

# Fonts config
cat << FONTS > /etc/skel/.config/fontconfig/fonts.conf
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <alias><family>sans-serif</family><prefer><family>Rajdhani</family></prefer></alias>
  <alias><family>serif</family><prefer><family>Rajdhani</family></prefer></alias>
  <alias><family>monospace</family><prefer><family>JetBrains Mono</family></prefer></alias>
</fontconfig>
FONTS

echo "BikerOS MVP ready!"
echo "Post-install steps:"
echo "1. sudo btrfs subvolume create /var (if btrfs) or similar for /var"
echo "2. Setup LUKS + TPM: systemd-cryptenroll --tpm2-device=auto ..."
echo "3. Read-only root: look into bootc / ashos or manual bind-mount"
echo "4. VISO AI: develop Electron/Python sidebar + Ollama/Claude/Gemini"
echo "5. Custom visor Plymouth: create theme with images/animations"
echo "6. Dynamic wallpapers: use Plasma built-in or komorebi"
EOF

chmod +x "${PROFILE_DIR}/airootfs/root/customize_airootfs.sh"

# Build the ISO
cd "${PROFILE_DIR}"
sudo mkarchiso -v -w /tmp/archiso-tmp -o "${OUT_DIR}" .

echo "======================================"
echo "BikerOS ISO מוכן כאן: ${OUT_DIR}/${ISO_NAME}"
echo "הרץ ב-VirtualBox / qemu-system-x86_64 -cdrom ..."
echo "זה MVP – להתקנה מלאה (atomic / visor / VISO AI) תמשיך לפתח אחרי ההתקנה."
echo "🏍️ It's alive! Now ride safe. 💨"