-- ==============================================
-- 文件类型配置表：为不同编程语言/文件类型设置专属规则
-- 作用：打开特定类型文件时，自动应用对应的缩进、显示、注释等配置
-- 核心逻辑：Ice.ft 是一个 table，键是文件类型（如 "python" "html"），值是配置函数
-- 新手友好：无需手动启用，打开对应文件自动生效；支持扩展自定义配置
-- ==============================================

Ice.ft = {
    -- 1. C 语言文件配置（文件类型：.c）
    c = function ()
        -- 设置 C 文件的 Tab 键对应空格数为 2（覆盖全局的 4 空格配置）
        -- 原因：C 语言社区部分项目习惯 2 空格缩进（如 Linux 内核），按需适配
        -- 注意点：仅对 .c 文件生效，不影响其他类型文件
        vim.bo.tabstop = 2
    end,

    -- 2. C# 语言文件配置（文件类型：.cs）
    cs = function()
        -- 设置 C# 文件的 80 列参考线为 100 列
        -- 原因：C# 代码通常有较长的类名/方法名，100 列更符合其编码习惯
        -- 扩展知识：colorcolumn 支持多列，如 "80,100" 表示显示两条参考线
        vim.wo.colorcolumn = "100"
    end,

    -- 3. CSS 样式文件配置（文件类型：.css）
    css = function()
        -- 设置 CSS 文件的注释格式：/* 注释内容 */
        -- 配置说明：
        -- - s1:/* 表示单行注释起始符为 /*
        -- - ex:*/ 表示注释结束符为 */
        -- 作用：使用 gcc/gc 快捷键（注释/取消注释）时，自动生成 CSS 风格注释
        -- 注意点：不同文件类型的注释格式不同，需单独配置才能让注释快捷键生效
        vim.bo.comments = "s1:/*,ex:*/"
    end,

    -- 4. Dart 语言文件配置（文件类型：.dart，Flutter 开发常用）
    dart = function()
        -- 设置 Dart 文件的 Tab 键对应空格数为 2
        -- 原因：Dart 官方推荐 2 空格缩进（Flutter 项目默认配置）
        -- 扩展：Dart 还有严格的代码规范，该配置仅解决缩进问题，格式化需配合 dartfmt 插件
        vim.bo.tabstop = 2
    end,

    -- 5. HTML 文件配置（文件类型：.html）
    html = function()
        -- 启用自动换行：长行 HTML 代码自动拆分成多行显示
        -- 原因：HTML 标签嵌套多，长行代码难以阅读，自动换行提升可读性
        vim.wo.wrap = true
        -- 启用按单词换行：换行时不会在单词中间拆分（避免 "he-llo" 这种拆分）
        -- 作用：保持单词完整性，换行后代码更整洁
        vim.wo.linebreak = true
        -- 启用缩进换行：换行后的内容自动缩进（与上一行保持对齐）
        -- 示例：<div>
        --          内容（自动缩进）
        --      </div>
        vim.wo.breakindent = true

        -- 二次确认文件类型为 HTML（双重保险，避免配置误触发）
        if vim.bo.filetype == "html" then
            -- 设置 HTML 文件的参考线为 120 列（HTML 标签较长，120 列更合理）
            vim.wo.colorcolumn = "120"
        end
    end,

    -- 6. JavaScript 文件配置（文件类型：.js）
    javascript = function()
        -- 设置 JS 文件的参考线为 120 列（JS 允许较长的函数/变量名）
        vim.wo.colorcolumn = "120"
        -- 设置 JS 文件的注释格式：// 注释内容
        -- 作用：使用 gcc/gc 快捷键时，自动生成单行注释
        -- 扩展知识：%s 是占位符，表示注释内容的位置
        vim.bo.commentstring = "// %s"
    end,

    -- 7. Markdown 文件配置（文件类型：.md）
    markdown = function()
        -- 启用自动换行（Markdown 文档以阅读为主，自动换行提升阅读体验）
        vim.wo.wrap = true
        -- 启用按单词换行（避免拆分英文单词）
        vim.wo.linebreak = true
        -- 启用缩进换行（列表、引用等结构换行后自动缩进）
        -- 示例：- 列表项1
        --       - 列表项2（自动缩进，保持对齐）
        vim.wo.breakindent = true
    end,

    -- 8. Python 文件配置（文件类型：.py）
    python = function()
        -- 设置 Python 文件的格式化选项（formatoptions）
        -- 选项含义（新手无需记全，知道作用即可）：
        -- - t: 自动缩进（按语法规则缩进，如 if 后换行缩进）
        -- - c: 注释时自动对齐（新行注释与上一行注释对齐）
        -- - q: 允许在注释中使用 gq 格式化（自动换行注释）
        -- - j: 删除注释行时，自动合并相邻的空行
        -- - o: 在换行后自动插入注释符（如 #）
        -- - r: 回车后自动插入注释符（继续上一行的注释）
        -- 作用：让 Python 代码的注释和缩进更规范，减少手动调整
        vim.bo.formatoptions = "tcqjor"
        -- 设置参考线为 88 列（符合 Python 代码规范工具 black 的默认行宽限制）
        -- 原因：black 是 Python 主流格式化工具，88 列是其推荐行宽，参考线提醒避免超长
        vim.wo.colorcolumn = "88" -- specified by black
    end,

    -- 9. TypeScript 文件配置（文件类型：.ts）
    typescript = function()
        -- 设置 TS 文件的参考线为 120 列（TS 支持复杂类型定义，行宽可适当放宽）
        vim.wo.colorcolumn = "120"
        -- 设置 TS 文件的注释格式：// 注释内容（与 JS 一致）
        vim.bo.commentstring = "// %s"
    end,

    -- 10. Typst 文件配置（文件类型：.typ，排版工具，类似 LaTeX）
    typst = function()
        -- 启用自动换行（Typst 文档以排版为主，自动换行提升阅读体验）
        vim.wo.wrap = true
        -- 启用按单词换行（避免拆分英文单词和公式）
        vim.wo.linebreak = true
        -- 设置参考线为 120 列（Typst 支持长公式和段落，120 列更适配）
        vim.wo.colorcolumn = "120"
        -- 启用缩进换行（列表、代码块等结构自动缩进）
        vim.wo.breakindent = true
        -- 设置 Tab 键对应空格数为 2（Typst 官方推荐 2 空格缩进）
        vim.bo.tabstop = 2
        -- 设置注释格式：// 注释内容（Typst 单行注释语法）
        vim.bo.commentstring = "// %s"
    end,

    -- 11. 扩展方法：为已有文件类型添加额外配置（不覆盖原有配置）
    -- 作用：新手无需修改上面的默认配置，可通过此方法扩展自定义规则
    -- 参数说明：
    -- - self: 指 Ice.ft 本身（调用时无需手动传入，由 Lua 自动传递）
    -- - ft: 要扩展的文件类型（如 "python" "html"）
    -- - callback: 扩展的配置函数（要添加的新规则）
    ---@param self table
    ---@param ft string
    ---@param callback function
    set = function(self, ft, callback)
        -- 获取该文件类型已有的默认配置函数
        local default_callback = self[ft]
        -- 如果已有默认配置（如上面的 python 配置）
        if default_callback ~= nil then
            -- 重新定义该文件类型的配置函数：先执行默认配置，再执行扩展配置
            -- 好处：保留原有规则，新增配置不会覆盖
            self[ft] = function()
                default_callback() -- 执行默认配置（如 python 的 88 列参考线）
                callback()         -- 执行扩展配置（如新增的自定义缩进规则）
            end
        else
            -- 如果该文件类型没有默认配置，直接将扩展配置设为其配置函数
            self[ft] = callback
        end
    end,
}