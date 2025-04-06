#!/usr/bin/env bash

## Script to launch the build process in the Docker container,
## supporting choosing between osu!-specific builds and generic 
## Wine builds.

Info() {
    echo -e '\033[1;34m'"WineBuilder:\033[0m $*"
}

Info "Welcome to WineBuilder!"

## Allow choosing between builds..
buildChoice="1"
script="$1"

if [ $# -eq 0 ]; then
    Info "Choose your preferred Wine build:
         1 - wine-osu (default)
         2 - wine-staging/custom"
    read -r -p "$(Info "Choose your option: ")" buildChoice

    case "$buildChoice" in
    '2')
        Info "Building wine-staging/custom.."
        script="build_wine"
        ;;
    *)  
        Info "Building wine-osu.."
        script="build_osu_wine"
        ;;
    esac
fi

if [ "$script" != "build_wine" ] && [ "$script" != "build_osu_wine" ]; then
    Info "Error: Invalid script choice. Must be either 'build_wine' or 'build_osu_wine'"
    exit 1
fi

## Setting up Docker..
mkdir -p {custompatches,ccache,output,protonfonts,sources}
docker buildx build --progress=plain -t wine-builder .

## Building..
docker run --rm -it \
    --name wine-builder \
    --mount type=bind,source="$(pwd)"/custompatches,target=/wine/custompatches \
    --mount type=bind,source="$(pwd)"/build_scripts,target=/wine/build_scripts \
    --mount type=bind,source="$(pwd)"/output,target=/wine \
    --mount type=bind,source="$(pwd)"/protonfonts,target=/wine/protonfonts \
    --mount type=bind,source="$(pwd)"/ccache,target=/root/.ccache \
    --mount type=bind,source="$(pwd)"/sources,target=/wine/sources \
    --entrypoint "/usr/local/bin/$script.sh" \
    wine-builder || { echo "failed" && exit 1 ; }

Info "FIXME: fixing up ownership of build files..."
sudo chown -R "$(id -u)":"$(id -g)" output/

## Copying finished builds in main directory..
mv output/*.tar.* .
