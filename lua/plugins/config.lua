-- ==============================================
-- 插件独立配置文件：统一管理所有 Neovim 插件的加载规则、功能配置和快捷键
-- 核心逻辑：
-- 1. 用 config 表存储所有插件配置，最终赋值给 Ice.plugins 生效
-- 2. 依赖 Ice 全局配置（如 symbols 图标、config_root 配置路径）
-- 3. 通过事件触发（如 IceLoad）控制插件加载时机，优化启动速度
-- 新手注意：所有注释不影响代码执行，可直接粘贴，后续每插件都有详细功能说明
-- ==============================================

---@diagnostic disable: need-check-nil  -- 禁用 "需要检查空值" 的诊断提示（原作者注释保留）
local config = {}  -- 所有插件配置的总容器
local symbols = Ice.symbols  -- 引入 Ice 全局图标配置（统一 UI 风格）
local config_root = vim.fn.stdpath "config"  -- 获取 Neovim 配置文件根路径（如 ~/.config/nvim）

-- ==============================================
-- 关键事件：IceLoad（插件统一加载触发事件）
-- 作用：确保插件在 "主题加载完成后" 才加载，避免 UI 冲突
-- 触发逻辑：
-- 1. 主题加载完成后（IceAfter colorscheme 事件）执行回调
-- 2. 检查当前缓冲区是否为 "非仪表盘" 且 "非空文件"，满足则直接触发 IceLoad
-- 3. 不满足则监听 BufEnter 事件，直到打开有效文件后触发 IceLoad 并取消监听
-- ==============================================
vim.api.nvim_create_autocmd("User", {
    pattern = "IceAfter colorscheme",  -- 触发时机：Ice 主题加载完成后
    callback = function()
        -- 条件判断：是否应该触发 IceLoad（排除仪表盘和空文件）
        local function should_trigger()
            return vim.bo.filetype ~= "dashboard" and vim.api.nvim_buf_get_name(0) ~= ""
        end

        -- 触发 IceLoad 事件（让依赖该事件的插件开始加载）
        local function trigger()
            vim.api.nvim_exec_autocmds("User", { pattern = "IceLoad" })
        end

        -- 满足条件则立即触发
        if should_trigger() then
            trigger()
            return
        end

        -- 不满足条件则监听 BufEnter 事件（后续打开文件时触发）
        local ice_load
        ice_load = vim.api.nvim_create_autocmd("BufEnter", {
            callback = function()
                if should_trigger() then
                    trigger()  -- 触发 IceLoad
                    vim.api.nvim_del_autocmd(ice_load)  -- 触发后取消监听，避免重复执行
                end
            end,
        })
    end,
})

-- ==============================================
-- 插件 1：avante.nvim（AI 辅助编程插件，模拟 Cursor AI 体验）
-- 功能概述：
-- 1. 基于 Copilot 等 AI 提供商，提供代码生成、解释、重构等功能
-- 2. 分窗口布局：选中代码区、输入区、结果区、文件选择区、TODO 区
-- 3. 支持 Markdown 渲染（依赖 render-markdown.nvim）
-- 注意：默认 enabled = false，需要手动开启（修改为 true 后执行 :Lazy install）
-- ==============================================

-- 辅助函数：快速切换到 Avante 的指定窗口（如输入区、结果区）
local function avante(win)
    return function()
        local candidate = require("avante").current.sidebar.containers[win]  -- 获取指定窗口容器
        if win then
            local win_id = candidate.winid  -- 获取窗口 ID
            vim.api.nvim_set_current_win(win_id)  -- 切换到该窗口
        end
    end
end

