-- ==============================================
-- LSP 增强插件配置：lspsaga.nvim + trouble.nvim
-- 核心定位：LSP 功能的「UI 增强器」和「诊断管理器」，让代码开发更高效
-- 插件组合价值：
-- 1. lspsaga.nvim：优化 LSP 原生功能的交互体验（如跳转定义、悬停文档、重命名），提供美观的 UI 界面
-- 2. trouble.nvim：集中管理 LSP 诊断信息（错误/警告/提示），支持分类筛选和快速跳转
-- 新手说明：以下分别详解两个插件的配置、功能、快捷键和使用场景，所有配置可直接粘贴使用
-- ==============================================

-- 一、LSP 功能增强插件：nvimdev/lspsaga.nvim
-- 插件介绍（lspsaga.nvim）：
-- - 核心定位：LSP 功能的「交互美化大师」，解决原生 LSP 交互简陋、操作繁琐的问题
-- - 核心特性：
--   1. 悬停文档：美化的函数文档显示（支持语法高亮、代码块、滚动）
--   2. 跳转功能：定义/引用/实现的可视化跳转（支持多窗口切换）
--   3. 重命名：批量修改变量/函数的所有引用（支持跨文件）
--   4. 诊断管理：行诊断、缓冲区诊断的快速查看和修复
--   5. 代码操作：LSP 代码修复建议的可视化菜单（如自动导入、修复语法错误）
-- - 优势：UI 设计美观、操作流畅、快捷键丰富，大幅提升 LSP 使用体验
Ice.plugins.lspsaga = {
    -- 插件基础信息：GitHub 仓库地址（作者 nvimdev，仓库 lspsaga.nvim）
    "nvimdev/lspsaga.nvim",
    -- 插件加载时机：命令触发加载（仅执行 :Lspsaga 相关命令时才加载，提升启动速度）
    cmd = "Lspsaga",
    -- 插件核心配置（opts 表定制 LSPsaga 的功能行为）
    opts = {
        -- 1. 查找功能配置（finder：定义/引用/实现查找）
        finder = {
            keys = {
                -- 切换/打开查找结果：按 Enter 键（<CR>），支持从查找窗口直接打开目标位置
                toggle_or_open = "<CR>",
            },
        },
        -- 2. 顶部导航栏配置（symbol_in_winbar：在状态栏显示当前代码位置层级）
        symbol_in_winbar = {
            enable = false,  -- 禁用顶部导航栏（若需要启用，改为 true，会在状态栏显示「文件→类→方法」层级）
            -- 启用注意点：可能占用状态栏空间，建议配合 lualine 等状态栏插件使用
        },
    },
    -- 自定义快捷键配置（核心操作入口，新手需重点记忆）
    keys = {
        -- 1. 批量重命名：<leader>lr（leader 是空格，按 空格+lr）
        -- 功能：光标选中变量/函数，执行后批量修改所有引用（跨文件也生效）
        -- 使用场景：重构代码时，修改变量名/函数名（比原生 :rename 更智能）
        { "<leader>lr", "<Cmd>Lspsaga rename<CR>", desc = "LSP: 批量重命名变量/函数", silent = true },

        -- 2. 代码操作菜单：<leader>lc（空格+lc）
        -- 功能：打开 LSP 代码修复建议菜单（如自动导入缺失的模块、修复语法错误、优化代码）
        -- 使用场景：代码下出现红色/黄色波浪线时，执行该命令查看修复选项
        { "<leader>lc", "<Cmd>Lspsaga code_action<CR>", desc = "LSP: 打开代码修复建议菜单", silent = true },

        -- 3. 跳转到定义：<leader>ld（空格+ld）
        -- 功能：光标选中变量/函数/类，跳转到其定义位置（如函数声明处、类定义处）
        -- 使用场景：想查看某函数的实现逻辑时，快速跳转
        { "<leader>ld", "<Cmd>Lspsaga goto_definition<CR>", desc = "LSP: 跳转到定义位置", silent = true },

        -- 4. 悬停文档：<leader>lh（空格+lh）
        -- 功能：显示光标所在变量/函数的详细文档（含参数、返回值、示例代码）
        -- 自定义逻辑：修复原生悬停文档不自动聚焦的问题，执行后自动切换到文档窗口
        {
            "<leader>lh",
            function()
                -- 保存 LSPsaga 原始的浮动窗口创建函数
                local win = require "lspsaga.window"
                local old_new_float = win.new_float
                -- 重写浮动窗口创建函数：创建后自动聚焦到文档窗口
                win.new_float = function(self, float_opt, enter, force)
                    local window = old_new_float(self, float_opt, enter, force)
                    local _, winid = window:wininfo()  -- 获取文档窗口 ID
                    vim.api.nvim_set_current_win(winid)  -- 自动聚焦到文档窗口

                    win.new_float = old_new_float  -- 恢复原始函数，避免影响其他功能
                    return window
                end

                vim.cmd "Lspsaga hover_doc"  -- 执行悬停文档命令
            end,
            desc = "LSP: 显示函数/变量详细文档（自动聚焦）",
            silent = true,
        },

        -- 5. 查找引用：<leader>lR（空格+l+R，注意 R 是大写）
        -- 功能：查找当前变量/函数的所有引用位置，显示在可视化窗口中
        -- 使用场景：想知道某函数被哪些地方调用时，快速查看所有引用
        { "<leader>lR", "<Cmd>Lspsaga finder<CR>", desc = "LSP: 查找变量/函数的所有引用", silent = true },

        -- 6. 跳转到实现：<leader>li（空格+li）
        -- 功能：光标选中接口/抽象类，跳转到其具体实现类
        -- 使用场景：面向对象编程中，快速查看接口的实现逻辑
        { "<leader>li", "<Cmd>Lspsaga finder<CR>", desc = "LSP: 跳转到接口/类的实现", silent = true },

        -- 7. 显示行诊断：<leader>lP（空格+l+P，大写 P）
        -- 功能：显示当前行的所有诊断信息（错误/警告/提示），含修复建议
        -- 使用场景：当前行出现波浪线时，查看具体问题和修复方法
        { "<leader>lP", "<Cmd>Lspsaga show_line_diagnostics<CR>", desc = "LSP: 显示当前行诊断信息", silent = true },

        -- 8. 下一个诊断：<leader>ln（空格+ln）
        -- 功能：跳转到当前缓冲区的下一个诊断位置（错误/警告/提示）
        -- 使用场景：批量修复文件中的所有问题，按顺序跳转
        { "<leader>ln", "<Cmd>Lspsaga diagnostic_jump_next<CR>", desc = "LSP: 跳转到下一个诊断位置", silent = true },

        -- 9. 上一个诊断：<leader>lp（空格+lp，小写 p）
        -- 功能：跳转到当前缓冲区的上一个诊断位置
        -- 使用场景：错过某个问题时，回退查看
        { "<leader>lp", "<Cmd>Lspsaga diagnostic_jump_prev<CR>", desc = "LSP: 跳转到上一个诊断位置", silent = true },
    },
}

