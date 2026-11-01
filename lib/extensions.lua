local class = require("rmp.oop").class
local Queue = require("rmp.util").Queue

---@class Extension
---@field state table
---@field frame table
---@field queue_able_functions table
local Extension <const> = class("Extension")
do
    function Extension:constructor(state, frame)
        self.state = state
        self.frame = frame
        self.queue_able_functions = Queue()
    end

    function Extension:setState(state)
        self.state = state
    end

    function Extension:setFrame(frame)
        self.frame = frame
    end

    --- register a callback extension
    --- @param cb fun(state:table , frame : table)
    function Extension:register(cb)
        if not cb then
            return
        end

        self.queue_able_functions:push(cb)
    end

    function Extension:apply()
        while not self.queue_able_functions:isEmpty() do
            local fnc = self.queue_able_functions:pop()
            if fnc and type(fnc) == "function" then
                fnc(self.frame, self.state)
            end
        end
    end
end

return Extension
