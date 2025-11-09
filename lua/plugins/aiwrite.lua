-- 在原有注释基础上，补充 每个插件的完整功能清单 和 个性化拓展方向，让你清晰了解现有插件的潜力的拓展空间，可直接粘贴替换原配置（仅补充注释，不修改代码）：
-- 这个代码是ai写的，他说✅ 可以！三大部分完整代码可以合并成一个 nvim/lua/xxx.lua 文件（比如 nvim/lua/plugins/init.lua），直接替换你原来的插件配置文件，不会报错！
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
-- 【完整功能清单】
-- 1. 代码生成：根据注释/关键词生成函数、类、完整文件
-- 2. 代码解释：解释选中代码的功能、逻辑、优化建议
-- 3. 代码重构：重命名变量、提取函数、优化性能、修复 bug
-- 4. 多窗口布局：选中代码区、输入提示区、AI 结果区、文件选择区、TODO 管理区
-- 5. 支持多 AI 提供商：Copilot、OpenAI、Anthropic 等
-- 6. Markdown 渲染：AI 结果支持表格、代码块、公式等 Markdown 语法
-- 7. 上下文感知：结合当前文件、项目依赖生成精准结果
-- 【个性化拓展方向】
-- 1. 切换 AI 提供商：opts.provider 改为 "openai"，配置 api_key 实现 GPT-4/3.5 调用
-- 2. 自定义提示词：在 opts.providers 中添加 prompt_template，定制 AI 输出格式（如强制注释风格）
-- 3. 快捷键拓展：添加快捷键实现 "一键补全注释" "一键格式化代码" "一键生成测试用例"
-- 4. 窗口样式定制：修改 opts.windows 中的宽高、边框、颜色，适配自己的 UI 风格
-- 5. 集成其他插件：结合 telescope 实现 "AI 搜索项目文档"，结合 nvim-dap 实现 "AI 调试代码"
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
-- 【完整功能清单】
-- 1. 标签式显示：顶部显示所有打开的缓冲区（文件），直观区分
-- 2. 鼠标操作：点击标签切换、右键关闭、拖拽调整标签顺序
-- 3. 快捷键支持：切换、关闭、移动标签，批量关闭其他标签
-- 4. LSP 诊断集成：标签上显示错误/警告数量，颜色区分严重程度
-- 5. 插件联动：与 NvimTree 自动适配（留出空间），与 gitsigns 显示 Git 状态
-- 6. 自定义样式：标签分隔符、颜色、图标、高亮效果可配置
-- 7. 未保存提示：关闭修改未保存的缓冲区时弹出确认窗口
-- 【个性化拓展方向】
-- 1. 样式定制：修改 opts.options.separator_style 为 "slant"（斜杠分隔符），添加 highlights 配置标签颜色
-- 2. 功能拓展：启用 opts.options.hover = { enabled = true, delay = 200 } 实现标签hover显示文件路径
-- 3. 快捷键拓展：添加快捷键实现 "标签排序" "批量保存缓冲区" "按文件类型过滤标签"
-- 4. 图标增强：通过 nvim-web-devicons 为更多文件类型添加自定义图标（如 .env、.jsonc）
-- 5. 集成其他插件：结合 bufferline-cycle-windowless 实现无窗口时也能切换标签
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
-- 【完整功能清单】
-- 1. 多格式支持：识别 #RGB/RGBA、rgb()/rgba()、hsl()/hsla()、颜色名称（如 red）
-- 2. 实时高亮：在颜色代码旁显示对应颜色块，修改代码后立即刷新
-- 3. 多文件类型适配：默认支持所有文件类型，CSS 等文件可单独配置
-- 4. 自定义规则：支持忽略特定颜色、调整颜色块大小、设置更新频率
-- 5. 透明度支持：识别 rgba()/hsla() 中的透明度，颜色块同步显示透明效果
-- 【个性化拓展方向】
-- 1. 样式定制：修改 opts.user_default_options.foreground = true 让颜色代码文字颜色与颜色块一致
-- 2. 功能拓展：启用 opts.user_default_options.mode = "virtualtext" 让颜色块显示在代码右侧（不占用字符位置）
-- 3. 文件类型细化：为 SCSS、Less、Vue、React 等文件单独配置颜色识别规则
-- 4. 快捷键添加：添加快捷键切换颜色高亮开启/关闭、调整颜色块大小
-- 5. 集成其他插件：结合 vim-css-color 实现颜色picker（点击颜色块选择颜色）
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
-- 【完整功能清单】
-- 1. 自定义启动界面：替代默认空缓冲区，显示 ASCII 艺术字、常用操作、版本信息
-- 2. 快速操作入口：点击/快捷键打开常用功能（编辑配置、插件管理、关于信息）
-- 3. 主题支持：内置 doom/hyper 等主题，可自定义颜色、图标、布局
-- 4. 动态内容：支持显示最近打开文件、项目列表、快捷命令
-- 5. 自动触发：启动时无打开文件则自动显示，打开文件后自动隐藏
-- 【个性化拓展方向】
-- 1. 界面定制：修改 header 为自己喜欢的 ASCII 艺术字（通过 patorjk.com 生成），调整 center 区域的图标和描述
-- 2. 功能拓展：在 center 区域添加更多入口（如 "打开最近文件" "新建文件" "打开项目"）
-- 3. 动态内容添加：显示天气、时间、Git 分支、系统信息等（通过自定义函数实现）
-- 4. 样式优化：修改字体、颜色、间距，添加背景图片（结合 nvim-background 插件）
-- 5. 快捷键拓展：为每个启动项添加单独快捷键，实现 "一键启动"
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
                    desc = "Lazy Profile",
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
-- 【完整功能清单】
-- 1. LSP 进度可视化：显示 LSP 服务的运行状态（如 "正在初始化" "正在分析代码" "格式化中"）
-- 2. 通知统一：覆盖 vim.notify 通知，统一样式和位置（避免弹窗混乱）
-- 3. 自定义样式：窗口位置、大小、透明度、颜色可配置
-- 4. 插件联动：支持与 nvim-tree、telescope 等插件冲突规避
-- 5. 自动隐藏：任务完成后自动关闭提示，不占用屏幕空间
-- 【个性化拓展方向】
-- 1. 样式定制：修改 opts.notification.window.align 为 "bottom" 让提示显示在底部，调整 winblend 实现半透明
-- 2. 内容拓展：启用 opts.notification.format = "{msg} ({percentage}%)" 显示任务进度百分比
-- 3. 过滤规则：添加过滤条件，忽略不重要的 LSP 通知（如 "文件已保存"）
-- 4. 快捷键添加：添加快捷键手动清除所有提示、暂停/恢复提示显示
-- 5. 集成其他插件：结合 noice.nvim 实现更强大的通知管理（如通知历史、弹窗样式）
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
-- 【完整功能清单】
-- 1. 行内改动提示：左侧行号旁显示 Git 改动标记（新增/修改/删除/未跟踪）
-- 2. 操作支持：暂存、撤销暂存、重置、预览改动、显示 blame 信息
-- 3. 跳转功能：快速跳转到上一个/下一个改动块
-- 4. 实时响应：Git 仓库变化后自动刷新，无需手动执行 git status
-- 5. 自定义标记：改动标记的图标、颜色、位置可配置
-- 6. 多仓库支持：同时编辑多个 Git 仓库的文件时，正确显示各自的改动状态
-- 【个性化拓展方向】
-- 1. 样式定制：修改 opts.signs 中的图标（如用 "A" 表示新增，"M" 表示修改），调整颜色适配主题
-- 2. 功能拓展：启用 opts.current_line_blame = true 实时显示当前行的 blame 信息（作者、时间、提交信息）
-- 3. 快捷键拓展：添加快捷键实现 "暂存所有改动" "撤销所有暂存" "查看当前文件 Git 日志"
-- 4. 集成其他插件：结合 diffview.nvim 实现文件对比（点击改动块打开对比窗口）
-- 5. 自定义操作：添加自定义命令实现 "一键提交当前文件改动" "批量重置多个改动块"
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
-- 【完整功能清单】
-- 1. 跨文件查找：支持项目内所有文件的模糊查找、精确查找、正则查找
-- 2. 批量替换：实时预览替换结果，确认后批量修改（支持 undo 撤销）
-- 3. 多模式支持：普通文本模式、正则模式、整词匹配模式、大小写敏感模式
-- 4. 过滤功能：按文件类型、路径排除不需要查找的文件
-- 5. 简洁 UI：分窗口显示查找结果、替换输入框、操作按钮
-- 6. 快捷键支持：查找、替换、预览、确认等操作都有快捷键
-- 【个性化拓展方向】
-- 1. 样式定制：修改 opts.window 中的宽高、边框、颜色，适配自己的 UI 风格
-- 2. 功能拓展：启用 opts.enable_replace_mode = true 直接进入替换模式，添加过滤规则排除 node_modules、.git 等目录
-- 3. 快捷键拓展：添加快捷键实现 "查找当前选中的文本" "替换后自动保存文件" "导出查找结果到文件"
-- 4. 集成其他插件：结合 telescope 实现 "查找结果快速跳转"，结合 nvim-tree 实现 "按目录过滤查找"
-- 5. 自定义规则：添加自定义替换规则（如批量替换注释风格、变量名格式）
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
-- 【完整功能清单】
-- 1. 图形化 Git 操作：替代命令行，支持提交、分支切换、合并、拉取/推送、标签管理
-- 2. 状态显示：直观显示暂存/未暂存改动、分支信息、远程仓库状态
-- 3. 提交编辑：内置提交信息编辑器，支持模板、拼写检查
-- 4. 日志查看：显示项目/文件的 Git 日志，支持按作者、时间过滤
-- 5. 冲突解决：可视化显示合并冲突，提供便捷的冲突解决操作
-- 6. 多仓库支持：同时管理多个 Git 仓库，切换无压力
-- 【个性化拓展方向】
-- 1. 界面定制：修改 opts.ui 中的布局、颜色、图标，启用 opts.ui.conceal = false 显示更多详细信息
-- 2. 功能拓展：启用 opts.integrations.diffview = true 集成 diffview.nvim 实现更强大的对比功能
-- 3. 快捷键拓展：添加快捷键实现 "一键拉取远程分支" "一键创建并切换分支" "一键回滚到上一个提交"
-- 4. 提交模板：配置 opts.commit_template = "~/.config/nvim/git-commit-template" 自定义提交信息模板
-- 5. 集成其他插件：结合 gitsigns 实现 "在 neogit 中快速跳转到改动块"，结合 telescope 实现 "查找 Git 提交"
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
-- 【完整功能清单】
-- 1. 多模式跳转：基于单词、字符、行、正则表达式的快速跳转
-- 2. 可视化提示：输入目标字符后，在目标位置显示快捷键提示（如 "f" "j"）
-- 3. 自定义范围：支持在当前窗口、整个缓冲区、可视区域内跳转
-- 4. 快捷键定制：跳转触发键、提示键集合可配置
-- 5. 无延迟响应：触发跳转后立即显示提示，按下快捷键瞬间跳转
-- 【个性化拓展方向】
-- 1. 模式拓展：添加快捷键触发不同跳转模式（如 <leader>hw 单词跳转、<leader>hc 字符跳转、<leader>hl 行跳转）
-- 2. 样式定制：修改 opts.hint_offset = 1 让提示显示在目标字符前，调整 opts.hint_inline = false 让提示显示在右侧
-- 3. 功能拓展：启用 opts.case_insensitive = true 实现大小写不敏感跳转，添加 opts.current_line_only = true 仅在当前行跳转
-- 4. 集成其他插件：结合 telescope 实现 "跳转后查找"，结合 nvim-treesitter 实现 "基于语法节点跳转"
-- 5. 自定义规则：添加自定义跳转规则（如 "跳转到最近的括号" "跳转到函数定义"）
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
-- 【完整功能清单】
-- 1. 缩进线显示：在代码缩进处显示垂直虚线/实线，区分代码块层级
-- 2. 彩虹缩进：与 rainbow-delimiters 联动，实现不同层级缩进线不同颜色
-- 3. 排除规则：可排除指定文件类型、缓冲区、行范围不显示缩进线
-- 4. 自定义样式：缩进线的颜色、宽度、样式（虚线/实线）可配置
-- 5. 语法感知：基于 treesitter 语法解析，正确识别嵌套代码的缩进层级
-- 【个性化拓展方向】
-- 1. 样式定制：修改 opts.indent.char = "│" 让缩进线为实线，调整 opts.indent.width = 2 让缩进线宽度为 2 像素
-- 2. 功能拓展：启用 opts.scope = { enabled = true } 显示代码块范围线（如函数、循环的边界线）
-- 3. 文件类型细化：为 Python、Lua、JavaScript 等文件单独配置缩进线颜色（适配语言特性）
-- 4. 动态调整：添加快捷键实现 "增加缩进线透明度" "隐藏/显示缩进线" "切换彩虹模式"
-- 5. 集成其他插件：结合 nvim-treesitter 实现 "基于语法节点的缩进线高亮"，结合 vim-sleuth 自动适配文件缩进风格
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
-- 【完整功能清单】
-- 1. 多分区显示：底部状态栏分为左、中、右三区，可自定义显示内容
-- 2. 丰富组件：支持显示文件名称、路径、类型、编码、大小、Git 分支、LSP 状态、时间等
-- 3. 主题适配：自动适配当前 Neovim 主题，也可手动指定主题
-- 4. 插件联动：与 NvimTree、Telescope、gitsigns 等插件集成，显示相关状态
-- 5. 动态隐藏：支持在特定文件类型（如终端、文件树）隐藏状态栏
-- 6. 自定义组件：支持添加自定义函数作为状态栏组件（如显示天气、内存占用）
-- 【个性化拓展方向】
-- 1. 内容定制：在 lualine_x 区域添加 "LSP: %{vim.lsp.status()}" 显示 LSP 状态，在 lualine_c 区域添加文件路径（%:p:h）
-- 2. 样式优化：修改 component_separators 和 section_separators 为更美观的符号，调整字体大小和颜色
-- 3. 功能拓展：启用 opts.options.globalstatus = true 实现全局状态栏（所有窗口共用一个状态栏）
-- 4. 自定义组件：添加组件显示当前光标位置（行/列）、文件总行数、当前模式（normal/insert）
-- 5. 集成其他插件：结合 nvim-dap 显示调试状态，结合 battery.nvim 显示电池电量，结合 clock.nvim 显示实时时间
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
-- 【完整功能清单】
-- 1. 实时预览：在浏览器中实时显示 Markdown 文件渲染效果，修改后自动刷新
-- 2. 语法支持：支持标准 Markdown 语法，以及表格、代码块、公式（MathJax）、脚注、任务列表
-- 3. 代码高亮：预览中的代码块支持多种编程语言的语法高亮
-- 4. 自定义配置：预览端口、浏览器、刷新频率、主题可配置
-- 5. 快捷键支持：一键打开/关闭预览，切换预览主题
-- 【个性化拓展方向】
-- 1. 样式定制：修改 vim.g.mkdp_theme = "dark" 启用暗色预览主题，调整 vim.g.mkdp_preview_options 配置字体大小、行间距
-- 2. 功能拓展：启用 vim.g.mkdp_enable_mathjax = true 支持 LaTeX 公式，设置 vim.g.mkdp_open_to_the_world = true 允许局域网访问预览
-- 3. 快捷键拓展：添加快捷键实现 "预览窗口全屏" "导出预览为 PDF" "复制预览内容"
-- 4. 集成其他插件：结合 vim-markdown-composer 实现更强大的渲染（如 Mermaid 图表），结合 telescope 实现 "预览中查找内容"
-- 5. 自定义渲染：添加自定义 CSS 样式（vim.g.mkdp_custom_css），修改预览页面的颜色、布局
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
-- 【完整功能清单】
-- 1. 自动补全：输入左括号（(、[、{、"、'、`）时自动补全右括号
-- 2. 智能换行：光标在括号中间时按回车，自动换行并缩进（保持代码格式）
-- 3. 配对删除：删除左括号时自动删除对应的右括号（避免孤括号）
-- 4. 自定义规则：支持添加自定义配对（如 HTML 标签 <div></div>、Vue 模板 {{}}）
-- 5. 禁用场景：可在特定文件类型、特定模式下禁用自动补全
-- 6. 插件联动：与 nvim-cmp 集成，在自动补全菜单选中项后正确补全括号
-- 【个性化拓展方向】
-- 1. 规则拓展：添加自定义配对（如 opts.pairs = { { "(", ")" }, { "{", "}" }, { "<", ">" } }），支持 HTML 标签自动补全
-- 2. 功能优化：启用 opts.disable_in_visualblock = true 禁用可视块模式下的自动补全，设置 opts.enable_check_bracket_line = false 允许行内括号不配对
-- 3. 快捷键添加：添加快捷键手动触发括号补全、删除配对括号、切换自动补全启用状态
-- 4. 集成其他插件：结合 nvim-treesitter 实现 "基于语法的括号补全"（如函数参数括号），结合 vim-surround 实现括号嵌套补全
-- 5. 自定义行为：修改 opts.break_undo = false 让括号补全不打断撤销历史，调整 opts.map_cr = true 让回车时自动格式化括号内内容
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
-- 【完整功能清单】
-- 1. 基础 UI 组件：提供弹窗（Popup）、窗口（Window）、菜单（Menu）、输入框（Input）等组件
-- 2. 样式定制：组件的边框、颜色、大小、位置可配置
-- 3. 事件支持：组件支持点击、按键、关闭等事件回调
-- 4. 布局管理：支持组件嵌套、网格布局、弹性布局
-- 5. 跨平台兼容：适配不同终端和 Neovim GUI（如 Neovide、WezTerm）
-- 【个性化拓展方向】
-- 1. 自定义组件：基于 nui 的基础组件封装自己的 UI 组件（如通知弹窗、确认对话框）
-- 2. 插件开发：利用 nui 为自己的脚本/插件开发 UI 界面（如配置面板、数据可视化）
-- 3. 样式优化：为组件添加圆角边框、阴影效果、渐变颜色，适配自己的主题
-- 4. 集成其他插件：结合 telescope 实现自定义菜单，结合 noice 实现更美观的通知组件
-- 5. 交互增强：为组件添加动画效果（如弹窗淡入淡出）、键盘导航（如 Tab 切换菜单选项）
-- 注意：lazy = true 表示延迟加载（仅在其他插件调用时才加载）
-- ==============================================
config.nui = {
    "MunifTanjim/nui.nvim",  -- 插件 GitHub 地址
    lazy = true,  -- 延迟加载（优化启动速度）
}

-- ==============================================
-- 插件 15：nvim-scrollview（美化滚动条）
-- 【完整功能清单】
-- 1. 可视化滚动条：在右侧/左侧显示美观的滚动条，直观显示当前滚动位置
-- 2. 自定义样式：滚动条的颜色、宽度、透明度、形状可配置
-- 3. 功能拓展：支持显示搜索结果标记、LSP 诊断标记、Git 改动标记
-- 4. 排除规则：可排除指定文件类型不显示滚动条
-- 5. 动态适配：窗口大小变化时自动调整滚动条位置和长度
-- 【个性化拓展方向】
-- 1. 样式定制：修改 opts.color = "#888888" 调整滚动条颜色，设置 opts.width = 2 增加滚动条宽度
-- 2. 功能拓展：启用 opts.search_mark = true 显示搜索结果标记（滚动条上的小点点），启用 opts.diagnostics_mark = true 显示 LSP 诊断标记
-- 3. 位置调整：修改 opts.base = "left" 让滚动条显示在左侧，调整 opts.column = 2 让滚动条与行号间隔 2 列
-- 4. 交互增强：添加快捷键实现 "滚动到顶部" "滚动到底部" "滚动到指定行"，支持鼠标拖拽滚动条
-- 5. 集成其他插件：结合 gitsigns 显示 Git 改动标记在滚动条上，结合 nvim-dap 显示断点标记
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
-- 【完整功能清单】
-- 1. 全局透明：移除 Neovim 背景色，实现整个界面透明（适配壁纸）
-- 2. 选择性透明：可指定特定高亮组（如 NvimTree、Telescope）透明
-- 3. 主题兼容：切换主题时自动重新应用透明配置，避免冲突
-- 4. 缓存支持：通过缓存文件记住透明启用状态，下次启动自动生效
-- 5. 自定义透明：支持手动指定透明的高亮组，或排除不需要透明的组
-- 【个性化拓展方向】
-- 1. 范围调整：在 opts.extra_groups 中添加更多需要透明的高亮组（如 "TelescopePrompt" "FloatBorder"）
-- 2. 动态控制：添加快捷键实现 "切换透明状态" "调整透明度" "仅在特定文件类型启用透明"
-- 3. 样式优化：修改透明缓存逻辑，让透明状态随主题切换自动调整（如浅色主题禁用透明）
-- 4. 集成其他插件：结合 nvim-background 实现动态壁纸+透明背景，结合 winsep 让窗口分隔线也支持透明
-- 5. 精细控制：为不同插件单独配置透明（如 NvimTree 完全透明，Telescope 半透明）
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
-- 【完整功能清单】
-- 1. 文件系统可视化：左侧显示目录树，支持展开/折叠、文件/文件夹操作
-- 2. 基础操作：创建、删除、重命名、剪切、复制、粘贴文件/文件夹
-- 3. 插件联动：与 LSP 集成显示文件错误提示，与 Git 集成显示文件状态，与终端集成打开文件
-- 4. 过滤功能：可过滤隐藏文件、指定目录（如 node_modules）、文件类型
-- 5. 快捷键支持：所有操作都有对应的快捷键，支持鼠标操作
-- 6. 自定义样式：文件树宽度、位置、图标、颜色可配置
-- 【个性化拓展方向】
-- 1. 功能拓展：启用 opts.git.enable = true 显示 Git 状态（新增/修改/删除），启用 opts.renderer.icons.show.git = true 显示 Git 图标
-- 2. 样式定制：修改 opts.renderer.icons.glyphs 自定义文件/文件夹图标，调整 opts.view.width = 35 增加文件树宽度
-- 3. 快捷键拓展：添加快捷键实现 "刷新文件树" "搜索文件树中的文件" "打开当前目录终端"
-- 4. 集成其他插件：结合 telescope 实现 "文件树中快速查找文件"，结合 nvim-dap 实现 "在文件树中设置断点"
-- 5. 自定义操作：添加自定义命令实现 "一键删除 node_modules" "批量重命名文件" "导出文件树结构"
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
-- 【完整功能清单】
-- 1. 精准语法高亮：基于语法树的代码高亮（比正则高亮更准确，支持嵌套结构）
-- 2. 代码缩进：自动根据语法结构缩进（如函数、循环、条件语句）
-- 3. 代码折叠：基于语法节点的代码折叠（如折叠函数体、类、注释块）
-- 4. 导航功能：快速跳转到定义、引用、函数开头/结尾、语法节点
-- 5. 文本对象：支持基于语法的文本选择（如 "af" 选择整个函数，"ac" 选择整个类）
-- 6. 多语言支持：支持 100+ 编程语言，可动态安装解析器
-- 7. 插件依赖：为 indent-blankline、rainbow-delimiters、nvim-cmp 等插件提供语法支持
-- 【个性化拓展方向】
-- 1. 功能拓展：启用 opts.highlight.enable = true 增强语法高亮，启用 opts.incremental_selection.enable = true 支持语法节点增量选择
-- 2. 解析器管理：在 opts.ensure_installed 中添加更多编程语言（如 "rust" "go" "vue"），启用 opts.auto_install = true 自动安装解析器
-- 3. 自定义高亮：通过 vim.treesitter.highlight.create_highlight_group 自定义语法高亮颜色（如关键字、字符串、注释）
-- 4. 集成其他插件：结合 nvim-treesitter-context 显示当前代码上下文（如函数名），结合 nvim-treesitter-refactor 实现代码重构（重命名、提取函数）
-- 5. 自定义功能：添加自定义查询（query）实现特定语法的高亮/导航（如自定义 DSL 语言）
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
-- 【完整功能清单】
-- 1. 包围操作：添加、删除、替换代码的包围符号（括号、引号、标签、自定义符号）
-- 2. 多模式支持：普通模式、可视模式、插入模式都支持包围操作
-- 3. 嵌套支持：正确处理嵌套的包围符号（如 ((())) 中替换内层括号）
-- 4. 自定义包围：支持添加自定义包围符号（如 /* */、<!-- -->）
-- 5. 快捷键简洁：默认快捷键简洁（如 ys 添加、ds 删除、cs 替换）
-- 【个性化拓展方向】
-- 1. 自定义包围符号：通过 opts.surrounds 添加自定义包围规则（如 { "/*", "*/" } 注释包围、{ "<div>", "</div>" } HTML 标签包围）
-- 2. 快捷键拓展：添加快捷键实现 "一键包围选中代码为函数" "批量替换所有嵌套括号为方括号"
-- 3. 功能优化：启用 opts.move_cursor = "end" 让添加包围后光标移动到包围结束位置，设置 opts.keymaps.insert = "<C-s>" 插入模式快速添加包围
-- 4. 集成其他插件：结合 nvim-treesitter 实现 "基于语法节点的包围"（如包围整个函数体），结合 vim-visual-multi 实现多光标包围操作
-- 5. 场景适配：为不同文件类型配置专属包围规则（如 Python 中添加三重引号包围、JSON 中添加双引号包围）
-- 核心价值：简化代码包围操作（如给变量加引号、给代码块加括号），提升编辑效率
-- ==============================================
config["nvim-surround"] = {  -- 插件名带连字符，用[]包裹
    "kylechui/nvim-surround",  -- 插件 GitHub 地址
    version = "*",  -- 使用最新版
    event = "User IceLoad",  -- 加载时机：IceLoad 事件触发后
    opts = {},  -- 使用默认配置（新手无需修改）
}

-- ==============================================
-- 插件 20：oil.nvim（文件系统编辑工具）
-- 【完整功能清单】
-- 1. 缓冲区文件管理：在 Neovim 缓冲区中直接编辑文件系统（类似 Vim 的 netrw，但更强大）
-- 2. 基础操作：创建、删除、重命名、移动、复制文件/文件夹，支持批量操作
-- 3. 文本编辑模式：文件列表支持文本编辑（如批量重命名时直接修改文件名文本）
-- 4. 插件联动：与 nvim-cmp 集成实现文件名补全，与 telescope 集成实现文件搜索，与 gitsigns 集成显示 Git 状态
-- 5. 过滤功能：支持过滤隐藏文件、指定文件类型、大小超过限制的文件
-- 6. 跨协议支持：支持本地文件系统、SSH 远程文件系统、Git 仓库等
-- 【个性化拓展方向】
-- 1. 功能拓展：启用 opts.view_options.show_hidden = true 显示隐藏文件，设置 opts.adapter_aliases 配置远程文件系统别名（如 SSH 连接快捷名）
-- 2. 快捷键定制：添加快捷键实现 "一键打开当前目录" "批量删除选中文件" "导出文件列表到文本"
-- 3. 样式优化：修改 opts.float.border = "rounded" 启用圆角边框，调整 opts.columns 自定义文件列表显示列（如添加文件大小、修改时间）
-- 4. 集成其他插件：结合 telescope 实现 "在 oil 中快速搜索文件"，结合 nvim-dap 实现 "远程调试时通过 oil 管理文件"
-- 5. 自定义操作：添加自定义命令实现 "一键压缩文件夹" "批量修改文件权限" "同步本地与远程文件"
-- 适用场景：需要批量文件操作、远程文件管理的场景（比 nvim-tree 更适合文本编辑式文件管理）
-- ==============================================
config.oil = {
    "stevearc/oil.nvim",  -- 插件 GitHub 地址
    opts = {
        columns = { "icon", "permissions", "size", "mtime" },  -- 文件列表显示列：图标、权限、大小、修改时间
        delete_to_trash = true,  -- 删除文件到回收站（而非直接删除）
        skip_confirm_for_simple_edits = true,  -- 简单编辑（如重命名单个文件）跳过确认
        view_options = {
            show_hidden = false,  -- 不显示隐藏文件（.开头）
        },
        float = {
            border = "single",  -- 浮动窗口边框样式（single/double/rounded）
            padding = 2,  -- 窗口内边距
            max_width = 90,  -- 最大宽度
            max_height = 0,  -- 最大高度（0 表示自适应）
        },
        keymaps = {
            ["g?"] = "actions.show_help",  -- 显示帮助
            ["<CR>"] = "actions.select",  -- 选择文件/进入目录
            ["<C-s>"] = "actions.select_vsplit",  -- 垂直分屏打开
            ["<C-h>"] = "actions.select_split",  -- 水平分屏打开
            ["<C-t>"] = "actions.select_tab",  -- 新标签页打开
            ["<C-p>"] = "actions.preview",  -- 预览文件
            ["<C-c>"] = "actions.close",  -- 关闭窗口
            ["<C-l>"] = "actions.refresh",  -- 刷新文件列表
            ["-"] = "actions.parent",  -- 进入上级目录
            ["_"] = "actions.open_cwd",  -- 打开当前工作目录
            ["`"] = "actions.cd",  -- 进入选中目录（替换当前工作目录）
            ["~"] = "actions.tcd",  -- 进入选中目录（替换全局工作目录）
            ["g."] = "actions.toggle_hidden",  -- 切换显示/隐藏隐藏文件
        },
    },
    dependencies = { "nvim-tree/nvim-web-devicons" },  -- 依赖文件图标库（美化文件列表）
    keys = {
        { "-", "<CMD>Oil<CR>", desc = "文件：打开当前目录文件管理", silent = true },
    },
}

-- ==============================================
-- 插件 21：persistence.nvim（会话持久化）
-- 【完整功能清单】
-- 1. 会话保存：自动/手动保存当前 Neovim 会话（包括打开的文件、窗口布局、缓冲区、折叠状态、光标位置）
-- 2. 会话恢复：下次启动时恢复之前保存的会话，支持恢复特定会话、最近会话
-- 3. 多会话管理：支持创建多个会话（如不同项目的会话），切换、删除会话
-- 4. 自定义保存：可配置保存的内容（如是否保存终端、LSP 状态、插件配置）
-- 5. 自动触发：支持退出时自动保存会话、启动时自动恢复会话
-- 【个性化拓展方向】
-- 1. 功能拓展：启用 opts.autosave = true 自动保存会话，设置 opts.savedir = vim.fn.expand("~/.config/nvim/sessions") 自定义会话保存目录
-- 2. 会话过滤：添加 opts.ignored_buffers 配置忽略不需要保存的缓冲区（如终端、文件树）
-- 3. 快捷键拓展：添加快捷键实现 "保存当前会话" "删除当前会话" "列出所有会话并选择恢复"
-- 4. 集成其他插件：结合 telescope 实现 "会话搜索"，结合 nvim-tree 实现 "恢复会话时自动打开文件树"
-- 5. 场景适配：为不同项目配置专属会话（如工作项目、个人项目分开保存），设置会话自动过期时间（如 7 天未使用自动删除）
-- 核心价值：避免意外关闭 Neovim 后丢失工作状态，提升多项目切换效率
-- ==============================================
config.persistence = {
    "folke/persistence.nvim",  -- 插件 GitHub 地址
    event = "BufReadPre",  -- 加载时机：读取文件前（确保会话恢复不覆盖当前文件）
    opts = {
        dir = vim.fn.expand(vim.fn.stdpath "data" .. "/sessions/"),  -- 会话保存目录（~/.local/share/nvim/sessions/）
        options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals" },  -- 保存的选项：缓冲区、当前目录、标签页、窗口大小、帮助、全局变量
        pre_save = function()
            -- 保存会话前关闭文件树（避免恢复时文件树位置异常）
            pcall(vim.cmd, "NvimTreeClose")
        end,
    },
    keys = {
        { "<leader>qs", "<CMD>lua require('persistence').save()<CR>", desc = "会话：保存当前会话", silent = true },
        { "<leader>ql", "<CMD>lua require('persistence').load({ last = true })<CR>", desc = "会话：恢复最近会话", silent = true },
        { "<leader>qd", "<CMD>lua require('persistence').stop()<CR>", desc = "会话：停止会话持久化", silent = true },
    },
}

-- ==============================================
-- 插件 22：telescope.nvim（模糊查找工具）
-- 【完整功能清单】
-- 1. 多场景查找：文件查找、内容查找（grep）、缓冲区查找、命令历史查找、帮助文档查找、LSP 符号查找等
-- 2. 模糊匹配：支持模糊搜索、精确匹配、正则匹配、大小写不敏感匹配
-- 3. 预览功能：查找文件/内容时实时预览结果，无需打开文件
-- 4. 插件联动：与 LSP 集成查找定义/引用/实现，与 Git 集成查找提交记录/分支，与 nvim-tree 集成查找文件
-- 5. 自定义筛选：支持按文件类型、大小、修改时间筛选结果
-- 6. 快捷键操作：查找过程中支持快速打开、分屏打开、删除、复制等操作
-- 【个性化拓展方向】
-- 1. 功能拓展：安装 telescope-fzf-native.nvim 插件增强模糊匹配性能，启用 opts.defaults.file_ignore_patterns 过滤不需要查找的目录（如 node_modules）
-- 2. 样式定制：修改 opts.defaults.layout_config 调整窗口布局（如水平/垂直/浮动），设置 opts.defaults.borderchars 自定义边框符号
-- 3. 新增查找源：添加自定义查找源（如 "查找项目中的 TODO 注释" "查找最近修改的文件" "查找终端命令历史"）
-- 4. 快捷键拓展：添加快捷键实现 "查找当前选中的文本" "查找后替换内容" "导出查找结果到文件"
-- 5. 集成其他插件：结合 telescope-ui-select 用 telescope 替代 Neovim 默认选择界面，结合 telescope-dap 查找调试断点
-- 核心价值：Neovim 查找功能的核心，替代多个单一查找工具（如 fzf、ripgrep 前端）
-- ==============================================
config.telescope = {
    "nvim-telescope/telescope.nvim",  -- 插件 GitHub 地址
    dependencies = { "nvim-lua/plenary.nvim" },  -- 依赖工具函数库（异步、路径处理等）
    event = "User IceLoad",  -- 加载时机：IceLoad 事件触发后
    main = "telescope",  -- 插件入口模块
    opts = {
        defaults = {
            file_ignore_patterns = {  -- 查找时忽略的文件/目录
                "node_modules",  -- Node.js 依赖目录
                ".git",  -- Git 版本控制目录
                "dist",  -- 构建产物目录
                "build",  -- 构建目录
                "target",  -- Rust 构建目录
            },
            mappings = {
                i = {
                    ["<C-j>"] = "move_selection_next",  -- 插入模式：向下选择结果
                    ["<C-k>"] = "move_selection_previous",  -- 插入模式：向上选择结果
                    ["<C-n>"] = "cycle_history_next",  -- 插入模式：历史记录下一项
                    ["<C-p>"] = "cycle_history_prev",  -- 插入模式：历史记录上一项
                    ["<C-q>"] = "smart_send_to_qflist",  -- 插入模式：发送结果到快速修复列表
                },
                n = {
                    ["<C-j>"] = "move_selection_next",  -- 普通模式：向下选择结果
                    ["<C-k>"] = "move_selection_previous",  -- 普通模式：向上选择结果
                    ["<C-q>"] = "smart_send_to_qflist",  -- 普通模式：发送结果到快速修复列表
                },
            },
            layout_config = {
                horizontal = {
                    preview_width = 0.55,  -- 水平布局：预览窗口宽度占比（55%）
                    results_width = 0.8,  -- 水平布局：结果窗口宽度占比（80%）
                },
                vertical = {
                    mirror = false,  -- 垂直布局：不镜像显示
                },
                width = 0.87,  -- 整体宽度占比（87%）
                height = 0.80,  -- 整体高度占比（80%）
                preview_cutoff = 120,  -- 窗口宽度小于 120 时不显示预览
            },
        },
        pickers = {
            find_files = {
                theme = "dropdown",  -- 文件查找：下拉菜单主题
                previewer = false,  -- 文件查找：禁用预览（加快速度）
                hidden = true,  -- 文件查找：显示隐藏文件
            },
            live_grep = {
                theme = "dropdown",  -- 实时内容查找：下拉菜单主题
            },
            buffers = {
                theme = "dropdown",  -- 缓冲区查找：下拉菜单主题
                previewer = false,  -- 缓冲区查找：禁用预览
            },
        },
    },
    keys = {
        { "<leader>ff", "<Cmd>Telescope find_files<CR>", desc = "查找：文件", silent = true },
        { "<leader>fg", "<Cmd>Telescope live_grep<CR>", desc = "查找：内容（实时）", silent = true },
        { "<leader>fb", "<Cmd>Telescope buffers<CR>", desc = "查找：缓冲区", silent = true },
        { "<leader>fh", "<Cmd>Telescope help_tags<CR>", desc = "查找：帮助文档", silent = true },
        { "<leader>fc", "<Cmd>Telescope commands<CR>", desc = "查找：Neovim 命令", silent = true },
        { "<leader>fr", "<Cmd>Telescope oldfiles<CR>", desc = "查找：最近打开的文件", silent = true },
    },
}

-- ==============================================
-- 插件 23：todo-comments.nvim（TODO 注释管理）
-- 【完整功能清单】
-- 1. 注释高亮：自动高亮代码中的 TODO、FIXME、NOTE、BUG 等注释标签，颜色区分优先级
-- 2. 快速查找：一键列出项目中所有 TODO 注释，支持按标签、文件类型、优先级筛选
-- 3. 优先级支持：内置高/中/低优先级标签（如 HACK 高优先级、OPTION 低优先级），可自定义
-- 4. 跳转功能：从 TODO 列表快速跳转到对应的代码位置
-- 5. 自定义标签：支持添加自定义标签（如 FIXME、FEATURE、REFACTOR）及对应颜色
-- 6. 插件联动：与 telescope 集成实现 TODO 查找，与 gitsigns 集成显示 TODO 所在提交
-- 【个性化拓展方向】
-- 1. 标签拓展：在 opts.keywords 中添加自定义标签（如 { "FEATURE", icon = "✨", color = "#ffcb74" } 新功能标签）
-- 2. 样式定制：修改 opts.highlight = { before = "", after = ":" } 调整标签显示格式（如 "TODO: 待办"），设置 opts.colors 自定义标签颜色
-- 3. 功能拓展：启用 opts.merge_keywords = true 合并默认标签和自定义标签，设置 opts.search = { command = "rg", args = { "--hidden" } } 支持查找隐藏文件中的 TODO
-- 4. 快捷键拓展：添加快捷键实现 "创建 TODO 注释" "标记 TODO 为已完成" "按优先级筛选 TODO"
-- 5. 集成其他插件：结合 telescope 实现 "TODO 模糊查找"，结合 neorg 实现 "TODO 同步到笔记"，结合 persistence 实现 "保存 TODO 状态"
-- 适用场景：项目开发中管理待办事项、bug 修复、优化建议等注释
-- ==============================================
config["todo-comments"] = {  -- 插件名带连字符，用[]包裹
    "folke/todo-comments.nvim",  -- 插件 GitHub 地址
    dependencies = { "nvim-lua/plenary.nvim" },  -- 依赖工具函数库
    event = "User IceLoad",  -- 加载时机：IceLoad 事件触发后
    main = "todo-comments",  -- 插件入口模块
    opts = {
        signs = true,  -- 显示 TODO 符号（左侧行号旁）
        sign_priority = 8,  -- 符号优先级（数值越高越靠上）
        keywords = {  -- 内置标签配置（图标、颜色、优先级）
            FIX = { icon = symbols.Warn, color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
            TODO = { icon = symbols.Info, color = "info" },
            HACK = { icon = symbols.Warn, color = "warning" },
            WARN = { icon = symbols.Warn, color = "warning", alt = { "WARNING", "XXX" } },
            PERF = { icon = symbols.Info, color = "hint", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
            NOTE = { icon = symbols.Info, color = "hint", alt = { "INFO" } },
        },
        gui_style = {
            fg = "NONE",  -- 标签前景色（继承父高亮）
            bg = "BOLD",  -- 标签背景色（加粗）
        },
        merge_keywords = true,  -- 合并默认标签和自定义标签
        highlight = {
            multiline = true,  -- 高亮多行 TODO 注释
            multiline_pattern = "^.",  -- 多行匹配规则（任意字符开头）
            multiline_context = 10,  -- 多行注释上下文范围（前后 10 行）
            before = "",  -- 标签前的字符（空表示无）
            keyword = "wide",  -- 标签高亮范围（wide 表示全词）
            after = ":",  -- 标签后的字符（如 "TODO: 待办"）
        },
        colors = {  -- 标签颜色（对应 Neovim 高亮组）
            error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
            warning = { "DiagnosticWarn", "WarningMsg", "#FBBF24" },
            info = { "DiagnosticInfo", "#2563EB" },
            hint = { "DiagnosticHint", "#10B981" },
            default = { "Identifier", "#7C3AED" },
        },
        search = {
            command = "rg",  -- 查找命令（ripgrep，需系统安装）
            args = {
                "--color=never",
                "--no-heading",
                "--with-filename",
                "--line-number",
                "--column",
            },
            pattern = [[\b(KEYWORDS):]],  -- 查找正则（匹配标签+冒号）
        },
    },
    keys = {
        { "<leader>ut", "<Cmd>TodoTelescope<CR>", desc = "工具：查找所有 TODO 注释", silent = true },
    },
}

-- ==============================================
-- 插件 24：toggleterm.nvim（终端管理工具）
-- 【完整功能清单】
-- 1. 多终端管理：创建多个终端实例，支持命名、切换、关闭
-- 2. 灵活布局：支持水平分屏、垂直分屏、浮动窗口、全屏等终端布局
-- 3. 快捷键操作：一键打开/关闭终端、切换终端、发送命令到终端
-- 4. 集成支持：与 Neovim 缓冲区联动（如终端输出作为缓冲区内容），与 LSP 集成（如终端中运行编译命令）
-- 5. 自定义终端：支持配置默认终端命令、工作目录、字体大小、颜色
-- 6. 持久化终端：关闭终端窗口后不终止进程，重新打开可恢复之前状态
-- 【个性化拓展方向】
-- 1. 布局定制：修改 opts.direction = "float" 设置默认浮动终端，调整 opts.size = 20 设置水平分屏终端高度
-- 2. 功能拓展：启用 opts.open_mapping = [[<c-\>]] 绑定 Ctrl+\ 快速打开终端，设置 opts.shade_terminals = false 禁用终端阴影
-- 3. 终端类型拓展：添加自定义终端（如 Python 交互式终端、Git 终端、远程 SSH 终端），配置默认启动命令（如打开终端后自动激活虚拟环境）
-- 4. 快捷键拓展：添加快捷键实现 "新建终端" "关闭当前终端" "切换终端布局" "终端与编辑器切换焦点"
-- 5. 集成其他插件：结合 telescope 实现 "终端实例查找"，结合 nvim-dap 实现 "调试终端"，结合 oil 实现 "终端中快速切换目录"
-- 核心价值：替代系统终端，实现 Neovim 内无缝终端操作（无需切换窗口）
-- ==============================================
config.toggleterm = {
    "akinsho/toggleterm.nvim",  -- 插件 GitHub 地址
    version = "*",  -- 使用最新版
    event = "User IceLoad",  -- 加载时机：IceLoad 事件触发后
    opts = {
        open_mapping = [[<c-\>]],  -- 快速打开/关闭终端的快捷键（Ctrl+\）
        direction = "horizontal",  -- 终端布局方向（horizontal/vertical/float/tab）
        shade_terminals = true,  -- 启用终端阴影（增强视觉区分）
        shading_factor = 2,  -- 阴影强度（0-10，数值越高阴影越深）
        start_in_insert = true,  -- 打开终端后自动进入插入模式
        insert_mappings = true,  -- 插入模式下启用终端快捷键
        persist_size = true,  -- 持久化终端大小（关闭后重新打开保持原大小）
        close_on_exit = true,  -- 终端命令执行完成后自动关闭
        shell = vim.o.shell,  -- 使用系统默认 shell（如 bash/zsh/fish）
        float_opts = {
            border = "curved",  -- 浮动终端边框样式（curved/rounded/single/double）
            winblend = 0,  -- 浮动终端透明度（0 完全不透明）
            highlights = {
                border = "Normal",  -- 边框高亮组
                background = "Normal",  -- 背景高亮组
            },
        },
    },
    config = function(_, opts)
        require("toggleterm").setup(opts)  -- 加载 toggleterm 配置

        -- 定义 3 个自定义终端实例（不同布局和用途）
        local Terminal = require("toggleterm.terminal").Terminal

        -- 终端 1：浮动终端（默认命令：系统 shell）
        local float_term = Terminal:new({ direction = "float" })
        -- 快捷键：<leader>tf 打开浮动终端
        vim.keymap.set("n", "<leader>tf", function() float_term:toggle() end, { desc = "终端：打开浮动终端", silent = true })

        -- 终端 2：LazyGit 终端（Git 可视化工具，需系统安装 lazygit）
        local lazygit = Terminal:new({
            cmd = "lazygit",  -- 启动命令：lazygit
            direction = "float",  -- 浮动布局
            on_open = function(term)
                vim.cmd("startinsert!")  -- 打开后自动进入插入模式
                -- 终端内快捷键：q 关闭终端
                vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<Cmd>close<CR>", { noremap = true, silent = true })
            end,
            on_close = function()
                vim.cmd("startinsert!")  -- 关闭后回到插入模式
            end,
        })
        -- 快捷键：<leader>tg 打开 LazyGit 终端
        vim.keymap.set("n", "<leader>tg", function() lazygit:toggle() end, { desc = "终端：打开 LazyGit 终端", silent = true })

        -- 终端 3：Python 交互式终端（需系统安装 Python）
        local python = Terminal:new({
            cmd = "python",  -- 启动命令：python
            direction = "vertical",  -- 垂直分屏布局
            on_open = function(term)
                vim.cmd("startinsert!")
            end,
        })
        -- 快捷键：<leader>tp 打开 Python 终端
        vim.keymap.set("n", "<leader>tp", function() python:toggle() end, { desc = "终端：打开 Python 交互式终端", silent = true })
    end,
    keys = {
        { "<leader>th", "<Cmd>ToggleTerm direction=horizontal<CR>", desc = "终端：打开水平分屏终端", silent = true },
        { "<leader>tv", "<Cmd>ToggleTerm direction=vertical<CR>", desc = "终端：打开垂直分屏终端", silent = true },
        { "<leader>tt", "<Cmd>ToggleTerm<CR>", desc = "终端：切换终端显示/隐藏", silent = true },
    },
}

-- ==============================================
-- 插件 25：vim-illuminate（代码高亮增强）
-- 【完整功能清单】
-- 1. 标识符高亮：自动高亮当前光标下的标识符（变量、函数、类名等）在整个缓冲区的所有引用
-- 2. 语法感知：基于 LSP 或 treesitter 解析，精准识别标识符引用（支持跨文件引用高亮）
-- 3. 跳转功能：快速跳转到上一个/下一个标识符引用位置
-- 4. 自定义配置：高亮颜色、延迟时间、忽略的文件类型可配置
-- 5. 低性能消耗：仅在光标停留时高亮，不影响编辑流畅度
-- 【个性化拓展方向】
-- 1. 样式定制：修改 opts.under_cursor = false 取消光标下标识符的下划线，设置 opts.highlight_with_outline = true 用边框高亮引用
-- 2. 功能拓展：启用 opts.defer_setup = false 立即加载插件，设置 opts.filetypes_denylist = { "markdown", "terminal" } 排除不需要高亮的文件类型
-- 3. 快捷键拓展：添加快捷键实现 "高亮当前选中的标识符" "关闭/开启高亮" "跳转到标识符定义"
-- 4. 集成其他插件：结合 LSP 实现 "跨文件引用高亮"，结合 telescope 实现 "列出所有引用并筛选"，结合 nvim-dap 实现 "调试时高亮当前变量引用"
-- 5. 性能优化：调整 opts.min_count_to_highlight = 2 仅当引用次数≥2 时才高亮，设置 opts.update_in_insert = false 插入模式下不更新高亮
-- 适用场景：代码阅读、重构时快速定位变量/函数的所有引用
-- ==============================================
config["vim-illuminate"] = {  -- 插件名带连字符，用[]包裹
    "RRethy/vim-illuminate",  -- 插件 GitHub 地址
    event = "User IceAfter nvim-treesitter",  -- 加载时机：treesitter 加载完成后（依赖语法解析）
    opts = {
        delay = 100,  -- 光标停留后延迟 100ms 高亮（避免频繁触发）
        under_cursor = true,  -- 光标下的标识符添加下划线
        filetypes_allowlist = {},  -- 允许高亮的文件类型（空表示所有）
        filetypes_denylist = {  -- 禁止高亮的文件类型
            "dirvish",
            "fugitive",
            "alpha",
            "NvimTree",
            "packer",
            "neogitstatus",
            "Trouble",
            "lir",
            "Outline",
            "spectre_panel",
            "toggleterm",
            "DressingSelect",
            "TelescopePrompt",
        },
        modes_allowlist = {},  -- 允许高亮的模式（空表示所有）
        modes_denylist = {},  -- 禁止高亮的模式
        providers = {  -- 高亮提供器（优先使用 LSP，其次 treesitter）
            "lsp",
            "treesitter",
            "regex",
        },
        large_file_cutoff = nil,  -- 大文件 cutoff（nil 表示不限制）
        large_file_overrides = nil,  -- 大文件覆盖配置
        min_count_to_highlight = 1,  -- 最小引用次数（≥1 即高亮）
    },
    config = function(_, opts)
        require("illuminate").configure(opts)  -- 加载 illuminate 配置

        -- 自定义高亮组：修改引用高亮颜色（适配主题）
        vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "Visual" })  -- 文本引用高亮（复用 Visual 高亮）
        vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "Visual" })  -- 读取引用高亮
        vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "Visual" })  -- 写入引用高亮

        -- 快捷键：跳转到上一个/下一个引用
        vim.keymap.set("n", "<a-n>", "<Cmd>lua require('illuminate').goto_next_reference()<CR>", { desc = "高亮：跳转到下一个引用", silent = true })
        vim.keymap.set("n", "<a-p>", "<Cmd>lua require('illuminate').goto_prev_reference()<CR>", { desc = "高亮：跳转到上一个引用", silent = true })
    end,
}

