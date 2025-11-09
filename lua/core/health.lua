-- ==============================================
-- IceNvim 健康检查模块：验证运行所需依赖是否安装
-- 作用：通过 :IceHealth 命令调用，检查配置依赖的工具/软件是否齐全
-- 核心价值：新手遇到配置异常时，先执行 :IceHealth 排查依赖问题，快速定位原因
-- 注释说明：逐行解释检查逻辑、依赖用途、异常处理，新手能看懂每个检查项的意义
-- ==============================================

-- 定义模块表 M：所有健康检查相关函数都存储在这里，最后导出供外部调用
local M = {}

-- 工具函数：检查指定命令（工具）是否可执行，并处理未安装的情况
-- 核心逻辑：调用 vim.fn.executable 判断命令是否存在，根据结果显示健康状态
-- 参数说明：
-- - cmd: 要检查的命令名称（如 "curl" "gcc"，即终端中能直接执行的命令）
-- - behavior: 可选参数，未安装时的自定义处理函数（默认抛出错误提示）
---@param cmd string the command to check
---@param behavior function | nil what to do if cmd is not executable; throws an error message by default
local function check(cmd, behavior)
    -- vim.fn.executable(cmd)：Neovim 内置函数，判断 cmd 是否可执行
    -- 返回值：1 表示可执行，0 表示未安装/未在环境变量中
    if vim.fn.executable(cmd) == 1 then
        -- 健康状态：正常（绿色 ok 标记），提示该工具已安装
        vim.health.ok(cmd .. " is installed.")
    else
        -- 工具未安装：执行自定义处理函数或默认错误提示
        if not behavior then
            -- 无自定义处理时，显示错误（红色 error 标记），提示工具缺失
            vim.health.error(cmd .. " is missing.")
        else
            -- 执行自定义处理函数（如显示警告、给出安装建议）
            behavior()
        end
    end
end

