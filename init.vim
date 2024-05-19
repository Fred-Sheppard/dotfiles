call plug#begin('/home/fred/.local/share/nvim/plugged')

Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'neovim/nvim-lspconfig'
Plug 'numToStr/Comment.nvim'


" Wilder.nvim
function! UpdateRemotePlugins(...)
    " Needed to refresh runtime files
    let &rtp=&rtp
    UpdateRemotePlugins
endfunction
Plug 'gelguy/wilder.nvim', { 'do': function('UpdateRemotePlugins') }

call plug#end()

call wilder#setup({'modes': [':', '/', '?']})
colorscheme catppuccin-macchiato
set clipboard=unnamedplus
set relativenumber
set shiftwidth=4 smarttab
set expandtab
set tabstop=8 softtabstop=0

let mapleader = ' '
nnoremap <Leader>a ggVG
inoremap <M-BS> <C-W>
nnoremap <Leader>h :nohl<CR>
nnoremap <Leader>q :q!<CR>
nnoremap <Leader>w :x<CR>
nnoremap <Leader>c :w<CR>
nnoremap gl :lua vim.diagnostic.open_float()<CR>

lua <<EOF
require'nvim-treesitter.configs'.setup {
	highlight = {
		enable = true,
	}
}
require'lspconfig'.hls.setup{
settings = {
    ['hls-analyzer'] = {},
  },
}
require('Comment').setup()
EOF
