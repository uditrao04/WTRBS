#!/bin/bash
# This file creates new files after transforming them into new positions/angles. This is denoted by prefixes and suffixes.
# 'O' at suffix means 'At Origin'.
# '1' at prefix means 'The 1st Blade of the wind turbine'.

# This is a bash safety setting saying, "If any command fails, stop the script immediately"
set -e 

TS="constant/triSurface"

surfaceTransformPoints \
    -translate "(-0.5 0 -10)" \
    "$TS/blade.stl" \
    "$TS/bladeO.stl"

echo "Done"
