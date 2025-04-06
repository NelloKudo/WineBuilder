# WineBuilder

**WineBuilder** is a script that makes it easier to build **Wine binaries**, including versions with custom patches, using Docker.

You can find prebuilt binaries on the [Releases page](https://github.com/NelloKudo/WineBuilder/releases).

---

## Builds description

WineBuilder uses the latest Proton SDK (with a few changes) to build Wine inside a Docker container. This ensures great compatibility and feature completeness — including seamless usage within the **Steam Linux Runtime**.
There are currently two build scripts available:

- **`build_osu_wine.sh`** (default): Builds a version of Wine made for **osu!stable**, with patches from [wine-osu-patches](https://github.com/whrvt/wine-osu-patches), also used in [osu-winello](https://github.com/NelloKudo/osu-winello).
- **`build_wine.sh`**: Builds the latest **Wine-Staging** version by default. You can customize it if you want.

> **Custom patches:** To use your own patches, just place them in the `custompatches/` folder and set the `PATCHSET` variable in `build_osu_wine.sh` to use them instead of the default ones.

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

It will ask you to choose between:

- `wine-osu`
- `wine-staging`

Or, you can run one directly like this:

```bash
./build.sh build_osu_wine    # For osu!stable
./build.sh build_wine        # For Wine-Staging
```

The built Wine binaries will be saved in the same folder when it's done. 🎉
