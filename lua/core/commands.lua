-- ==============================================
-- 核心自定义命令配置文件：IceNvim 专属便捷命令集合
-- 作用：将常用功能封装为 :命令 形式，新手可直接调用（无需记复杂快捷键/代码）
-- 所有命令均支持「普通模式输入 :命令名 回车」执行，附带详细使用说明
-- 注释包含「功能+逻辑+注意点+扩展知识」，新手能轻松理解每一步作用
-- ==============================================

-- 窗口样式配置函数：统一所有自定义命令弹出窗口的样式（复用逻辑，避免重复代码）
-- 参数说明：
-- - win：目标窗口的 ID（要配置的窗口）
-- - buf：窗口对应的缓冲区 ID（存储窗口内容的内存区域）
-- 核心目的：让所有弹出窗口风格一致，降低新手操作成本（比如统一用 q 关闭）
local function config_window(win, buf)
    -- 绑定关闭快捷键：普通模式（n）按 q 关闭当前窗口
    -- <C-w>c 是 Neovim 内置快捷键：Ctrl+w 组合键后按 c，含义是「关闭当前窗口」
    -- { buffer = buf }：快捷键仅在当前缓冲区生效，不影响其他文件/窗口（避免全局冲突）
    vim.keymap.set("n", "q", "<C-w>c", { buffer = buf })

    -- 关闭窗口的行号显示（弹出窗口无需行号，节省空间且更整洁）
    -- vim.api.nvim_set_option_value：Neovim 官方 API，用于设置选项值
    -- { win = win }：选项仅对当前窗口生效（局部配置，不修改全局设置）
    vim.api.nvim_set_option_value("number", false, { win = win })
    -- 关闭窗口的相对行号显示（与行号保持一致，避免混乱）
    vim.api.nvim_set_option_value("relativenumber", false, { win = win })
    -- 设置缓冲区为不可修改（防止误编辑弹出窗口的内容，保护数据）
    -- { buf = buf }：选项仅对当前缓冲区生效（其他文件可正常编辑）
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
    -- 关闭窗口的符号列（符号列用于显示断点、LSP 提示等，弹出窗口无需显示）
    vim.api.nvim_set_option_value("signcolumn", "no", { win = win })
    -- 关闭窗口的光标行高亮（弹出窗口内容少，无需高亮定位光标）
    vim.api.nvim_set_option_value("cursorline", false, { win = win })
    -- 清空窗口的 80 列参考线（弹出窗口内容短，无需行宽限制）
    vim.api.nvim_set_option_value("colorcolumn", "", { win = win })
    -- 设置文件末尾填充字符：将默认的 "~" 改为空格（视觉更整洁）
    -- eob 是 end-of-buffer 的缩写，指文件内容之外的空白区域
    vim.api.nvim_set_option_value("fillchars", "eob: ", { win = win })
end

