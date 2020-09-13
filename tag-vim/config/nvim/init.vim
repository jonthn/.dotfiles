" follow the :options order


" 1. important {{{

scriptencoding utf-8

" XDG

if empty($XDG_CONFIG_HOME)
	let $XDG_CONFIG_HOME = $HOME.'/.config'
endif
if empty($XDG_CACHE_HOME)
	let $XDG_CACHE_HOME = $HOME.'/.cache'
endif
if empty($XDG_DATA_HOME)
	let $XDG_DATA_HOME = $HOME.'/.local/share'
endif

if has('nvim')
	let $XDG_CACHE_BASEDIR = $XDG_CACHE_HOME.'/nvim'
else
	let $XDG_CACHE_BASEDIR = $XDG_CACHE_HOME.'/vim'
endif

if !isdirectory($XDG_DATA_HOME)
	if exists("*mkdir")
		if has('nvim')
			call mkdir($XDG_DATA_HOME.'/nvim', "p")
		else
			call mkdir($XDG_DATA_HOME.'/vim', "p")
		endif
	endif
endif

" set <mapleader> early so it gets propagated correctly
let g:mapleader = "\<Space>"
" let g:mapleader = ","
" map space to leader but this way we get a hint in commandline
" map <space> <leader>

" this one is for certain filetype / local to a buffer
let g:maplocalleader = '_'

" remember start directory
let g:vim_start_dir = getcwd()

" define a group `vimrc` and initialize.
if has("autocmd")
	augroup vimrc
		autocmd!
	augroup END
endif

" }}}

" 2 moving around, searching and patterns {{{

set whichwrap+=<,>,h,l

" automatically switch to buffer directory
" if exists('+autochdir')
" 	set autochdir
" else
" 	if has("autocmd")
" 		autocmd vimrc BufEnter * silent! lcd %:p:h
" 	endif
" endif
"

if has("autocmd")
	autocmd BufWritePost $MYVIMRC source $MYVIMRC
endif


" search goes back to top when @bottom
set wrapscan
if has('extra_search')
	" show search matches as you type
	set incsearch
endif
" ignore case during a search
set ignorecase
" ignore case if pattern is all lowercase
set smartcase

" In visual mode when you press * or # to search for the current selection

if has('timers')
	" Blink 2 times with 75ms interval
	noremap <expr> <plug>(slash-after) 'zz'.Slash_blink(2, 75)
else
	noremap <plug>(slash-after) zz
endif


set errorformat^=%f:%l:%c\ %m
" :g/foo/# but persistent (see :global)
command! -nargs=1 Gl lgetexpr filter(map(getline(1,'$'), {key, val -> expand("%") . ":" . (key + 1) . ":1 " . val }), { idx, val -> val =~ <q-args> })

" function : hack <cr> to make list-like commands more intuitive {{{
"  (details) https://gist.github.com/romainl/047aca21e338df7ccf771f96858edb86
"  (latest version) https://gist.github.com/romainl/5b2cfb2b81f02d44e1d90b74ef555e31
function! s:ccr()
    let cmdline = getcmdline()
    command! -bar Z silent set more|delcommand Z
    if getcmdtype() != ':'
	if exists("*<sid>wrap")
		return <sid>wrap("\<cr>")
	else
		return "\<cr>"
	endif
    endif
    if cmdline =~ '\v\C^(ls|files|buffers)'
        " like :ls but prompts for a buffer command
        return "\<cr>:b "
    elseif cmdline =~ '\v\C/(#|nu|num|numb|numbe|number)$'
        " like :g//# but prompts for a command
        return "\<cr>:"
    elseif cmdline =~ '\v\C^(dli|il)'
        " like :dlist or :ilist but prompts for a count for :djump or :ijump
        return "\<cr>:" . cmdline[0] . "j  " . split(cmdline, " ")[1] . "\<S-Left>\<Left>"
    elseif cmdline =~ '\v\C^(cli|lli)'
        " like :clist or :llist but prompts for an error/location number
        return "\<cr>:sil " . repeat(cmdline[0], 2) . "\<Space>"
    elseif cmdline =~ '\C^old'
        " like :oldfiles but prompts for an old file to edit
        set nomore
        return "\<cr>:Z|e #<"
    elseif cmdline =~ '\C^changes'
        " like :changes but prompts for a change to jump to
        set nomore
        return "\<cr>:Z|norm! g;\<S-Left>"
    elseif cmdline =~ '\C^ju'
        " like :jumps but prompts for a position to jump to
        set nomore
        return "\<cr>:Z|norm! \<C-o>\<S-Left>"
    elseif cmdline =~ '\C^marks'
        " like :marks but prompts for a mark to jump to
        return "\<cr>:norm! `"
    elseif cmdline =~ '\C^undol'
        " like :undolist but prompts for a change to undo
        return "\<cr>:u "
    else
        return "\<cr>"
    endif
endfunction

" }}}

" mapping Enter (<cr>) to s:ccr() function
cnoremap <expr> <cr> <sid>ccr()

" }}}

" 3 tags {{{

" jump to a tag/help/.. using Control-@
map <C-@>   <C-]>

" }}}

" 4 displaying text {{{

" always 2 lines above & below current line
set scrolloff=2
set sidescrolloff=5
"
set display+=lastline
" do not wrap long lines
set nowrap
" wrap at a space instead of in a word
set linebreak
" show ↪  at the beginning of wrapped lines
let &showbreak=nr2char(8618).' '
if (v:version > 704 || v:version == 704 && has('patch338'))
	set breakindent
	set breakindentopt=sbr
