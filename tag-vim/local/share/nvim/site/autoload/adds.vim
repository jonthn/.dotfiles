if has('nvim')
	let s:datahome = $XDG_DATA_HOME.'/nvim/site'
else
	let s:datahome = $XDG_DATA_HOME.'/vim'
endif
let s:plugins_manager_url = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
let s:plugins_manager_corefile = s:datahome . '/' . 'autoload/plug.vim'
let $ADDS = s:datahome . '/' . 'autoload/adds.vim'
let $adds = s:datahome . '/' . 'autoload/adds.vim'
let $PLUGINS = s:datahome . '/' . 'autoload/adds.vim'
let s:use_plugins = 0

" define a group `adds` and initialize.
if has("autocmd")
	augroup adds
		autocmd!
	augroup END
endif

" check the plug-ins manager is installed
function! adds#has_manager() abort
	let s:use_plugins = !empty(glob(s:plugins_manager_corefile))
	return s:use_plugins
endfunction

" function to detect and install if it's not the case the plug-ins manager
function! adds#install_manager() abort
	if adds#has_manager()
		let s:use_plugins = 1
		return
	endif

	if 1 == confirm("Install plugins manager ?", "&Yes\n&No", 2)

		let l:pldir = fnamemodify(s:plugins_manager_corefile, ":p:h")
		if !isdirectory(l:pldir)
			if exists("*mkdir")
				call mkdir(l:pldir, 'p')
			endif
		endif

		if !isdirectory(l:pldir)
			return
		endif

		let l:plugin_installation = 0
		if executable('curl')
			execute '!curl -fkLo '. s:plugins_manager_corefile . ' ' . s:plugins_manager_url
			if !v:shell_error
				let l:plugin_installation = 1
			endif
		elseif executable('wget')
			execute '!wget -O '. s:plugins_manager_corefile . ' ' . s:plugins_manager_url
			if !v:shell_error
				let l:plugin_installation = 1
			endif
		else
			echohl ErrorMsg | echomsg "curl or wget necessary" | echohl NONE
		endif

		if l:plugin_installation
			let s:use_plugins = 1
			" register the plug-ins we want
			call adds#setup()
			" force install of those plug-ins
			PlugInstall
		endif
	endif

endfunction

function! s:rstrip_slash(input_string)
	return substitute(a:input_string, '^\s*\(.\{-}\)/*$', '\1', '')
endfunction

function! adds#available(plugin_name)
	let l:result = 0
	if exists('g:plugs')
		if has_key(g:plugs, a:plugin_name)
			if stridx(&rtp, s:rstrip_slash(g:plugs[a:plugin_name].dir)) >= 0
						\&& isdirectory(g:plugs[a:plugin_name].dir)
				let l:result = 1
			endif
		endif
	endif

	" echohl ErrorMsg | echomsg "Plugin ". a:plugin_name . " is " . l:result | echohl NONE
	"otherwise it means it's not here

	return l:result
endfunction