config.avante = {
    "yetone/avante.nvim",  -- 插件 GitHub 地址
    enabled = false,  -- 禁用状态（true 启用，false 禁用）
    build = function()  -- 安装/更新时的构建命令（跨平台兼容）
        if require("core.utils").is_windows then  -- Windows 系统
            return "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
        else  -- Linux/Mac 系统
            return "make"
        end
    end,
    event = "User IceLoad",  -- 加载时机：IceLoad 事件触发后（主题加载完成+打开有效文件）
    version = false,  -- 不指定版本（使用最新版）
    opts = {  -- 插件核心配置
        provider = "copilot",  -- 默认 AI 提供商（支持 copilot/openai 等）
        providers = {
            copilot = {
                model = "gpt-4.1",  -- 使用的 AI 模型
                extra_request_body = {
                    temperature = 0.75,  -- 随机性（0-1，越高越随机）
                    max_tokens = 20480,  -- 最大生成 tokens（控制输出长度）
                },
            },
        },
        mappings = {
            confirm = {
                focus_window = "<leader>awf",  -- 聚焦确认窗口的快捷键
            },
        },
        windows = {  -- 窗口样式配置
            width = 40,  -- 侧边栏宽度
            sidebar_header = {
                align = "left",  -- 标题左对齐
                rounded = false,  -- 不使用圆角边框
            },
            input = {
                height = 16,  -- 输入框高度
            },
            ask = {
                start_insert = false,  -- 打开询问窗口时不自动进入插入模式
            },
        },
    },
    dependencies = {  -- 依赖插件（必须先安装这些插件才能正常工作）
        "nvim-lua/plenary.nvim",  -- 基础工具函数库（异步、路径处理等）
        "MunifTanjim/nui.nvim",  -- UI 组件库（弹窗、窗口等）
        "nvim-telescope/telescope.nvim",  -- 模糊查找器（用于文件选择等）
        "nvim-tree/nvim-web-devicons",  -- 文件图标库（美化 UI）
        "zbirenbaum/copilot.lua",  -- Copilot 客户端（AI 功能依赖）
        { "MeanderingProgrammer/render-markdown.nvim", opts = { file_types = { "Avante" } }, ft = { "Avante" } },  -- Markdown 渲染（显示 AI 结果）
    },
    keys = {  -- 快捷键配置（仅在插件启用时生效）
        { "<leader>awc", avante "selected_code", desc = "AI 辅助：聚焦选中代码窗口", silent = true },
        { "<leader>awi", avante "input", desc = "AI 辅助：聚焦输入窗口", silent = true },
        { "<leader>awa", avante "result", desc = "AI 辅助：聚焦结果窗口", silent = true },
        { "<leader>aws", avante "selected_files", desc = "AI 辅助：聚焦选中文件窗口", silent = true },
        { "<leader>awt", avante "todos", desc = "AI 辅助：聚焦 TODO 窗口", silent = true },
    },
}
-- ==============================================
-- 插件 2：bufferline.nvim（标签式缓冲区管理）
-- 功能概述：
-- 1. 顶部显示所有打开的缓冲区（文件），支持鼠标操作和快捷键切换
-- 2. 集成 LSP 诊断提示（显示错误/警告数量）
-- 3. 与 NvimTree 联动（自动留出文件树空间）
-- 核心价值：解决多文件编辑时的缓冲区切换混乱问题
-- ==============================================
config.bufferline = {
    "akinsho/bufferline.nvim",  -- 插件 GitHub 地址
    dependencies = { "nvim-tree/nvim-web-devicons" },  -- 依赖文件图标库（美化标签）
    event = "User IceLoad",  -- 加载时机：IceLoad 事件触发后
    opts = {  -- 插件配置
        options = {
            close_command = ":BufferLineClose %d",  -- 关闭缓冲区的命令（%d 为缓冲区 ID）
            right_mouse_command = ":BufferLineClose %d",  -- 右键点击标签关闭缓冲区
            separator_style = "thin",  -- 标签分隔符样式（thin/slant/padded_slant 等）
            offsets = {  -- 偏移配置（为 NvimTree 留出空间）
                {
                    filetype = "NvimTree",  -- 当 NvimTree 打开时
                    text = "File Explorer",  -- 显示的文本
                    highlight = "Directory",  -- 文本高亮组（复用目录高亮）
                    text_align = "left",  -- 文本左对齐
                },
            },
            diagnostics = "nvim_lsp",  -- 启用 LSP 诊断提示
            diagnostics_indicator = function(_, _, diagnostics_dict, _)  -- 诊断图标自定义
                local s = " "
                for e, n in pairs(diagnostics_dict) do  -- e: 错误类型（error/warn/info），n: 数量
                    -- 根据错误类型选择图标（复用 Ice.symbols 全局图标）
                    local sym = e == "error" and symbols.Error or (e == "warning" and symbols.Warn or symbols.Info)
                    s = s .. n .. sym  -- 拼接数量和图标（如 "2❌1⚠️"）
                end
                return s
            end,
        },
    },
    config = function(_, opts)  -- 插件初始化函数（加载配置后执行）
        -- 自定义命令：BufferLineClose（关闭指定缓冲区，带未保存提示）
        vim.api.nvim_create_user_command("BufferLineClose", function(buffer_line_opts)
            local bufnr = 1 * buffer_line_opts.args  -- 获取传入的缓冲区 ID
            local buf_is_modified = vim.api.nvim_get_option_value("modified", { buf = bufnr })  -- 检查缓冲区是否修改未保存

            -- 构造 bdelete 命令参数（0 表示当前缓冲区）
            local bdelete_arg
            if bufnr == 0 then
                bdelete_arg = ""
            else
                bdelete_arg = " " .. bufnr
            end
            local command = "bdelete!" .. bdelete_arg  -- 强制关闭命令（! 忽略未保存提示，后续手动处理）

            -- 若缓冲区已修改，弹出确认窗口
            if buf_is_modified then
                local option = vim.fn.confirm("文件未保存，是否强制关闭？", "&Yes\n&No", 2)  -- 2 表示默认选 No
                if option == 1 then  -- 用户选 Yes 则执行关闭
                    vim.cmd(command)
                end
            else  -- 未修改则直接关闭
                vim.cmd(command)
            end
        end, { nargs = 1 })  -- nargs = 1 表示命令需要 1 个参数（缓冲区 ID）

        require("bufferline").setup(opts)  -- 加载 bufferline 配置

        -- 扩展文件图标：为 Typst 文件（.typ）添加自定义图标
        require("nvim-web-devicons").setup {
            override = {
                typ = { icon = "", color = "#239dad", name = "typst" },  -- icon: 图标，color: 颜色，name: 文件名
            },
        }
    end,
    keys = {  -- 缓冲区操作快捷键（<leader> 默认为空格）
        { "<leader>bc", "<Cmd>BufferLinePickClose<CR>", desc = "缓冲区：选择关闭某个标签", silent = true },
        { "<leader>bd", "<Cmd>BufferLineClose 0<CR>", desc = "缓冲区：关闭当前标签", silent = true },
        { "<leader>bh", "<Cmd>BufferLineCyclePrev<CR>", desc = "缓冲区：切换到上一个标签", silent = true },
        { "<leader>bl", "<Cmd>BufferLineCycleNext<CR>", desc = "缓冲区：切换到下一个标签", silent = true },
        { "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", desc = "缓冲区：关闭其他所有标签", silent = true },
        { "<leader>bp", "<Cmd>BufferLinePick<CR>", desc = "缓冲区：选择切换标签", silent = true },
        { "<leader>bm", "<Cmd>IceRepeat BufferLineMoveNext<CR>", desc = "缓冲区：标签向右移动", silent = true },
        { "<leader>bM", "<Cmd>IceRepeat BufferLineMovePrev<CR>", desc = "缓冲区：标签向左移动", silent = true },
    },
}

-- ==============================================
-- 插件 3：nvim-colorizer.lua（颜色代码实时高亮）
-- 功能概述：
-- 1. 自动识别文本中的颜色代码（如 #fff、rgb(255,255,255)、hsl(0,0%,100%)）
-- 2. 在颜色代码旁显示对应的颜色块，直观查看颜色效果
-- 3. 支持 CSS、SCSS、Lua 等多种文件类型
-- 适用场景：前端开发、主题配置（快速预览颜色）
-- ==============================================
config.colorizer = {
    "NvChad/nvim-colorizer.lua",  -- 插件 GitHub 地址
    main = "colorizer",  -- 插件入口模块（require("colorizer")）
    event = "User IceLoad",  -- 加载时机：IceLoad 事件触发后
    opts = {  -- 插件配置
        filetypes = {
            "*",  -- 对所有文件类型启用
            css = {
                names = true,  -- CSS 文件中启用颜色名称识别（如 red、blue）
            },
        },
        user_default_options = {
            css = true,  -- 启用 CSS 颜色语法支持
            css_fn = true,  -- 启用 CSS 颜色函数支持（如 rgb()、hsl()）
            names = false,  -- 全局禁用颜色名称识别（仅 CSS 单独启用）
            always_update = true,  -- 实时更新颜色高亮（修改颜色代码后立即刷新）
        },
    },
    config = function(_, opts)
        require("colorizer").setup(opts)  -- 加载 colorizer 配置
        vim.cmd "ColorizerToggle"  -- 切换颜色高亮（确保默认启用）
    end,
}
-- ==============================================
-- 插件 4：dashboard-nvim（美化启动界面）
-- 功能概述：
-- 1. Neovim 启动时显示自定义界面（替代默认的空缓冲区）
-- 2. 显示常用操作入口（编辑配置、打开 Mason、关于 IceNvim 等）
-- 3. 支持自定义标题、图标、底部提示语
-- 核心价值：提升启动体验，快速访问常用功能
-- ==============================================
config.dashboard = {
    "nvimdev/dashboard-nvim",  -- 插件 GitHub 地址
    event = "User IceAfter colorscheme",  -- 加载时机：主题加载完成后（优先显示启动界面）
    opts = {
        theme = "doom",  -- 启动界面主题（doom/hyper 等）
        config = {
            -- 标题：ASCII 艺术字（IceNvim 标志），通过 patorjk.com 生成
            header = {
                " ",
                "██╗ ██████╗███████╗███╗   ██╗██╗   ██╗██╗███╗   ███╗",
                "██║██╔════╝██╔════╝████╗  ██║██║   ██║██║████╗ ████║",
                "██║██║     █████╗  ██╔██╗ ██║██║   ██║██║██╔████╔██║",
                "██║██║     ██╔══╝  ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║",
                "██║╚██████╗███████╗██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║",
                "╚═╝ ╚═════╝╚══════╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═",
                " ",
                string.format("                      %s                       ", require("core.utils").version),  -- 显示 IceNvim 版本
                " ",
            },
            -- 中间：常用操作入口（图标 + 描述 + 执行命令）
            center = {
                {
                    icon = "  ",  -- 图标（通过 nvim-web-devicons 提供）
                    desc = "Lazy Profile",  -- 描述
                    action = "Lazy profile",  -- 执行命令（打开 Lazy 插件管理器的性能分析）
                },
                {
                    icon = "  ",
                    desc = "Edit preferences   ",
                    action = string.format("edit %s/lua/custom/init.lua", config_root),  -- 编辑自定义配置文件
                },
                {
                    icon = "  ",
                    desc = "Mason",
                    action = "Mason",  -- 打开 Mason 插件管理器
                },
                {
                    icon = "  ",
                    desc = "About IceNvim",
                    action = "IceAbout",  -- 显示 IceNvim 关于信息
                },
            },
            footer = { "🧊 Hope that you enjoy using IceNvim 😀😀😀" },  -- 底部提示语
        },
    },
    config = function(_, opts)
        require("dashboard").setup(opts)  -- 加载 dashboard 配置

        -- 若启动时无打开的文件（空缓冲区），则显示启动界面
        if vim.api.nvim_buf_get_name(0) == "" then
            vim.cmd "Dashboard"
        end

        -- 自定义底部提示语高亮（清除默认高亮，使用 IceNormal 配色）
        -- 原作者注释：使用 highlight 命令比 vim.api.nvim_set_hl() 更方便
        vim.cmd "highlight DashboardFooter cterm=NONE gui=NONE"
    end,
}

