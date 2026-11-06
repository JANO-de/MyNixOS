return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    window = { position = "left", width = 30 },
    filesystem = {
      follow_current_file = { enabled = true },
      filtered_items = { visible = true, hide_dotfiles = false },
    },
  },
}
