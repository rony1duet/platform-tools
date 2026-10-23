import os, subprocess, zipfile, shutil

base = os.path.dirname(os.path.abspath(__file__))
# Run all three creators
for s in ['create_gcam_module.py','create_debloat_module.py','create_module.py']:
    subprocess.run(['python', os.path.join(base, s)], check=True, cwd=base)

# Merge outputs into one module dir
out_zip = os.path.join(base, 'Combined_All_Module.zip')
mod = os.path.join(base, 'Combined_All_Module')
if os.path.exists(mod): shutil.rmtree(mod)
os.makedirs(mod)
for z in ['GCam_System_Module.zip','System_Safe_Debloat_Module.zip','LunarisDolby_Magisk_Module.zip']:
    with zipfile.ZipFile(os.path.join(base, z)) as zf:
        zf.extractall(mod)

# Single module.prop
with open(os.path.join(mod, 'module.prop'), 'w') as f:
    f.write('id=combined_all_modules\nname=Combined All Modules\nversion=1.0\nversionCode=1\nauthor=Md Rony Hossen (rony1duet)\ndescription=GCam + Safe Debloat + Lunaris Dolby combined\n')

# Build single zip
if os.path.exists(out_zip): os.remove(out_zip)
with zipfile.ZipFile(out_zip, 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, _, files in os.walk(mod):
        for fn in files:
            fp = os.path.join(root, fn)
            zf.write(fp, os.path.relpath(fp, mod))
print('Created', out_zip, os.path.getsize(out_zip))
