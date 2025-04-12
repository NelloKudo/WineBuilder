#!/usr/bin/env bash

## Script to launch the build process in the Docker container.

Info() {
    echo -e '\033[1;34m'"WineBuilder:\033[0m $*"
}

Info "Welcome to WineBuilder!"

## Setting up Docker..
mkdir -p {custompatches,ccache,output,protonfonts,sources}
docker buildx build --progress=plain -t wine-builder .

## Building..
docker run --rm -it \
    --name wine-builder \
    --mount type=bind,source="$(pwd)"/custompatches,target=/wine/custompatches \
    --mount type=bind,source="$(pwd)"/output,target=/wine \
    --mount type=bind,source="$(pwd)"/protonfonts,target=/wine/protonfonts \
    --mount type=bind,source="$(pwd)"/ccache,target=/root/.ccache \
    --mount type=bind,source="$(pwd)"/sources,target=/wine/sources \
    --entrypoint "/usr/local/bin/wine_builder.sh" \
    wine-builder || { echo "failed" && exit 1 ; }

Info "FIXME: fixing up ownership of build files..."
sudo chown -R "$(id -u)":"$(id -g)" output/

## Copying finished builds in main directory..
mv output/*.tar.* .
