# WineBuilder

Fork of [Wine-Builds](https://github.com/Kron4ek/Wine-Builds) aimed at making **building Wine binaries** (eventually using custom patches) easier than ever.

You can find binaries built from this repo on the releases page and (eventually) at [osu-winello](https://github.com/NelloKudo/osu-winello) 8)

## Builds description

The binaries create an **Ubuntu 20.04 Docker image** and build Wine using it. That means providing support for a wide range of distros, as long as **GLIBC>=2.31**.

**Custom patches** can be applied by simply copying those into the `custompatches` folder of the repo, and configuring the `PATCHSET` in `build_wine.sh` to use those instead of the ones from the [wine-osu-patches](https://github.com/whrvt/wine-osu-patches) repo.

## Requirements

Use your package manager to install the following dependencies: `docker` and `docker-buildx`.

**You can use the following:**

**Ubuntu/Debian:** `sudo apt install -y docker docker-buildx`

**Arch Linux:** `sudo pacman -Sy --needed --noconfirm docker docker-buildx`

**Fedora:** `sudo dnf install -y docker docker-buildx`

## Building Wine

First of all, clone the repository (or download it) and enter it with:

```
git clone https://github.com/NelloKudo/WineBuilder.git
cd WineBuilder
```

Once in the folder, run the following to create the Docker image and build Wine in it:

```
./build.sh
```

You'll find the binaries in the same folder :)

## osu! builds support (OUTDATED)

Instructions for building your own wine-osu binary are below:

- [Building wine-osu with custom patches](https://gist.github.com/NelloKudo/b6f6d48807548bd3cacd3018a1cadef5)

If you don't need it, setting it to `false` will be enough :3

You can read more into the `build_wine.sh` file.