-- ==============================================
-- 插件 5：fidget.nvim（LSP 进度提示）
-- 功能概述：
-- 1. 在右下角显示 LSP 服务的运行状态（如 "正在分析代码"、"格式化中"）
-- 2. 替代默认的 LSP 进度提示（更美观、简洁）
-- 3. 支持自定义窗口样式、位置
-- 核心价值：避免 LSP 后台运行时无反馈，提升用户体验
-- ==============================================
config.fidget = {
    "j-hui/fidget.nvim",  -- 插件 GitHub 地址
    event = "VeryLazy",  -- 加载时机：极晚加载（LSP 启动后才需要）
    opts = {
        notification = {
            override_vim_notify = true,  -- 覆盖 vim.notify 通知（统一样式）
            window = {
                winblend = 0,  -- 窗口不透明（0-100，0 完全不透明）
                x_padding = 2,  -- 水平内边距
                align = "top",  -- 窗口对齐方式（top/bottom）
            },
        },
        integration = {
            ["nvim-tree"] = {
                enable = false,  -- 禁用 NvimTree 的进度提示（避免冲突）
            },
        },
    },
}
-- ==============================================
-- 插件 6：gitsigns.nvim（Git 代码改动提示）
-- 功能概述：
-- 1. 在左侧行号旁显示 Git 改动标记（新增/修改/删除）
-- 2. 支持快捷键操作（暂存、撤销暂存、查看改动内容等）
-- 3. 实时响应 Git 仓库变化（无需手动刷新）
-- 适用场景：Git 版本控制下的代码编辑，快速跟踪改动
-- ==============================================
config.gitsigns = {
    "lewis6991/gitsigns.nvim",  -- 插件 GitHub 地址
    event = "User IceLoad",  -- 加载时机：IceLoad 事件触发后
    main = "gitsigns",  -- 插件入口模块
    opts = {},  -- 使用默认配置（新手无需修改）
    keys = {  -- Git 操作快捷键
        { "<leader>gn", "<Cmd>Gitsigns next_hunk<CR>", desc = "Git：跳转到下一个改动块", silent = true },
        { "<leader>gp", "<Cmd>Gitsigns prev_hunk<CR>", desc = "Git：跳转到上一个改动块", silent = true },
        { "<leader>gP", "<Cmd>Gitsigns preview_hunk<CR>", desc = "Git：预览当前改动块", silent = true },
        { "<leader>gs", "<Cmd>Gitsigns stage_hunk<CR>", desc = "Git：暂存当前改动块", silent = true },
        { "<leader>gu", "<Cmd>Gitsigns undo_stage_hunk<CR>", desc = "Git：撤销暂存当前改动块", silent = true },
        { "<leader>gr", "<Cmd>Gitsigns reset_hunk<CR>", desc = "Git：重置当前改动块（丢弃修改）", silent = true },
        { "<leader>gB", "<Cmd>Gitsigns stage_buffer<CR>", desc = "Git：暂存整个缓冲区改动", silent = true },
        { "<leader>gb", "<Cmd>Gitsigns blame<CR>", desc = "Git：显示文件 blame 信息", silent = true },
        { "<leader>gl", "<Cmd>Gitsigns blame_line<CR>", desc = "Git：显示当前行 blame 信息", silent = true },
    },
}

-- ==============================================
-- 插件 7：grug-far.nvim（强大的查找替换工具）
-- 功能概述：
-- 1. 支持跨文件模糊查找 + 批量替换（比内置 :%s 更强大）
-- 2. 实时预览替换结果，支持正则表达式
-- 3. 简洁的 UI 界面，操作直观
-- 核心价值：解决多文件批量修改的痛点（如重构变量名）
-- ==============================================
config["grug-far"] = {  -- 插件名带连字符，用[]包裹
    "MagicDuck/grug-far.nvim",  -- 插件 GitHub 地址
    opts = {
        disableBufferLineNumbers = true,  -- 禁用查找窗口的行号
        startInInsertMode = true,  -- 打开后自动进入插入模式（方便输入查找内容）
        windowCreationCommand = "tabnew %",  -- 用新标签页打开查找窗口
    },
    keys = {
        { "<leader>ug", "<Cmd>GrugFar<CR>", desc = "工具：打开查找替换窗口", silent = true },
    },
}

