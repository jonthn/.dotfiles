if has('nvim')
	let s:xdgconfig = $XDG_CONFIG_HOME.'/nvim/site'
else
	let s:xdgconfig = $XDG_CONFIG_HOME.'/vim/site'
endif
let s:plugins_manager_url = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
let s:plugins_manager_corefile = s:xdgconfig . '/' . 'autoload/plug.vim'
let $ADDS = s:xdgconfig . '/' . 'autoload/adds.vim'
let $adds = s:xdgconfig . '/' . 'autoload/adds.vim'
let $PLUGINS = s:xdgconfig . '/' . 'autoload/adds.vim'
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

	if has('nvim')
		let l:host_plugmanager_disable = $XDG_CONFIG_HOME . '/nvim/z_disable_pluginmanager'
	else
		let l:host_plugmanager_disable = $XDG_CONFIG_HOME . '/vim/z_disable_pluginmanager'
	endif

	if filereadable(l:host_plugmanager_disable)
		" disable plug manager
		return
	endif

	let l:choice = confirm("Install plugins manager ?", "&Yes\n&No\n&Disable", 2)

	if 3 == l:choice
		" Disable plugin manager
		call writefile(["disable"], l:host_plugmanager_disable)
	elseif 1 == l:choice
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

	call adds#before_load()

	if has('nvim')
		call plug#begin($XDG_CACHE_HOME.'/nvim/addins')
	else
		call plug#begin($XDG_CACHE_HOME.'/vim/addins')
	endif

	" Insert here plugin to install and configure them after plug#end()

	" repeat for plugin mapping
	Plug 'tpope/vim-repeat'

	""" Important plugins
	"--------------------

	" comment is a must-a-have
	" Plug 'tomtom/tcomment_vim'
	"Plug 'tpope/vim-commentary' " is packaged in the (n)vimrc as fallback
	Plug 'tpope/vim-unimpaired'

	" highlight matching parens, &.el
	Plug 'junegunn/rainbow_parentheses.vim'

	" even better %
	Plug 'andymass/vim-matchup'

	" Jump to any location specified by two characters
	Plug 'justinmk/vim-sneak'

	if has('nvim')
		Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
	endif

	" Navigate between buffers, files, ...
	" With a goal of consistent approach between shell and (n)vim
	if executable('fzf')
		Plug 'junegunn/fzf'
	else
		Plug 'junegunn/fzf', { 'dir': $XDG_CACHE_HOME.'/fzf', 'do': { -> fzf#install() } }
	endif
	Plug 'junegunn/fzf.vim'

	" if executable('sk')
	" 	Plug 'lotabout/skim'
	" else
	" 	Plug 'lotabout/skim', { 'dir': $XDG_CACHE_HOME.'/skim', 'do': './install' }
	" endif
	" Plug 'lotabout/skim.vim'

	" tmux is a close friend
	Plug 'tpope/vim-dispatch'

	Plug 'justinmk/vim-dirvish'

	" remove and show annoying whitespace
	Plug 'ntpeters/vim-better-whitespace'

	" display gutter add/remove/modify since last commit
	if has('nvim') || has('patch-8.0.902')
		Plug 'mhinz/vim-signify'
	else
		Plug 'mhinz/vim-signify', { 'branch': 'legacy' }
	endif

	" Syntax / Completion / Semantic / Lint

	" snippet saves typing
	Plug 'hrsh7th/vim-vsnip'

	" (some/lots) snippets
	Plug 'rafamadriz/friendly-snippets'

	" compatible with neosnippet / ultisnips / vsnip
	Plug 'jonthn/snippets'

	" LSP + autocomplete
	if has('nvim')
		Plug 'williamboman/mason.nvim'
		Plug 'williamboman/mason-lspconfig.nvim'
		Plug 'neovim/nvim-lspconfig'
		Plug 'hrsh7th/cmp-nvim-lsp'
		Plug 'hrsh7th/cmp-buffer'
		Plug 'hrsh7th/cmp-vsnip'
		Plug 'hrsh7th/nvim-cmp'
		Plug 'hrsh7th/cmp-nvim-lsp-signature-help'
		" Plug 'ray-x/lsp_signature.nvim'

		Plug 'nvim-lua/plenary.nvim'
		Plug 'jose-elias-alvarez/null-ls.nvim'
		Plug 'jayp0521/mason-null-ls.nvim'

		Plug 'kyazdani42/nvim-web-devicons'
		Plug 'folke/trouble.nvim'
	else
		" display syntax errors
		" Plug 'dense-analysis/ale'
		Plug 'prabirshrestha/vim-lsp'
		Plug 'mattn/vim-lsp-settings'
		Plug 'prabirshrestha/asyncomplete.vim'
		Plug 'prabirshrestha/asyncomplete-lsp.vim'
		" Play well wil ALE
		" Plug 'rhysd/vim-lsp-ale'
		" integrate with vim-lsp and more
		Plug 'hrsh7th/vim-vsnip-integ'
	endif

	" A collection of language packs for Vim
	Plug 'sheerun/vim-polyglot'

	""" Useful plugins
	"-----------------

	" detect indent
	"  disabled as it's included inside `vim-polyglot`
	" Plug 'tpope/vim-sleuth'

	" change/add/delete surround foo -> (foo) -> "foo"
	Plug 'machakann/vim-sandwich'

	" describe the character under cursor
	Plug 'tpope/vim-characterize'

	" keyword help
	" Plug 'romainl/vim-devdocs'

	if v:version > 702
		" binary editing
		Plug 'Shougo/vinarise.vim'
	endif

	" visual star search and enable/disable search highlight
	" packaged in the (n)vimrc as fallback
	" Plug 'romainl/vim-cool'
	" Plug 'PeterRincker/vim-searchlight'

	" Narrow region
	Plug 'chrisbra/NrrwRgn'

	""" Nice plugins
	"-----------------------

	" distraction-free writing in Vim
	Plug 'junegunn/goyo.vim', { 'on': 'Goyo', 'for': 'markdown' }
	"  stage the words
	Plug 'junegunn/limelight.vim', { 'on': 'Goyo', 'for': 'markdown' }

	Plug 'iamcco/markdown-preview.nvim', { 'do': ':call mkdp#util#install()', 'for': ['markdown']}

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

	if has('nvim')
		Plug 'norcalli/nvim-colorizer.lua'
	else
		" Preview colours in source code
		Plug 'ap/vim-css-color'
	endif

	" Generate ToC for Markdown files
	Plug 'mzlogin/vim-markdown-toc', { 'for': 'markdown' }

	""" Colorscheme
	"--------------

	" Preview within Vim
	"Plug 'felixhummel/setcolors.vim'
	" then :SetColors all and <F8> to go through everything

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