-- ==============================================
-- 插件 26：which-key.nvim（快捷键提示工具）
-- 【完整功能清单】
-- 1. 快捷键可视化：按下前缀键（如 <leader>）后，显示所有绑定的快捷键及描述
-- 2. 分组提示：按功能分组显示快捷键（如 "缓冲区操作" "查找功能" "终端操作"）
-- 3. 延迟配置：可设置提示延迟时间（避免误触时显示）
-- 4. 自定义分组：支持自定义快捷键分组名称、图标、颜色
-- 5. 模糊搜索：支持在提示窗口中模糊搜索快捷键（按描述或按键）
-- 6. 插件联动：自动识别其他插件的快捷键（如 telescope、nvim-tree）并显示
-- 【个性化拓展方向】
-- 1. 样式定制：修改 opts.window.border = "rounded" 启用圆角提示窗口，调整 opts.layout = { spacing = 4 } 增加快捷键之间的间距
-- 2. 分组拓展：在 opts.plugins.presets 中启用更多预设分组（如 operators、motions），添加自定义分组（如 "AI 辅助" "笔记管理"）
-- 3. 快捷键补全：启用 opts.show_help = true 显示快捷键帮助信息，设置 opts.triggers = { "<leader>", "<localleader>", "g", "z", "<C-" } 增加触发前缀键
-- 4. 交互增强：添加快捷键实现 "在提示窗口中搜索" "隐藏/显示快捷键提示" "导出快捷键列表"
-- 5. 集成其他插件：结合 telescope 实现 "快捷键搜索"，结合 neorg 实现 "笔记快捷键单独提示"，结合 persistence 实现 "会话相关快捷键提示"
-- 核心价值：解决快捷键记不住的痛点，降低 Neovim 学习成本
-- ==============================================
config["which-key"] = {  -- 插件名带连字符，用[]包裹
    "folke/which-key.nvim",  -- 插件 GitHub 地址
    event = "VeryLazy",  -- 加载时机：极晚加载（优化启动速度）
    opts = {
        plugins = {
            marks = true,  -- 启用标记（mark）快捷键提示
            registers = true,  -- 启用寄存器快捷键提示
            spelling = {
                enabled = true,  -- 启用拼写检查快捷键提示
                suggestions = 20,  -- 拼写建议数量
            },
            presets = {
                operators = false,  -- 禁用操作符快捷键提示
                motions = false,  -- 禁用运动快捷键提示
                text_objects = false,  -- 禁用文本对象快捷键提示
                windows = true,  -- 启用窗口快捷键提示
                nav = true,  -- 启用导航快捷键提示
                z = true,  -- 启用折叠快捷键提示
                g = true,  -- 启用 g 前缀快捷键提示
            },
        },
        icons = {
            breadcrumb = "»",  -- 面包屑分隔符
            separator = "➜",  -- 快捷键与描述分隔符
            group = "+",  -- 分组标记
        },
        popup_mappings = {
            scroll_down = "<c-d>",  -- 提示窗口向下滚动（Ctrl+d）
            scroll_up = "<c-u>",  -- 提示窗口向上滚动（Ctrl+u）
        },
        window = {
            border = "single",  -- 提示窗口边框样式（single/double/rounded）
            position = "bottom",  -- 提示窗口位置（bottom/top）
            margin = { 1, 0, 1, 0 },  -- 窗口外边距（上、右、下、左）
            padding = { 2, 2, 2, 2 },  -- 窗口内边距
            winblend = 0,  -- 窗口透明度（0 完全不透明）
        },
        layout = {
            height = { min = 4, max = 25 },  -- 布局高度（最小 4 行，最大 25 行）
            width = { min = 20, max = 50 },  -- 布局宽度（最小 20 列，最大 50 列）
            spacing = 3,  -- 快捷键之间的间距
            align = "left",  -- 文本对齐方式（left/center/right）
        },
        hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " },  -- 隐藏的前缀（不显示在提示中）
        show_help = true,  -- 显示帮助信息（? 键）
        show_keys = true,  -- 显示快捷键
        triggers = "auto",  -- 触发方式（auto 自动触发，或指定前缀键）
        triggers_blacklist = {
            i = { "j", "k" },  -- 插入模式下不触发的键（避免影响编辑）
            v = { "j", "k" },  -- 可视模式下不触发的键
        },
        disable = {
            buftypes = {},  -- 禁用的缓冲区类型
            filetypes = { "TelescopePrompt" },  -- 禁用的文件类型（Telescope 查找时不显示）
        },
    },
    config = function(_, opts)
        local wk = require "which-key"
        wk.setup(opts)  -- 加载 which-key 配置

        -- 自定义快捷键分组（<leader> 前缀）
        wk.register({
            b = { name = " 缓冲区操作" },  -- 缓冲区操作分组（图标+名称）
            f = { name = "🔍 查找功能" },    -- 查找功能分组
            g = { name = "🐙 Git 操作" },     -- Git 操作分组
            q = { name = "💾 会话管理" },    -- 会话管理分组
            t = { name = "💻 终端操作" },    -- 终端操作分组
            u = { name = "🛠️  工具功能" },    -- 工具功能分组
            ["<tab>"] = { name = "📑 标签页操作" },  -- 标签页操作分组
        }, { prefix = "<leader>" })  -- 前缀键：<leader>（默认空格）
    end,
}

