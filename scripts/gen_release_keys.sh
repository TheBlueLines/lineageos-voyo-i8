#!/bin/bash
# Generate the private signing keys (no password) in ~/.android-certs, back them up to the
# personal OneDrive, and install them as vendor/lineage-priv/keys for inline signing.
# make_key does not quote its path, so keys are generated in a space-free dir first.
set -e
K=~/.android-certs
B="/mnt/c/Users/David/OneDrive/Android Signing Keys/voyo-i8-lineageos"
cd ~/los
mkdir -p "$K" "$B"
subject='/C=HU/O=David Feher/OU=VOYO i8 LineageOS/CN=VOYO i8 LineageOS'
for cert in bluetooth cyngn-app media networkstack nfc platform releasekey sdk_sandbox shared testcert testkey verity; do
  [ -f "$K/$cert.pk8" ] && continue
  printf '\n' | timeout 120 ./development/tools/make_key "$K/$cert" "$subject" >/dev/null 2>&1 || true  # make_key always exits 1 (EXIT trap)
  [ -s "$K/$cert.pk8" ] && [ -s "$K/$cert.x509.pem" ] || { echo "FAILED $cert"; exit 1; }
done
chmod 600 "$K"/*.pk8
# Backup (never overwrite an existing backup with different keys)
for f in "$K"/*; do
  n=$(basename "$f")
  if [ -e "$B/$n" ]; then cmp -s "$f" "$B/$n" || { echo "BACKUP DIFFERS: $n"; exit 1; }
  else cp "$f" "$B/$n"; fi
done
# Inline signing setup
P=vendor/lineage-priv/keys
mkdir -p "$P"
cp "$K"/* "$P"/
echo 'PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/lineage-priv/keys/releasekey' > "$P/keys.mk"
cat > "$P/BUILD.bazel" <<'B'
filegroup(
    name = "android_certificate_directory",
    srcs = glob([
        "*.pk8",
        "*.pem",
    ]),
    visibility = ["//visibility:public"],
)
B
ls "$P"
(cd "$K" && sha256sum *) > /tmp/keys.sha
(cd "$B" && sha256sum -c /tmp/keys.sha | grep -vc ': OK$' || true) | sed 's/^/backup mismatches: /'
