---@diagnostic disable: need-check-nil  -- 禁用"需要检查空值"的诊断提示
-- 原因：部分 API 调用（如 vim.cmd、io.open）在特定场景下可能返回 nil，但实际已通过 pcall 捕获异常，无需强制检查空值
local utils = {}  -- 定义工具函数模块表，用于存储所有全局通用辅助功能

-- ==============================================
-- 函数：主题切换与初始化（核心工具函数）
-- 作用：加载指定主题、执行主题配置、同步全局状态、联动透明插件
-- 参数1：colorscheme_name - 要切换的主题名称（需在 Ice.colorschemes 中预先定义）
-- 参数2：transparent - 可选参数，强制启用/禁用透明（默认跟随主题配置）
-- ==============================================
utils.colorscheme = function(colorscheme_name, transparent)
    Ice.colorscheme = colorscheme_name  -- 将当前主题名称存入 Ice 全局配置，供其他模块读取

    local colorscheme = Ice.colorschemes[colorscheme_name]  -- 从主题列表中获取目标主题的完整配置
    if not colorscheme then  -- 若目标主题不存在（未在 Ice.colorschemes 中定义）
        -- 弹出错误通知，提示主题无效
        vim.notify(colorscheme_name .. " is not a valid color scheme!", vim.log.levels.ERROR)
        return  -- 终止函数执行，避免后续错误
    end

    -- 根据主题配置的 setup 类型，执行初始化逻辑
    if type(colorscheme.setup) == "table" then
        -- 若 setup 是配置表，直接传递给主题插件的 setup 函数初始化
        require(colorscheme.name).setup(colorscheme.setup)
    elseif type(colorscheme.setup) == "function" then
        -- 若 setup 是函数，直接执行该函数（支持自定义初始化逻辑）
        colorscheme.setup()
    end

    -- 调用 Lazy 加载器的 colorscheme 方法，确保主题插件已加载完成
    require("lazy.core.loader").colorscheme(colorscheme.name)
    vim.cmd("colorscheme " .. colorscheme.name)  -- 执行 Neovim 原生命令，应用主题
    vim.o.background = colorscheme.background  -- 设置背景色模式（light/dark），部分主题依赖此配置

    -- 自定义选中区域（Visual 模式）高亮：启用反向显示，确保不同主题下选中效果一致
    vim.api.nvim_set_hl(0, "Visual", { reverse = true })

    -- 触发自定义事件"IceAfter colorscheme"，通知其他插件（如 lualine、indent-blankline）主题已切换，需更新 UI
    vim.api.nvim_exec_autocmds("User", { pattern = "IceAfter colorscheme" })

    -- 联动透明插件：根据主题配置自动启用/禁用透明
    -- 条件判断：1. 未强制关闭透明（transparent ~= false） 2. 透明插件已配置 3. 透明插件未被禁用
    if transparent ~= false and Ice.plugins["nvim-transparent"] ~= nil and Ice.plugins["nvim-transparent"].enabled ~= false then
        if colorscheme.transparent then  -- 若主题支持透明，执行启用透明命令
            ---@diagnostic disable-next-line: param-type-mismatch
            pcall(vim.cmd, "TransparentEnable")  -- 用 pcall 捕获异常，避免插件未加载时报错
        else  -- 若主题不支持透明，执行禁用透明命令
            ---@diagnostic disable-next-line: param-type-mismatch
            pcall(vim.cmd, "TransparentDisable")
        end
    end
end

-- ==============================================
-- 自定义 Neovim 命令：IceColorscheme
-- 作用：提供手动切换主题的命令接口，支持自动补全和主题持久化
-- 使用方式：:IceColorscheme 主题名称（如 :IceColorscheme catppuccin）
-- ==============================================
vim.api.nvim_create_user_command("IceColorscheme", function(args)
    local colorscheme = args.args  -- 获取命令后输入的主题名称参数
    utils.colorscheme(colorscheme)  -- 调用上面的主题切换函数，应用主题

    -- 主题持久化：将当前主题名称保存到缓存文件，下次启动自动加载
    local colorscheme_cache = vim.fs.joinpath(vim.fn.stdpath "data", "colorscheme")  -- 缓存文件路径：~/.local/share/nvim/colorscheme
    local f = io.open(colorscheme_cache, "w")  -- 打开/创建缓存文件（可写模式）
    f:write(colorscheme)  -- 将主题名称写入缓存文件
    f:close()  -- 关闭文件，确保数据写入磁盘
end, {
    nargs = 1,  -- 指定命令必须接收 1 个参数（主题名称）
    complete = function(_, _)
        -- 命令自动补全：仅返回 Ice.colorschemes 中定义的有效主题名称
        return vim.tbl_keys(Ice.colorschemes)
    end,
})

