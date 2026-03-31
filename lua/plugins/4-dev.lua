-- Dev
-- Plugins you actively use for coding.

--    Sections:
--       ## SNIPPETS
--       -> luasnip                        [snippet engine]
--       -> friendly-snippets              [snippet templates]

--       ## GIT
--       -> gitsigns.nvim                  [git hunks]
--       -> fugitive.vim                   [git commands]

--       ## ANALYZER
--       -> aerial.nvim                    [symbols tree]
--       -> litee-calltree.nvim            [calltree]

--       ## CODE DOCUMENTATION
--       -> dooku.nvim                     [html doc generator]
--       -> markdown-preview.nvim          [markdown previewer]
--       -> markmap.nvim                   [markdown mindmap]

--       -> guess-indent                   [guess-indent]

--       ## COMPILER
--       -> compiler.nvim                  [compiler]
--       -> overseer.nvim                  [task runner]

--       ## DEBUGGER
--       -> nvim-dap                       [debugger]

--       ## TESTING
--       -> neotest.nvim                   [unit testing]
--       -> nvim-coverage                  [code coverage]

local is_windows = vim.fn.has('win32') == 1 -- true if on windows

return {
  --  SNIPPETS ----------------------------------------------------------------
  --  Vim Snippets engine  [snippet engine] + [snippet templates]
  --  https://github.com/L3MON4D3/LuaSnip
  --  https://github.com/rafamadriz/friendly-snippets
  {
    "L3MON4D3/LuaSnip",
    build = not is_windows and "make install_jsregexp" or nil,
    dependencies = {
      "rafamadriz/friendly-snippets",
      "zeioth/NormalSnippets",
      "benfowler/telescope-luasnip.nvim",
    },
    event = "User BaseFile",
    opts = {
      history = true,
      delete_check_events = "TextChanged",
      region_check_events = "CursorMoved",
    },
    config = function(_, opts)
      if opts then require("luasnip").config.setup(opts) end
      vim.tbl_map(
        function(type) require("luasnip.loaders.from_" .. type).lazy_load() end,
        { "vscode", "snipmate", "lua" }
      )
      -- friendly-snippets - enable standardized comments snippets
      require("luasnip").filetype_extend("typescript", { "tsdoc" })
      require("luasnip").filetype_extend("javascript", { "jsdoc" })
      require("luasnip").filetype_extend("lua", { "luadoc" })
      require("luasnip").filetype_extend("python", { "pydoc" })
      require("luasnip").filetype_extend("sh", { "shelldoc" })
    end,
  },

  --  GIT ---------------------------------------------------------------------
  --  Git signs [git hunks]
  --  https://github.com/lewis6991/gitsigns.nvim
  {
    "lewis6991/gitsigns.nvim",
    enabled = vim.fn.executable("git") == 1,
    event = "User BaseGitFile",
    opts = function()
      local get_icon = require("base.utils").get_icon
      return {
        max_file_length = vim.g.big_file.lines,
        signs = {
          add = { text = get_icon("GitSign") },
          change = { text = get_icon("GitSign") },
          delete = { text = get_icon("GitSign") },
          topdelete = { text = get_icon("GitSign") },
          changedelete = { text = get_icon("GitSign") },
          untracked = { text = get_icon("GitSign") },
        },
      }
    end
  },

  --  Git fugitive mergetool + [git commands]
  --  https://github.com/lewis6991/gitsigns.nvim
  --  PR needed: Setup keymappings to move quickly when using this feature.
  --
  --  We only want this plugin to use it as mergetool like "git mergetool".
  --  To enable this feature, add this  to your global .gitconfig:
  --
  --  [mergetool "fugitive"]
  --  	cmd = nvim -c \"Gvdiffsplit!\" \"$MERGED\"
  --  [merge]
  --  	tool = fugitive
  --  [mergetool]
  --  	keepBackup = false
  {
    "tpope/vim-fugitive",
    enabled = vim.fn.executable("git") == 1,
    dependencies = { "tpope/vim-rhubarb" },
    cmd = {
      "Gvdiffsplit",
      "Gdiffsplit",
      "Gedit",
      "Gsplit",
      "Gread",
      "Gwrite",
      "Ggrep",
      "GMove",
      "GRename",
      "GDelete",
      "GRemove",
      "GBrowse",
      "Git",
      "Gstatus",
    },
    config = function()
      -- NOTE: On vim plugins we use config instead of opts.
      vim.g.fugitive_no_maps = 1
    end,
  },

  --  ANALYZER ----------------------------------------------------------------
  --  [symbols tree]
  --  https://github.com/stevearc/aerial.nvim
  {
    "stevearc/aerial.nvim",
    event = "User BaseFile",
    opts = {
      filter_kind = { -- Symbols that will appear on the tree
        -- "Class",
        "Constructor",
        "Enum",
        "Function",
        "Interface",
        -- "Module",
        "Method",
        -- "Struct",
      },
      open_automatic = false, -- Open if the buffer is compatible
      nerd_font = (vim.g.fallback_icons_enabled and false) or true,
      autojump = true,
      link_folds_to_tree = false,
      link_tree_to_folds = false,
      attach_mode = "global",
      backends = { "lsp", "treesitter", "markdown", "man" },
      disable_max_lines = vim.g.big_file.lines,
      disable_max_size = vim.g.big_file.size,
      layout = {
        min_width = 28,
        default_direction = "right",
        placement = "edge",
      },
      show_guides = true,
      guides = {
        mid_item = "├ ",
        last_item = "└ ",
        nested_top = "│ ",
        whitespace = "  ",
      },
      keymaps = {
        ["[y"] = "actions.prev",
        ["]y"] = "actions.next",
        ["[Y"] = "actions.prev_up",
        ["]Y"] = "actions.next_up",
        ["{"] = false,
        ["}"] = false,
        ["[["] = false,
        ["]]"] = false,
      },
    },
    config = function(_, opts)
      require("aerial").setup(opts)
      -- HACK: The first time you open aerial on a session, close all folds.
      vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
        desc = "Aerial: When aerial is opened, close all its folds.",
        callback = function()
          local is_aerial = vim.bo.filetype == "aerial"
          local is_ufo_available = require("base.utils").is_available("nvim-ufo")
          if is_ufo_available and is_aerial and vim.b.new_aerial_session == nil then
            vim.b.new_aerial_session = false
            require("aerial").tree_set_collapse_level(0, 0)
          end
        end,
      })
    end
  },

  -- Litee calltree [calltree]
  -- https://github.com/ldelossa/litee.nvim
  -- https://github.com/ldelossa/litee-calltree.nvim
  -- press ? inside the panel to show help.
  {
    'ldelossa/litee.nvim',
    event = "User BaseFile",
    opts = {
      notify = { enabled = false },
      tree = {
        icon_set = "default" -- "nerd", "codicons", "default", "simple"
      },
      panel = {
        orientation = "bottom",
        panel_size = 10,
      },
    },
    config = function(_, opts)
      require('litee.lib').setup(opts)
    end
  },
  {
    'ldelossa/litee-calltree.nvim',
    dependencies = 'ldelossa/litee.nvim',
    event = "User BaseFile",
    opts = {
      on_open = "panel", -- or popout
      map_resize_keys = false,
      keymaps = {
        expand = "<CR>",
        collapse = "c",
        collapse_all = "C",
        jump = "<C-CR>"
      },
    },
    config = function(_, opts)
      require('litee.calltree').setup(opts)

      -- Highlight only while on calltree
      vim.api.nvim_create_autocmd({ "WinEnter" }, {
        desc = "Clear highlights when leaving calltree + UX improvements.",
        callback = function()
          vim.defer_fn(function()
            if vim.bo.filetype == "calltree" then
              vim.wo.colorcolumn = "0"
              vim.wo.foldcolumn = "0"
              vim.cmd("silent! PinBuffer") -- stickybuf.nvim
              vim.cmd(
                "silent! hi LTSymbolJump ctermfg=015 ctermbg=110 cterm=italic,bold,underline guifg=#464646 guibg=#87afd7 gui=italic,bold")
              vim.cmd(
                "silent! hi LTSymbolJumpRefs ctermfg=015 ctermbg=110 cterm=italic,bold,underline guifg=#464646 guibg=#87afd7 gui=italic,bold")
            else
              vim.cmd("silent! highlight clear LTSymbolJump")
              vim.cmd("silent! highlight clear LTSymbolJumpRefs")
            end
          end, 100)
        end
      })
    end
  },

  --  CODE DOCUMENTATION ------------------------------------------------------
  --  dooku.nvim [html doc generator]
  --  https://github.com/zeioth/dooku.nvim
  {
    "zeioth/dooku.nvim",
    cmd = {
      "DookuGenerate",
      "DookuOpen",
      "DookuAutoSetup"
    },
    opts = {},
  },

  --  [markdown previewer]
  --  https://github.com/iamcco/markdown-preview.nvim
  --  Note: If you change the build command, wipe ~/.local/data/nvim/lazy
  {
    "iamcco/markdown-preview.nvim",
    build = function(plugin)
      -- guard clauses
      local yarn = (vim.fn.executable("yarn") and "yarn")
          or (vim.fn.executable("npx") and "npx -y yarn")
          or nil
      if not yarn then error("Missing `yarn` or `npx` in the PATH") end

      -- run cmd
      local cd_cmd = "!cd " .. plugin.dir .. " && cd app"
      local yarn_install_cmd = "COREPACK_ENABLE_AUTO_PIN=0 " .. yarn .. " install --frozen-lockfile"
      vim.cmd(cd_cmd .. " && " .. yarn_install_cmd)
    end,
    init = function()
      local plugin = require("lazy.core.config").spec.plugins["markdown-preview.nvim"]
      vim.g.mkdp_filetypes = require("lazy.core.plugin").values(plugin, "ft", true)
    end,
    ft = { "markdown", "markdown.mdx" },
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  },

  --  [markdown markmap]
  --  https://github.com/zeioth/markmap.nvim
  --  Important: Make sure you have yarn in your PATH before running markmap.
  {
    "zeioth/markmap.nvim",
    build = "yarn global add markmap-cli",
    cmd = { "MarkmapOpen", "MarkmapSave", "MarkmapWatch", "MarkmapWatchStop" },
    config = function(_, opts) require("markmap").setup(opts) end,
  },


  -- [guess-indent]
  -- https://github.com/NMAC427/guess-indent.nvim
  -- Note that this plugin won't autoformat the code.
  -- It just set the buffer options to tabluate in a certain way.
  {
    "NMAC427/guess-indent.nvim",
    event = "User BaseFile",
    opts = {}
  },

  --  COMPILER ----------------------------------------------------------------
  --  compiler.nvim [compiler]
  --  https://github.com/zeioth/compiler.nvim
  {
    "zeioth/compiler.nvim",
    cmd = {
      "CompilerOpen",
      "CompilerToggleResults",
      "CompilerRedo",
      "CompilerStop"
    },
    dependencies = { "stevearc/overseer.nvim" },
    opts = {},
  },

  --  overseer [task runner]
  --  https://github.com/stevearc/overseer.nvim
  --  If you need to close a task immediately:
  --  press ENTER in the output menu on the task you wanna close.
  {
    "stevearc/overseer.nvim",
    cmd = {
      "OverseerOpen",
      "OverseerClose",
      "OverseerToggle",
      "OverseerSaveBundle",
      "OverseerLoadBundle",
      "OverseerDeleteBundle",
      "OverseerRunCmd",
      "OverseerRun",
      "OverseerInfo",
      "OverseerBuild",
      "OverseerQuickAction",
      "OverseerTaskAction",
      "OverseerClearCache"
    },
    opts = {
      task_list = { -- the window that shows the results.
        direction = "bottom",
        min_height = 25,
        max_height = 25,
        default_detail = 1,
      },
      -- component_aliases = {
      --   default = {
      --     -- Behaviors that will apply to all tasks.
      --     "on_exit_set_status",                   -- don't delete this one.
      --     "on_output_summarize",                  -- show last line on the list.
      --     "display_duration",                     -- display duration.
      --     "on_complete_notify",                   -- notify on task start.
      --     "open_output",                          -- focus last executed task.
      --     { "on_complete_dispose", timeout=300 }, -- dispose old tasks.
      --   },
      -- },
    },
  },

  --  DEBUGGER ----------------------------------------------------------------
  --  Debugger alternative to vim-inspector [debugger]
  --  https://github.com/mfussenegger/nvim-dap
  --  Here we configure the adapter+config of every debugger.
  --  Debuggers don't have system dependencies, you just install them with mason.
  --  We currently ship most of them with nvim.
  {
    "mfussenegger/nvim-dap",
    enabled = vim.fn.has "win32" == 0,
    event = "User BaseFile",
    config = function()
      local dap = require("dap")

      -- Python
      dap.adapters.python = {
        type = 'executable',
        command = vim.fn.stdpath('data') .. '/mason/packages/debugpy/venv/bin/python',
        args = { '-m', 'debugpy.adapter' },
      }
      dap.configurations.python = {
        {
          type = "python",
          request = "launch",
          name = "Launch file",
          program = "${file}", -- This configuration will launch the current file if used.
        },
      }

      -- Lua
      dap.adapters.nlua = function(callback, config)
        callback({ type = 'server', host = config.host or "127.0.0.1", port = config.port or 8086 })
      end
      dap.configurations.lua = {
        {
          type = 'nlua',
          request = 'attach',
          name = "Attach to running Neovim instance",
          program = function() pcall(require "osv".launch({ port = 8086 })) end,
        }
      }

      -- Javascript / Typescript (firefox)
      dap.adapters.firefox = {
        type = 'executable',
        command = vim.fn.stdpath('data') .. '/mason/bin/firefox-debug-adapter',
      }
      dap.configurations.typescript = {
        {
          name = 'Debug with Firefox',
          type = 'firefox',
          request = 'launch',
          reAttach = true,
          url = 'http://localhost:5173', -- Write the actual URL of your project.
          webRoot = '${workspaceFolder}',
          firefoxExecutable = '/usr/bin/firefox'
        }
      }
      dap.configurations.javascript = dap.configurations.typescript
      dap.configurations.javascriptreact = dap.configurations.typescript
      dap.configurations.typescriptreact = dap.configurations.typescript

      -- Shell
      dap.adapters.bashdb = {
        type = 'executable',
        command = vim.fn.stdpath("data") .. '/mason/packages/bash-debug-adapter/bash-debug-adapter',
        name = 'bashdb',
      }
      dap.configurations.sh = {
        {
          type = 'bashdb',
          request = 'launch',
          name = "Launch file",
          showDebugOutput = true,
          pathBashdb = vim.fn.stdpath("data") .. '/mason/packages/bash-debug-adapter/extension/bashdb_dir/bashdb',
          pathBashdbLib = vim.fn.stdpath("data") .. '/mason/packages/bash-debug-adapter/extension/bashdb_dir',
          trace = true,
          file = "${file}",
          program = "${file}",
          cwd = '${workspaceFolder}',
          pathCat = "cat",
          pathBash = "/bin/bash",
          pathMkfifo = "mkfifo",
          pathPkill = "pkill",
          args = {},
          env = {},
          terminalKind = "integrated",
        }
      }
    end, -- of dap config
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "rcarriga/cmp-dap",
      "jay-babu/mason-nvim-dap.nvim",
      "jbyuki/one-small-step-for-vimkind",
    },
  },

  -- nvim-dap-ui [dap ui]
  -- https://github.com/mfussenegger/nvim-dap-ui
  -- user interface for the debugger dap
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "nvim-neotest/nvim-nio" },
    opts = { floating = { border = "rounded" } },
    config = function(_, opts)
      local dap, dapui = require("dap"), require("dapui")
      dap.listeners.after.event_initialized["dapui_config"] = function(
      )
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function(
      )
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
      dapui.setup(opts)
    end,
  },

  -- cmp-dap [dap autocomplete]
  -- https://github.com/mfussenegger/cmp-dap
  -- Enables autocomplete for the debugger dap.
  {
    "rcarriga/cmp-dap",
    dependencies = { "nvim-cmp" },
    config = function()
      require("cmp").setup.filetype(
        { "dap-repl", "dapui_watches", "dapui_hover" },
        {
          sources = {
            { name = "dap" },
          },
        }
      )
    end,
  },

  --  TESTING -----------------------------------------------------------------
  --  Run tests inside of nvim [unit testing]
  --  https://github.com/nvim-neotest/neotest
  --
  --
  --  MANUAL:
  --  -- Unit testing:
  --  To tun an unit test you can run any of these commands:
  --
  --    :Neotest run      -- Runs the nearest test to the cursor.
  --    :Neotest stop     -- Stop the nearest test to the cursor.
  --    :Neotest run file -- Run all tests in the file.
  --
  --  -- E2e and Test Suite
  --  Normally you will prefer to open your e2e framework GUI outside of nvim.
  --  But you have the next commands in ../base/3-autocmds.lua:
  --
  --    :TestNodejs    -- Run all tests for this nodejs project.
  --    :TestNodejsE2e -- Run the e2e tests/suite for this nodejs project.
  {
    "nvim-neotest/neotest",
    cmd = { "Neotest" },
    dependencies = {
      "nvim-neotest/neotest-jest",
    },
    opts = function()
      return {
        -- your neotest config here
        adapters = {
          require("neotest-jest"),
        },
      }
    end,
    config = function(_, opts)
      -- get neotest namespace (api call creates or returns namespace)
      local neotest_ns = vim.api.nvim_create_namespace "neotest"
      vim.diagnostic.config({
        float = {
          border = "rounded",
          width = 60,
          source = true,
          wrap = true,
        },
        virtual_text = {
          format = function(diagnostic)
            local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
            return message
          end,
        },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      }, neotest_ns)
      require("neotest").setup(opts)
    end,
  },

  --  Shows a float panel with the [code coverage]
  --  https://github.com/andythigpen/nvim-coverage
  --
  --  Your project must generate coverage/lcov.info for this to work.
  --
  --  On jest, make sure your packages.json file has this:
  --  "tests": "jest --coverage"
  --
  --  If you use other framework or language, refer to nvim-coverage docs:
  --  https://github.com/andythigpen/nvim-coverage/blob/main/doc/nvim-coverage.txt
  {
    "andythigpen/nvim-coverage",
    cmd = {
      "Coverage",
      "CoverageLoad",
      "CoverageLoadLcov",
      "CoverageShow",
      "CoverageHide",
      "CoverageToggle",
      "CoverageClear",
      "CoverageSummary",
    },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      summary = {
        min_coverage = 80.0, -- passes if higher than
      },
    },
    config = function(_, opts) require("coverage").setup(opts) end,
  },

  {
    "ThePrimeagen/99",
    event = "VeryLazy",
    config = function()
      -- Ensure opencode is on PATH for vim.system calls
      local opencode_bin = vim.fn.expand("~/.opencode/bin")
      if vim.fn.isdirectory(opencode_bin) == 1 and not vim.env.PATH:find(opencode_bin, 1, true) then
        vim.env.PATH = opencode_bin .. ":" .. vim.env.PATH
      end

      local _99 = require("99")

      -- For logging that is to a file if you wish to trace through requests
      -- for reporting bugs, i would not rely on this, but instead the provided
      -- logging mechanisms within 99.  This is for more debugging purposes
      local cwd = vim.uv.cwd()
      local basename = vim.fs.basename(cwd)
      _99.setup({
        provider = _99.ClaudeCodeProvider, -- default: OpenCodeProvider
        logger = {
          level = _99.DEBUG,
          path = "/tmp/" .. basename .. ".99.debug",
          print_on_error = true,
        },

        --- Completions: #rules and @files in the prompt buffer
        completion = {
          -- I am going to disable these until i understand the
          -- problem better.  Inside of cursor rules there is also
          -- application rules, which means i need to apply these
          -- differently
          -- cursor_rules = "<custom path to cursor rules>"

          --- A list of folders where you have your own SKILL.md
          --- Expected format:
          --- /path/to/dir/<skill_name>/SKILL.md
          ---
          --- Example:
          --- Input Path:
          --- "scratch/custom_rules/"
          ---
          --- Output Rules:
          --- {path = "scratch/custom_rules/vim/SKILL.md", name = "vim"},
          --- ... the other rules in that dir ...
          ---
          custom_rules = {
            "./cursor/skills/",
          },

          --- Configure @file completion (all fields optional, sensible defaults)
          files = {
            enabled = true,
            max_file_size = 102400, -- bytes, skip files larger than this
            max_files = 5000,       -- cap on total discovered files
            exclude = { ".env", ".env.*", "node_modules", ".git" },
          },

          --- What autocomplete do you use.  We currently only
          --- support cmp right now
          source = "cmp",
        },

        --- WARNING: if you change cwd then this is likely broken
        --- ill likely fix this in a later change
        ---
        --- md_files is a list of files to look for and auto add based on the location
        --- of the originating request.  That means if you are at /foo/bar/baz.lua
        --- the system will automagically look for:
        --- /foo/bar/AGENT.md
        --- /foo/AGENT.md
        --- assuming that /foo is project root (based on cwd)
        md_files = {
          "AGENT.md",
        },
      })

      -- take extra note that i have visual selection only in v mode
      -- technically whatever your last visual selection is, will be used
      -- so i have this set to visual mode so i dont screw up and use an
      -- old visual selection
      --
      -- likely ill add a mode check and assert on required visual mode
      -- so just prepare for it now
      vim.keymap.set("v", "<leader>9v", function()
        _99.visual()
      end)

      --- if you have a request you dont want to make any changes, just cancel it
      vim.keymap.set("v", "<leader>9s", function()
        _99.stop_all_requests()
      end)
    end,
  },
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    opts = {
      terminal = {
        git_repo_cwd = true,
      },
    },
    keys = {
      { "<leader>a",  nil,                              desc = "AI/Claude Code" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>",            desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>",       desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>",   desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",       desc = "Add current buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>",        mode = "v",                  desc = "Send to Claude" },
      {
        "<leader>as",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file",
        ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
      },
      -- Diff management
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",   desc = "Deny diff" },
    },
  },
  {
    'kkrampis/codex.nvim',
    lazy = true,
    cmd = { 'Codex', 'CodexToggle' }, -- Optional: Load only on command execution
    keys = {
      {
        '<leader>cc', -- Change this to your preferred keybinding
        function()
          local codex = require 'codex'
          codex.setup { cmd = { 'codex', '--no-alt-screen' } }
          codex.toggle()
        end,
        desc = 'Toggle Codex popup or side-panel',
        mode = { 'n', 't' }
      },
      {
        '<leader>cr',
        function()
          local codex = require 'codex'
          local state = require 'codex.state'

          -- Restart with resume picker command so codex.nvim opens in its panel.
          if state.job then
            vim.fn.jobstop(state.job)
            state.job = nil
          end

          codex.close()
          codex.setup { cmd = { 'codex', '--no-alt-screen', 'resume' } }
          codex.open()
          vim.cmd 'startinsert'
        end,
        desc = 'Resume Codex',
        mode = 'n',
      },
    },
    opts = {
      keymaps     = {
        toggle = nil,      -- Keybind to toggle Codex window (Disabled by default, watch out for conflicts)
        quit = '<C-q>',    -- Keybind to close the Codex window (default: Ctrl + q)
      },                   -- Disable internal default keymap (<leader>cc -> :CodexToggle)
      width       = 0.4,   -- Width of the floating window (0.0 to 1.0)
      height      = 0.8,   -- Height of the floating window (0.0 to 1.0)
      model       = nil,   -- Optional: pass a string to use a specific model (e.g., 'o3-mini')
      autoinstall = true,  -- Automatically install the Codex CLI if not found
      panel       = true,  -- Open Codex in a side-panel (vertical split) instead of floating window
      use_buffer  = false, -- Capture Codex stdout into a normal buffer instead of a terminal buffer
    },
  },
  {
    'pwntester/octo.nvim',
    event = "VeryLazy",
    lazy = false,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      require "octo".setup({ enable_builtin = true })
      vim.cmd([[hi OctoEditable guibg=none]])
    end,
    keys = {
      { "<leader>O", "<cmd>Octo<cr>", desc = "Octo" },
    },
  },
} -- end of return
