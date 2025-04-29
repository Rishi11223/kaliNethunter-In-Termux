#!/data/data/com.termux/files/usr/bin/bash

# Colors
red='\033[1;31m'
green='\033[1;32m'
yellow='\033[1;33m'
blue='\033[1;34m'
reset='\033[0m'

# Variables
chroot="full"
DESTINATION="$HOME/kali-arm"
START_SCRIPT="$PREFIX/bin/startkali"
EXTRAARGS="--alternate"
ARCH=""
rootfs=""

# Functions
print_banner() {
    echo -e "${yellow}Installing Kali NetHunter in Termux (No Root)${reset}"
    echo -e "${blue}Author: Auto-Script by OpenAI (Based on Hax4Us)${reset}\n"
}

detect_arch() {
    case $(getprop ro.product.cpu.abi) in
        arm64-v8a) ARCH="arm64";;
        armeabi* ) ARCH="armhf";;
        *) echo -e "${red}[!] Unsupported architecture${reset}"; exit 1;;
    esac
    echo -e "${green}[✓] Detected architecture: $ARCH${reset}"
}

check_dependencies() {
    echo -e "${blue}[+] Checking and installing required packages...${reset}"
    for pkg in proot tar axel; do
        if ! command -v $pkg >/dev/null; then
            echo -e "${yellow}Installing $pkg...${reset}"
            pkg install -y $pkg || { echo -e "${red}Failed to install $pkg${reset}"; exit 1; }
        fi
    done
}

download_rootfs() {
    rootfs="kali-nethunter-rootfs-${chroot}-${ARCH}.tar.xz"
    URL="https://kali.download/nethunter-images/current/rootfs/$rootfs"

    cd $HOME

    if [ -f "$rootfs" ]; then
        echo -e "${yellow}[!] Existing rootfs found. Skipping download.${reset}"
    else
        echo -e "${blue}[+] Downloading NetHunter rootfs...${reset}"
        axel $EXTRAARGS "$URL" || { echo -e "${red}Download failed${reset}"; exit 1; }
    fi
}

verify_integrity() {
    echo -e "${blue}[+] Verifying file integrity...${reset}"
    sha_url="${URL}.sha512sum"
    axel -a "$sha_url" -o "${rootfs}.sha512sum"
    sha512sum -c "${rootfs}.sha512sum" || {
        echo -e "${red}Integrity check failed. Try deleting $rootfs and rerun.${reset}"
        exit 1
    }
}

extract_rootfs() {
    echo -e "${blue}[+] Extracting to $DESTINATION...${reset}"
    mkdir -p "$DESTINATION"
    proot --link2symlink tar -xf "$rootfs" -C "$DESTINATION" || {
        echo -e "${red}Extraction failed${reset}"
        exit 1
    }
}

create_launcher() {
    echo -e "${blue}[+] Creating startkali script...${reset}"
    cat > "$START_SCRIPT" <<- EOF
#!/data/data/com.termux/files/usr/bin/bash
unset LD_PRELOAD
proot \\
    --link2symlink \\
    -0 \\
    -r $DESTINATION \\
    -b /dev \\
    -b /proc \\
    -b /sdcard \\
    -b \$HOME \\
    -w /root \\
    \$PREFIX/bin/env -i \\
    HOME=/root \\
    TERM="\$TERM" \\
    LANG="C.UTF-8" \\
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \\
    /bin/bash --login
EOF
    chmod +x "$START_SCRIPT"
    echo -e "${green}[✓] You can now run Kali using: ${yellow}startkali${reset}"
}

setup_dns() {
    echo -e "${blue}[+] Setting up DNS resolvers...${reset}"
    echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > "$DESTINATION/etc/resolv.conf"
}

cleanup() {
    echo -e "${blue}[+] Cleaning up temporary files...${reset}"
    rm -f "$rootfs" "$rootfs.sha512sum"
}

# Run
print_banner
detect_arch
check_dependencies
download_rootfs
verify_integrity
extract_rootfs
create_launcher
setup_dns
cleanup

echo -e "${green}[✓] Kali NetHunter installed successfully!${reset}"
echo -e "${yellow}To start Kali, just type: ${blue}startkali${reset}\n"
