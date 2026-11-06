return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      lua_ls = { mason = false },
      nil_ls = { mason = false },
      vtsls = { mason = false },
      tailwindcss = { mason = false },
      jsonls = { mason = false },
      yamlls = { mason = false },
      taplo = { mason = false },
      marksman = { mason = false },
      bashls = { mason = false },
    },
  },
}
