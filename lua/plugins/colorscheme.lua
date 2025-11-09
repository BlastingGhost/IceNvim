-- ==============================================
-- 主题配置总表：预定义常用配色方案（colorscheme），支持快速切换和个性化配置
-- 核心定位：IceNvim 的「主题管理中心」，统一管理所有可选主题的加载规则、外观样式
-- 配置逻辑：
-- 1. 键名：主题别名（如 "gruvbox-dark"），用于快速切换和识别
-- 2. 配置字段：
--    - name：主题实际名称（需与插件仓库名称一致，如 "gruvbox" 对应插件 "ellisonleao/gruvbox.nvim"）
--    - background：背景模式（"dark" 深色模式 / "light" 浅色模式）
--    - transparent：是否启用透明背景（true 透明 / false 不透明，默认 false）
--    - setup：主题个性化配置（函数或表，用于覆盖主题默认样式，如字体、对比度、高亮规则）
-- 核心价值：
-- - 一键切换：通过修改默认主题别名，即可快速更换整个 Neovim 外观
-- - 统一风格：所有主题共享相同的配置结构，切换后体验一致
-- - 个性化：支持为每个主题单独配置细节（如透明背景、字体样式）
-- 新手说明：以下逐主题详解风格特点、适用场景和配置细节，附主题总结和切换方法
-- ==============================================

