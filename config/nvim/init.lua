vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = 'yes'
vim.opt.cursorline = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.termguicolors = false
vim.opt.mouse = ''
vim.opt.undofile = true
vim.opt.updatetime = 250
vim.cmd.colorscheme('habamax')

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('n', '<leader>w', '<cmd>write<CR>', { desc = 'Write file' })
vim.keymap.set('n', '<leader>q', '<cmd>quit<CR>', { desc = 'Quit window' })
vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  local result = vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable',
    'https://github.com/folke/lazy.nvim.git', lazypath })
  if vim.v.shell_error ~= 0 then error('lazy.nvim bootstrap failed: ' .. result) end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  { 'nvim-treesitter/nvim-treesitter', branch = 'master', build = ':TSUpdate', config = function()
    require('nvim-treesitter.configs').setup({
      ensure_installed = { 'bash', 'css', 'html', 'javascript', 'json', 'lua', 'markdown',
        'markdown_inline', 'python', 'tsx', 'typescript' },
      auto_install = false,
      highlight = { enable = true },
      indent = { enable = true },
    })
  end },
  { 'nvim-telescope/telescope.nvim', dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local t = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', t.find_files, { desc = 'Find files' })
      vim.keymap.set('n', '<leader>fg', t.live_grep, { desc = 'Search text' })
      vim.keymap.set('n', '<leader>fb', t.buffers, { desc = 'Buffers' })
      vim.keymap.set('n', '<leader>fh', t.help_tags, { desc = 'Help' })
    end },
  { 'lewis6991/gitsigns.nvim', opts = { signs = {
    add = { text = '+' }, change = { text = '~' }, delete = { text = '-' },
    topdelete = { text = '^' }, changedelete = { text = '~' },
  } } },
  { 'neovim/nvim-lspconfig', dependencies = { 'hrsh7th/cmp-nvim-lsp' },
    config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local servers = { 'ts_ls', 'html', 'cssls', 'jsonls', 'pyright', 'bashls', 'lua_ls', 'marksman' }
      for _, name in ipairs(servers) do
        vim.lsp.config(name, { capabilities = capabilities })
        vim.lsp.enable(name)
      end
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(event)
          local opts = { buffer = event.buf }
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
          vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)
          vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
        end,
      })
      vim.diagnostic.config({ virtual_text = { prefix = '!' }, signs = true })
    end },
  { 'hrsh7th/nvim-cmp', dependencies = { 'hrsh7th/cmp-nvim-lsp', 'hrsh7th/cmp-buffer', 'hrsh7th/cmp-path' },
    config = function()
      local cmp = require('cmp')
      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = false }),
          ['<C-n>'] = cmp.mapping.select_next_item(),
          ['<C-p>'] = cmp.mapping.select_prev_item(),
        }),
        sources = cmp.config.sources({ { name = 'nvim_lsp' }, { name = 'path' } },
          { { name = 'buffer' } }),
      })
    end },
  { 'stevearc/conform.nvim', opts = {
    formatters_by_ft = {
      javascript = { 'prettier' }, javascriptreact = { 'prettier' },
      typescript = { 'prettier' }, typescriptreact = { 'prettier' },
      html = { 'prettier' }, css = { 'prettier' }, json = { 'prettier' },
      markdown = { 'prettier' }, python = { 'ruff_format' },
      sh = { 'shfmt' }, bash = { 'shfmt' }, lua = { 'stylua' },
    },
    format_on_save = { timeout_ms = 1500, lsp_format = 'fallback' },
  }, config = function(_, opts)
    require('conform').setup(opts)
    vim.keymap.set('n', '<leader>F', function()
      require('conform').format({ async = true, lsp_format = 'fallback' })
    end, { desc = 'Format buffer' })
  end },
}, {
  lockfile = vim.fn.stdpath('config') .. '/lazy-lock.json',
  install = { missing = true, colorscheme = { 'habamax' } },
  checker = { enabled = false },
  change_detection = { notify = false },
  ui = { icons = { cmd = ':', config = '*', event = '@', ft = 'ft', init = '+', keys = 'key',
    plugin = '*', runtime = 'rt', require = 'req', source = 'src', start = '>', task = '>' } },
})
