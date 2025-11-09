-- ==============================================
-- null-ls 插件配置：第三方工具集成框架（专注代码格式化功能）
-- 原作者备注：虽然 null-ls 能做更多事情（如代码诊断、代码操作），但本配置仅用它做格式化
--            其他功能（诊断/代码操作）交给 LspSaga 处理（详见 lsp/extra.lua）
-- 插件介绍（none-ls.nvim，原 null-ls.nvim，已迁移到 nvimtools 组织）：
-- - 核心定位：Neovim 与第三方命令行工具的「桥梁」，让外部工具无缝集成到 LSP 工作流
-- - 核心功能：
--   1. 格式化：集成第三方格式化工具（如 black、prettier），通过 LSP 接口触发
--   2. 诊断：集成 lint 工具（如 eslint、flake8），将结果转为 LSP 诊断信息
--   3. 代码操作：集成代码修复工具（如 eslint --fix），提供一键修复功能
-- - 本配置聚焦：仅启用格式化功能，保持配置简洁，避免与 LspSaga 功能冲突
-- - 优势：无需手动执行命令行工具，通过 LSP 统一接口（如 vim.lsp.buf.format）触发，体验一致
-- 新手说明：以下逐节解释配置逻辑、工具集成、快捷键使用，新手可直接复用，无需修改
-- ==============================================

