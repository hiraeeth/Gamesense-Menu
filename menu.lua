local menu = {
    DEBUG = false,
    SAFE_CALLBACKS = false,
    CALLBACK_MESSAGE = "Callback failed: \f<error>"
}

---@global overrides
local function ternary(condition, true_value, false_value)
    --- Ternary operator.
    --- @param condition boolean The condition to check
    --- @param true_value any The value to return if the condition is true
    --- @param false_value any The value to return if the condition is false
    if condition then
        return true_value
    else
        return false_value
    end
end

local type = function(var, type_name)
    --- Checks the type of a variable.
    --- @param var any The variable to check
    --- @param type_name? string The expected type (optional)
    --- @return string|boolean The type of the variable or a boolean indicating type match
    return ternary(type_name, type(var) == type_name, type(var))
end

local function print_colored(...)
    local args = { ... }
    for key, arg in ipairs(args) do
        if type(arg) == "table" then
            client.color_log(arg[2], arg[3], arg[4], tostring(arg[1]) .. "\0")
        else
            client.color_log(217, 217, 217, tostring(arg) .. "\0")
        end
    end
    client.color_log(1, 1, 1, " ")
end

--- Prints text to the console.
--- @param ... any[] Text or values to print
local function print(...)
    local message = { ... }
    for k, v in ipairs(message) do
        message[k] = tostring(v);
    end
    local message = table.concat(message, " ")
    print_colored(message)
end

local function parse(tbl, fn)
    --- Parses a table using a given function.
    --- @param tbl table The table to parse
    --- @param fn function The function to apply to each key-value pair
    for key, value in pairs(tbl) do
        fn(key, value)
    end
end

math.clamp = function(value, min, max)
    --- Clamps a value within a given range.
    --- @param value number The value to clamp
    --- @param min number The minimum value
    --- @param max number The maximum value
    return math.min(math.max(value, min), max)
end

table.merge = function(...)
    --- Merges multiple tables into a single table.
    --- @vararg table List of tables to merge
    local result = {}
    parse({ ... }, function(_, tbl)
        parse(tbl, function(_, v)
            table.insert(result, v)
        end)
    end)
    return result
end

table.contains = function(tbl, item)
    --- Checks if a table contains a specific item.
    --- @param tbl table The table to check
    --- @param item any The item to search for
    for _, value in pairs(tbl) do
        if tostring(value) == tostring(item) then
            return true
        end
    end
    return false
end

local function switch(c)
    --- Implements a switch-case statement.
    --- @param c any The variable to switch upon
    local cases = {
        var = c,
        default = nil,
        missing = nil
    }
    setmetatable(cases, {
        __call = function(self, code)
            local f
            if self.var then
                for case, func in pairs(code) do
                    if type(case) == "table" and table.contains(case, self.var) or case == self.var then
                        f = func
                        break
                    end
                end
                f = f or code.default
            else
                f = code.missing or code.default
            end
            if f then
                if type(f) == "function" then
                    return f(self.var, self)
                else
                    print("case ", "\b" .. tostring(self.var), " is not a valid function")
                end
            end
        end
    })
    return cases
end

local function menu_error(...)
    --- Prints menu-related errors to the console.
    --- @param ... any[] Error messages or values to print
    local args = { ... }

    parse(args, function(key, arg)
        args[key] = tostring(arg)
    end)
    print_colored({ _NAME .. " » ", 171, 219, 0 }, table.concat(args, " "))
end

local aliases = {}
menu.alias = function(word, alias)
    if word:find(" ") then
        return menu_error("[menu_alias] You can not use empty spaces inside alises (use underline instead)")
    end

    if aliases[word] then
        return menu_error(("[menu_alias] Word '%s' is already aliased as '%s'"):format(word, aliases[word]))
    end

    aliases[word] = alias
    return { word, alias }
end

menu.contains = function(element, value)
    --- Checks if an element contains a specific value.
    --- @param element any The menu element to check
    --- @param value any The value to search for
    --- @return boolean True if the element contains the value, false otherwise
    local boolean = false
    switch(element:type()) {
        listbox = function()
            boolean = element:list()[element:get() + 1] == value
        end,
        combobox = function()
            boolean = element:get() == value
        end,
        multiselect = function()
            for _, v in ipairs(element:get()) do
                if v == value then
                    boolean = true
                end
            end
        end
    }
    return boolean
