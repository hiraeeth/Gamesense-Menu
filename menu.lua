local menu = {}
--[[
    Object oriented gamesense menu system
    Created by dragos112 

    📂 - Functions (element as menu_element):
    - element:get 
    - element:set 
    - element:set_visible
    - element:set_enabled
    - element:set_callback
    - element:name

    🆕 - Added by me 
    - element:reference
    - element:type
    - element:list
    - element:depend
    - element:update
    - element:contains

    🔗 - Other properties
    - element.args
    - element.dependency
    - element.is_visible

    📜 - Note: menu_element is a structure that includes all the functions mentioned above.
    🚨 - Warning! Please use ":" to call functions and "." to access properties of menu elements.

    @module menu
]]

--[[
    📜 - For each function, I've provided instructions in case you want to use it in your own code.
]]

-- Prints colored text to the console
---@param ... any[] Text or values to print
local print_colored = function(...)
    local args = {...}
    for key, arg in ipairs(args) do
        if type(arg) == "table" then
            client.color_log(arg[2], arg[3], arg[4], tostring(arg[1]) .. "\0")
        else
            client.color_log(217, 217, 217, tostring(arg) .. "\0")
        end
    end
    client.color_log(1, 1, 1, " ")
end

-- Prints text to the console
---@param ... any[] Text or values to print
local print = function(...)
    local message = {...}
    for k, v in ipairs(message) do
        message[k] = tostring(v);
    end
    local message = table.concat(message, " ")
    print_colored(message)
end

-- Converts RGB values to hexadecimal color format
---@param r number Red value (0-255)
---@param g number Green value (0-255)
---@param b number Blue value (0-255)
---@param a? number Alpha value (0-255), optional
local toHEX = function(r, g, b, a)
    return string.format('\a%02X%02X%02X%02X', r, g, b, a or 255)
end

-- Implements a ternary operator
---@param condition boolean The condition to check
---@param true_value any Value to return if the condition is true
---@param false_value any Value to return if the condition is false
local ternary = function(condition, true_value, false_value)
    if condition then
        return true_value
    else
        return false_value
    end
end

-- Checks the type of a variable
---@param var any The variable to check
---@param type_name? string The expected type (optional)
local type = function(var, type_name)
    return ternary(type_name, type(var) == type_name, type(var))
end

-- Parses a table using a given function
---@param tbl table The table to parse
---@param fn function The function to apply to each key-value pair
local parse = function(tbl, fn)
    for key, value in pairs(tbl) do
        return fn(key, value)
    end
end

-- Clamps a value within a given range
---@param value number The value to clamp
---@param min number The minimum value
---@param max number The maximum value
math.clamp = function(value, min, max)
    return math.min(math.max(value, min), max)
end

-- Merges multiple tables into a single table
---@vararg table List of tables to merge
table.merge = function(...)
    local result = {}
    parse({...}, function(k, tbl)
        parse(tbl, function(_, v)
            table.insert(result, v)
        end)
    end)
    return result
end

-- Checks if a table contains a specific item
---@param table table The table to check
---@param item any The item to search for
table.contains = function(table, item)
    for _, value in pairs(table) do
        if value == item then
            return true
        end
    end
    return false
end