-- ==============================================
-- 插件 27：zen-mode.nvim（专注模式）
-- 【完整功能清单】
-- 1. 专注模式切换：一键进入/退出专注模式，隐藏无关 UI（如状态栏、行号、文件树）
-- 2. 窗口调整：进入专注模式后自动调整窗口大小（如居中显示、加宽编辑区）
-- 3. 自定义配置：可配置专注模式下的 UI 元素（如是否显示行号、折叠状态）
-- 4. 插件联动：与 twilight.nvim 集成（自动调暗非当前代码块），与 telescope 集成（专注模式下隐藏查找窗口）
-- 5. 快捷键支持：一键进入/退出专注模式，调整专注模式参数
-- 【个性化拓展方向】
-- 1. 样式定制：修改 opts.window.width = 0.8 调整专注模式窗口宽度占比，设置 opts.window.height = 0.9 调整高度占比
-- 2. 功能拓展：启用 opts.plugins.kitty = { enabled = true } 控制 Kitty 终端窗口大小（需 Kitty 终端支持），添加 opts.on_open 回调（进入专注模式时关闭文件树）
-- 3. 联动增强：集成 twilight.nvim 实现 "仅高亮当前代码块"，集成 nvim-transparent 实现 "专注模式下加深透明效果"
-- 4. 快捷键拓展：添加快捷键实现 "切换专注模式样式" "调整窗口大小" "快速退出专注模式"
-- 5. 场景适配：为不同文件类型配置专属专注模式（如 Markdown 写作时隐藏行号和符号列，代码编辑时保留行号）
-- 适用场景：需要集中注意力写作、编码时（减少 UI 干扰）
-- ==============================================
config["zen-mode"] = {  -- 插件名带连字符，用[]包裹
    "folke/zen-mode.nvim",  -- 插件 GitHub 地址
    opts = {
        window = {
            backdrop = 1,  -- 背景透明度（0-1，1 完全不透明）
            width = 120,  -- 专注模式窗口宽度（120 列）
            height = 1,  -- 专注模式窗口高度（1 表示全屏高度）
            options = {
                signcolumn = "no",  -- 隐藏符号列
                number = false,  -- 隐藏行号
                relativenumber = false,  -- 隐藏相对行号
                cursorline = false,  -- 隐藏光标行
                cursorcolumn = false,  -- 隐藏光标列
                foldcolumn = "0",  -- 隐藏折叠列
                list = false,  -- 隐藏列表字符（如制表符）
            },
        },
        plugins = {
            twilight = { enabled = true },  -- 启用 twilight 插件联动（调暗非当前代码块）
            gitsigns = { enabled = false },  -- 禁用 gitsigns（隐藏 Git 改动提示）
            tmux = { enabled = false },  -- 禁用 tmux 联动
            kitty = {
                enabled = false,  -- 禁用 Kitty 终端联动
                font = "+4",  -- Kitty 终端字体大小调整（+4 放大）
            },
            alacritty = {
                enabled = false,  -- 禁用 Alacritty 终端联动
                font = "14",  -- Alacritty 终端字体大小
            },
            notify = { enabled = false },  -- 禁用通知插件
            vimwiki = { enabled = false },  -- 禁用 vimwiki 插件
        },
        on_open = function()
            -- 进入专注模式时执行：关闭文件树
            pcall(vim.cmd, "NvimTreeClose")
        end,
        on_close = function()
            -- 退出专注模式时执行：无操作（可添加恢复 UI 的逻辑）
        end,
    },
    keys = {
        { "<leader>uz", "<Cmd>ZenMode<CR>", desc = "工具：切换专注模式", silent = true },
    },
}

