#!/bin/bash
# Add the VOYO i8 camera sensors to the gemini8 kernel: GC5005 (rear, "main")
# and GC2235 (front, "sub"), as named by LK's camera_info and the stock HAL's
# libcameracustom.so. Driver sources come from kernel-port/camera/ (public
# GalaxyCore MTK drivers, adjusted to match the stock kernel's register writes,
# recovered by disassembly). Power sequences are the stock kernel's PowerOnList
# entries. Idempotent.
set -e
A='/mnt/c/Users/David/Voyo i8/LineageOS'
K=$HOME/los-kernel/gemini8/kernel-3.18
I=$K/drivers/misc/mediatek/imgsensor
SRC=$I/src/mt6797

for d in gc5005mipi_raw gc2235mipi_raw; do
  mkdir -p $SRC/$d
  for f in "$A/kernel-port/camera/$d/"*; do sed 's/\r$//' "$f" > $SRC/$d/$(basename "$f"); done
done

python3 - "$I" <<'PY'
import sys, re
I = sys.argv[1]
def patch(path, anchor, text, marker):
    s = open(path).read()
    if marker in s:
        return
    assert anchor in s, (path, anchor)
    s = s.replace(anchor, text + anchor, 1)
    open(path, 'w').write(s)

h = I + '/inc/kd_imgsensor.h'
patch(h, '#define S5K5E2YA_SENSOR_ID',
      '#define GC5005MIPI_SENSOR_ID                    0x5005\n', 'GC5005MIPI_SENSOR_ID')
patch(h, '#define SENSOR_DRVNAME_S5K5E2YA_MIPI_RAW',
      '#define SENSOR_DRVNAME_GC5005_MIPI_RAW          "gc5005mipiraw"\n'
      '#define SENSOR_DRVNAME_GC2235_MIPI_RAW          "gc2235mipiraw"\n', 'SENSOR_DRVNAME_GC5005_MIPI_RAW')

# The stock HAL (an MTK O release between the m95 and gemini kernels) copies a
# 160-byte MSDK_SENSOR_INFO_STRUCT; gemini's is 216 bytes, so GETINFO wrote past
# the HAL's buffer. Drop the newer fields (offsets then match the stock
# kernel's get_info stores, checked by disassembly).
d = I + '/inc/kd_imgsensor_define.h'
s = open(d).read()
end = s.index('} ACDK_SENSOR_INFO_STRUCT')
start = s.rindex('typedef struct {', 0, end)
blk = s[start:end]
if 'SensorGrabStartX_PRV' in blk:
    drop = re.compile(r'^\s*MUINT(8|16|32) (SensorGrabStart[XY]_\w+|MIPIDataLowPwr2HSSettleDelayM\d|SensorHorFOV|SensorVerFOV|SensorOrientation|SensorModuleID);.*\n', re.M)
    nb = drop.sub('', blk)
    s = s[:start] + nb + s[end:]
    open(d, 'w').write(s)