endif
" use :set list! to toggle formatting character (linefeed, tab, ...)
if !has('win32') && (&termencoding ==# 'utf-8' || &encoding ==# 'utf-8')
	set listchars=tab:→·,trail:¬,extends:›,precedes:‹,nbsp:○,eol:¶
else
	set listchars=tab:>\ ,trail:-,extends:>,precedes:<,nbsp:+,eol:¶
endif

" no refresh when a script is running
set lazyredraw
" always show line numbers
set number

" }}}

" 5 syntax, highlighting and spelling {{{

" function : load colorscheme from a list {{{
"
function! s:loadcolorscheme(schemes) abort
	for l:scheme in a:schemes
		try
			execute "colorscheme" l:scheme
			break
		catch
		endtry
	endfor
endfunction
" }}}

" function : adapt colorscheme {{{
"
function! s:adapt_colorscheme(...) abort

	" force_type
	"  - dynamic
	"  - toggle (alternate dark / light)
	"  - dark
	"  - light
	let l:force_type = get(a:, 1, 'dynamic')

	let l:colorschemes = [ 'zellner', 'morning' ]
	if !has('gui_running') && !((&t_Co == 88) || (&t_Co == 256))
		call insert(l:colorschemes, 'slate')
	endif

	let l:sel_background='dark'

	if force_type == "dynamic"
		if strftime('%H') >= 9 && strftime('%H') < 17
			let l:sel_background='light'
		else
			let l:sel_background='dark'
		endif
	elseif force_type == "toggle"
		let l:sel_background=( &background == "dark"? "light" : "dark" )
	elseif force_type == "dark"
		let l:sel_background='dark'
	elseif force_type == "light"
		let l:sel_background='light'
	endif

	redir => l:current_colorscheme
	silent colorscheme
	redir END
	let l:current_colorscheme = substitute(l:current_colorscheme, "\n", "", "g")

	let l:require_dark_cs = [ 'tender' , 'monokai_pro' ]
	let l:cs = [ 'cosmic_latte', 'snow', 'tender', 'monokai_pro', 'seoul256' , 'two-firewatch', 'hemisu' ]
	let l:colorschemes = l:cs + l:colorschemes

	if 'dark' == l:sel_background
		" nothing to filter
	elseif "light" == l:sel_background
		call filter(l:colorschemes, '0 <= index(l:require_dark_cs, v:val) ? 0 : 1')
	endif

	" apply settings
	let &background = l:sel_background
	" echohl ErrorMsg | echomsg "List colorscheme(s) " . join(l:colorschemes, ':') | echohl NONE
	call <sid>loadcolorscheme(l:colorschemes)

	" Useful for demonstration
	":colorscheme shoji_niji

endfunction
" }}}

command! ThemeAdapt call s:adapt_colorscheme()
command! ThemeToggle call s:adapt_colorscheme('toggle')
command! ThemeDark call s:adapt_colorscheme('dark')
command! ThemeLight call s:adapt_colorscheme('light')
command! ThemeDemo colorscheme shoji_niji

filetype plugin indent on

if has('syntax')
	let g:load_doxygen_syntax=1

	" activates syntax highlighting
	"  [-] on :	overrrides even the default
	"  [-] enable : allow overrides (:h highlight)
	syntax enable
	" syntax sync fromstart
	syntax sync minlines=100
	syntax sync maxlines=300
	set synmaxcol=800

	function! SyntaxDescribeCursor()
		let l:s = synID(line('.'), col('.'), 1)
		echo synIDattr(l:s, 'name') . ' -> ' . synIDattr(synIDtrans(l:s), 'name')
	endfunction

	command! SyntaxIdentify call SyntaxDescribeCursor()
endif

" syntax coloring lines that are too long just slows down the world
if has('extra_search')
	" highlight search terms
	set hlsearch
endif

if exists('+colorcolumn')
	" highlight the column 80
	set colorcolumn=80

	function! s:colorcolumn_colorscheme() abort
		if !hlexists("ColorColumn") && hlexists("Error")
			highlight! link  ColorColumn Error
		endif
	endfunction

	if !hlexists("ColorColumn")
		call s:colorcolumn_colorscheme()
	endif

	if has("autocmd")
		autocmd vimrc ColorScheme * call <SID>colorcolumn_colorscheme()
	endif

endif

if has('conceal')
	set conceallevel=1 concealcursor=i
	set listchars += "conceal:\u2206"       " nr2char(8710)
endif

if has('spell')
	" maximum 5 suggestion in order to correct an error
	set spellsuggest=5
	if !has('nvim')
		set spell spelllang=
	endif

	" Language : FR
	command! LangFR :setlocal spell spelllang=fr<cr>
	" Language : EN
	command! LangEN :setlocal spell spelllang=en<cr>
	" Language : None
	command! LangNONE :setlocal spell spelllang=<cr>

endif

" }}}

" 6 multiple windows {{{

if has('windows')

	function! s:tabline_colorscheme() abort
		highlight! TabLine guifg=#e5e9f0 guibg=#4c566a ctermfg=7 ctermbg=8
		highlight! TabLineSel guifg=#3b4252 guibg=#88c0d0 ctermfg=0 ctermbg=6
		highlight! TabLineFill guifg=#e5e9f0 guibg=#4c566a ctermfg=7 ctermbg=8
	endfunction

	function Tabline_expression() abort
		let l:s = ''
		for i in range(tabpagenr('$'))
			let l:tab=i+1
			let l:buflist = tabpagebuflist(tab) " list of buffers associated with the windows in the current tab
			let l:winnr = tabpagewinnr(tab) " gets current window of current tab
			let l:bufname = bufname(buflist[winnr - 1]) " current buffer name
			let l:windows = tabpagewinnr(tab,'$') " get the number of windows in the current tab

			" select the highlighting
			if l:tab == tabpagenr()
				let l:s .= '%#TabLineSel#'
			else
				let l:s .= '%#TabLine#'
			endif

			" set the tab page number (for mouse clicks)
			let l:s .= '%' . tab . 'T'

			if empty(bufname)
				let l:s .= ' <noname> '
			else
				let l:s .= ' ' . fnamemodify(bufname, ':t') . ' '
			endif

			if 1 < l:windows
				" if there's more than one, add a colon and display the count
				let l:s .= '{' . l:windows . '} '
			endif

		endfor

		" after the last tab fill with TabLineFill and reset tab page nr
		let l:s .= '%#TabLineFill#%T'

		" right-align the label to close the current tab page
		if tabpagenr('$') > 1
			let l:s .= '%=%#TabLine#%999X[x]'
		endif

		return l:s
	endfunction

	if has("autocmd")
		autocmd vimrc ColorScheme * call <SID>tabline_colorscheme()
	endif

	" tabline colorscheme
	call <SID>tabline_colorscheme()

	" set function for tabline
	set tabline=%!Tabline_expression()
endif

if has('statusline')

	let s:stl_active = ''
	let s:stl_inactive = ''

	function! s:switch_stl(...) abort
		let enabled = get(a:, 1, 1)
		let w = winnr()
		for n in range(1, winnr('$'))
			if !enabled
				call setwinvar(n, '&statusline', ' ')
			else
				call setwinvar(n, '&statusline', n != w ?
							\s:stl_inactive : s:stl_active)
			endif
		endfor
	endfunction

	command! StatusCustomLineNO call <sid>switch_stl(0)
	command! StatusCustomLineACTIVE call <sid>switch_stl(1)

	function! s:statusline_colorscheme() abort

		highlight! StatusLine guifg=#ffffff guibg=#45474f ctermfg=15 ctermbg=238
		highlight! StatusLineNC guifg=#1c1d21 guibg=#45474f ctermfg=234 ctermbg=238

		let l:stl_bg_term = synIDattr(hlID("StatusLine"), "bg", "cterm")
		let l:stl_bg_gui = synIDattr(hlID("StatusLine"), "bg", "gui")

		highlight! StatusLineModeNormal guifg=#fdf6e3 guibg=#268bd2 ctermfg=230 ctermbg=33
		highlight! StatusLineModeInsert guifg=#282a36 guibg=#50fa7b gui=bold ctermfg=235 ctermbg=84
		highlight! StatusLineModeVisual guifg=#444444 guibg=#f2c68a ctermfg=238 ctermbg=216
		highlight! StatusLineModeReplace guifg=#30302c guibg=#df5f87 ctermfg=236 ctermbg=168
		highlight! StatusLineModeTerminal guifg=#282a36 guibg=#bd93f9 ctermfg=235 ctermbg=141
		highlight! StatusLineModePlugin guifg=#fdf6e3 guibg=#6c71c4 ctermfg=230 ctermbg=61
		highlight! StatusLineModeNC guifg=#002b36 guibg=#657b83 ctermfg=234 ctermbg=240

		"highlight! StatusLineModeNormal guifg=#30302c guibg=#87afaf ctermfg=236 ctermbg=109
		" highlight! StatusLineModePlugin guifg=#fdf6e3 guibg=#073642 ctermfg=230 ctermbg=235

		" Active statusline
		highlight! StatusLineContext guifg=#fafafa guibg=#1c1d21 ctermfg=15 ctermbg=234
		highlight! StatusLineFile guifg=#e5cd52 guibg=#686b78 ctermfg=221 ctermbg=242
		highlight! StatusLineOperation guifg=#30302c guibg=#949484 ctermfg=236 ctermbg=246

		highlight! StatusLineFileDetails guifg=#a8a897 guibg=#1c1d21 ctermfg=248 ctermbg=234
		highlight! StatusLineFilePosition guifg=#282a36 guibg=#bd93f9 ctermfg=235 ctermbg=141
		highlight! StatusLineCursorPosition guifg=#f8f8f2 guibg=#6272a4 ctermfg=231 ctermbg=61

		" Non active / NC (Non Current)
		highlight! StatusLineNCContext guifg=#fafafa guibg=#1c1d21 ctermfg=15 ctermbg=234
		highlight! StatusLineNCFile guifg=#666656 guibg=#30302c ctermfg=242 ctermbg=236
		highlight! StatusLineNCOperation guifg=#30302c guibg=#949484 ctermfg=236 ctermbg=246

		highlight! StatusLineNCFileDetails guifg=#a8a897 guibg=#1c1d21 ctermfg=248 ctermbg=234
		highlight! StatusLineNCFilePosition guifg=#8be9fd guibg=#282a36 ctermfg=117 ctermbg=235
		highlight! StatusLineNCCursorPosition guifg=#f8f8f2 guibg=#282a36 ctermfg=231 ctermbg=235

		" invariant group(s)
		if empty(l:stl_bg_gui) || empty(l:stl_bg_term)
			highlight! StatusLineSyntaxError guifg=Red ctermfg=9
			highlight! StatusLineSyntaxWarning guifg=#ffaa00 ctermfg=214
		else
			execute 'highlight! StatusLineSyntaxError guifg=Red guibg='.l:stl_bg_gui.' ctermfg=9 ctermbg='.l:stl_bg_term
			execute 'highlight! StatusLineSyntaxWarning guifg=#ffaa00 guibg='.l:stl_bg_gui.' ctermfg=214 ctermbg='.l:stl_bg_term
		endif

		if empty(l:stl_bg_gui) || empty(l:stl_bg_term)
			highlight! link StatusLineFileChangesPlus DiffAdd
			highlight! link StatusLineFileChangesModified DiffChange
			highlight! link StatusLineFileChangesMinus DiffDelete
		else
			execute 'highlight! StatusLineFileChangesPlus guifg=#50fa7b guibg='.l:stl_bg_gui.' ctermfg=84 ctermbg='.l:stl_bg_term
			execute 'highlight! StatusLineFileChangesModified guifg=#f1fa8c guibg='.l:stl_bg_gui.' ctermfg=228 ctermbg='.l:stl_bg_term
			execute 'highlight! StatusLineFileChangesMinus guifg=#ff79c6 guibg='.l:stl_bg_gui.' ctermfg=212 ctermbg='.l:stl_bg_term
		endif

	endfunction

	function! s:statusline_sepleft() abort
		let l:sepleft = ''
		if has('multi_byte')
			let l:sepleft = '≫'
		else
			let l:sepleft = '>'
		endif

		return l:sepleft
	endfunction

	function! s:statusline_sepright() abort
		let l:sepright = ''
		if has('multi_byte')
			let l:sepright = '≪'
		else
			let l:sepright = '<'
		endif

		return l:sepright
	endfunction

	function! s:stl_no_details()
		return (&filetype =~ 'vim-plug'
					\|| &filetype == 'help'
					\|| &filetype == 'qf'
					\) ? 1 : 0
	endfunction

	function! Stl_mode() abort
		let l:mode = ''
		let l:color = 'StatusLineModeNormal'

		if &filetype =~ 'help'
			let l:color = 'StatusLineModePlugin'
			let l:mode = 'help ⚐'
		elseif &filetype =~ 'vim-plug'
			let l:color = 'StatusLineModePlugin'
			let l:mode = 'Plug'
		elseif &filetype =~ 'qf'
			let l:color = 'StatusLineModePlugin'
			let l:mode = '※'
		else
			" Vim mode otherwise
			let l:mode = mode()

			if l:mode =~# '\v(v|V|)'
				" Visual mode
				let l:color = 'StatusLineModeVisual'

				if l:mode ==# 'v'
					let l:mode = 'VISUAL'
				elseif l:mode ==# 'V'
					let l:mode = 'V·LINE'
				elseif l:mode ==# ''
					let l:mode = 'V·BLOCK'
				endif

			elseif l:mode =~# '\v(s|S|)'
				" Select mode
				let l:color = 'StatusLineModeVisual'

				if l:mode ==# 's'
					let l:mode = 'SELECT'
				elseif l:mode ==# 'S'
					let l:mode = 'S·LINE'
				elseif l:mode ==# ''
					let l:mode = 'S·BLOCK'
				endif
			elseif l:mode =~# '\vi'
				" Insert mode
				let l:color = 'StatusLineModeInsert'

				let l:mode = 'INSERT'

			elseif l:mode =~# '\v(R|Rv)'
				" Replace mode
				let l:color = 'StatusLineModeReplace'

				let l:mode = 'REPLACE'
			elseif l:mode =~# '\vt'
				" Terminal mode
				let l:color = 'StatusLineModeTerminal'

				let l:mode = 'TERMINAL'
			else
				let l:color = 'StatusLineModeNormal'

				" Fallback to normal mode
				let l:mode = 'NORMAL' " Normal (current)
			endif
		endif

		if winwidth(0) < 60
			let l:mode = strcharpart(l:mode, 0, 1)
		endif
		if &paste
			let l:mode = l:mode . ' 〃'
		endif

		execute 'highlight! link StatusLineMode ' . l:color

		return l:mode
	endfunction

	function! Stl_context() abort
		let l:context=''

		try
			if exists('*fugitive#head')
				let mark = 'ש '  " edit here for cool mark
				let _ = fugitive#head()
				if strlen(_)
					let l:context = mark._
				endif
			endif
		catch
		endtry

		return l:context
	endfunction

	function! Stl_filename() abort
		let l:filename = ''
		let l:fname = expand('%:t')
		if &filetype =~ 'vim-plug' || &filetype =~ 'qf'
			let l:filename = ''
		elseif &filetype =~ 'help'
			let l:filename = '' != fname ? fname : ''
		elseif 25 < winwidth(0)
			let l:ro = &readonly ? 'ro' : ''
			let l:modif = &modified ? '+' : &modifiable ? '' : '-'
			let l:file = '' != fname ? fname : '<noname>'

			let l:filename = join(filter([l:ro, l:file, l:modif], '!empty(v:val)'), ' ')
		endif

		return l:filename
	endfunction

	function! Stl_operation() abort
		let l:operation = ''

		return l:operation
	endfunction

	function! Stl_filesyntax_symbol(type) abort
		let l:filesyntax_symbol = ''
		let l:symbols= [ 'E', 'W' ]
		if has('multi_byte')
			" let l:symbols= [ '×', '∧' ]
			let l:symbols= [ '⨉', '⚠' ]
		endif
		if !empty(Stl_filesyntax_count(a:type))
			let l:filesyntax_symbol = l:symbols[a:type]
		endif

		return l:filesyntax_symbol
	endfunction

	function! Stl_filesyntax_count(type) abort
		let l:filesyntax_count = ''
		if exists('*ale#statusline#Count')
			let l:counts = ale#statusline#Count(bufnr(''))
			let l:syntx = 0
			if 0 == a:type
				let l:syntx = l:counts.error + l:counts.style_error
			elseif 1 == a:type
				let l:syntx = l:counts.total - (l:counts.error + l:counts.style_error)
			endif
			if 0 != l:syntx
				let l:filesyntax_count = printf('%d', l:syntx)
			endif
		endif

		return l:filesyntax_count
	endfunction

	function! Stl_filechange_symbol(type) abort
		let l:filechange_symbol = ''
		" added , modified , removed
		let l:symbols= [ '+', '~', '-' ]
		if has('multi_byte')
			let l:symbols= [ '✚ ', '✹ ', '✖ ' ]
		endif

		if !empty(Stl_filechange_count(a:type))
			let l:filechange_symbol = l:symbols[a:type]
		endif

		return l:filechange_symbol
	endfunction

	function! Stl_filechange_count(type) abort
		let l:filechange_count = ''
		let l:changes = []

		if get(g:, 'loaded_signify') &&
					\exists('*sy#repo#get_stats') &&
					\exists('*sy#buffer_is_active') &&
					\sy#buffer_is_active()
			let l:changes = sy#repo#get_stats()
		endif

		if !empty(l:changes) && 0 < l:changes[a:type]
			let l:filechange_count = printf('%d', l:changes[a:type])
		endif

		return l:filechange_count
	endfunction

	function! Stl_filedetails() abort
		let l:filedetails = ''
		if !<SID>stl_no_details()
			let l:fileelements = []
			call add(l:fileelements, Stl_fileformat())
			call add(l:fileelements, Stl_fileencoding())
			call add(l:fileelements, Stl_filetype())
			if 70 < winwidth(0)
				let l:filedetails = join(filter(l:fileelements,
							\'!empty(v:val)'),
							\' '.<SID>statusline_sepright().' ')
			endif
		endif

		return l:filedetails
	endfunction

	function! Stl_fileformat() abort
		let l:fileformat = ''

		let l:fileformat = &fileformat . '('
		if &softtabstop == &shiftwidth || (&softtabstop <= 0 && &tabstop == &shiftwidth)
			let l:fileformat .= 'tab:'. &softtabstop ? &softtabstop : &tabstop
		else
			let l:fileformat .= 't'.&tabstop
			let l:fileformat .= 'w'.&shiftwidth
			if (&softtabstop > 0)
				let l:fileformat .= 's'.&softtabstop
			endif
		endif
		let l:fileformat .= ')'

		return l:fileformat
	endfunction

	function! Stl_fileencoding() abort
		let l:fileencoding = strlen(&fenc) ? &fenc : &enc

		return l:fileencoding
	endfunction

	function! Stl_filetype() abort
		let l:filetype = strlen(&filetype) ? &filetype : 'no ft'

		return l:filetype
	endfunction


	function! s:statusline_format(changes) abort


		" create inactive statusline first
		set statusline=
		set statusline+=\ %#StatusLineModeNC#%(\ %{Stl_mode()}\ %)%0*
		set statusline+=%#StatusLineNCFile#%(\ %{Stl_filename()}\ %)%0*
		" separation between left/right
		set statusline+=%=
		" truncate from here if it's too long
		set statusline+=%<
		set statusline+=%#StatusLineNCFilePosition#\ %P\ %0*
		set statusline+=%#StatusLineNCCursorPosition#\ %-(%4l:%2c%)\ %0*

		" let g:statuslineNC=&statusline
		let s:stl_inactive=&statusline

		" create active (standard) statusline in second
		set statusline=
		set statusline+=\ %#StatusLineMode#%(\ %{Stl_mode()}\ %)%0*
		set statusline+=%#StatusLineContext#%(\ %{Stl_context()}\ %)%0*
		set statusline+=%#StatusLineFile#%(\ %{Stl_filename()}\ %)%0*
		set statusline+=%#StatusLineOperation#%(\ %{Stl_operation()\ }%)%0*

		" separation between left/right
		set statusline+=%=
		" truncate from here if it's too long
		set statusline+=%<

		set statusline+=%(%#StatusLineSyntaxError#%{Stl_filesyntax_symbol(0)}%0*\ %{Stl_filesyntax_count(0)}\ %)
		set statusline+=%(%#StatusLineSyntaxWarning#%{Stl_filesyntax_symbol(1)}%0*\ %{Stl_filesyntax_count(1)}\ %)
		if a:changes
			set statusline+=%(%#StatusLineFileChangesPlus#%{Stl_filechange_symbol(0)}%0*%{Stl_filechange_count(0)}\ %)
			set statusline+=%(%#StatusLineFileChangesModified#%{Stl_filechange_symbol(1)}%0*%{Stl_filechange_count(1)}\ %)
			set statusline+=%(%#StatusLineFileChangesMinus#%{Stl_filechange_symbol(2)}%0*%{Stl_filechange_count(2)}\ %)
		endif
		set statusline+=%#StatusLineFileDetails#%(\ %{Stl_filedetails()}\ %)%0*

		" replace %c with %v to take into account tabstop value offset
		set statusline+=%#StatusLineFilePosition#\ %P\ %0*
		set statusline+=%#StatusLineCursorPosition#\ %-(%4l:%2c%)\ %0*

		" let g:statuslineC=&statusline
		let s:stl_active=&statusline

		highlight! link StatusLineMode StatusLineModeNormal

		if has("autocmd")
			augroup stl
				autocmd!
				" autocmd WinEnter * let &l:statusline = s:stl_active
				" autocmd WinLeave * let &l:statusline = s:stl_inactive
				autocmd WinEnter,BufWinEnter,FileType,SessionLoadPost * call s:switch_stl()
			augroup END
		endif

	endfunction

	if has("autocmd")
		autocmd vimrc ColorScheme * call <SID>statusline_colorscheme()
	endif

	" create highlight group even if they're cleared aftewards by
	" colorscheme
	call <SID>statusline_colorscheme()
	" finally set the statusline
	call <SID>statusline_format(1)
	" set statusline=%!Statusline_expression()

	" display statusline
	set laststatus=2

endif

" turn off needless toolbar on gvim/MacVim
set guioptions-=T
" buffer are hidden not closed
set hidden
" switch to already opened buffer instead of replacing current window buffer
set switchbuf=usetab,useopen

" use a simpler version for switching buffer when no plugins are available
"  use nmap as <cr> has to be 'expanded' into s:ccr()
nmap <leader><Space> :<C-u>buffers<cr>

" go to alternate buffer
nnoremap <bs> :buffer#<cr>

" }}}

" 7 multiple tab pages {{{
" }}}

" 8 terminal {{{

" assume fast terminal connection
set ttyfast

if &term =~ '256color'
	" Disable Background Color Erase (BCE) so that color schemes
	" work properly when Vim is used inside tmux and GNU screen.
	" See also http://snk.tuxfamily.org/log/vim-256color-bce.html
	set t_ut=
endif

if has('nvim') || has('terminal')
	tnoremap <Esc> <c-\><c-n>
endif

" }}}

" 9 using the mouse {{{

if !has('gui_running')
	" scroll in normal/insert mode
	set mouse=ni
endif

" }}}

" 10 GUI {{{

if has('gui_running')
	set guifont=Hack:h12,Code\ New\ Roman:h13,ProggyDotted:h13,Input:h14,Fira\ Code:h12
endif

" }}}

" 11 printing {{{
" }}}

" 12 messages and info {{{

" abbr. messages (avoids 'hit enter')
set shortmess+=filmxoOtTc
if ((has('nvim') && has('nvim-0.4')) ||
			\ (!has('nvim') &&
			\ (v:version > 800 || v:version == 800 && has('patch1270'))))
	" show count for matches
	set shortmess-=S
else
endif

" don't need to see the mode it's already displayed
set noshowmode

if has('cmdline_info')
	" show ruler (position)
	set ruler
	" a ruler on steroids
	set rulerformat=%30(%=\:b%n%y%m%r%w\ %l,%c%V\ %P%)
	" display an incomplete command in status
	set showcmd
endif

" no sound
set noerrorbells
" no flash in terminal we set visualbell with an empty code for flash
set visualbell t_vb=
if has('autocmd')
	autocmd vimrc GUIEnter * set visualbell t_vb=
endif

try
	" messages in system C language
	lang C
catch
endtry

" }}}

" 13 selecting text {{{

" Paste previous yank over current inner word
"nnoremap <leader>P "_diwP
nnoremap ,P "_diwP
" Paste previous yank over current visual selection
"xnoremap <leader>P "_dP
xnoremap ,P "_dP

" }}}

" 14 editing text {{{

" standard allowed text width
"set textwidth=79
set backspace=indent,eol,start
set formatoptions+=1
if (v:version > 703 || v:version == 703 && has('patch584'))
	" Delete comment character when joining commented lines
	set formatoptions+=j
endif

if has('digraphs')
	" add ellipsis (…) to digraphs
	digraph ., 8230
	" Mac command key (PLACE OF INTEREST SIGN)
	digraph %% 8984
endif

set showmatch

" match more than 1 char group using matchit
runtime! macros/matchit.vim

" extended '%' with ignorecase option
let b:match_ignorecase = 1

if has('insert_expand')
	" don't look in current file and includes files
	set complete-=i
	" completion options
	set completeopt=menu,menuone,longest
	" limit popup menu height
	set pumheight=15
endif

command! Time :normal i <C-R>=strftime('%H:%M')<CR><ESC>
command! Date :normal i <C-R>=strftime('%Y-%m-%dT%H:%M:%S')<CR><ESC>

" Toggle line commenting but in a more basic way than tcomment
"  S-c would normally delete the line and change the content the
"  equivalent of 'c'
nmap <S-c> <Plug>CommentaryLine
xmap <S-c> <Plug>Commentary

" }}}

" 15 tabs and indenting {{{

set tabstop=8                       " for maximum compatibility use 8
set shiftwidth=8                    " number of spaces to use for autoindenting
set smarttab                        " insert tabs on the start of a line
"set softtabstop=8                   " a tab is X spaces
set shiftround                      " use multiple of shiftwidth with '<' / '>'
set noexpandtab                     " insert real tab not spaces
set autoindent                      " always set autoindenting on
set copyindent                      " copy the previous indentation level

" credits romainl/minivimrc
" commands for adjusting indentation rules manually
command! -nargs=1 Spaces let b:wv = winsaveview() | execute "setlocal tabstop=" . <args> . " expandtab"   | silent execute "%!expand -it "  . <args> . "" | call winrestview(b:wv) | setlocal ts? sw? sts? et?
command! -nargs=1 Tabs   let b:wv = winsaveview() | execute "setlocal tabstop=" . <args> . " noexpandtab" | silent execute "%!unexpand -t " . <args> . "" | call winrestview(b:wv) | setlocal ts? sw? sts? et?


if has("autocmd")
	autocmd vimrc FileType c,cpp,objc set cinoptions+=:0,t0,(0
end

if has("autocmd")
	autocmd vimrc FileType make setlocal softtabstop=0 shiftwidth=8 tabstop=8 noexpandtab
endif

" }}}

" 16 folding {{{
" }}}

" 17 diff mode {{{

if has('diff')
	" diff in vertical and space is a change
	try
		set diffopt+=iwhite
	catch /E474:/
	endtry
	try
		set diffopt+=vertical
	catch
	endtry
endif

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
	command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
				\ | wincmd p | diffthis
endif

" Put/Get diff with visual selection
command! -range DG '<,'>diffget
command! -range DP '<,'>diffput
xnoremap dp :diffput<cr>
xnoremap do :diffget<cr>

nnoremap <C-k> [c
nnoremap <C-j> ]c

" }}}

" 18 mapping {{{

" don't wait 1s when pressing <esc>
set timeout timeoutlen=360 ttimeoutlen=80

" For quick recordings just type qq to start recording, then q to stop
"   afterwards Q to play it :)
nnoremap Q @q

" be consistent
nnoremap U <C-r>

inoremap <C-U> <C-G>u<C-U>

" Yank (copy) the whole line
nnoremap Y y$

" H beginning of line
map H ^
" L end of line
map L $

" visual shifting (does not exit Visual mode)
xnoremap < <gv
xnoremap > >gv

" bash / shell start-end of line movement
inoremap <C-a> <Home>
inoremap <C-e> <End>

" ncurses 'inception' problem we need to go deeper !!
"  correct up/down mapping inside tmux/screen
"
"  basically the key code change when ncurses inside ncurses
"
nmap <Esc>[A  <Up>
nmap <Esc>[B  <Down>
nmap <Esc>[C  <Right>
nmap <Esc>[D  <Left>

" Fix home and end keybindings for screen, particularly on mac
" - for some reason this fixes the arrow keys too. huh.
map  [F $
imap [F $
map  [H g0
imap [H g0

if has("gui_macvim")
	nmap <SwipeLeft> :bN<cr>
	nmap <SwipeRight> :bn<cr>
endif

" move between functions
nmap <leader>f	]]
nmap <leader>F	[[

" }}}

" 19 reading and writing files {{{

set modeline
set modelines=5

" function : append modeline after last line in buffer {{{
" Use substitute() instead of printf() to handle '%%s' modeline in LaTeX
" files.
function! s:AppendModeline() abort
	let l:modeline = printf(" vim: set ft=%s ts=%d sw=%d tw=%d %set :",
				\ &filetype, &tabstop, &shiftwidth, &textwidth, &expandtab ? '' : 'no')
	let l:modeline = substitute(&commentstring, "%s", l:modeline, "")
	call append(line("$"), l:modeline)
endfunction
" }}}

command! Modeline call <SID>AppendModeline()

set fileformats+=mac

let s:backup_dir=$XDG_CACHE_BASEDIR . "/backup"
if !isdirectory(s:backup_dir)
	if exists("*mkdir")
		call mkdir(s:backup_dir, 'p')
	endif
endif

if isdirectory(s:backup_dir)
	set backupdir=$XDG_CACHE_BASEDIR/backup//,/tmp//
endif

if exists('+undofile')
	" disable backup we've got undo
	set nobackup
	if exists('+writebackup')
		" no backup at all, careful data loss may occur
		set nowritebackup
	endif
endif

" reload file modified outside of vim
set autoread

" When opening a large file, take some measures to keep things loading quickly
if has('eval') && has('autocmd')

	" Threshold is 10 MB in size
	autocmd vimrc BufReadPre *
				\ if getfsize(expand("<afile>")) > (10*1024*1024)
				\| setlocal nobackup
				\| setlocal nowritebackup
				\| setlocal noswapfile
				\| if has('persistent_undo')
				\| 	setlocal noundofile
				\| endif
				\| if exists('&synmaxcol')
				\| 	setlocal synmaxcol=256
				\| endif
				\| endif
endif

" When opening understand FILENAME:LINE:COL
"  see github.com/junegunn/dotfiles/blob/master/vimrc
function! s:filelinecol()
	let tokens = split(expand('%'), ':')
	if len(tokens) <= 1 || !filereadable(tokens[0])
		return
	endif

	let file = tokens[0]
	let rest = map(tokens[1:], 'str2nr(v:val)')
	let line = get(rest, 0, 1)
	let col  = get(rest, 1, 1)
	bd!
	silent execute 'e' file
	execute printf('normal! %dG%d|', line, col)
endfunction

autocmd vimrc BufNewFile * nested call s:filelinecol()

" }}}

" 20 the swap file {{{

let s:swap_dir=$XDG_CACHE_BASEDIR . "/swap"
if !isdirectory(s:swap_dir)
	if exists("*mkdir")
		call mkdir(s:swap_dir, 'p')
	endif
endif

if isdirectory(s:swap_dir)
	" double slash at the end to store the swap using the complete path
	set directory^=$XDG_CACHE_BASEDIR/swap//
endif

" }}}

" 21 command line editing {{{

" number of command lines to remember
set history=8000
" completion mode for the menu
set wildmode=longest,list

if has('wildignore')
	" ignore those files for completion and directories
	set wildignore+=*.swp,*.obj,*.o,*.dylib,*.so,*.a,*.class,*.pyc
	set wildignore+=*.DS_Store,Thumbs.db,.hg,.git,.svn
	set wildignore+=*.jpg,*.png,*.tif,*.gif,*.tar,*.zip,*.tar.gz,*.tar.bz2
	set wildignore+=*.tgz,*.tar.xz,*.7z
endif

" command-line completion menu in command mode
set wildmenu

if exists('+undofile')

	set undofile

	let s:undo_dir=$XDG_CACHE_BASEDIR . "/undo"
	if !isdirectory(s:undo_dir)
		if exists("*mkdir")
			call mkdir(s:undo_dir, 'p')
		endif
	endif

	if isdirectory(s:undo_dir)
		" where to store undo history // at the end keep hierarchy
		set undodir^=$XDG_CACHE_BASEDIR/undo//
	endif
endif

"" Function to obtain approximately the base dir when editing
function! s:referencedir() abort
	if exists("b:git_dir")
		return fnamemodify(b:git_dir, ":h")
	else
		return expand(g:vim_start_dir)
	endif

endfunction

cabbrev %% <c-r>=<SID>referencedir()<cr>
" autochdir (by hand)
cabbrev %. <c-r>=expand("%:p:h")<cr>

cabbrev %w <c-r>=expand("<cword>")<cr>
" copy visual selection in register 'v' and allow to use for command mode
xnoremap <silent> ,. "vy
cabbrev %v <c-r>=getreg('v')<cr>

" save as r00t
command! -bar W :
			\ setlocal nomodified |
			\ exe (has('gui_running') ? '' : 'silent') 'write !sudo tee % >/dev/null' |
			\ let &modified = v:shell_error

" }}}

" 22 executing external commands {{{

" function : redirect output of Vim or external command into scratch buffer {{{
"  credits https://gist.github.com/romainl/eae0a260ab9c135390c30cd370c20cd7
function! Redir(cmd, rng, start, end)
	for win in range(1, winnr('$'))
		if getwinvar(win, 'scratch')
			execute win . 'windo close'
		endif
	endfor
	if a:cmd =~ '^!'
		let cmd = a:cmd =~' %'
			\ ? matchstr(substitute(a:cmd, ' %', ' ' . expand('%:p'), ''), '^!\zs.*')
			\ : matchstr(a:cmd, '^!\zs.*')
		if a:rng == 0
			let output = systemlist(cmd)
		else
			let joined_lines = join(getline(a:start, a:end), '\n')
			let cleaned_lines = substitute(shellescape(joined_lines), "'\\\\''", "\\\\'", 'g')
			let output = systemlist(cmd . " <<< $" . cleaned_lines)
		endif
	else
		redir => output
		execute a:cmd
		redir END
		let output = split(output, "\n")
	endif
	vnew
	let w:scratch = 1
	setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
	call setline(1, output)
endfunction
"}}}

command! -nargs=1 -complete=command -bar -range Redir silent call Redir(<q-args>, <range>, <line1>, <line2>)

" Prefer POSIX shell
if &shell =~# 'fish$'
	set shell=/bin/sh
endif

if !has('nvim') && has("gui_macvim")
	let py3lib = reverse(split(glob("~/.local/pkg/dist/lib/libpython3*", 1), '\n'))
	let py3exe = reverse(split(glob("~/.local/pkg/dist/bin/python3.[0-9][0-9]", 1), '\n'))
	let py3exe += reverse(split(glob("~/.local/pkg/dist/bin/python3.[0-9]", 1), '\n'))
	if ! empty(py3lib)
		let py3home=fnamemodify(py3lib[0], ':p:h:h')
		let &pythonthreehome=py3home
		let &pythonthreedll=py3lib[0]
	endif
	let g:python3_host_prog=py3exe[0]
endif

" }}}

" 23 running make and jumping to errors & grep {{{

if executable('rg')
	set grepprg=rg\ --vimgrep\ --no-heading
elseif executable('ag')
	set grepprg=ag\ --nogroup\ --column\ --smart-case\ --nocolor\ --follow
	set grepformat=%f:%l:%c:%m
elseif executable('ack')
	set grepprg=ack\ --nogroup\ --column\ --smart-case\ --nocolor\ --follow\ $*
	set grepformat=%f:%l:%c:%m
endif

" function : Grep for :grep, add friendliness to it {{{
" see https://gist.github.com/romainl/56f0c28ef953ffc157f36cc495947ab3
function! Grep(...)
	if exists('*expandcmd')
		return system(join([&grepprg] + [expandcmd(join(a:000, ' '))], ' '))
	else
		return system(join([&grepprg] + a:000, ' '))
	endif
endfunction
" }}}

command! -nargs=+ -complete=file_in_path -bar Grep  cgetexpr Grep(<f-args>)
command! -nargs=+ -complete=file_in_path -bar LGrep lgetexpr Grep(<f-args>)

cnoreabbrev <expr> grep (getcmdtype() ==# ':' && getcmdline() ==# 'grep') ? 'Grep' : 'grep'
cnoreabbrev <expr> lgrep (getcmdtype() ==# ':' && getcmdline() ==# 'lgrep') ? 'LGrep' : 'lgrep'

if has('quickfix') && has("autocmd")

	" automatically show/open location-list or quickfix
	augroup automaticquickfix
		autocmd!
		autocmd QuickFixCmdPost [^l]* cwindow
		autocmd QuickFixCmdPost    l* lwindow
	augroup END
endif

" }}}

" 24 language specific {{{

" highlight VCS conflict markers
match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

" }}}

" 25 multi-byte characters {{{

if has('multi_byte')
	" encoding utf-8
	set encoding=utf-8
	" file save encoding utf-8
	set fileencoding=utf-8
	" terminal encoding utf-8
	" set termencoding=utf-8
endif

" }}}

" 26 various {{{

" search always with 'g' flag
set gdefault

if has('nvim')
	set shada+=n$XDG_CACHE_BASEDIR/principal.shada
else
	set viminfo+=n$XDG_CACHE_BASEDIR/viminfo
endif
set viminfo^=!

" remove options information from session file
set sessionoptions-=options

" Don't keep .viminfo information for files in temporary directories or shared
" memory filesystems; this is because they're used as scratch spaces for tools
" like sudoedit(8) and pass(1) and hence could present a security problem
if has('viminfo') && has('autocmd')
	augroup viminfoskip
		autocmd!
		silent! autocmd BufNewFile,BufReadPre
					\ /tmp/*,$TMPDIR/*,$TMP/*,$TEMP/*,*/shm/*
					\ setlocal viminfo=
	augroup END
endif

" }}}

if filereadable($MYVIMRC.'local')
	source $MYVIMRC.'local'
endif

if has('vim_starting')

	let s:has_adds = 0
	let s:disable_adds = 0

	if !s:disable_adds
		try
			if adds#has_manager() || !adds#has_manager()
				let s:has_adds = 1
			endif
		catch /E117/
			" missing function or simply missing adds.vim in autoload
		catch /Vim.*/
			echo v:exception
		catch
			throw v:exception
		endtry
	endif

	if !s:has_adds
		ThemeAdapt
	else
		if !adds#has_manager()
			if has("autocmd")
				autocmd vimrc VimEnter * call adds#install_manager()
				autocmd vimrc VimEnter * call adds#configure()
				autocmd vimrc VimEnter * ThemeAdapt
			else
				command! -bang AddsInstallManager call adds#install_manager()
				command! -bang AddsConfigure      call adds#configure()
			endif
		else
			call adds#setup()
			call adds#configure()
			ThemeAdapt
		endif
	endif

endif

" vim-commentary @ f8238d70f873969fb41bf6a6b07ca63a4c0b82b1 {{{
" commentary.vim - Comment stuff out
" Maintainer:   Tim Pope <http://tpo.pe/>
" Version:      1.3
" GetLatestVimScripts: 3695 1 :AutoInstall: commentary.vim

if exists("g:loaded_commentary") || v:version < 700
  finish
endif
let g:loaded_commentary = 1

function! s:surroundings() abort
  return split(get(b:, 'commentary_format', substitute(substitute(substitute(
        \ &commentstring, '^$', '%s', ''), '\S\zs%s',' %s', '') ,'%s\ze\S', '%s ', '')), '%s', 1)
endfunction

function! s:strip_white_space(l,r,line) abort
  let [l, r] = [a:l, a:r]
  if l[-1:] ==# ' ' && stridx(a:line,l) == -1 && stridx(a:line,l[0:-2]) == 0
    let l = l[:-2]
  endif
  if r[0] ==# ' ' && a:line[-strlen(r):] != r && a:line[1-strlen(r):] == r[1:]
    let r = r[1:]
  endif
  return [l, r]
endfunction

function! s:go(...) abort
  if !a:0
    let &operatorfunc = matchstr(expand('<sfile>'), '[^. ]*$')
    return 'g@'
  elseif a:0 > 1
    let [lnum1, lnum2] = [a:1, a:2]
  else
    let [lnum1, lnum2] = [line("'["), line("']")]
  endif

  let [l, r] = s:surroundings()
  let uncomment = 2
  for lnum in range(lnum1,lnum2)
    let line = matchstr(getline(lnum),'\S.*\s\@<!')
    let [l, r] = s:strip_white_space(l,r,line)
    if len(line) && (stridx(line,l) || line[strlen(line)-strlen(r) : -1] != r)
      let uncomment = 0
    endif
  endfor

  if get(b:, 'commentary_startofline')
    let indent = '^'
  else
    let indent = '^\s*'
  endif

  for lnum in range(lnum1,lnum2)
    let line = getline(lnum)
    if strlen(r) > 2 && l.r !~# '\\'
      let line = substitute(line,
            \'\M' . substitute(l, '\ze\S\s*$', '\\zs\\d\\*\\ze', '') . '\|' . substitute(r, '\S\zs', '\\zs\\d\\*\\ze', ''),
            \'\=substitute(submatch(0)+1-uncomment,"^0$\\|^-\\d*$","","")','g')
    endif
    if uncomment
      let line = substitute(line,'\S.*\s\@<!','\=submatch(0)[strlen(l):-strlen(r)-1]','')
    else
      let line = substitute(line,'^\%('.matchstr(getline(lnum1),indent).'\|\s*\)\zs.*\S\@<=','\=l.submatch(0).r','')
    endif
    call setline(lnum,line)
  endfor
  let modelines = &modelines
  try
    set modelines=0
    silent doautocmd User CommentaryPost
  finally
    let &modelines = modelines
  endtry
  return ''
endfunction

function! s:textobject(inner) abort
  let [l, r] = s:surroundings()
  let lnums = [line('.')+1, line('.')-2]
  for [index, dir, bound, line] in [[0, -1, 1, ''], [1, 1, line('$'), '']]
    while lnums[index] != bound && line ==# '' || !(stridx(line,l) || line[strlen(line)-strlen(r) : -1] != r)
      let lnums[index] += dir
      let line = matchstr(getline(lnums[index]+dir),'\S.*\s\@<!')
      let [l, r] = s:strip_white_space(l,r,line)
    endwhile
  endfor
  while (a:inner || lnums[1] != line('$')) && empty(getline(lnums[0]))
    let lnums[0] += 1
  endwhile
  while a:inner && empty(getline(lnums[1]))
    let lnums[1] -= 1
  endwhile
  if lnums[0] <= lnums[1]
    execute 'normal! 'lnums[0].'GV'.lnums[1].'G'
  endif
endfunction

command! -range -bar Commentary call s:go(<line1>,<line2>)
xnoremap <expr>   <Plug>Commentary     <SID>go()
nnoremap <expr>   <Plug>Commentary     <SID>go()
nnoremap <expr>   <Plug>CommentaryLine <SID>go() . '_'
onoremap <silent> <Plug>Commentary        :<C-U>call <SID>textobject(get(v:, 'operator', '') ==# 'c')<CR>
nnoremap <silent> <Plug>ChangeCommentary c:<C-U>call <SID>textobject(1)<CR>
nmap <silent> <Plug>CommentaryUndo :echoerr "Change your <Plug>CommentaryUndo map to <Plug>Commentary<Plug>Commentary"<CR>

if !hasmapto('<Plug>Commentary') || maparg('gc','n') ==# ''
  xmap gc  <Plug>Commentary
  nmap gc  <Plug>Commentary
  omap gc  <Plug>Commentary
  nmap gcc <Plug>CommentaryLine
  if maparg('c','n') ==# '' && !exists('v:operator')
    nmap cgc <Plug>ChangeCommentary
  endif
  nmap gcu <Plug>Commentary<Plug>Commentary
endif

" }}}

" vim-slash @ 31aee09b7ea8893a18fa34f65e63e364fc998444 {{{
" The MIT License (MIT)
"
" Copyright (c) 2016 Junegunn Choi
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
" THE SOFTWARE.

function! s:wrap(seq)
  if mode() == 'c' && stridx('/?', getcmdtype()) < 0
    return a:seq
  endif
  silent! autocmd! slash
  set hlsearch
  return a:seq."\<plug>(slash-trailer)"
endfunction

function! s:immobile(seq)
  let s:winline = winline()
  let s:pos = getpos('.')
  return a:seq."\<plug>(slash-prev)"
endfunction

function! s:trailer()
  augroup slash
    autocmd!
    autocmd CursorMoved,CursorMovedI * set nohlsearch | autocmd! slash
  augroup END

  let seq = foldclosed('.') != -1 ? 'zv' : ''
  if exists('s:winline')
    let sdiff = winline() - s:winline
    unlet s:winline
    if sdiff > 0
      let seq .= sdiff."\<c-e>"
    elseif sdiff < 0
      let seq .= -sdiff."\<c-y>"
    endif
  endif
  let after = len(maparg("<plug>(slash-after)", mode())) ? "\<plug>(slash-after)" : ''
  return seq . after
endfunction

function! s:trailer_on_leave()
  augroup slash
    autocmd!
    autocmd InsertLeave * call <sid>trailer()
  augroup END
  return ''
endfunction

function! s:prev()
  return getpos('.') == s:pos ? '' : '``'
endfunction

function! s:escape(backward)
  return '\V'.substitute(escape(@", '\' . (a:backward ? '?' : '/')), "\n", '\\n', 'g')
endfunction

function! Slash_blink(times, delay)
  let s:blink = { 'ticks': 2 * a:times, 'delay': a:delay }

  function! s:blink.tick(_)
    let self.ticks -= 1
    let active = self == s:blink && self.ticks > 0

    if !self.clear() && active && &hlsearch
      let [line, col] = [line('.'), col('.')]
      let w:blink_id = matchadd('IncSearch',
            \ printf('\%%%dl\%%>%dc\%%<%dc', line, max([0, col-2]), col+2))
    endif
    if active
      call timer_start(self.delay, self.tick)
      if has('nvim')
        call feedkeys("\<plug>(slash-nop)")
      endif
    endif
  endfunction

  function! s:blink.clear()
    if exists('w:blink_id')
      call matchdelete(w:blink_id)
      unlet w:blink_id
      return 1
    endif
  endfunction

  call s:blink.clear()
  call s:blink.tick(0)
  return ''
endfunction

map      <expr> <plug>(slash-trailer) <sid>trailer()
imap     <expr> <plug>(slash-trailer) <sid>trailer_on_leave()
cnoremap        <plug>(slash-cr)      <cr>
noremap  <expr> <plug>(slash-prev)    <sid>prev()
inoremap        <plug>(slash-prev)    <nop>
noremap!        <plug>(slash-nop)     <nop>

" cmap <expr> <cr> <sid>wrap("\<cr>")
map  <expr> n    <sid>wrap('n')
map  <expr> N    <sid>wrap('N')
map  <expr> gd   <sid>wrap('gd')
map  <expr> gD   <sid>wrap('gD')
map  <expr> *    <sid>wrap(<sid>immobile('*'))
map  <expr> #    <sid>wrap(<sid>immobile('#'))
map  <expr> g*   <sid>wrap(<sid>immobile('g*'))
map  <expr> g#   <sid>wrap(<sid>immobile('g#'))
xmap <expr> *    <sid>wrap(<sid>immobile("y/\<c-r>=<sid>escape(0)\<plug>(slash-cr)\<plug>(slash-cr)"))
xmap <expr> #    <sid>wrap(<sid>immobile("y?\<c-r>=<sid>escape(1)\<plug>(slash-cr)\<plug>(slash-cr)"))

" }}}

" vim: set ft=vim ts=8 sw=8 tw=78 noet fdm=marker :