-- ==============================================
-- 插件 28：twilight.nvim（代码块聚焦）
-- 【完整功能清单】
-- 1. 代码块调暗：自动识别当前代码块（函数、类、循环等），调暗其他区域（非当前代码块）
-- 2. 语法感知：基于 treesitter 语法解析，精准识别代码块边界
-- 3. 自定义配置：可配置调暗强度、忽略的代码块类型、启用的文件类型
-- 4. 插件联动：与 zen-mode 集成（专注模式下自动启用），与 nvim-treesitter 集成（依赖语法解析）
-- 5. 快捷键支持：一键启用/禁用代码块聚焦，调整调暗强度
-- 【个性化拓展方向】
-- 1. 样式定制：修改 opts.dimming.amount = 0.5 调整调暗强度（0-1，数值越高越暗），设置 opts.context = 10 增加当前代码块上下文范围（前后 10 行不调暗）
-- 2. 功能拓展：启用 opts.expand = { "function", "class", "method" } 仅对函数、类、方法启用调暗，添加 opts.exclude = { "markdown" } 排除不需要调暗的文件类型
-- 3. 联动增强：与 zen-mode 深度集成（专注模式下自动调整调暗强度），与 vim-illuminate 集成（同时高亮当前标识符和代码块）
-- 4. 快捷键拓展：添加快捷键实现 "切换调暗模式" "调整上下文范围" "快速聚焦到当前函数"
-- 5. 场景适配：为不同编程语言配置专属调暗规则（如 Python 聚焦类和函数，HTML 聚焦标签块）
-- 适用场景：阅读大文件、复杂代码时（减少视觉干扰，聚焦当前编辑区域）
-- ==============================================
config.twilight = {
    "folke/twilight.nvim",  -- 插件 GitHub 地址
    opts = {
        dimming = {
            alpha = 0.25,  -- 调暗透明度（0-1，0.25 表示 75% 亮度）
            color = { "Normal", "#ffffff" },  -- 调暗颜色（继承 Normal 高亮，白色）
            term_bg = "#000000",  -- 终端背景色
            inactive = false,  -- 非激活窗口是否调暗
        },
        context = 15,  -- 当前代码块上下文范围（前后 15 行不调暗）
        treesitter = true,  -- 启用 treesitter 语法解析
        expand = {  -- 支持调暗的代码块类型（基于 treesitter 节点）
            "function",
            "method",
            "table",
            "if_statement",
            "for_statement",
            "for_in_statement",
            "class",
            "struct",
            "try_statement",
            "catch_statement",
            "while_statement",
            "function_declaration",
            "block",
            "argument_list",
            "object",
            "dictionary",
        },
        exclude = {},  -- 排除的文件类型（空表示所有文件类型都支持）
    },
}