function! adds#before_load()

	if !s:use_plugins
		return
	endif

	" Here set some global variable affecting loading and settings for plugins

	" vim-better-whitespace
	let g:better_whitespace_filetypes_blacklist = [ 'vim-plug' ]

	" vim-cool
	let g:cool_total_matches = 1

	" vim-polyglot
	let g:polyglot_disabled = ['sensible']

	" tcomment_vim
	let g:tcomment_maps = 0

	" vim-indexed-search
	let g:indexed_search_mappings = 0

	" disable asyncomplete.vim popup
	" let g:asyncomplete_auto_popup = 0

	let g:lsp_settings_servers_dir = $XDG_CACHE_HOME . '/vim/lsp/servers'

endfunction

function! adds#configure()

	if !s:use_plugins
		return
	endif

	"echohl ErrorMsg | echomsg "configure start" | echohl NONE

	if adds#available('tcomment_vim')
		" Toggle line commenting
		nmap <S-c> <Plug>TComment_<c-_><c-_>
		xmap <S-c> <Plug>TComment_<c-_><c-_>
	endif

	if adds#available('vim-indexed-search')
		noremap <expr> <plug>(slash-after) 'zz'.'<Cmd>ShowSearchIndex<cr>'.Slash_blink(2, 75)
	endif

	if adds#available('vim-fugitive')
		if has("autocmd")
			autocmd adds BufReadPost fugitive://* set bufhidden=delete
		endif
	endif

	if adds#available('fzf.vim')

		if has('nvim') || has('gui_running')
			let $FZF_DEFAULT_OPTS .= ' --inline-info'
		endif

		let g:fzf_command_prefix = 'Fz'

		let g:fzf_colors =
					\ { 'fg':    ['fg', 'Normal'],
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

		autocmd! FileType fzf
		autocmd  FileType fzf set laststatus=0 noshowmode noruler
					\| autocmd BufLeave <buffer> set laststatus=2 showmode ruler

		if exists('$TMUX')
			let g:fzf_layout = { 'tmux': '-p90%,60%' }
		elseif has('nvim') || has('patch-8.2.191')
			" let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6 } }
			let g:fzf_layout = { 'up': '42%' }
		endif

		" unmap <leader><Space>

		nmap <leader> <Plug>[fzf]
		" nnoremap <silent> <Plug>[fzf]<Space> :<C-u>Buffers<cr>
		nnoremap <silent> <Plug>[fzf], :<C-u>FzFiles<cr>
		nnoremap <silent> <Plug>[fzf]v :<C-u>FzBLines<cr>
		nnoremap <silent> <Plug>[fzf]b :<C-u>FzLines<cr>
		" nnoremap <silent> <Plug>[fzf]<Enter>> :<C-u>Quickfix<cr>
		" nnoremap <silent> <Plug>[fzf]n :<C-u>Quickfix!<cr>

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

		" All files
		if executable('fd')
			command! -nargs=? -complete=dir Fichiers
						\ call fzf#run(fzf#wrap(fzf#vim#with_preview({
						\   'source': 'fd --type f --hidden --follow --exclude .git --no-ignore . '.expand(<q-args>)
						\ })))
		endif

		if executable('rg')

			function! RipgrepFzf(query, fullscreen)
				let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case -- %s || true'
				let initial_command = printf(command_fmt, shellescape(a:query))
				let reload_command = printf(command_fmt, '{q}')
				let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
				call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
			endfunction

			command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)
		endif

	endif


	if adds#available('vim-vsnip')

		if "\<Space>" == g:mapleader
			imap ,l	<Plug>(vsnip-expand-or-jump)
			smap ,l	<Plug>(vsnip-expand-or-jump)
		else
			imap <leader>l	<Plug>(vsnip-expand-or-jump)
			smap <leader>l	<Plug>(vsnip-expand-or-jump)
		endif

		" Jump forward or backward
		" imap <expr> <Tab>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
		" smap <expr> <Tab>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
		" imap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
		" smap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
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

	if adds#available('nvim-treesitter')
		lua << EOF
		require("nvim-treesitter.install").command_extra_args = {
		    curl = { "-k" },
	        }

		require'nvim-treesitter.configs'.setup {
			-- A list of parser names, or "all"
			ensure_installed = { "bash", "c", "comment", "cmake", "cpp",
					"html", "javascript", "json", "latex",
					"make", "markdown", "ruby", "rust" },

			-- Install parsers synchronously (only applied to `ensure_installed`)
			sync_install = false,

			highlight = {
				enable = false,
				additional_vim_regex_highlighting = false,
			},

			indent = {
				enable = true,
			},

			matchup = {
				enable = true,
			}
		}
