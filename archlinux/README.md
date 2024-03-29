## INSTALL ARCH LINUX - DUAL BOOT WITH WINDOWS & UEFI/GPT

### PRE-REQUISITES

1. Already installed Windows
2. Separate partition for Arch Linux
3. Separate partition for swap, Equal to RAM or more
4. Optional separate partition for home

Paritions can be created in advance using GParted Live ISO or using `cfdisk` during Arch installation.

### ARCH INSTALLATION - BOOT FROM ARCH ISO OR LIVE USB

Connect to WiFi using `iwctl` command (iwctl > device list > station DEVICE scan > station DEVICE get-networks > station DEVICE connect SSID).
Confirm connectivity with `ping -c5 www.google.com`.

#### Update the system clock

`timedatectl set-ntp true`

#### Check partition details

Check parition details with `fdisk -l` and make a note of paritions.

We will use below examples:

1. EFI - /dev/sda1
2. Windows - /dev/sda2
3. Root - /dev/sda3 (ext4 - `mkfs.ext4 /dev/sda3`)
4. swap - /dev/sda4
5. home - /dev/sda5 (Optional: ext4 - `mkfs.ext4 /dev/sda5`)

#### Mount partitions:

```
mount /dev/sda3 /mnt
mkswap /dev/sda4
swapon /dev/sda4
```

#### Install Arch base packages: `pacstrap -i /mnt base nano`

Mount (optional) home partition: `mount /dev/sda5 /mnt/home`

Generate fstab to mount partitions on reboot: `genfstab -U /mnt >> /mnt/etc/fstab`

Chroot to newly installed Arch for further setup: `arch-chroot /mnt`

Set system locale: `nano /etc/locale.gen`

Uncomment the language of your choice (e.g. en_US.UTF-8) and save the file using `Ctrl+O` then close with `Ctrl+X`.

Generate system locale: `locale-gen`

Create locale configuration file (As per language selection): `echo "LANG=en_US.UTF-8" > /etc/locale.conf`

Select timezone: `tzselect`

Set localtime: `ln -sf /usr/share/zoneinfo/Region/City /etc/localtime`

#### Install Linux LTS kernel:

`pacman -S intel-ucode linux-lts linux-firmware`

(linux for latest Linux kernel, amd-ucode for AMD systems; Install headers required for VirtualBox - linux-headers or linux-lts-headers)

#### Install bootloader and other required tools:

`pacman -S grub efibootmgr dosfstools os-prober mtools ntfs-3g`

#### Create EFI directory and mount EFI partition created during Windows installtion:

```
mkdir /boot/EFI
mount /dev/sda1 /boot/EFI
```

#### Install and configure grub

`grub-install –-target=x86_64-efi --bootloader-id=grub_uefi –-recheck`

Enable os-prober for dual-boot: Edit file /etc/default/grub and uncomment the line GRUB_DISABLE_OS_PROBER=false

Generate grub-config: `grub-mkconfig -o /boot/grub/grub.cfg`

#### Final Touch Ups:

Set root password: `passwd`

Hostname: `echo MyComputerName > /etc/hostname`

Hosts file: `nano /etc/hosts` and add following

```
127.0.0.1 localhost
::1       localhost
127.0.1.1 MyComputerName
```

Install sudo: `pacman -S sudo`

Create New User: `useradd -m -g users -G wheel,storage,power YourNewUser`

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

Optional apps: `pacman -S firewalld gwenview okular kate kcalc kdeconnect cups hplip-lite skanlite spectacle nano-syntax-highlighting neofetch onlyoffice-bin aspell aspell-en dolphin-plugins ark p7zip unarchiver powertop usb_modeswitch usbutils yakuake`

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

Install NVIDIA drivers: `pacman -S nvidia-390xx-dkms nvidia-390xx-utils nvidia-390xx-settings`

Re-generate grub-config: `grub-mkconfig -o /boot/grub/grub.cfg`
