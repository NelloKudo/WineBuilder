#!/usr/bin/env bash

mkdir -p {custompatches,ccache,output,protonfonts,sources}

docker buildx build --progress=plain -t wine-builder .

docker run --rm -it \
    --name wine-builder \
    --mount type=bind,source="$(pwd)"/custompatches,target=/wine/custompatches \
    --mount type=bind,source="$(pwd)"/osu-misc,target=/wine/osu-misc \
    --mount type=bind,source="$(pwd)"/output,target=/wine \
    --mount type=bind,source="$(pwd)"/protonfonts,target=/wine/protonfonts \
    --mount type=bind,source="$(pwd)"/ccache,target=/root/.ccache \
    --mount type=bind,source="$(pwd)"/sources,target=/wine/sources \
    wine-builder || { echo "failed" && exit 1 ; }

echo "FIXME: fixing up ownership of build files..."

sudo chown -R "$(id -u)":"$(id -g)" output/

mv output/*.tar.* .
