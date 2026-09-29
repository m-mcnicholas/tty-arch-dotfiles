local M = {}
local packs = {
  ['lang-js'] = { parsers = { 'javascript', 'typescript', 'tsx' }, servers = { 'ts_ls' }, formatters = { javascript = {'prettier'}, javascriptreact = {'prettier'}, typescript = {'prettier'}, typescriptreact = {'prettier'} } },
  ['lang-web'] = { parsers = { 'html', 'css' }, servers = { 'html', 'cssls' }, formatters = { html = {'prettier'}, css = {'prettier'} } },
  ['lang-json'] = { parsers = { 'json' }, servers = { 'jsonls' }, formatters = { json = {'prettier'} } },
  ['lang-python'] = { parsers = { 'python' }, servers = { 'pyright' }, formatters = { python = {'ruff_format'} } },
  ['lang-bash'] = { parsers = { 'bash' }, servers = { 'bashls' }, formatters = { sh = {'shfmt'}, bash = {'shfmt'} } },
  ['lang-lua'] = { parsers = { 'lua' }, servers = { 'lua_ls' }, formatters = { lua = {'stylua'} } },
  ['lang-markdown'] = { parsers = { 'markdown', 'markdown_inline' }, servers = { 'marksman' }, formatters = { markdown = {'prettier'} } },
  ['lang-rust'] = { parsers = { 'rust' }, servers = { 'rust_analyzer' }, formatters = { rust = {'rustfmt'} } },
}
local function enabled()
  local dir = (vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. '/.config')) .. '/tty-setup/languages'
  local result = {}
  for id, pack in pairs(packs) do
    if vim.fn.filereadable(dir .. '/' .. id) == 1 then table.insert(result, pack) end
  end
  return result
end
function M.parsers()
  local result = {}
  for _, pack in ipairs(enabled()) do vim.list_extend(result, pack.parsers) end
  return result
end
function M.servers()
  local result = {}
  for _, pack in ipairs(enabled()) do vim.list_extend(result, pack.servers) end
  return result
end
function M.formatters()
  local result = {}
  for _, pack in ipairs(enabled()) do
    for ft, formatters in pairs(pack.formatters) do result[ft] = formatters end
  end
  return result
end
function M.install()
  local missing = {}
  for _, parser in ipairs(M.parsers()) do
    if #vim.api.nvim_get_runtime_file('parser/' .. parser .. '.so', false) == 0 then
      table.insert(missing, parser)
    end
  end
  if #missing > 0 then
    vim.cmd('TSInstallSync ' .. table.concat(missing, ' '))
    for _, parser in ipairs(missing) do
      if #vim.api.nvim_get_runtime_file('parser/' .. parser .. '.so', false) == 0 then
        error('Tree-sitter parser was not installed: ' .. parser)
      end
    end
  end
end
return M
