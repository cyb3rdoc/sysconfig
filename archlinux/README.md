## INSTALL ARCH LINUX - DUAL BOOT WITH WINDOWS & BIOS/MBR

### PRE-REQUISITES

1. Already installed Windows
2. Separate partition for Arch Linux install
3. Separate partition for swap, Equal to RAM or more
4. Optional separate partition for home

Paritions can be created using GParted Live ISO.

### ARCH INSTALLATION - BOOT FROM ARCH ISO OR LIVE USB

Connect to WiFi using `wifi-menu` command and confirm connectivity with `ping -c5 www.google.com`.

Check parition details with `fdisk -l` and make a note of paritions.

We will use below examples:
1. Windows - /dev/sda1
2. Root - /dev/sda2
3. swap - /dev/sda3
4. home - /dev/sda4

#### Mount partitions:

```
mkswap /dev/sda3
swapon /dev/sda3
mount /dev/sda2 /mnt
```

#### Install Arch base packages: `pacstrap -i /mnt base nano`

Mount (optional) home partition: `mount /dev/sda4 /mnt/home`

Generate fstab to mount partitions on reboot: `genfstab -U /mnt >> /mnt/etc/fstab`

Chroot to newly installed Arch for further setup: `arch-chroot /mnt`

Set system locale: `nano /etc/locale.gen`

Uncomment the language of your choice and save the file using `Ctrl+O` then close with `Ctrl+X`.

Generate system locale: `locale-gen`

Create locale configuration file (As per language selection): `echo "LANG=en_US.UTF-8" > /etc/locale.conf`

Select timezone: `tzselect`

Set localtime: `ln -s /usr/share/zoneinfo/Region/City /etc/localtime`

#### Install Linux kernel:
`pacman -S intel-ucode linux linux-firmware`

(linux-lts for LTS kernel, amd-ucode for AMD systems; Install headers required for VirtualBox - linux-headers or linux-lts-headers)

#### Install bootloader to HDD - /dev/sda:
```
pacman -S grub os-prober ntfs-3g
grub-install --target=i386-pc /dev/sda
```

Enable os-prober for dual-boot: Edit file /etc/default/grub and uncomment the line GRUB_DISABLE_OS_PROBER=false

Generate grub-config: `grub-mkconfig -o /boot/grub/grub.cfg`

#### Final Touch Ups:

Set root password: `passwd`

Hostname: `echo MyComputerName > /etc/hostname`

Hosts file: `nano /etc/hosts` and add following
```
127.0.0.1 localhost
::1       localhost
127.0.0.1 MyComputerName
```

Install sudo: `pacman -S sudo`

Create New User: `useradd -m -G wheel,storage,power YourNewUser`

Set New User Password: `passwd YourNewUser`

Allow `wheel` group to use `sudo`:

`EDITOR=nano visudo` and uncomment the line `%wheel ALL=(ALL) ALL`. Save the file with `Ctrl+O` and `Ctrl+X`.

#### Install Desktop Environment:

Install video driver:
```
# For nVidia (newer) video cards - proprietary: pacman -S nvidia
# For nVidia (older) video cards - opensource: pacman -S xf86-video-nouveau
# For AMD video cards: pacman -S xf86-video-amdgpu
# For ATI video cards: pacman -S xf86-video-ati
# For Intel video cards: pacman -S xf86-video-intel
```

Install video server: `pacman -S xorg xorg-server`

Install KDE Plasma desktop environment & basic apps: `pacman -S plasma networkmanager pipewire konsole dolphin firefox wget`

Enable Networking: `systemctl enable NetworkManager.service`

Enable Graphical Interface: `systemctl enable sddm.service`

Go back to live ISO prompt: `exit`

Shutdown System: `shutdown now`

Remove Live ISO medium and start the system. You will be greeted with grub menu followed by Arch login screen!

Optional apps: `pacman -S firewalld gwenview okular kate kcalc kdeconnect cups hplip-lite skanlite spectacle nano-syntax-highlighting neofetch onlyoffice-bin aspell aspell-en dolphin-plugins ark p7zip unarchiver powertop usb_modeswitch yakuake`

Enable syntax highlighting for nano: `echo "include /usr/share/nano-syntax-highlighting/*.nanorc" > ~/.nanorc`

### Install NVIDIA Legacy Drivers through `kernel-lts` unofficial repo:

Import Key ID:
```
sudo pacman-key --keyserver hkps://keyserver.ubuntu.com --recv-key 76C6E477042BFE985CC220BD9C08A255442FAFF0
sudo pacman-key --lsign 76C6E477042BFE985CC220BD9C08A255442FAFF0
```

Add following to `/etc/pacman.conf`
```
[kernel-lts]
Server = https://repo.m2x.dev/current/$repo/$arch
```

Install NVIDIA drivers:

`pacman -S nvidia-390xx-dkms nvidia-390xx-utils nvidia-390xx-settings`

Re-generate grub-config: `grub-mkconfig -o /boot/grub/grub.cfg`
