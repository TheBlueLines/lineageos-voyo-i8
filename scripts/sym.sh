cd ~/los-kernel/m95/out
for a in "$@"; do awk -v t="$a" 'BEGIN{ta=strtonum("0x" t)} {v=strtonum("0x" substr($1,9)); if(v<=ta){n=$3;b=v} else {printf "%s -> %s+0x%x\n",t,n,ta-b; exit}}' <(grep -E ' [tT] ' System.map | sort); done
for f in ffffffc0012bf8b0; do grep -E ' init_thread_union| __init_begin| _edata| __bss_start| _end$| init_stack' System.map | head; done
