D='/mnt/c/Users/David/Voyo i8/LineageOS/scripts/disasm.sh'
bash "$D" ffffffc0008c7c90 ffffffc0008c8ca0 > /tmp/tp.dis 2>/dev/null
wc -l /tmp/tp.dis
grep -n 'bl.*8c4c18\|bl.*8c6020\|bl.*8c3f98\|bl.*8c40dc' /tmp/tp.dis | head
for l in $(grep -n 'bl.*8c4c18' /tmp/tp.dis | cut -d: -f1 | head -2); do sed -n "$((l-10)),$((l))p" /tmp/tp.dis | cut -f1,3-; done
echo; grep -nE 'adrp|add +x[0-9]+, x[0-9]+, #0x' /tmp/tp.dis | cut -f1,3- | grep -E 'ffffffc0014[0-9a-f]+' | sort -u -k3 | head -24
