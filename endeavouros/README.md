## ADDITIONAL CONFIGURATION FOR ENDEAVOUR OS

### POSSIBLY MISSING FIRMWARE ERROR
#### Intall missing firmwares qla1280, qla2xxx, qed, bfa, ast, aic94xx, wd719x, xhci_pci
`pacman -Syuq --noconfirm --noprogressbar --needed linux-firmware-qlogic ast-firmware aic94xx-firmware wd719x-firmware upd72020x-fw`


### NVIDIA LEGACY DRIVER INSTALLATION

#### Enable kernel-lts repo for legacy nvidia cards (390, 470)
`nvidia-inst --legacyrepo`

#### Dry run nvidia 390 driver install (Change parameters to 470 for 470 cards)
`nvidia-inst --series 390 -t`

#### If no errors, install nvidia 390 drivers (Change parameters to 470 for 470 cards)
`nvidia-inst --series 390`
#### Actual package insallation performed by nvidia-inst
`pacman -Syuq --noconfirm --noprogressbar --needed nvidia-390xx-dkms nvidia-390xx-utils nvidia-390xx-settings nvidia-installer-kernel-para`

#### Regenerate bootloader config
`grub-mkconfig -o /boot/grub/grub.cfg`


### UPDATE DEFAULT PROMPT TO COLORED FOR BASH
**Typeface:** 0 - Normal, 1 - Bold (Bright), 2 - Dim, 4 - Underlined

**Color:** 30 – Black, 31 – Red, 32 – Green, 33 – Yellow, 34 – Blue, 35 – Magenta, 36 – Cyan, 37 – Light gray (More details [here](https://misc.flogisoft.com/bash/tip_colors_and_formatting) and [here](https://www.howtogeek.com/307701/how-to-customize-and-colorize-your-bash-prompt/))

**One-line Prompt:**

`PS1='[\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]]\$ '`

**Two-line Prompt:**

`PS1='\[\033[;32m\]┌──(\[\033[1;32m\]\u\[\033[0;1m\]@\[\033[1;32m\]\h\[\033[;32m\])-[\[\033[0;1m\]\w\[\033[;32m\]]\n\[\033[;32m\]└─\[\033[1;32m\]\$\[\033[0m\] '`

### ENABLE TEXT HIGHLIGHTING IN nano BY ADDING FOLLOWING IN ~/.nanorc FILE
`include /usr/share/nano-syntax-highlighting/*.nanorc`
