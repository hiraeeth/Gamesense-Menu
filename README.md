# Object Oriented GameSense Menu System
The primary component is the `menu` table, which contains various functions and properties to handle menu elements.

# How to use it?
> Import the library
```
local menu = require("menu")
```

> Create an element
```
local test = menu.combobox("CONFIG", "LUA", "Hello", {"test", "hello", "baby"})
```

> Acces the functions
```
print(test:contains("test"))
print(test.args) -- TABLE: {"CONFIG", "LUA", "Hello", {"test", "hello", "baby"}}
print(test) -- element::combobox[3](Hello)
```

# get
> Returns the value of the menu element.
### Usage:
```
element:get()
```

# set
> Sets the value of the menu element.
### Usage:
```
element:set(any: ...)
```

# reference
> Returns a reference to the menu element.
### Usage:
```
element:reference()
```

# set_visible
> Sets the visibility of the menu element.
### Usage:
```
element:set_visible(boolean: value_to_set)
```

# set_enabled
> Sets the enabled status of the menu element.
### Usage:
```
element:set_enabled(boolean: value_to_set)
```

# set_callback
> Sets a callback for the menu element.
### Usage:
```
element:set_callback(void: function(element: reference, number: original))
```

# name
> Returns the name of the menu element.
### Usage:
```
element:name(boolean?: original)
```

# type
> Returns the type of the menu element as a string.
### Usage:
```
element:type()
```

# list
> Returns the list of values of the menu element or nil if not a table.
### Usage:
```
element:list()
```

# depend
> Handles dependencies of the menu element.
### Usage:
```
element:depend(element: menu_element)
```
  
# update
> Updates the menu element with new values.
### Usage:
```
element:update(any: ...)
```

# contains
> Checks if an element contains a specific value.
### Usage:
```
element:contains(any: value)
```

---

*Note: These functions are accessed using the `:` operator.*
*You can also access other properties like **args**, **dependency** and **is_visible** by using the `.` operator.*