-- Predefined colorschemes（预定义主题，原作者注释保留）
Ice.colorschemes = {
    -- 1. Cyberdream 主题（深色模式）
    ["cyberdream-dark"] = {
        name = "cyberdream",  -- 主题实际名称（插件："scottmckendry/cyberdream.nvim"）
        background = "dark",  -- 深色背景模式
        transparent = true,   -- 启用透明背景（适合喜欢极简、无背景干扰的用户）
        setup = {
            variant = "dark",  -- 指定主题变体为深色（cyberdream 支持 dark/light 两种变体）
        },
        -- 主题特点：
        -- - 风格：赛博朋克风，高对比度，荧光色高亮（如蓝色、紫色代码元素）
        -- - 适用场景：夜间编码、喜欢科技感界面的用户
        -- - 优势：语法高亮清晰（变量、函数、关键字区分明显），透明背景适配壁纸
        -- - 注意点：高对比度可能刺眼，长时间编码建议调低屏幕亮度
    },

    -- 2. Cyberdream 主题（浅色模式）
    ["cyberdream-light"] = {
        name = "cyberdream",  -- 主题实际名称（与深色模式共享同一个插件）
        background = "light", -- 浅色背景模式
        setup = {
            variant = "light", -- 指定主题变体为浅色
        },
        -- 主题特点：
        -- - 风格：赛博朋克风浅色版，明亮但不刺眼，荧光色元素柔和化
        -- - 适用场景：白天编码、光线充足的环境
        -- - 优势：长时间编码不易疲劳，代码高亮依然清晰
        -- - 注意点：浅色背景下透明模式效果不明显，建议关闭 transparent
    },

    -- 3. Gruvbox 主题（深色模式）
    ["gruvbox-dark"] = {
        name = "gruvbox",     -- 主题实际名称（插件："ellisonleao/gruvbox.nvim"，经典配色）
        transparent = true,   -- 启用透明背景
        setup = {
            italic = {
                strings = true,    -- 字符串类型启用斜体
                operators = false, -- 运算符不启用斜体
                comments = true,   -- 注释启用斜体（突出注释，区分代码）
            },
            contrast = "hard",    -- 高对比度模式（可选 "hard"/"soft"/"medium"，默认 "medium"）
        },
        background = "dark",  -- 深色背景模式
        -- 主题特点：
        -- - 风格：复古棕色调，温暖柔和，灵感来自复古计算机终端
        -- - 配色：主要以棕色、绿色、黄色为主，低饱和度（保护视力）
        -- - 适用场景：长时间编码、喜欢复古风格、视力敏感用户
        -- - 优势：社区支持广，兼容性好（适配所有主流插件），语法高亮层次分明
        -- - 注意点：高对比度（contrast = "hard"）适合低分辨率屏幕，低对比度适合高分辨率
    },

    -- 4. Gruvbox 主题（浅色模式）
    ["gruvbox-light"] = {
        name = "gruvbox",     -- 主题实际名称（与深色模式共享插件）
        setup = {
            italic = {
                strings = true,
                operators = false,
                comments = true,
            },
            contrast = "hard",    -- 高对比度模式
        },
        background = "light", -- 浅色背景模式
        -- 主题特点：
        -- - 风格：复古棕色调浅色版，明亮温暖，无刺眼感
        -- - 适用场景：白天编码、光线充足环境、喜欢浅色主题的用户
        -- - 优势：与深色模式风格统一，切换后无需适应新的颜色逻辑
    },

    -- 5. Kanagawa 主题（Wave 变体，深色）
    ["kanagawa-wave"] = {
        name = "kanagawa-wave", -- 主题实际名称（插件："rebelot/kanagawa.nvim"，Wave 变体）
        transparent = true,     -- 启用透明背景
        background = "dark",    -- 深色背景模式
        -- 主题特点：
        -- - 风格：日式和风，低饱和度，柔和配色（以红色、蓝色、绿色为主）
        -- - 设计灵感：源自日本浮世绘，配色典雅，视觉舒适
        -- - 适用场景：长时间编码、喜欢简约典雅风格的用户
        -- - 优势：语法高亮自然（如函数用蓝色、变量用绿色），插件适配完美（尤其是 Telescope、LSP 相关 UI）
    },

    -- 6. Kanagawa 主题（Dragon 变体，深色）
    ["kanagawa-dragon"] = {
        name = "kanagawa-dragon", -- 主题实际名称（Kanagawa Dragon 变体）
        transparent = true,       -- 启用透明背景
        background = "dark",      -- 深色背景模式
        -- 主题特点：
        -- - 风格：Kanagawa 深色增强版，对比度更高，颜色更浓郁（如红色更鲜艳、蓝色更深）
        -- - 适用场景：夜间编码、喜欢高对比度但不刺眼的用户
        -- - 区别于 Wave 变体：Dragon 更适合低光线环境，Wave 适合普通夜间环境
    },

    -- 7. Kanagawa 主题（Lotus 变体，浅色）
    ["kanagawa-lotus"] = {
        name = "kanagawa-lotus", -- 主题实际名称（Kanagawa Lotus 变体）
        background = "light",    -- 浅色背景模式
        -- 主题特点：
        -- - 风格：日式和风浅色版，以米白色为背景，淡红色、淡蓝色为高亮色
        -- - 适用场景：白天编码、光线充足环境
        -- - 优势：颜色柔和，长时间编码不易疲劳，语法高亮清晰不刺眼
    },

    -- 8. Miasma 主题（深色模式）
    miasma = {
        name = "miasma",         -- 主题实际名称（插件："miasma.nvim"，小众简约主题）
        background = "dark",      -- 深色背景模式
        -- 主题特点：
        -- - 风格：极简主义，低对比度，冷色调（以深灰色、淡蓝色为主）
        -- - 适用场景：喜欢极简风格、不喜欢过多色彩干扰的用户
        -- - 优势：界面干净整洁，代码可读性高，适合专注编码
        -- - 注意点：颜色变化少，语法高亮区分度较低，新手可能需要适应
    },

    -- 9. Monet 主题（深色模式）
    ["monet-dark"] = {
        name = "monet",          -- 主题实际名称（插件："loctvl842/monet.nvim"）
        transparent = true,       -- 启用透明背景
        setup = function()        -- 个性化配置（函数形式，动态修改主题调色板）
            local palette = require "monet.palette"
            setmetatable(palette, { __index = palette.defaults }) -- 使用默认深色调色板
        end,
        background = "dark",      -- 深色背景模式
        -- 主题特点：
        -- - 风格：莫奈油画风，低饱和度，柔和渐变色彩（如淡紫色、淡绿色）
        -- - 适用场景：喜欢艺术感、追求视觉舒适的用户
        -- - 优势：颜色过渡自然，无刺眼感，长时间编码友好
    },

    -- 10. Monet 主题（浅色模式）
    ["monet-light"] = {
        name = "monet",          -- 主题实际名称（与深色模式共享插件）
        setup = function()        -- 个性化配置：使用浅色调色板
            local palette = require "monet.palette"
            setmetatable(palette, { __index = palette.light_mode }) -- 切换到浅色调色板
        end,
        background = "light",     -- 浅色背景模式
        -- 主题特点：
        -- - 风格：莫奈油画风浅色版，以淡米色为背景，淡粉色、淡蓝色为高亮色
        -- - 适用场景：白天编码、喜欢柔和浅色主题的用户
    },

    -- 11. Nightfox 主题（默认深色变体）
    nightfox = {
        name = "nightfox",        -- 主题实际名称（插件："EdenEast/nightfox.nvim"）
        transparent = true,       -- 启用透明背景
        background = "dark",      -- 深色背景模式
        -- 主题特点：
        -- - 风格：现代简约，中高对比度，冷色调（以蓝色、紫色为主）
        -- - 适用场景：夜间编码、喜欢现代风格的用户
        -- - 优势：插件生态适配完美，支持自定义调色板，语法高亮层次清晰
    },

    -- 12. Nightfox 主题（Carbon 变体，深色）
    ["nightfox-carbon"] = {
        name = "carbonfox",       -- 主题实际名称（Nightfox Carbon 变体）
        transparent = true,       -- 启用透明背景
        background = "dark",      -- 深色背景模式
        -- 主题特点：
        -- - 风格：Nightfox 深色增强版，以深灰色、黑色为主，高对比度
        -- - 适用场景：夜间编码、低光线环境、喜欢深色沉浸式体验的用户
    },

    -- 13. Nightfox 主题（Day 变体，浅色）
    ["nightfox-day"] = {
        name = "dayfox",          -- 主题实际名称（Nightfox Day 变体）
        background = "light",     -- 浅色背景模式
        -- 主题特点：
        -- - 风格：Nightfox 浅色版，以浅蓝色为背景，明亮但不刺眼
        -- - 适用场景：白天编码、喜欢现代浅色风格的用户
    },

    -- 14. Nightfox 主题（Dawn 变体，浅色）
    ["nightfox-dawn"] = {
        name = "dawnfox",         -- 主题实际名称（Nightfox Dawn 变体）
        background = "light",     -- 浅色背景模式
        -- 主题特点：
        -- - 风格：Nightfox 浅色暖调版，以淡橙色为背景，温暖柔和
        -- - 适用场景：白天编码、喜欢暖色调的用户
    },

    -- 15. Nightfox 主题（Dusk 变体，深色）
    ["nightfox-dusk"] = {
        name = "duskfox",         -- 主题实际名称（Nightfox Dusk 变体）
        transparent = true,       -- 启用透明背景
        background = "dark",      -- 深色背景模式
        -- 主题特点：
        -- - 风格：Nightfox 深色暖调版，以深紫色、深橙色为主，温暖不刺眼
        -- - 适用场景：夜间编码、喜欢暖色调深色主题的用户
    },

    -- 16. Nightfox 主题（Nord 变体，深色）
    ["nightfox-nord"] = {
        name = "nordfox",         -- 主题实际名称（Nightfox Nord 变体）
        transparent = true,       -- 启用透明背景
        background = "dark",      -- 深色背景模式
        -- 主题特点：
        -- - 风格：基于 Nord 配色方案，冷色调，低饱和度（以蓝色、灰色为主）
        -- - 适用场景：喜欢 Nord 风格、追求平静视觉体验的用户
        -- - 优势：颜色柔和，保护视力，适合长时间编码
    },

    -- 17. Nightfox 主题（Tera 变体，深色）
    ["nightfox-tera"] = {
        name = "terafox",         -- 主题实际名称（Nightfox Tera 变体）
        transparent = true,       -- 启用透明背景
        background = "dark",      -- 深色背景模式
        -- 主题特点：
        -- - 风格：Nightfox 高对比度变体，颜色更鲜艳（如亮蓝色、亮绿色）
        -- - 适用场景：喜欢高对比度、代码元素区分明显的用户
    },

    -- 18. TokyoNight 主题（默认深色模式）
    tokyonight = {
        name = "tokyonight",      -- 主题实际名称（插件："folke/tokyonight.nvim"，最流行的主题之一）
        background = "dark",      -- 深色背景模式
        setup = {
            style = "moon",       -- 指定主题风格为 "moon"（TokyoNight 支持 storm/night/moon 三种风格）
            styles = {
                comments = { italic = true },  -- 注释启用斜体
                keywords = { italic = false }, -- 关键字不启用斜体
            },
        },
        -- 主题特点：
        -- - 风格：现代都市风，冷色调，中高对比度（以蓝色、紫色为主）
        -- - 设计灵感：东京夜景，配色时尚，界面简洁
        -- - 适用场景：夜间编码、前端开发、喜欢时尚风格的用户
        -- - 优势：插件适配完美（LSP、Telescope、Nvim-Tree 等均有优化），语法高亮精准，支持多种风格切换
        -- - 风格区别：
        --   - storm：高对比度，颜色鲜艳（适合低光线环境）
        --   - night：中等对比度，颜色柔和（默认风格）
        --   - moon：低对比度，颜色淡雅（适合长时间编码）
    },
}

