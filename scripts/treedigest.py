#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Algorithm from Omamobile (tools/toolchain.lock, "tree" kind), MIT License,
# Copyright (c) 2026 Derek Ross and Omamobile contributors. Reimplemented here.
#
# Usage: python3 -I scripts/treedigest.py <directory>
#
# Digest de un arbol de directorios, mismo algoritmo que el tipo "tree" de
# omamobile/tools/toolchain.lock (reimplementado aqui para no ejecutar su
# script): SHA-256 sobre "f <x|-> <sha256> <ruta>\0" por fichero y
# "l <destino> <ruta>\0" por symlink, ordenado por bytes de la ruta.
import hashlib, os, stat, sys

if len(sys.argv) != 2:
    sys.exit("uso / usage: python3 -I scripts/treedigest.py <directorio>")
root = sys.argv[1]
if not os.path.isdir(root):
    sys.exit("no es un directorio: " + root)
entries = []
for d, dirs, files in os.walk(root):
    for n in dirs + files:
        p = os.path.join(d, n)
        rel = os.path.relpath(p, root).encode("utf-8", "surrogateescape")
        st = os.lstat(p)
        if stat.S_ISLNK(st.st_mode):
            entries.append((rel, b"l " + os.readlink(p).encode("utf-8", "surrogateescape")))
        elif stat.S_ISREG(st.st_mode):
            h = hashlib.sha256()
            with open(p, "rb") as f:
                for chunk in iter(lambda: f.read(1 << 20), b""):
                    h.update(chunk)
            x = b"x" if st.st_mode & 0o111 else b"-"
            entries.append((rel, b"f " + x + b" " + h.hexdigest().encode()))
        elif not stat.S_ISDIR(st.st_mode):
            sys.exit("tipo de fichero inesperado: " + p)
top = hashlib.sha256()
for rel, desc in sorted(entries):
    top.update(desc + b" " + rel + b"\0")
print(top.hexdigest())