EOF
	endif

	if adds#available('mason-lspconfig.nvim')
		lua << EOF
		require("mason").setup({
			install_root_dir = vim.env.XDG_CACHE_HOME .. "/nvim/lsp/servers"
		})
		require("mason-lspconfig").setup()
EOF
	endif

	if adds#available('null-ls.nvim')
		lua << EOF
		local null_ls = require("null-ls")

		local sources = {
			null_ls.builtins.code_actions.shellcheck,
			null_ls.builtins.code_actions.eslint_d,
			null_ls.builtins.diagnostics.shellcheck,
			null_ls.builtins.diagnostics.clang_check,
			null_ls.builtins.diagnostics.eslint_d,
		}

		null_ls.setup({ sources = sources })
EOF
	endif

	if adds#available('mason-null-ls.nvim')
		lua << EOF
		require("mason-null-ls").setup({
			automatic_installation = true,
			automatic_setup = true,
		})
EOF
	endif

	if adds#available('nvim-lspconfig') && adds#available('nvim-cmp') && adds#available('cmp-nvim-lsp')
		lua << EOF
		local lspconfig = require('lspconfig')
		local lsp_defaults = lspconfig.util.default_config

		lsp_defaults.capabilities = vim.tbl_deep_extend(
			'force',
			lsp_defaults.capabilities,
			require('cmp_nvim_lsp').default_capabilities()
		)
