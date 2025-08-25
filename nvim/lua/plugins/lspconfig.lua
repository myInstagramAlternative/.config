return {
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

      -- Create autocmd to disable Ruff hover in favor of Pyright
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup('lsp_attach_disable_ruff_hover', { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client == nil then
            return
          end
          if client.name == 'ruff' then
            -- Disable hover in favor of Pyright
            client.server_capabilities.hoverProvider = false
          end
        end,
        desc = 'LSP: Disable hover capability from Ruff',
      })

      -- Set updatetime for CursorHold event
      vim.o.updatetime = 1000

      -- -- Set up global hover handler before any LSP setup
      -- vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
      --   vim.lsp.handlers.hover, {
      --     focusable = false,
      --     border = "rounded"
      --   }
      -- )

      -- General on_attach function for LSP
      local on_attach = function(client, bufnr)
        -- Set key mappings for LSP
        local buf_set_keymap = function(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
        local opts = { noremap = true, silent = true }

        -- Mapping for code actions
        buf_set_keymap("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)

        -- Mapping to go to definition
        buf_set_keymap("n", "<leader>gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)

        -- Mapping to list references
        buf_set_keymap("n", "<leader>gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)

        -- Mapping to go to implementation
        buf_set_keymap("n", "<leader>gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)

        -- Mapping to list workspace symbols
        buf_set_keymap("n", "<leader>gw", "<cmd>lua vim.lsp.buf.workspace_symbol()<CR>", opts)

        -- Mapping to show signature help
        buf_set_keymap("n", "<leader>gs", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)

        -- Add manual hover mapping instead of automatic
        buf_set_keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)

        -- Setup CursorHold to show hover information automatically
        -- This will show hover windows when you hold the cursor, but they won't be focusable
        -- vim.api.nvim_create_autocmd("CursorHold", {
        --   buffer = bufnr,
        --   callback = function()
        --     vim.lsp.buf.hover()
        --   end,
        -- })
      end

      -- LSP server configurations
      lspconfig.lua_ls.setup({
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
              disable = { "different-requires" },
            },
          },
        },
        on_attach = on_attach,
        capabilities = capabilities,
      })

      lspconfig.ts_ls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
      })

      lspconfig.rust_analyzer.setup({
        on_attach = on_attach,
        capabilities = capabilities,
      })

      lspconfig.gopls.setup({
        filetypes = { "go", "gomod", "gowork", "gotmpl" },
        settings = {
          env = {
            GOEXPERIMENT = "rangefunc",
          },
          formatting = {
            gofumpt = true,
          },
        },
        on_attach = on_attach,
        capabilities = capabilities,
      })

      lspconfig.tailwindcss.setup({
        settings = {
          includeLanguages = {
            templ = "html",
          },
        },
        on_attach = on_attach,
        capabilities = capabilities,
      })

      lspconfig.templ.setup({
        on_attach = on_attach,
        capabilities = capabilities,
      })

      lspconfig.nil_ls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
      })

      lspconfig.omnisharp.setup({
        on_attach = on_attach,
        capabilities = capabilities,
      })

      lspconfig.pyright.setup({
        settings = {
          pyright = {
            -- Using Ruff's import organizer
            disableOrganizeImports = true,
          },
          python = {
            analysis = {
              -- Ignore all files for analysis to exclusively use Ruff for linting
              ignore = { '*' },
            },
          },
        },
        on_attach = on_attach,
        capabilities = capabilities,
      })

      lspconfig.ruff.setup({
        init_options = {
          settings = {
            -- Ruff language server settings go here
          }
        },
        on_attach = on_attach,
        capabilities = capabilities,
      })
    end,
  },
}