-- 核心健康检查函数：供外部调用（通过 :IceHealth 命令触发）
-- 执行逻辑：按「基础依赖→系统专属依赖」的顺序检查，分模块显示结果
M.check = function()
    -- 开始检查「基础前置依赖」：所有系统（Linux/Mac/Windows）通用
    vim.health.start "IceNvim Prerequisites"
    -- 提示信息：IceNvim 不自动检查 Nerd Font，但至少需要安装一款
    -- 原因：配置中使用了 Nerd Font 图标（如插件图标、状态栏图标），未安装会显示乱码
    -- 注意点：需手动安装 Nerd Font 并在终端中设置使用，否则图标异常
    vim.health.info "IceNvim does not check this for you, but at least one [nerd font] should be installed."

    -- 批量检查基础依赖命令（所有系统必需，缺失会导致部分功能失效）
    -- 每个命令的作用（新手必看）：
    -- - curl/wget：下载插件、工具（如 Lazy.nvim 安装插件）
    -- - fd：文件搜索（如 Telescope 插件的文件搜索功能）
    -- - rg（ripgrep）：文本内容搜索（比 grep 更快，插件依赖）
    -- - gcc/cmake：编译安装部分插件（如 nvim-treesitter 语法解析器）
    -- - node/npm/yarn：前端相关插件依赖（如 LSP 服务、格式化工具）
    -- - python3/pip3：Python 相关插件依赖（如部分 LSP 服务、代码补全）
    -- - tree-sitter：语法高亮核心工具（nvim-treesitter 插件依赖）
    for _, cmd in ipairs {
        "curl",
        "wget",
        "fd",
        "rg",
        "gcc",
        "cmake",
        "node",
        "npm",
        "yarn",
        "python3",
        "pip3",
        "tree-sitter",
    } do
        -- 调用上面定义的 check 函数，检查每个命令是否安装
        check(cmd)
    end

    -- 检查压缩工具：gzip 或 7z 至少安装一个
    -- 作用：解压插件安装包（部分插件下载后是压缩包格式）
    -- 逻辑：只要其中一个存在就显示正常，都不存在则报错
    if vim.fn.executable "gzip" == 1 or vim.fn.executable "7z" == 1 then
        vim.health.ok "One of gzip / 7zip is installed."
    else
        vim.health.error "You must install one of gzip or 7zip."
    end

    -- 检查 Rust 开发依赖：rust-analyzer（Rust 语言 LSP 服务）
    -- 自定义处理逻辑：未安装时显示警告（非必需，仅 Rust 开发需要）
    check("rust-analyzer", function()
        vim.health.warn "For best experience with rust development, you should install rust-analyzer."
    end)

    -- 检查 Linux 系统专属依赖
    if require("core.utils").is_linux then
        -- 开始检查「Linux 系统前置依赖」
        vim.health.start "IceNvim Prerequisites for Linux"
        -- 提示信息：需要 Python 虚拟环境（Python 插件依赖，避免污染系统 Python）
        -- 注意点：需手动创建虚拟环境，具体方法可参考 IceNvim 文档
        vim.health.info "IceNvim does not check this for you, but you need a [python virtualenv]."

        -- Linux 系统必需的工具（缺失会导致部分功能异常）
        -- 命令作用：
        -- - unzip：解压 zip 格式文件（插件安装包常用格式）
        -- - xclip：系统剪贴板工具（实现 Neovim 与系统剪贴板互通，如复制到粘贴板）
        -- - zip：压缩文件（部分插件导出功能依赖）
        for _, cmd in ipairs { "unzip", "xclip", "zip" } do
            check(cmd)
        end
    end

    -- 检查 Windows 或 WSL（Windows 子系统）专属依赖
    if require("core.utils").is_windows or require("core.utils").is_wsl then
        -- 开始检查「Windows/WSL 可选依赖」
        vim.health.start "IceNvim Optional Dependencies for Windows and WSL"

        -- 仅 Windows 系统需要检查：cl.exe（MSVC 编译器）
        if require("core.utils").is_windows then
            check("cl", function()
                -- 自定义错误提示：treesitter 插件需要 MSVC 编译器，否则无法编译语法解析器
                -- 解决方法：安装 Visual Studio 或 MSVC 构建工具，并将 cl.exe 加入环境变量
                vim.health.error "You need msvc for treesitter to work properly. Specifically, you need cl.exe to be in your PATH."
            end)
        end

        -- 检查中文输入法切换工具：im-select.exe
        -- 路径：~/.config/nvim/bin/im-select.exe（配置目录下的 bin 文件夹）
        -- 作用：自动切换输入法（编辑代码时切英文，进入插入模式切中文）
        -- 自定义警告：未安装时提示下载地址，非必需但中文用户建议安装
        check(vim.fs.joinpath(vim.fn.stdpath "config", "bin/im-select.exe"), function()
            vim.health.warn "You need im-select.exe to enable automatic IME switching for Chinese. Consider downloading it at https://github.com/daipeihust/im-select/raw/master/win/out/x86/im-select.exe"
        end)

        -- 检查 Unicode 剪贴板工具：uclip.exe
        -- 路径：~/.config/nvim/bin/uclip.exe
        -- 作用：解决 Windows 系统中 Unicode 字符（如中文、特殊符号）复制粘贴乱码问题
        -- 自定义警告：未安装时提示下载地址，非必需但中文用户建议安装
        check(vim.fs.joinpath(vim.fn.stdpath "config", "bin/uclip.exe"), function()
            vim.health.warn "You need uclip.exe for correct unicode copy / paste. Consider downloading it at https://github.com/suzusime/uclip/releases/download/v0.1.0/uclip.exe"
        end)
    end

    -- 检查 MacOS 系统专属依赖
    if require("core.utils").is_mac then
        -- 开始检查「MacOS 可选依赖」
        vim.health.start "IceNvim Optional Dependencies for MacOS"

        -- 检查中文输入法切换工具：macism
        -- 作用：MacOS 下自动切换输入法（类似 Windows 的 im-select.exe）
        -- 自定义警告：未安装时提示参考文档，非必需但中文用户建议安装
        check("macism", function()
            vim.health.warn "You need macism to enable automatic IME switching for Chinese. Please refer to the wiki for instruction on how to install it."
        end)
    end
end

-- 导出模块 M：供其他文件 require 调用（如 commands.lua 中的 :IceHealth 命令）
return M