EOF
	endif

	if adds#available('nvim-lspconfig') && adds#available('mason-lspconfig.nvim')

		lua << EOF
		-- General lspconfig

		-- Mappings.
		local opts = { noremap = true, silent = true }
		vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
		vim.keymap.set('n', '[g', vim.diagnostic.goto_prev, opts)
		vim.keymap.set('n', ']g', vim.diagnostic.goto_next, opts)
		vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)

		local on_attach_lsp = function(client, bufnr)

			local bufopts = { noremap=true, silent=true, buffer=bufnr }

			vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
			vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
			vim.keymap.set('n', 'gy', vim.lsp.buf.type_definition,bufopts)
			vim.keymap.set('n', 'gi', vim.lsp.buf.implementation,bufopts)
			vim.keymap.set('n', 'gr', vim.lsp.buf.references,bufopts)
			vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
			vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
			vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
			vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
			vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, bufopts)

			vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
			vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
			vim.keymap.set('n', '<leader>wl', function()
				print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
			end, opts)
		end

		if vim.fn['adds#available']('mason-lspconfig.nvim') then
			local mason_lspconfig = require("mason-lspconfig")

			mason_lspconfig.setup_handlers({
				function(server_name)
					require("lspconfig")[server_name].setup({
						on_attach = on_attach_lsp
					})
				end
			})
		else
			-- Activate server LSP config manually
			local lspconfig = require('lspconfig')

			local lsp_flags = {
				-- This is the default in Nvim 0.7+
				debounce_text_changes = 150,
			}

			lspconfig.vimls.setup({
				on_attach = on_attach_lsp,
				flags = lsp_flags,
			})
			lspconfig.tsserver.setup({
				on_attach = on_attach_lsp,
				flags = lsp_flags,
			})
			lspconfig.rust_analyzer.setup({
				on_attach = on_attach_lsp,
				flags = lsp_flags,
			})
			lspconfig.clangd.setup({
				on_attach = on_attach_lsp,
				flags = lsp_flags,
			})
			lspconfig.bashls.setup({
				on_attach = on_attach_lsp,
				flags = lsp_flags,
			})
		end
EOF
	endif

	if adds#available('nvim-cmp') && adds#available('cmp-nvim-lsp')
		lua << EOF
		  -- Set up nvim-cmp.
		  local cmp = require'cmp'

		  cmp.setup({
			--enabled = function()
				-- disable completion in comments
				--local context = require 'cmp.config.context'
				-- keep command mode completion enabled when cursor is in a comment
				--if vim.api.nvim_get_mode().mode == 'c' then
					--return true
				--else
					--return not context.in_treesitter_capture("comment")
					--and not context.in_syntax_group("Comment")
				--end
    			--end,
			snippet = {
				expand = function(args)
					vim.fn["vsnip#anonymous"](args.body)
				end
			},
			window = {
				-- completion = cmp.config.window.bordered(),
				 documentation = cmp.config.window.bordered(),
			},
			mapping = cmp.mapping.preset.insert({
				['<C-b>'] = cmp.mapping.scroll_docs(-4),
				['<C-f>'] = cmp.mapping.scroll_docs(4),
				['<C-Space>'] = cmp.mapping.complete(),
				['<C-e>'] = cmp.mapping.abort(),
				-- Accept currently selected item.
				-- Set `select` to `false` to only confirm
				--   explicitly selected items.
				-- ['<CR>'] = cmp.mapping.confirm({ select = true }),
				['<CR>'] = cmp.mapping({
					i = function(fallback)
						if cmp.visible() and cmp.get_active_entry() then
							cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
						else
							fallback()
						end
					end,
					s = cmp.mapping.confirm({ select = true }),
					c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true })
				}),
			}),
			sources = cmp.config.sources({
				{ name = 'nvim_lsp' },
				{ name = 'nvim_lsp_signature_help' },
				{ name = 'vsnip' }
			}, {
				{ name = 'buffer' },
			})
		})
