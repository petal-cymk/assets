local root = "SOLUTIONS"
local structure = {
    "assets",
    "assets/sounds",
    "assets/images",
    "cache"
}

for _, path in ipairs(structure) do
    local full = root .. "/" .. path
    if not isfolder(full) then
        makefolder(full)
    end
end

local function import(name, folder, link)
    local path = root .. "/assets/" .. folder
    local full = path .. "/" .. name

    if isfile(full) then
        print("local " .. full .. " found")
        return full
    end

    warn("importing " .. name .. " into " .. path .. " for first time import")
    writefile(full, game:HttpGet(link))
    return full
end

local function gca(name, folder)
    local full = root .. "/assets/" .. folder .. "/" .. name
    if isfile(full) then
        return getcustomasset(full)
    end
end

return {
    import = import,
    gca = gca
}
