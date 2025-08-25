# USB-Formatter-Linux
A usb formatter in linux Supported format [FAT32, exFAT, NTFS, APFS, and HFS+]

```bash
git clone https://github.com/CtorW/USB-Formatter-Linux.git ~/donttouch
cd ~/donttouch && chmod +x donttouchthis.sh && sudo ./donttouchthis.sh
```
Dependencies

FAT32: Requires `dosfstools`

exFAT: Requires `exfatprogs`

NTFS: Requires `ntfs-3g`

HFS+: Requires `hfsplus`

APFS: `apfs-fuse`

TUI: `whiptail`