-- ==============================================
-- 插件 8：neogit（Git 可视化操作界面）
-- 功能概述：
-- 1. 提供图形化 Git 操作界面（替代命令行 git 操作）
-- 2. 支持提交、分支切换、合并、查看日志等核心 Git 功能
-- 3. 与 Neovim 无缝集成，操作逻辑与 Vim 一致
-- 适用场景：不熟悉 Git 命令的新手，或需要快速可视化操作的场景
-- ==============================================
config.neogit = {
    "NeogitOrg/neogit",  -- 插件 GitHub 地址
    dependencies = { "nvim-lua/plenary.nvim" },  -- 依赖工具函数库
    main = "neogit",  -- 插件入口模块
    opts = {
        disable_hint = true,  -- 禁用操作提示（简化界面）
        status = {
            recent_commit_count = 30,  -- 显示最近 30 条提交记录
        },
        commit_editor = {
            kind = "auto",  -- 提交编辑器类型（自动适配窗口大小）
            show_staged_diff = false,  -- 不显示暂存文件的差异（简化编辑器）
        },
    },
    keys = {
        { "<leader>gt", "<Cmd>Neogit<CR>", desc = "Git：打开可视化操作界面", silent = true },
    },
    config = function(_, opts)
        require("neogit").setup(opts)  -- 加载 neogit 配置

        -- 自定义 NeogitCommitMessage 缓冲区行为：打开后光标定位到第一行开头
        Ice.ft.NeogitCommitMessage = function()
            vim.api.nvim_win_set_cursor(0, { 1, 0 })
        end
    end,
}
-- ==============================================
-- 插件 9：hop.nvim（快速跳转工具）
-- 功能概述：
-- 1. 基于字符/单词的快速跳转（类似 EasyMotion）
-- 2. 输入目标字符后，显示快捷键提示，按下对应键即可跳转
-- 3. 支持自定义跳转范围、快捷键集合
-- 核心价值：减少光标移动次数，提升编辑效率
-- ==============================================
config.hop = {
    "smoka7/hop.nvim",  -- 插件 GitHub 地址
    main = "hop",  -- 插件入口模块
    opts = {
        -- hint_position = 3：等价于 require("hop.hint").HintPosition.END（跳转提示显示在目标字符末尾）
        hint_position = 3,
        keys = "fjghdksltyrueiwoqpvbcnxmza",  -- 跳转快捷键集合（避免使用常用编辑键）
    },
    keys = {
        { "<leader>hp", "<Cmd>HopWord<CR>", desc = "跳转：基于单词快速跳转", silent = true },
    },
}

-- ==============================================
-- 插件 10：indent-blankline.nvim（缩进线提示）
-- 功能概述：
-- 1. 在代码缩进处显示垂直虚线，直观区分代码块层级
-- 2. 支持彩虹色缩进线（与 rainbow-delimiters 联动）
-- 3. 可排除指定文件类型（如仪表盘、终端）
-- 适用场景：嵌套代码较多的场景（如 Python、Lua 函数/循环嵌套）
-- ==============================================
config["indent-blankline"] = {  -- 插件名带连字符，用[]包裹
    "lukas-reineke/indent-blankline.nvim",  -- 插件 GitHub 地址
    event = "User IceAfter nvim-treesitter",  -- 加载时机：treesitter 加载完成后（依赖语法解析）
    main = "ibl",  -- 插件入口模块（新版 indent-blankline 用 ibl 作为入口）
    opts = {
        exclude = {  -- 排除的文件类型（不显示缩进线）
            filetypes = { "dashboard", "terminal", "help", "log", "markdown", "TelescopePrompt" },
        },
        indent = {
            highlight = {  -- 缩进线高亮组（彩虹色配置）
                "IblIndent",
                "RainbowDelimiterRed",
                "RainbowDelimiterYellow",
                "RainbowDelimiterBlue",
                "RainbowDelimiterOrange",
                "RainbowDelimiterGreen",
                "RainbowDelimiterViolet",
                "RainbowDelimiterCyan",
            },
        },
    },
}

-- ==============================================
-- 插件 11：lualine.nvim（美化状态栏）
-- 功能概述：
-- 1. 底部显示状态栏，包含文件信息、Git 分支、LSP 状态、时间等
-- 2. 支持自定义分区、图标、颜色主题
-- 3. 与 NvimTree 等插件联动（自动隐藏/显示）
-- 核心价值：替代默认简陋状态栏，提供丰富的上下文信息
-- ==============================================
config.lualine = {
    "nvim-lualine/lualine.nvim",  -- 插件 GitHub 地址
    dependencies = { "nvim-tree/nvim-web-devicons" },  -- 依赖文件图标库（美化状态栏）
    event = "User IceLoad",  -- 加载时机：IceLoad 事件触发后
    main = "lualine",  -- 插件入口模块
    opts = {
        options = {
            theme = "auto",  -- 自动适配当前主题（无需手动指定）
            component_separators = { left = "", right = "" },  -- 组件分隔符（Unicode 符号）
            section_separators = { left = "", right = "" },  -- 分区分隔符
            disabled_filetypes = { "undotree", "diff" },  -- 禁用状态栏的文件类型
        },
        extensions = { "nvim-tree" },  -- 扩展支持 NvimTree（文件树中显示状态栏）
        sections = {
            lualine_b = { "branch", "diff" },  -- 左侧分区：Git 分支、提交差异（新增/修改/删除）
            lualine_c = {
                "filename",  -- 文件名（包含路径）
            },
            lualine_x = {  -- 右侧分区：文件大小、格式、编码、类型
                "filesize",  -- 文件大小
                {
                    "fileformat",  -- 文件格式（Unix/Dos/Mac）
                    symbols = { unix = symbols.Unix, dos = symbols.Dos, mac = symbols.Mac },  -- 自定义格式图标
                },
                "encoding",  -- 文件编码（如 utf-8）
                "filetype",  -- 文件类型（如 lua、python）
            },
        },
    },
}
-- ==============================================
-- 插件 12：markdown-preview.nvim（Markdown 实时预览）
-- 功能概述：
-- 1. 在浏览器中实时预览 Markdown 文件（修改后自动刷新）
-- 2. 支持 MathJax、代码高亮、表格等 Markdown 扩展语法
-- 3. 仅在打开 .md 文件时加载（优化启动速度）
-- 适用场景：写文档、笔记、博客时实时查看效果
-- ==============================================
config["markdown-preview"] = {  -- 插件名带连字符，用[]包裹
    "iamcco/markdown-preview.nvim",  -- 插件 GitHub 地址
    ft = "markdown",  -- 加载时机：仅打开 Markdown 文件（.md）时
    config = function()
        vim.g.mkdp_filetypes = { "markdown" }  -- 仅对 markdown 文件启用预览
        vim.g.mkdp_auto_close = 0  -- 关闭 Neovim 时不自动关闭预览窗口（0 禁用，1 启用）
    end,
    build = "cd app && yarn install",  -- 安装时构建依赖（需要 Node.js 和 yarn）
    keys = {
        {
            "<A-b>",  -- 快捷键：Alt + b
            "<Cmd>MarkdownPreviewToggle<CR>",  -- 切换预览（打开/关闭）
            desc = "Markdown：切换实时预览",
            ft = "markdown",  -- 仅在 Markdown 文件中生效
            silent = true,
        },
    },
}

