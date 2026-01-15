return {
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      -- Capabilities (with nvim-cmp integration)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

      -- Disable Ruff hover in favor of Pyright when both attach
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup('lsp_attach_disable_ruff_hover', { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client == nil then
            return
          end
          if client.name == 'ruff' then
            client.server_capabilities.hoverProvider = false
          end
        end,
        desc = 'LSP: Disable hover capability from Ruff',
      })

      -- Reasonable updatetime for hover and diagnostics
      vim.o.updatetime = 1000

      -- General on_attach function for LSP
      local on_attach = function(client, bufnr)
        local buf_set_keymap = function(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
        local opts = { noremap = true, silent = true }

        -- Code actions
        buf_set_keymap("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
        -- Go to definition
        buf_set_keymap("n", "<leader>gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
        -- References
        buf_set_keymap("n", "<leader>gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
        -- Implementation
        buf_set_keymap("n", "<leader>gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
        -- Workspace symbols
        buf_set_keymap("n", "<leader>gw", "<cmd>lua vim.lsp.buf.workspace_symbol()<CR>", opts)
        -- Signature help
        buf_set_keymap("n", "<leader>gs", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
        -- Hover (manual on K)
        buf_set_keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
      end

      -- Server configurations (Neovim 0.11+ style)
      local servers = {
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = {
                globals = { "vim" },
                disable = { "different-requires" },
              },
            },
          },
        },
        ts_ls = {},
        rust_analyzer = {},
        gopls = {
          filetypes = { "go", "gomod", "gowork", "gotmpl" },
          settings = {
            env = { GOEXPERIMENT = "rangefunc" },
            formatting = { gofumpt = true },
          },
        },
        tailwindcss = {
          settings = {
            includeLanguages = {
              templ = "html",
            },
          },
        },
        templ = {},
        nil_ls = {},
        omnisharp = {},
        pyright = {
          settings = {
            pyright = { disableOrganizeImports = true },
            python = { analysis = { ignore = { '*' } } },
          },
        },
        ruff = {
          init_options = {
            settings = {
              -- Ruff language server settings
            }
          },
        },
      }

      for name, conf in pairs(servers) do
        conf.capabilities = capabilities
        conf.on_attach = on_attach
        vim.lsp.config(name, conf)
        vim.lsp.enable(name)
      end
    end,
  },
}
