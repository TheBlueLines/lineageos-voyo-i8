#!/bin/bash
# DSI_Start on the dual module must start DSI1 as well, as the stock kernel
# does. Otherwise command-mode packets (the panel's sleep-out/display-on
# after resume) only go out on DSI0 and the right half of the panel stays
# asleep.
set -e
cd $HOME/los-kernel/gemini8/kernel-3.18
python3 - <<'PY'
p = 'drivers/misc/mediatek/video/mt6797/dispsys/ddp_dsi.c'
s = open(p).read()
old = '''	} else {
		/* TODO: do we need this? */
		DSI_OUTREGBIT(cmdq, DSI_START_REG, DSI_REG[0]->DSI_START, DSI_START, 0);
		DSI_OUTREGBIT(cmdq, DSI_START_REG, DSI_REG[0]->DSI_START, DSI_START, 1);
	}

	return DSI_STATUS_OK;
}

void DSI_Set_VM_CMD('''
new = '''	} else {
		/* Start both links, like the stock kernel. */
		for (i = 0; i < 2; i++) {
			DSI_OUTREGBIT(cmdq, DSI_START_REG, DSI_REG[i]->DSI_START, DSI_START, 0);
			DSI_OUTREGBIT(cmdq, DSI_START_REG, DSI_REG[i]->DSI_START, DSI_START, 1);
		}
	}

	return DSI_STATUS_OK;
}

void DSI_Set_VM_CMD('''
if new not in s:
    assert s.count(old) == 1, 'DSI_Start pattern not found'
    s = s.replace(old, new)
    open(p, 'w').write(s)
PY
git diff --stat
