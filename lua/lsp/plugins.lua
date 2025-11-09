-- ==============================================
-- 语言专属插件+Mason 配置：聚焦特定语言开发增强和 LSP 服务管理
-- 核心定位：
-- 1. 语言专属插件：为 Flutter/Rust/Typst 提供针对性开发功能（如预览、调试集成）
-- 2. Mason：LSP 服务/格式化工具的「自动安装管理器」，统一管理依赖，避免手动配置
-- 配置逻辑：
-- - 语言插件：按文件类型加载（如 .dart 文件触发 flutter-tools），按需启用
-- - Mason：自动安装 Ice.lsp 中配置的 LSP 服务和格式化工具，初始化 LSP 配置
-- 新手说明：以下逐插件详解功能、配置和使用，所有注释不修改原代码，可直接粘贴
-- ==============================================

local symbols = Ice.symbols  -- 引入统一图标配置（复用 Ice.symbols 中的图标）

-- 一、Flutter 开发增强插件：nvim-flutter/flutter-tools.nvim
-- 插件介绍：
-- - 核心定位：Flutter/Dart 开发的「一站式增强工具」，整合 dartls LSP 服务，提供远超原生的开发体验
-- - 核心功能：
--   1. 热重载/热重启：快捷键触发，无需手动输入 flutter run 命令
--   2. 设备管理：列出连接的设备（手机/模拟器），支持快速切换
--   3. Widget 预览：实时预览 Flutter 组件效果（部分功能需配合 Flutter SDK）
--   4. 调试集成：与 nvim-dap 配合，支持断点调试、变量查看
--   5. 代码辅助：增强 Dart 补全、重构、语法检查（基于 dartls）
-- - 依赖：plenary.nvim（工具函数库）、dressing.nvim（UI 美化）
Ice.plugins["flutter-tools"] = {
    "nvim-flutter/flutter-tools.nvim",  -- 插件 GitHub 仓库地址
    ft = "dart",  -- 加载时机：仅打开 .dart 文件时加载（提升启动速度）
    dependencies = {
        "nvim-lua/plenary.nvim",  -- 提供异步操作、路径处理等基础工具函数
        "stevearc/dressing.nvim",  -- 美化插件的 UI 界面（如选择设备的弹窗）
    },
    main = "flutter-tools",  -- 插件入口模块名（require("flutter-tools")）
    opts = {
        ui = {
            border = "rounded",  -- UI 窗口圆角边框（美观，与整体配置风格统一）
        },
        decorations = {
            statusline = {
                app_version = true,  -- 状态栏显示 Flutter 应用版本
                device = true,        -- 状态栏显示当前连接的设备名称（如 "iPhone 15"）
            },
        },
    },
    -- 启用条件：仅当 Ice.lsp.flutter.enabled 为 true 时启用（通过 Ice.lsp 统一控制）
    enabled = function()
        return Ice.lsp.flutter.enabled == true
    end,
}

-- 二、Rust 开发增强插件：mrcjkb/rustaceanvim
-- 插件介绍：
-- - 核心定位：Rust 开发的「终极增强工具」，基于 rust-analyzer LSP 服务，提供专业级 Rust 开发体验
-- - 核心功能：
--   1. 语法增强：完整支持 Rust 语法特性（生命周期、模式匹配、宏定义）
--   2. 代码辅助：智能补全、类型推断、错误提示（比原生 rust-analyzer 更精准）
--   3. 重构工具：批量重命名、提取函数、模式匹配优化、生命周期自动补全
--   4. 调试集成：与 lldb 配合，支持断点调试、变量查看、表达式求值
--   5. Cargo 集成：快速执行 cargo build/run/test 命令，查看构建结果
-- - 优势：零配置开箱即用，深度适配 Rust 语言特性，性能优秀
Ice.plugins.rustaceanvim = {
    "mrcjkb/rustaceanvim",  -- 插件 GitHub 仓库地址
    ft = "rust",  -- 加载时机：仅打开 .rs 文件时加载（提升启动速度）
    -- 启用条件：仅当 Ice.lsp.rust.enabled 为 true 时启用（通过 Ice.lsp 统一控制）
    enabled = function()
        return Ice.lsp.rust.enabled == true
    end,
}