-- 自定义命令 1：:IceAbout —— 查看 IceNvim 配置基本信息
-- 使用场景：想了解配置的作者、仓库地址、版权信息时调用
-- 执行方式：普通模式输入 :IceAbout 并回车
vim.api.nvim_create_user_command("IceAbout", function()
    -- 创建临时缓冲区：存储 About 窗口的文本内容
    -- 参数说明：
    -- - false：不加入缓冲区列表（关闭后不残留，不占用资源）
    -- - true：标记为临时缓冲区（退出窗口后自动删除，无需手动清理）
    local buf = vim.api.nvim_create_buf(false, true)

    -- 获取当前窗口的宽高（用于计算弹出窗口的位置，实现居中显示）
    local win_width = vim.fn.winwidth(0)  -- 0 表示「当前活动窗口」
    local win_height = vim.fn.winheight(0)
    local popup_width = 80  -- 弹出窗口固定宽度（80 列，适合显示文本）
    local popup_height = math.floor(win_height * 0.3)  -- 弹出窗口高度（占当前窗口 30%）
    -- 水平居中计算：(当前窗口宽度 - 弹出窗口宽度) / 2，向下取整避免错位
    local popup_left = math.floor((win_width - popup_width) / 2)
    -- 垂直居中计算：(当前窗口高度 - 弹出窗口高度) / 2，向下取整
    local popup_top = math.floor((win_height - popup_height) / 2)

    -- 向缓冲区添加文本内容（About 窗口要显示的信息）
    -- vim.api.nvim_buf_set_lines：批量设置缓冲区的行内容
    -- 参数说明：
    -- - buf：目标缓冲区 ID（上面创建的临时缓冲区）
    -- - 0：起始行（从第 0 行开始，即缓冲区顶部）
    -- - -1：结束行（-1 表示覆盖缓冲区所有现有内容，若缓冲区为空则直接添加）
    -- - false：是否反向插入（false 表示按列表顺序正向插入）
    -- 最后一个参数：文本列表，每个元素对应一行内容（空字符串 "" 表示空行，用于排版）
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "",
        "A beautiful, powerful and highly customizable neovim config.",  -- 配置描述：美观、强大、高可定制
        "",
        "Author: Shaobin Jiang",  -- 配置作者
        "",
        "Url: https://github.com/Shaobin-Jiang/IceNvim",  -- 配置仓库地址（可下载更新、提交反馈）
        "",
        string.format("Copyright © 2022-%s Shaobin Jiang", os.date "%Y"),  -- 版权信息（年份自动更新为当前年）
    })

    -- 打开弹出窗口：显示缓冲区内容
    -- vim.api.nvim_open_win：创建并打开新窗口
    -- 参数说明：
    -- - buf：要显示的缓冲区 ID（上面添加了文本的缓冲区）
    -- - true：是否自动聚焦窗口（true 表示创建后直接切换到该窗口）
    -- 第三个参数：窗口配置选项（控制窗口样式、位置等）
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "win",  -- 相对定位基准：当前窗口（不是整个屏幕，适配分屏场景）
        width = popup_width,  -- 窗口宽度（上面定义的 80）
        height = popup_height,  -- 窗口高度（上面定义的 30%）
        row = popup_top,  -- 窗口垂直位置（上面计算的居中值）
        col = popup_left,  -- 窗口水平位置（上面计算的居中值）
        border = "rounded",  -- 窗口边框样式：圆角边框（更美观，区别于普通编辑窗口）
        title = "About IceNvim",  -- 窗口标题（明确窗口功能）
        title_pos = "center",  -- 标题位置：居中
        footer = "Press q to close window",  -- 窗口底部提示（告诉新手如何关闭）
        footer_pos = "center",  -- 底部提示位置：居中
    })

    -- 应用统一窗口样式：调用上面定义的 config_window 函数，设置 q 关闭、无行号等
    config_window(win, buf)
end, { nargs = 0 })  -- 命令参数配置：nargs = 0 表示该命令不需要传入任何参数

