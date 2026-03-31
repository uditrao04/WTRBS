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
