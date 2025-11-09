-- ==============================================
-- blink-cmp 插件配置：高性能代码补全框架（替代传统 nvim-cmp）
-- 核心定位：Neovim 代码补全的「核心引擎」，提供快速、智能、可定制的补全体验
-- 插件介绍（blink.cmp）：
-- - 优势：比 nvim-cmp 启动更快、响应更流畅（基于 Lua 原生实现，减少冗余计算）
-- - 核心特性：支持 LSP 补全、路径补全、代码片段补全、缓冲区补全，且支持命令行补全
-- - 兼容性：兼容大多数 nvim-cmp 的插件生态（如 friendly-snippets 代码片段库）
-- 配置逻辑：通过 opts 表全面定制补全的外观、行为、快捷键和数据源，适配不同场景
-- 新手说明：以下逐节解释配置含义，包含功能作用、使用场景和注意点，新手可直接复用
-- ==============================================

Ice.plugins["blink-cmp"] = {
    -- 插件基础信息：GitHub 仓库地址（作者 saghen，仓库 blink.cmp）
    "saghen/blink.cmp",
    -- 依赖插件：补全功能的「辅助组件」
    dependencies = {
        "rafamadriz/friendly-snippets",  -- 代码片段库（提供海量预设片段，如 for 循环、函数模板）
    },
    -- 插件加载时机：按需加载，提升 Neovim 启动速度
    event = { 
        "InsertEnter",  -- 进入插入模式时加载（编辑代码时触发）
        "CmdlineEnter", -- 进入命令行模式时加载（输入 : 或 / 时触发）
        "User IceLoad"  -- IceNvim 自定义事件（确保配置加载顺序）
    },
    version = "*",  -- 使用最新版本（可改为具体版本号锁定，如 "v0.1.0"，避免更新异常）
    -- 核心配置选项（opts 是 blink-cmp 的主要配置入口）
    opts = {
        -- 一、外观配置：控制补全菜单的显示样式
        appearance = {
            -- 补全类型图标：使用 Ice.symbols 中定义的统一图标（如函数用 🔧、变量用 🔄）
            -- 作用：补全列表中显示类型图标，快速区分补全项类型（如 LSP 函数、路径、片段）
            kind_icons = Ice.symbols,
        },

        -- 二、命令行补全配置：定制 : / / ? 等命令行模式的补全行为
        cmdline = {
            completion = {
                menu = {
                    auto_show = true,  -- 命令行输入时自动显示补全菜单（无需手动触发）
                },
            },
            -- 命令行模式补全快捷键
            keymap = {
                preset = "none",  -- 不使用默认快捷键预设，完全自定义
                ["<Tab>"] = { "accept" },  -- Tab 键：确认选中的补全项
                ["<C-k>"] = { "select_prev", "fallback" },  -- Ctrl+k：选中上一个补全项，无补全时执行默认行为
                ["<C-j>"] = { "select_next", "fallback" },  -- Ctrl+j：选中下一个补全项，无补全时执行默认行为
            },
        },

        -- 三、补全核心行为配置：控制补全的触发、选择、文档显示等逻辑
        completion = {
            accept = {
                -- 自动添加括号：补全函数/方法时，自动在括号内留空（如输入 print 补全为 print()，光标在括号中）
                auto_brackets = { enabled = true },
            },
            documentation = {
                auto_show = true,  -- 选中补全项时自动显示文档（如函数参数、返回值说明）
                auto_show_delay_ms = 200,  -- 文档显示延迟（200 毫秒，避免频繁切换导致卡顿）
            },
            ghost_text = {
                enabled = true,  -- 启用幽灵文本（补全建议实时显示在光标后，不占用输入位置）
                show_without_selection = true,  -- 未选中补全项时也显示幽灵文本
                -- 作用：输入时实时预览补全结果，减少手动选择操作（如输入 "pri" 时，光标后显示 "nt()"）
            },
            list = {
                selection = {
                    preselect = false,  -- 不自动预选第一个补全项（避免误选，手动选择更精准）
                    auto_insert = true, -- 选中补全项后自动插入到代码中
                },
            },
            menu = {
                draw = {
                    -- 补全菜单列配置：控制菜单显示的内容和布局
                    columns = {
                        { "label", "label_description", gap = 1 },  -- 第一列：补全项名称 + 描述（间距 1 字符）
                        { "kind_icon" },  -- 第二列：补全类型图标（如函数、变量图标）
                    },
                    treesitter = { "lsp" },  -- 使用 LSP 提供的语法信息优化补全显示（更精准的类型识别）
                },
            },
            trigger = {
                -- 退格时也显示补全：在单词中退格时，重新触发补全（如输入 "prnit" 退格为 "pri" 时，重新显示补全）
                show_on_backspace_in_keyword = true,
            },
        },

        -- 四、插件启用条件：控制哪些场景下启用补全（避免无效场景占用资源）
        enabled = function()
            -- 1. 排除特定文件类型：在 grug-far（搜索替换工具）和 TelescopePrompt（搜索窗口）中禁用补全
            local filetype_is_allowed = not vim.tbl_contains({ "grug-far", "TelescopePrompt" }, vim.bo.filetype)

            -- 2. 限制文件大小：超过指定大小（默认 1MB）的文件禁用补全（避免大文件卡顿）
            local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(0))
            local filesize_is_allowed = true
            if ok and stats then
                ---@diagnostic disable-next-line: need-check-nil
                filesize_is_allowed = stats.size < (Ice.max_file_size or (1024 * 1024))  -- 1024*1024 = 1MB
            end

            -- 同时满足「文件类型允许」和「文件大小允许」才启用补全
            return filetype_is_allowed and filesize_is_allowed
        end,

        -- 五、插入模式补全快捷键：核心操作入口，适配日常编码习惯
        keymap = {
            preset = "none",  -- 不使用默认快捷键预设，完全自定义（避免与其他配置冲突）
            ["<Tab>"] = {  -- Tab 键：核心确认/切换快捷键
                function(cmp)
                    -- 只有补全菜单显示时，才执行「选中并确认」操作
                    if not cmp.is_menu_visible() then
                        return
                    end
                    -- 选中当前高亮的补全项，并自动插入
                    return cmp.select_and_accept {}
                end,
                "snippet_forward",  -- 额外功能：代码片段向前跳转（如片段中有 $1 $2 光标位置时）
                "fallback",  -- 无补全菜单时，执行 Tab 键默认行为（如缩进）
            },
            ["<S-Tab>"] = { "snippet_backward", "fallback" },  -- Shift+Tab：代码片段向后跳转，无片段时执行默认行为
            ["<C-k>"] = { "select_prev", "fallback" },  -- Ctrl+k：选中上一个补全项，无补全时执行默认行为
            ["<C-j>"] = { "select_next", "fallback" },  -- Ctrl+j：选中下一个补全项，无补全时执行默认行为
            ["<A-c>"] = {  -- Alt+c：显示/隐藏补全菜单（自定义触发快捷键）
                -- 原作者警告：此处切勿添加 "fallback"！否则会导致输入 "c" 时自动插入额外字符
                function(cmp)
                    if cmp.is_menu_visible() then
                        cmp.cancel()  -- 补全菜单已显示时，关闭菜单
                    else
                        cmp.show()   -- 补全菜单未显示时，手动触发显示
                    end
                end,
            },
            ["<C-d>"] = { "scroll_documentation_down", "fallback" },  -- Ctrl+d：向下滚动补全项的文档说明
            ["<C-u>"] = { "scroll_documentation_up", "fallback" },    -- Ctrl+u：向上滚动补全项的文档说明
        },

        -- 六、补全数据源配置：控制补全内容的来源（决定补全能提供哪些候选）
        sources = {
            -- 默认数据源：根据当前场景自动选择补全来源
            default = function()
                -- 获取当前命令行类型（/ 是搜索模式，: 是命令模式，@ 是寄存器模式）
                local cmdwin_type = vim.fn.getcmdwintype()
                
                if cmdwin_type == "/" or cmdwin_type == "?" then
                    -- 搜索模式（/ 或 ?）：仅使用缓冲区补全（补全当前文件中已出现的文本）
                    return { "buffer" }
                end
                if cmdwin_type == ":" or cmdwin_type == "@" then
                    -- 命令模式（: 或 @）：仅使用命令行补全（补全 Neovim 命令、文件路径等）
                    return { "cmdline" }
                end

                -- 插入模式（编辑代码）：使用全套补全来源（优先级：LSP > 路径 > 片段 > 缓冲区）
                local source = { "lsp", "path", "snippets", "buffer" }
                return source
            end,
            -- 数据源提供者配置：为每个数据源设置额外选项
            providers = {
                snippets = {  -- 代码片段数据源配置（依赖 friendly-snippets）
                    opts = {
                        -- 自定义代码片段搜索路径：优先加载用户自定义片段（custom/snippets 目录）
                        -- 作用：支持用户添加自己的代码片段（如项目专属模板、常用函数）
                        search_paths = { vim.fs.joinpath(vim.fn.stdpath "config", "lua/custom/snippets") },
                    },
                },
            },
        },
    },
}

