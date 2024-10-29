#!/usr/bin/env bash

mkdir -p {custompatches,ccache,output,sources}

docker build -t wine-builder .

docker run --rm -it \
    --name wine-builder \
    --mount type=bind,source="$(pwd)"/custompatches,target=/wine/custompatches \
    --mount type=bind,source="$(pwd)"/osu-misc,target=/wine/osu-misc \
    --mount type=bind,source="$(pwd)"/output,target=/wine \
    --mount type=bind,source="$(pwd)"/ccache,target=/root/.ccache \
    --mount type=bind,source="$(pwd)"/sources,target=/wine/sources \
    wine-builder
