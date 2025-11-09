-- ==============================================
-- IceNvim 核心快捷键配置文件：自定义高效操作快捷键
-- 作用：覆盖 Neovim 默认快捷键，优化编辑、窗口、终端等场景的操作流程
-- 核心特点：
-- 1. 跨模式兼容：支持普通模式（n）、插入模式（i）、视觉模式（v）、终端模式（t）、命令模式（c）
-- 2. 语义化绑定：快捷键与功能强关联（如 <C-s> 保存、<C-t> 打开终端），新手易记
-- 3. 智能适配：自动兼容 Linux/Mac/Windows 系统，终端命令自动选择当前系统可用工具
-- 4. 细节优化：解决默认快捷键痛点（如空白行注释、多行合并增强）
-- 注释说明：逐行解释快捷键功能、使用场景、实现逻辑，新手能快速上手所有绑定
-- ==============================================

-- 1. 全局快捷键前缀配置（所有自定义快捷键的基础）
-- vim.g.mapleader：全局快捷键前缀（默认设置为 空格 键）
-- 原因：空格键在键盘中央，易按压，且默认无功能，适合作为快捷键前缀避免冲突
-- 用途：所有需要 <leader> 触发的快捷键（如 <leader>ul 打开 Lazy 插件面板）都基于此
vim.g.mapleader = " "
-- vim.g.maplocalleader：局部快捷键前缀（默认设置为 逗号 , 键）
-- 原因：逗号键位置顺手，用于缓冲区/文件类型专属快捷键（避免与全局快捷键冲突）
vim.g.maplocalleader = ","

