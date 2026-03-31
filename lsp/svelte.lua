--- Svelte Language Server
--- https://github.com/sveltejs/language-tools/tree/master/packages/language-server

---@type vim.lsp.Config
return {
  settings = {
    svelte = {
      plugin = {
        svelte = {
          format = { enable = true },
        },
      },
      ["enable-ts-plugin"] = true,
    },
  },
}
