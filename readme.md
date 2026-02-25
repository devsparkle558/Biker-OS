BikerOS is a custom, performance-tuned Arch Linux distribution designed as a "Cockpit for Riders". It merges a high-octane aesthetic with a robust suite of tools for gaming, development, and local AI processing.
🏍️ Vision
Built for enthusiasts who demand speed and security, BikerOS (RiderCore) provides an atomic-ready environment with a unique "HelmetUI" aesthetic. It transitions from a daily driver to a high-performance workstation with ease, featuring deep integration for local AI models and a hardened security posture.
🛠️ Key Features
Desktop Environment: KDE Plasma customized with a dark theme and #FF5500 orange accents.

Typography: Professional-grade fonts including Rajdhani for UI and JetBrains Mono for terminal/coding.

AI Integrated: Pre-installed with Ollama for local LLM orchestration.

Hardened Security: Built-in AppArmor, Firejail, and UFW (firewall) configured to deny incoming traffic by default.

Gaming Ready: Includes Steam, Lutris, Heroic Games Launcher, and Proton-GE out of the box.

Compatibility: Full Wine and Waydroid support for running Windows and Android applications.

Boot Experience: Custom Plymouth splash screen (spinner) for a seamless transition from BIOS to Desktop.
📦 Core Stack
Category,Tools
Base,Arch Linux (Rolling Release)
Kernel,Linux Kernel with Headers
Shell/Terminal,Kitty + Neovim
Browsing,Brave Browser
Dev Tools,"VS Code, Git, Docker, Python"
Filesystem,Btrfs/LUKS support with TPM2 integration
🚀 Building the ISO
The project includes automated build scripts to generate a fresh .iso image using archiso.

Clone the Repository:
git clone https://github.com/devsparkle558/BikerOS.git
cd BikerOS
Make the script executable:
chmod +x biker-os-builder-final.sh
Run the builder:
./biker-os-builder-final.sh
Note: This requires an Arch-based host system and root privileges.
🚧 Roadmap (MVP 1.0)
[ ] VISO AI: Development of an Electron/Python sidebar for real-time AI assistance.

[ ] Custom Visor: Upgrading the Plymouth splash to a custom-designed biker visor animation.

[ ] Atomic Updates: Implementation of read-only root filesystems via bootc or ashos.
Developer: Itay Shmolovitz+ Grok 

Version: 1.0 (2026)