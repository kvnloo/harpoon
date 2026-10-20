-- Custom equality callbacks receive HarpoonListItem values, not sparse nil slots.
local List = require("harpoon.list")
local Config = require("harpoon.config")
local Extensions = require("harpoon.extensions")
local eq = assert.are.same

local function new_sparse_list()
    local config = Config.get_config(Config.merge_config(), "custom")
    config.equals = function(left, right)
        return left.value == right.value
    end

    local first = { value = "first" }
    local target = { value = "target", context = { kind = "note" } }
    local last = { value = "last" }
    local list = List:new(config, "custom", { first, target, last })
    list:remove_at(1)
    eq(3, list:length())
    eq(nil, list:get(1))
    return list, target, last
end

describe("HarpoonList with sparse custom equality", function()
    it("remove compares only stored items and leaves missing lookups inert", function()
        local list, target, last = new_sparse_list()
        local events = {}
        local listeners = Extensions.extensions.listeners
        local listener_idx = #listeners + 1
        Extensions.extensions:add_listener({
            REMOVE = function(payload)
                events[#events + 1] = payload
            end,
        })
        local ok, err = pcall(function()
            assert.is_true(list:remove({ value = "target" }) == list)
            eq(1, #events)
            assert.is_true(events[1].item == target)
            assert.is_true(events[1].list == list)
            eq(2, events[1].idx)
        end)
        table.remove(listeners, listener_idx)
        assert(ok, err)
        eq(nil, list:get(2))
        assert.is_true(list:get(3) == last)
        assert.is_true(list:remove({ value = "missing" }) == list)
        assert.is_true(list:get(3) == last)
        eq(3, list:length())
        list:remove({ value = "last" })
        eq(0, list:length())
    end)

    it("add reuses the first hole without passing nil to equals", function()
        local list, target, last = new_sparse_list()
        local inserted = { value = "inserted" }
        assert.is_true(list:add(inserted) == list)
        assert.is_true(list:get(1) == inserted)
        assert.is_true(list:get(2) == target)
        assert.is_true(list:get(3) == last)
        eq(3, list:length())
    end)

    it("prepend inserts into a leading hole without passing nil to equals", function()
        local list, target, last = new_sparse_list()
        local inserted = { value = "inserted" }
        assert.is_true(list:prepend(inserted) == list)
        assert.is_true(list:get(1) == inserted)
        assert.is_true(list:get(2) == target)
        assert.is_true(list:get(3) == last)
        eq(3, list:length())
    end)

    it("replace_at fills holes and removes duplicates with custom equals", function()
        local list, target, last = new_sparse_list()
        local inserted = { value = "inserted", context = { kind = "new" } }
        list:replace_at(1, inserted)
        assert.is_true(list:get(1) == inserted)
        assert.is_true(list:get(2) == target)
        assert.is_true(list:get(3) == last)
        eq(3, list:length())

        local duplicate, kept, original = new_sparse_list()
        local caller = { value = "last", context = { kind = "caller" } }
        duplicate:replace_at(1, caller)
        assert.is_true(duplicate:get(1) == caller)
        assert.is_true(duplicate:get(2) == kept)
        eq(nil, duplicate:get(3))
        eq(2, duplicate:length())
        assert.is_true(caller ~= original)
    end)
end)