-- ==============================================
-- 函数：通过 Telescope 可视化选择主题（快捷操作）
-- 作用：弹出 Telescope 窗口，支持模糊搜索、实时预览主题，回车确认切换
-- 依赖：Telescope.nvim 插件（未安装则函数无效果）
-- ==============================================
utils.select_colorscheme = function()
    -- 检查 Telescope 插件是否安装（pcall 捕获 require 异常，避免报错）
    local status, _ = pcall(require, "telescope")
    if not status then
        return  -- 未安装则终止函数
    end

    -- 引入 Telescope 核心模块
    local pickers = require "telescope.pickers"  -- 用于创建选择窗口
    local finders = require "telescope.finders"  -- 用于定义数据源
    local conf = require("telescope.config").values  -- 用于获取 Telescope 默认配置
    local actions = require "telescope.actions"  -- 用于绑定窗口操作快捷键
    local action_state = require "telescope.actions.state"  -- 用于获取窗口选中状态

    -- 定义 Telescope 选择器（主题选择窗口）
    local function picker(opts)
        opts = opts or {}  -- 处理默认参数（为空时使用默认配置）

        local colorschemes = Ice.colorschemes  -- 获取所有有效主题配置
        local suffix_current = " (current)"  -- 当前主题的标记文本
        local results = { Ice.colorscheme .. suffix_current }  -- 初始化结果列表，先加入当前主题（带标记）

        -- 遍历所有主题，将非当前主题加入结果列表（按定义顺序排序）
        for name, _ in require("core.utils").ordered_pair(colorschemes) do
            if name ~= Ice.colorscheme then
                results[#results + 1] = name
            end
        end

        -- 创建并显示 Telescope 选择窗口
        pickers
            .new(opts, {
                prompt_title = "Colorschemes",  -- 选择窗口标题
                finder = finders.new_table {  -- 配置数据源
                    entry_maker = function(entry)
                        -- 处理列表条目：移除当前主题的标记，提取纯主题名称
                        local pattern = string.gsub(suffix_current, "%(", "%%%(")  -- 转义正则特殊字符 "("
                        pattern = string.gsub(pattern, "%)", "%%%)")  -- 转义正则特殊字符 ")"
                        local colorscheme, _ = string.gsub(entry, pattern, "")  -- 移除标记文本

                        -- 返回 Telescope 要求的条目格式（value 为实际值，display 为显示文本）
                        return {
                            value = colorscheme,  -- 实际用于切换的主题名称
                            display = entry,      -- 窗口中显示的文本（含当前主题标记）
                            ordinal = entry,      -- 排序用的原始文本
                        }
                    end,
                    results = results,  -- 数据源：处理后的主题列表
                },
                sorter = conf.generic_sorter(opts),  -- 配置排序器：使用默认模糊排序
                attach_mappings = function(prompt_bufnr, _)
                    local original_colorscheme = Ice.colorscheme  -- 记录原始主题，用于未确认时回退
                    local should_restore_colorscheme = false  -- 标记是否需要回退主题

                    -- 辅助函数：根据当前选中条目切换主题
                    local function set_colorscheme_by_selection()
                        local selection = action_state.get_selected_entry()  -- 获取当前选中的条目
                        if selection == nil then
                            return  -- 无选中条目时直接返回
                        end

                        local colorscheme = selection.value  -- 获取选中的主题名称
                        utils.colorscheme(colorscheme)  -- 调用主题切换函数
                        return colorscheme  -- 返回切换后的主题名称
                    end

                    -- 增强快捷键：切换选中项（上下键）时，实时预览主题
                    require("telescope.actions.set").shift_selection:enhance {
                        post = function()
                            local colorscheme = set_colorscheme_by_selection()
                            -- 若切换到非原始主题，标记需要回退
                            if colorscheme ~= nil and colorscheme ~= original_colorscheme then
                                should_restore_colorscheme = true
                            end
                        end,
                    }

                    -- 增强快捷键：关闭窗口（ESC）时，若未确认选择则恢复原始主题
                    actions.close:enhance {
                        post = function()
                            if should_restore_colorscheme then
                                utils.colorscheme(original_colorscheme)
                            end
                        end,
                    }

                    -- 替换默认回车行为：确认选择并保存主题
                    actions.select_default:replace(function()
                        local colorscheme = set_colorscheme_by_selection()
                        if colorscheme == nil then
                            return  -- 无选中条目时直接返回
                        end

                        -- 保存主题到缓存文件（持久化）
                        local colorscheme_cache = vim.fs.joinpath(vim.fn.stdpath "data", "colorscheme")
                        local f = io.open(colorscheme_cache, "w")
                        f:write(colorscheme)
                        f:close()

                        should_restore_colorscheme = false  -- 已确认选择，无需回退

                        actions.close(prompt_bufnr)  -- 关闭选择窗口
                    end)
                    return true  -- 启用自定义快捷键映射
                end,
            })
            :find()  -- 显示选择窗口
    end

    picker()  -- 执行选择器函数，弹出主题选择窗口
end

-- ==============================================
-- 函数：通过 Telescope 查看/编辑配置文件（快捷操作）
-- 作用：扫描 Neovim 配置目录，弹出 Telescope 窗口，支持搜索、预览、编辑配置文件
-- 依赖：Telescope.nvim + plenary.nvim 插件（未安装则函数无效果）
-- ==============================================
utils.view_configuration = function()
    -- 检查 Telescope 插件是否安装
    local status, _ = pcall(require, "telescope")
    if not status then
        return  -- 未安装则终止函数
    end

    -- 引入所需模块
    local pickers = require "telescope.pickers"  -- 创建选择窗口
    local finders = require "telescope.finders"  -- 定义数据源
    local conf = require("telescope.config").values  -- 获取默认配置
    local actions = require "telescope.actions"  -- 绑定快捷键
    local action_state = require "telescope.actions.state"  -- 获取选中状态
    local previewers = require "telescope.previewers.buffer_previewer"  -- 文件预览器
    local from_entry = require "telescope.from_entry"  -- 解析条目路径

    -- 定义 Telescope 选择器（配置文件选择窗口）
    local function picker(opts)
        opts = opts or {}  -- 处理默认参数

        local config_root = vim.fn.stdpath "config"  -- 获取 Neovim 配置根目录（~/.config/nvim）
        -- 扫描配置目录下的所有文件（含隐藏文件），依赖 plenary.nvim 的 scandir 功能
        local files = require("plenary.scandir").scan_dir(config_root, { hidden = true })
        local sep = require("plenary.path").path.sep  -- 获取系统路径分隔符（Windows \ / Linux/macOS /）
        local picker_sep = "/"  -- 选择窗口中统一显示的路径分隔符（避免跨系统差异）
        local results = {}  -- 存储过滤后的配置文件相对路径

        -- 生成 Telescope 文件条目格式（默认处理方式）
        local make_entry = require("telescope.make_entry").gen_from_file

        -- 处理扫描结果：简化路径并过滤无用文件
        for _, item in pairs(files) do
            item = string.gsub(item, config_root, "")  -- 移除配置根目录前缀，保留相对路径
            item = string.gsub(item, sep, picker_sep)  -- 统一路径分隔符为 /
            item = string.sub(item, 2)  -- 移除路径开头的分隔符（如 "/init.lua" → "init.lua"）

            -- 过滤规则：不显示 bin、.git、screenshots 目录下的文件（避免无关文件干扰）
            if not (string.find(item, "bin/") or string.find(item, ".git/") or string.find(item, "screenshots/")) then
                results[#results + 1] = item  -- 将过滤后的路径加入结果列表
            end
        end

        -- 创建并显示配置文件选择窗口
        pickers
            .new(opts, {
                prompt_title = "Configuration Files",  -- 窗口标题
                finder = finders.new_table {  -- 配置数据源
                    entry_maker = make_entry(opts),  -- 使用默认文件条目格式
                    results = results,  -- 过滤后的配置文件列表
                },
                previewer = (function(_opts)  -- 配置文件预览器（显示选中文件内容）
                    _opts = _opts or {}
                    return previewers.new_buffer_previewer {
                        title = "Configuration",  -- 预览窗口标题
                        get_buffer_by_name = function(_, entry)
                            -- 根据条目获取文件路径
                            return from_entry.path(entry, false)
                        end,
                        define_preview = function(self, entry)
                            -- 拼接完整文件路径（配置根目录 + 相对路径）
                            local p = vim.fs.joinpath(config_root, entry.filename)
                            if p == nil or p == "" then
                                return  -- 路径无效时不显示预览
                            end
                            -- 调用 Telescope 默认缓冲区预览器，显示文件内容
                            conf.buffer_previewer_maker(p, self.state.bufnr, {
                                bufname = self.state.bufname,
                                winid = self.state.winid,
                                preview = _opts.preview,
                                file_encoding = _opts.file_encoding,
                            })
                        end,
                    }
                end)(opts),
                sorter = conf.generic_sorter(opts),  -- 排序器：默认模糊排序
                attach_mappings = function(prompt_bufnr, _)
                    -- 替换默认回车行为：打开选中的配置文件
                    actions.select_default:replace(function()
                        actions.close(prompt_bufnr)  -- 关闭选择窗口

                        local selected_entry = action_state.get_selected_entry()  -- 获取选中条目
                        if selected_entry ~= nil then
                            local selection = selected_entry[1]  -- 获取相对路径
                            selection = string.gsub(selection, picker_sep, sep)  -- 恢复系统路径分隔符
                            local full_path = vim.fs.joinpath(config_root, selection)  -- 拼接完整路径

                            vim.cmd("edit " .. full_path)  -- 以编辑模式打开选中的配置文件
                        end
                    end)
                    return true  -- 启用自定义快捷键映射
                end,
            })
            :find()  -- 显示配置文件选择窗口
    end

    picker()  -- 执行选择器函数，弹出窗口
end

return utils  -- 导出工具函数模块，供其他文件 require 使用