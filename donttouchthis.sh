#!/bin/bash

display_message() {
    whiptail --msgbox "$1" 10 60
}

check_and_install_deps() {
    local format="$1"
    local tool=""
    local pkg=""

    case "$format" in
        "FAT32") tool="mkfs.fat"; pkg="dosfstools";;
        "exFAT") tool="mkfs.exfat"; pkg="exfatprogs";;
        "NTFS") tool="mkfs.ntfs"; pkg="ntfs-3g";;
        "HFS+") tool="mkfs.hfsplus"; pkg="hfsprogs";;
        "APFS") tool="apfs-fuse"; pkg="apfs-fuse";;
    esac

    if ! command -v "$tool" &> /dev/null; then
        display_message "The required tool ($tool) is not installed. We will attempt to install it."
        if command -v pacman &> /dev/null; then
            if ! sudo pacman -S --noconfirm "$pkg"; then
                display_message "Failed to install dependencies with pacman. Please install '$pkg' manually."
                exit 1
            fi
        elif command -v apt-get &> /dev/null; then
            if ! sudo apt-get install -y "$pkg"; then
                display_message "Failed to install dependencies with apt-get. Please install '$pkg' manually."
                exit 1
            fi
        elif command -v dnf &> /dev/null; then
            if ! sudo dnf install -y "$pkg"; then
                 display_message "Failed to install dependencies with dnf. Please install '$pkg' manually."
                 exit 1
            fi
        else
            display_message "Could not determine package manager. Please install '$pkg' manually."
            exit 1
        fi
    fi
}

if [[ $EUID -ne 0 ]]; then
   display_message "This script must be run as root."
   exit 1
fi

if ! whiptail --yesno "⚠️ Are you aware that this tool will format a USB drive? All data on the selected drive will be permanently erased. Do you wish to continue?" 10 60; then
    exit 0
fi

usb_drives=$(lsblk -d -o NAME,SIZE,MODEL,RM | awk '$4=="1" {print $1, $2 " " $3}')

if [ -z "$usb_drives" ]; then
    display_message "No removable drives detected. Please ensure your drive is plugged in."
    exit 1
fi

chosen_drive=$(whiptail --title "Select a USB Drive" --menu "Choose a drive to format:" 20 78 15 --cancel-button "Exit" --ok-button "Select" \
    $(echo "$usb_drives" | awk '{print $1, $2 " " $3 " ("$4")"}') 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    exit 0
fi

chosen_format=$(whiptail --title "Select a File System Format" --menu "Choose a format for the drive:" 15 60 5 \
    "FAT32" "Standard compatibility" \
    "exFAT" "Modern format for large files" \
    "NTFS" "Windows compatibility" \
    "HFS+" "Apple compatibility (older Mac OS)" \
    "APFS" "Apple compatibility (modern Mac OS)" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    exit 0
fi

if ! whiptail --yesno "❗ Are you sure you want to format /dev/$chosen_drive with $chosen_format? This action is irreversible." 10 60; then
    exit 0
fi

check_and_install_deps "$chosen_format"

display_message "Starting the formatting process for /dev/$chosen_drive with $chosen_format..."

if [[ $(lsblk -l | grep "$chosen_drive" | grep -v "$chosen_drive"p) ]]; then
    sudo umount "/dev/$chosen_drive"* 2>/dev/null
fi

sudo parted -s "/dev/$chosen_drive" mklabel msdos
sudo parted -s "/dev/$chosen_drive" mkpart primary 0% 100%
sleep 2
partition_name=$(lsblk -p -o NAME "/dev/$chosen_drive" | grep -v "NAME" | tail -n 1)


case "$chosen_format" in
    "FAT32")
        sudo mkfs.fat -F 32 "$partition_name"
        ;;
    "exFAT")
        sudo mkfs.exfat "$partition_name"
        ;;
    "NTFS")
        sudo mkfs.ntfs -f "$partition_name"
        ;;
    "HFS+")
        sudo mkfs.hfsplus "$partition_name"
        ;;
    "APFS")
        display_message "APFS formatting is complex and requires specific tools. The 'apfs-fuse' package provides read-only support on Linux. For full functionality, it is recommended to format on a Mac. Script will exit."
        exit 1
        ;;
esac

display_message "✅ Formatting complete! Your USB drive has been formatted to $chosen_format."