-- ==============================================
-- 插件 13：nvim-autopairs（括号自动补全）
-- 功能概述：
-- 1. 输入左括号（(、[、{、"、' 等）时自动补全右括号
-- 2. 光标在括号中间时，按回车自动换行并缩进
-- 3. 支持自定义补全规则（如 HTML 标签、Vue 模板）
-- 核心价值：减少重复输入，避免括号不匹配错误
-- ==============================================
config["nvim-autopairs"] = {  -- 插件名带连字符，用[]包裹
    "windwp/nvim-autopairs",  -- 插件 GitHub 地址
    event = "InsertEnter",  -- 加载时机：进入插入模式时
    main = "nvim-autopairs",  -- 插件入口模块
    opts = {},  -- 使用默认配置（新手无需修改）
}

-- ==============================================
-- 插件 14：nui.nvim（UI 组件库）
-- 功能概述：
-- 1. 提供基础 UI 组件（弹窗、窗口、菜单等），供其他插件依赖
-- 2. 不直接提供用户功能，仅作为底层支持
-- 注意：lazy = true 表示延迟加载（仅在其他插件调用时才加载）
-- ==============================================
config.nui = {
    "MunifTanjim/nui.nvim",  -- 插件 GitHub 地址
    lazy = true,  -- 延迟加载（优化启动速度）
}
-- ==============================================
-- 插件 15：nvim-scrollview（美化滚动条）
-- 功能概述：
-- 1. 在右侧显示可视化滚动条（替代默认简陋滚动条）
-- 2. 支持自定义滚动条位置、透明度、宽度
-- 3. 可排除指定文件类型（如 NvimTree）
-- 核心价值：直观显示当前滚动位置，提升 UI 美观度
-- ==============================================
config["nvim-scrollview"] = {  -- 插件名带连字符，用[]包裹
    "dstein64/nvim-scrollview",  -- 插件 GitHub 地址
    event = "User IceLoad",  -- 加载时机：IceLoad 事件触发后
    main = "scrollview",  -- 插件入口模块
    opts = {
        excluded_filetypes = { "nvimtree" },  -- 排除 NvimTree（文件树不需要滚动条）
        current_only = true,  -- 仅显示当前激活窗口的滚动条
        winblend = 75,  -- 滚动条透明度（0-100，75 表示半透明）
        base = "right",  -- 滚动条位置（right/left）
        column = 1,  -- 滚动条宽度（1 列）
    },
}

-- ==============================================
-- 插件 16：nvim-transparent（透明背景）
-- 功能概述：
-- 1. 移除 Neovim 背景色，实现透明效果（适配壁纸）
-- 2. 支持自定义需要透明的高亮组（如 NvimTree、Telescope）
-- 3. 主题切换时自动重新应用透明配置
-- 注意：需要终端/Neovim GUI 支持透明（如 Alacritty、WezTerm、Neovide）
-- ==============================================
config["nvim-transparent"] = {  -- 插件名带连字符，用[]包裹
    "xiyaowong/transparent.nvim",  -- 插件 GitHub 地址
    event = "VeryLazy",  -- 加载时机：极晚加载（确保主题已生效）
    opts = {
        extra_groups = {  -- 额外需要透明的高亮组（默认仅透明 Normal 组）
            "NvimTreeNormal",  -- NvimTree 背景透明
            "NvimTreeNormalNC",  -- NvimTree 非激活窗口背景透明
            "TelescopeNormal",  -- Telescope 背景透明
        },
    },
    config = function(_, opts)
        -- 创建自动命令组：主题切换时重新应用透明配置
        local autogroup = vim.api.nvim_create_augroup("transparent", { clear = true })
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = autogroup,
            callback = function()
                -- 获取当前 Normal 高亮组的前景色和背景色
                local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
                local foreground = string.format("#%06x", normal_hl.fg)  -- 前景色（十六进制）
                local background = string.format("#%06x", normal_hl.bg)  -- 背景色（十六进制）
                -- 创建自定义高亮组 IceNormal：保留前景色，背景色透明（或原背景色）
                vim.cmd("highlight default IceNormal guifg=" .. foreground .. " guibg=" .. background)

                require("transparent").clear()  -- 清除现有透明配置，重新应用
            end,
        })

        -- 默认启用透明：通过缓存文件控制（首次启动时创建缓存）
        local transparent_cache = vim.fs.joinpath(vim.fn.stdpath "data", "transparent_cache")
        if not vim.uv.fs_stat(transparent_cache) then  -- 若缓存文件不存在
            local f = io.open(transparent_cache, "w")
            f:write "true"  -- 写入 true 表示启用透明
            f:close()
        end

        require("transparent").setup(opts)  -- 加载透明配置

        -- 确保 IceNormal 高亮组已设置（触发一次 ColorScheme 事件）
        vim.api.nvim_exec_autocmds("ColorScheme", { group = "transparent" })

        -- 重写 vim.api.nvim_get_hl：当获取 Normal 高亮时，返回 IceNormal（确保透明生效）
        local old_get_hl = vim.api.nvim_get_hl
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.api.nvim_get_hl = function(ns_id, opt)
            if opt.name == "Normal" then
                local attempt = old_get_hl(0, { name = "IceNormal" })
                if next(attempt) ~= nil then  -- 若 IceNormal 存在
                    opt.name = "IceNormal"  -- 替换为 IceNormal
                end
            end
            return old_get_hl(ns_id, opt)
        end

        -- 重写 vim.api.nvim_set_hl：处理 bg = "bg" 的情况（避免透明失效）
        -- 原作者注释：nvim_set_hl 允许 bg 设为 "bg"（链接到 Normal 组），但透明后 Normal 组 bg 可能异常，需手动替换
        local old_set_hl = vim.api.nvim_set_hl
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.api.nvim_set_hl = function(ns_id, name, val)
            if val.bg == "bg" then  -- 若 bg 设为 "bg"
                val.bg = old_get_hl(0, { name = "IceNormal" }).bg  -- 替换为 IceNormal 的 bg
            end
            return old_set_hl(ns_id, name, val)
        end

        -- 触发 IceAfter transparent 事件（供其他插件监听）
        vim.api.nvim_exec_autocmds("User", { pattern = "IceAfter transparent" })
    end,
}
-- ==============================================
-- 插件 17：nvim-tree.lua（文件树管理器）
-- 功能概述：
-- 1. 左侧显示文件系统树，支持文件/文件夹的创建、删除、重命名等操作
-- 2. 与 LSP、Git 联动（显示文件状态、错误提示）
-- 3. 支持自定义快捷键、过滤规则、窗口样式
-- 核心价值：替代命令行文件操作，直观管理项目目录
-- ==============================================
config["nvim-tree"] = {  -- 插件名带连字符，用[]包裹
    "nvim-tree/nvim-tree.lua",  -- 插件 GitHub 地址
    dependencies = { "nvim-tree/nvim-web-devicons" },  -- 依赖文件图标库（美化文件树）
    opts = {
        on_attach = function(bufnr)  -- 文件树缓冲区附加时的回调（配置快捷键）
            local api = require "nvim-tree.api"  -- 引入 nvim-tree API
            local opt = { buffer = bufnr, silent = true }  -- 快捷键仅在文件树缓冲区生效

            api.config.mappings.default_on_attach(bufnr)  -- 加载默认快捷键

            -- 自定义快捷键（通过 core.utils.group_map 批量设置）
            require("core.utils").group_map({
                edit = {  -- 编辑文件（特殊处理：部分文件类型用外部程序打开）
                    "n",
                    "<CR>",  -- 回车键
                    function()
                        local node = api.tree.get_node_under_cursor()  -- 获取当前光标下的节点
                        if node.name ~= ".." and node.fs_stat.type == "file" then  -- 若为文件（非上级目录）
                            -- 外部打开的文件类型：图片、视频、文档等（不适合用 Neovim 编辑）
                            -- stylua: ignore start（禁用 stylua 格式化）
                            local extensions_opened_externally = {
                                "avi", "bmp", "doc", "docx", "exe", "flv", "gif", "jpg", "jpeg", "m4a", "mov", "mp3",
                                "mp4", "mpeg", "mpg", "pdf", "png", "ppt", "pptx", "psd", "pub", "rar", "rtf", "tif",
                                "tiff", "wav", "xls", "xlsx", "zip",
                            }
                            -- stylua: ignore end
                            if table.find(extensions_opened_externally, node.extension) then
                                api.node.run.system()  -- 用系统默认程序打开
                                return
                            end
                        end

                        api.node.open.edit()  -- 用 Neovim 打开文件
                    end,
                },
                vertical_split = { "n", "V", api.node.open.vertical },  -- 垂直分屏打开
                horizontal_split = { "n", "H", api.node.open.horizontal },  -- 水平分屏打开
                toggle_hidden_file = { "n", ".", api.tree.toggle_hidden_filter },  -- 显示/隐藏隐藏文件（.开头）
                reload = { "n", "<F5>", api.tree.reload },  -- 刷新文件树
                create = { "n", "a", api.fs.create },  -- 创建文件/文件夹
                remove = { "n", "d", api.fs.remove },  -- 删除文件/文件夹
                rename = { "n", "r", api.fs.rename },  -- 重命名文件/文件夹
                cut = { "n", "x", api.fs.cut },  -- 剪切文件/文件夹
                copy = { "n", "y", api.fs.copy.node },  -- 复制文件/文件夹
                paste = { "n", "p", api.fs.paste },  -- 粘贴文件/文件夹
                system_run = { "n", "s", api.node.run.system },  -- 用系统程序打开
                show_info = { "n", "i", api.node.show_info_popup },  -- 显示文件信息弹窗
            }, opt)
        end,
        git = {
            enable = false,  -- 禁用 Git 状态显示（简化文件树）
        },
        update_focused_file = {
            enable = true,  -- 聚焦文件时，自动在文件树中高亮该文件
        },
        filters = {
            dotfiles = false,  -- 显示隐藏文件（.开头）
            custom = { "node_modules", "^.git$" },  -- 过滤的文件/文件夹（不显示）
            exclude = { ".gitignore" },  -- 例外：显示 .gitignore 文件
        },
        respect_buf_cwd = true,  -- 尊重当前缓冲区的工作目录（文件树根目录跟随当前文件）
        view = {
            width = 30,  -- 文件树宽度（30 列）
            side = "left",  -- 显示在左侧
            number = false,  -- 不显示行号
            relativenumber = false,  -- 不显示相对行号
            signcolumn = "yes",  -- 显示符号列（用于显示错误/警告图标）
        },
        actions = {
            open_file = {
                resize_window = true,  -- 打开文件时自动调整文件树宽度
                quit_on_open = true,  -- 打开文件后关闭文件树（节省空间）
            },
        },
    },
    keys = {
        { "<leader>uf", "<Cmd>NvimTreeToggle<CR>", desc = "工具：切换文件树显示/隐藏", silent = true },
    },
}

-- ==============================================
-- 插件 18：nvim-treesitter（语法解析引擎）
-- 功能概述：
-- 1. 基于语法树的代码高亮、缩进、折叠、导航
-- 2. 支持 100+ 编程语言，提供精准的语法分析
-- 3. 为其他插件提供语法支持（如 indent-blankline、彩虹括号）
-- 核心价值：Neovim 现代化编辑体验的基石，替代传统正则语法高亮
-- ==============================================
config["nvim-treesitter"] = {  -- 插件名带连字符，用[]包裹
    "nvim-treesitter/nvim-treesitter",  -- 插件 GitHub 地址
    build = ":TSUpdate",  -- 安装/更新时执行：更新语法解析器
    dependencies = { "hiphish/rainbow-delimiters.nvim" },  -- 依赖彩虹括号插件
    event = "User IceAfter colorscheme",  -- 加载时机：主题加载完成后
    branch = "main",  -- 使用 main 分支（最新版）
    opts = {
        -- 确保安装的语法解析器（覆盖常用编程语言）
        -- stylua: ignore start（禁用 stylua 格式化）
        ensure_installed = {
            "bash", "c", "c_sharp", "cpp", "css", "fish", "go", "html", "javascript", "json", "lua", "markdown",
            "markdown_inline", "python", "query", "rust", "toml", "typescript", "typst", "tsx", "vim", "vimdoc",
        },
        -- stylua: ignore end
    },
    config = function(_, opts)
        local nvim_treesitter = require "nvim-treesitter"
        nvim_treesitter.setup()  -- 加载 treesitter 基础配置

        local pattern = {}  -- 存储需要启用 treesitter 的文件类型
        for _, parser in ipairs(opts.ensure_installed) do
            local has_parser, _ = pcall(vim.treesitter.language.inspect, parser)  -- 检查解析器是否已安装

            if not has_parser then
                nvim_treesitter.install(parser)  -- 未安装则自动安装（需重启生效）
            else
                -- 将解析器支持的文件类型添加到 pattern 中
                vim.list_extend(pattern, vim.treesitter.language.get_filetypes(parser))
            end
        end

        -- 创建自动命令组：为指定文件类型启用 treesitter
        local group = vim.api.nvim_create_augroup("NvimTreesitterFt", { clear = true })
        vim.api.nvim_create_autocmd("FileType", {
            group = group,
            pattern = pattern,  -- 仅对指定文件类型生效
            callback = function(ev)
                local max_filesize = Ice.max_file_size or (1024 * 1024)  -- 最大文件大小（1MB）
                local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(ev.buf))  -- 获取文件大小
                -- 若文件大小未超过限制，启用 treesitter
                if not (ok and stats and stats.size > max_filesize) then
                    vim.treesitter.start()
                    -- 非 dart 文件：使用 treesitter 缩进（dart 与 flutter-tools 冲突，禁用）
                    if vim.bo.filetype ~= "dart" then
                        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    end
                end
            end,
        })

        -- 配置彩虹括号（依赖 rainbow-delimiters.nvim）
        local rainbow_delimiters = require "rainbow-delimiters"
        vim.g.rainbow_delimiters = {
            strategy = {
                [""] = rainbow_delimiters.strategy["global"],  -- 全局启用彩虹括号
                vim = rainbow_delimiters.strategy["local"],  -- Vim 脚本局部启用
            },
            query = {
                [""] = "rainbow-delimiters",  -- 默认查询规则
                lua = "rainbow-blocks",  -- Lua 语言使用特殊规则（块级彩虹）
            },
            highlight = {  -- 彩虹括号颜色高亮组
                "RainbowDelimiterRed",
                "RainbowDelimiterYellow",
                "RainbowDelimiterBlue",
                "RainbowDelimiterOrange",
                "RainbowDelimiterGreen",
                "RainbowDelimiterViolet",
                "RainbowDelimiterCyan",
            },
        }
        rainbow_delimiters.enable()  -- 启用彩虹括号

        -- 兼容处理：Markdown 中 scheme 代码块用 query 语法高亮
        -- 原作者注释：Markdown 中 scheme 代码块若用 scheme 解析器会高亮异常，链接到 query 解析器
        vim.treesitter.language.register("query", "scheme")

        -- 触发事件：通知其他插件 treesitter 已加载
        vim.api.nvim_exec_autocmds("User", { pattern = "IceAfter nvim-treesitter" })
        vim.api.nvim_exec_autocmds("FileType", { group = "NvimTreesitterFt" })
    end,
}
-- ==============================================
-- 插件 19：nvim-surround（代码包围操作）
-- 功能概述：
-- 1. 快速添加、删除、替换代码的包围符号（括号、引号、标签等）
-- 2. 支持可视化模式操作（选中代码后快速包围）
-- 3. 支持自定义包围符号和快捷键
-- 核心价值：简化代码重构中的包围操作（如将 "" 替换为 ''、添加函数括号）
-- ==============================================
config.surround = {
    "kylechui/nvim-surround",  -- 插件 GitHub 地址
    version = "*",  -- 使用最新稳定版
    opts = {
        keymaps = {
            insert = "<C-c>s",  -- 插入模式：添加包围符号（Ctrl + c + s）
            insert_line = "<C-c>S",  -- 插入模式：添加行级包围符号（Ctrl + c + S）
        },
    },
    event = "User IceLoad",  -- 加载时机：IceLoad 事件触发后
}

