# iwlwifi-dkms

Patched iwlwifi dkms module.

## Disclaimer

This project is for research purposes only.

You are fully responsible for compliance with local regulations.

## Installation

```bash
# Maually build from source
makepkg -si
# Or install prebuilt package from release
sudo pacman -U iwlwifi-dkms-7.x.x-1-any.pkg.tar.zst
```

## Usage

For older network cards, use `lar_disable=1` option:
```bash
echo "options iwlwifi lar_disable=Y" | sudo tee /etc/modprobe.d/iwlwifi.conf
```

For newer network cards, use `force_mcc=<COUNTRY>` option:
```bash
echo "options iwlwifi force_mcc=CN" | sudo tee /etc/modprobe.d/iwlwifi.conf
```

## Reference

- https://github.com/TenkyuChimata/linux-wireless-reg-unlocked
- https://aur.archlinux.org/packages/iwlwifi-lar-disable-dkms
- https://gitee.com/tianqi256/iwlwifi-force-mcc
