import os
import os.path
import sys
import re
import argparse
import traceback
import curses

tmux_command = 'tmux'
python_command = 'python3'

# We need to replace the current pane with a pane running the plugin script.
# Ideally this would be done without messing with any application currently running within the pane.
# So, create a new window and pane for that application.  If the created window/pane
# is larger than the current pane, divide it into sections and set the pane to the proper size.


def runcmd(command, one=False, lines=False, emptylines=False):
	f = os.popen(command)
	data = f.read()
	estatus = f.close()
	if estatus:
		raise Exception(f'Command "{command}" exited with status {estatus}')
	if one or lines: # return list of lines
		dlines = data.split('\n')
		if not one and blanklines:
			dlines = [ l for l in dlines if len(l) > 0 ]
	if one: # single-line
		return dlines[0] if len(dlines) > 0 else ''
	return dlines if lines else data

def runtmux(args, one=False, lines=False, emptylines=False):
	if isinstance(args, list):
		args = ' '.join([ "'" + str(arg).replace("'", "'\\''") + "'" for arg in args ])
	return runcmd(tmux_command + ' ' + args, one=one, lines=lines, emptylines=emptylines)

def capture_pane_contents(target=None):
	args = [ 'capture-pane', '-p' ]
	if target != None:
		args += [ '-t', target ]
	return runtmux(args)[:-1]

def get_pane_info(target=None, capture=False):
	args = [ 'display-message', '-p' ]
	if target != None:
		args += [ '-t', target ]
	args += [ '#{session_id} #{window_id} #{pane_id} #{pane_width} #{pane_height} #{window_zoomed_flag}' ]
	r = runtmux(args, one=True).split(' ')
	rdict = {
		'session_id': r[0],
		'window_id': r[1],
		'window_id_full': r[0] + ':' + r[1],
		'pane_id': r[2],
		'pane_id_full': r[0] + ':' + r[1] + '.' + r[2],
		'pane_size': (int(r[3]), int(r[4])),
		'zoomed': bool(int(r[5]))
	}
	if capture:
		rdict['contents'] = capture_pane_contents(rdict['pane_id_full'])
	return rdict

def create_window_pane_of_size(size):
	# Create a new window in the background
	window_id_full = runtmux([ 'new-window', '-dP', '-F', '#{session_id}:#{window_id}', '/bin/sh' ], one=True)
	# Get the information about the new pane just created
	pane = get_pane_info(window_id_full)
	# If the width is greater than the target width, do a vertical split.
	# Note that splitting reduces width by at least 2 due to the separator
	resize = False
	if pane['pane_size'][0] > size[0] + 1:
		runtmux([ 'split-window', '-t', pane['pane_id_full'], '-hd', '/bin/sh' ])
		resize = True
	# If too tall, do a horizontal split
	if pane['pane_size'][1] > size[1] + 1:
		runtmux([ 'split-window', '-t', pane['pane_id_full'], '-vd', '/bin/sh' ])
		resize = True
	# Resize the pane to desired size
	if resize:
		runtmux([ 'resize-pane', '-t', pane['pane_id_full'], '-x', size[0], '-y', size[1] ])
	# Return info
	pane['pane_size'] = size
	return pane

swap_count = 0
def swap_hidden_pane():
	global swap_count
	if args.swap_mode == 'pane-swap':
		# Swap target pane and hidden pane
		t1 = args.t
		t2 = args.hidden_t
		runtmux([ 'swap-pane', '-Z', '-s', t2, '-t', t1 ])
	else:
		# Switch to either the hidden window or the orig window
		if swap_count % 2 == 0:
			selectwin = args.hidden_window
		else:
			selectwin = args.orig_window
		runtmux([ 'select-window', '-t', selectwin ])
	swap_count += 1

def cleanup_internal_process():
	if swap_count % 2 == 1:
		swap_hidden_pane()
	runtmux([ 'kill-window', '-t', args.hidden_window ])