-- ==============================================
-- 插件 20：telescope.nvim（模糊查找神器）
-- 功能概述：
-- 1. 支持文件查找、命令查找、代码符号查找、Git 提交查找等
-- 2. 基于 fzf 算法，查找速度快，支持模糊匹配、正则匹配
-- 3. 可扩展（支持多种插件集成，如项目管理、浏览器书签）
-- 核心价值：Neovim 生态的查找核心，替代多个专用查找工具
-- ==============================================
config.telescope = {
    "nvim-telescope/telescope.nvim",  -- 插件 GitHub 地址
    dependencies = {
        "nvim-lua/plenary.nvim",  -- 依赖工具函数库（异步操作）
        {  -- fzf 扩展：提升查找性能（C 语言编写）
            "nvim-telescope/telescope-fzf-native.nvim",
            build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && "  -- 构建命令（跨平台）
                .. "cmake --build build --config Release && "
                .. "cmake --install build --prefix build",
        },
    },
    cmd = "Telescope",  -- 加载时机：执行 :Telescope 命令时（延迟加载）
    opts = {
        defaults = {  -- 默认配置
            initial_mode = "insert",  -- 打开后进入插入模式（方便输入查找内容）
            mappings = {
                i = {  -- 插入模式快捷键
                    ["<C-j>"] = "move_selection_next",  -- 向下选择
                    ["<C-k>"] = "move_selection_previous",  -- 向上选择
                    ["<C-n>"] = "cycle_history_next",  -- 历史记录下一项
                    ["<C-p>"] = "cycle_history_prev",  -- 历史记录上一项
                    ["<C-c>"] = "close",  -- 关闭查找窗口
                    ["<C-u>"] = "preview_scrolling_up",  -- 预览窗口向上滚动
                    ["<C-d>"] = "preview_scrolling_down",  -- 预览窗口向下滚动
                },
            },
        },
        pickers = {  -- 特定查找器配置
            find_files = {
                winblend = 20,  -- 查找窗口透明度（20% 透明）
            },
        },
        extensions = {  -- 扩展配置（fzf 优化）
            fzf = {
                fuzzy = true,  -- 启用模糊匹配
                override_generic_sorter = true,  -- 覆盖通用排序器
                override_file_sorter = true,  -- 覆盖文件排序器
                case_mode = "smart_case",  -- 智能大小写（全小写匹配不区分大小写，含大写则区分）
            },
        },
    },
    config = function(_, opts)
        local telescope = require "telescope"
        telescope.setup(opts)  -- 加载 telescope 配置
        telescope.load_extension "fzf"  -- 加载 fzf 扩展（提升性能）
    end,
    keys = {  -- 常用查找快捷键
        { "<leader>tf", "<Cmd>Telescope find_files<CR>", desc = "查找：文件", silent = true },
        { "<leader>t<C-f>", "<Cmd>Telescope live_grep<CR>", desc = "查找：实时文本（项目内）", silent = true },
        { "<C-k><C-t>", require("plugins.utils").select_colorscheme, desc = "查找：选择主题", silent = true },
        { "<leader>uc", require("plugins.utils").view_configuration, desc = "查找：查看配置文件", silent = true },
    },
}

