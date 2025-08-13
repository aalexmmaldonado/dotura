<h1 align="center">dotura</h1>
<h4 align="center">Arch/MacOS setup and configuration</h4>

I have the unfortunate combination of having a goldfish memory with niche tastes.
`dotura` helps minimize the time between fresh installations and getting back to work.

## OS Installation

### Arch

It is unlikely that I am able to write a better installation guide than [the arch wiki](https://wiki.archlinux.org/title/Installation_guide).
However, there are a few ~mistakes~ things that will make the setup process smoother.

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