-- ==============================================
-- 一、主题核心信息总表（新手快速选型）
-- ==============================================
-- | 主题别名               | 实际名称       | 背景模式 | 透明支持 | 核心风格特点                                  | 适用场景                                  |
-- |------------------------|----------------|----------|----------|-----------------------------------------------|-------------------------------------------|
-- | cyberdream-dark        | cyberdream     | dark     | ✅       | 赛博朋克风，高对比度，荧光色                  | 夜间编码、喜欢科技感                      |
-- | cyberdream-light       | cyberdream     | light    | ❌       | 赛博朋克风浅色版，明亮柔和                    | 白天编码、科技感爱好者                    |
-- | gruvbox-dark           | gruvbox        | dark     | ✅       | 复古棕色调，温暖柔和，低饱和度                | 长时间编码、视力敏感、复古风格              |
-- | gruvbox-light          | gruvbox        | light    | ❌       | 复古棕色调浅色版，明亮温暖                    | 白天编码、复古风格                        |
-- | kanagawa-wave          | kanagawa-wave  | dark     | ✅       | 日式和风，低饱和度，典雅配色                  | 长时间编码、简约典雅风格                  |
-- | kanagawa-dragon        | kanagawa-dragon| dark     | ✅       | 日式和风增强版，高对比度，颜色浓郁            | 夜间编码、低光线环境                      |
-- | kanagawa-lotus         | kanagawa-lotus | light    | ❌       | 日式和风浅色版，淡米白背景                    | 白天编码、和风风格                        |
-- | miasma                 | miasma         | dark     | ❌       | 极简主义，低对比度，冷色调                    | 专注编码、极简风格爱好者                  |
-- | monet-dark             | monet          | dark     | ✅       | 莫奈油画风，低饱和度，柔和渐变                | 艺术感偏好、视觉舒适需求                  |
-- | monet-light            | monet          | light    | ❌       | 莫奈油画风浅色版，淡粉淡蓝高亮                | 白天编码、艺术风格                        |
-- | nightfox               | nightfox       | dark     | ✅       | 现代简约，中高对比度，冷色调                  | 夜间编码、现代风格                        |
-- | nightfox-carbon        | carbonfox      | dark     | ✅       | 深灰黑色调，高对比度，沉浸式                  | 夜间编码、低光线环境                      |
-- | nightfox-day           | dayfox         | light    | ❌       | 现代浅色，浅蓝色背景，明亮简洁                | 白天编码、现代风格                        |
-- | nightfox-dawn          | dawnfox        | light    | ❌       | 现代浅色暖调，淡橙色背景                    | 白天编码、暖色调偏好                      |
-- | nightfox-dusk          | duskfox        | dark     | ✅       | 深色暖调，深紫深