-- Implements a switch-case statement
---@param c any The variable to switch upon
local switch = function(c)
    local cases = {
        var = c,
        default = nil,
        missing = nil
    }
    setmetatable(cases, {
        __call = function(self, code)
            local f
            if (self.var) then
                for case, func in pairs(code) do
                    if type(case) == "table" and table.contains(case, self.var) or case == self.var then
                        f = func
                        break
                    end
                end
                if not f then
                    f = code.default
                end
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

-- Prints menu-related errors to the console
---@param ... any[] Error messages or values to print
local menu_error = function(...)
    local args = {...}
    parse(args, function(key, arg)
        args[key] = tostring(arg)
    end)
    print_colored({_NAME .. " » ", 171, 219, 0}, table.concat(args, " "))
end

-- Checks if an element contains a specific value
---@param element any The menu element to check
---@param value any The value to search for
---@return boolean True if the element contains the value, false otherwise
menu.contains = function(element, value)
    local boolean = false;
    switch(element:type()) {
        listbox = function()
            boolean = element:list()[element:get() + 1] == value
        end,
        combobox = function()
            boolean = element:get() == value
        end,
        multiselect = function()
            parse(element:get(), function(key, name)
                if name == value then
                    boolean = true
                end
            end)
        end
    }
    return boolean
end

---@param args any The arguments provided to the menu element
---@field dependency table[] The dependency array of the menu element
---@field is_visible boolean The visibility status of the menu element
---@field get fun(): any Returns the value of the menu element
---@field set fun(...): {any} Sets the value of the menu element
---@field reference fun(): any Returns a reference to the menu element
---@field set_visible fun(boolean): {any} Sets the visibility of the menu element
---@field set_enabled fun(boolean): {any} Sets the enabled status of the menu element
---@field set_callback fun(callback: fun(self: any, menu_ref: any)): {any} Sets a callback for the menu element
---@field name fun(original?: any): any Returns the name of the menu element or original if provided
---@field type fun(): string Returns the type of the menu element as a string
---@field list fun(): table | nil Returns the list of values of the menu element or nil if not a table
---@field depend fun(dependency: any, value: any): {any} Handles dependencies of the menu element
---@field update fun(...): {any} Updates the menu element with new values
setmetatable(menu, {
    __index = function(self, index)
        return function(...)
            local args = {...}
            local name = args[3]
            switch(index) {
                button = function()
                    if args[4] == nil then
                        table.insert(args, function()
                        end)
                    end
                end
            }

            local item = ui["new_" .. index](unpack(args))
            local struct = {
                args = args,
                dependency = {},
                is_visible = true,

                ---@return any 
                get = function(self)
                    if not self then
                        menu_error("Invalid usage, please use: [element]:get()")
                        return
                    end
                    return ui.get(item)
                end,

                ---@return {element: menu_element, any: ...} 
                set = function(self, ...)
                    if not self then
                        menu_error("Invalid usage, please use: [element]:set(any: ...)")
                        return
                    end
                    ui.set(item, unpack({...}))
                    return {self, unpack({...})}
                end,

                ---@return number
                reference = function(self)
                    if not self then
                        menu_error("Invalid usage, please use: [element]:reference()")
                        return
                    end
                    return item
                end,

                ---@return {element: menu_element, boolean: value_to_set} 
                set_visible = function(self, boolean)
                    if not self then
                        menu_error("Invalid usage, please use: [element]:set_visibile(boolean: value_to_set)")
                        return
                    end
                    ui.set_visible(item, boolean)
                    self.visibility = boolean
                    return {self, boolean}
                end,

                ---@return {element: menu_element, boolean: value_to_set} 
                set_enabled = function(self, boolean)
                    if not self then
                        menu_error("Invalid usage, please use: [element]:set_enabled(boolean: value_to_set)")
                        return
                    end
                    ui.set_enabled(item, boolean)
                    return {self, boolean}
                end,

                ---@return {element: menu_element, function: callback} 
                set_callback = function(self, callback)
                    if not (self and callback) then
                        menu_error("Invalid usage, please use: [element]:set_callback(void: function(element: reference, number: original))")
                        return
                    end
                    ui.set_callback(item, function(menu_ref)
                        callback(self, menu_ref)
                    end)
                    return {self, callback}
                end,

                ---@return name as string
                name = function(self, original)
                    if not self then
                        menu_error("Invalid usage, please use: [element]:name(boolean?: original)")
                        return
                    end
                    if original then
                        return original
                    else
                        return ui.name(item)
                    end
                end,

                ---@return type as string 
                type = function(self)
                    if not self then
                        menu_error("Invalid usage, please use: [element]:type()")
                        return
                    end
                    return ui.type(item)
                end,

                ---@return list_content as table
                list = function(self)
                    if not self then
                        menu_error("Invalid usage, please use: [element]:list()")
                        return
                    end
                    if type(args[4], "table") then
                        return args[4]
                    else
                        return nil
                    end
                end,

                ---@return {element: menu_element, dependency: menu_element, boolean: dependency_value, any: value} 
                depend = function(self, dependency, value)
                    if not (self and dependency) then
                        menu_error("Invalid usage, please use: [element]:depend(element: menu_element)")
                        return
                    end

                    self.visibility = ternary(value, menu.contains(dependency, value), dependency:get())
                    ui.set_visible(item, ternary(value, menu.contains(dependency, value), dependency:get()))

                    self.dependency = self.dependency or {}
                    if not table.contains(self.dependency, dependency) then
                        table.insert(self.dependency, dependency)
                    end

                    return ternary(value, {self, dependency, dependency:get(), value}, {self, dependency, dependency:get()})
                end,

                ---@return {element: menu_element, any: ...} 
                update = function(self, ...)
                    if not (self and ...) then
                        menu_error("Invalid usage, please use: [element]:update(any: ...)")
                        return
                    end
                    ui.update(item, unpack({...}))
                    return {self, unpack({...})}
                end,

                ---@return value as boolean
                contains = function(self, value)
                    if not (self and value) then
                        menu_error("Invalid usage, please use: [element]:contains(any: value)")
                        return
                    end
                    return menu.contains(self, value)
                end
            }

            setmetatable(struct, {
                __tostring = function(self)
                    if type(args[4], "table") then
                        return string.format("%s::%s[%s](%s)", "element", index, #args[4], name)
                    else
                        return string.format("%s::%s(%s)", "element", index, name)
                    end
                end,
                __newindex = function()
                    return
                end,
                __metatable = false
            })

            return struct
        end
    end,
    __newindex = function()
        return
    end,
    __metatable = false
})

return menu
