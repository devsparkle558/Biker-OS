FROM archlinux:latest

# Update and install build dependencies
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    archiso \
    git \
    base-devel \
    cmake \
    qt5-base \
    make \
    gcc \
    sudo \
    bash \
    grub \
    efibootmgr \
    libisoburn \
    mtools \
    dosfstools

# Create a non-root builder user
RUN useradd -m builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set working directory
WORKDIR /home/builder/Biker-OS

# Set the entrypoint to the build script
CMD ["/bin/bash", "scripts/build.sh"]
