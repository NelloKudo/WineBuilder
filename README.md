# WineBuilder

Fork of [Wine-Builds](https://github.com/Kron4ek/Wine-Builds) aimed at making **building Wine binaries** (eventually using custom patches) easier than ever.

You can find binaries built from this repo at [osu-winello](https://github.com/NelloKudo/osu-winello) 8)

## Builds description

The binaries built from this script use the same configuration as the [original repo](https://github.com/Kron4ek/Wine-Builds), therefore creating two **Ubuntu bootstraps** and building Wine using those. That means providing support for a wide range of distros, as long as **GLIBC>=2.27**.

**Custom patches** can be applied by simply copying those into the `custompatches` folder of the repo, the script will handle the rest itself.

`ccache` is also enabled by default.

## Requirements

Use your package manager to install the following dependencies: `git`, `autoconf`, `bubblewrap`, `perl`, `debootstrap`, `wget`, `ccache`, `bc`.

**You can use the following:**

**Ubuntu/Debian:** `sudo apt install -y git autoconf bubblewrap perl debootstrap wget ccache bc`

**Arch Linux:** `sudo pacman -Sy --needed  --noconfirm git autoconf bubblewrap perl debootstrap wget ccache bc`

**Fedora:** `sudo dnf install -y git autoconf bubblewrap perl debootstrap wget ccache bc`

## Building Wine

First of all, clone the repository and enter it with:

```
git clone https://github.com/NelloKudo/WineBuilder.git
cd WineBuilder
```

Once in the folder, run the following to create the containers:

This will probably take a while, so relax while you're at it and *watch some Mushoku Tensei* e.e

```
sudo ./create_ubuntu_bootstraps.sh
```
When it's done, you'll be ready to compile after customizing `build_wine.sh` with a simple command:

```
./build_wine.sh
```
You'll find the binaries in the same folder :)

## osu! builds support

Since I use this repo to build Wine binaries for  [osu-winello](https://github.com/NelloKudo/osu-winello), I added the variable `WINE_OSU` in `build_wine.sh` to specify whether to use the custom **winepulse.tar** file provided, necessary to apply **gonX's patch** from [ThePooN's Discord](https://discord.gg/dTBPae8Mqf).

If you don't need it, setting it to `false` will be enough :3

You can read more into the `build_wine.sh` file.