# GETINFO2 is a separate call: the HAL's getInfo2 reads a 208-byte struct with
# the older layout (SensorDrivingCurrent at 132, SensorModeNum at 157, PDAF at
# 168, checked by disassembly). Gemini aliases it to the INFO struct above, which
# left SensorModeNum at 0, so LSC built a 0x0 grid and TSF crashed on it.
s = open(d).read()
alias = '#define ACDK_SENSOR_INFO2_STRUCT ACDK_SENSOR_INFO_STRUCT\n#define PACDK_SENSOR_INFO2_STRUCT PACDK_SENSOR_INFO_STRUCT\n'
info2 = '''typedef struct {
	MUINT16 SensorPreviewResolutionX;
	MUINT16 SensorPreviewResolutionY;
	MUINT16 SensorFullResolutionX;
	MUINT16 SensorFullResolutionY;
	MUINT8 SensorClockFreq;
	MUINT8 SensorCameraPreviewFrameRate;
	MUINT8 SensorVideoFrameRate;
	MUINT8 SensorStillCaptureFrameRate;
	MUINT8 SensorWebCamCaptureFrameRate;
	MUINT8 SensorClockPolarity;
	MUINT8 SensorClockFallingPolarity;
	MUINT8 SensorClockRisingCount;
	MUINT8 SensorClockFallingCount;
	MUINT8 SensorClockDividCount;
	MUINT8 SensorPixelClockCount;
	MUINT8 SensorDataLatchCount;
	MUINT8 SensorHsyncPolarity;
	MUINT8 SensorVsyncPolarity;
	MUINT8 SensorInterruptDelayLines;
	MINT32 SensorResetActiveHigh;
	MUINT32 SensorResetDelayCount;
	ACDK_SENSOR_INTERFACE_TYPE_ENUM SensroInterfaceType;
	ACDK_SENSOR_OUTPUT_DATA_FORMAT_ENUM SensorOutputDataFormat;
	ACDK_SENSOR_MIPI_LANE_NUMBER_ENUM SensorMIPILaneNumber;
	MUINT32 CaptureDelayFrame;
	MUINT32 PreviewDelayFrame;
	MUINT32 VideoDelayFrame;
	MUINT32 HighSpeedVideoDelayFrame;
	MUINT32 SlimVideoDelayFrame;
	MUINT32 YUVAwbDelayFrame;
	MUINT32 YUVEffectDelayFrame;
	MUINT32 Custom1DelayFrame;
	MUINT32 Custom2DelayFrame;
	MUINT32 Custom3DelayFrame;
	MUINT32 Custom4DelayFrame;
	MUINT32 Custom5DelayFrame;
	MUINT16 SensorGrabStartX_PRV;
	MUINT16 SensorGrabStartY_PRV;
	MUINT16 SensorGrabStartX_CAP;
	MUINT16 SensorGrabStartY_CAP;
	MUINT16 SensorGrabStartX_VD;
	MUINT16 SensorGrabStartY_VD;
	MUINT16 SensorGrabStartX_VD1;
	MUINT16 SensorGrabStartY_VD1;
	MUINT16 SensorGrabStartX_VD2;
	MUINT16 SensorGrabStartY_VD2;
	MUINT16 SensorGrabStartX_CST1;
	MUINT16 SensorGrabStartY_CST1;
	MUINT16 SensorGrabStartX_CST2;
	MUINT16 SensorGrabStartY_CST2;
	MUINT16 SensorGrabStartX_CST3;
	MUINT16 SensorGrabStartY_CST3;
	MUINT16 SensorGrabStartX_CST4;
	MUINT16 SensorGrabStartY_CST4;
	MUINT16 SensorGrabStartX_CST5;
	MUINT16 SensorGrabStartY_CST5;
	MUINT16 SensorDrivingCurrent;
	MUINT8 SensorMasterClockSwitch;
	MUINT8 AEShutDelayFrame;
	MUINT8 AESensorGainDelayFrame;
	MUINT8 AEISPGainDelayFrame;
	MUINT8 FrameTimeDelayFrame;
	MUINT8 MIPIDataLowPwr2HighSpeedTermDelayCount;
	MUINT8 MIPIDataLowPwr2HighSpeedSettleDelayCount;
	MUINT8 MIPIDataLowPwr2HSSettleDelayM0;
	MUINT8 MIPIDataLowPwr2HSSettleDelayM1;
	MUINT8 MIPIDataLowPwr2HSSettleDelayM2;
	MUINT8 MIPIDataLowPwr2HSSettleDelayM3;
	MUINT8 MIPIDataLowPwr2HSSettleDelayM4;
	MUINT8 MIPICLKLowPwr2HighSpeedTermDelayCount;
	MUINT8 SensorWidthSampling;
	MUINT8 SensorHightSampling;
	MUINT8 SensorPacketECCOrder;
	SENSOR_MIPI_TYPE_ENUM MIPIsensorType;
	MUINT8 SensorCaptureOutputJPEG;
	MUINT8 SensorModeNum;
	MUINT8 IHDR_Support;
	MUINT16 IHDR_LE_FirstLine;
	MUINT8 ZHDR_Mode;
	SENSOR_SETTLEDELAY_MODE_ENUM SettleDelayMode;
	MUINT8 PDAF_Support;
	MUINT8 HDR_Support;
	MUINT8 DPCM_INFO;
	MUINT8 IMGSENSOR_DPCM_TYPE_PRE;
	MUINT8 IMGSENSOR_DPCM_TYPE_CAP;
	MUINT8 IMGSENSOR_DPCM_TYPE_VD;
	MUINT8 IMGSENSOR_DPCM_TYPE_VD1;
	MUINT8 IMGSENSOR_DPCM_TYPE_VD2;
	MUINT8 PerFrameCTL_Support;
	SENSOR_SCAM_DATA_CHANNEL_ENUM SCAM_DataNumber;
	MUINT8 SCAM_DDR_En;
	MUINT8 SCAM_CLK_INV;
	MUINT8 SCAM_DEFAULT_DELAY;
	MUINT8 SCAM_CRC_En;
	MUINT8 SCAM_SOF_src;
	MUINT32 SCAM_Timout_Cali;
	MUINT32 SensorMIPIDeskew;
	MUINT32 Reserved[2];
} ACDK_SENSOR_INFO2_STRUCT, *PACDK_SENSOR_INFO2_STRUCT;
'''
if alias in s:
    s = s.replace(alias, info2, 1)
    open(d, 'w').write(s)

