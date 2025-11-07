--给你代码，写新手详细注释，越详细越好，可复制粘贴
-- ==============================================
-- 全局配置入口文件：整合核心配置、插件、自定义配置
-- 所有配置数据统一存储在全局表 Ice 中，方便管理
-- ==============================================

-- 创建全局表 Ice，用于存储整个配置的核心数据（快捷键、文件类型配置、插件列表等）
-- 后续所有模块的配置都会汇总到这里，是配置的"数据中心"
Ice = {}

-- 加载核心配置入口：包含基础设置、快捷键、命令、工具函数等核心功能
-- "core.init" 对应 lua/core/init.lua 文件，会自动加载 core 目录下的关键模块
require "core.init"
-- 加载插件配置入口：包含所有插件的定义、配置规则、Lazy.nvim 配置等
-- "plugins.init" 对应 lua/plugins/init.lua 文件，是插件管理的总入口
require "plugins.init"

-- 获取 Neovim 的标准配置目录路径（默认是 ~/.config/nvim）
-- vim.fn.stdpath("config") 是 Neovim 内置函数，专门用于获取固定路径（配置、数据、缓存等）
local config_root = vim.fn.stdpath "config"
-- 拼接自定义配置目录路径：~/.config/nvim/lua/custom
-- 这个目录用于存放用户自己的自定义配置，不修改默认配置，方便后续更新和维护
local custom_path = vim.fs.joinpath(config_root, "lua/custom")
-- 检查 custom 目录是否存在：判断 "lua/custom/" 是否在 Neovim 的运行时路径中
-- vim.api.nvim_get_runtime_file 查找运行时路径下的文件/目录，返回找到的路径列表
-- 第二个参数 false 表示不递归查找子目录
if not vim.api.nvim_get_runtime_file("lua/custom/", false)[1] then
    -- 如果 custom 目录不存在，执行系统命令创建它（os.execute 用于调用系统终端命令）
    os.execute('mkdir "' .. custom_path .. '"')
end

-- 检查 custom 目录下是否有 init.lua 文件（用户自定义配置的入口文件）
-- vim.uv.fs_stat 是 Neovim 内置的文件状态检查函数，判断文件/目录是否存在
-- vim.fs.joinpath 用于安全拼接文件路径（避免不同系统路径分隔符问题）
if vim.uv.fs_stat(vim.fs.joinpath(custom_path, "init.lua")) then
    -- 如果存在自定义入口文件，加载它（优先级高于默认配置，可覆盖默认设置）
    require "custom.init"
end

-- 注册全局快捷键：调用 core 模块的工具函数 group_map，批量注册 Ice.keymap 中的快捷键
-- Ice.keymap 是在 lua/core/keymap.lua 中定义的快捷键列表，group_map 负责解析并注册
require("core.utils").group_map(Ice.keymap)

-- 配置文件类型相关规则：遍历 Ice.ft 中的所有配置，为对应文件类型应用设置
-- Ice.ft 是在 lua/core/ft.lua 中定义的文件类型配置表（键是文件类型，值是配置规则）
-- 例如：为 Python 文件设置 4 空格缩进、为 Markdown 文件设置自动换行等
for filetype, config in pairs(Ice.ft) do
    -- 调用 core 工具函数 ft，将配置应用到指定文件类型
    require("core.utils").ft(filetype, config)
end

