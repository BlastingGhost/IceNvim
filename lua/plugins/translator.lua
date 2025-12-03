-- ==============================================
-- 翻译插件：voldikss/vim-translator（新手专用配置）
-- 核心功能：
-- 1. 划词翻译：选中文字后一键翻译（支持英文→中文，自动识别语言）
-- 2. 行翻译：直接翻译当前行内容，适合阅读英文文档
-- 3. 输入翻译：手动输入单词/句子翻译，适合主动查词
-- 为什么选这个插件？
-- - 无需配置 API 密钥，开箱即用
-- - 支持弹窗显示结果，不打断编辑流程
-- - 快捷键简单，新手容易记忆
-- ==============================================
local config = {}  -- 用于存放当前插件的配置

-- 插件核心配置
config["vim-translator"] = {
    "voldikss/vim-translator",  -- 插件的 GitHub 地址（用于 lazy.nvim 下载）
    event = "User IceLoad",     -- 加载时机：Ice 框架初始化完成后（和其他插件保持一致）
    keys = {                    -- 快捷键配置（<leader> 默认为空格，新手易操作）
        -- 普通模式：选中文字后按 <leader>t 翻译
        { "v", "<leader>t", "<Plug>TranslateV", desc = "翻译：划词翻译（选中文本后使用）", silent = true },
        -- 普通模式：按 <leader>tl 翻译当前行
        { "<leader>tl", "<Plug>TranslateLine", desc = "翻译：翻译当前行内容", silent = true },
        -- 普通模式：按 <leader>ti 手动输入要翻译的内容
        { "<leader>ti", "<Plug>TranslateInput", desc = "翻译：手动输入单词/句子", silent = true },
    },
    init = function()
        -- 基础设置（新手无需修改，保持默认即可）
        vim.g.translator_default_engines = { "baidu" }  -- 使用百度翻译引擎（稳定、免费）
        vim.g.translator_target_lang = "zh-CN"          -- 目标语言：简体中文
        vim.g.translator_source_lang = "auto"           -- 源语言：自动识别（英文/中文等）
        
        -- 显示设置：结果在弹窗中显示（不遮挡编辑区，适合新手）
        vim.g.translator_popup_win = 1      -- 1=弹窗显示，0=新窗口显示
        vim.g.translator_popup_width = 80   -- 弹窗宽度（适配大多数屏幕）
        vim.g.translator_popup_height = 10  -- 弹窗高度（显示关键内容即可）
    end
}

-- 将当前插件配置添加到全局 Ice.plugins 中（让 lazy.nvim 识别并加载）
for k, v in pairs(config) do
    Ice.plugins[k] = v
end