def run_wrapper(main_action, args):
	pane = get_pane_info(args.t)
	# Wrap the inner utility in different ways depending on if the pane is zoomed or not.
	# This is because tmux does funny thingy when swapping zoomed panes.
	# When an ordinary pane, use 'pane-swap' mode.  In this case, the internal utility
	# is run as a command in a newly created pane of the same size in a newly created window.
	# The command pane is then swapped with the target pane, and swapped back once complete.
	# In 'window-switch' mode, the internal utility is run as a single pane in a new window,
	# then the active window is switched to that new window.  Once complete, the window is
	# switched back.
	if pane['zoomed']:
		z_win_id = runtmux([ 'new-window', '-dP', '-F', '#{session_id}:#{window_id}', '/bin/sh' ], one=True)
		hidden_pane = get_pane_info(z_win_id)
		swap_mode = 'window-switch'
	else:
		hidden_pane = create_window_pane_of_size(pane['pane_size'])
		swap_mode = 'pane-swap'
	thisfile = os.path.abspath(__file__)
	cmd = f'{python_command} "{thisfile}"'
	def addopt(opt, val=None):
		nonlocal cmd
		if val == None:
			cmd += ' \'' + opt + '\''
		else:
			cmd += ' \'' + opt + '\' \'' + str(val) + '\''
	addopt('--run-internal')
	addopt('-t', pane['pane_id'])
	addopt('--hidden-t', hidden_pane['pane_id'])
	addopt('--hidden-window', hidden_pane['window_id'])
	addopt('--orig-window', pane['window_id'])
	addopt('--swap-mode', swap_mode)
	cmd += f' "{main_action}"'
	#cmd += ' 2>/tmp/tm_wrap_log'
	runtmux([ 'respawn-pane', '-k', '-t', hidden_pane['pane_id_full'], cmd ])


def run_easymotion(stdscr):
	orig_pane = get_pane_info(args.t, capture=True)
	overlay_pane = get_pane_info(args.hidden_t)

	curses.curs_set(False)
	curses.start_color()
	curses.use_default_colors()
	curses.init_pair(1, curses.COLOR_RED, -1)
	stdscr.clear()
	curses_size = stdscr.getmaxyx() # note: in (y,x) not (x,y)

	# display current contents
	content_lines = orig_pane['contents'].split('\n')
	line_width = min(curses_size[1], orig_pane['pane_size'][0])
	for i in range(min(curses_size[0], len(content_lines))):
		stdscr.addstr(i, 0, content_lines[i][:line_width])
	#n = 0
	#stdscr.addstr(n, 0, 'Test')
	#n += 1
	#stdscr.addstr(n, 0, str(stdscr.getmaxyx()))
	#n += 1
	stdscr.refresh()
	swap_hidden_pane()
	k = ''
	while k != 'q':
		#stdscr.addstr(n, 0, str(stdscr.getmaxyx()))
		#n += 1
		k = stdscr.getkey()
		stdscr.addstr(0, 0, str(k))
	with open('/tmp/k', 'w') as f:
		f.write(k)


argp = argparse.ArgumentParser(description='tmux pane utils')
argp.add_argument('-t', help='target pane')

# internal args
argp.add_argument('--run-internal', action='store_true')
argp.add_argument('--hidden-t')
argp.add_argument('--hidden-window')
argp.add_argument('--orig-window')
argp.add_argument('--swap-mode')

argp.add_argument('action')
args = argp.parse_args()

if not args.run_internal:
	run_wrapper(args.action, args)
	exit(0)


assert(args.t)
assert(args.t.startswith('%'))
assert(args.hidden_t)
assert(args.hidden_t.startswith('%'))
assert(args.hidden_window)
assert(args.orig_window)
assert(args.swap_mode)

try:

	os.environ.setdefault('ESCDELAY', '10') # lower curses pause on escape
	if args.action == 'easymotion':
		#swap_hidden_pane()
		curses.wrapper(run_easymotion)
	else:
		print('Invalid action')
		exit(1)

except Exception as ex:
	print('Error:')
	print(ex)
	traceback.print_exc()
	print('ENTER to continue ...')
	input()

finally:
	cleanup_internal_process()
	exit(0)




