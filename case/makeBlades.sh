# This file creates new files after transforming them into new positions/angles. This is denoted by prefixes and suffixes.
# 'O' at suffix means 'At Origin'.
# 'P' at suffix means 'Pitch Angle Applied"
# '1' at prefix means 'The 1st Blade of the wind turbine'.

# To use this type:
#	./makeBlades.sh {Hub Radius} {Pitch Angle} {Number of Blades}

# By default:
#	Hub Radius = 10
#	Pitch Angle = 45
#	Number of Blades = 3



#!/bin/bash

# This is a bash safety setting saying, "If any command fails, stop the script immediately"
set -e 

TS="constant/triSurface"
LOG="log.makeBlades"

HR=${1:-10}						# Hub Radius, 1st Command-Line Argument
PA=${2:-45}						# Pitch angle
NB=${3:-3}						# Number of Blades

if [ "$NB" -lt 1 ]		# Input validation
then
	echo "Error: Number of Blades (NB) must be atleast 1"
	exit 1
fi

STEP=$(awk "BEGIN {print 360/$NB}")			# Blade Step Angle


: > "$LOG"		# Clear the old log file			
runCmd()		# Logging function (Wrapper Function)
{
	echo ">>> $*" >> "$LOG"		# Essentially ">>> surfaceTransformPoints >> "$LOG"
	"$@" >> "$LOG" 2>&1		# Both stdout and stderr are redirected to the log file.
}

echo "Hub Radius = $HR"
echo "Pitch Angle = $PA"
echo "Blade Count = $NB"
echo "Step Angle = $STEP"
echo "Detailed Output -> $LOG"

# Hub at Origin
runCmd surfaceTransformPoints \
	-translate "(-$HR -$HR -$HR)" \
	"$TS/hub.stl" \
	"$TS/hubO.stl"

# Base Blade at Origin
runCmd surfaceTransformPoints \
	-translate "(-0.5 0 -10)" \
	"$TS/blade.stl" \
	"$TS/bladeO.stl" 
   
# Blade 1 at Position 
# A little bit inside the hub to prevent meshing complications
runCmd surfaceTransformPoints \
	-translate "(0 5 0)" \
	"$TS/bladeO.stl" \
	"$TS/1bladeO.stl"

# Blade 1 at Origin and Pitched
runCmd surfaceTransformPoints \
	-rotate-y $PA \
	"$TS/1bladeO.stl" \
	"$TS/1bladeOP.stl"

for((i=2;i<=NB;i++))
do
	# Basically angle for each blade ('N'bladeOP) = N * Blade Step Angle
	ANGLE=$(awk "BEGIN {print($i-1)*$STEP}")
	
	# Creation of remaining blades
	runCmd surfaceTransformPoints \
    		-rotate-x "$ANGLE" \
    		"$TS/1bladeOP.stl" \
    		"$TS/${i}bladeOP.stl"
done

echo "Done"
echo "Created $NB blades."
