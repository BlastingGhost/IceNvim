-- ==============================================
-- LSP 语言服务器配置表：为每种编程语言指定对应的 LSP 服务、格式化工具和个性化规则
-- 核心定位：IceNvim LSP 功能的「语言适配中心」，决定不同语言的 LSP 服务启动、功能开关和行为
-- 配置逻辑：
-- 1. 键名：LSP 服务名称（如 pyright、clangd，与 mason.nvim 中的服务名一致）
-- 2. 配置字段：
--    - formatter：指定该语言的格式化工具（对应 null-ls 中的工具名，如 "black" 对应 Python 格式化）
--    - setup：LSP 服务的个性化配置（如语法检查规则、工作目录、插件集成）
--    - managed_by_plugin：是否由其他插件管理（如 rust-analyzer 由 rust-tools.nvim 管理，无需手动配置）
--    - enabled：是否启用该 LSP 服务（默认 true，可设为 false 禁用）
-- 新手说明：以下逐节解释每种语言的 LSP 配置，包含服务功能、适用场景和注意点，可直接粘贴使用
-- 参考文档：https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md（官方 LSP 配置指南）
-- ==============================================

local lsp = {}

-- For instructions on configuration, see official wiki:
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
lsp = {
    -- 1. Bash 语言 LSP 配置（对应文件类型：.sh、.bash）
    ["bash-language-server"] = {
        formatter = "shfmt",  -- 格式化工具：shfmt（Bash 官方推荐格式化工具，统一缩进、行宽）
        -- 服务功能：
        -- - 语法高亮、语法检查（如未闭合括号、无效命令提示）
        -- - 自动补全（命令名、变量名、函数名）
        -- - 跳转定义（函数、变量的定义位置）
        -- 使用场景：编写 Shell 脚本（如自动化部署脚本、启动脚本）
    },

    -- 2. C/C++ 语言 LSP 配置（对应文件类型：.c、.cpp、.h、.hpp）
    clangd = {
        -- 未指定 formatter：可在 lsp/format.lua 中补充，或使用 clangd 内置格式化
        -- 服务功能（clangd：C/C++ 官方 LSP 服务，功能强大且稳定）：
        -- - 语法检查（支持 C11/C++17 等标准，检测语法错误、类型不匹配）
        -- - 代码补全（变量、函数、宏定义、头文件内容）
        -- - 跳转定义/引用（跨文件跳转，支持大型项目）
        -- - 重构功能（重命名变量、提取函数）
        -- 适用场景：C/C++ 项目开发（如嵌入式、桌面应用、系统编程）
        -- 注意点：需安装 LLVM 工具链（clangd 依赖），可通过 :Mason 安装 clangd 自动关联
    },

    -- 3. CSS 系列语言 LSP 配置（对应文件类型：.css、.less、.scss）
    ["css-lsp"] = {
        formatter = "prettier",  -- 格式化工具：prettier（前端通用格式化，统一缩进、属性顺序）
        setup = {
            settings = {
                css = {
                    validate = true,  -- 启用 CSS 语法验证（如无效属性、错误值提示）
                    lint = {
                        unknownAtRules = "ignore",  -- 忽略未知的 CSS 规则（如自定义 CSS 变量、框架专属规则）
                    },
                },
                less = {  -- Less 预处理器配置（与 CSS 规则一致）
                    validate = true,
                    lint = {
                        unknownAtRules = "ignore",
                    },
                },
                scss = {  -- SCSS 预处理器配置（与 CSS 规则一致）
                    validate = true,
                    lint = {
                        unknownAtRules = "ignore",
                    },
                },
            },
        },
        -- 服务功能（css-lsp：前端 CSS 专用 LSP 服务）：
        -- - 语法高亮、属性补全（支持 CSS3+ 所有属性）
        -- - 颜色预览、单位提示（如 px、rem 转换建议）
        -- - 跳转定义（导入的 CSS 文件、变量定义）
        -- 适用场景：前端样式开发（网页、Vue/React 组件样式）
    },

    -- 4. Emmet 语法 LSP 配置（对应文件类型：HTML、JSX、TSX、CSS 等）
    ["emmet-ls"] = {
        setup = {
            filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less" },
            -- 配置说明：指定支持的文件类型（前端常用模板/样式文件）
        },
        -- 服务功能（emmet-ls：前端 Emmet 语法增强工具，快速编写 HTML/CSS）：
        -- - 缩写展开（如输入 "div.container" 展开为 <div class="container"></div>）
        -- - 嵌套语法（如输入 "ul>li*3" 展开为 3 个列表项）
        -- - CSS 缩写（如输入 "w100" 展开为 width: 100px;）
        -- 适用场景：前端快速编写 HTML 结构和 CSS 样式，大幅提升编码速度
    },

    -- 5. Flutter/Dart 语言 LSP 配置（对应文件类型：.dart）
    flutter = {
        managed_by_plugin = true,  -- 由 flutter-tools.nvim 插件管理（无需手动配置 LSP 服务）
        -- 服务功能（基于 dartls，Flutter 官方推荐 LSP）：
        -- - Dart 语法检查、代码补全（支持 Flutter 组件、API）
        -- - 热重载集成、Widget 预览
        -- - 跳转定义、重构（重命名、提取组件）
        -- 适用场景：Flutter 跨平台应用开发（移动端、桌面端、Web 端）
        -- 注意点：需安装 Flutter SDK 并配置环境变量，插件会自动关联 dartls 服务
    },

    -- 6. Go 语言 LSP 配置（对应文件类型：.go）
    gopls = {
        formatter = "gofumpt",  -- 格式化工具：gofumpt（Go 官方推荐，比 gofmt 更严格的代码风格）
        setup = {
            settings = {
                gopls = {
                    analyses = {
                        unusedparams = true,  -- 启用未使用参数检查（提示代码冗余）
                    },
                },
            },
        },
        -- 服务功能（gopls：Go 官方 LSP 服务，完全遵循 Go 代码规范）：
        -- - 语法检查、代码补全（变量、函数、标准库 API）
        -- - 模块依赖管理、导入优化
        -- - 重构功能（重命名、提取函数、接口实现检查）
        -- 适用场景：Go 语言开发（后端服务、云原生、工具开发）
    },

    -- 7. HTML 语言 LSP 配置（对应文件类型：.html）
    ["html-lsp"] = {
        formatter = "prettier",  -- 格式化工具：prettier（统一 HTML 缩进、标签顺序）
        -- 服务功能（html-lsp：前端 HTML 专用 LSP 服务）：
        -- - 语法检查（未闭合标签、无效属性提示）
        -- - 标签/属性补全（支持 HTML5 所有标签和属性）
        -- - 跳转定义（导入的 CSS/JS 文件、锚点链接）
        -- 适用场景：前端 HTML 页面开发、Vue/React 组件模板
    },

    -- 8. JSON 语言 LSP 配置（对应文件类型：.json、.jsonc）
    ["json-lsp"] = {
        formatter = "prettier",  -- 格式化工具：prettier（统一 JSON 缩进、键值对顺序）
        -- 服务功能（json-lsp：JSON 专用 LSP 服务）：
        -- - 语法检查（无效 JSON 格式、多余逗号提示）
        -- - 键名补全、值类型提示（如布尔值、数字、字符串）
        -- - JSON Schema 验证（支持自定义 Schema，如 package.json 语法检查）
        -- 适用场景：配置文件编写（如 package.json、tsconfig.json、项目配置文件）
    },

    -- 9. Lua 语言 LSP 配置（对应文件类型：.lua，含 Neovim 配置文件）
    ["lua-language-server"] = {
        formatter = "stylua",  -- 格式化工具：stylua（Lua 官方推荐，适配 Neovim 配置文件）
        setup = {
            settings = {
                Lua = {
                    runtime = {
                        version = "LuaJIT",  -- 指定 Lua 运行时（Neovim 内置 LuaJIT）
                        path = (function()
                            -- 配置 Lua 模块搜索路径（确保 require 能找到自定义模块）
                            local runtime_path = vim.split(package.path, ";")
                            table.insert(runtime_path, "lua/?.lua")
                            table.insert(runtime_path, "lua/?/init.lua")
                            return runtime_path
                        end)(),
                    },
                    diagnostics = {
                        globals = { "vim" },  -- 声明全局变量 "vim"（Neovim API，避免语法检查报错）
                    },
                    hint = {
                        enable = true,  -- 启用内嵌提示（显示变量类型、函数返回值类型）
                    },
                    workspace = {
                        library = {
                            vim.env.VIMRUNTIME,  -- 加入 Neovim 运行时库（支持 Neovim API 补全）
                            "${3rd}/luv/library",  -- 加入 luv 库（Lua 异步 I/O 库）
                        },
                        checkThirdParty = false,  -- 禁用第三方库检查（避免提示冗余）
                    },
                    telemetry = {
                        enable = false,  -- 禁用遥测（不发送使用数据）
                    },
                },
            },
        },
        enabled = true,  -- 启用 Lua LSP 服务（编辑 Neovim 配置文件必备）
        -- 服务功能（lua-language-server：Lua 专用 LSP 服务，原名 sumneko_lua）：
        -- - 语法检查、代码补全（支持 Neovim API、自定义模块）
        -- - 内嵌类型提示、函数文档
        -- - 重构功能（重命名、提取函数、代码折叠）
        -- 适用场景：编辑 Lua 脚本、Neovim 配置文件（如 init.lua、插件配置）
    },

    -- 10. C# 语言 LSP 配置（对应文件类型：.cs）
    omnisharp = {
        formatter = "csharpier",  -- 格式化工具：csharpier（C# 代码格式化工具，遵循 .NET 规范）
        setup = {
            cmd = {
                "dotnet",  -- 启动命令：通过 dotnet 运行 Omnisharp 服务
                vim.fs.joinpath(vim.fn.stdpath "data", "mason/packages/omnisharp/libexec/Omnisharp.dll"),
                -- Omnisharp 服务路径（Mason 安装后自动生成）
            },
            on_attach = function(client, _)
                -- 禁用语义令牌提供（避免与其他插件冲突，如语法高亮）
                client.server_capabilities.semanticTokensProvider = nil
            end,
        },
        -- 服务功能（omnisharp：C# 官方 LSP 服务，支持 .NET 生态）：
        -- - 语法检查、代码补全（支持 C# 10+ 特性、.NET 库 API）
        -- - 跳转定义、重构（重命名、提取接口）
        -- - 调试集成（与 nvim-dap 配合实现断点调试）
        -- 适用场景：C# 开发（.NET Core、Unity 游戏、桌面应用）
        -- 注意点：需安装 .NET SDK，确保 dotnet 命令可正常执行
    },

    -- 11. Python 语言 LSP 配置（对应文件类型：.py）
    pyright = {
        formatter = "black",  -- 格式化工具：black（Python 官方推荐，强制 PEP8 规范）
        -- 服务功能（pyright：微软开发的 Python LSP 服务，功能全面）：
        -- - 语法检查（语法错误、类型不匹配、未定义变量）
        -- - 代码补全（变量、函数、标准库/第三方库 API）
        -- - 类型推断、导入优化（自动导入缺失包、删除无用导入）
        -- - 跳转定义/引用（跨文件支持）
        -- 适用场景：Python 开发（后端服务、数据分析、机器学习）
        -- 注意点：配合 black 格式化工具，需提前安装（pip install black）
    },

    -- 12. Rust 语言 LSP 配置（对应文件类型：.rs）
    rust = {
        managed_by_plugin = true,  -- 由 rust-tools.nvim 插件管理（提供更强大的 Rust 开发功能）
        -- 服务功能（基于 rust-analyzer，Rust 官方 LSP 服务）：
        -- - 语法检查、代码补全（支持 Rust 所有特性、标准库）
        -- - 类型推断、生命周期检查（Rust 核心特性支持）
        -- - 重构功能（重命名、提取函数、模式匹配优化）
        -- - 调试集成（与 rust-gdb 配合实现断点调试）
        -- 适用场景：Rust 开发（系统编程、后端服务、WebAssembly）
        -- 注意点：需安装 Rust 工具链（rustup），插件会自动关联 rust-analyzer
    },

    -- 13. Typst 语言 LSP 配置（对应文件类型：.typ，排版工具）
    tinymist = {
        -- 未指定 formatter：tinymist 内置格式化功能（无需额外工具）
        setup = {
            settings = {
                formatterMode = "typstyle",  -- 格式化模式：typstyle（Typst 官方风格）
                formatterPrintWidth = 120,  -- 行宽限制：120 列
                formatterProseWrap = true,  --  prose 模式自动换行（优化文档阅读体验）
            },
        },
        -- 服务功能（tinymist：Typst 专用 LSP 服务，排版工具必备）：
        -- - 语法检查、代码补全（Typst 标签、函数、变量）
        -- - 实时预览集成、公式补全
        -- - 跳转定义（引用的模板、变量）
        -- 适用场景：Typst 文档排版（学术论文、报告、简历）
    },

    -- 14. TypeScript/JavaScript 语言 LSP 配置（对应文件类型：.ts、.tsx、.js、.jsx）
    ["typescript-language-server"] = {
        formatter = "prettier",  -- 格式化工具：prettier（前端通用，统一 TS/JS 代码风格）
        setup = {
            root_dir = function(_, on_dir)
                -- 配置项目根目录（使用 core.utils.get_root()，确保找到项目配置文件如 tsconfig.json）
                on_dir(require("core.utils").get_root())
            end,
            flags = lsp.flags,  -- 继承全局 LSP 标志（如超时时间、并发请求数）
            on_attach = function(client)
                -- 冲突处理：若已启动 denols（Deno 专用 LSP），则停止当前 tsserver（避免冲突）
                if #vim.lsp.get_clients { name = "denols" } > 0 then
                    client.stop()
                end
            end,
        },
        -- 服务功能（typescript-language-server：TS/JS 官方 LSP 服务，简称 tsserver）：
        -- - 语法检查、代码补全（支持 TS 类型、JS 特性、第三方库 API）
        -- - 类型推断、接口检查（TS 核心功能）
        -- - 重构功能（重命名、提取组件、导入优化）
        -- 适用场景：前端开发（React、Vue、Node.js 后端）、TS/JS 项目
        -- 注意点：与 Deno 项目冲突，需确保仅启动一个 LSP 服务（tsserver 或 denols）
    },
}

-- 将 LSP 配置赋值给 Ice.lsp，供其他模块（如 lsp.lsp.lua、null-ls）调用
Ice.lsp = lsp

-- ==============================================
-- 核心配置字段&语言服务汇总（新手快速查阅）
-- ==============================================
-- 一、核心配置字段说明
-- | 字段名              | 作用                                  | 示例值                |
-- |---------------------|---------------------------------------|-----------------------|
-- | formatter           | 指定格式化工具（对应 null-ls 工具名）  | "black"、"prettier"   |
-- | setup               | LSP 服务个性化配置（语法、工作目录等） | settings、cmd、on_attach |
-- | managed_by_plugin   | 是否由其他插件管理（无需手动配置）     | true（Rust/Flutter）  |
-- | enabled             | 是否启用该 LSP 服务