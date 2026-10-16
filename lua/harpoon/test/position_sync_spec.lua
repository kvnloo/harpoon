-- Regression: #685 should retain cursor restoration for ordinary and named file lists
-- after #1 protects custom items without file-position context.
local List = require("harpoon.list")
local Config = require("harpoon.config")
local Path = require("plenary.path")
local eq = assert.are.same

describe("position sync", function()
    for _, list_name in ipairs({ Config.DEFAULT_LIST, "named-file-list" }) do
        it("updates an existing file item in " .. list_name, function()
            local cfg = Config.get_config(Config.merge_config(), list_name)
            local bufnr = vim.api.nvim_get_current_buf()
            local current_file = Path:new(vim.api.nvim_buf_get_name(bufnr))
                :make_relative(cfg.get_root_dir())
            local item = {
                value = current_file,
                context = { row = -1, col = -1 },
            }
            local list = List:new(cfg, list_name, { item })
            local cursor = vim.api.nvim_win_get_cursor(0)

            Config.update_harpoon_item_position(list, bufnr)

            eq({ row = cursor[1], col = cursor[2] }, item.context)
            eq(1, list:length())
            eq(item, list.items[1])
        end)
    end
end)
