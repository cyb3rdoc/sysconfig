# Intall missing firmwares qla1280, qla2xxx, qed, bfa, aic94xx, wd719x, xhci_pci
pacman -Syuq --noconfirm --noprogressbar --needed linux-firmware-qlogic aic94xx-firmware wd719x-firmware upd72020x-fw
# Enable kernel-lts repo for legacy nvidia cards (390, 470)
nvidia-inst --legacyrepo
# Dry run nvidia 390 driver install (Change parameters to 470 for 470 cards)
nvidia-inst --series 390 -t
# If no errors, install nvidia 390 drivers (Change parameters to 470 for 470 cards)
nvidia-inst --series 390
#pacman -Syuq --noconfirm --noprogressbar --needed nvidia-390xx-dkms nvidia-390xx-utils nvidia-390xx-settings nvidia-installer-kernel-para
# Regenerate bootloader config
grub-mkconfig -o /boot/grub/grub.cfg
