-- ==============================================
-- 核心杂项配置文件：处理剪贴板、输入法、目录切换等辅助功能
-- 作用：解决跨系统兼容、编辑体验优化等细节问题，提升使用流畅度
-- 核心特点：
-- 1. 跨系统适配：自动识别 Windows/WSL/Mac/Linux，应用对应配置
-- 2. 细节优化：修复剪贴板互通、输入法自动切换、冗余文件清理等痛点
-- 3. 可配置性：支持通过 Ice 全局表自定义排除规则（如目录切换黑名单）
-- 注释说明：逐行解释功能逻辑、适用场景、注意点，新手能理解每个配置的意义
-- ==============================================

-- 引入核心工具函数模块（提供系统判断、路径处理等基础功能）
local utils = require "core.utils"

-- 获取 Neovim 配置目录路径（默认 ~/.config/nvim）
local config_path = vim.fn.stdpath "config"

-- ==============================================
-- 1. 跨系统剪贴板配置：实现 Neovim 与系统剪贴板互通
-- 痛点：Windows/WSL 系统默认剪贴板与 Neovim 不互通，复制粘贴乱码/失效
-- 解决方案：自动选择系统可用的剪贴板工具，实现无缝复制粘贴
-- ==============================================
-- 定义 uclip.exe 路径（Unicode 剪贴板工具，解决中文复制乱码问题）
-- 路径：配置目录下的 bin 文件夹（~/.config/nvim/bin/uclip.exe）
local clip_path = vim.fs.joinpath(config_path, "bin/uclip.exe")

-- 检查 uclip.exe 是否存在（若用户未手动下载，则使用系统默认剪贴板工具）
if not vim.uv.fs_stat(clip_path) then
    local root  -- 系统根目录（Windows 是 C:，WSL 是 /mnt/c）
    if utils.is_windows then
        root = "C:"  -- Windows 系统根目录
    else
        root = "/mnt/c"  -- WSL 系统访问 Windows 目录的路径
    end
    -- 切换为系统默认剪贴板工具 clip.exe（Windows 自带，路径固定）
    clip_path = vim.fs.joinpath(root, "Windows/System32/clip.exe")
end

-- 针对 Windows/WSL 系统：设置复制事件自动同步到系统剪贴板
if utils.is_windows or utils.is_wsl then
    -- 创建自动命令：TextYankPost 事件（复制操作完成后触发）
    vim.api.nvim_create_autocmd("TextYankPost", {
        callback = function()
            -- 仅当操作是复制（operator == "y"）时执行（排除剪切、删除等操作）
            if vim.v.event.operator == "y" then
                -- 调用剪贴板工具，将寄存器 0 的内容（刚复制的内容）写入系统剪贴板
                -- vim.fn.getreg("0")：获取寄存器 0 的内容（Neovim 中复制的内容默认存入寄存器 0）
                vim.fn.system(clip_path, vim.fn.getreg "0")
            end
        end,
    })
else
    -- 非 Windows/WSL 系统（Mac/Linux）：启用默认剪贴板互通
    -- set clipboard+=unnamedplus：让 Neovim 共享系统剪贴板（复制粘贴直接互通）
    vim.cmd "set clipboard+=unnamedplus"
end

-- ==============================================
-- 2. 输入法自动切换：编辑模式切换时自动切换输入法（中文用户必备）
-- 痛点：插入模式需要中文输入，普通模式需要英文输入，手动切换繁琐
-- 解决方案：通过自动命令，插入模式切中文、普通模式切英文，退出 Neovim 切中文
-- ==============================================
-- 创建输入法自动切换的自动命令组（组名 ImeAutoGroup，clear = true 表示创建前清空旧组）
-- 作用：将所有输入法相关自动命令归类，方便管理和清理
local ime_autogroup = vim.api.nvim_create_augroup("ImeAutoGroup", { clear = true })

-- Windows/WSL 系统：使用 im-select.exe 工具切换输入法
if utils.is_windows or utils.is_wsl then
    -- 定义 im-select.exe 路径（输入法切换工具，需用户手动下载到配置目录的 bin 文件夹）
    local im_select_path = vim.fs.joinpath(config_path, "bin/im-select.exe")

    -- 检查 im-select.exe 是否存在（存在才启用自动切换）
    if vim.uv.fs_stat(im_select_path) then
        -- 定义输入法切换的通用函数（简化重复代码）
        -- 参数：event（触发事件）、code（输入法编码，1033=英文，2052=中文）
        local function autocmd(event, code)
            vim.api.nvim_create_autocmd(event, {
                group = ime_autogroup,  -- 归属于上面创建的输入法命令组
                callback = function()
                    -- 执行 im-select.exe 切换输入法（silent 表示不显示命令执行结果）
                    vim.cmd(":silent :!" .. im_select_path .. " " .. code)
                end,
            })
        end

        -- 插入模式退出（InsertLeave）→ 切换为英文输入法（编码 1033）
        autocmd("InsertLeave", 1033)
        -- 插入模式进入（InsertEnter）→ 切换为中文输入法（编码 2052）
        autocmd("InsertEnter", 2052)
        -- Neovim 退出前（VimLeavePre）→ 切换为中文输入法（避免退出后输入法停留在英文）
        autocmd("VimLeavePre", 2052)
    end
