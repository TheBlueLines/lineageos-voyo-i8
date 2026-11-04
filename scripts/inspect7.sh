cd ~/los-kernel/m95
sed -n 285,305p drivers/misc/mediatek/power/mt6797/pmic_irq.c
grep -rn 'upmu_is_chr_det' --include=*.h --include=*.c drivers | head -8
grep -n 'include' drivers/misc/mediatek/power/mt6797/pmic_irq.c | sed -n 1,36p | grep -iE 'batt|charg'
