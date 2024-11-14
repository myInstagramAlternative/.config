return {
    {
      "zbirenbaum/copilot.lua",
      cmd = "Copilot",
      event = "InsertEnter",
      lazy = true,
      opts = function()
        return require("plugins.configs.copilot")
      end,
      config = function(_, opts)
        require("copilot").setup(opts)
      end,
      build = ":Copilot auth",
    }
}