end

--- @return group struct
menu.group = function(tab, container)
    --- Creates a menu group.
    --- @param tab any The menu tab
    --- @param container any The menu container
    local struct = {
        tab = tab,
        container = container
    }
    setmetatable(struct, {
        __index = function(self, key)
            return function(...)
                local args = { ... }

                if tostring(args[1]) ~= "menu::group" then
                    return menu_error("[menu_group] Please use the menu group as an object.")
                end

                local g = args[1]
                table.remove(args, 1)

                if table.contains(args, "menu::group") then
                    return menu_error("[menu_group] You can not use a group as argument.")
                end

                return menu[key](g.tab, g.container, unpack(args));
            end
        end,
        __tostring = function(self)
            return string.format("menu::%s", "group")
        end,
        __newindex = function()
            return
        end,
        __metatable = false
    })
    return struct
end

--- @return element struct The menu element structure
local function struct(menu_type, item, args)
    --- Creates a menu element structure.
    --- @param menu_type string The type of menu element
    --- @param item any The menu element reference
    --- @param args? table The arguments for the menu element (optional)
    local struct = {
        dependency = {},
        is_visible = true,
        menu_type = menu_type,

        --- Gets the value of the menu element.
        --- @return any The value of the menu element
        get = function(self)
            if not self then
                menu_error(("Invalid usage, please use: [%s]:get()"):format(menu_type))
                return
            end
            return ui.get(item)
        end,

        --- Sets the value of the menu element.
        --- @vararg any Values to set for the menu element
        --- @return {element: menu_element, any: ...} The menu element and set values
        set = function(self, ...)
            if not self then
                menu_error(("Invalid usage, please use: [%s]:set(...)"):format(menu_type))
                return
            end
            ui.set(item, ...)
            return { self, ... }
        end,

        --- Gets the reference of the menu element.
        --- @return number The reference number of the menu element
        reference = function(self)
            if not self then
                menu_error(("Invalid usage, please use: [%s]:reference()"):format(menu_type))
                return
            end
            return item
        end,

        --- Sets the visibility of the menu element.
        --- @param boolean boolean The visibility status
        --- @return {element: menu_element, boolean: value_to_set} The menu element and set visibility status
        set_visible = function(self, boolean)
            if not self then
                menu_error(("Invalid usage, please use: [%s]:set_visible(boolean)"):format(menu_type))
                return
            end
            ui.set_visible(item, boolean)
            self.is_visible = boolean
            return { self, boolean }
        end,

        --- Sets the enabled status of the menu element.
        --- @param boolean boolean The enabled status
        --- @return {element: menu_element, boolean: value_to_set} The menu element and set enabled status
        set_enabled = function(self, boolean)
            if not self then
                menu_error(("Invalid usage, please use: [%s]:set_enabled(boolean)"):format(menu_type))
                return
            end
            ui.set_enabled(item, boolean)
            return { self, boolean }
        end,

        --- Sets the callback function for the menu element.
        --- @param callback function The callback function
        --- @return {element: menu_element, function: callback} The menu element and set callback function
        set_callback = function(self, callback)
            if not self then
                menu_error(("Invalid usage, please use: [%s]:set_callback(function(element, original))"):format(
                menu_type))
                return
            end

            local safe = menu.SAFE_CALLBACKS or false
            local cb = function(menu_ref)
                if safe then
                    local success, error_message = pcall(callback, self, menu_ref)
                    if not success then
                        local placeholder = menu.CALLBACK_MESSAGE:match("\f<(%w+)>")
                        if (menu.DEBUG and not placeholder) then
                            menu_error("WARNING! No error placeholder found, the error will be omitted from the message.");
                        end
                        return menu_error(placeholder and menu.CALLBACK_MESSAGE:gsub("\f<" .. placeholder .. ">", error_message) or menu.CALLBACK_MESSAGE)
                    end
                else
                    callback(self, menu_ref)
                end
            end

            ui.set_callback(item, cb)
            return { self, callback }
        end,
        --- Gets the name of the menu element.
        --- @return string The name of the menu element
        name = function(self)
            if not self then
                menu_error(("Invalid usage, please use: [%s]:name()"):format(menu_type))
                return
            end
            return ui.name(item)
        end,

        --- Gets the type of the menu element.
        --- @return string The type of the menu element
        type = function(self)
            if not self then
                menu_error(("Invalid usage, please use: [%s]:type()"):format(menu_type))
                return
            end
            return ui.type(item)
        end,

        --- Adds a dependency to the menu element.
        --- @param dependency table The dependent menu element
        --- @param value any The optional value for the dependency
        --- @return {element: menu_element, dependency: menu_element, boolean: dependency_value, any: value} The menu element, dependency, dependency value, and optional value
        depend = function(self, dependency, value)
            if not (self and dependency) then
                return menu_error("Invalid usage, please use: [element]:depend(element, ?value)")
            end

            self.dependency = self.dependency or {}
            if not table.contains(self.dependency, { dependency, value or nil }) then
                table.insert(self.dependency, { dependency, value or nil })
            end

            local vis = true
            for k, v in ipairs(self.dependency) do
                vis = vis and ternary(v[2], menu.contains(v[1], value), v[1]:get())
            end

            self.is_visible = vis
            self:set_visible(vis)

            return ternary(value, { self, dependency, dependency:get(), value }, { self, dependency, dependency:get() })
        end,

        -- Adds more dependecies to a menu element
        multi_depend = function(self, ...)
            if not self then
                menu_error(("Invalid usage, please use: [%s]:multi_depend(...)"):format(menu_type))
                return
            end
            for k, v in ipairs({ ... }) do
                if (v[1] ~= nil) then
                    self:depend(v[1], v[2])
                else
                    self:depend(v)
                end
            end
            return self.dependency
        end,

        --- Updates the menu element.
        --- @vararg any Values to update for the menu element
        --- @return {element: menu_element, any: ...} The menu element and updated values
        update = function(self, ...)
            if not self then
                menu_error(("Invalid usage, please use: [%s]:update(...)"):format(menu_type))
                return
            end
            ui.update(item, ...)
            return { self, ... }
        end,

        --- Checks if the menu element contains a specific value.
        --- @param value any The value to check
        --- @return boolean True if the element contains the value, false otherwise
        contains = function(self, value)
            if not self then
                menu_error(("Invalid usage, please use: [%s]:contains(value)"):format(menu_type))
                return
            end
            return menu.contains(self, value)
        end
    }

    if args then
        struct.args = args

        --- Gets the list content of the menu element.
        --- @return table|nil The list content or nil if not applicable
        struct.list = function(self)
            if not self then
                menu_error(("Invalid usage, please use: [%s]:list()"):format(menu_type))
                return
            end
            return type(args[4]) == "table" and args[4] or nil
        end
    end

    setmetatable(struct, {
        __tostring = function(self)
            if (args and type(args[4], "table")) then
                return string.format("%s::%s[%s](%s)", menu_type, struct:type(), #args[4], struct:name())
            else
                return string.format("%s::%s(%s)", menu_type, struct:type(), struct:name())
            end
        end,
        __newindex = function()
            return
        end,
        __metatable = false
    })

    return struct
end

--- Referencing to a gamesense element
---@vararg any The arguments provided to the menu element
---@return table A struct representing the menu element
menu.find = function(...)
    local args = { ... }
    local items = {}

    local refs = { ui.reference(unpack(args)) }
    for _, item in ipairs(refs) do
        local ref = struct("reference", item);
        table.insert(items, ref)
    end

    if (#items < 1) then
        return menu_error("The element is either non-existent or the provided path is invalid.")
    end

    return unpack(items)
end

setmetatable(menu, {
    __index = function(self, index)
        return function(...)
            local args = { ... }

            parse(args, function(i, arg)
                if type(arg) == "string" then
                    local placeholder = arg:match("\f<(%w+)>")
                    local alias = aliases[placeholder]
                    if placeholder and alias then
                        arg = arg:gsub("\f<" .. placeholder .. ">", alias)
                        args[i] = arg
                    end
                end
                if tostring(arg) == "menu::group" then
                    args[i] = arg.tab;
                    table.insert(args, i + 1, arg.container)
                end
            end)

            switch(index) {
                button = function()
                    if args[4] == nil then
                        table.insert(args, function()
                        end)
                    end
                end
            }

            local item = ui["new_" .. index](unpack(args))
            return struct("element", item, args)
        end
    end,
    __newindex = function()
        return
    end,
    __metatable = false
})

return menu
