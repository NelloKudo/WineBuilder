# WineBuilder

**WineBuilder** is a script that makes it easier to build **Wine binaries**, including versions with custom patches, using Docker.

You can find prebuilt binaries on the [Releases page](https://github.com/NelloKudo/WineBuilder/releases).

---

## Builds description

WineBuilder uses the latest Proton SDK (with a few changes) to build Wine inside a Docker container. This ensures great compatibility and feature completeness — including seamless usage within the **Steam Linux Runtime**.

By default, the script creates **osu!-specific builds**, with patches from [wine-osu-patches](https://github.com/whrvt/wine-osu-patches), also used in [osu-winello](https://github.com/NelloKudo/osu-winello). 

To build a regular Wine-Staging version instead, simply set **`WINE_OSU="false"`** in `wine_builder.sh`.

> **Custom patches:** To use your own patches in your custom builds, just place them in the `custompatches/` folder.
---

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

---

## Building Wine

First, clone the repo and go into the folder:

```bash
git clone https://github.com/NelloKudo/WineBuilder.git
cd WineBuilder
```

Then run the build script:

```bash
./build.sh
```

The built Wine binaries will be saved in the same folder when it's done. 🎉
