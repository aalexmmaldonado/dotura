<h1 align="center">dotura</h1>
<h4 align="center">Arch/MacOS setup and configuration</h4>

I have the unfortunate combination of having a goldfish memory with niche tastes.
`dotura` helps minimize the time between fresh installations and getting back to work.

## OS Installation

### Arch

It is unlikely that I can write a better installation guide than [the Arch Wiki](https://wiki.archlinux.org/title/Installation_guide).
However, we have written some (hopefully helpful) advice below to streamline an arch installation.

#### Making a live USB

We made an `install.sh` script that guides you through creating a bootable USB drive from a Linux ISO.
Once you have downloaded the ISO file, you can create the live disk by running the following command.

```bash
sudo ./install.sh
```

This will prompt you to select your USB drive, the ISO file, and an optional configuration file.
We provide some sample config files for Arch and Ubuntu in the `config` directory of this repository.
(Note that the config files are tailored to my preferences; feel free to change it.)

#### Loading custom configurations

There are a few extra steps if you choose to use a configuration file for Arch.

Once you have booted into the live Arch environment, the USB drive is not automatically mounted for file access.
You must manually mount the partition to retrieve your `archinstall` configuration file.

First, ensure you have an active internet connection (e.g., `ping archlinux.org`).
Then, identify the device node of your USB drive.
Look for the partition labeled `ARCH_YYYYMM` (or `INSTALLER`) with a filesystem size matching your thumb drive.

```bash
lsblk -f
```

_Note the device path, for example: `/dev/sdb1`. We will be using `/dev/sbd1/` as a placeholder. Make sure to change this to your path!_

Create a temporary directory and mount the USB partition containing your config file.

```bash
mkdir -p /tmp/usb
mount /dev/sdb1 /tmp/usb
```

Copy the configuration file to the live user's home directory to keep things clean, then unmount the drive.

```bash
cp /tmp/usb/arch-config.json ~/arch-config.json
umount /tmp/usb
```

Pass the local path to `archinstall` to begin the automated setup.

```bash
archinstall --config ~/arch-config.json
```

Note that Disk configuration and Authentication are not included in the configuration file; make sure to do these manually.

#### NVIDIA GPUs

Using Arch with NVIDIA GPUs will be a little more complicated.
You will likely need to disable [Kernel Mode Setting (KMS)](https://wiki.archlinux.org/title/Kernel_mode_setting) when creating the Live USB.
After installation, you will also need to turn off KMS manually using the following steps.

1. Press `e` when you see the bootloader after turning on your computer.
2. Go to the very end of the line and add `nomodeset nouveau.modeset=0`.
3. Press Enter.

Once you are logged in, you need to install the following packages to support your NVIDIA GPU.

```bash
sudo pacman -Syu nvidia-open nvidia-utils
```

After installation, please restart your computer and verify it boots correctly _without_ turning off KMS.
If it still goes to a black screen after seeing the `uevents triggering` line, then turn off KMS again and consult the [Arch wiki](https://wiki.archlinux.org/title/NVIDIA).

### MacOS

Let's be real, do we really need instructions for this?

## dotura usage

Clone [this repository](https://github.com/aalexmmaldonado/dotura) and begin installation.
You can just run the `setup.sh` script from here!
