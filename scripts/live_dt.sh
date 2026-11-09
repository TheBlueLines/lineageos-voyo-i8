A='/mnt/f/Voyo i8/LineageOS'
rm -rf /tmp/dt; mkdir -p /tmp/dt; tar -xf "$A/device-info/devicetree.tar" -C /tmp/dt 2>/dev/null
dtc -I fs -O dts -o "$A/analysis/live.dts" /tmp/dt 2>/dev/null; wc -l "$A/analysis/live.dts"
cd "$A/analysis"
grep -nE 'compatible = "mediatek,(cap_touch|mt6797-touch|gsensor|msensor|alsps|gyro|barometer|sw_charger|buck_boost|speaker_amp|i2c_lcd_bias|strobe_main|camera_main|camera_sub|bq25890|mt6605)' live.dts | head -20
grep -nE 'pinctrl-names' live.dts | cut -c1-170 | head -50
sed -n '/lcm_pinctrl {/,/};/p' live.dts | cut -c1-120 | head -20
sed -n '/touch@ {/,/};/p' live.dts | cut -c1-170 | head -30
sed -n '/touch_panel@ {/,/};/p' live.dts | cut -c1-120 | head -10
sed -n '/i2c4@\|i2c@11009000/,+2p' live.dts | head -8
grep -n 'cap_touch' live.dts | head; grep -n 'model = ' live.dts | head -3
grep -c 'phandle' live.dts
