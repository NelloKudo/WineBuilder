# WineBuilder

**WineBuilder** is a script that makes it easy to build **Wine binaries**, including versions with custom patches, using Docker.

Prebuilt binaries are available on the [Releases page](https://github.com/NelloKudo/WineBuilder/releases).

## How it works

WineBuilder uses the Proton SDK (with a few changes) to build Wine inside a Docker container. This ensures great compatibility and feature completeness, and the resulting builds also work within the **Steam Linux Runtime**.

The `wine-builder` container is hosted on [Docker Hub](https://hub.docker.com/r/nellokudo/wine-builder) and built from the [winebuilder-image repository](https://github.com/NelloKudo/winebuilder-image).

### Build types

By default, the script creates **osu!-specific builds** with patches from [wine-osu-patches](https://github.com/whrvt/wine-osu-patches), also used in [osu-winello](https://github.com/NelloKudo/osu-winello).

Other build options:

- **Wine-Staging:** run `WINE_OSU=false ./build.sh`.
- **[wine-tkg](https://github.com/Kron4ek/wine-tkg)** by Kron4ek: run `WINE_OSU=false USE_TKG=true ./build.sh`.
- **[Wine-CachyOS](https://github.com/CachyOS/wine-cachyos):** run `WINE_OSU=false USE_CACHY=true ./build.sh`.
- **[Wine-EM](https://github.com/Etaash-mathamsetty/wine-valve)**: run `WINE_OSU=false USE_EM=true ./build.sh`.

More settings (build name, Wine branch, patchsets, WoW64 and more) can be tweaked in the configuration section at the top of `wine_builder.sh`.

**Custom patches:** to use your own patches in your builds, just place them in the `custompatches/` folder. When a patchset is used (like for the default osu! builds), those patches are applied *on top* of it, in alphabetical order.

## Workflows

WineBuilder currently provides two automated builds via [GitHub Actions](https://github.com/NelloKudo/WineBuilder/actions):

- [wine-osu-winello](https://github.com/NelloKudo/WineBuilder/actions/workflows/wine-osu-winello.yml): osu!-specific Wine builds with patches from [wine-osu-patches](https://github.com/whrvt/wine-osu-patches), built on new releases.
- [wine-staging-git](https://github.com/NelloKudo/WineBuilder/actions/workflows/wine-staging-git.yml): Wine-Staging builds based on master, built every 3 days (might fail sometimes when staging rebases are needed!)

## Requirements

Install the following packages using your system's package manager:

- `docker`
- `docker-buildx`

**Ubuntu/Debian:**

```bash
sudo apt install -y docker docker-buildx
```

**Arch Linux:**

```bash
sudo pacman -Sy --needed --noconfirm docker docker-buildx
```

**Fedora:**

```bash
sudo dnf install -y docker docker-buildx
```

After installing, add yourself to the Docker group and enable the Docker service:

```bash
sudo gpasswd -a $USER docker
sudo systemctl enable docker docker.socket
```

## Building Wine

Clone the repo and go into the folder:

```bash
git clone https://github.com/NelloKudo/WineBuilder.git
cd WineBuilder
```

Then run the build script:

```bash
./build.sh
```

The built Wine binaries will be saved in the same folder when it's done. 🎉
