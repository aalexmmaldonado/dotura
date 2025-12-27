<h1 align="center">dotura</h1>
<h4 align="center">Arch/MacOS setup and configuration</h4>

I have the unfortunate combination of having a goldfish memory with niche tastes.
`dotura` helps minimize the time between fresh installations and getting back to work.

## OS Installation

### Arch

It is unlikely that I can write a better installation guide than [the Arch Wiki](https://wiki.archlinux.org/title/Installation_guide).
However, we have written some (hopefully helpful) advice below to streamline an arch installation.

We made an `install.sh` script that guides you through creating a bootable USB drive from a Linux ISO.
Once you have downloaded the ISO file, you can create the live disk by running the following command.

```bash
sudo ./install.sh
```

This will prompt you to select your USB drive, the ISO file, and an optional configuration file.
We provide some sample config files for Arch and Ubuntu in the `config` directory of this repository.
(Note that the config files are tailored to my preferences; feel free to change it.)
Below is an example of a successfully running install script.

```text
[+] Detected OS: Darwin
[+] Listing external physical drives (macOS)...
/dev/disk4 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:     FDisk_partition_scheme                        *31.6 GB    disk4
   1:                 DOS_FAT_32 ARCH_202512             31.6 GB    disk4s1


Enter the DEVICE IDENTIFIER (e.g., 'disk2') to target.
WARNING: Ensure you pick the USB drive. This device will be ERASED.
Enter Device Node: disk4
[+] Selected Device: /dev/disk4
Path to ISO: ~/Downloads/archlinux-2025.12.01-x86_64.iso
[+] Using ISO: /Users/alex/Downloads/archlinux-2025.12.01-x86_64.iso
Optional path to config file (press Enter to skip): ./config/arch/arch-config.json

[!] WARNING: YOU ARE ABOUT TO WIPE /dev/disk4
Type 'yes' to proceed: yes
[+] Unmounting target device...
Unmount of all volumes on disk4 was successful
[+] Wiping and Formatting /dev/disk4 as FAT32...
[+] Partition Label: ARCH_202512
Forced unmount of all volumes on disk4 was successful
Started erase on disk4
Unmounting disk
Creating the partition map
Waiting for partitions to activate
Formatting disk4s1 as MS-DOS (FAT) with name ARCH_202512
512 bytes per physical sector
/dev/rdisk4s1: 61735424 sectors in 1929232 FAT32 clusters (16384 bytes/cluster)
bps=512 spc=32 res=32 nft=2 mid=0xf8 spt=32 hds=255 hid=2048 drv=0x80 bsec=61765632 bspf=15073 rdcl=2 infs=1 bkbs=6
Mounting disk
Finished erase on disk4
[+] Waiting for volume to mount...
[+] Volume mounted at /Volumes/ARCH_202512
[+] Extracting ISO contents to USB...
[+] Adding config file to USB root...
[+] Syncing buffers...
Unmount of all volumes on disk4 was successful
[+] Cleaning up...
[+] Success!
```

#### Loading Custom Configuration

There are a few extra steps to do if you chose to use a configuration file for Arch.

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

### MacOS

Let's be real, do we really need instructions for this?

## Before Cloning

It will probably be helpful to perform these tasks before trying to clone these repositories.
We assume you already have `git` installed so we can configure it.

```sh
git config --global user.name "Alex M. Maldonado"
git config --global user.email "alex@scient.ing"
```

```sh
ssh-keygen -f ~/.ssh/id_github -t ed25519 -C "alex@scient.ing"
```

After this, [add the public key to your GitHub account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account?tool=webui&platform=linux#adding-a-new-ssh-key-to-your-account).

```sh
cat ~/.ssh/id_github.pub
```

Go to [Settings -> SSH and GPG keys](https://github.com/settings/keys) and add a new SSH key.

To check SSH access to GitHub, you can run this command.

```sh
ssh -T git@github.com -i ~/.ssh/id_github
```

## dotura usage

Once you have SSH access to GitHub, you can now clone [this repository](https://github.com/aalexmmaldonado/dotura) and begin installation.

```sh
GIT_SSH_COMMAND="ssh -i ~/.ssh/id_github" git clone git@github.com:aalexmmaldonado/dotura.git && cd dotura
```

You can just run the `install.sh` script from here!
