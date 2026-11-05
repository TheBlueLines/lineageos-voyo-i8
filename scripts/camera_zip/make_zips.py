"""Build the TWRP zips for the camera fix: python make_zips.py <boot.img> <outdir>"""
import hashlib, os, sys, zipfile
here = os.path.dirname(os.path.abspath(__file__))
boot, out = sys.argv[1], sys.argv[2]
def z(name, script, extra):
    p = os.path.join(out, name)
    with zipfile.ZipFile(p, "w", zipfile.ZIP_DEFLATED) as f:
        s = open(os.path.join(here, script), newline="").read().replace("\r\n", "\n")
        i = zipfile.ZipInfo("META-INF/com/google/android/update-binary"); i.external_attr = 0o755 << 16
        f.writestr(i, s)
        f.writestr("META-INF/com/google/android/updater-script", "# dummy\n")
        for n, data in extra: f.writestr(n, data)
    print(p, hashlib.sha256(open(p, "rb").read()).hexdigest())
data = open(boot, "rb").read()
z("voyo-i8-camera.zip", "install.sh", [("boot.img", data), ("boot.sha256", hashlib.sha256(data).hexdigest() + "\n")])
z("voyo-i8-camera-rollback.zip", "rollback.sh", [])