function! adds#setup()

	if !s:use_plugins
		return
	endif

	" runtime plug.vim
	"echohl ErrorMsg | echomsg "setup start" | echohl NONE

	let g:plug_window = "below new"

	if exists('+colorcolumn') && has("autocmd")
		" Disable colorcolumn in vim-plug window
		autocmd adds FileType vim-plug setl colorcolumn=0
	endif

	call plug#begin(s:datahome.'/addins')

	" Insert here plugin to install and configure them after plug#end()

	" repeat for plugin mapping
	Plug 'tpope/vim-repeat'

	""" Important plugins
	"--------------------

	" comment is a must-a-have
	" Plug 'tomtom/tcomment_vim'
	"Plug 'tpope/vim-commentary' " is packaged in the (n)vimrc as fallback

	" highlight matching parens, &.el
	Plug 'junegunn/rainbow_parentheses.vim'

	" even better %
	Plug 'andymass/vim-matchup'

	" Navigate between buffers, files, ...
	" With a goal of consistent approach between shell and (n)vim
	" if executable('fzf')
	" 	Plug 'junegunn/fzf'
	" else
	" 	Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
	" endif
	" Plug 'junegunn/fzf.vim'
	" Plug 'fszymanski/fzf-quickfix'

	Plug 'justinmk/vim-dirvish'

	" Completion
	" if has('nvim')
		" Plug 'neovim/nvim-lsp'
		" Complementary plugins
		" Plug 'haorenW1025/completion-nvim'
		" Plug 'haorenW1025/diagnostic-nvim'
	" endif

	" Plug 'autozimu/LanguageClient-neovim', {
	" 			\ 'branch': 'next',
	" 			\ 'do': 'sh install.sh',
	" 			\ }

	if has('insert_expand') && has('menu')
		Plug 'lifepillar/vim-mucomplete'
	endif

	" remove and show annoying whitespace
	Plug 'ntpeters/vim-better-whitespace'

	" display gutter add/remove/modify since last commit
	if has('nvim') || has('patch-8.0.902')
		Plug 'mhinz/vim-signify'
	else
		Plug 'mhinz/vim-signify', { 'branch': 'legacy' }
	endif

	" display syntax errors
	" Plug 'neomake/neomake'
	Plug 'dense-analysis/ale'

	" A collection of language packs for Vim
	Plug 'sheerun/vim-polyglot'

	" snippet saves typing
	Plug 'Shougo/neosnippet'
	Plug 'Shougo/neosnippet-snippets'

	" compatible with both neosnippet and ultisnips
	Plug 'jonthn/snippets'

	""" Useful plugins
	"-----------------

	" detect indent
	Plug 'tpope/vim-sleuth'

	" change/add/delete surround foo -> (foo) -> "foo"
	Plug 'machakann/vim-sandwich'

	" describe the character under cursor
	Plug 'tpope/vim-characterize'

	" keyword help
	Plug 'romainl/vim-devdocs'

	if v:version > 702
		" binary editing
		Plug 'Shougo/vinarise.vim'
	endif

	"Plug 'junegunn/vim-slash' " is packaged in the (n)vimrc as fallback

	" show count match
	Plug 'henrik/vim-indexed-search'

	" Narrow region
	Plug 'chrisbra/NrrwRgn'

	""" Nice plugins
	"-----------------------

	" distraction-free writing in Vim
	Plug 'junegunn/goyo.vim'
	"  stage the words
	Plug 'junegunn/limelight.vim'

	if executable('git')
		" git is one famous version control system let's give him some love
		Plug 'tpope/vim-fugitive'
		" an alternative
		" Plug 'jreybert/vimagit'
	endif

	" display the undo tree human friendly
	" Plug 'mbbill/undotree'

	""" Sugar plugins
	"--------------------

	" Preview colours in source code
	Plug 'ap/vim-css-color'

	" Generate ToC for Markdown files
	Plug 'mzlogin/vim-markdown-toc'

	" Align
	Plug 'junegunn/vim-easy-align'

	""" Colorscheme
	"--------------

	" Dark
	Plug 'jacoborus/tender.vim'
	Plug 'phanviet/vim-monokai-pro'

	" default to dark
	Plug 'junegunn/seoul256.vim'

	" Dark/Light
	Plug 'noahfrederick/vim-hemisu'
	Plug 'nightsense/cosmic_latte'
	Plug 'nightsense/snow'
	Plug 'rakr/vim-two-firewatch'

	" Useful for demonstration
	Plug 'nightsense/shoji'

	call plug#end()

	"" -------------------------------------------------------
	"" At this point plugins are loaded they can be configured
	"" -------------------------------------------------------

	" if there is a missing directory it means we need to install
	"  a plugin do it here
	if has("autocmd")
				\&& !empty(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
		autocmd adds VimEnter * PlugInstall
	endif

	"echohl ErrorMsg | echomsg "setup finished" | echohl NONE

endfunction

function! adds#configure()

	if !s:use_plugins
		return
	endif

	"echohl ErrorMsg | echomsg "configure start" | echohl NONE

	if adds#available('vim-better-whitespace')
		let g:better_whitespace_filetypes_blacklist = [ 'vim-plug', 'unite', 'denite' ]
	endif

	if adds#available('vim-fugitive')
		if has("autocmd")
			autocmd adds BufReadPost fugitive://* set bufhidden=delete
		endif
	endif

	if adds#available('neosnippet')

		if "\<Space>" == g:mapleader
			imap ,l     <Plug>(neosnippet_expand_or_jump)
			smap ,l     <Plug>(neosnippet_expand_or_jump)
			xmap ,l     <Plug>(neosnippet_expand_target)
		else
			imap <leader>l     <Plug>(neosnippet_expand_or_jump)
			smap <leader>l     <Plug>(neosnippet_expand_or_jump)
			xmap <leader>l     <Plug>(neosnippet_expand_target)
		endif

		autocmd vimrc InsertLeave * NeoSnippetClearMarkers

	endif

	if adds#available('vim-mucomplete')
		if adds#available('neosnippet')
			let g:mucomplete#chains = {
						\ 'default' : ['path', 'omni', 'keyn', 'nsnp', 'dict', 'uspl' ],
						\ 'vim' : ['path', 'cmd', 'keyn', 'nsnp' ],
						\ }
		endif
	endif

	if adds#available('fzf.vim')

		if has('nvim') || has('gui_running')
			let $FZF_DEFAULT_OPTS .= ' --inline-info'
		endif

		let g:fzf_colors =
					\ { 'fg':      ['fg', 'Normal'],
					\ 'bg':      ['bg', 'Normal'],
					\ 'hl':      ['fg', 'Comment'],
					\ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
					\ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
					\ 'hl+':     ['fg', 'Statement'],
					\ 'info':    ['fg', 'PreProc'],
					\ 'border':  ['fg', 'Ignore'],
					\ 'prompt':  ['fg', 'Conditional'],
					\ 'pointer': ['fg', 'Exception'],
					\ 'marker':  ['fg', 'Keyword'],
					\ 'spinner': ['fg', 'Label'],
					\ 'header':  ['fg', 'Comment'] }

		" Terminal buffer options for fzf
		autocmd! FileType fzf
		autocmd  FileType fzf set noshowmode noruler nonu

		if exists('$TMUX')
			let g:fzf_layout = { 'tmux': '-p90%,60%' }
		elseif has('nvim') || has('patch-8.2.191')
			let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6 } }
		endif

		" All files
		if executable('fd')
			command! -nargs=? -complete=dir Fichiers
						\ call fzf#run(fzf#wrap(fzf#vim#with_preview({
						\   'source': 'fd --type f --hidden --follow --exclude .git --no-ignore . '.expand(<q-args>)
						\ })))
		endif

		unmap <leader><Space>

		nmap <leader> <Plug>[fzf]
		nnoremap <silent> <Plug>[fzf]<Space> :<C-u>Buffers<cr>
		nnoremap <silent> <Plug>[fzf]<Enter>> :<C-u>Quickfix<cr>
		nnoremap <silent> <Plug>[fzf], :<C-u>Files<cr>
		nnoremap <silent> <Plug>[fzf]v :<C-u>BLines<cr>
		nnoremap <silent> <Plug>[fzf]b :<C-u>Lines<cr>
		nnoremap <silent> <Plug>[fzf]n :<C-u>Quickfix!<cr>

		function! s:plug_help_sink(line)
			let dir = g:plugs[a:line].dir
			for pat in ['doc/*.txt', 'README.md']
				let match = get(split(globpath(dir, pat), "\n"), 0, '')
				if len(match)
					execute 'tabedit' match
					return
				endif
			endfor
			tabnew
			execute 'Explore' dir
		endfunction

		command! PlugHelp call fzf#run(fzf#wrap({
					\ 'source': sort(keys(g:plugs)),
					\ 'sink':   function('s:plug_help_sink')}))

		if executable('rg')
			function! RipgrepFzf(query, fullscreen)
				let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case %s || true'
				let initial_command = printf(command_fmt, shellescape(a:query))
				let reload_command = printf(command_fmt, '{q}')
				let options = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
				if a:fullscreen
					let options = fzf#vim#with_preview(options)
				endif
				call fzf#vim#grep(initial_command, 1, options, a:fullscreen)
			endfunction

			command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)
		endif

	endif

	if adds#available('rainbow_parentheses.vim')
		let g:rainbow#blacklist = [ '#555555', 'black' ]
		if has("autocmd")
			autocmd adds VimEnter *  silent! RainbowParentheses
		endif
	endif

	if adds#available('two-firewatch')
		augroup colorscheme_custom_two_firewatch
			autocmd!
			autocmd ColorScheme two-firewatch highlight! link SignColumn LineNr
		augroup END
	endif

	if adds#available('vim-signify')

		if has("autocmd") && !has('nvim')
			" to update statusline
			augroup signify
				autocmd!
				" autocmd User Signify redraw!
				autocmd BufWritePost * redraw!
			augroup END
		endif

		" nmap bn <plug>(signify-next-hunk)
		" nmap op <plug>(signify-prev-hunk)
	endif

	if adds#available('ale')
		" see Stl_filesyntax_symbol()
		if has('multi_byte')
			let g:ale_sign_error = '⨉'
			let g:ale_sign_warning = '⚠'
		else
			let g:ale_sign_error = 'E'
			let g:ale_sign_warning = 'w'
		endif

		try
			call ale#statusline#Count(bufnr(''))
		catch
		endtry

		" cycle through location list
		nmap <silent> <leader>n <Plug>(ale_next_wrap)
		nmap <silent> <leader>p <Plug>(ale_previous_wrap)
	endif

	if adds#available('tcomment_vim')
		let g:tcomment_maps = 0
		" Toggle line commenting
		nmap <S-c> <Plug>TComment_<c-_><c-_>
		xmap <S-c> <Plug>TComment_<c-_><c-_>
	endif

	if adds#available('vim-indexed-search')
		let g:indexed_search_mappings = 0
		noremap <expr> <plug>(slash-after) 'zz'.'<Cmd>ShowSearchIndex<cr>'.Slash_blink(2, 75)
	endif

	if adds#available('vim-devdocs')
		if has("autocmd")
			autocmd vimrc FileType cpp setlocal keywordprg=:DD
		end
	endif

	if adds#available('goyo.vim')
		function! s:goyo_enter()
			redir => g:previous_colorscheme
			silent colorscheme
			redir END
			let g:previous_colorscheme = substitute(g:previous_colorscheme, "\n", "", "g")
			colorscheme seoul256
			StatusCustomLineNO
			if executable('tmux') && strlen($TMUX)
				silent !tmux set status off
				silent !tmux list-panes -F '\#F' | grep -q Z || tmux resize-pane -Z
			endif
			set noshowmode
			set noshowcmd
			set scrolloff=999
			if adds#available('limelight.vim')
				Limelight
			endif
		endfunction

		function! s:goyo_leave()
			if executable('tmux') && strlen($TMUX)
				silent !tmux set status on
				silent !tmux list-panes -F '\#F' | grep -q Z && tmux resize-pane -Z
			endif
			set showmode
			set showcmd
			set scrolloff=5
			if adds#available('limelight.vim')
				Limelight!
			endif
			if exists('g:previous_colorscheme') && !empty(g:previous_colorscheme)
				execute "colorscheme " . g:previous_colorscheme
				unlet g:previous_colorscheme
			endif
			StatusCustomLineACTIVE
		endfunction

		autocmd! User GoyoEnter nested call <SID>goyo_enter()
		autocmd! User GoyoLeave nested call <SID>goyo_leave()
	endif

	if adds#available('limelight.vim')
		let g:limelight_default_coefficient = 0.7
	endif

	"echohl ErrorMsg | echomsg "configure finished" | echohl NONE

endfunction