-- 二、LSP 诊断管理插件：folke/trouble.nvim
-- 插件介绍（trouble.nvim）：
-- - 核心定位：LSP 诊断信息的「集中管理器」，解决原生 LSP 诊断分散、难以批量处理的问题
-- - 核心特性：
--   1. 集中显示：将所有诊断信息（错误/警告/提示）汇总到一个窗口，支持分类筛选
--   2. 快速跳转：点击诊断项直接跳转到对应的代码位置
--   3. 多源支持：支持 LSP 诊断、treesitter 语法错误、lint 工具（如 eslint）诊断
--   4. 灵活过滤：可按诊断级别（错误/警告/提示）、文件、缓冲区筛选
-- - 优势：适合大型项目，快速定位和修复所有代码问题，提升调试效率
Ice.plugins.trouble = {
    -- 插件基础信息：GitHub 仓库地址（作者 folke，仓库 trouble.nvim）
    "folke/trouble.nvim",
    -- 插件核心配置（opts 表，默认空表表示使用插件默认配置）
    -- 可扩展配置示例（新手可按需添加）：
    -- opts = {
    --   mode = "document_diagnostics",  -- 默认显示当前文档的诊断（可改为 "workspace_diagnostics" 显示整个工作区）
    --   severity = vim.diagnostic.severity.ERROR,  -- 仅显示错误（可添加 WARNING 显示警告）
    -- },
    opts = {},
    -- 插件加载时机：命令触发加载（仅执行 :Trouble 命令时加载，提升启动速度）
    cmd = "Trouble",
    -- 自定义快捷键配置
    keys = {
        -- 诊断窗口切换：<leader>lt（空格+lt）
        -- 功能：打开/关闭 Trouble 诊断窗口，自动聚焦到窗口
        -- 命令解析：
        -- - Trouble diagnostics toggle：切换诊断窗口（打开/关闭）
        -- - focus=true：打开后自动聚焦到诊断窗口，方便快速操作
        -- 使用场景：想查看整个文件/工作区的所有问题时，一键打开集中处理
        { "<leader>lt", "<Cmd>Trouble diagnostics toggle focus=true<CR>", desc = "LSP: 打开/关闭诊断管理窗口", silent = true },
    },
}