-- 自定义命令 2：:IceCheckIcons —— 查看已配置的 Nerd Font 图标
-- 使用场景：验证 Nerd Font 字体是否正常加载（避免图标显示乱码）、查看图标对应名称
-- 执行方式：普通模式输入 :IceCheckIcons 并回车
-- 前提：必须安装 Nerd Font 字体（否则图标会显示为方框/乱码，需手动安装）
vim.api.nvim_create_user_command("IceCheckIcons", function()
    -- 创建临时缓冲区：存储图标列表内容
    local buf = vim.api.nvim_create_buf(false, true)

    -- 图标显示格式配置（确保图标排列整齐）
    local item_width = 24  -- 每个图标项的总宽度（字符数，包含名称和图标）
    local item_name_width = 18  -- 图标名称的固定宽度（字符数，不足则用空格填充）
    local win_width = vim.fn.winwidth(0)  -- 当前窗口宽度
    local win_height = vim.fn.winheight(0)  -- 当前窗口高度
    -- 计算每行可显示的图标数量：当前窗口宽度 / 每个图标项宽度 - 1（预留边距，避免溢出）
    local columns = math.floor(win_width / item_width) - 1

    local content = {}  -- 存储最终要显示的图标内容（按行组织）
    local items_in_row = 0  -- 记录当前行已添加的图标数量
    local current_line = ""  -- 记录当前行的文本内容
    local total_items = 0  -- 记录总图标数量

    -- 遍历 Ice.symbols 中的所有图标（Ice.symbols 在 core/symbols.lua 中定义，存储所有图标配置）
    -- require("core.utils").ordered_pair：有序遍历 table（保持图标顺序与配置一致，普通 pairs 是无序的）
    for icon_name, icon_symbol in require("core.utils").ordered_pair(Ice.symbols) do
        total_items = total_items + 1  -- 总图标数量+1

        -- 格式化单个图标项：名称 + 空格填充 + 图标 + 空格填充（确保每个项宽度一致）
        -- string.rep(" ", n)：生成 n 个空格（用于对齐，让所有图标项排列整齐）
        -- vim.fn.strdisplaywidth(icon_symbol)：计算图标的「显示宽度」（图标是特殊字符，#icon_symbol 无法正确计算）
        current_line = string.format(
            "%s%s%s%s%s",
            current_line,  -- 拼接当前行已有的图标项（同一行显示多个图标）
            icon_name,  -- 图标名称（如 "error"、"warning"、"git_add"）
            string.rep(" ", item_name_width - #icon_name),  -- 名称后填充空格（确保名称占 18 字符）
            icon_symbol,  -- 图标符号（如 ""、""、""）
            -- 图标后填充空格：确保整个图标项占 24 字符（总宽度 - 名称宽度 - 图标显示宽度）
            string.rep(" ", item_width - item_name_width - vim.fn.strdisplaywidth(icon_symbol))
        )

        items_in_row = items_in_row + 1  -- 当前行图标数量+1

        -- 当当前行图标数量达到最大列数（columns），则将当前行添加到内容列表，准备下一行
        if items_in_row == columns then
            content[#content + 1] = current_line  -- 新增一行到内容列表
            items_in_row = 0  -- 重置当前行图标数量
            current_line = ""  -- 重置当前行文本
        end
    end

    -- 将格式化后的图标内容添加到缓冲区（显示到窗口）
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

    -- 计算图标窗口的尺寸和位置（居中显示）
    local popup_width = columns * item_width  -- 窗口宽度 = 每行图标数 * 每个图标项宽度
    -- 窗口高度 = 总图标数 / 每行图标数（向上取整，确保所有图标都能显示）
    local popup_height = math.ceil(total_items / columns)
    local popup_left = math.floor((win_width - popup_width) / 2)  -- 水平居中
    local popup_top = math.floor((win_height - popup_height) / 2)  -- 垂直居中

    -- 打开窗口显示图标列表
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "win",
        width = popup_width,
        height = popup_height,
        row = popup_top,
        col = popup_left,
        border = "rounded",
        title = "Check Nerd Font Icons",  -- 窗口标题（明确功能：检查 Nerd Font 图标）
        title_pos = "center",
        footer = "Press q to close window",  -- 关闭提示（新手友好）
        footer_pos = "center",
    })

    -- 应用统一窗口样式（q 关闭、无行号等）
    config_window(win, buf)
    -- 禁用窗口自动换行（图标列表需要横向排列，换行后会错乱）
    vim.api.nvim_set_option_value("wrap", false, { win = win })
end, { nargs = 0 })  -- 该命令不需要参数