-- ==============================================
-- 插件 29：neodev.nvim（Lua 开发增强）
-- 【完整功能清单】
-- 1. Neovim API 补全：为 Neovim Lua API（如 vim.api、vim.fn）提供精准的自动补全和类型提示
-- 2. 插件开发支持：为 Lua 插件开发提供环境（如 nvim-treesitter、telescope 等插件的 API 补全）
-- 3. 文档提示：补全时显示 API 文档（参数说明、返回值、示例）
-- 4. 类型定义：自动生成 Neovim API 的类型定义文件（支持 LSP 类型检查）
-- 5. 自定义配置：支持配置需要补全的插件、API 版本、类型提示深度
-- 【个性化拓展方向】
-- 1. 功能拓展：启用 opts.library.plugins = true 为所有已安装的 Lua 插件提供 API 补全，设置 opts.library.types = true 启用 Neovim 类型定义补全
-- 2. 开发优化：添加 opts.setup_jsonls = true 自动配置 jsonls LSP（支持 plugin.json 补全），设置 opts.override = function(root_dir, options) ... end 自定义 LSP 配置
-- 3. 集成其他插件：结合 nvim-cmp 实现 "Lua API 补全优先级提升"，结合 lua-language-server 实现 "类型检查增强"
-- 4. 场景适配：为不同开发场景配置专属补全（如插件开发时启用所有 API 补全，普通 Lua 脚本开发时仅启用基础 API）
-- 5. 文档增强：集成 neogen 实现 "Lua 函数注释自动生成"，结合 vim-doge 实现 "API 文档快速查看"
-- 适用场景：Neovim 配置编写、Lua 插件开发（提升开发效率和代码正确性）
-- ==============================================
config.neodev = {
    "folke/neodev.nvim",  -- 插件 GitHub 地址
    opts = {
        library = {
            enabled = true,  -- 启用库补全
            runtime = true,  -- 启用 Neovim 运行时 API 补全
            types = true,    -- 启用 Neovim 类型定义补全
            plugins = true,  -- 启用已安装 Lua 插件的 API 补全
        },
        setup_jsonls = false,  -- 不自动配置 jsonls LSP（手动配置更灵活）
        lspconfig = true,      -- 自动集成到 LSP 配置
        pathStrict = true,     -- 严格路径检查（避免补全无关 API）
    },
}

-- ==============================================
-- 插件 30：mason.nvim + mason-lspconfig.nvim（LSP 管理工具）
-- 【完整功能清单】
-- 1. LSP 自动安装：图形化界面管理 LSP 服务器，支持一键安装、更新、卸载
-- 2. 版本管理：自动下载对应系统的 LSP 服务器版本，支持指定版本安装
-- 3. 配置联动：mason-lspconfig 自动将安装的 LSP 服务器与 nvim-lspconfig 关联，无需手动配置
-- 4. 多语言支持：支持 100+ 编程语言的 LSP 服务器（如 Python、Lua、JavaScript、Rust 等）
-- 5. 插件联动：与 nvim-lspconfig 集成（自动配置 LSP 服务器），与 telescope 集成（LSP 功能查找）
-- 【个性化拓展方向】
-- 1. 自动安装：在 opts.ensure_installed 中添加常用 LSP 服务器（如 "pyright" "lua_ls" "tsserver"），启动时自动安装缺失的 LSP
-- 2. 镜像配置：设置 opts.ui.check_outdated_packages_on_open = false 关闭启动时检查更新，配置 opts.install_root_dir = vim.fn.expand("~/.config/nvim/mason") 自定义安装目录（解决网络问题可配置国内镜像）
-- 3. LSP 定制：通过 mason-lspconfig 的 handlers 配置特定 LSP 的参数（如 pyright 启用类型检查，lua_ls 忽略未使用变量警告）
-- 4. 快捷键拓展：添加快捷键打开 Mason 管理界面、更新所有 LSP 服务器、查看 LSP 安装状态
-- 5. 集成其他插件：结合 null-ls 实现 "LSP 格式化工具自动安装"，结合 nvim-dap 实现 "调试器自动安装"
-- 核心价值：简化 LSP 服务器的安装和配置（替代手动下载、配置环境变量）
-- ==============================================
config.mason = {
    "williamboman/mason.nvim",  -- 插件 GitHub 地址
    build = ":MasonUpdate",  -- 安装/更新时执行：更新 Mason 自身
    opts = {
        ui = {
            icons = {
                package_installed = symbols.Check,    -- 已安装图标
                package_pending = symbols.Loading,   -- 安装中图标
                package_uninstalled = symbols.Error,  -- 未安装图标
            },
        },
        ensure_installed = {  -- 确保安装的 LSP 服务器/工具（按需添加）
            "lua_ls",        -- Lua LSP
            "pyright",       -- Python LSP
            "tsserver",      -- TypeScript/JavaScript LSP
            "gopls",         -- Go LSP
            "rust_analyzer", -- Rust LSP
            "html",          -- HTML LSP
            "cssls",         -- CSS LSP
            "jsonls",        -- JSON LSP
            "bashls",        -- Bash LSP
            "lemminx",       -- XML LSP
            "typst_lsp",     -- Typst LSP
            "clangd",        -- C/C++ LSP
        },
    },
}

config["mason-lspconfig"] = {  -- 插件名带连字符，用[]包裹
    "williamboman/mason-lspconfig.nvim",  -- 插件 GitHub 地址
    dependencies = { "williamboman/mason.nvim" },  -- 依赖 Mason
    opts = {
        automatic_installation = true,  -- 自动安装 LSP 服务器（检测到项目需要时）
        handlers = nil,  -- 自定义 LSP 配置处理器（nil 表示使用默认）
    },
}

-- ==============================================
-- 插件 31：nvim-lspconfig（LSP 核心配置）
-- 【完整功能清单】
-- 1. LSP 服务器配置：为每个 LSP 服务器提供统一的配置接口（如端口、根目录、初始化参数）
-- 2. 核心 LSP 功能：代码补全、语法检查、格式化、定义跳转、引用查找、重命名、代码动作等
-- 3. 自定义回调：支持配置 LSP 事件回调（如初始化完成、诊断更新、服务器退出）
-- 4. 多服务器支持：同时配置多个 LSP 服务器（如一个文件类型对应多个 LSP）
-- 5. 插件联动：与 nvim-cmp 集成（代码补全），与 telescope 集成（LSP 功能查找），与 fidget.nvim 集成（LSP 进度提示）
-- 【个性化拓展方向】
-- 1. 服务器定制：为每个 LSP 服务器配置专属参数（如 lua_ls 配置 runtime.path 包含 Neovim 配置目录，pyright 配置 python.analysis.extraPaths 添加项目依赖路径）
-- 2. 功能增强：启用代码格式化（通过 lsp-format 插件），配置诊断虚拟文本（vim.diagnostic.config({ virtual_text = true })），设置 LSP 快捷键（如 gd 跳转定义、gr 查找引用）
-- 3. 性能优化：调整 opts.capabilities.textDocument.completion.completionItem.snippetSupport = true 启用代码片段补全，设置 LSP 超时时间（opts.settings = { lua_ls = { telemetry = { enable = false } } } 禁用遥测）
-- 4. 集成其他插件：结合 null-ls 实现 "LSP 未支持的格式化工具"（如 black、prettier），结合 nvim-dap 实现 "LSP 调试集成"，结合 vim-illuminate 实现 "跨文件引用高亮"
-- 5. 场景适配：为不同项目配置专属 LSP（如工作项目启用严格类型检查，个人项目禁用部分警告）
-- 核心价值：Neovim 现代化代码编辑的核心（提供 IDE 级别的代码辅助功能）
-- ==============================================
config["lspconfig"] = {  -- 插件名带连字符，用[]包裹
    "neovim/nvim-lspconfig",  -- 插件 GitHub 地址
    dependencies = {
        "williamboman/mason-lspconfig.nvim",  -- 依赖 mason-lspconfig（LSP 安装联动）
        "folke/neodev.nvim",                  -- 依赖 neodev（Lua LSP 增强）
    },
    event = "User IceLoad",  -- 加载时机：IceLoad 事件触发后
    config = function()
        local lspconfig = require "lspconfig"  -- 引入 nvim-lspconfig
        local capabilities = require("cmp_nvim_lsp").default_capabilities()  -- 引入 nvim-cmp 增强的 LSP 能力

        -- 通用 LSP 配置（所有 LSP 服务器共享）
        local on_attach = function(client, bufnr)
            -- 快捷键：仅在当前 LSP 缓冲区生效
            local opts = { buffer = bufnr, silent = true }

            -- LSP 核心快捷键
            vim.keymap.set("n", "gd", "<Cmd>Telescope lsp_definitions<CR>", vim.tbl_extend("force", opts, { desc = "LSP：跳转定义" }))
            vim.keymap.set("n", "gr", "<Cmd>Telescope lsp_references<CR>", vim.tbl_extend("force", opts, { desc = "LSP：查找引用" }))
            vim.keymap.set("n", "gi", "<Cmd>Telescope lsp_implementations<CR>", vim.tbl_extend("force", opts, { desc = "LSP：查找实现" }))
            vim.keymap.set("n", "gt", "<Cmd>Telescope lsp_type_definitions<CR>", vim.tbl_extend("force", opts, { desc = "LSP：跳转类型定义" }))
            vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "LSP：显示文档" }))
            vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "LSP：显示签名帮助" }))
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "LSP：重命名" }))
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "LSP：代码动作" }))
            vim.keymap.set("n", "<leader>f", function() vim.lsp.buf.format { async = true } end, vim.tbl_extend("force", opts, { desc = "LSP：格式化代码" }))

            -- 禁用 LSP 自带的格式化（使用专门的格式化插件如 null-ls）
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
        end

        -- 配置已安装的 LSP 服务器（与 mason 中 ensure_installed 对应）
        local servers = {
            "lua_ls", "pyright", "tsserver", "gopls", "rust_analyzer",
            "html", "cssls", "jsonls", "bashls", "lemminx", "typst_lsp", "clangd",
        }

        for _, server in ipairs(servers) do
            -- 特殊配置：Lua LSP（lua_ls）
            if server == "lua_ls" then
                lspconfig[server].setup {
                    on_attach = on_attach,
                    capabilities = capabilities,
                    settings = {
                        Lua = {
                            runtime = { version = "LuaJIT" },  -- 使用 LuaJIT 运行时
                            diagnostics = {
                                globals = { "vim", "Ice" },  -- 识别全局变量 vim 和 Ice
                            },
                            workspace = {
                                checkThirdParty = false,
                                library = vim.api.nvim_get_runtime_file("", true),  -- 包含 Neovim 运行时目录
                            },
                            telemetry = { enable = false },  -- 禁用遥测
                        },
                    },
                }
            -- 特殊配置：Python LSP（pyright）
            elseif server == "pyright" then
                lspconfig[server].setup {
                    on_attach = on_attach,
                    capabilities = capabilities,
                    settings = {
                        python = {
                            analysis = {
                                autoSearchPaths = true,
                                useLibraryCodeForTypes = true,
                                diagnosticMode = "workspace",  -- 工作区级别的诊断
                            },
                        },
                    },
                }
            -- 其他 LSP 服务器使用默认配置
            else
                lspconfig[server].setup {
                    on_attach = on_attach,
                    capabilities = capabilities,
                }
            end
        end

        -- LSP 诊断配置（全局）
        vim.diagnostic.config {
            virtual_text = {
                prefix = symbols.Info,  -- 诊断虚拟文本前缀图标
                spacing = 4,  -- 虚拟文本间距
            },
            signs = true,  -- 显示诊断符号（左侧行号旁）
            update_in_insert = false,  -- 插入模式下不更新诊断
            underline = true,  -- 下划线标记诊断行
            severity_sort = true,  -- 按严重程度排序诊断
            float = {
                border = "rounded",  -- 诊断浮动窗口圆角边框
                source = "always",  -- 显示诊断来源（如 LSP 服务器名称）
            },
        }

        -- 自定义诊断符号（左侧行号旁）
        local signs = { Error = symbols.Error, Warn = symbols.Warn, Info = symbols.Info, Hint = symbols.Hint }
        for type, icon in pairs(signs) do
            local hl = "DiagnosticSign" .. type
            vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
        end
    end,
}