-- ==============================================
-- 插件 21：todo-comments.nvim（TODO 注释管理）
-- 功能概述：
-- 1. 高亮代码中的 TODO、FIXME、NOTE 等注释
-- 2. 支持通过 Telescope 查找所有 TODO 注释（全局搜索）
-- 3. 可自定义注释关键词和高亮颜色
-- 适用场景：项目开发中标记待办事项，方便后续跟踪
-- ==============================================
config["todo-comments"] = {  -- 插件名带连字符，用[]包裹
    "folke/todo-comments.nvim",  -- 插件 GitHub 地址
    dependencies = { "nvim-lua/plenary.nvim" },  -- 依赖工具函数库
    event = "User IceLoad",  -- 加载时机：IceLoad 事件触发后
    main = "todo-comments",  -- 插件入口模块
    opts = {},  -- 使用默认配置（关键词：TODO、FIXME、HACK、BUG、NOTE 等）
    keys = {
        { "<leader>ut", "<Cmd>TodoTelescope<CR>", desc = "工具：查看所有 TODO 注释", silent = true },
    },
}
-- ==============================================
-- 插件 22：nvim-ufo（高级代码折叠）
-- 功能概述：
-- 1. 基于语法树的代码折叠（比内置折叠更精准）
-- 2. 支持预览折叠内容（悬停时查看）
-- 3. 支持自定义折叠图标、预览窗口样式
-- 核心价值：替代内置简陋折叠，提升代码阅读体验（尤其是大文件）
-- ==============================================
config.ufo = {
    "kevinhwang91/nvim-ufo",  -- 插件 GitHub 地址
    dependencies = {
        "kevinhwang91/promise-async",  -- 依赖异步 Promise 库（处理折叠异步逻辑）
    },
    event = "VeryLazy",  -- 加载时机：极晚加载（仅在需要折叠时生效）
    opts = {
        preview = {  -- 折叠预览配置
            win_config = {
                border = "rounded",  -- 预览窗口圆角边框
                winhighlight = "Normal:Folded",  -- 预览窗口高亮组（复用折叠高亮）
                winblend = 0,  -- 预览窗口不透明
            },
        },
    },
    config = function(_, opts)
        vim.opt.foldenable = true  -- 启用折叠功能（默认关闭）

        require("ufo").setup(opts)  -- 加载 ufo 配置
    end,
    keys = {  -- 折叠操作快捷键
        {
            "zR",  -- 打开所有折叠
            function()
                require("ufo").openAllFolds()
            end,
            desc = "折叠：打开所有",
        },
        {
            "zM",  -- 关闭所有折叠
            function()
                require("ufo").closeAllFolds()
            end,
            desc = "折叠：关闭所有",
        },
        {
            "zp",  -- 预览折叠内容
            function()
                require("ufo").peekFoldedLinesUnderCursor()
            end,
            desc = "折叠：预览当前折叠",
        },
    },
}