-- 自定义命令 3：:IceCheckPlugins —— 检查插件更新状态（标记过时插件）
-- 使用场景：想知道哪些插件长期未更新（超过 30 天），是否需要升级
-- 执行方式：普通模式输入 :IceCheckPlugins 并回车
-- 核心逻辑：通过 git 命令获取每个插件的最后提交时间，与当前时间对比，标记过时插件
vim.api.nvim_create_user_command("IceCheckPlugins", function()
    -- 插件安装路径：Lazy.nvim 默认安装目录（~/.local/share/nvim/lazy）
    -- vim.fn.stdpath("data")：Neovim 数据目录（默认 ~/.local/share/nvim）
    local plugins_path = vim.fs.joinpath(vim.fn.stdpath "data", "lazy")
    -- 扫描插件目录：获取目录下所有文件/子目录（vim.uv 是 Neovim 内置异步 I/O 库）
    local dir = vim.uv.fs_scandir(plugins_path)

    local stale_plugins = {}  -- 存储过时插件列表（格式：{ {插件名, 过时天数}, ... }）
    local total_plugins = 0  -- 已扫描的有效插件数量（排除非插件目录）

    -- 如果插件目录存在（即已安装插件）
    if dir ~= nil then
        -- 创建协程（coroutine）：异步处理插件扫描，避免阻塞 Neovim 主线程
        -- 为什么用协程？
        -- 1. 每个插件的更新时间需要调用 git 命令获取（异步操作），若同步处理会导致 Neovim 卡顿
        -- 2. 协程可暂停/恢复执行，等待所有异步操作完成后再显示结果
        local co = coroutine.create(function()
            local checked_count = 1  -- 已完成检查的插件数量
            -- 循环等待：直到所有插件都检查完成（total_plugins 是总插件数）
            while total_plugins > checked_count do
                coroutine.yield()  -- 暂停协程，等待下一个插件检查完成
                checked_count = checked_count + 1  -- 恢复后更新已检查数量
            end

            -- 对过时插件列表排序：按过时天数「降序」排列（最旧的插件排在最前面）
            table.sort(stale_plugins, function(a, b)
                return a[2] > b[2]  -- a[2] 是插件 a 的过时天数，b[2] 是插件 b 的过时天数
            end)

            local old_plugin_count = 0  -- 严重过时插件数量（超过 365 天未更新）
            -- 格式化插件报告：将插件列表转换为可读文本（每行一个插件）
            local report = vim.tbl_map(function(plugin_info)
                local plugin_name, stale_days = plugin_info[1], plugin_info[2]
                -- 若过时超过 365 天，标记为严重过时
                if stale_days > 365 then
                    old_plugin_count = old_plugin_count + 1
                end
                -- 格式化文本：「插件名: 过时天数 days」（如 "nvim-treesitter: 120 days"）
                return string.format("%s: %d days", plugin_name, stale_days)
            end, stale_plugins)

            -- 原作者备注：在协程中直接操作缓冲区/窗口可能导致异常
            -- 解决方案：用 vim.schedule 将操作推迟到 Neovim 主线程空闲时执行（安全操作 UI）
            vim.schedule(function()
                -- 创建临时缓冲区：存储插件更新报告
                local report_buf = vim.api.nvim_create_buf(false, true)

                -- 计算报告窗口的尺寸和位置（居中显示）
                local win_width = vim.fn.winwidth(0)
                local win_height = vim.fn.winheight(0)
                local report_width = math.floor(win_width * 0.5)  -- 窗口宽度占当前窗口 50%
                -- 窗口高度：取「当前窗口 70% 高度」和「报告行数」的最小值（避免窗口过高）
                local report_height = math.min(math.floor(win_height * 0.7), #stale_plugins)
                local popup_left = math.floor((win_width - report_width) / 2)  -- 水平居中
                local popup_top = math.floor((win_height - report_height) / 2)  -- 垂直居中

                -- 将格式化后的报告添加到缓冲区（0 到 -1 表示覆盖整个缓冲区）
                -- 原作者备注：若将 end 设为 0 而非 -1，缓冲区最后会多一行空行
                vim.api.nvim_buf_set_lines(report_buf, 0, -1, false, report)

                -- 创建命名空间：用于给不同过时程度的插件添加颜色高亮（区分严重程度）
                -- 命名空间（namespace）：Neovim 中隔离不同功能高亮的容器，避免冲突
                local ns_id = vim.api.nvim_create_namespace "out-of-date-plugins"
                -- 严重过时插件（>365 天）：用 ErrorMsg 高亮组（默认红色）标记
                for line = 0, old_plugin_count - 1 do
                    -- vim.hl.range：给缓冲区指定行范围添加高亮
                    -- 参数说明：缓冲区 ID、命名空间 ID、高亮组、起始位置（行，列）、结束位置（行，列）、额外选项
                    vim.hl.range(report_buf, ns_id, "ErrorMsg", { line, 0 }, { line, -1 }, {})
                end
                -- 普通过时插件（30-365 天）：用 WarningMsg 高亮组（默认黄色）标记
                for line = old_plugin_count, #stale_plugins - 1 do
                    vim.hl.range(report_buf, ns_id, "WarningMsg", { line, 0 }, { line, -1 }, {})
                end

                -- 打开窗口显示插件更新报告
                local win = vim.api.nvim_open_win(report_buf, true, {
                    relative = "win",
                    width = report_width,
                    height = report_height,
                    row = popup_top,
                    col = popup_left,
                    border = "rounded",
                    -- 窗口标题：显示过时插件总数（明确报告核心信息）
                    title = string.format("%d plugins possibly out of date", #stale_plugins),
                    title_pos = "center",
                })

                -- 应用统一窗口样式（q 关闭、无行号等）
                config_window(win, report_buf)
            end)
        end)

        -- 循环扫描插件目录中的所有条目（文件/子目录）
        while true do
            -- 逐个获取目录条目：item 是文件名/目录名，item_type 是类型（file/directory）
            local item, item_type = vim.uv.fs_scandir_next(dir)

            if not item then
                break  -- 没有更多条目时，退出循环
            end

            -- 筛选有效插件目录：仅处理子目录，且排除 "readme" 目录（非插件）
            if item_type == "directory" and item ~= "readme" then
                total_plugins = total_plugins + 1  -- 有效插件数量+1

                -- 异步执行 git 命令：获取插件最后一次提交的日期（用于计算过时天数）
                -- vim.system：Neovim 内置异步执行外部命令的函数（不阻塞主线程）
                vim.system(
                    { "git", "log", "-1", "--format=%cd", "--date=short" },  -- git 命令：获取最近1次提交的日期（格式：YYYY-MM-DD）
                    { cwd = vim.fs.joinpath(plugins_path, item) },  -- 命令执行目录：当前插件的安装目录
                    function(obj)  -- 命令执行完成后的回调函数（obj 是命令输出结果）
                        -- 清理 git 命令输出的换行符（stdout 是命令输出内容，可能带 \n）
                        local last_update_date = string.gsub(obj.stdout, "\n", "")  -- 格式示例："2023-05-10"
                        -- 提取日期中的年、月、日（字符串截取：从第1-4字符取年，6-7取月，9-10取日）
                        local year = string.sub(last_update_date, 1, 4)
                        local month = string.sub(last_update_date, 6, 7)
                        local day = string.sub(last_update_date, 9, 10)
                        -- 将日期转换为时间戳（秒数，从 1970-01-01 开始计算）
                        local last_update_timestamp = os.time { year = year, month = month, day = day }
                        local current_timestamp = os.time()  -- 获取当前时间戳
                        -- 计算过时天数：(当前时间戳 - 最后更新时间戳) / 86400（一天的秒数），向下取整
                        local stale_days = math.floor((current_timestamp - last_update_timestamp) / 86400)

                        -- 若插件过时超过 30 天，添加到过时插件列表
                        if stale_days > 30 then
                            stale_plugins[#stale_plugins + 1] = { item, stale_days }
                        end

                        -- 恢复协程执行（通知协程：当前插件已检查完成）
                        coroutine.resume(co)
                    end
                )
            end
        end
    end
end, { nargs = 0 })  -- 该命令不需要参数

-- 自定义命令 4：:IceUpdate —— 更新 IceNvim 配置本身
-- 使用场景：想获取配置的最新功能/修复时，更新本地配置文件
-- 执行方式：普通模式输入 :IceUpdate 并回车
-- 核心逻辑：通过 git pull 拉取远程仓库（GitHub）的最新配置（配置本身是通过 git 管理的）
vim.api.nvim_create_user_command("IceUpdate", function()
    -- 异步执行 git pull 命令：拉取远程配置仓库的最新代码
    vim.system(
        { "git", "pull" },  -- git pull：拉取远程分支并合并到本地
        { cwd = vim.fn.stdpath "config", text = true },  -- 执行目录：Neovim 配置目录（~/.config/nvim）
        function(out)  -- 命令执行完成后的回调函数
            -- 根据命令退出码判断是否更新成功（out.code 为 0 表示成功）
            if out.code == 0 then
                -- 显示成功通知：vim.notify 是 Neovim 内置通知函数
                vim.notify "IceNvim up to date"
            else
                -- 显示失败通知：指定警告级别（vim.log.levels.WARN），输出错误信息（out.stderr）
                vim.notify("IceNvim update failed: " .. out.stderr, vim.log.levels.WARN)
            end
        end
    )
end, { nargs = 0 })  -- 该命令不需要参数

-- 自定义命令 5：:IceHealth —— 检查 IceNvim 配置的健康状态
-- 使用场景：配置出现异常（如插件加载失败、依赖缺失）时，查看诊断信息
-- 执行方式：普通模式输入 :IceHealth 并回车
-- 核心逻辑：调用 Neovim 内置的 :checkhealth 命令，指定检查「core」模块（IceNvim 核心健康检查）
vim.api.nvim_create_user_command("IceHealth", "checkhealth core", { nargs = 0 })

-- 自定义命令 6：:IceRepeat —— 重复执行指定命令（支持计数）
-- 使用场景：需要重复执行某个命令时（如重复保存、重复格式化），避免手动输入多次
-- 执行方式：普通模式输入「数字 + :IceRepeat 命令」（如 3:IceRepeat w 表示保存 3 次）
-- 核心逻辑：通过 v:count1 获取用户输入的计数（默认 1 次），循环执行指定命令
vim.api.nvim_create_user_command("IceRepeat", function(args)
    -- 循环 v:count1 次（v:count1 是 Neovim 内置变量，存储用户输入的前置数字，默认 1）
    for _ = 1, vim.v.count1 do
        vim.cmd(args.args)  -- 执行用户指定的命令（args.args 是用户传入的命令参数）
    end
end, { 
    nargs = "+",  -- 命令需要传入至少 1 个参数（即要重复的命令）
    complete = "command"  -- 自动补全：仅补全 Neovim 已存在的命令（提升使用体验）
})

-- 自定义命令 7：:IceView —— 在外部缓冲区查看命令输出结果
-- 使用场景：某些命令输出内容过多（如 :set 查看所有选项），在当前窗口显示不全时使用
-- 执行方式：
-- 1. :IceView 命令名（如 :IceView set）：查看命令输出
-- 2. :IceView（无参数）：打开上次的输出文件
-- 核心逻辑：将命令输出写入临时文件，再用 Neovim 打开该文件
vim.api.nvim_create_user_command("IceView", function(args)
    -- 定义输出文件路径：~/.local/share/nvim/ice-view.txt（Neovim 数据目录下的临时文件）
    local output_path = vim.fs.joinpath(vim.fn.stdpath "data", "ice-view.txt")
    
    if args.args == "" then
        -- 无参数时：直接打开输出文件（查看上次的命令输出）
        vim.cmd("edit " .. output_path)
    else
        -- 有参数时：执行命令并将输出写入文件
        vim.cmd(string.format(
            [[
                redir! > %s  " 重定向命令输出到文件（! 表示覆盖原有内容）
                silent %s       " 静默执行用户指定的命令（不在命令行显示输出）
                redir END       " 结束输出重定向
                edit %s         " 打开输出文件，显示结果
            ]],
            output_path,  -- 输出文件路径
            args.args,    -- 用户指定的命令
            output_path   -- 再次指定文件路径（确保打开正确的文件）
        ))
    end
end, { 
    nargs = "*",  -- 命令可传入 0 个或多个参数（支持带空格的命令）
    complete = "command"  -- 自动补全：仅补全 Neovim 已存在的命令
})