-- ==============================================
-- 插件 32：nvim-cmp + 补全源插件（代码补全框架）
-- 【完整功能清单】
-- 1. 多源补全：支持 LSP 补全、缓冲区补全、路径补全、字典补全、代码片段补全、命令补全
-- 2. 智能排序：补全项按优先级排序（如 LSP 补全优先于缓冲区补全）
-- 3. 自定义样式：补全菜单的边框、颜色、图标、选中效果可配置
-- 4. 交互增强：支持补全项预览、文档显示、快捷键选择、自动补全触发条件
-- 5. 插件联动：与 LSP 集成（LSP 补全源），与 treesitter 集成（语法感知补全），与 snippets 插件集成（代码片段补全）
-- 【个性化拓展方向】
-- 1. 补全源拓展：添加更多补全源（如 cmp-git  Git 提交信息补全、cmp-emoji 表情补全、cmp-latex-symbols LaTeX 符号补全）
-- 2. 样式定制：修改 opts.window.completion.border = "rounded" 启用补全菜单圆角边框，设置 opts.formatting.fields = { "kind", "abbr", "menu" } 调整补全项显示字段（图标、缩写、描述）
-- 3. 功能优化：启用 opts.completion.completeopt = "menu,menuone,noselect" 补全行为，设置 opts.mapping["<Tab>"] = cmp.mapping.select_next_item() 绑定 Tab 键选择下一个补全项
-- 4. 代码片段：集成 LuaSnip 插件实现代码片段补全（如输入 "for" 自动补全 for 循环模板），自定义代码片段（如常用函数、注释模板）
-- 5. 场景适配：为不同文件类型配置专属补全源（如 Markdown 文件启用 emoji 和 LaTeX 符号补全，Python 文件启用 LSP 和路径补全）
-- 核心价值：Neovim 代码补全核心（提供 IDE 级别的智能补全体验）
-- ==============================================
config["nvim-cmp"] = {  -- 插件名带连字符，用[]包裹
    "hrsh7th/nvim-cmp",  -- 插件 GitHub 地址
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",  -- LSP 补全源
        "hrsh7th/cmp-buffer",    -- 缓冲区补全源（当前文件内容）
        "hrsh7th/cmp-path",      -- 路径补全源（文件/目录路径）
        "hrsh7th/cmp-cmdline",   -- 命令补全源（: 命令行）
        "saadparwaiz1/cmp_luasnip",  -- LuaSnip 代码片段补全源
        "L3MON4D3/LuaSnip",      -- 代码片段引擎
        "onsails/lspkind.nvim",  -- 补全项图标美化
    },
    event = { "InsertEnter", "CmdlineEnter" },  -- 加载时机：插入模式或命令行模式进入时
    config = function()
        local cmp = require "cmp"  -- 引入 nvim-cmp
        local luasnip = require "luasnip"  -- 引入 LuaSnip
        local lspkind = require "lspkind"  -- 引入 lspkind（图标美化）

        -- 代码片段：添加默认代码片段（可自定义）
        luasnip.add_snippets("all", {
            -- 通用代码片段：TODO 注释
            luasnip.snippet({ trig = "todo", name = "TODO Comment" }, {
                luasnip.text_node({ "TODO: " }),
                luasnip.insert_node(0),  -- 光标位置
            }),
            -- 通用代码片段：函数注释（示例）
            luasnip.snippet({ trig = "fn", name = "Function Comment" }, {
                luasnip.text_node({ "/**", " * " }),
                luasnip.insert_node(0, "Function description"),
                luasnip.text_node({ "", " */" }),
            }),
        })

        -- nvim-cmp 核心配置
        cmp.setup {
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)  -- 使用 LuaSnip 展开代码片段
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),  -- 下一个补全项
                ["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),  -- 上一个补全项
                ["<C-b>"] = cmp.mapping.scroll_docs(-4),  -- 向上滚动补全文档
                ["<C-f>"] = cmp.mapping.scroll_docs(4),   -- 向下滚动补全文档
                ["<C-Space>"] = cmp.mapping.complete(),   -- 手动触发补全
                ["<C-e>"] = cmp.mapping.abort(),          -- 取消补全
                ["<CR>"] = cmp.mapping.confirm({ select = true }),  -- 确认选中的补全项
                ["<Tab>"] = cmp.mapping(function(fallback)
                    -- Tab 键：展开代码片段或选择下一个补全项
                    if luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                    else
                        fallback()
                    end
                end, { "i", "s" }),
                ["<S-Tab>"] = cmp.mapping(function(fallback)
                    -- Shift+Tab 键：回退代码片段或选择上一个补全项
                    if luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, { "i", "s" }),
            }),
            sources = cmp.config.sources({
                { name = "nvim_lsp" },    -- LSP 补全（优先级最高）
                { name = "luasnip" },     -- 代码片段补全
                { name = "path" },        -- 路径补全
                { name = "buffer" },      -- 缓冲区补全（优先级最低）
            }),
            formatting = {
                format = lspkind.cmp_format({
                    mode = "symbol_text",  -- 显示模式：图标+文本
                    maxwidth = 50,         -- 补全项最大宽度
                    ellipsis_char = "...", -- 溢出省略字符
                    -- 自定义补全项图标
                    symbol_map = {
                        Text = symbols.Text,
                        Method = symbols.Method,
                        Function = symbols.Function,
                        Constructor = symbols.Constructor,
                        Field = symbols.Field,
                        Variable = symbols.Variable,
                        Class = symbols.Class,
                        Interface = symbols.Interface,
                        Module = symbols.Module,
                        Property = symbols.Property,
                        Unit = symbols.Unit,
                        Value = symbols.Value,
                        Enum = symbols.Enum,
                        Keyword = symbols.Keyword,
                        Snippet = symbols.Snippet,
                        Color = symbols.Color,
                        File = symbols.File,
                        Reference = symbols.Reference,
                        Folder = symbols.Folder,
                        EnumMember = symbols.EnumMember,
                        Constant = symbols.Constant,
                        Struct = symbols.Struct,
                        Event = symbols.Event,
                        Operator = symbols.Operator,
                        TypeParameter = symbols.TypeParameter,
                    },
                }),
            },
            window = {
                completion = cmp.config.window.bordered({
                    border = "rounded",  -- 补全菜单圆角边框
                    winhighlight = "Normal:CmpPmenu,CursorLine:CmpSel,Search:None",
                }),
                documentation = cmp.config.window.bordered({
                    border = "rounded",  -- 文档窗口圆角边框
                }),
            },
            experimental = {
                ghost_text = false,  -- 禁用幽灵文本（补全预览）
            },
        }

        -- 命令行模式补全配置（: 开头）
        cmp.setup.cmdline("/", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
                { name = "buffer" },  -- 缓冲区补全（搜索命令时）
            },
        })

        cmp.setup.cmdline(":", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({
                { name = "path" },  -- 路径补全（命令行参数为路径时）
            }, {
                { name = "cmdline" },  -- 命令补全（命令名称）
            }),
        })
    end,
}

-- ==============================================
-- 插件 33：null-ls.nvim（非 LSP 工具集成）
-- 【完整功能清单】
-- 1. 工具集成：将非 LSP 工具（格式化工具、代码检查工具、代码动作工具）集成到 LSP 框架中
-- 2. 多工具支持：支持 100+ 工具（如 black、prettier、flake8、eslint、shellcheck 等）
-- 3. LSP 兼容：通过 LSP 接口提供功能（如格式化、诊断、代码动作），与 nvim-lspconfig 无缝联动
-- 4. 自定义工具：支持添加自定义脚本/工具作为 null-ls 源（如自定义格式化脚本）
-- 5. 动态启用：根据项目配置（如 .prettierrc、flake8.cfg）自动启用对应的工具
-- 【个性化拓展方向】
-- 1. 工具拓展：添加常用工具（如 "black" Python 格式化、"prettier" 前端格式化、"flake8" Python 代码检查、"eslint" JavaScript 代码检查）
-- 2. 功能定制：为每个工具配置专属参数（如 black 配置 line-length=120，prettier 配置 singleQuote=true）
-- 3. 联动增强：与 mason 集成（自动安装 null-ls 依赖的工具），与 nvim-cmp 集成（提供代码检查结果补全）
-- 4. 自定义源：添加自定义工具源（如公司内部代码规范检查工具、个人格式化脚本）
-- 5. 场景适配：为不同项目配置专属工具（如工作项目使用公司指定格式化工具，个人项目使用自定义工具）
-- 核心价值：补充 LSP 功能（LSP 不支持的格式化、代码检查），统一工具调用接口
-- ==============================================
config["null-ls"] = {  -- 插件名带连字符，用[]包裹
    "jose-elias-alvarez/null-ls.nvim",  -- 插件 GitHub 地址
    dependencies = { "nvim-lua/plenary.nvim" },  -- 依赖工具函数库
    event = "User IceLoad",  -- 加载时机：IceLoad 事件触发后
    config = function()
        local null_ls = require "null-ls"  -- 引入 null-ls
        local formatting = null_ls.builtins.formatting  -- 格式化工具组
        local diagnostics = null_ls.builtins.diagnostics  -- 诊断工具组
        local code_actions = null_ls.builtins.code_actions  -- 代码动作工具组

        -- 配置 null-ls 源（工具）
        null_ls.setup {
            sources = {
                -- 格式化工具
                formatting.black.with({ extra_args = { "--line-length", "120" } }),  -- Python 格式化（行宽 120）
                formatting.prettier.with({ extra_args = { "--single-quote", "true" } }),  -- 前端格式化（单引号）
                formatting.stylua,  -- Lua 格式化
                formatting.gofmt,   -- Go 格式化
                formatting.rustfmt, -- Rust 格式化
                formatting.shfmt,   -- Shell 格式化
                formatting.clang_format,  -- C/C++ 格式化

                -- 诊断工具
                diagnostics.flake8.with({ extra_args = { "--max-line-length", "120" } }),  -- Python 代码检查（行宽 120）
                diagnostics.eslint,  -- JavaScript/TypeScript 代码检查
                diagnostics.shellcheck,  -- Shell 脚本检查
                diagnostics.luacheck.with({ extra_args = { "--globals", "vim" } }),  -- Lua 代码检查（识别 vim 全局变量）
                diagnostics.golangci_lint,  -- Go 代码检查
                diagnostics.clang_check,  -- C/C++ 代码检查

                -- 代码动作工具
                code_actions.shellcheck,  -- Shell 脚本修复建议
                code_actions.eslint,  -- JavaScript/TypeScript 修复建议
                code_actions.gitsigns,  -- Git 相关代码动作（如放弃修改、暂存）
            },
            -- 格式化触发配置（与 LSP 格式化统一）
            on_attach = function(client, bufnr)
                -- 快捷键：格式化当前缓冲区（与 LSP 共用快捷键）
                vim.keymap.set("n", "<leader>f", function()
                    vim.lsp.buf.format({
                        filter = function(fmt_client)
                            -- 优先使用 null-ls 格式化（避免 LSP 格式化冲突）
                            return fmt_client.name == "null-ls"
                        end,
                        async = true,
                    })
                end, { buffer = bufnr, desc = "格式化：代码（null-ls）", silent = true })
            end,
        }
    end,
}

-- ==============================================
-- 插件 34：nvim-dap（调试器框架）
-- 【完整功能清单】
-- 1. 多语言调试：支持 Python、Lua、JavaScript、Rust、Go、C/C++ 等多种语言调试
-- 2. 核心调试功能：设置断点、单步执行、步入/步出函数、变量查看、表达式求值、调用栈查看
-- 3. 配置灵活：支持自定义调试器路径、启动参数、环境变量、断点条件
-- 4. 插件联动：与 nvim-dap-ui 集成（可视化调试界面），与 mason 集成（自动安装调试器），与 LSP 集成（基于 LSP 查找调试入口）
-- 5. 会话管理：支持保存/加载调试会话，多调试会话并行
-- 【个性化拓展方向】
-- 1. 调试器拓展：为不同语言配置专属调试器（如 Python 使用 debugpy、Lua 使用 luadbg、Rust 使用 lldb-vscode）
-- 2. 界面定制：通过 nvim-dap-ui 配置调试面板布局（变量面板、调用栈面板、控制台面板位置）
-- 3. 功能增强：添加断点日志（断点处输出日志而不中断执行）、条件断点（满足条件才触发）、命中次数断点（触发指定次数后中断）
-- 4. 快捷键拓展：添加快捷键实现 "快速设置断点" "重启调试" "终止调试" "查看全局变量"
-- 5. 集成其他插件：结合 telescope 实现 "查找断点" "查找调试配置"，结合 nvim-tree 实现 "调试时查看文件结构"，结合 which-key 实现 "调试快捷键提示"
-- 核心价值：Neovim 内置调试解决方案（替代外部调试工具，实现编辑器内无缝调试）
-- ==============================================
config["nvim-dap"] = {  -- 插件名带连字符，用[]包裹
    "mfussenegger/nvim-dap",  -- 插件 GitHub 地址
    dependencies = {
        "rcarriga/nvim-dap-ui",  -- 调试可视化界面
        "theHamsta/nvim-dap-virtual-text",  -- 调试虚拟文本（变量值显示）
        "williamboman/mason.nvim",  -- 依赖 mason 自动安装调试器
    },
    config = function()
        local dap = require "dap"  -- 引入 nvim-dap
        local dapui = require "dapui"  -- 引入 nvim-dap-ui
        local dap_virtual_text = require "nvim-dap-virtual-text"  -- 引入虚拟文本插件

        -- 初始化调试可视化界面
        dapui.setup {
            layouts = {
                {
                    elements = {
                        "scopes",  -- 变量作用域面板
                        "breakpoints",  -- 断点面板
                        "stacks",  -- 调用栈面板
                        "watches",  -- 监视表达式面板
                    },
                    size = 40,  -- 左侧面板宽度（列数）
                    position = "left",  -- 左侧布局
                },
                {
                    elements = {
                        "repl",  -- 调试控制台（输入命令）
                        "console",  -- 程序输出控制台
                    },
                    size = 10,  -- 底部面板高度（行数）
                    position = "bottom",  -- 底部布局
                },
            },
            floating = {
                border = "rounded",  -- 浮动窗口圆角边框
                mappings = {
                    close = { "q", "<Esc>" },  -- 关闭浮动窗口快捷键
                },
            },
        }

        -- 初始化调试虚拟文本（代码行旁显示变量值）
        dap_virtual_text.setup {
            enabled = true,  -- 启用虚拟文本
            enabled_commands = true,  -- 启用虚拟文本相关命令
            highlight_changed_variables = true,  -- 高亮变化的变量
            highlight_new_as_changed = false,  -- 不将新变量高亮为变化的变量
            show_stop_reason = true,  -- 显示中断原因（如断点、异常）
            commented = false,  -- 不将虚拟文本设为注释样式
            only_first_definition = true,  -- 仅显示变量的第一个定义
            all_references = false,  -- 不显示变量的所有引用
            clear_on_continue = false,  -- 继续执行时不清除虚拟文本
            virt_text_pos = "eol",  -- 虚拟文本位置（行尾）
            virt_lines = false,  -- 不使用虚拟行显示
            virt_text_win_col = nil,  -- 不指定虚拟文本窗口列
        }

        -- 调试事件回调：启动调试时打开 dap-ui
        dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
        end
        -- 调试事件回调：退出调试时关闭 dap-ui
        dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
        end
        -- 调试事件回调：暂停调试时关闭 dap-ui
        dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
        end

        -- 自定义断点图标（左侧行号旁）
        vim.fn.sign_define("DapBreakpoint", { text = symbols.Breakpoint, texthl = "DapBreakpoint", numhl = "" })
        vim.fn.sign_define("DapBreakpointCondition", { text = symbols.Conditional, texthl = "DapBreakpointCondition", numhl = "" })
        vim.fn.sign_define("DapLogPoint", { text = symbols.Log, texthl = "DapLogPoint", numhl = "" })
        vim.fn.sign_define("DapStopped", { text = symbols.Stopped, texthl = "DapStopped", numhl = "" })
        vim.fn.sign_define("DapBreakpointRejected", { text = symbols.Error, texthl = "DapBreakpointRejected", numhl = "" })

        -- 配置 Python 调试器（依赖 debugpy，需通过 mason 安装）
        dap.adapters.python = {
            type = "executable",
            command = vim.fn.expand("~/.local/share/nvim/mason/packages/debugpy/venv/bin/python"),  -- debugpy 路径（mason 安装目录）
            args = { "-m", "debugpy.adapter" },
        }
        -- Python 调试配置（支持文件调试和测试调试）
        dap.configurations.python = {
            {
                name = "文件调试：当前文件",
                type = "python",
                request = "launch",
                program = "${file}",  -- 调试当前打开的文件
                console = "integratedTerminal",  -- 使用集成终端
                pythonPath = function()
                    -- 自动识别虚拟环境（优先使用项目根目录下的 venv/bin/python）
                    local cwd = vim.fn.getcwd()
                    if vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
                        return cwd .. "/venv/bin/python"
                    elseif vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
                        return cwd .. "/.venv/bin/python"
                    else
                        return "/usr/bin/python"  --  fallback 到系统 Python
                    end
                end,
            },
            {
                name = "测试调试：pytest 单个函数",
                type = "python",
                request = "launch",
                module = "pytest",
                args = { "-s", "${file}::${function}", "--no-header" },  -- 调试当前文件的指定函数
                console = "integratedTerminal",
            },
        }

        -- 配置 Lua 调试器（Neovim 自身调试，依赖 nlua.nvim）
        dap.adapters.nlua = function(callback, config)
            callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
        end
        dap.configurations.lua = {
            {
                name = "调试：Neovim Lua 代码",
                type = "nlua",
                request = "attach",
                host = "127.0.0.1",
                port = 8086,
            },
        }

        -- 配置 Rust 调试器（依赖 lldb-vscode，需通过 mason 安装）
        dap.adapters.lldb = {
            type = "executable",
            command = vim.fn.expand("~/.local/share/nvim/mason/packages/codelldb/codelldb"),  -- codelldb 路径
            name = "lldb",
        }
        dap.configurations.rust = {
            {
                name = "文件调试：当前 Rust 程序",
                type = "lldb",
                request = "launch",
                program = function()
                    -- 调试已编译的二进制文件（默认查找 target/debug/[项目名]）
                    local cargo_metadata = vim.fn.json_decode(vim.fn.system("cargo metadata --format-version 1 --no-deps"))
                    local exe_name = cargo_metadata.packages[1].name
                    return vim.fn.getcwd() .. "/target/debug/" .. exe_name
                end,
                args = {},
                cwd = "${workspaceFolder}",
                stopOnEntry = false,
                runInTerminal = true,
            },
        }

        -- 调试核心快捷键
        vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "调试：切换断点", silent = true })
        vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "调试：继续执行", silent = true })
        vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "调试：步入函数", silent = true })
        vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "调试：步过函数", silent = true })
        vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "调试：步出函数", silent = true })
        vim.keymap.set("n", "<leader>dr", dap.restart, { desc = "调试：重启会话", silent = true })
        vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "调试：终止调试", silent = true })
        vim.keymap.set("n", "<leader>dC", function() dap.set_breakpoint(vim.fn.input("断点条件：")) end, { desc = "调试：设置条件断点", silent = true })
        vim.keymap.set("n", "<leader>dL", function() dap.set_breakpoint(nil, nil, vim.fn.input("日志内容：")) end, { desc = "调试：设置日志断点", silent = true })
        vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "调试：切换调试界面", silent = true })
        vim.keymap.set("n", "<leader>dw", function() dapui.widgets.watches.add() end, { desc = "调试：添加监视表达式", silent = true })
    end,
}