-- ==============================================
-- 插件 23：undotree（撤销树可视化）
-- 功能概述：
-- 1. 可视化显示所有撤销记录（树形结构，支持分支撤销）
-- 2. 支持在撤销历史中跳转（恢复任意历史版本）
-- 3. 替代内置撤销（:undo/:redo），提供更灵活的撤销管理
-- 核心价值：避免误操作后无法恢复，尤其是复杂编辑场景
-- ==============================================
config.undotree = {
    "mbbill/undotree",  -- 插件 GitHub 地址
    config = function()
        vim.g.undotree_WindowLayout = 2  -- 窗口布局：右侧显示撤销树，左侧显示预览
        vim.g.undotree_TreeNodeShape = "-"  -- 撤销树节点形状（- 表示分支）
    end,
    keys = {
        { "<leader>uu", "<Cmd>UndotreeToggle<CR>", desc = "工具：切换撤销树显示/隐藏", silent = true },
    },
}

-- ==============================================
-- 插件 24：which-key.nvim（快捷键提示）
-- 功能概述：
-- 1. 按下 <leader> 等前缀键后，显示所有相关快捷键提示
-- 2. 支持自定义快捷键分组、图标、窗口样式
-- 3. 帮助新手记忆快捷键，避免遗忘配置
-- 核心价值：降低快捷键记忆成本，提升操作效率
-- ==============================================
config["which-key"] = {  -- 插件名带连字符，用[]包裹
    "folke/which-key.nvim",  -- 插件 GitHub 地址
    event = "VeryLazy",  -- 加载时机：极晚加载（不影响启动速度）
    opts = {
        icons = {
            mappings = false,  -- 不显示快捷键映射图标（简化界面）
        },
        plugins = {
            marks = true,  -- 启用标记（mark）快捷键提示
            registers = true,  -- 启用寄存器快捷键提示
            spelling = {
                enabled = false,  -- 禁用拼写检查快捷键提示
            },
            presets = {
                operators = false,  -- 禁用运算符快捷键提示
                motions = true,  -- 启用运动快捷键提示
                text_objects = true,  -- 启用文本对象快捷键提示
                windows = true,  -- 启用窗口快捷键提示
                nav = true,  -- 启用导航快捷键提示
                z = true,  -- 启用折叠快捷键提示
                g = true,  -- 启用 g 开头快捷键提示
            },
        },
        spec = {  -- 快捷键分组（<leader> 前缀下的分组）
            { "<leader>a", group = "+avante" },  -- a 组：avante AI 辅助
            { "<leader>b", group = "+buffer" },  -- b 组：缓冲区操作
            { "<leader>c", group = "+comment" },  -- c 组：注释操作（需配合 comment 插件）
            { "<leader>g", group = "+git" },  -- g 组：Git 操作
            { "<leader>h", group = "+hop" },  -- h 组：快速跳转
            { "<leader>l", group = "+lsp" },  -- l 组：LSP 相关操作
            { "<leader>t", group = "+telescope" },  -- t 组：查找操作
            { "<leader>u", group = "+utils" },  -- u 组：工具操作
        },
        win = {  -- 提示窗口样式
            border = "none",  -- 无边框
            padding = { 1, 0, 1, 0 },  -- 内边距（上、右、下、左）
            wo = {
                winblend = 0,  -- 不透明
            },
            zindex = 1000,  -- 窗口层级（确保在最上层）
        },
    },
}

-- ==============================================
-- 插件 25：colorful-winsep.nvim（彩色窗口分隔线）
-- 功能概述：
-- 1. 为多窗口分隔线添加颜色（替代默认灰色分隔线）
-- 2. 支持自定义分隔线样式、颜色、动画
-- 核心价值：提升多窗口编辑时的视觉体验，区分不同窗口
-- ==============================================
config.winsep = {
    "nvim-zh/colorful-winsep.nvim",  -- 插件 GitHub 地址
    event = "User IceAfter colorscheme",  -- 加载时机：主题加载完成后（适配主题颜色）
    opts = {
        border = "single",  -- 分隔线样式（single/double/dashed 等）
        highlight = function()
            -- 分隔线高亮：链接到 IceNormal 组（适配主题颜色）
            vim.cmd "highlight link ColorfulWinsep IceNormal"
        end,
        animate = {
            enabled = false,  -- 禁用分隔线动画（简化界面）
        },
    },
}

-- ==============================================
-- 主题插件：所有预定义主题的依赖声明（延迟加载）
-- 说明：
-- 1. 所有主题插件设置为 lazy = true（仅在切换主题时加载）
-- 2. 主题名称与 Ice.colorschemes 中的配置对应
-- 3. 无需额外配置，通过 Ice 全局配置切换主题即可
-- ==============================================
config["cyberdream"] = { "scottmckendry/cyberdream.nvim", lazy = true }  -- 赛博朋克风主题
config["gruvbox"] = { "ellisonleao/gruvbox.nvim", lazy = true }  -- 复古棕色调主题
config["kanagawa"] = { "rebelot/kanagawa.nvim", lazy = true }  -- 日式和风主题
config["miasma"] = { "xero/miasma.nvim", lazy = true }  -- 极简冷色调主题
config["monet"] = { "fynnfluegge/monet.nvim", lazy = true }  -- 莫奈油画风主题
config["nightfox"] = { "EdenEast/nightfox.nvim", lazy = true }  -- 现代多变体主题（支持 dark/light）
config["tokyonight"] = { "folke/tokyonight.nvim", lazy = true }  -- 东京夜景风主题（流行度高）

-- ==============================================
-- 最终生效：将所有插件配置赋值给 Ice.plugins
-- 说明：Ice 框架会自动加载 Ice.plugins 中的所有插件
-- ==============================================
Ice.plugins = config