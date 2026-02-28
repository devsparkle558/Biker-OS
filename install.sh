#!/bin/bash

# BikerOS Installation Script - Arch Linux

# Set timezone
timedatectl set-timezone Your/Timezone  # Replace with your timezone

# Update system
pacman -Syu --noconfirm

# Install necessary packages
pacman -S --noconfirm linux linux-firmware base base-devel

# Disk Partitioning (modify /dev/sda as needed)
echo "Partitioning the disk..."
# Caution: The following commands will erase data! Adjust according to needs.
parted /dev/sda --script mklabel gpt
parted /dev/sda --script mkpart primary 1MiB 100MiB           # Boot partition
parted /dev/sda --script mkpart primary 100MiB 100%          # Root partition

# Format partitions
echo "Formatting partitions..."
mkfs.fat -F32 /dev/sda1                              # Boot partition
cryptsetup luksFormat /dev/sda2                      # Root partition
cryptsetup open /dev/sda2 cryptroot                  # Unlock LUKS device

# Format encrypted partition
mkfs.ext4 /dev/mapper/cryptroot                       # Filesystem on the encrypted partition

# Mount partitions
echo "Mounting partitions..."
mount /dev/mapper/cryptroot /mnt                      # Mount root
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot                              # Mount boot

# Install base system
echo "Installing base system..."
pacstrap /mnt base linux linux-firmware vim nano

# Generate fstab
echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the new system
echo "Entering the new system..."
arch-chroot /mnt /bin/bash <<EOF

# Set up timezone
ln -sf /usr/share/zoneinfo/Your/Timezone /etc/localtime  # Replace with your timezone
hwclock --systohc

# Localization
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Hostname
echo "bikeros" > /etc/hostname
cat <<EOF2 >> /etc/hosts
127.0.0.1	localhost
::1		localhost
127.0.1.1	bikeros.localdomain	bikeros
EOF2

# Install network tools
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager

# Install KDE Plasma
pacman -S --noconfirm plasma kde-applications sddm
systemctl enable sddm

# Set root password
echo "Set root password:"
passwd

# Exit chroot
exit
EOF

# Unmount partitions
echo "Unmounting partitions..."
umount -R /mnt

echo "Installation complete. Reboot the system.
