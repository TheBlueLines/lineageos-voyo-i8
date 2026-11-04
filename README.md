# LineageOS 20 for the VOYO i8 (x970_t10_97inc)

An unofficial LineageOS 20 (Android 13) port for the 9.7" VOYO i8 tablet (MediaTek MT6797X / Helio X27,
stock Android 8.0, build O00623). It runs a 3.18 kernel built from source on top of the
tablet's own Android 8 vendor blobs.

LineageOS 20 is the newest version this hardware can run. LineageOS 21 and later need a 4.14 or newer
kernel, and no such kernel exists for this chip.

Download the images from [Releases](../../releases). The recovery is in
[twrp-voyo-i8](https://github.com/TheBlueLines/twrp-voyo-i8).

## Status

Tested on one tablet.

| Feature | State |
|---|---|
| Boot, display, touch, sleep and wake | Working; the tablet deep-sleeps with the screen off (about 92% of screen-off time with Wi-Fi connected) |
| Wi-Fi (2.4 and 5 GHz) | Working |
| Bluetooth | Working |
| Battery and charging | Working |
| GPU | Mali-T880 GLES 3.2 with DVFS; Vulkan 1.0 |
| SELinux | Enforcing |
| Encryption | File-based (FBE v1); keys are protected only in software, since the tablet has no TEE |
| Signing | Private release keys (`dev-keys`), so the Trust app reports the build as signed |
| Security patch | Shows 2026-02-01. LineageOS 20 gets community ASB backports, up to about October 2026, without bumping that date |
| Audio output | Sound card registers and the audio HAL writes to it; speaker and headphone output not yet checked by ear |
| Camera | **Not working**: the camera HAL crashes during sensor detection, so it is disabled |
| Hardware video decoding | OMX runs, but the software Codec2 decoders are picked first |
| GPS, sensors, USB OTG | Untested |
| Display refresh | 48.3 Hz, the panel's stock rate |

Known bring-up leftovers: `adb reboot` from Android lands in TWRP once (the `voyo_failsafe` RTC mark;
`adb reboot` from TWRP boots Android). A diagnostic logger runs until boot completes.

## Before you flash

- Install [TWRP for the VOYO i8](https://github.com/TheBlueLines/twrp-voyo-i8) first and read its
  "Before you flash" section. Unlocking the bootloader wipes the tablet.
- Back up every partition to the microSD card. `nvram`, `nvdata` and `proinfo` hold per-device
  calibration data, and there is no downloadable stock firmware to go back to.
- Only `x970_t10_97inc` with the 1536x2048 BOE panel is supported. Check
  `adb shell getprop ro.product.device`.
- Never use MediaTek download mode (SP Flash Tool, mtkclient) for this. Everything here is done
  from TWRP.

## Flashing

`system.img` and `vendor.img` are sparse. Expand them in RAM before writing: `simg2img` straight to
the block device skips empty chunks and leaves old data behind. From TWRP, with the images on the
microSD card in `/external_sd/LineageOS/` (run these in `adb shell` or TWRP's Terminal):

```sh
cd /external_sd/LineageOS
sha256sum -c SHA256SUMS
N=lineage-20.0-20261104-UNOFFICIAL-x970_t10_97inc
dd if=$N-boot.img of=/dev/block/mmcblk0p23 bs=1048576
simg2img $N-vendor.img /tmp/vendor.raw && dd if=/tmp/vendor.raw of=/dev/block/mmcblk0p29 bs=1048576; rm /tmp/vendor.raw
simg2img $N-system.img /tmp/system.raw && dd if=/tmp/system.raw of=/dev/block/mmcblk0p30 bs=1048576; rm /tmp/system.raw
sync
```

Coming from stock Android, or from an unencrypted LineageOS build, wipe `/data` so that the first
boot creates it with file-based encryption. **This deletes all user data, including internal storage:**

```sh
dd if=/dev/zero of=/dev/block/mmcblk0p32 bs=1048576 count=16
```

Don't use TWRP's **Format Data** for this: it creates an unencrypted `/data/media/0`, and LineageOS
then cannot enable encryption. TWRP can't decrypt LineageOS's FBE, so keep files you need in TWRP
on the microSD card.

If LineageOS boot-loops, enter TWRP with Vol Up + Power, then "Select Boot Mode", Vol Up to
Recovery and Vol Down to confirm.

## Repository layout

- `device/voyo/x970_t10_97inc`: the LineageOS device tree. `tools/gen_vendor.py` builds the vendor
  tree from an unpacked stock `/vendor`, and `tools/port_stock_sepolicy.py` generates
  `sepolicy/stock` from the stock policy. Hand-written policy is in `sepolicy/vendor`.
- `kernel-port/patches`: the kernel as patches on
  [`dguidipc/gemini-android-kernel-3.18-android8`](https://github.com/dguidipc/gemini-android-kernel-3.18-android8),
  with parts (binder, Wi-Fi/BT/GPS connectivity) taken from
  [`nomorecoolnicknames/android_kernel_meizu_m95`](https://github.com/nomorecoolnicknames/android_kernel_meizu_m95).
  `x970_t10_97inc_defconfig` is the kernel config. `lcm/` and `touch/` are the panel and touch
  drivers, which were written from disassembly of the stock kernel.
- `patches`: changes to LineageOS 20 projects (`hardware/interfaces` for the Android 8 audio HAL,
  `external/setupcompat` for the setup wizard layout on tablets).
- `analysis`: the board device tree (`dtb0.dtb`, appended to the kernel) and live device-tree dumps.
- `scripts`: build, flash and debugging helpers. They expect the WSL distro `TWRP-Builder` with
  the LineageOS tree in `~/los` and the kernel in `~/los-kernel/gemini8`, and this checkout at
  `C:\Users\David\Voyo i8\LineageOS`. Many `inspect*.sh` scripts are one-off bring-up probes.

### Building

1. `scripts/sync_los.sh` syncs LineageOS 20, then apply the patches in `patches/`.
2. Apply `kernel-port/patches` to the Gemini kernel and build it (`scripts/build_gemini.sh`).
3. Unpack the stock `/vendor` (`scripts/unpack_stock_fs.sh`). `scripts/setup_tree.sh` installs the
   device tree and kernel and generates `vendor/voyo`.
4. `scripts/gen_release_keys.sh` creates signing keys in `vendor/lineage-priv` (optional).
5. `m bootimage systemimage vendorimage` through `scripts/los_env.sh`.

## Licensing

Files written for this project are under the [Apache License 2.0](LICENSE), except:

- `kernel-port` modifies the Linux kernel and is under the GPL-2.0.
  `kernel-port/touch/gsl3680_fw.h` is touch controller firmware extracted from the stock kernel.
- `patches` modify AOSP projects and keep their licenses (Apache 2.0).
- The release `vendor.img` contains the proprietary stock vendor blobs from the tablet.
