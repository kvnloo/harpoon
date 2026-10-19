-- The REMOVE event must carry the stored object, not an equal-valued lookup key.
local List = require("harpoon.list")
local Config = require("harpoon.config")
local Extensions = require("harpoon.extensions")
local eq = assert.are.same

describe("HarpoonList:remove REMOVE event identity", function()
    it("preserves stored context and emits once to all listeners", function()
        local config = Config.get_config(Config.merge_config(), "custom")
        local stored = { value = "task", context = { row = 19, col = 6 } }
        local lookup = { value = "task", context = { row = 1, col = 0 } }
        local list = List:new(config, "custom", { stored })
        local seen, calls = {}, {}
        local listeners = Extensions.extensions.listeners
        local before = #listeners
        Extensions.extensions:add_listener({
            REMOVE = function(event)
                seen[#seen + 1] = event
                calls[#calls + 1] = "first"
            end,
        })
        Extensions.extensions:add_listener({
            REMOVE = function(event)
                assert.is_true(event == seen[#seen])
                calls[#calls + 1] = "second"
            end,
        })

        local ok, err = pcall(function()
            assert.is_true(list:remove(lookup) == list)
            list:remove(lookup) -- Already removed: no second event.
            eq({ "first", "second" }, calls)
            eq(1, #seen)
            eq(1, seen[1].idx)
            assert.is_true(seen[1].list == list)
            assert.is_true(seen[1].item == stored)
            eq(19, seen[1].item.context.row)
            eq(6, seen[1].item.context.col)
            eq(0, list:length())
        end)
        table.remove(listeners, before + 2)
        table.remove(listeners, before + 1)
        assert(ok, err)
    end)
end)
