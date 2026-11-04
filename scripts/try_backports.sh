#!/bin/bash
# Dry-run every m95 commit against the Gemini tree. Changes nothing in the tree.
A='/mnt/c/Users/David/Voyo i8/LineageOS'
cd ~/los-kernel/m95
git rev-parse --is-shallow-repository | grep -q true && git fetch -q --unshallow origin lineage-20.0
BASE=$(git rev-list --max-parents=0 origin/lineage-20.0 | tail -1)
P=~/los-kernel/m95-patches
rm -rf "$P"; mkdir -p "$P"
git format-patch -q --no-renames -o "$P" "$BASE..origin/lineage-20.0"
ls "$P" | wc -l
cd ~/los-kernel/gemini8/kernel-3.18
for f in "$P"/*.patch; do
  n=$(basename "$f" | cut -c1-58)
  files=$(grep -c '^diff --git' "$f")
  lines=$(grep -cE '^[+-][^+-]' "$f")
  # paths are relative to the kernel root, one level below the repo root here
  if git apply --check --directory=kernel-3.18 "$f" 2>/dev/null; then s=CLEAN
  else
    bad=$(git apply --check --directory=kernel-3.18 "$f" 2>&1 | grep -c '^error: patch failed\|^error: .*No such file\|does not exist')
    s="FAIL($bad)"
  fi
  printf '%-9s %3d files %6d lines  %s\n' "$s" "$files" "$lines" "$n"
done
