#!/bin/sh
#
# Print the container tree for the focused workspace, then wait for a keypress.
# Bound to $mod+Shift+i, which opens it in a small floating terminal.
#
# The point is to make the structure visible. Sway's layout behaviour is driven
# entirely by the tree, but the tree is mostly invisible on screen: a container
# holding a single window renders exactly like the bare window - same borders,
# same geometry, and focusing it looks identical - while still changing what
# every directional move does. When a move "should" work and doesn't, the reason
# is almost always a container you cannot see, so this marks those explicitly
# rather than leaving them to be inferred from indentation.

python3 - <<'PY'
import json, subprocess, sys

tree = json.loads(subprocess.run(
    ["swaymsg", "-t", "get_tree", "--raw"], capture_output=True, text=True).stdout)


def find_focused_workspace(node, current=None):
    """The workspace containing the focused node, not the focused node itself."""
    if node.get("type") == "workspace":
        current = node
    if node.get("focused"):
        return current
    for child in node.get("nodes", []) + node.get("floating_nodes", []):
        found = find_focused_workspace(child, current)
        if found:
            return found
    return None


def kids(node):
    return node.get("nodes", []) + node.get("floating_nodes", [])


BOLD, DIM, RESET = "\033[1m", "\033[2m", "\033[0m"
YEL, CYA, GRN = "\033[33m", "\033[36m", "\033[32m"

ws = find_focused_workspace(tree)
if ws is None:
    print("No focused workspace found.")
    sys.exit(0)

print(f"{BOLD}workspace {ws.get('num')}{RESET}  {DIM}{ws.get('name')}{RESET}"
      f"   layout={CYA}{ws.get('layout')}{RESET}\n")

lone = 0


def render(node, depth=0):
    global lone
    pad = "  " * depth
    app = node.get("app_id") or (node.get("window_properties") or {}).get("class")
    r = node.get("rect", {})
    size = f"{DIM}{r.get('width')}x{r.get('height')}{RESET}"
    focus = f"  {GRN}<- focused{RESET}" if node.get("focused") else ""

    if app:
        name = (node.get("name") or "")[:40]
        print(f"{pad}{BOLD}* {app}{RESET}  {size}{focus}")
        if name and name != app:
            print(f"{pad}    {DIM}{name}{RESET}")
    else:
        warn = ""
        # A container with exactly one child is the invisible one: it renders
        # identically to its child but still absorbs directional moves.
        if len(kids(node)) == 1:
            warn = f"  {YEL}[lone - Super+Shift+\\ dissolves it]{RESET}"
            lone += 1
        print(f"{pad}+ {CYA}{node.get('layout')}{RESET}  {size}{focus}{warn}")

    for child in kids(node):
        render(child, depth + 1)


children = kids(ws)
if not children:
    print("  (empty)")
for child in children:
    render(child, 1)

print(f"\n{DIM}compact:{RESET} {ws.get('representation')}")
if lone:
    print(f"{YEL}{lone} single-child container(s) above.{RESET} "
          f"They are invisible on screen and are the usual reason a\n"
          f"directional move goes somewhere unexpected: moving toward a view "
          f"swaps with it,\nbut moving toward a container moves you inside it.")
PY

printf '\n\033[2mpress any key to close\033[0m'

# Any key rather than Enter: this is a glance-at-it popup. Fall back to a plain
# read where stty cannot put the terminal in raw mode (no tty, unusual $TERM).
if stty -echo -icanon min 1 time 0 2>/dev/null; then
	dd bs=1 count=1 >/dev/null 2>&1
	stty echo icanon 2>/dev/null
else
	read -r _
fi