-- ==============================================
-- 插件核心功能&使用场景汇总（新手快速查阅）
-- ==============================================
-- | 功能类型                | 操作方式                                  | 配置关联                  | 适用场景                                  |
-- |-------------------------|-------------------------------------------|---------------------------|-------------------------------------------|
-- | 代码补全触发            | 打字自动触发 / Alt+c 手动触发             | completion.trigger        | 忘记函数名/变量名时，快速获取候选          |
-- | 补全项选择              | Ctrl+j（下一个）/ Ctrl+k（上一个）         | keymap["<C-j>"]/<C-k>     | 补全列表中切换候选，精准选择需要的内容      |
-- | 补全确认                | Tab 键                                    | keymap["<Tab>"]           | 选中补全项后，快速插入到代码中             |
-- | 函数文档查看            | 选中补全项自动显示（200ms 延迟）          | completion.documentation  | 不清楚函数参数时，查看文档说明              |
-- | 代码片段插入            | 输入片段前缀（如 fori）+ Tab              | sources.providers.snippets | 快速插入循环、函数等模板，减少重复编码      |
-- | 代码片段跳转            | Tab（向前）/ Shift+Tab（向后）             | keymap["<Tab>"]/<S-Tab>   | 片段中有多个光标位置（$1 $2）时，快速切换  |
-- | 命令行补全              | 输入 : / 后自动触发                       | cmdline.completion        | 输入命令/搜索时，补全历史命令/文件内容      |
-- | 自定义片段加载          | 在 custom/snippets 目录添加 .lua 片段文件  | sources.providers.snippets | 添加项目专属模板（如接口请求模板、类模板）  |

