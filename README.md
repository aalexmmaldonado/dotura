<h1 align="center">dotura</h1>
<h4 align="center">Arch (btw) setup and configuration</h4>

I have the unfortunate combination of having a goldfish memory with niche tastes.
`dotura` helps minimize the time between fresh installations and getting back to work.

## Installation

It is unlikely that I am able to write a better installation guide than [the arch wiki](https://wiki.archlinux.org/title/Installation_guide).
However, there are a few ~mistakes~ things that will make the setup process smoother.

### Essential packages

**TL;DR:** Include the following packages when using `pacstrap`:

```bash
pacstrap -K /mnt grub efibootmgr networkmanager vim nano \
  helix sudo git pipewire pipewire-alsa pipewire-pulse \
  pipewire-jack wireplumber zsh zsh-completions \
  zsh-autosuggestions openssh
```

When using [pacstrap to install essential packages](https://wiki.archlinux.org/title/Installation_guide#Install_essential_packages), make sure you include [`networkmanager`](https://wiki.archlinux.org/title/NetworkManager).
Forgetting this step means booting back into your [live disk](https://wiki.archlinux.org/title/Installation_guide#Boot_the_live_environment) and installing it then.

TODO: Finish section by explaining why these extra packages are useful.
