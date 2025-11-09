-- ==============================================
-- 核心工具函数模块：提供配置中通用的辅助功能（系统判断、快捷键注册、路径处理等）
-- 作用：封装重复逻辑，让其他模块（如 keymap、ft、miscellaneous）直接调用，减少冗余代码
-- 核心特点：
-- 1. 通用性强：涵盖系统判断、文件类型配置、快捷键批量注册、表操作等常用功能
-- 2. 兼容性好：适配 Windows/Mac/Linux/WSL 多系统，处理不同环境差异
-- 3. 可扩展性：提供有序遍历、表查找等增强功能，补充 Lua 原生表的不足
-- 注释说明：逐行解释函数作用、参数含义、使用场景、注意点，新手能理解每个工具的用途
-- ==============================================

-- 1. Neovim 版本获取：避免加载冗余模块，提升启动速度
-- 原作者备注：
-- - 不使用 vim.version 是因为它会加载 vim.version 模块，增加启动耗时
-- - 不使用 vim.fn.api_info().version 是因为 api_info 函数同样消耗较多时间
-- 实现逻辑：执行 :version 命令，通过正则提取版本号（如 "0.9.5"）
-- 用途：后续可能用于版本兼容性判断（如某些功能仅支持特定版本）
local version = vim.fn.matchstr(vim.fn.execute "version", "NVIM v\\zs[^\\n]*")

-- 2. 插件禁用判断：检测是否通过 --noplugin/--noplugins 参数禁用插件
-- 逻辑说明：
-- - vim.api.nvim_get_vvar("argv") 获取 Neovim 启动时的命令行参数列表
-- - vim.list_contains 检查参数中是否包含 --noplugin 或 --noplugins（两者功能相同，兼容不同写法）
-- 用途：禁用插件时，跳过插件相关配置（如快捷键、自动命令），避免报错
local argv = vim.api.nvim_get_vvar "argv"
local noplugin = vim.list_contains(argv, "--noplugin") or vim.list_contains(argv, "--noplugins")

-- 3. 工具函数主表：所有工具函数和全局状态都存储在这里，最后导出
local utils = {
    -- 系统类型判断（多系统适配的核心）
    is_linux = vim.uv.os_uname().sysname == "Linux",  -- 是否为 Linux 系统
    is_mac = vim.uv.os_uname().sysname == "Darwin",   -- 是否为 MacOS 系统（Darwin 是 Mac 内核名称）
    is_windows = vim.uv.os_uname().sysname == "Windows_NT",  -- 是否为 Windows 系统
    is_wsl = string.find(vim.uv.os_uname().release, "WSL") ~= nil,  -- 是否为 WSL（Windows 子系统）
    noplugin = noplugin,  -- 是否禁用插件（上面判断的结果）
    version = version,    -- Neovim 版本号（上面提取的结果）
}

-- 4. 文件类型配置自动命令组：统一管理文件类型相关的自动命令
-- 作用：将所有文件类型配置（如 core/ft.lua 中的规则）归到同一个组，方便后续清理/修改
-- clear = true：创建前清空同名组，避免重复注册自动命令
local ft_group = vim.api.nvim_create_augroup("IceFt", { clear = true })

-- 5. 文件类型配置函数：为指定文件类型绑定配置（核心功能，被 core/ft.lua 调用）
-- 作用：简化文件类型自动命令的创建，无需重复写 vim.api.nvim_create_autocmd
-- 参数说明：
-- - filetype：目标文件类型（如 "python" "html"，支持通配符，如 "*.lua"）
-- - config：配置函数（文件类型匹配时执行的逻辑，如设置缩进、行号等）
---@param filetype string
---@param config function
utils.ft = function(filetype, config)
    -- 创建 FileType 事件自动命令：当打开指定类型文件时，执行 config 函数
    vim.api.nvim_create_autocmd("FileType", {
        pattern = filetype,  -- 匹配的文件类型（如 "python" 匹配所有 .py 文件）
        group = ft_group,    -- 归属于上面创建的 IceFt 组
        callback = config,   -- 触发后执行的配置函数
    })
end