EOF
	endif

	if adds#available('lsp_signature.nvim')
		lua << EOF
		--cfg = {}  -- add you config here
		--require "lsp_signature".setup(cfg)
		require "lsp_signature".setup()
EOF
	endif

	if adds#available('trouble.nvim')
		lua << EOF
		require("trouble").setup {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		}
EOF
	endif

	if adds#available('vim-lsp')

		function! s:on_lsp_buffer_enabled() abort
			setlocal omnifunc=lsp#complete
			setlocal signcolumn=yes
			if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
			nmap <buffer> gD <plug>(lsp-declaration)
			nmap <buffer> gd <plug>(lsp-definition)
			nmap <buffer> gy <plug>(lsp-type-definition)
			nmap <buffer> gi <plug>(lsp-implementation)
			nmap <buffer> gr <plug>(lsp-references)
			nmap <buffer> gs <plug>(lsp-document-symbol-search)
			nmap <buffer> gS <plug>(lsp-workspace-symbol-search)
			nmap <buffer> K <plug>(lsp-hover)
			nmap <buffer> <C-k> <plug>(lsp-signature-help)
			nmap <buffer> <leader>rn <plug>(lsp-rename)
			nmap <buffer> <leader>ca <plug>(lsp-code-action)
			nmap <buffer> <leader>f <plug>(lsp-document-format)

			nmap <buffer> [g <plug>(lsp-previous-diagnostic)
			nmap <buffer> ]g <plug>(lsp-next-diagnostic)

			nnoremap <buffer> <expr><c-f> lsp#scroll(+4)
			nnoremap <buffer> <expr><c-d> lsp#scroll(-4)

			" let g:lsp_format_sync_timeout = 1000

			" refer to doc to add more commands
		endfunction

		augroup lsp_install
			au!
			" call s:on_lsp_buffer_enabled only for languages that has the server registered.
			autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
		augroup END
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

		if has('gui_running')
			let g:ale_set_balloons = 1
		endif
		let g:ale_hover_to_floating_preview = 1

		function! s:ale_mappings()
			let l:lsp=v:false
			let l:ale=v:false

			for linter in ale#linter#Get(&filetype)
				if !empty(linter.lsp)
					if ale#lsp_linter#CheckWithLSP(bufnr(''), linter)
						let l:lsp=v:true
					endif
					let l:ale=v:true
				endif
			endfor

			if ! has('nvim')
				if l:lsp || l:ale
					if ! adds#available('vim-lsp')
						setlocal omnifunc=ale#completion#OmniFunc
						nmap <buffer> gd <Plug>(ale_go_to_definition)
						nmap <buffer> gy <plug>(ale_go_to_type_definition)
						nmap <silent> <buffer> gS :ALESymbolSearch<Return>
						nmap <silent> <buffer> gr :ALEFindReferences -relative<Return>
						nmap <buffer> <leader>rn :ALERename<Return>
						nmap <buffer> K <plug>(ale_hover)
					endif
				else
					if ! adds#available('vim-lsp')
						setlocal omnifunc=
						silent! unmap <buffer> <C-]>
						silent! unmap <buffer> gd
						silent! unmap <buffer> gy
						silent! unmap <buffer> gS
						silent! unmap <buffer> gr
						silent! unmap <buffer> <leader>rn
						silent! unmap <buffer> K
					endif
				endif
			endif
		endfunction

		autocmd vimrc BufRead,FileType * call s:ale_mappings()
	endif

	if adds#available('asyncomplete.vim')
		inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
		inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
		inoremap <expr> <cr>    pumvisible() ? asyncomplete#close_popup() : "\<cr>"

		if adds#available('ale')
			" Use ALE's function for asyncomplete defaults
			au User asyncomplete_setup call asyncomplete#register_source(asyncomplete#sources#ale#get_source_options({
						\ 'priority': 10,
						\ }))
		endif
	endif


	if adds#available('rainbow_parentheses.vim')
		let g:rainbow#blacklist = [ '#555555', 'black' ]
		if has("autocmd")
			autocmd adds VimEnter *  silent! RainbowParentheses
		endif
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

	if adds#available('nvim-colorizer.lua')
		lua require'colorizer'.setup()
	endif

	"echohl ErrorMsg | echomsg "configure finished" | echohl NONE

endfunction