-- ==============================================
-- 插件核心功能&快捷键汇总（新手必备，快速查阅）
-- ==============================================
-- 一、lspsaga.nvim 核心功能&快捷键
-- | 快捷键       | 功能描述                                  | 适用场景                                  |
-- |--------------|-------------------------------------------|-------------------------------------------|
-- | <leader>lr   | 批量重命名变量/函数（跨文件生效）          | 重构代码时修改变量名/函数名                |
-- | <leader>lc   | 打开代码修复建议菜单                      | 代码出现波浪线时，查看修复选项（如自动导入）|
-- | <leader>ld   | 跳转到变量/函数/类的定义位置              | 查看函数实现、类定义                      |
-- | <leader>lh   | 显示详细文档（含参数、返回值、示例）       | 不清楚函数用法时，快速查阅文档            |
-- | <leader>lR   | 查找变量/函数的所有引用位置                | 了解函数被哪些地方调用                    |
-- | <leader>li   | 跳转到接口/类的具体实现                    | 面向对象编程中查看接口实现                |
-- | <leader>lP   | 显示当前行的诊断信息（错误/警告+修复建议） | 当前行出现波浪线时，查看具体问题          |
-- | <leader>ln   | 跳转到下一个诊断位置                      | 按顺序修复文件中的所有问题                |
-- | <leader>lp   | 跳转到上一个诊断位置                      | 回退查看之前的问题                        |

-- 二、trouble.nvim 核心功能&快捷键
-- | 快捷键       | 功能描述                                  | 适用场景                                  |
-- |--------------|-------------------------------------------|-------------------------------------------|
-- | <leader>lt   | 打开/关闭诊断管理窗口（自动聚焦）          | 集中查看整个文件/工作区的所有问题          |
-- | 窗口内快捷键（默认）：                    |                                           |
-- | j/k          | 上下移动选中诊断项                        | 切换不同的问题                            |
-- | <CR>         | 跳转到选中诊断项对应的代码位置            | 定位并修复问题                            |
-- | q            | 关闭诊断窗口                              | 修复完成后关闭窗口                        |
-- | <space>      | 展开/折叠诊断项（显示子问题）             | 查看复杂问题的详细信息                    |
-- | r            | 刷新诊断信息                              | 修复问题后更新窗口内容                    |
-- | x            | 关闭当前诊断项（标记为已处理）            | 忽略无需修复的问题                        |

-- ==============================================
-- 新手使用注意点（避坑指南）
-- ==============================================
-- 1. 依赖前提：两个插件都依赖 LSP 服务正常运行（需确保对应语言服务器已安装，如 pyright、tsserver）
--    - 检查 LSP 状态：执行 :LspInfo，确保「active lsp」列表中有当前文件类型对应的服务
--    - 安装语言服务器：执行 :Mason，搜索对应语言服务器（如 Python 搜 pyright），点击 Install
-- 2. 快捷键冲突：
--    - 若 <leader>l 开头的快捷键无效，检查是否被其他插件占用（如 core/keymap.lua 中的配置）
--    - 可修改快捷键前缀（如将 <leader>l 改为 <leader>s），只需替换 keys 中的 "<leader>l" 为新前缀
-- 3. lspsaga 悬停文档：
--    - 若文档显示乱码，检查是否安装 Nerd Font 字体（文档中可能包含图标）
--    - 若文档不显示，执行 :Lspsaga hover_doc 手动触发，或检查 LSP 服务是否返回文档信息
-- 4. trouble.nvim 扩展配置：
--    - 仅显示错误：在 opts 中添加 severity = {vim.diagnostic.severity.ERROR}
--    - 显示整个工作区诊断：在 opts 中添加 mode = "workspace_diagnostics"
--    - 过滤特定文件类型：在 opts 中添加 exclude = { "markdown" }（不显示 markdown 文件的诊断）
-- 5. 性能优化：
--    - 大型项目中，Trouble 窗口加载可能较慢，可改为仅显示当前文档诊断（默认配置）
--    - 关闭不必要的 LSPsaga 功能（如 symbol_in_winbar），提升启动速度
-- 6. 常见问题排查：
--    - 插件功能未生效：执行 :Lazy 检查插件是否已安装，未安装则执行 :Lazy install
--    - 诊断信息不更新：执行 :LspRestart 重启 LSP 服务，或 :Trouble refresh 刷新 Trouble 窗口
--    - 跳转失败：确保光标准确选中变量/函数（需选中名称，而非括号/引号）