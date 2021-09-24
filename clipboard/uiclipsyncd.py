# This utility acts as a sync between the external (tmux-based) clipboard
# scripts and the X11 (or whatever) GUI clipboard.  It polls both for changes
# and sync changes across.
# This is written as a Tkinter app primarily so it holds a persistent clipboard
# for X on Linux.  On mac tkinter shouldn't really be necessary but is still
# used for the main loop.

import tkinter
import subprocess
import os
import re
import signal
import platform

# Polling interval
check_interval = 1000
# Interval divider for checking for UI clipboard changes
interval_div_uitoext = 1
# Interval divider for checking for external clipboard changes
# This is set higher because it's typically synced on SIGHUP instead.
interval_div_exttoui = 10

mydir = os.path.dirname(os.path.abspath(__file__))
tkmain = tkinter.Tk()

mac_workaround = os.name == 'mac' or platform.system() == 'Darwin'

def get_ui_clipboard():
    if mac_workaround:
        r = subprocess.run([ 'pbpaste' ], stdout=subprocess.PIPE)
        return r.stdout.decode('utf-8')
    try:
        return tkmain.clipboard_get()
    except tkinter.TclError:
        return ''

def set_ui_clipboard(text):
    if mac_workaround:
        subprocess.run([ 'pbcopy' ], input=text.encode('utf-8'))
        return
    tkmain.clipboard_clear()
    tkmain.clipboard_append(text)

def get_ext_clipboard():
    r = subprocess.run([ os.path.join(mydir, 'getcopybuffer.sh') ], stdout=subprocess.PIPE)
    r.check_returncode()
    return r.stdout.decode('utf-8')

def set_ext_clipboard(text):
    r = subprocess.run([ os.path.join(mydir, 'pushclip.sh') ], input=text.encode('utf-8'))
    r.check_returncode()

last_ui_clip = ''
last_ext_clip = ''

def compare_normalize(text):
    return re.sub('\s', '', text)

def check_sync_exttoui():
    global last_ext_clip, last_ui_clip
    extclip = get_ext_clipboard()
    norm_extclip = compare_normalize(extclip)
    if norm_extclip == last_ext_clip:
        return False
    last_ext_clip = norm_extclip
    print('Setting UI clipboard to external clipboard')
    set_ui_clipboard(extclip)
    last_ui_clip = norm_extclip
    tkmain.update()
    return True

def check_sync_uitoext():
    global last_ext_clip, last_ui_clip
    uiclip = get_ui_clipboard()
    norm_uiclip = compare_normalize(uiclip)
    if norm_uiclip == last_ui_clip:
        return False
    last_ui_clip = norm_uiclip
    print('Setting external clipboard to UI clipboard')
    set_ext_clipboard(uiclip)
    last_ext_clip = norm_uiclip
    return True

def check_sync():
    r = False
    try:
        r = check_sync_exttoui()
    except Exception as e:
        print(e)
    if r: return True
    try:
        r = check_sync_uitoext()
    except Exception as e:
        print(e)
    return r

uitoext_ctr = interval_div_uitoext - 1
exttoui_ctr = interval_div_exttoui - 1

def check_loop():
    global uitoext_ctr, exttoui_ctr
    uitoext_ctr += 1
    exttoui_ctr += 1
    r = False
    if exttoui_ctr >= interval_div_exttoui:
        exttoui_ctr = 0
        try:
            r = check_sync_exttoui()
        except Exception as e:
            print(e)
    if uitoext_ctr >= interval_div_uitoext:
        uitoext_ctr = 0
        if not r:
            try:
                check_sync_uitoext()
            except Exception as e:
                print(e)

    tkmain.after(check_interval, check_loop)

signal.signal(signal.SIGINT, lambda x, y: tkmain.destroy())
signal.signal(signal.SIGTERM, lambda x, y: tkmain.destroy())
signal.signal(signal.SIGHUP, lambda x, y: check_sync())

tkmain.withdraw()
check_loop()
tkmain.mainloop()


