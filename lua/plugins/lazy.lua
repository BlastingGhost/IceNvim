-- ==============================================
-- Lazy.nvim 插件管理器配置（Neovim 插件生态核心）
-- 功能概述：
-- 1. 自动安装、更新、卸载 Neovim 插件
-- 2. 支持插件延迟加载、依赖管理、性能优化
-- 3. 替代传统 plugin-manager（如 packer.nvim），更高效易用
-- 新手注意：这部分是所有插件运行的基础，必须放在配置文件开头（插件配置之前）
-- ==============================================

-- 定义 Lazy.nvim 的安装路径
-- vim.fn.stdpath "data"：Neovim 数据目录（如 ~/.local/share/nvim）
-- 最终路径：~/.local/share/nvim/lazy/lazy.nvim（Lazy 自身的安装位置）
local lazypath = vim.fs.joinpath(vim.fn.stdpath "data", "lazy/lazy.nvim")

-- 条件判断：是否启用插件（通过 Ice 全局配置的 noplugin 标志控制）
-- 若 Ice.noplugin = true，则禁用所有插件（仅加载基础 Neovim 功能）
if not require("core.utils").noplugin then
    -- 检查 Lazy.nvim 是否已安装（判断安装路径是否存在）
    if not vim.uv.fs_stat(lazypath) then
        -- 未安装则自动克隆安装（通过 git 命令）
        vim.fn.system {
            "git",  -- git 命令（需系统已安装 git）
            "clone",  -- 克隆仓库
            "--filter=blob:none",  -- 仅克隆最新提交的文件（不下载历史大文件，加速安装）
            "https://github.com/folke/lazy.nvim.git",  -- Lazy.nvim 官方仓库地址
            "--branch=stable",  -- 安装稳定版（避免开发版的不稳定问题）
            lazypath,  -- 安装到指定路径
        }
    end
    -- 将 Lazy.nvim 的路径添加到 Neovim 的 runtimepath（RTSP）
    -- prepend：添加到 RTSP 开头，确保 Lazy 优先加载
    vim.opt.rtp:prepend(lazypath)
end

-- 配置 Lazy.nvim 的全局选项（通过 Ice.lazy 传递给 Lazy）
Ice.lazy = {
    performance = {  -- 性能优化相关配置
        rtp = {
            -- 禁用 Neovim 内置的无用插件（减少启动时间和内存占用）
            disabled_plugins = {
                "editorconfig",  -- 禁用内置 editorconfig 支持（建议用单独插件 editorconfig.nvim）
                "gzip",  -- 禁用内置 gzip 压缩支持（很少用到）
                "man",  -- 禁用内置 man 手册查看（建议用插件 man.nvim）
                "matchit",  -- 禁用内置匹配增强（如 % 匹配 HTML 标签，建议用插件 vim-matchup）
                "matchparen",  -- 禁用内置括号匹配高亮（建议用插件 nvim-treesitter 或 vim-matchup）
                "netrwPlugin",  -- 禁用内置文件浏览器（建议用 nvim-tree.lua 或 oil.nvim）
                "osc52",  -- 禁用内置 OSC52 剪贴板支持（远程服务器用，本地很少用）
                "rplugin",  -- 禁用远程插件支持（很少用到）
                "shada",  -- 禁用内置 shada 持久化支持（Neovim 自身已优化，无需额外插件）
                "spellfile",  -- 禁用内置拼写文件支持（建议用插件 vim-spellcheck）
                "tarPlugin",  -- 禁用内置 tar 解压支持（很少用到）
                "tohtml",  -- 禁用内置 HTML 导出支持（很少用到）
                "tutor",  -- 禁用内置教程（新手首次使用后可禁用）
                "zipPlugin",  -- 禁用内置 zip 解压支持（很少用到）
            },
        },
    },
    ui = {  -- Lazy 界面样式配置
        backdrop = 100,  -- 背景透明度（0-100，100 表示完全不透明，0 表示完全透明）
        -- 作用：Lazy 窗口打开时，背景不模糊，保持清晰（适合大多数终端）
    },
}

-- 后续说明：
-- 1. 启动 Neovim 后，Lazy 会自动检测配置中的插件，未安装则自动安装
-- 2. 常用 Lazy 命令：
--    :Lazy -> 打开 Lazy 管理界面（查看插件状态、更新、卸载）
--    :Lazy install -> 安装所有未安装的插件
--    :Lazy update -> 更新所有已安装的插件
--    :Lazy clean -> 卸载所有未在配置中声明的插件
-- 3. 新手无需修改此部分，保持默认即可满足绝大多数需求