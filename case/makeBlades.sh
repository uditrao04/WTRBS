#!/bin/bash
# This file creates new files after transforming them into new positions/angles. This is denoted by prefixes and suffixes.
# 'O' at suffix means 'At Origin'.
# 'P' at suffix means 'Pitch Angle Applied"
# '1' at prefix means 'The 1st Blade of the wind turbine'.
# This is a bash safety setting saying, "If any command fails, stop the script immediately"
set -e 

TS="constant/triSurface"

# Hub Radius
HR=10

# Pitch angle
PA=45

# Hub at Origin
surfaceTransformPoints \
    -translate "(-$HR -$HR -$HR)" \
    "$TS/hub.stl" \
    "$TS/hubO.stl"
    
# Blade 1 at Origin 
surfaceTransformPoints \
    -translate "(0 $HR 0)" \
    "$TS/bladeO.stl" \
    "$TS/1bladeO.stl"

surfaceTransformPoints \
    -rotate-x 120 \
    "$TS/blade1.stl" \
    "$TS/blade2.stl"

surfaceTransformPoints \
    -rotate-x 240 \
    "$TS/blade1.stl" \
    "$TS/blade3.stl"

echo "Done"