-- MacOS 系统：使用 macism 工具切换输入法
elseif utils.is_mac then
    -- 检查 macism 是否安装（需用户手动安装，用于控制 Mac 输入法）
    if vim.fn.executable "macism" == 1 then
        -- 插入模式退出（InsertLeave）→ 切换为英文输入法（ABC 布局）
        vim.api.nvim_create_autocmd("InsertLeave", {
            group = ime_autogroup,
            callback = function()
                -- 保存当前输入法编码（退出插入模式前的输入法，下次进入时恢复）
                vim.system({ "macism" }, { text = true }, function(out)
                    -- 去除输出中的换行符，存入 Ice 全局表（临时存储）
                    Ice.__PREVIOUS_IM_CODE_MAC = string.gsub(out.stdout, "\n", "")
                end)
                -- 切换为英文输入法（com.apple.keylayout.ABC 是 Mac 英文输入法的固定 ID）
                vim.cmd ":silent :!macism com.apple.keylayout.ABC"
            end,
        })

        -- 插入模式进入（InsertEnter）→ 恢复之前的输入法（如中文）
        vim.api.nvim_create_autocmd("InsertEnter", {
            group = ime_autogroup,
            callback = function()
                -- 如果之前保存了输入法编码，恢复该输入法
                if Ice.__PREVIOUS_IM_CODE_MAC then
                    vim.cmd(":silent :!macism " .. Ice.__PREVIOUS_IM_CODE_MAC)
                end
                -- 清空保存的编码（避免重复恢复）
                Ice.__PREVIOUS_IM_CODE_MAC = nil
            end,
        })
    end
-- Linux 系统：使用 fcitx5 输入法切换（Linux 主流输入法框架）
elseif utils.is_linux then
    -- Vimscript 语法：直接执行 fcitx5 相关命令（Linux 下 fcitx5 支持命令行控制）
    vim.cmd [[
        let fcitx5state=system("fcitx5-remote")  -- 获取当前输入法状态（0=关闭，1=激活，2=英文，3=中文）
        -- 插入模式退出 → 切换为英文输入法（fcitx5-remote -c 表示切换为英文）
        autocmd InsertLeave * :silent let fcitx5state=system("fcitx5-remote")[0] | silent !fcitx5-remote -c
        -- 插入模式进入 → 若之前是中文状态，恢复中文（fcitx5-remote -o 表示切换为中文）
        autocmd InsertEnter * :silent if fcitx5state == 2 | call system("fcitx5-remote -o") | endif
    ]]
end

-- ==============================================
-- 3. 自动切换工作目录：打开文件时，自动切换到项目根目录
-- 痛点：编辑项目文件时，相对路径引用（如导入模块、读取配置）需要以项目根为基准
-- 解决方案：根据文件路径自动定位项目根目录（如 .git 目录所在目录），切换当前工作目录
-- ==============================================
-- 创建自动命令组：AutoChdir（目录自动切换），清空旧组避免重复
vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("AutoChdir", { clear = true }),
    callback = function()
        -- 控制开关：若 Ice.auto_chdir 为 false，则禁用自动切换（默认启用）
        if not (Ice.auto_chdir or Ice.auto_chdir == nil) then
            return
        end

        -- 默认排除的文件类型：这些窗口不需要切换目录（如文件树、帮助文档）
        local default_exclude_filetype = { "NvimTree", "help" }
        -- 默认排除的缓冲区类型：终端、无文件缓冲区（不需要目录上下文）
        local default_exclude_buftype = { "terminal", "nofile" }

        -- 用户自定义排除文件类型：若 Ice.chdir_exclude_filetype 是有效表格，则使用用户配置，否则用默认
        local exclude_filetype = Ice.chdir_exclude_filetype
        if exclude_filetype == nil or type(exclude_filetype) ~= "table" then
            exclude_filetype = default_exclude_filetype
        end

        -- 用户自定义排除缓冲区类型：逻辑同上
        local exclude_buftype = Ice.chdir_exclude_buftype
        if exclude_buftype == nil or type(exclude_buftype) ~= "table" then
            exclude_buftype = default_exclude_buftype
        end

        -- 若当前文件类型/缓冲区类型在排除列表中，不执行目录切换
        if table.find(exclude_filetype, vim.bo.filetype) or table.find(exclude_buftype, vim.bo.buftype) then
            return
        end

        -- 切换当前工作目录到项目根目录（get_root() 是工具函数，自动识别 .git/.svn 等根目录标记）
        vim.api.nvim_set_current_dir(require("core.utils").get_root())
    end,
})

-- ==============================================
-- 4. Windows 系统专属：清理 Neovim 冗余临时文件
-- 痛点：Windows 系统下，Neovim 退出后可能残留 shada.tmp.X 临时文件，占用空间
-- 解决方案：Neovim 退出前自动扫描并删除这些临时文件
-- ==============================================
if utils.is_windows then
    -- 创建自动命令组：RemoveShadaTmp（清理 shada 临时文件）
    local remove_shada_tmp_group = vim.api.nvim_create_augroup("RemoveShadaTmp", { clear = true })
    -- VimLeavePre 事件：Neovim 退出前触发（确保退出时清理）
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = remove_shada_tmp_group,
        callback = function()
            -- shada 目录路径：~/.local/share/nvim/shada（存储会话数据的目录）
            local dir = vim.fs.joinpath(vim.fn.stdpath "data", "shada")
            -- 扫描 shada 目录下的所有文件/子目录
            local shada_dir = vim.uv.fs_scandir(dir)

            local shada_temp = ""  -- 存储当前扫描到的临时文件名
            -- 循环扫描目录，直到没有更多文件
            while shada_temp ~= nil do
                -- 匹配文件名包含 ".tmp." 的文件（Neovim 生成的临时文件格式）
                if string.find(shada_temp, ".tmp.") then
                    -- 拼接临时文件的完整路径
                    local full_path = vim.fs.joinpath(dir, shada_temp)
                    -- 删除临时文件（os.remove 是 Lua 内置函数）
                    os.remove(full_path)
                end
                -- 扫描下一个文件
                shada_temp = vim.uv.fs_scandir_next(shada_dir)
            end
        end,
    })
end