-- ==============================================
-- 插件 35：neorg（笔记与知识管理）
-- 【完整功能清单】
-- 1. 结构化笔记：支持组织模式（Org-mode）风格的笔记格式，支持标题层级、列表、表格、代码块
-- 2. 任务管理：支持 TODO 任务跟踪（待办/进行中/已完成）、截止日期、优先级、标签分类
-- 3. 知识图谱：自动生成笔记间的链接图谱，支持跳转、反向链接查看
-- 4. 导出功能：支持导出笔记为 Markdown、HTML、PDF、LaTeX 等格式
-- 5. 插件生态：支持语法高亮、自动补全、快捷键绑定、第三方插件扩展（如日历、计时器）
-- 6. 版本控制：与 Git 集成，支持笔记提交、分支管理、历史记录查看
-- 【个性化拓展方向】
-- 1. 笔记结构定制：修改 opts.load["core.concealer"].config.icon_preset = "diamond" 调整标题图标样式，设置 opts.load["core.dirman"].config.workspaces 自定义笔记工作区（如工作笔记、学习笔记分开）
-- 2. 功能拓展：启用 opts.load["core.gtd.base"] 开启 GTD 任务管理功能，添加 opts.load["core.integrations.telescope"] 集成 telescope 实现笔记查找
-- 3. 样式优化：配置 opts.load["core.concealer"].config.conceal = false 禁用语法隐藏（显示原始标记），调整笔记字体大小、行间距
-- 4. 快捷键拓展：添加快捷键实现 "快速创建笔记" "批量修改任务状态" "生成知识图谱" "导出当前笔记"
-- 5. 集成其他插件：结合 telescope 实现 "笔记模糊查找"，结合 todo-comments 实现 "笔记 TODO 与代码 TODO 同步"，结合 persistence 实现 "笔记编辑状态保存"
-- 适用场景：个人笔记、项目文档、知识管理、任务规划（替代 Obsidian、Notion 等外部工具）
-- ==============================================
config.neorg = {
    "nvim-neorg/neorg",  -- 插件 GitHub 地址
    build = ":Neorg sync-parsers",  -- 安装/更新时同步语法解析器
    dependencies = {
        "nvim-lua/plenary.nvim",  -- 依赖工具函数库
        "nvim-treesitter/nvim-treesitter",  -- 依赖语法高亮
        "nvim-neorg/neorg-telescope",  -- 集成 telescope 插件
    },
    ft = "norg",  -- 仅在 .norg 文件类型时加载
    opts = {
        load = {
            -- 核心模块：基础功能（必须加载）
            ["core.defaults"] = {},
            -- 核心模块：语法隐藏与美化（标题图标、列表符号等）
            ["core.concealer"] = {
                config = {
                    icon_preset = "diamond",  -- 标题图标预设（diamond/circle/square）
                    icons = {
                        heading = {
                            level_1 = { icon = "◉" },
                            level_2 = { icon = "○" },
                            level_3 = { icon = "●" },
                            level_4 = { icon = "◌" },
                            level_5 = { icon = "◆" },
                            level_6 = { icon = "◇" },
                        },
                        todo = {
                            enable = { icon = "✓" },
                            disable = { icon = "✗" },
                            pending = { icon = "○" },
                            on_hold = { icon = "⌛" },
                            cancelled = { icon = "✕" },
                        },
                    },
                },
            },
            -- 核心模块：笔记目录管理
            ["core.dirman"] = {
                config = {
                    workspaces = {
                        notes = "~/Notes/General",  -- 通用笔记工作区
                        work = "~/Notes/Work",      -- 工作笔记工作区
                        study = "~/Notes/Study",    -- 学习笔记工作区
                    },
                    default_workspace = "notes",  -- 默认工作区
                    index = "index.norg",  -- 每个工作区的索引文件（首页）
                },
            },
            -- 核心模块：任务管理（GTD）
            ["core.gtd.base"] = {
                config = {
                    workspace = "work",  -- GTD 任务存储在 work 工作区
                    default_lists = {
                        inbox = "inbox.norg",  -- 收件箱
                        todo = "todo.norg",    -- 待办任务
                        doing = "doing.norg",  -- 进行中任务
                        done = "done.norg",    -- 已完成任务
                        cancelled = "cancelled.norg",  -- 已取消任务
                        on_hold = "on_hold.norg",      -- 暂停任务
                    },
                },
            },
            -- 核心模块：笔记链接管理
            ["core.looking-glass"] = {},  -- 预览链接内容
            ["core.highlights"] = {},     -- 语法高亮增强
            ["core.ui.calendar"] = {},    -- 日历功能（任务截止日期选择）
            -- 集成模块：与 telescope 联动（笔记查找）
            ["core.integrations.telescope"] = {},
            -- 集成模块：与 nvim-cmp 联动（笔记内容补全）
            ["core.integrations.nvim-cmp"] = {},
        },
    },
    keys = {
        { "<leader>nn", "<Cmd>Neorg workspace notes<CR>", desc = "笔记：打开通用笔记", silent = true },
        { "<leader>nw", "<Cmd>Neorg workspace work<CR>", desc = "笔记：打开工作笔记", silent = true },
        { "<leader>ns", "<Cmd>Neorg workspace study<CR>", desc = "笔记：打开学习笔记", silent = true },
        { "<leader>ni", "<Cmd>Neorg index<CR>", desc = "笔记：打开当前工作区首页", silent = true },
        { "<leader>nt", "<Cmd>Neorg gtd capture<CR>", desc = "笔记：添加 GTD 任务", silent = true },
        { "<leader>nf", "<Cmd>Telescope neorg find_norg_files<CR>", desc = "笔记：查找笔记文件", silent = true },
        { "<leader>nl", "<Cmd>Telescope neorg find_linkable<CR>", desc = "笔记：查找可链接内容", silent = true },
    },
}

-- ==============================================
-- 插件 36：alpha-nvim（启动界面）
-- 【完整功能清单】
-- 1. 自定义启动页：支持添加 Logo、菜单、最近文件、项目列表、快捷操作
-- 2. 动态内容：显示最近打开的文件、常用命令、系统信息（Neovim 版本、加载时间）
-- 3. 样式定制：支持自定义颜色、字体、布局、动画效果
-- 4. 交互支持：点击菜单跳转、快捷键触发操作、模糊搜索最近文件
-- 5. 插件联动：与 telescope 集成（启动页搜索文件），与 persistence 集成（启动页恢复会话），与 nvim-tree 集成（启动页打开文件树）
-- 【个性化拓展方向】
-- 1. 布局定制：修改 opts.section.header 自定义 Logo（ASCII 艺术），调整 opts.section.buttons 自定义快捷按钮（如添加 "打开笔记" "打开终端" 按钮）
-- 2. 内容拓展：添加自定义模块（如显示天气、待办任务数、Git 分支），启用 opts.section.recent_files 显示更多最近文件
-- 3. 样式优化：设置 opts.opts.noautocmd = true 禁用自动命令，调整启动页背景色、文字颜色，添加渐变效果
-- 4. 交互增强：添加快捷键实现 "启动页搜索文件" "快速切换项目" "启动页隐藏/显示"，支持鼠标点击操作
-- 5. 集成其他插件：结合 telescope 实现 "启动页全局搜索"，结合 neorg 实现 "启动页打开最近笔记"，结合 todo-comments 实现 "启动页显示未完成 TODO"
-- 核心价值：替代 Neovim 默认启动界面（空白页），提供更美观、更实用的启动体验
-- ==============================================
config.alpha = {
    "goolord/alpha-nvim",  -- 插件 GitHub 地址
    dependencies = { "nvim-tree/nvim-web-devicons" },  -- 依赖文件图标库（美化菜单）
    event = "VimEnter",  -- 加载时机：Neovim 启动时
    config = function()
        local alpha = require "alpha"
        local dashboard = require "alpha.themes.dashboard"

        -- 自定义 ASCII Logo（可替换为自己喜欢的样式）
        dashboard.section.header.val = {
            "                                                     ",
            "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
            "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
            "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
            "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
            "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
            "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
            "                                                     ",
            "                  Neovim 配置加载完成!                ",
        }

        -- 自定义快捷按钮（图标+操作+描述）
        dashboard.section.buttons.val = {
            dashboard.button("f", symbols.File .. " 查找文件", "<Cmd>Telescope find_files<CR>"),
            dashboard.button("g", symbols.Search .. " 查找内容", "<Cmd>Telescope live_grep<CR>"),
            dashboard.button("r", symbols.History .. " 最近文件", "<Cmd>Telescope oldfiles<CR>"),
            dashboard.button("s", symbols.Session .. " 恢复会话", "<Cmd>lua require('persistence').load({ last = true })<CR>"),
            dashboard.button("n", symbols.Note .. " 打开笔记", "<Cmd>Neorg workspace notes<CR>"),
            dashboard.button("e", symbols.Folder .. " 打开文件树", "<Cmd>NvimTreeToggle<CR>"),
            dashboard.button("t", symbols.Terminal .. " 打开终端", "<Cmd>ToggleTerm<CR>"),
            dashboard.button("q", symbols.Quit .. " 退出 Neovim", "<Cmd>qa<CR>"),
        }

        -- 自定义底部信息（显示 Neovim 版本、加载时间）
        dashboard.section.footer.val = function()
            local version = vim.version()
            local load_time = vim.fn.printf("%.2f", vim.fn.reltimefloat(vim.fn.reltime(vim.g.start_time)))
            return string.format(
                "Neovim v%d.%d.%d | 加载时间: %ss | 插件数量: %d",
                version.major, version.minor, version.patch,
                load_time,
                #vim.tbl_keys(package.loaded["lazy"].plugins)
            )
        end

        -- 样式配置
        dashboard.opts.opts.noautocmd = true  -- 禁用自动命令（避免干扰）
        dashboard.section.header.opts.hl = "AlphaHeader"  -- 标题高亮组（自定义颜色）
        dashboard.section.buttons.opts.hl = "AlphaButtons"  -- 按钮高亮组
        dashboard.section.footer.opts.hl = "AlphaFooter"  -- 底部信息高亮组

        -- 自定义高亮颜色（适配主题）
        vim.api.nvim_set_hl(0, "AlphaHeader", { fg = "#61afef" })  -- 标题颜色（蓝色）
        vim.api.nvim_set_hl(0, "AlphaButtons", { fg = "#98c379" })  -- 按钮颜色（绿色）
        vim.api.nvim_set_hl(0, "AlphaFooter", { fg = "#d19a66" })  -- 底部信息颜色（橙色）

        -- 启动 alpha 启动页
        alpha.setup(dashboard.opts)

        -- 关闭启动页后自动聚焦到编辑区
        vim.api.nvim_create_autocmd("User", {
            pattern = "AlphaClosed",
            callback = function()
                vim.cmd("setlocal cursorline")  -- 启用光标行高亮
            end,
        })
    end,
}

-- ==============================================
-- 插件 37：noice.nvim（通知与命令行增强）
-- 【完整功能清单】
-- 1. 通知美化：替换 Neovim 默认通知（vim.notify），支持浮动窗口、图标、动画、超时设置
-- 2. 命令行增强：美化命令行（: 模式）、搜索命令行（/ ? 模式），支持自动补全、历史记录、语法高亮
-- 3. 消息管理：整合 LSP 消息、插件通知、错误信息，支持消息过滤、搜索、清除
-- 4. 交互优化：通知支持点击跳转（如 LSP 错误通知跳转至代码行）、快捷键操作（关闭、查看详情）
-- 5. 插件联动：与 nvim-cmp 集成（命令行补全），与 telescope 集成（消息搜索），与 which-key 集成（命令行快捷键提示）
-- 【个性化拓展方向】
-- 1. 样式定制：修改 opts.views.notify.view = "mini" 设置通知为迷你模式，调整 opts.views.cmdline_popup.border = "rounded" 命令行窗口圆角边框
-- 2. 功能拓展：启用 opts.routes 配置消息路由（如将 LSP 进度消息定向到右下角），设置 opts.presets.bottom_search 优化搜索命令行样式
-- 3. 交互增强：添加快捷键实现 "清除所有通知" "搜索消息历史" "暂停通知显示"，配置通知超时时间（重要消息不自动关闭）
-- 4. 消息过滤：通过 opts.routes 过滤不重要的消息（如插件加载成功通知），仅显示错误、警告级别消息
-- 5. 集成其他插件：结合 telescope 实现 "消息历史搜索"，结合 fidget.nvim 实现 "LSP 进度消息整合"，结合 dap 实现 "调试消息美化"
-- 核心价值：解决 Neovim 原生通知/命令行丑陋、功能弱的问题，提升交互体验
-- ==============================================
config.noice = {
    "folke/noice.nvim",  -- 插件 GitHub 地址
    event = "VeryLazy",  -- 加载时机：极晚加载（优化启动速度）
    dependencies = {
        "MunifTanjim/nui.nvim",  -- UI 组件库（浮动窗口、布局）
        "rcarriga/nvim-notify",  -- 通知美化依赖（可选，增强通知功能）
    },
    opts = {
        lsp = {
            -- LSP 消息整合（替换原生 LSP 消息）
            override = {
                ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                ["vim.lsp.util.stylize_markdown"] = true,
                ["cmp.entry.get_documentation"] = true,
            },
            -- LSP 进度消息配置
            progress = {
                enabled = true,
                format = "lsp_progress",
                format_done = "lsp_progress_done",
                throttle = 1000 / 30,  -- 刷新频率（30fps）
                view = "mini",  -- 进度消息显示模式（迷你模式）
            },
        },
        routes = {
            -- 路由规则：过滤不重要的消息
            {
                filter = {
                    event = "msg_show",
                    kind = "",
                    find = "written",  -- 过滤 "X 行已写入" 消息
                },
                opts = { skip = true },  -- 跳过显示
            },
            {
                filter = {
                    event = "notify",
                    level = vim.log.levels.INFO,
                    find = "loaded",  -- 过滤 "插件已加载" 通知
                },
                opts = { skip = true },
            },
            -- 路由规则：LSP 错误消息显示在弹出窗口
            {
                filter = {
                    event = "lsp",
                    kind = "error",
                },
                view = "popup",
                opts = { title = "LSP 错误" },
            },
        },
        views = {
            -- 通知视图配置（迷你模式）
            mini = {
                position = {
                    row = -1,  -- 底部显示
                    col = 0,   -- 左侧对齐
                },
                size = {
                    width = "auto",
                    height = "auto",
                },
                border = "none",  -- 无边框
                win_options = {
                    winblend = 20,  -- 透明度 20%
                },
            },
            -- 命令行弹出窗口配置
            cmdline_popup = {
                position = {
                    row = 5,  -- 距离顶部 5 行
                    col = "50%",  -- 水平居中
                },
                size = {
                    width = "80%",  -- 宽度 80%
                    height = "auto",
                },
                border = {
                    style = "rounded",  -- 圆角边框
                    padding = { 0, 1 },  -- 内边距
                },
                win_options = {
                    winblend = 0,  -- 不透明
                },
            },
        },
        presets = {
            bottom_search = true,  -- 搜索命令行（/ ?）底部显示
            command_palette = true,  -- 命令面板（: 长按）
            long_message_to_split = true,  -- 长消息自动拆分显示
            inc_rename = false,  -- 禁用增量重命名（使用原生或其他插件）
            lsp_doc_border = true,  -- LSP 文档窗口带边框
        },
        -- 通知配置
        notify = {
            enabled = true,
            view = "notify",  -- 使用 notify 视图
            timeout = 3000,  -- 普通通知 3 秒后自动关闭
            stages = "fade",  -- 动画效果（淡入淡出）
            top_down = false,  -- 通知从下往上显示
        },
    },
    keys = {
        { "<leader>un", "<Cmd>Noice dismiss<CR>", desc = "通知：关闭所有通知", silent = true },
        { "<leader>uh", "<Cmd>Noice history<CR>", desc = "通知：查看消息历史", silent = true },
        { "<leader>us", "<Cmd>Noice telescope<CR>", desc = "通知：搜索消息", silent = true },
    },
}