l = I + '/src/mt6797/kd_sensorlist.h'
patch(l, 'UINT32 S5K5E2YA_MIPI_RAW_SensorInit(',
      'UINT32 GC5005MIPI_RAW_SensorInit(PSENSOR_FUNCTION_STRUCT *pfFunc);\n'
      'UINT32 GC2235MIPI_RAW_SensorInit(PSENSOR_FUNCTION_STRUCT *pfFunc);\n', 'GC5005MIPI_RAW_SensorInit(PSENSOR')
# The HAL's table in libcameracustom.so is walked by position and the kernel is
# asked for the same index, so kdSensorList has to line up with it: gc5005 is
# entry 9 and gc2235 entry 13. Empty slots return -EIO, as a miss should.
s = open(l).read()
s = re.sub(r'/\* VOYO i8.*?(?=/\*  ADD sensor driver before this line \*/)', '', s, flags=re.S)
empty = '    {0, {0}, NULL},\n'
s = s.replace('/*  ADD sensor driver before this line */',
      '/* VOYO i8: indices match the stock HAL, see camera_kernel.sh */\n'
      + empty * 9 +
      '    {GC5005MIPI_SENSOR_ID, SENSOR_DRVNAME_GC5005_MIPI_RAW, GC5005MIPI_RAW_SensorInit},\n'
      + empty * 3 +
      '    {GC2235_SENSOR_ID, SENSOR_DRVNAME_GC2235_MIPI_RAW, GC2235MIPI_RAW_SensorInit},\n'
      '/*  ADD sensor driver before this line */', 1)
open(l, 'w').write(s)

c = I + '/src/mt6797/camera_hw/kd_camera_hw.c'
s = open(c).read()
# Entries in the stock kernel's table are name[32], socket, then (type, value,
# delay) triples. GC5005 keeps the order that works here; GC2235 follows stock,
# since it needs 10 ms after reset and again after PDN before it answers I2C.
s = re.sub(r'/\* VOYO i8: stock kernel PowerOnList entries \*/\n.*?#endif\n.*?#endif\n', '', s, count=1, flags=re.S)
anchor = 'PowerUp PowerOnList = {\n\t{\n'
assert anchor in s
seq = '''/* VOYO i8: stock kernel PowerOnList entries */
#if defined(GC5005MIPI_RAW)
	{SENSOR_DRVNAME_GC5005_MIPI_RAW,
	 {
	  {SensorMCLK, Vol_High, 0},
	  {DOVDD, Vol_1800, 0},
	  {AVDD, Vol_2800, 0},
	  {DVDD, Vol_1200, 0},
	  {AFVDD, Vol_2800, 5},
	  {PDN, Vol_Low, 4},
	  {PDN, Vol_Low, 0},
	  {RST, Vol_Low, 1},
	  {RST, Vol_High, 0},
	 },
	},
#endif
#if defined(GC2235MIPI_RAW)
	{SENSOR_DRVNAME_GC2235_MIPI_RAW,
	 {
	  {SensorMCLK, Vol_High, 0},
	  {AVDD, Vol_2800, 1},
	  {DOVDD, Vol_1800, 1},
	  {AFVDD, Vol_2800, 0},
	  {RST, Vol_High, 10},
	  {PDN, Vol_Low, 10},
	 },
	},
#endif
'''
s = s.replace(anchor, anchor + seq, 1)
# Both sensors take their clock from MCLK1 on this board. Stock's hwpoweron calls
# ISP_MCLK1_EN whatever pinSetIdx is, so with MCLK2 the GC2235 has no clock and
# never answers I2C. Stock powers off with MCLK2, leaking an MCLK1 user on every
# cycle; use MCLK1 here too so the count stays balanced.
for v in ('TRUE', 'FALSE'):
    assert ('ISP_MCLK2_EN(%s);' % v in s) or ('ISP_MCLK1_EN(%s); /* VOYO i8: sub */' % v in s)
    s = s.replace('ISP_MCLK2_EN(%s);' % v, 'ISP_MCLK1_EN(%s); /* VOYO i8: sub */' % v)
open(c, 'w').write(s)
PY

cfg=$K/arch/arm64/configs/x970_t10_97inc_defconfig
sed -i 's/^CONFIG_CUSTOM_KERNEL_IMGSENSOR=.*/CONFIG_CUSTOM_KERNEL_IMGSENSOR="gc5005mipi_raw gc2235mipi_raw"/' $cfg
grep -n CUSTOM_KERNEL_IMGSENSOR $cfg
cd $K && git status --short | head -20
