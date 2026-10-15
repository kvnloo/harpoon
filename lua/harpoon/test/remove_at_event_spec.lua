-- Assert the public REMOVE event payload is preserved during indexed removal.
local List = require("harpoon.list")
local Config = require("harpoon.config")
local Extensions = require("harpoon.extensions")
local eq = assert.are.same

describe("HarpoonList:remove_at REMOVE event", function()
    it("delivers the original removed item, index, and list exactly once", function()
        local config = Config.get_config(Config.merge_config(), "custom")
        local first = { value = "first", context = { kind = "note" } }
        local second = { value = "second", context = { kind = "note" } }
        local list = List:new(config, "custom", { first, second })
        local events = {}
        local listener = {
            REMOVE = function(payload)
                events[#events + 1] = payload
            end,
        }

        local listeners = Extensions.extensions.listeners
        local listener_idx = #listeners + 1
        Extensions.extensions:add_listener(listener)
        local ok, err = pcall(function()
            list:remove_at(1)
            list:remove_at(1) -- Hole must not re-emit REMOVE.
            list:remove_at(2)

            eq(2, #events)
            assert.is_true(events[1].item == first)
            assert.is_true(events[2].item == second)
            eq(1, events[1].idx)
            eq(2, events[2].idx)
            assert.is_true(events[1].list == list)
            assert.is_true(events[2].list == list)
            eq(0, list:length())
        end)
        table.remove(listeners, listener_idx)
        assert(ok, err)
    end)
end)