-- 三、Typst 预览插件：chomosuke/typst-preview.nvim
-- 插件介绍：
-- - 核心定位：Typst 排版工具的「实时预览插件」，解决 Typst 文档编写时无法实时查看效果的痛点
-- - 核心功能：
--   1. 实时预览：启动预览服务器，修改 Typst 文档后自动刷新预览（支持浏览器/本地窗口）
--   2. 双向跳转：预览窗口点击内容，跳转到 Neovim 中对应的代码位置（反向也支持）
--   3. 轻量高效：预览服务器占用资源少，刷新速度快（毫秒级响应）
-- - 适用场景：编写学术论文、报告、简历等 Typst 文档，实时调整格式和内容
Ice.plugins["typst-preview"] = {
    "chomosuke/typst-preview.nvim",  -- 插件 GitHub 仓库地址
    ft = "typst",  -- 加载时机：仅打开 .typ 文件时加载（提升启动速度）
    build = function()
        require("typst-preview").update()  -- 安装/更新时自动更新预览服务器
    end,
    opts = {},  -- 使用默认配置（新手无需修改，进阶可配置预览端口、浏览器等）
    keys = {
        -- 快捷键：Alt+b（<A-b>）触发预览开关（仅在 Typst 文件中生效）
        { "<A-b>", "<Cmd>TypstPreviewToggle<CR>", desc = "Typst：打开/关闭实时预览", ft = "typst", silent = true },
    },
    -- 启用条件：仅当 Ice.lsp.tinymist.enabled 为 true 时启用（与 Typst LSP 联动）
    enabled = function()
        return Ice.lsp.tinymist.enabled == true
    end,
}