-- 条件加载插件和配色方案：只有启动 Neovim 时未传入 --noplugin 参数才执行
-- require("core.utils").noplugin 是工具函数，用于判断是否禁用插件（--noplugin 触发）
if not require("core.utils").noplugin then
    -- 初始化 Lazy.nvim 插件管理器：加载所有插件
    -- vim.tbl_values(Ice.plugins) 提取 Ice.plugins 中的所有插件配置（去掉键名，保留值列表）
    -- Ice.lazy 是在 lua/plugins/lazy.lua 中定义的 Lazy.nvim 全局配置（安装路径、并行下载等）
    require("lazy").setup(vim.tbl_values(Ice.plugins), Ice.lazy)

    -- 定义自动命令的触发条件：默认是 "IceAfter transparent"（透明插件加载完成后）
    local pattern = "IceAfter transparent"
    -- 如果 nvim-transparent 插件被禁用（enabled 为 false），则修改触发条件
    if Ice.plugins["nvim-transparent"].enabled == false then
        -- 改为 "VeryLazy"（Lazy.nvim 内置事件，Neovim 完全启动后触发）
        pattern = "VeryLazy"
    end
    -- 创建自动命令：在指定事件触发后执行后续逻辑（自动命令是 Neovim 事件驱动的核心）
    -- vim.api.nvim_create_autocmd 是 Neovim 内置函数，用于创建自动命令
    vim.api.nvim_create_autocmd("User", {
        once = true, -- 该自动命令只执行一次（避免重复触发）
        pattern = pattern, -- 触发事件（上面定义的 pattern）
        callback = function() -- 事件触发后执行的具体逻辑
            -- 获取插件运行时路径中的 plugin 目录（存放插件的自动加载脚本）
            -- vim.opt.packpath:get()[1] 获取 Neovim 的插件安装路径（默认是 ~/.local/share/nvim/site）
            local rtp_plugin_path = vim.fs.joinpath(vim.opt.packpath:get()[1], "plugin")
            -- 扫描 rtp_plugin_path 目录下的所有条目（文件/目录）
            local dir = vim.uv.fs_scandir(rtp_plugin_path)
            if dir ~= nil then
                -- 循环遍历目录中的所有条目
                while true do
                    -- 逐个获取目录中的条目名称和类型（文件/目录）
                    local plugin, entry_type = vim.uv.fs_scandir_next(dir)
                    -- 如果没有更多条目，或遇到子目录，退出循环
                    if plugin == nil or entry_type == "directory" then
                        break
                    else
                        -- 加载插件的自动脚本（vim.cmd 执行 Vim 命令，source 用于加载脚本文件）
                        vim.cmd(string.format("source %s/%s", rtp_plugin_path, plugin))
                    end
                end
            end

            -- 处理配色方案：如果 Ice.colorscheme 未被自定义配置设置
            if not Ice.colorscheme then
                -- 设置默认配色方案为 "tokyonight"
                Ice.colorscheme = "tokyonight"
                -- 拼接配色方案缓存文件路径：~/.local/share/nvim/colorscheme
                -- 缓存文件用于保存用户上次选择的配色方案，下次启动自动加载
                local colorscheme_cache = vim.fs.joinpath(vim.fn.stdpath "data", "colorscheme")
                -- 检查配色方案缓存文件是否存在
                if vim.uv.fs_stat(colorscheme_cache) then
                    -- 打开缓存文件并读取内容（io.open 用于文件读写操作）
                    local colorscheme_cache_file = io.open(colorscheme_cache, "r")
                    ---@diagnostic disable: need-check-nil （忽略缓存文件为空的语法警告）
                    local colorscheme = colorscheme_cache_file:read "*a" -- 读取文件全部内容
                    colorscheme_cache_file:close() -- 关闭文件（避免资源泄露）
                    -- 将缓存中的配色方案名称赋值给 Ice.colorscheme（覆盖默认值）
                    Ice.colorscheme = colorscheme
                end
            end

            -- 加载最终确定的配色方案：调用插件工具函数 colorscheme
            -- 第二个参数 false 表示本次加载不保存到缓存（避免覆盖用户手动选择的配色）
            require("plugins.utils").colorscheme(Ice.colorscheme, false)
        end,
    })
end

-- 将自定义配置目录（custom_path）添加到 Neovim 运行时路径的最前面
-- 运行时路径（rtp）决定了 Neovim 查找配置文件、插件的顺序，前置确保自定义配置优先级最高
-- 最后执行是为了避免被 Lazy.nvim 自动调整路径时覆盖
vim.opt.rtp:prepend(custom_path)