-- 2. 注释功能生成器：创建「在指定位置插入注释」的通用函数
-- 核心逻辑：读取当前文件的注释格式（commentstring），自动生成对应风格的注释
-- 解决痛点：不同文件类型（如 Python 的 #、JS 的 //、CSS 的 /* */）注释格式不同，无需手动切换
-- 参数说明：
-- - pos：注释插入位置，可选值：
--   - "above"：在当前行上方插入注释
--   - "below"：在当前行下方插入注释
--   - "end"：在当前行末尾插入注释
---@param pos string Can be one of "above" / "below" / "end"; indicates where the comment is to be inserted
local function comment(pos)
    -- 返回实际执行的快捷键函数（闭包形式，保留 pos 参数）
    return function()
        -- 获取当前光标所在行号（vim.api.nvim_win_get_cursor(0) 返回 {行号, 列号}，0 表示当前窗口）
        local row = vim.api.nvim_win_get_cursor(0)[1]
        -- 获取当前缓冲区的总行数（判断是否为最后一行）
        local total_lines = vim.api.nvim_buf_line_count(0)
        -- 获取当前缓冲区的注释格式（如 Python 是 "# %s"，JS 是 "// %s"）
        local commentstring = vim.bo.commentstring
        -- 提取纯注释符号（去除 commentstring 中的 %s 占位符，%s 表示注释内容位置）
        local cmt = string.gsub(commentstring, "%%s", "")
        -- 找到 %s 在注释格式中的位置（用于后续光标定位）
        local index = string.find(commentstring, "%%s")

        local target_line  -- 目标行（用于获取缩进、判断是否为空行等）
        if pos == "below" then
            -- 插入到当前行下方时：复用下一行的缩进格式（保持代码对齐）
            -- 特殊处理：如果当前行是最后一行，就用当前行的缩进
            if row == total_lines then
                -- 获取当前行内容（row-1 是因为缓冲区行号从 0 开始）
                target_line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
            else
                -- 获取下一行内容
                target_line = vim.api.nvim_buf_get_lines(0, row, row + 1, true)[1]
            end
        else
            -- 插入到上方/行尾时：用当前行的内容
            target_line = vim.api.nvim_get_current_line()
        end

        if pos == "end" then
            -- 行尾插入注释：非空行需在注释前加空格（避免 "print()#注释" 这种不规范格式）
            if string.find(target_line, "%S") then  -- %S 匹配非空白字符，判断行是否非空
                cmt = " " .. cmt  -- 注释前加空格
                index = index + 1  -- 光标位置同步后移（跳过空格）
            end
            -- 替换当前行：在末尾添加注释
            vim.api.nvim_buf_set_lines(0, row - 1, row, false, { target_line .. cmt })
            -- 调整光标位置：移动到注释符号后（方便直接输入注释内容）
            vim.api.nvim_win_set_cursor(0, { row, #target_line + index - 2 })
        else
            -- 上方/下方插入注释：复用目标行的缩进（保持代码结构整齐）
            -- 找到目标行第一个非空白字符的位置（获取缩进部分）
            local line_start = string.find(target_line, "%S") or (#target_line + 1)
            -- 提取缩进部分（从行首到第一个非空白字符前的空格/tab）
            local blank = string.sub(target_line, 1, line_start - 1)

            if pos == "above" then
                -- 在当前行上方插入带缩进的注释（row-1 表示插入到当前行前面）
                vim.api.nvim_buf_set_lines(0, row - 1, row - 1, true, { blank .. cmt })
                -- 光标移动到新插入的注释行，且定位到注释符号后
                vim.api.nvim_win_set_cursor(0, { row, #blank + index - 2 })
            end

            if pos == "below" then
                -- 在当前行下方插入带缩进的注释（row 表示插入到当前行后面）
                vim.api.nvim_buf_set_lines(0, row, row, true, { blank .. cmt })
                -- 光标移动到新插入的注释行，且定位到注释符号后
                vim.api.nvim_win_set_cursor(0, { row + 1, #blank + index - 2 })
            end
        end

        -- 进入插入模式（a 命令：在光标后插入），方便直接输入注释内容
        vim.api.nvim_feedkeys("a", "n", false)
    end
end

-- 3. 单行注释切换函数：解决默认 gcc 快捷键不支持空白行的问题
-- 核心功能：
-- - 非空白行：调用 Neovim 内置注释切换（gcc 原功能，支持不同文件类型）
-- - 空白行：直接添加注释（默认 gcc 对空白行无效，此函数修复该痛点）
local function comment_line()
    -- 获取当前行内容
    local line = vim.api.nvim_get_current_line()

    -- 获取当前光标行号、注释格式、纯注释符号、%s 位置（同上面的 comment 函数）
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local commentstring = vim.bo.commentstring
    local cmt = string.gsub(commentstring, "%%s", "")
    local index = string.find(commentstring, "%%s")

    -- 如果当前行是空白行（无任何非空白字符）
    if not string.find(line, "%S") then
        -- 在空白行添加注释（保持原有缩进）
        vim.api.nvim_buf_set_lines(0, row - 1, row, false, { line .. cmt })
        -- 光标定位到注释符号后（方便输入注释）
        vim.api.nvim_win_set_cursor(0, { row, #line + index - 1 })
    else
        -- 非空白行：调用 Neovim 内置注释切换功能（支持注释/取消注释）
        -- 原作者备注：该 API 未在官方文档中明确说明，未来可能重命名（但目前稳定可用）
        require("vim._comment").toggle_lines(row, row, { row, 0 })
    end
end

-- 4. 多行合并增强函数：支持计数合并（默认 J 仅合并当前行和下一行）
-- 功能优化：输入数字 + J 可合并「数字+1」行（如 3J 合并 4 行，默认 3J 仅合并 3 行）
local function join_lines()
    -- 计算合并行数：vim.v.count1 是当前输入的计数（默认 1），+1 实现「计数+1行合并」
    local v_count = vim.v.count1 + 1
    -- 获取当前模式（普通模式 n / 视觉模式 v）
    local mode = vim.api.nvim_get_mode().mode
    local keys  -- 要执行的按键序列

    if mode == "n" then
        -- 普通模式：拼接「计数+J」（如 3 → "3J"，合并 4 行）
        keys = v_count .. "J"
    else
        -- 视觉模式：直接用 J（合并选中的所有行）
        keys = "J"
    end

    -- 执行按键序列：vim.api.nvim_replace_termcodes 处理特殊字符（如 <CR>），确保正确执行
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
end

-- 5. HTML 文件预览函数：用系统默认浏览器打开当前 HTML 文件
-- 适用场景：前端开发时快速预览页面效果，无需手动打开浏览器和查找文件
local function open_html_file()
    -- 仅当当前文件类型是 html 时生效（避免其他文件误触发）
    if vim.bo.filetype == "html" then
        local utils = require "core.utils"  -- 引入工具函数（判断系统类型）
        local command  -- 系统对应的打开命令

        -- 根据系统类型选择打开命令（跨平台兼容）
        if utils.is_linux or utils.is_wsl then
            command = "xdg-open"  -- Linux/WSL 系统默认文件打开命令
        elseif utils.is_windows then
            command = "explorer"  -- Windows 系统文件资源管理器命令
        else
            command = "open"      -- MacOS 系统默认打开命令
        end

        -- Windows 系统特殊处理：临时禁用 shellslash（避免路径分隔符问题）
        if require("core.utils").is_windows then
            local old_shellslash = vim.opt.shellslash  -- 保存原有设置
            vim.opt.shellslash = false  -- 禁用 shellslash（使用 \ 作为路径分隔符）
            -- 执行命令：! 表示调用外部命令，%:p 是当前文件的绝对路径
            vim.cmd(string.format('silent exec "!%s %%:p"', command))
            vim.opt.shellslash = old_shellslash  -- 恢复原有设置（避免影响其他功能）
        else
            -- 其他系统直接执行命令：silent 表示不显示命令执行结果（减少干扰）
            vim.cmd(string.format('silent exec "!%s %%:p"', command))
        end
    end
end

-- 6. 智能保存函数：仅当文件修改时才保存（避免重复保存未修改文件）
-- 优化点：保存后自动回到普通模式（如插入模式下按 <C-s> 保存后退出插入）
local function save_file()
    -- 判断当前缓冲区是否被修改（modified 选项为 true 表示已修改）
    local buffer_is_modified = vim.api.nvim_get_option_value("modified", { buf = 0 })
    if buffer_is_modified then
        vim.cmd "write"  -- 执行保存（等价于 :w 命令）
    else
        print "Buffer not modified. No writing is done."  -- 未修改时提示，避免用户困惑
    end
    -- 保存后回到普通模式（<Esc> 快捷键），避免停留在插入/视觉模式
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
end

-- 7. 跨模式撤销函数：支持在普通/插入/视觉模式下撤销，且撤销后回到普通模式
-- 解决痛点：默认 <C-z> 在插入模式下可能无效，且撤销后不会自动退出插入模式
local function undo()
    -- 获取当前模式
    local mode = vim.api.nvim_get_mode().mode

    -- 仅在普通/插入/视觉模式下执行撤销（其他模式如终端/命令模式不生效）
    if mode == "n" or mode == "i" or mode == "v" then
        vim.cmd "undo"  -- 执行撤销（等价于 u 命令）
        -- 撤销后回到普通模式（避免停留在插入模式影响后续操作）
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
    end
end

-- 8. 终端命令自动适配：根据系统选择可用的终端工具（Windows 系统优先选择更强大的终端）
local terminal_command  -- 存储最终的终端打开命令
if not require("core.utils").is_windows then
    -- 非 Windows 系统：使用 split 分屏打开终端，默认使用系统 $SHELL（如 bash/zsh）
    terminal_command = "<Cmd>split | terminal<CR>" -- let $SHELL decide the default shell
else
    -- Windows 系统：按优先级查找可用终端（pwsh > powershell > bash > cmd）
    local executables = { "pwsh", "powershell", "bash", "cmd" }
    -- 有序遍历终端列表（优先选择功能更强的 pwsh）
    for _, executable in require("core.utils").ordered_pair(executables) do
        -- 检查终端是否可执行
        if vim.fn.executable(executable) == 1 then
            -- 构建终端命令：split 分屏打开指定终端
            terminal_command = "<Cmd>split term://" .. executable .. "<CR>"
            break  -- 找到第一个可用终端后退出循环
        end
    end
end

-- ==============================================
-- 核心快捷键绑定表：所有自定义快捷键的集中配置
-- 配置格式：{ 模式列表, 快捷键, 执行函数/命令, 可选参数 }
-- 模式说明：
-- - n: 普通模式（Normal mode）
-- - i: 插入模式（Insert mode）
-- - v: 视觉模式（Visual mode）
-- - t: 终端模式（Terminal mode）
-- - c: 命令模式（Command mode）
-- ==============================================
Ice.keymap = {
    -- 1. 黑洞寄存器：删除内容不存入寄存器（避免覆盖剪贴板）
    -- 模式：普通/视觉模式，快捷键：\（反斜杠），功能：""_（黑洞寄存器）
    -- 用途：删除不需要的内容时，不影响剪贴板中的有用数据（如删除注释、空行）
    black_hole_register = { { "n", "v" }, "\\", '"_' },

    -- 2. 清空命令行：快速清除命令行输入（避免手动删除）
    -- 模式：所有模式，快捷键：<C-g>（Ctrl+g），功能：<Cmd>mode<CR>（显示模式信息，间接清空命令行）
    -- 用途：输入错误命令后，快速清空重新输入
    clear_cmd_line = { { "n", "i", "v", "t" }, "<C-g>", "<Cmd>mode<CR>" },

    -- 3. 命令模式光标控制：优化命令行输入体验（默认命令模式光标操作不便）
    -- 命令模式 右移：<C-f>（Ctrl+f）→ 右箭头，同普通模式右移习惯
    cmd_forward = { "c", "<C-f>", "<Right>", { silent = false } },
    -- 命令模式 左移：<C-b>（Ctrl+b）→ 左箭头
    cmd_backward = { "c", "<C-b>", "<Left>", { silent = false } },
    -- 命令模式 到行首：<C-a>（Ctrl+a）→ Home 键
    cmd_home = { "c", "<C-a>", "<Home>", { silent = false } },
    -- 命令模式 到行尾：<C-e>（Ctrl+e）→ End 键
    cmd_end = { "c", "<C-e>", "<End>", { silent = false } },
    -- 命令模式 按单词右移：<A-f>（Alt+f）→ Shift+右箭头
    cmd_word_forward = { "c", "<A-f>", "<S-Right>", { silent = false } },
    -- 命令模式 按单词左移：<A-b>（Alt+b）→ Shift+左箭头
    cmd_word_backward = { "c", "<A-b>", "<S-Left>", { silent = false } },

    -- 4. 注释快捷键（基于上面的 comment/comment_line 函数，支持所有文件类型）
    -- 单行注释切换：普通模式 gcc → 空白行添加注释，非空白行切换注释状态
    comment_line = { "n", "gcc", comment_line },
    -- 在当前行上方插入注释：普通模式 gcO → 自动缩进+注释，光标定位到注释后
    comment_above = { "n", "gcO", comment "above" },
    -- 在当前行下方插入注释：普通模式 gco → 自动缩进+注释，光标定位到注释后
    comment_below = { "n", "gco", comment "below" },
    -- 在当前行尾添加注释：普通模式 gcA → 非空行自动加空格，光标定位到注释后
    comment_end = { "n", "gcA", comment "end" },

    -- 5. 禁用鼠标快捷键（避免误触鼠标导致操作混乱）
    -- 禁用 Ctrl+左键点击：普通模式 <C-LeftMouse> → 空操作
    disable_ctrl_left_mouse = { "n", "<C-LeftMouse>", "" },
    -- 右键点击映射为左键点击：所有模式 <RightMouse> → <LeftMouse>（避免右键菜单干扰）
    disable_right_mouse = { { "n", "i", "v", "t" }, "<RightMouse>", "<LeftMouse>" },

    -- 6. 多行合并增强：普通/视觉模式 J → 支持计数合并（如 3J 合并 4 行）
    join_lines = { { "n", "v" }, "J", join_lines },

    -- 7. Lazy 插件面板：普通模式 <leader>ul → 打开 Lazy 插件的性能分析面板
    -- 用途：查看插件加载时间，排查性能问题
    lazy_profile = { "n", "<leader>ul", "<Cmd>Lazy profile<CR>" },

    -- 8. 快速新建行（不进入插入模式，保持普通模式操作流）
    -- 普通模式 <A-o>（Alt+o）→ 在当前行下方新建空行（类似 o 但不进入插入模式）
    new_line_below_normal = { "n", "<A-o>", "o<Esc>" },
    -- 普通模式 <A-O>（Alt+Shift+o）→ 在当前行上方新建空行（类似 O 但不进入插入模式）
    new_line_above_normal = { "n", "<A-O>", "O<Esc>" },

    -- 9. HTML 预览：普通模式 <A-b>（Alt+b）→ 用系统默认浏览器打开当前 HTML 文件
    open_html_file = { "n", "<A-b>", open_html_file },
    -- 打开终端：普通模式 <C-t>（Ctrl+t）→ 水平分屏打开终端（自动适配系统）
    open_terminal = { "n", "<C-t>", terminal_command },
    -- 终端模式退出：终端模式 <Esc> → 切换到普通模式（默认需按 <C-\><C-n>，简化操作）
    normal_mode_in_terminal = { "t", "<Esc>", "<C-\\><C-n>" },

    -- 10. 智能保存：普通/插入/视觉模式 <C-s>（Ctrl+s）→ 仅修改时保存，保存后回普通模式
    save_file = { { "n", "i", "v" }, "<C-s>", save_file },

    -- 11. 跨模式撤销：普通/插入/视觉/终端/命令模式 <C-z>（Ctrl+z）→ 撤销并回普通模式
    undo = { { "n", "i", "v", "t", "c" }, "<C-z>", undo },

    -- 12. 视觉行选中增强：普通模式 V → 选中整行（从行首到行尾，默认 V 可能不选中行尾空格）
    visual_line = { "n", "V", "0v$" },
}

-- 特殊处理：如果启用了 noplugin 模式（不加载插件），清空 Lazy 插件面板快捷键（避免报错）
if require("core.utils").noplugin then
    Ice.keymap.lazy_profile[3] = ""
end

-- ==============================================
-- 快捷键功能汇总（新手必备，快速查阅）
-- ==============================================
-- 一、基础操作快捷键
-- | 快捷键       | 模式         | 功能描述                                  | 适用场景                          |
-- |--------------|--------------|-------------------------------------------|-----------------------------------|
-- | <C-s>        | n/i/v        | 智能保存（仅修改时保存，保存后回普通模式） | 编辑文件后快速保存                |
-- | <C-z>        | n/i/v/t/c    | 跨模式撤销（撤销后回普通模式）            | 输入错误后快速撤销                |
-- | <C-g>        | 所有模式     | 清空命令行输入                            | 命令输入错误后重新输入            |
-- | \（反斜杠）  | n/v          | 黑洞寄存器删除（不影响剪贴板）            | 删除无用内容（如注释、空行）      |
-- | J            | n/v          | 多行合并（支持计数，如 3J 合并 4 行）     | 合并连续行（如代码块、文本段落）  |
-- | V            | n            | 选中整行（行首到行尾）                    | 快速选中单行代码                  |
-- | <A-o>        | n            | 下方新建空行（不进入插入模式）            | 快速添加空行，保持普通模式操作    |
-- | <A-O>        | n            | 上方新建空行（不进入插入模式）            | 快速添加空行，保持普通模式操作    |

-- 二、注释快捷键（支持所有文件类型，自动适配注释格式）
-- | 快捷键       | 模式         | 功能描述                                  | 适用场景                          |
-- |--------------|--------------|-------------------------------------------|-----------------------------------|
-- | gcc          | n            | 单行注释切换（空白行添加注释，非空白行切换）| 快速注释/取消注释单行代码          |
-- | gcO          | n            | 当前行上方插入注释（自动缩进，光标定位后）| 在代码块前添加注释说明            |
-- | gco          | n            | 当前行下方插入注释（自动缩进，光标定位后）| 在代码块后添加注释说明            |
-- | gcA          | n            | 当前行尾添加注释（非空行自动加空格）      | 给代码行添加行尾注释              |

-- 三、命令模式快捷键（优化命令行输入体验）
-- | 快捷键       | 模式         | 功能描述                                  | 适用场景                          |
-- |--------------|--------------|-------------------------------------------|-----------------------------------|
-- | <C-f>        | c            | 命令行右移                                 | 调整命令输入位置                  |
-- | <C-b>        | c            | 命令行左移                                 | 调整命令输入位置                  |
-- | <C-a>        | c            | 命令行到行首                               | 快速修改命令开头                  |
-- | <C-e>        | c            | 命令行到行尾                               | 快速修改命令结尾                  |
-- | <A-f>        | c            | 命令行按单词右移                           | 快速跳过单词调整位置              |
-- | <A-b>        | c            | 命令行按单词左移                           | 快速跳过单词调整位置              |

-- 四、终端/浏览器快捷键
-- | 快捷键       | 模式         | 功能描述                                  | 适用场景                          |
-- |--------------|--------------|-------------------------------------------|-----------------------------------|
-- | <C-t>        | n            | 水平分屏打开终端（自动适配系统）          | 编辑时快速打开终端执行命令        |
-- | <Esc>        | t            | 终端模式切换到普通模式                    | 终端中操作完成后返回编辑          |
-- | <A-b>        | n            | 用默认浏览器打开当前 HTML 文件            | 前端开发预览页面效果              |

-- 五、插件/工具快捷键
-- | 快捷键       | 模式         | 功能描述                                  | 适用场景                          |
-- |--------------|--------------|-------------------------------------------|-----------------------------------|
-- | <leader>ul   | n            | 打开 Lazy 插件性能分析面板                | 排查插件加载慢的问题              |

-- 六、禁用快捷键（避免误触）
-- | 快捷键       | 模式         | 功能描述                                  | 原因                              |
-- |--------------|--------------|-------------------------------------------|-----------------------------------|
-- | <C-LeftMouse>| n            | 禁用 Ctrl+左键点击                        | 避免误触导致光标跳转              |
-- | <RightMouse> | 所有模式     | 右键映射为左键点击                        | 避免右键菜单干扰编辑操作          |

-- 新手使用建议：
-- 1. 优先掌握基础操作快捷键（<C-s> <C-z> J V），覆盖 80% 日常编辑场景；
-- 2. 注释快捷键（gcc gcO gco gcA）是代码开发高频使用，建议重点记忆；
-- 3. 终端快捷键（<C-t> <Esc>）适合需要频繁执行命令的开发场景（如后端、脚本开发）；
-- 4. 所有快捷键均基于「语义化」设计（如 <C-s> = Save，<C-t> = Terminal），结合功能记忆更易上手；
-- 5. 若快捷键与其他软件冲突（如 <C-s> 可能被终端占用），可在 custom/init.lua 中重新绑定（如改为 <leader>w）。