-- ==============================================
-- 插件 38：fidget.nvim（LSP 进度提示）
-- 【完整功能清单】
-- 1. LSP 进度可视化：显示 LSP 服务器的后台任务进度（如初始化、索引、格式化）
-- 2. 动态更新：实时显示任务进度百分比、当前操作（如 "索引文件" "格式化代码"）
-- 3. 样式定制：支持自定义进度条样式、颜色、位置、图标
-- 4. 多任务支持：同时显示多个 LSP 服务器的进度，自动排序
-- 5. 插件联动：与 nvim-lspconfig 集成（自动检测 LSP 进度事件），与 noice.nvim 集成（可选，整合进度消息）
-- 【个性化拓展方向】
-- 1. 样式定制：修改 opts.text.spinner = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" } 自定义加载动画，调整 opts.window.border = "rounded" 进度窗口圆角边框
-- 2. 功能拓展：启用 opts.debug = false 禁用调试模式，设置 opts.timeout = 500 任务完成后 500ms 自动隐藏
-- 3. 位置调整：设置 opts.window.relative = "editor" 进度窗口相对编辑器定位，调整 opts.window.x = "right" 水平靠右显示
-- 4. 过滤任务：通过 opts.filter = function(task) return task.name ~= "null-ls" end 过滤不需要显示的 LSP 任务
-- 5. 集成其他插件：结合 noice.nvim 实现 "LSP 进度消息整合到通知中心"，结合 alpha-nvim 实现 "启动时 LSP 进度提示"
-- 适用场景：LSP 后台任务（如大型项目索引）时，提供直观的进度反馈（避免误以为 Neovim 卡死）
-- ==============================================
config.fidget = {
    "j-hui/fidget.nvim",  -- 插件 GitHub 地址
    tag = "legacy",  -- 使用 legacy 版本（兼容旧配置）
    event = "LspAttach",  -- 加载时机：LSP 附加到缓冲区时
    opts = {
        text = {
            spinner = "dots",  -- 加载动画（dots/line/circle/square）
            done = symbols.Check,  -- 任务完成图标
            commenced = "开始...",  -- 任务开始文本
            completed = "完成!",  -- 任务完成文本
        },
        window = {
            relative = "win",  -- 进度窗口相对当前窗口定位
            blend = 0,  -- 不透明
            zindex = nil,  -- 不指定层级（使用默认）
        },
        fmt = {
            task = function(task_name, msg, percentage)
                -- 格式化进度文本：[任务名] 消息 (进度%)
                return string.format("[%s] %s (%.0f%%)", task_name, msg, percentage)
            end,
            lsp_client_name = function(client_name)
                -- 简化 LSP 客户端名称（如 "pyright" → "Python"）
                local name_map = {
                    pyright = "Python",
                    lua_ls = "Lua",
                    tsserver = "TS/JS",
                    gopls = "Go",
                    rust_analyzer = "Rust",
                }
                return name_map[client_name] or client_name
            end,
        },
        timeout = 3000,  -- 任务完成后 3 秒自动隐藏
        ignore = {
            clients = {},  -- 不忽略任何 LSP 客户端
            ft = {},  -- 不忽略任何文件类型
            intensity = {},  -- 不忽略任何任务强度
        },
    },
}

-- ==============================================
-- 插件 39：nvim-transparent（透明度控制）
-- 【完整功能清单】
-- 1. 全局透明度调整：一键调整 Neovim 整体透明度（包括背景、窗口、文本）
-- 2. 局部透明度控制：单独调整特定窗口（如终端、文件树、通知）的透明度
-- 3. 自动透明：启动时自动设置透明度，支持根据主题自动适配
-- 4. 快捷键支持：一键切换透明模式、调整透明度等级
-- 5. 插件联动：与 nvim-tree、toggleterm、noice 等插件兼容，支持它们的透明度独立配置
-- 【个性化拓展方向】
-- 1. 默认透明度：设置 opts.transparent = true 启动时自动启用透明，调整 opts.opacity = 0.9 全局透明度（0-1，数值越低越透明）
-- 2. 局部透明：通过 opts.exclude = { "NvimTree", "ToggleTerm" } 排除不需要透明的窗口，单独配置这些窗口的透明度
-- 3. 快捷键拓展：添加快捷键实现 "增加透明度" "降低透明度" "重置透明度" "切换透明模式"
-- 4. 场景适配：为不同场景配置专属透明度（如专注模式下加深透明，编辑模式下提高不透明度）
-- 5. 集成其他插件：结合 zen-mode 实现 "专注模式下自动调整透明度"，结合 alpha-nvim 实现 "启动页透明度优化"
-- 适用场景：喜欢透明效果、使用美化终端（如 Kitty、Alacritty）的用户，提升视觉体验
-- ==============================================
config["nvim-transparent"] = {  -- 插件名带连字符，用[]包裹
    "xiyaowong/nvim-transparent",  -- 插件 GitHub 地址
    event = "User IceLoad",  -- 加载时机：IceLoad 事件触发后
    opts = {
        groups = {  -- 需要透明化的高亮组
            "Normal",
            "NormalNC",
            "Comment",
            "Constant",
            "Special",
            "Identifier",
            "Statement",
            "PreProc",
            "Type",
            "Underlined",
            "Todo",
            "String",
            "Function",
            "Conditional",
            "Repeat",
            "Operator",
            "Structure",
            "LineNr",
            "NonText",
            "SignColumn",
            "CursorLineNr",
            "EndOfBuffer",
        },
        extra_groups = {  -- 额外需要透明化的高亮组（插件相关）
            "NvimTreeNormal",
            "NvimTreeNormalNC",
            "ToggleTerm",
            "NoicePopup",
            "AlphaHeader",
            "AlphaButtons",
            "AlphaFooter",
        },
        exclude_groups = {},  -- 不透明化的高亮组（空表示全部透明）
        opacity = 0.95,  -- 全局透明度（0.95 表示轻微透明）
        transparent_background = true,  -- 透明背景
        enable = true,  -- 启动时启用透明
    },
    keys = {
        { "<leader>ut", "<Cmd>TransparentToggle<CR>", desc = "工具：切换透明度", silent = true },
        { "<leader>uT", "<Cmd>TransparentEnable<CR>", desc = "工具：启用透明度", silent = true },
        { "<leader>uC", "<Cmd>TransparentDisable<CR>", desc = "工具：禁用透明度", silent = true },
    },
}

-- ==============================================
-- 插件 40：catppuccin（主题插件）
-- 【完整功能清单】
-- 1. 多风格主题：内置多个配色方案（latte 浅色系、frappe 中浅色系、macchiato 中深色系、mocha 深色系）
-- 2. 全局美化：统一 Neovim 界面颜色（文本、背景、边框、高亮组），支持透明背景
-- 3. 插件适配：完美适配 100+ 主流插件（如 nvim-tree、telescope、lspconfig、dap 等），自动美化插件 UI
-- 4. 自定义配置：支持修改主题颜色、高亮组样式、插件专属配色
-- 5. 动态切换：支持一键切换主题风格，保存主题偏好
-- 【个性化拓展方向】
-- 1. 主题选择：设置 opts.flavor = "mocha" 默认为深色主题，调整 opts.transparent_background = true 启用透明背景
-- 2. 颜色定制：修改 opts.color_overrides 自定义主题颜色（如调整注释颜色、函数颜色），设置 opts.highlight_overrides 自定义高亮组（如调整光标行颜色）
-- 3. 插件适配：通过 opts.integrations 启用特定插件的主题适配（如启用 telescope、dap、neorg 的专属配色）
-- 4. 动态切换：添加快捷键实现 "切换主题风格" "切换明暗模式" "重置主题配置"
-- 5. 集成其他插件：结合 nvim-transparent 实现 "主题透明深度调整"，结合 alpha-nvim 实现 "启动页主题适配"，结合 noice 实现 "通知主题美化"
-- 核心价值：Neovim 视觉体验核心，提供美观、统一、可定制的主题（替代多个零散的高亮配置）
-- ==============================================
config.catppuccin = {
    "catppuccin/nvim",  -- 插件 GitHub 地址
    name = "catppuccin",  -- 插件名称（用于 Lazy.nvim 识别）
    priority = 1000,  -- 加载优先级（最高，确保主题先加载）
    event = "User IceLoad",  -- 加载时机：IceLoad 事件触发后
    opts = {
        flavor = "mocha",  -- 默认主题风格（mocha 深色系）
        background = {  -- 背景配置
            light = "latte",  -- 浅色模式主题
            dark = "mocha",   -- 深色模式主题
        },
        transparent_background = true,  -- 启用透明背景（与 nvim-transparent 配合）
        show_end_of_buffer = false,  -- 不显示缓冲区末尾的 ~ 符号
        term_colors = true,  -- 同步终端颜色
        dim_inactive = {
            enabled = false,  -- 不调暗非激活窗口
            shade = "dark",
            percentage = 0.15,
        },
        no_italic = false,  -- 启用斜体
        no_bold = false,    -- 启用粗体
        no_underline = false,  -- 启用下划线
        styles = {  -- 不同语法元素的样式
            comments = { "italic" },
            conditionals = { "italic" },
            loops = {},
            functions = { "bold" },
            keywords = {},
            strings = {},
            variables = {},
            numbers = {},
            booleans = {},
            properties = {},
            types = { "bold" },
            operators = {},
        },
        color_overrides = {  -- 自定义主题颜色（基于 mocha 风格）
            mocha = {
                base = "#0a0a0a",    -- 背景色（深黑色）
                mantle = "#111111",  -- 外层背景色
                crust = "#1a1a1a",   -- 边框/窗口背景色
                text = "#e0e0e0",    -- 文本色（浅灰色）
                subtext1 = "#b0b0b0",-- 次要文本色
                subtext0 = "#808080",-- 次要文本色（更浅）
                overlay2 = "#606060",-- 覆盖层颜色
                overlay1 = "#404040",-- 覆盖层颜色（更深）
                overlay0 = "#303030",-- 覆盖层颜色（最深）
                surface2 = "#252525",-- 表面层颜色
                surface1 = "#202020",-- 表面层颜色（更深）
                surface0 = "#151515",-- 表面层颜色（最深）
                primary = "#61afef", -- 主色调（蓝色）
                secondary = "#98c379",-- 辅助色（绿色）
                tertiary = "#d19a66",-- 第三色（橙色）
                accent = "#c678dd",  -- 强调色（紫色）
                error = "#dc2626",   -- 错误色（红色）
                warning = "#fbbf24", -- 警告色（黄色）
                info = "#2563eb",    -- 信息色（蓝色）
                hint = "#10b981",    -- 提示色（绿色）
            },
        },
        highlight_overrides = {  -- 自定义高亮组
            mocha = function(c)
                return {
                    -- 光标行高亮
                    CursorLine = { bg = c.surface0 },
                    -- 选中文本高亮
                    Visual = { bg = c.surface1, fg = c.text },
                    -- 搜索结果高亮
                    Search = { bg = c.surface2, fg = c.text },
                    -- 代码折叠高亮
                    FoldColumn = { fg = c.overlay1, bg = c.base },
                    -- LSP 诊断高亮
                    DiagnosticError = { fg = c.error },
                    DiagnosticWarn = { fg = c.warning },
                    DiagnosticInfo = { fg = c.info },
                    DiagnosticHint = { fg = c.hint },
                }
            end,
        },
        integrations = {  -- 插件主题适配（启用所有常用插件）
            cmp = true,
            gitsigns = true,
            nvimtree = true,
            telescope = true,
            notify = true,
            noice = true,
            dap = { enabled = true, enable_ui = true },
            neorg = true,
            alpha = true,
            toggleterm = true,
            illuminate = true,
            which_key = true,
            fidget = true,
            lsp_trouble = true,
            mason = true,
            neotree = false,  -- 禁用 neotree 适配（使用 nvim-tree）
            dropbar = { enabled = false },
            native_lsp = {
                enabled = true,
                virtual_text = {
                    errors = { "italic" },
                    hints = { "italic" },
                    warnings = { "italic" },
                    information = { "italic" },
                },
                underlines = {
                    errors = { "underline" },
                    hints = { "underline" },
                    warnings = { "underline" },
                    information = { "underline" },
                },
                inlay_hints = {
                    background = true,
                },
            },
        },
    },
    config = function(_, opts)
        require("catppuccin").setup(opts)  -- 加载主题配置
        vim.cmd.colorscheme "catppuccin"  -- 设置默认主题
    end,
    keys = {
        { "<leader>uc", "<Cmd>Catppuccin toggle<CR>", desc = "主题：切换明暗模式", silent = true },
        { "<leader>ul", "<Cmd>Catppuccin latte<CR>", desc = "主题：切换浅色系（latte）", silent = true },
        { "<leader>uf", "<Cmd>Catppuccin frappe<CR>", desc = "主题：切换中浅色系（frappe）", silent = true },
        { "<leader>um", "<Cmd>Catppuccin macchiato<CR>", desc = "主题：切换中深色系（macchiato）", silent = true },
        { "<leader>ud", "<Cmd>Catppuccin mocha<CR>", desc = "主题：切换深色系（mocha）", silent = true },
    },
}

-- ==============================================
-- 最终配置导出（供 Lazy.nvim 加载）
-- ==============================================
return config      