"" in this file some old configurations that are kept here
"    as a backup
"

" 3 tags {{{

if has('path_extra')
  setglobal tags-=./tags tags-=./tags; tags^=./tags;
endif

if has('cscope')

	if has("autocmd") && executable('cscope')
		" load cscope when entering buffer
		autocmd vimrc BufEnter /*
			\ let s:cscopeoutdb = findfile("cscope.out", ".;")
			\| if (!empty(s:cscopeoutdb))
			\| let s:csbpath = fnamemodify(s:cscopeoutdb, ':p:h')
			\| try
			\| 	exe "cs add " . s:cscopeoutdb . " " . s:csbpath
			\| catch /Vim.*/
			\|	echo v:exception
			\| catch /E568: duplicate cscope database not added/
			\| catch
			\| 	throw v:exception
			\| endtry
			\| endif
	endif

	"set csprg=/bin/cscope
	" search both ctags and cscope
	set cscopetag
	" check cscope before ctags
	set cscopetagorder=0
	set nocscopeverbose
	if has('quickfix')
		set cscopequickfix=s-,c-,d-,i-,t-,e-
	endif

endif

" }}}

" 6 multiple windows {{{
"
		" elseif &filetype =~ 'unite'
		" 	let l:color = 'StatusLineModePlugin'
		" 	let l:mode = 'Unite ' . unite#get_status_string()
		" elseif &filetype =~ 'denite'
		" 	let l:color = 'StatusLineModePlugin'
		" 	let l:mode = 'Denite ' . denite#get_status("mode")
		" elseif &filetype =~ 'undotree'
		" 	let l:color = 'StatusLineModePlugin'
		" 	let l:mode = 'Undotree'
		" elseif &filetype =~ 'bufferchooser'
		" 	let l:color = 'StatusLineModePlugin'
		" 	let l:mode = 'Buffer'

" }}}

" bufferchooser {{{

"" heavily inspired from
"=== VIM BUFFER LIST SCRIPT 1.3 ===============================================
"= Copyright(c) 2005, Robert Lillack <rob@lillack.de>                         =
"= Redistribution in any form with or without modification permitted.         =
"==============================================================================

function! s:bufferchooser_formatbuf(bufnum) abort

	let l:bol = ''

	if a:bufnum == bufnr('%')
		let l:bol .= '%a'
	elseif a:bufnum == bufnr('#')
		let l:bol .= '#'
	else
		let l:bol .= ''
	endif

	if getbufvar(a:bufnum, '&modified')
		let l:bol .= '+'
	endif

	let l:bufl = printf("%*s %-*s", len(bufnr("$")), a:bufnum, 4, l:bol)
	let l:bufl .= bufname(a:bufnum) == '' ? '<noname>' : bufname(a:bufnum)

	let l:filetype = getbufvar(a:bufnum, '&filetype')

	if l:filetype != ''
		let l:bufl .= ' '. '{' . l:filetype . '}'
	endif

	return l:bufl

endfunction

" toggle the buffer chose window
function! s:bufferchooser() abort
	if bufexists(bufnr("__buffers__"))
		exec ':' . bufnr("__buffers__") . 'bwipeout'
		return
	endif

	let l:buflist = ''

	let l:curbuffer = bufnr('%')
	let l:line = s:bufferchooser_formatbuf(l:curbuffer)
	let l:buflist .= " " . l:line . "\n"

	if bufexists(0) && bufnr('#') != l:curbuffer
		" alternate buffer exists
		let l:altbuffer = bufnr('#')
		let l:line = s:bufferchooser_formatbuf(l:altbuffer)
		let l:buflist .= " " . l:line . "\n"
	else
		let l:altbuffer = -1
	endif

	" iterate through the buffers
	let l:i = 0 | while l:i < bufnr('$') | let l:i = l:i + 1
		if l:i == l:curbuffer || (l:altbuffer >= 0 && l:altbuffer == l:i)
			continue
		endif
		if ! getbufvar(l:i, '&buflisted')
			continue
		endif
		let l:line = s:bufferchooser_formatbuf(l:i)

		" add to the list
		let l:buflist .= " " . l:line . "\n"
	endwhile

	" now, create the buffer & set it up
	exec 'silent! new __buffers__'
	setlocal noshowcmd
	setlocal noswapfile
	setlocal buftype=nofile
	setlocal bufhidden=delete
	setlocal filetype=bufferchooser
	setlocal nobuflisted
	setlocal nomodifiable
	setlocal nowrap
	setlocal nonumber

	setlocal modifiable

	silent! put! =l:buflist
	silent! normal! GkJ
	silent! normal! 0

	setlocal nomodifiable

	" set up the keymap
	noremap <silent> <buffer> <CR> :call <SID>choosebuffer()<cr>
	map <silent> <buffer> q :bwipeout<cr>
	map <silent> <buffer> <esc> :bwipeout<cr>
	map <silent> <buffer> j :call <SID>bufferchose_move(1)<cr>
	map <silent> <buffer> k :call <SID>bufferchose_move(-1)<cr>
	map <silent> <buffer> <MouseDown> k
	map <silent> <buffer> <MouseUp> j
	map <silent> <buffer> <LeftDrag> <Nop>
	map <silent> <buffer> <LeftRelease> <Nop>
	map <silent> <buffer> <2-LeftMouse> <Nop>
	map <silent> <buffer> <Down> j
	map <silent> <buffer> <Up> k
	map <buffer> h <Nop>
	map <buffer> l <Nop>
	map <buffer> <Left> <Nop>
	map <buffer> <Right> <Nop>

	if has("autocmd")
		augroup bufferchooser
			autocmd!
			autocmd BufLeave <buffer> :bwipeout
		augroup END
	endif

	" go to the correct line
	call cursor(1, 1)
	call <SID>bufferchose_move(0)
endfunction

" move the selection bar of the list
function! s:bufferchose_move(where) abort
	setlocal modifiable

	" exchange the first char (>) with a space
	call setline(line("."), " ".strpart(getline(line(".")), 1))

	let l:nexlin = line(".") + a:where

	if l:nexlin < 1
		call cursor(1, 1)
	elseif l:nexlin > line("$")
		call cursor(line("$"), 1)
	else
		call cursor(l:nexlin, 1)
	endif

	" and mark this line with a >
	call setline(line("."), ">".strpart(getline(line(".")), 1))

	setlocal nomodifiable
endfunction

" loads the selected buffer
function! s:choosebuffer() abort

	echohl ErrorMsg | echomsg "Failed to retrieve buffer#" | echohl NONE

	let l:num=str2nr(substitute(matchstr(getline(line(".")), '^.\(\d\+\)'),
					\ ">", "", "g"))

	if 0 < l:num

		" kill the buffer list
		bwipeout
		" ...and switch to the buffer number
		exec ":b " . l:num
	else
		echohl ErrorMsg | echomsg "Failed to retrieve buffer#" | echohl NONE
	endif
endfunction

nnoremap <silent><Plug>Bufferchooser  :<C-U>call <SID>bufferchooser()<CR>

" }}}

" vim: set ft=vim ts=8 sw=8 tw=78 noet fdm=marker :
