#!/usr/bin/env bash

# BikerOS / Custom Arch ISO Builder - Updated with your links
# Includes: VS Code, Brave, Notepad++ (Wine), Detect-It-Easy, LibreOffice, etc.
# Some repos cloned & basic setup (not full build for Electron/MaxKey etc.)

set -e

WORK_DIR="${HOME}/biker-custom-build"
PROFILE_DIR="${WORK_DIR}/custom-profile"
OUT_DIR="${WORK_DIR}/out"
ISO_NAME="BikerOS-Custom-v2-$(date +%Y%m%d).iso"

echo "מתקין כלים..."
sudo pacman -Syu --noconfirm --needed archiso git base-devel cmake make gcc

mkdir -p "${PROFILE_DIR}"
cp -r /usr/share/archiso/configs/releng/* "${PROFILE_DIR}/"

# packages.x86_64 - חבילות מובנות
cat << EOF > "${PROFILE_DIR}/packages.x86_64"
plasma-meta kde-applications-meta sddm networkmanager
code brave-browser virtualbox virtualbox-host-modules-arch
wine winetricks libreoffice-fresh git neovim kitty plymouth plymouth-theme-spinner
base-devel cmake gcc make  # לבניית דברים מ-GitHub
EOF

# profiledef.sh
cat << EOF > "${PROFILE_DIR}/profiledef.sh"
#!/usr/bin/env bash
iso_name="biker-custom"
iso_label="BikerCustom_v2"
iso_publisher="Itay Shmolovitz"
iso_application="BikerOS Custom ISO"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('uefi-x64.grub.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
EOF

# pacman.conf עם multilib (Wine)
cat << EOF > "${PROFILE_DIR}/pacman.conf"
[options]
Architecture = auto
CheckSpace
SigLevel = Required DatabaseOptional

[core] [extra] [multilib]
Include = /etc/pacman.d/mirrorlist
EOF

# customize_airootfs.sh - כאן הקסם: התקנה + clone + setup בסיסי
cat << 'EOF' > "${PROFILE_DIR}/airootfs/root/customize_airootfs.sh"
#!/usr/bin/env bash
set -e -u -x

pacman -Syu --noconfirm

# multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Syu --noconfirm

# yay להתקנת AUR
pacman -S --noconfirm --needed base-devel git
su -c 'git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si --noconfirm' -s /bin/sh nobody
rm -rf /tmp/yay

# AUR אם צריך (דוגמה)
yay -S --noconfirm github-desktop-bin  # GitHub Desktop

# Brave (אם לא ב-packages)
# curl -fsS https://dl.brave.com/install.sh | sh   ← אבל pacman עדיף

# VS Code deb/rpm לא רלוונטי - משתמשים בחבילה code

# Notepad++ via Wine
echo "t" | winetricks notepadplus

# Clone repos & basic setup
cd /opt
git clone https://github.com/horsicq/Detect-It-Easy.git die
cd die && qmake && make -j$(nproc) || echo "DiE build failed - install Qt manually later"

git clone https://github.com/k-water/electron-filesystem.git electron-fs
cd electron-fs && npm install && npm run build || echo "Electron FS build later"

# ghc::filesystem - lib, לא אפליקציה - דוגמה clone
git clone https://github.com/gulrak/filesystem.git ghc-fs

# Microsoft365DSC - PowerShell tool (לא Office!)
# git clone https://github.com/microsoft/Microsoft365DSC.git
# cd Microsoft365DSC && ./install.ps1 || echo "M365DSC setup later"

# LibreOffice as M365 alternative
# Already in packages

# Services
systemctl enable sddm NetworkManager

# Plymouth
plymouth-set-default-theme -R spinner
sed -i 's/HOOKS=(base udev ...)/HOOKS=(base udev ... plymouth ...)/' /etc/mkinitcpio.conf
mkinitcpio -P

# Basic dark/orange theme
mkdir -p /etc/skel/.config
echo -e "[General]\nColorScheme=BreezeDark\naccentColor=#FF5500" > /etc/skel/.config/plasmarc

echo "Customization done. Some builds need manual fix after install (Qt/npm/etc)."
EOF

chmod +x "${PROFILE_DIR}/airootfs/root/customize_airootfs.sh"

# Build!
cd "${PROFILE_DIR}"
sudo mkarchiso -v -w "${WORK_DIR}/work" -o "${OUT_DIR}" .

echo "ISO מוכן כאן: ${OUT_DIR}/${ISO_NAME}"
echo "בדוק ב-VirtualBox. אחרי התקנה – הרץ sudo pacman -Syu && cd /opt/* כדי לבנות/להריץ את מה שצריך."