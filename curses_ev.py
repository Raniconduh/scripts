#!/usr/bin/env python3

import curses

scr = curses.initscr()
curses.raw()
curses.curs_set(0)
curses.noecho()
scr.clear()
scr.refresh()

old = 0

try:
    while True:
        c = scr.getch()
        if c == old: continue
        if c == 27: break
        old = c
        scr.erase()
        scr.addstr(0, 0, chr(c))
        scr.addstr(1, 1, str(c))
        scr.refresh()
except KeyboardInterrupt:
    pass
curses.endwin()

