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

# This is a bash safety setting saying, "If any command fails, just stop the script immediately"
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

rm -f "$TS"/hubO.stl
rm -f "$TS"/bladeO.stl
rm -f "$TS"/1bladeO.stl
rm -f "$TS"/1bladeOP.stl
rm -f "$TS"/[2-9]*bladeOP.stl
rm -f "$TS"/rotorUnion.stl
rm -f "$TS"/rotorRemesh.stl
rm -f "$TS"/unionRotor.scad
rm -f "$TS"/remesh_rotor.py

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
	-rotate-y "$PA" \
	"$TS/1bladeO.stl" \
	"$TS/1bladeOP.stl"

for((i=2;i<=NB;i++))
do
	# Basically angle for each blade ('N'bladeOP) = N * Blade Step Angle
	ANGLE=$(awk "BEGIN {print ($i-1)*$STEP}")
	
	# Creation of remaining blades
	runCmd surfaceTransformPoints \
    		-rotate-x "$ANGLE" \
    		"$TS/1bladeOP.stl" \
    		"$TS/${i}bladeOP.stl"
done

# Create OpenSCAD union script
cat > "$TS/unionRotor.scad" <<EOF
union() {
    import("hubO.stl");
    import("1bladeOP.stl");
EOF

for ((i=2; i<=NB; i++)); do
cat >> "$TS/unionRotor.scad" <<EOF
    import("${i}bladeOP.stl");
EOF
done

cat >> "$TS/unionRotor.scad" <<EOF
}
EOF

# Export unioned STL
runCmd openscad -o "$TS/rotorUnion.stl" "$TS/unionRotor.scad"

if [ ! -f "$TS/rotorUnion.stl" ]
then
	echo "Error: rotorUnion.stl was not created. Check $LOG"
	exit 1
fi

echo "Unioned STL created: $TS/rotorUnion.stl"

# Create Blender remesh script
cat > "$TS/remesh_rotor.py" << 'EOF'
import bpy
import sys
import os

argv = sys.argv
argv = argv[argv.index("--") + 1:] if "--" in argv else []

infile = os.path.abspath(argv[0])
outfile = os.path.abspath(argv[1])
voxel_size = float(argv[2])

print("INFILE =", infile)
print("OUTFILE =", outfile)
print("VOXEL =", voxel_size)

bpy.ops.wm.read_factory_settings(use_empty=True)

# Import STL
ok_import = False
try:
    bpy.ops.wm.stl_import(filepath=infile)
    ok_import = True
    print("Imported with bpy.ops.wm.stl_import")
except Exception as e:
    print("wm.stl_import failed:", e)

if not ok_import:
    try:
        bpy.ops.import_mesh.stl(filepath=infile)
        ok_import = True
        print("Imported with bpy.ops.import_mesh.stl")
    except Exception as e:
        print("import_mesh.stl failed:", e)

if not ok_import:
    raise RuntimeError("Could not import STL")

obj = bpy.context.selected_objects[0]

# Ensure object is active
bpy.context.view_layer.objects.active = obj
obj.select_set(True)

# CRITICAL FIX for Blender multi-user mesh/object data
if obj.data.users > 1:
    obj.data = obj.data.copy()

bpy.ops.object.make_single_user(object=True, obdata=True, material=False, animation=False)

# Voxel remesh
mod = obj.modifiers.new(name="Remesh", type='REMESH')
mod.mode = 'VOXEL'
mod.voxel_size = voxel_size
mod.adaptivity = 0.0
bpy.ops.object.modifier_apply(modifier=mod.name)
print("Voxel remesh applied")

# Triangulate
tri = obj.modifiers.new(name="Triangulate", type='TRIANGULATE')
bpy.ops.object.modifier_apply(modifier=tri.name)
print("Triangulate applied")

# Export STL
ok_export = False
try:
    bpy.ops.wm.stl_export(filepath=outfile, export_selected_objects=True)
    ok_export = True
    print("Exported with bpy.ops.wm.stl_export")
except Exception as e:
    print("wm.stl_export failed:", e)

if not ok_export:
    try:
        bpy.ops.export_mesh.stl(filepath=outfile, use_selection=True)
        ok_export = True
        print("Exported with bpy.ops.export_mesh.stl")
    except Exception as e:
        print("export_mesh.stl failed:", e)

if not ok_export:
    raise RuntimeError("Could not export STL")

if not os.path.isfile(outfile):
    raise RuntimeError(f"Export reported success but file not found: {outfile}")

print("DONE:", outfile)
EOF

# Export remeshed STL
# Voxel size can be changed later if needed
runCmd blender -b --python "$TS/remesh_rotor.py" -- \
	"$TS/rotorUnion.stl" \
	"$TS/rotorRemesh.stl" \
	0.5

if [ ! -f "$TS/rotorRemesh.stl" ]
then
	echo "Error: rotorRemesh.stl was not created. Check $LOG"
	exit 1
fi

echo "Remeshed STL created: $TS/rotorRemesh.stl"

# Surface check for the remeshed STL
runCmd surfaceCheck "$TS/rotorRemesh.stl"

echo "Surface check completed for remeshed STL"
echo "Done"
echo "Created $NB blades."
echo "Use this file in snappyHexMeshDict: $TS/rotorRemesh.stl"