Ice.plugins["null-ls"] = {
    -- 插件基础信息：GitHub 仓库地址（原 null-ls.nvim，现迁移到 nvimtools 组织，改名为 none-ls）
    "nvimtools/none-ls.nvim",
    -- 依赖插件：核心辅助工具
    dependencies = {
        "nvim-lua/plenary.nvim",  -- Lua 工具函数库（null-ls 依赖其处理异步操作、路径处理等）
    },
    -- 插件加载时机：IceNvim 自定义事件触发（确保在 LSP 配置加载后启动，避免依赖冲突）
    event = "User IceLoad",
    -- 插件基础配置选项
    opts = {
        debug = false,  -- 禁用调试模式（启用后会输出详细日志，用于排查问题，默认关闭以减少干扰）
    },
    -- 插件自定义配置函数（核心逻辑：配置格式化工具集成）
    config = function(_, opts)
        -- 引入 null-ls 模块
        local null_ls = require "null-ls"
        -- 提取 null-ls 的格式化工具集合（仅关注格式化功能）
        local formatting = null_ls.builtins.formatting

        -- 存储要启用的格式化工具列表
        local sources = {}
        -- 遍历 Ice.lsp 配置（Ice.lsp 中存储了各语言的 LSP 配置，含格式化工具指定）
        -- 逻辑：若某语言配置中指定了 formatter（如 Python 配置 formatter = "black"），则添加对应的格式化工具
        for _, config in pairs(Ice.lsp) do
            if config.formatter then
                -- 根据 formatter 名称获取对应的 null-ls 格式化工具（如 config.formatter = "black" → formatting.black）
                local source = formatting[config.formatter]
                -- 将工具添加到 sources 列表（后续会传递给 null-ls 启动）
                sources[#sources + 1] = source
            end
        end

        -- 启动 null-ls：合并基础配置（opts）和格式化工具列表（sources）
        -- vim.tbl_deep_extend("keep", a, b)：深度合并两个表，保留 a 中原有字段，用 b 补充新字段
        null_ls.setup(vim.tbl_deep_extend("keep", opts, { sources = sources }))
    end,
    -- 自定义快捷键配置（格式化功能的核心触发方式）
    keys = {
        {
            "<leader>lf",  -- 快捷键：<leader>（空格）+ lf（格式：format）
            function()
                -- 查找当前缓冲区激活的 null-ls 客户端（判断 null-ls 是否已加载并可用）
                local active_client = vim.lsp.get_clients { bufnr = 0, name = "null-ls" }

                -- 格式化选项配置
                local format_option = { async = true }  -- 异步格式化（不阻塞 Neovim 主线程，编辑不卡顿）
                -- 若 null-ls 已激活，指定格式化由 null-ls 执行（避免与 LSP 内置格式化冲突）
                if #active_client > 0 then
                    format_option.name = "null-ls"  -- 强制使用 null-ls 进行格式化
                end
                -- 执行格式化（调用 LSP 统一格式化接口，自动适配 null-ls）
                vim.lsp.buf.format(format_option)
            end,
            mode = { "n", "v" },  -- 支持普通模式（n）和视觉模式（v）
            desc = "代码格式化（使用 null-ls 集成的第三方工具）",  -- 快捷键描述（:checkhealth 或插件中可查看）
        },
    },
}

-- ==============================================
-- 核心概念&工具集成详解（新手必看）
-- ==============================================
-- 一、核心逻辑拆解：
-- 1. 配置关联：null-ls 的格式化工具由 Ice.lsp 配置驱动（如 Ice.lsp.python.formatter = "black"）
--    - 示例：若 Ice.lsp 中 Python 配置指定 formatter = "black"，则 null-ls 自动加载 formatting.black 工具
--    - 好处：集中管理各语言的格式化工具，无需在 null-ls 中重复配置
-- 2. 触发方式：
--    - 手动触发：快捷键 <leader>lf（普通模式格式化整个文件，视觉模式格式化选中内容）
--    - 自动触发：若 lsp/format.lua 中配置了保存自动格式化，则 :w 时会自动调用该功能
-- 3. 冲突处理：强制指定由 null-ls 执行格式化（避免 LSP 内置格式化与第三方工具冲突）

-- 二、常用格式化工具&对应语言（Ice.lsp 中可配置的 formatter 名称）：
-- | formatter 名称 | 对应工具       | 支持语言                | 核心功能                                  |
-- |----------------|----------------|-------------------------|-------------------------------------------|
-- | black          | black          | Python                  | 强制遵循 PEP8 规范，自动调整缩进、行宽（88列） |
-- | prettier       | prettier       | JS/TS/HTML/CSS/JSON     | 前端通用格式化，统一代码风格（如缩进、引号） |
-- | clang-format   | clang-format   | C/C++/Java/Objective-C  | C 系语言格式化，支持自定义代码风格（如 Google 风格） |
-- | stylua         | stylua         | Lua                     | Lua 代码格式化，适配 Neovim 配置文件        |
-- | eslint_d       | eslint         | JS/TS/Vue               | 前端代码格式化+语法检查（本配置仅用格式化功能） |
-- | gofmt          | gofmt          | Go                      | Go 语言官方格式化工具，强制统一代码风格      |
-- | rustfmt        | rustfmt        | Rust                    | Rust 官方格式化工具，遵循 Rust 代码规范     |

-- 三、快捷键汇总（格式化功能核心操作）
-- | 快捷键       | 模式         | 功能描述                                  | 适用场景                                  |
-- |--------------|--------------|-------------------------------------------|-------------------------------------------|
-- | <leader>lf   | 普通模式（n）| 格式化整个当前文件                        | 编辑完文件后，统一格式化代码风格            |
-- | <leader>lf   | 视觉模式（v）| 格式化选中的代码片段                      | 仅优化部分代码（如复制粘贴的代码）          |

-- ==============================================
-- 新手使用注意点（避坑指南）
-- ==============================================
-- 1. 工具安装：null-ls 仅提供集成能力，需手动安装对应的第三方格式化工具（如 black、prettier）
--    - 安装方式：
--      - Python 工具（black/flake8）：pip install black
--      - 前端工具（prettier/eslint）：npm install -g prettier eslint
--      - C 系工具（clang-format）：sudo apt install clang-format（Linux）/ brew install clang-format（Mac）
--    - 验证安装：终端执行工具名（如 black --version），能正常输出版本即安装成功
-- 2. 配置关联：需在 Ice.lsp 中为对应语言指定 formatter（否则 null-ls 无格式化工具可用）
--    - 示例配置（在 custom/init.lua 中添加）：
--      Ice.lsp = Ice.lsp or {}
--      Ice.lsp.python = { formatter = "black" }  -- Python 使用 black 格式化
--      Ice.lsp.javascript = { formatter = "prettier" }  -- JS 使用 prettier 格式化
-- 3. 格式化失效排查：
--    - 步骤1：检查第三方工具是否安装（终端执行工具名验证）
--    - 步骤2：检查 Ice.lsp 中是否为当前语言指定了 formatter
--    - 步骤3：执行 :NullLsInfo 查看 null-ls 状态（是否加载成功、格式化工具是否已注册）
--    - 步骤4：检查是否有其他插件占用格式化接口（如 LSP 内置格式化）
-- 4. 异步格式化：配置中启用 async = true（默认），格式化时不会阻塞编辑（大文件格式化也不卡顿）
-- 5. 视觉模式格式化：选中代码后按 <leader>lf，仅格式化选中部分（适合局部优化，不影响其他代码）
-- 6. 插件迁移说明：原插件名是 "jose-elias-alvarez/null-ls.nvim"，现已迁移到 "nvimtools/none-ls.nvim"
--    - 若出现插件安装失败，确保仓库地址正确（使用新地址 "nvimtools/none-ls.nvim"）