-- ==============================================
-- 新手使用注意点（避坑指南）
-- ==============================================
-- 1. 依赖安装：首次使用需确保依赖插件已安装（执行 :Lazy 查看 friendly-snippets 是否存在，未安装则执行 :Lazy install）
-- 2. 图标显示：若补全项图标乱码，检查 Ice.symbols 是否配置正确，或切换为 FiraCode 兼容版图标（参考 symbols.lua 配置）
-- 3. 性能优化：大文件（超过 1MB）会自动禁用补全，避免卡顿（可通过 Ice.max_file_size 调整阈值）
-- 4. 快捷键冲突：若 Tab 键/Alt+c 等快捷键无效，检查其他插件是否占用该键（如终端、编辑器快捷键）
-- 5. 片段自定义：在 lua/custom/snippets 目录下创建 .lua 文件，可添加自定义片段（格式参考 friendly-snippets）
-- 6. 版本问题：若更新后功能异常，可将 version 改为具体版本号（如 "v0.2.0"），锁定稳定版本
-- 7. 补全失效排查：
--    - 执行 :LspInfo 检查 LSP 服务是否正常运行（LSP 补全依赖语言服务器）
--    - 执行 :BlinkCmpInfo 查看 blink-cmp 状态（是否加载成功、数据源是否启用）
--    - 检查当前文件类型是否支持补全（如 .txt 文件仅支持缓冲区补全，无 LSP 补全）