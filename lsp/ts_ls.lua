--- TypeScript Language Server
--- https://github.com/typescript-language-server/typescript-language-server
--- Extends the default nvim-lspconfig config with project-specific settings.

---@type vim.lsp.Config
return {
  -- Prefer the git root so monorepo subdirectories don't hijack the cwd.
  -- Falls back to the nearest tsconfig/jsconfig/package.json when not in
  -- a git repo.
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { '.git' })
      or vim.fs.root(bufnr, { 'tsconfig.json', 'jsconfig.json', 'package.json' })
    if root then
      on_dir(root)
    end
  end,
}