-- 6. 项目根目录获取函数：自动定位当前文件的项目根目录（被 miscellaneous.lua 调用）
-- 作用：编辑项目文件时，以项目根为工作目录，方便相对路径引用（如导入模块、读取配置）
utils.get_root = function()
    -- 默认项目根目录标记：包含这些文件/目录的目录视为项目根（如 .git 是 Git 仓库根标记）
    local default_pattern = {
        ".git",          -- Git 仓库根标记
        "package.json",  -- Node.js 项目根标记
        ".prettierrc",   -- Prettier 配置文件（前端项目）
        "tsconfig.json", -- TypeScript 项目根标记
        "pubspec.yaml",  -- Flutter/Dart 项目根标记
        ".gitignore",    -- Git 忽略文件（通用项目标记）
        "stylua.toml",   -- Stylua 配置文件（Lua 项目）
    }

    -- 用户自定义根目录标记：若 Ice.chdir_root_pattern 是有效表格，则使用用户配置，否则用默认
    local pattern = Ice.chdir_root_pattern
    if pattern == nil or type(pattern) ~= "table" then
        pattern = default_pattern
    end

    -- 获取当前文件的绝对路径（resolve 处理符号链接，expand("%:p") 获取绝对路径，true 表示解析链接）
    local filename = vim.fn.resolve(vim.fn.expand("%:p", true))
    -- 查找项目根目录：vim.fs.root 从当前文件向上遍历，找到包含 pattern 中任一标记的目录
    -- 若未找到，返回当前文件所在目录（vim.fs.dirname(filename)）
    local root = vim.fs.root(filename, pattern) or vim.fs.dirname(filename)

    return root  -- 返回项目根目录路径
end

-- 7. 快捷键批量注册函数：批量绑定快捷键，统一配置选项（被 keymap.lua 调用）
-- 解决痛点：单个绑定快捷键繁琐，批量注册可统一设置默认选项（如 silent、desc）
-- 参数说明：
-- - group：快捷键组（如 Ice.keymap），格式：{ 描述 = { 模式, 快捷键, 执行命令, 可选选项 } }
-- - opt：默认选项（如 { silent = true }），会应用到所有快捷键
---@param group table list of keymaps
---@param opt table | nil default opt
utils.group_map = function(group, opt)
    -- 若未传入默认选项，初始化为空表
    if not opt then
        opt = {}
    end

    -- 遍历快捷键组中的每一个快捷键
    for desc, keymap in pairs(group) do
        -- 将快捷键描述中的下划线替换为空格（如 black_hole_register → "black hole register"）
        -- 用途：作为快捷键的描述信息（desc 选项），方便通过 :checkhealth 或插件查看快捷键含义
        desc = string.gsub(desc, "_", " ")
        -- 合并默认选项：优先级：用户传入的 opt → 内置默认（desc、nowait、silent）
        -- nowait = true：避免快捷键等待（如连续按多个键时不阻塞）
        -- silent = true：执行快捷键时不显示命令执行结果（减少干扰）
        local default_option = vim.tbl_extend("force", { desc = desc, nowait = true, silent = true }, opt)
        -- 深度合并快捷键配置：确保用户传入的选项（如 { noremap = true }）覆盖默认选项
        -- 格式：{ 模式, 快捷键, 执行命令, 最终选项 }
        local map = vim.tbl_deep_extend("force", { nil, nil, nil, default_option }, keymap)
        -- 注册快捷键：vim.keymap.set 是 Neovim 内置快捷键注册函数
        vim.keymap.set(map[1], map[2], map[3], map[4])
    end
end

