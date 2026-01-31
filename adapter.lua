local TS = loadstring(game:HttpGet("https://raw.githubusercontent.com/sametexe001/sametlibs/refs/heads/main/Thugsense/Library.lua"))()

local Library = {}
Library.Tabs = {}
Library.Options = {}
Library.Toggles = {}
Library.Holder = {}
Library.Flags = {}

local auto_flag = 0
local function resolveFlag(flag, kind)
    if flag then return flag end
    auto_flag += 1
    return "__auto_" .. (kind or "flag") .. "_" .. auto_flag
end

function Library:CreateWindow(params)
    local window = TS:Window({
        Name = params.Title or params.Name or "Window",
        FadeSpeed = params.MenuFadeTime or 0.25,
    })

    function window:AddTab(name, icon)
        local tab = window:Page({ Name = name, Columns = 2 })

        function tab:AddLeftTabbox()
            local box = {}
            function box:AddTab(tabName)
                local section = tab:Section({ Name = tabName, Side = 1 })
                return Library:WrapSection(section)
            end
            return box
        end

        function tab:AddRightTabbox()
            local box = {}
            function box:AddTab(tabName)
                local section = tab:Section({ Name = tabName, Side = 2 })
                return Library:WrapSection(section)
            end
            return box
        end

        function tab:AddLeftGroupbox(name)
            return Library:WrapSection(tab:Section({ Name = name, Side = 1 }))
        end

        function tab:AddRightGroupbox(name)
            return Library:WrapSection(tab:Section({ Name = name, Side = 2 }))
        end

        Library.Tabs[name] = tab
        return tab
    end

    Library.Window = window
    return window
end

function Library:WrapSection(section)
    local wrapper = {}

    local function safeOnChanged(obj, callback)
        if obj.OnChanged then
            obj:OnChanged(callback)
        else
            -- fallback for objects like Colorpicker that sometimes lack OnChanged
            local last = obj.Value or obj:GetValue and obj:GetValue()
            task.spawn(function()
                while task.wait() do
                    local val = obj.Value or obj:GetValue and obj:GetValue()
                    if val ~= last then
                        last = val
                        callback(val)
                    end
                end
            end)
        end
    end

    local function wrapGeneric(obj, flag)
        local w = {}
        function w:OnChanged(fn)
            safeOnChanged(obj, fn)
            return self
        end
        function w:SetValue(v)
            if obj.SetValue then obj:SetValue(v) end
            Library.Flags[flag] = v
            return self
        end
        function w:GetValue()
            return Library.Flags[flag]
        end
        return w
    end

    local function wrapToggle(obj, flag)
        local w = wrapGeneric(obj, flag)
        function w:AddColorPicker() return self end
        function w:AddKeyPicker() return self end
        return w
    end

    local function wrapKey(obj, flag)
        local w = wrapGeneric(obj, flag)
        function w:GetState() return Library.Flags[flag] end
        return w
    end

    function wrapper:AddToggle(params)
        local flag = resolveFlag(params.Flag, "toggle")
        local obj = section:Toggle({
            Name = params.Text or params.Name,
            Default = params.Default,
            Flag = flag,
            Callback = params.Callback,
        })
        Library.Toggles[flag] = obj
        Library.Flags[flag] = params.Default or false

        safeOnChanged(obj, function(v)
            Library.Flags[flag] = v
            if params.Callback then params.Callback(v) end
        end)

        return wrapToggle(obj, flag)
    end

    function wrapper:AddCheckbox(params)
        return wrapper:AddToggle(params)
    end

    function wrapper:AddSlider(params)
        local flag = resolveFlag(params.Flag, "slider")
        local obj = section:Slider({
            Name = params.Text or params.Name,
            Min = params.Min,
            Max = params.Max,
            Default = params.Default,
            Suffix = params.Suffix,
            Decimals = params.Rounding or params.Decimals,
            Flag = flag,
            Callback = params.Callback,
        })
        Library.Options[flag] = obj
        Library.Flags[flag] = params.Default

        safeOnChanged(obj, function(v)
            Library.Flags[flag] = v
            if params.Callback then params.Callback(v) end
        end)

        return wrapGeneric(obj, flag)
    end

    function wrapper:AddDropdown(params)
        local flag = resolveFlag(params.Flag, "dropdown")
        local obj = section:Dropdown({
            Name = params.Text or params.Name,
            Items = params.Values or params.Items or {},
            Default = params.Default,
            Multi = params.Multi or false,
            Flag = flag,
            Callback = params.Callback,
        })
        Library.Options[flag] = obj
        Library.Flags[flag] = params.Default

        safeOnChanged(obj, function(v)
            Library.Flags[flag] = v
            if params.Callback then params.Callback(v) end
        end)

        return wrapGeneric(obj, flag)
    end

    function wrapper:AddInput(params)
        local flag = resolveFlag(params.Flag, "input")
        local obj = section:TextBox({
            Name = params.Text or params.Name,
            Default = params.Default,
            Numeric = params.Numeric,
            Placeholder = params.Placeholder,
            Flag = flag,
            Callback = params.Callback,
        })
        Library.Options[flag] = obj
        Library.Flags[flag] = params.Default

        safeOnChanged(obj, function(v)
            Library.Flags[flag] = v
            if params.Callback then params.Callback(v) end
        end)

        return wrapGeneric(obj, flag)
    end

    function wrapper:AddColorPicker(params)
        local flag = resolveFlag(params.Flag, "color")
        local obj = section:Colorpicker({
            Name = params.Title or params.Text or params.Name,
            Default = params.Default or Color3.fromRGB(255,255,255),
            Flag = flag,
            Callback = params.Callback,
        })
        Library.Options[flag] = obj
        Library.Flags[flag] = params.Default

        safeOnChanged(obj, function(v)
            Library.Flags[flag] = v
            if params.Callback then params.Callback(v) end
        end)

        return wrapGeneric(obj, flag)
    end

    function wrapper:AddKeyPicker(params)
        local flag = resolveFlag(params.Flag, "key")
        local obj = section:Keybind({
            Name = params.Text or params.Name,
            Default = params.Default,
            Mode = params.Mode or "Toggle",
            Flag = flag,
            Callback = params.Callback,
        })
        Library.Options[flag] = obj
        Library.Flags[flag] = false

        safeOnChanged(obj, function(v)
            Library.Flags[flag] = v
            if params.Callback then params.Callback(v) end
        end)

        return wrapKey(obj, flag)
    end

    function wrapper:AddButton(params)
        section:Button({
            Name = params.Text or params.Name,
            Func = params.Func,
        })
        return wrapper
    end

    function wrapper:AddLabel(text)
        section:Label({ Text = type(text) == "table" and text.Text or text })
        return wrapper
    end

    function wrapper:AddDivider()
        section:Divider()
        return wrapper
    end

    return wrapper
end

function Library:Notify(params)
    TS:Notification(
        (params.Title or "Notification") .. "\n" .. (params.Description or ""),
        params.Time or 3,
        params.Color or Color3.fromRGB(255,255,255)
    )
end

function Library:Notification(text, time, color)
    TS:Notification(text, time or 3, color or Color3.fromRGB(255,255,255))
end

function Library:SetWatermarkVisibility(bool)
    if Library.Window and Library.Window.Watermark then
        Library.Window.Watermark:SetVisibility(bool)
    end
end

function Library:Unload()
    if Library.Window then
        Library.Window:Close()
    end
end

return Library
