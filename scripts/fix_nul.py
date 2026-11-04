import sys

p = sys.argv[1]
b = open(p, "rb").read()
b = b.replace(b'fn + b"\x00"', b'fn + b"\\0"')
assert b"\x00" not in b
open(p, "wb").write(b)
compile(b.decode(), p, "exec")
print("ok")