-- 8. 有序遍历表函数：按键名排序后遍历 Lua 表（Lua 原生 pairs 是无序的）
-- 作用：确保遍历表时顺序一致（如插件列表、图标列表按定义顺序处理）
-- 参数：t 要遍历的表
-- 返回值：迭代器函数（每次调用返回排序后的键和值）
---@param t table
---@return function
utils.ordered_pair = function(t)
    local a = {}  -- 存储表的所有键

    -- 第一步：提取表中所有键，存入数组 a
    for n in pairs(t) do
        a[#a + 1] = n
    end

    -- 第二步：对键进行排序（默认按字符串/数字顺序）
    table.sort(a)

    local i = 0  -- 迭代器索引

    -- 第三步：返回迭代器函数（每次调用 i+1，返回排序后的键和对应的值）
    return function()
        i = i + 1
        return a[i], t[a[i]]
    end
end

-- 9. 表查找增强函数：查找目标值在表中的第一个键/索引（Lua 原生无此功能）
-- 作用：快速判断值是否在表中，并获取其位置（如排除列表判断、配置查找）
-- 参数：
-- - t：目标表（数组/字典均可）
-- - target：要查找的值
-- 返回值：找到则返回对应的键/索引，未找到则返回 nil
---@param t table
---@param target ... | any
---@return ... | any
table.find = function(t, target)
    -- 遍历表中的所有键值对
    for key, value in pairs(t) do
        -- 若值匹配目标，返回对应的键/索引
        if value == target then
            return key
        end
    end

    -- 未找到目标，返回 nil
    return nil
end

-- ==============================================
-- 核心工具函数汇总（新手快速查阅）
-- ==============================================
-- | 函数名         | 核心作用                                  | 适用场景                                  | 注意点                                  |
-- |----------------|-------------------------------------------|-------------------------------------------|-----------------------------------------|
-- | utils.is_linux/is_mac/is_windows/is_wsl | 判断当前系统类型 | 多系统兼容配置（如剪贴板、输入法、终端） | 基于系统内核判断，准确区分 WSL 与 Linux |
-- | utils.noplugin | 检测是否禁用插件 | 跳过插件相关配置（避免报错）              | 响应 --noplugin/--noplugins 启动参数    |
-- | utils.version  | 获取 Neovim 版本号 | 版本兼容性判断（如特定功能仅支持高版本）  | 无额外模块加载，提升启动速度            |
-- | utils.ft       | 绑定文件类型配置 | 为特定文件类型设置规则（如缩进、行号）    | 自动归到 IceFt 命令组，方便管理        |
-- | utils.get_root | 定位项目根目录 | 自动切换工作目录，支持相对路径引用        | 支持用户自定义根目录标记（Ice.chdir_root_pattern） |
-- | utils.group_map | 批量注册快捷键 | 统一绑定多个快捷键，设置默认选项          | 自动生成快捷键描述，支持选项覆盖        |
-- | utils.ordered_pair | 有序遍历表 | 按键名排序遍历（如图标列表、插件列表）    | Lua 原生 pairs 无序，此函数补充有序需求  |
-- | table.find     | 查找表中值的键 | 判断值是否在表中（如排除列表、配置查找）  | 支持数组和字典表，返回第一个匹配的键    |

-- ==============================================
-- 新手使用建议（重要！）
-- ==============================================
-- 1. 无需手动调用：这些工具函数已被其他核心模块（keymap、ft、miscellaneous）自动调用，新手无需手动操作；
-- 2. 扩展用途：若需要自定义功能（如新增文件类型配置、批量注册快捷键），可直接调用这些函数：
--    - 示例1：为 JSON 文件设置 2 空格缩进 → utils.ft("json", function() vim.bo.tabstop = 2 end)
--    - 示例2：批量注册自定义快捷键 → utils.group_map({ my_save = { "n", "<leader>s", "<Cmd>w<CR>" } })
-- 3. 兼容性保障：系统判断函数（is_windows/is_wsl 等）已处理多环境差异，无需担心跨系统使用问题；
-- 4. 表操作增强：table.find 和 ordered_pair 补充了 Lua 原生表的不足，自定义配置时可直接使用：
--    - 示例：判断文件类型是否在排除列表 → if table.find(exclude_ft, vim.bo.filetype) then return end
-- 5. 配置修改：若需要调整默认行为（如项目根目录标记），可通过 Ice 全局表自定义：
--    - 示例：添加 "pyproject.toml" 作为 Python 项目根标记 → Ice.chdir_root_pattern = { "pyproject.toml", ".git" }
-- 6. 问题排查：若某功能（如自动切换工作目录）未生效，可检查对应工具函数的参数是否正确（如排除列表是否包含目标文件类型）

-- 导出工具函数模块：供其他模块 require 调用（如 require "core.utils"）
return utils