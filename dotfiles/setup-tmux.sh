#!/bin/bash

DOTFILES="$(realpath "$(dirname "$0")")"
INPUT_TMUX_CONF="$DOTFILES/tmux.conf"
OUTPUT_TMUX_CONF="$HOME/.tmux.conf"
TEMP_TMUX_CONF="$HOME/.tmux.conf-temp"
rm -f "$TEMP_TMUX_CONF"

# Find python
if command -v python3 &>/dev/null; then
	PYTHON=python3
elif command -v python &>/dev/null; then
	PYTHON=python
else
	echo 'Could not find python3'
	exit 1
fi

# Find tmux version
if ! command -v tmux &>/dev/null; then
	echo 'Could not find tmux'
	exit 1
fi
TMUX_VERSION="`tmux -V | cut -d ' ' -f 2`"
if [[ -z $TMUX_VERSION ]]; then
	echo 'Could not find tmux version'
	exit 1
fi
echo "tmux version: $TMUX_VERSION"

# Filter tmux.conf through python script to handle conditionals
"$PYTHON" - "$INPUT_TMUX_CONF" "$TMUX_VERSION" >"$TEMP_TMUX_CONF" <<'PYEOF'
import sys
import re
import subprocess
tmux_version = sys.argv[-1]
tmux_conf = sys.argv[-2]

def parse_tmux_vers(vers):
	m = re.search(r'([0-9]+\.)+[0-9]+[a-z]?', vers)
	if not m:
		raise Exception('Could not parse tmux version: ' + vers)
	r = []
	for c in m.group().split('.'):
		m2 = re.search(r'[a-z]', c)
		if m2:
			r.append(int(c[:m2.start()]))
			r.append(c[m2.start():])
		else:
			r.append(int(c))
	return tuple(r)

def check_tmux_version(op, vers):
	v1 = parse_tmux_vers(tmux_version)
	v2 = parse_tmux_vers(vers)
	if op == '==' or op == '=':
		return v1 == v2
	elif op == '!=':
		return not check_tmux_version('==', vers)
	elif op == '<':
		for i in range(max(len(v1), len(v2))):
			if i >= len(v1):
				return True
			elif i >= len(v2):
				return False
			elif isinstance(v1[i], str) != isinstance(v2[i], str):
				return isinstance(v1[i], str)
			elif v1[i] != v2[i]:
				return v1[i] < v2[i]
		return False
	elif op == '<=':
		return check_tmux_version('<', vers) or check_tmux_version('==', vers)
	elif op == '>=':
		return not check_tmux_version('<', vers)
	elif op == '>':
		return not check_tmux_version('<=', vers)
	else:
		raise Exception('Invalid check_tmux_version operator: ' + op)

def eval_conditional(cond):
	return eval(cond)

def make_substitutions(line):
	def subexec(match):
		cmd = match.group(1)
		r = subprocess.run(cmd, capture_output=True, shell=True, executable='/bin/bash', encoding='utf8')
		if r.returncode != 0:
			raise Exception('Error running command: ' + cmd)
		return r.stdout.strip()
	line = re.sub(r'\{\{(.*)\}\}', subexec, line)
	return line

condstack = [ True ]
with open(tmux_conf, 'r') as f:
	for line in f:
		if line.strip().startswith('#?'):
			condarg = line[line.index('?')+1:].strip()
			if len(condarg) > 0:
				if not condstack[-1]:
					condstack.append(False)
				else:
					condstack.append(eval_conditional(condarg))
			else:
				if len(condstack) <= 1:
					raise Exception('Invalid tmux.conf conditional syntax - too many closes')
				condstack.pop()
		else:
			if condstack[-1]:
				line = line.lstrip()
				if line.startswith('#$'):
					line = make_substitutions(line[2:].lstrip())
				print(line, end='')
	if len(condstack) != 1:
		raise Exception('Invalid tmux.conf conditional syntax - unclosed block')
PYEOF

if [ $? -ne 0 ]; then
	echo 'tmux.conf conditional parser returned nonzero status'
	exit 1
fi

rm -f "$OUTPUT_TMUX_CONF"
mv "$TEMP_TMUX_CONF" "$OUTPUT_TMUX_CONF"
exit 0