-- 四、LSP 服务管理器：mason-org/mason.nvim（核心插件）
-- 插件介绍：
-- - 核心定位：Neovim 生态的「包管理器」，专门管理 LSP 服务、格式化工具、Linter 等开发依赖
-- - 核心功能：
--   1. 自动安装：根据 Ice.lsp 配置，自动下载对应的 LSP 服务（如 pyright）和格式化工具（如 black）
--   2. 版本管理：支持插件更新、回滚、卸载，可视化管理所有依赖
--   3. 兼容性：自动适配不同系统（Windows/Linux/Mac），解决依赖安装路径问题
--   4. 可视化 UI：执行 :Mason 打开管理窗口，直观查看所有依赖的安装状态
-- - 依赖：nvim-lspconfig（LSP 基础配置）、mason-lspconfig.nvim（Mason 与 LSP 配置的桥梁）
Ice.plugins.mason = {
    "mason-org/mason.nvim",  -- 插件 GitHub 仓库地址
    dependencies = {
        "neovim/nvim-lspconfig",  -- Neovim 官方 LSP 基础配置库
        "mason-org/mason-lspconfig.nvim",  -- 连接 Mason 和 nvim-lspconfig，自动关联 LSP 服务
    },
    event = "User IceLoad",  -- 加载时机：IceNvim 初始化完成后加载（确保依赖顺序）
    cmd = "Mason",  -- 命令触发加载：执行 :Mason 命令时也会加载
    opts = {
        ui = {
            icons = {
                package_installed = symbols.Affirmative,  -- 已安装插件图标（复用 Ice.symbols 中的 ✓）
                package_pending = symbols.Pending,        -- 安装中插件图标（复用 Ice.symbols 中的 ➜）
                package_uninstalled = symbols.Negative,   -- 未安装插件图标（复用 Ice.symbols 中的 ✗）
            },
        },
    },
    -- 核心配置函数：Mason 初始化、依赖安装、LSP 配置加载（核心逻辑）
    config = function(_, opts)
        -- 1. 初始化 Mason 插件（应用上面的 UI 配置）
        require("mason").setup(opts)

        -- 2. 获取 Mason 插件注册表（管理所有可安装的依赖）
        local registry = require "mason-registry"

        -- 3. 刷新注册表（首次启动时若为空，刷新获取最新依赖列表）
        local package_list = registry.get_all_package_names()
        if #package_list == 0 then
            registry.refresh()
        end

        -- 4. 定义依赖安装函数：检查依赖是否已安装，未安装则自动安装
        local function install(package)
            local s, p = pcall(registry.get_package, package)  -- 尝试获取依赖信息
            if s and not p:is_installed() then  -- 若依赖存在且未安装
                p:install()  -- 自动安装
            end
        end

        -- 5. 获取 Mason 与 LSP 服务的映射关系（如 "pyright" 对应 LSP 服务名 "pyright"）
        local mason_lspconfig_mapping = require("mason-lspconfig").get_mappings().package_to_lspconfig

        -- 6. 获取已安装的依赖列表
        local installed_packages = registry.get_installed_package_names()

        -- 7. 遍历 Ice.lsp 配置，自动安装 LSP 服务和格式化工具
        for lsp, config in pairs(Ice.lsp) do
            -- 若当前 LSP 服务被禁用（enabled=false），跳过
            if not config.enabled then
                goto continue
            end

            local formatter = config.formatter  -- 获取该语言的格式化工具（如 "black"）
            install(lsp)         -- 安装 LSP 服务（如 "pyright"）
            install(formatter)   -- 安装格式化工具（如 "black"）

            -- 若 LSP 服务未安装完成，跳过后续配置
            if not vim.tbl_contains(installed_packages, lsp) then
                goto continue
            end

            -- 将 Mason 依赖名转换为 LSP 服务名（确保配置匹配）
            lsp = mason_lspconfig_mapping[lsp]
            -- 若 LSP 服务不由插件管理（managed_by_plugin=false）且存在配置，初始化 LSP
            if not config.managed_by_plugin and vim.lsp.config[lsp] ~= nil then
                local setup = config.setup  -- 获取该 LSP 的个性化配置
                -- 处理配置格式：若 setup 是函数，执行后获取配置；若为 nil，初始化为空表
                if type(setup) == "function" then
                    setup = setup()
                elseif setup == nil then
                    setup = {}
                end

                -- 集成 blink-cmp 补全能力：为 LSP 服务添加补全相关配置
                local blink_capabilities = require("blink.cmp").get_lsp_capabilities()
                blink_capabilities.textDocument.foldingRange = {  -- 支持代码折叠
                    dynamicRegistration = false,
                    lineFoldingOnly = true,
                }
                -- 合并配置：将补全能力、个性化配置合并（个性化配置优先级更高）
                setup = vim.tbl_deep_extend("force", setup, {
                    capabilities = blink_capabilities,
                })

                -- 应用 LSP 配置（启动 LSP 服务）
                vim.lsp.config(lsp, setup)
            end
            ::continue::  -- 循环跳转标记（跳过已禁用/未安装的 LSP）
        end

        -- 8. 全局诊断配置（统一 LSP 诊断信息的显示样式）
        vim.diagnostic.config {
            update_in_insert = true,  -- 插入模式下实时更新诊断（边打字边提示错误）
            severity_sort = true,     -- 按严重程度排序诊断（错误 > 警告 > 提示 > 信息），LSPsaga 依赖此配置
            virtual_text = true,      -- 行尾显示诊断文本提示（如 "未定义变量"）
            signs = {  -- 左侧符号列显示诊断图标（复用 Ice.symbols）
                text = {
                    [vim.diagnostic.severity.ERROR] = symbols.Error,  -- 错误图标（如 ❌）
                    [vim.diagnostic.severity.WARN] = symbols.Warn,    -- 警告图标（如 ⚠️）
                    [vim.diagnostic.severity.HINT] = symbols.Hint,    -- 提示图标（如 💡）
                    [vim.diagnostic.severity.INFO] = symbols.Info,   -- 信息图标（如 ℹ️）
                },
                numhl = {  -- 行号列高亮（使用 Neovim 内置高亮组）
                    [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
                    [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
                    [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
                    [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
                },
            },
        }

        -- 9. 启用内嵌提示（inlay hints）：显示变量类型、函数返回值类型（如 TypeScript 中 let x: number）
        vim.lsp.inlay_hint.enable()

        -- 10. 定义 LSP 启动函数：根据当前文件类型启动对应的 LSP 服务
        local function lsp_start()
            -- 原作者备注：不直接调用 :LspStart 命令，因为若没有匹配的 LSP 服务会报错
            -- 解决方案：先检查当前文件类型是否有对应的 LSP 服务，有则启动
            local servers = {}
            local filetype = vim.bo.filetype  -- 获取当前文件类型（如 "python"）
            ---@diagnostic disable-next-line: invisible
            for name, _ in pairs(vim.lsp.config._configs) do  -- 遍历所有已配置的 LSP 服务
                local filetypes = vim.lsp.config[name].filetypes  -- 获取该 LSP 支持的文件类型
                if filetypes and vim.tbl_contains(filetypes, filetype) then  -- 若支持当前文件类型
                    table.insert(servers, name)  -- 添加到要启动的服务列表
                end
            end

            if #servers > 0 then
                vim.lsp.enable(servers)  -- 启动所有匹配的 LSP 服务
            end
        end

        -- 11. 创建 LSP 自动命令组（统一管理 LSP 相关自动命令）
        local augroup = vim.api.nvim_create_augroup("IceLsp", { clear = true })
        -- 自动命令 1：打开文件时（FileType 事件）启动对应的 LSP 服务
        vim.api.nvim_create_autocmd("FileType", {
            group = augroup,
            callback = lsp_start,
        })

        -- 自动命令 2：LSP 服务附加到缓冲区时（LspAttach 事件）执行自定义逻辑
        vim.api.nvim_create_autocmd("LspAttach", {
            group = augroup,
            callback = function(args)
                -- 获取当前附加的 LSP 客户端
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                -- 若客户端不存在或为 null-ls（格式化工具），跳过
                if not client or client.name == "null-ls" then
                    return
                end
                -- 获取 LSP 服务名与 Mason 依赖名的映射关系
                local lspconfig_mapping = require("mason-lspconfig").get_mappings().lspconfig_to_package

                -- 执行该 LSP 服务的 on_attach 回调（个性化配置，如禁用某些功能）
                local cfg = Ice.lsp[lspconfig_mapping[client.name]]
                if type(cfg) == "table" and type(cfg.setup) == "table" and type(cfg.setup.on_attach) == "function" then
                    Ice.aaa = cfg.setup.on_attach  -- 临时存储回调（原作者保留逻辑）
                    cfg.setup.on_attach(client, args.buf)  -- 执行回调，传入客户端和缓冲区 ID
                end
            end,
        })

        -- 12. 初始启动 LSP 服务（打开 Neovim 时若有已打开的文件，自动启动对应 LSP）
        lsp_start()
    end,
}