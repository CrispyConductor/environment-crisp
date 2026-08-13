let s:sdir = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let s:ysshpush = s:sdir . '/vimyanksyncpush.sh'
let s:ysshpull = s:sdir . '/vimyanksyncpull.sh'
let s:ysshgetbuf = s:sdir . '/getcopybuffer.sh'

" Shifts register 0->1, 1->2, etc. then sets reg 0 to the given value
" Expects a linewise list for newcontents
function! YankSyncShiftRegs(newcontents)
	for i in [9, 8, 7, 6, 5, 4, 3, 2, 1]
		let rtype = getregtype(i - 1)
		let rcontents = getreg(i - 1, 1, rtype ==# 'V')
		call setreg(i, rcontents, rtype)
	endfor
	" If the new contents ends with a NL (empty list entry), remove the
	" empty entry and setreg linewise.  Otherwise, setreg characterwise.
	if len(a:newcontents) == 0
		call setreg(0, [], 'cu')
	elseif empty(a:newcontents[-1])
		call setreg(0, a:newcontents[0:-2], 'lu')
	else
		call setreg(0, a:newcontents, 'cu')
	endif
endfunction

function! YankSyncPurgeRegs(newcontents)
	for i in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, '']
		call setreg(i, a:newcontents, 'c')
	endfor
endfunction

" Returns register contents as list of lines, including trailing blank line if
" applicable
function! YankSyncGetRegLines(regname)
	return getreg(a:regname, 1, 1) + (getregtype(a:regname) ==# 'v' ? [] : [''])
endfunction

" Triggered when text is yanked in vim
function! YankSyncPush(regname)
	if empty(a:regname)
		let contents = YankSyncGetRegLines(a:regname)
		call system(s:ysshpush, contents)
	endif
endfunction

" Triggered externally to cause vim to pull in external buffer
function! YankSyncPull()
	let newbuf = systemlist(s:ysshpull, '', 1)
	if v:shell_error == 0
		if newbuf == ['!!!___PURGED___!!!']
			call YankSyncPurgeRegs(newbuf)
		else
			let curcontents = YankSyncGetRegLines(0)
			if curcontents != newbuf
				call YankSyncShiftRegs(newbuf)
			endif
		endif
	endif
endfunction

" Synchronizes all numbered registers to external buffers
function! YankSyncPullAll()
	"for i in [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]
	for i in [0] " just load one to speed up startup
		let newbuf = systemlist(s:ysshgetbuf . ' ' . string(i), '', 1)
		if v:shell_error == 0
			call YankSyncShiftRegs(newbuf)
		endif
	endfor
endfunction

augroup clipmgmt
	autocmd!
	autocmd TextYankPost * call YankSyncPush(v:event['regname'])
	silent! autocmd Signal SIGUSR1 call YankSyncPull()
	autocmd VimEnter * call YankSyncPullAll()
augroup END


