local Services = {
	Http = game:GetService("HttpService"),
	Tween = game:GetService("TweenService"),
	Core = game:GetService("CoreGui"),
	RS = game:GetService("ReplicatedStorage"),
	WS = game:GetService("Workspace")
}

local Style = {
	bg = Color3.fromRGB(14,14,18),
	panel = Color3.fromRGB(18,18,22),
	stroke = Color3.fromRGB(38,38,45),
	text = Color3.fromRGB(240,240,245),
	muted = Color3.fromRGB(200,200,210),
	accent = Color3.fromRGB(88,101,242)
}

local function new(c,p)
	local i = Instance.new(c)
	for k,v in pairs(p or {}) do
		if k ~= "Parent" then i[k]=v end
	end
	i.Parent = p and p.Parent
	return i
end

local function tween(o,t,p)
	return Services.Tween:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),p)
end

local function corner(o,r)
	return new("UICorner",{CornerRadius=UDim.new(0,r),Parent=o})
end

local function stroke(o)
	return new("UIStroke",{Color=Style.stroke,Parent=o})
end

local function safeText(obj, text)
	local ok = pcall(function()
		obj.Text = text
	end)
	if not ok then
		obj.Text = "--// file too big to display."
	end
end

local gui = new("ScreenGui",{
	ResetOnSpawn=false,
	IgnoreGuiInset=true,
	ZIndexBehavior=Enum.ZIndexBehavior.Global
})

pcall(function() gui.Parent = Services.Core end)

local main = new("Frame",{
	Size = UDim2.fromOffset(720,430),
	Position = UDim2.fromScale(0.5,0.5),
	AnchorPoint = Vector2.new(0.5,0.5),
	BackgroundColor3 = Style.bg,
	BorderSizePixel = 0,
	Parent = gui
})

corner(main,14)
stroke(main)

local list = new("ScrollingFrame",{
	Size = UDim2.fromOffset(260,360),
	Position = UDim2.fromOffset(20,40),
	BackgroundTransparency = 1,
	ScrollBarThickness = 4,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = main
})

new("UIListLayout",{
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0,6),
	Parent = list
})

new("UIPadding",{
	PaddingTop = UDim.new(0,6),
	PaddingLeft = UDim.new(0,6),
	PaddingRight = UDim.new(0,6),
	Parent = list
})

local search = new("TextBox",{
	Size = UDim2.fromOffset(260,30),
	Position = UDim2.fromOffset(20,10),
	BackgroundColor3 = Color3.fromRGB(20,20,25),
	Text = "",
	PlaceholderText = "search...",
	Font = Enum.Font.Code,
	TextSize = 13,
	TextColor3 = Style.text,
	ClearTextOnFocus = false,
	BorderSizePixel = 0,
	Parent = main
})

corner(search,8)
stroke(search)

local input = new("TextBox",{
	Size = UDim2.fromOffset(420,36),
	Position = UDim2.fromOffset(300,40),
	BackgroundColor3 = Color3.fromRGB(20,20,25),
	Text = "",
	PlaceholderText = "game.workspace.script",
	Font = Enum.Font.Code,
	TextSize = 14,
	TextColor3 = Style.text,
	ClearTextOnFocus = false,
	BorderSizePixel = 0,
	Parent = main
})

corner(input,10)
stroke(input)

local function buttonFX(btn, baseColor)
	local baseSize = btn.Size
	local basePos = btn.Position
	local baseStroke = 0.7

	local hoverTween
	local pressTween

	local strokeInst = Instance.new("UIStroke")
	strokeInst.Color = Style.stroke
	strokeInst.Thickness = baseStroke
	strokeInst.Parent = btn

	local function tweenTo(props, t)
		return Services.Tween:Create(btn, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
	end

	btn.MouseEnter:Connect(function()
		if pressTween then pressTween:Cancel() end

		hoverTween = tweenTo({
			Size = UDim2.new(baseSize.X.Scale, baseSize.X.Offset + 2, baseSize.Y.Scale, baseSize.Y.Offset + 2),
			BackgroundColor3 = baseColor:Lerp(Color3.new(1,1,1), 0.05)
		}, 0.18)

		hoverTween:Play()

		Services.Tween:Create(strokeInst, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Thickness = 1.2
		}):Play()
	end)

	btn.MouseLeave:Connect(function()
		if hoverTween then hoverTween:Cancel() end
		if pressTween then pressTween:Cancel() end

		Services.Tween:Create(btn, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = baseSize,
			BackgroundColor3 = baseColor,
			Position = basePos
		}):Play()

		Services.Tween:Create(strokeInst, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Thickness = baseStroke
		}):Play()
	end)

	btn.MouseButton1Down:Connect(function()
		if hoverTween then hoverTween:Cancel() end

		pressTween = tweenTo({
			Size = UDim2.new(baseSize.X.Scale, baseSize.X.Offset - 2, baseSize.Y.Scale, baseSize.Y.Offset - 2),
			Position = basePos + UDim2.fromOffset(0, 2)
		}, 0.08)

		pressTween:Play()
	end)

	btn.MouseButton1Up:Connect(function()
		if pressTween then pressTween:Cancel() end

		tweenTo({
			Size = baseSize,
			Position = basePos
		}, 0.18):Play()
	end)
end

local function makeBtn(text,y,color)
	local b = new("TextButton",{
		Size = UDim2.fromOffset(135,30),
		Position = UDim2.fromOffset(300,y),
		BackgroundColor3 = color,
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Color3.new(1,1,1),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = main
	})

	corner(b,10)
	return b
end

local btn = makeBtn("decompile",90,Style.accent)
buttonFX(btn, Style.accent)

local copyBtn = makeBtn("copy",130,Color3.fromRGB(60,60,70))
buttonFX(copyBtn, Color3.fromRGB(60,60,70))

local dlBtn = makeBtn("download",170,Color3.fromRGB(60,60,70))
buttonFX(dlBtn, Color3.fromRGB(60,60,70))

local output = new("TextBox",{
	Size = UDim2.fromOffset(420,200),
	Position = UDim2.fromOffset(300,210),
	BackgroundColor3 = Style.panel,
	Text = "",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	MultiLine = true,
	TextEditable = false,
	TextWrapped = true,
	Font = Enum.Font.Code,
	TextSize = 14,
	TextColor3 = Style.muted,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = main
})

corner(output,12)
stroke(output)

local function collect()
	local out = {}

	local lp = game:GetService("Players").LocalPlayer

	local function safeAdd(v)
		if v:IsA("LocalScript") or v:IsA("ModuleScript") then
			table.insert(out, v)
		end
	end

	if lp then
		local ps = lp:FindFirstChild("PlayerScripts")
		local pg = lp:FindFirstChild("PlayerGui")

		if ps then
			for _,v in ipairs(ps:GetDescendants()) do
				safeAdd(v)
			end
		end

		if pg then
			for _,v in ipairs(pg:GetDescendants()) do
				safeAdd(v)
			end
		end
	end

	for _,v in ipairs(workspace:GetDescendants()) do
		if not v:IsDescendantOf(game:GetService("CoreGui")) then
			safeAdd(v)
		end
	end

	for _,v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
		safeAdd(v)
	end

	local filtered = {}

	for _,v in ipairs(out) do
		local path = v:GetFullName():lower()

		if not string.find(path, "__index")
		and not string.find(path, "corepackages")
		and not string.find(path, "packages")
		and not string.find(path, "robloxscriptsecurity")
		and not string.find(path, "coregui") then
			table.insert(filtered, v)
		end
	end

	return filtered
end

local modules = collect()

local current = ""

local function add(m)
	local b = new("TextButton",{
		Size = UDim2.new(1,0,0,26),
		BackgroundTransparency = 1,
		Text = m:GetFullName(),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Code,
		TextSize = 13,
		TextColor3 = Style.text,
		Parent = list,
		TextTransparency = 1
	})

	b.Position = b.Position + UDim2.fromOffset(0,6)

	b.MouseButton1Click:Connect(function()
		input.Text = "game."..m:GetFullName()
	end)

	tween(b,0.18,{TextTransparency=0,Position=b.Position-UDim2.fromOffset(0,6)}):Play()
end

for _,v in ipairs(modules) do
	add(v)
	task.wait()
end

local function getGameName()
	local ok, info = pcall(function()
		return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
	end)
	if ok and info and info.Name then
		return info.Name
	end
	return "unknown game"
end

local function buildWatermark(scriptName, scriptPath)
	local now = os.date("*t")
	local timeStr = string.format("%02d:%02d:%02d", now.hour, now.min, now.sec)
	local dateStr = string.format("%04d-%02d-%02d", now.year, now.month, now.day)

	return table.concat({
		"--[[",
		"game: " .. getGameName(),
		"at: " .. timeStr,
		"date: " .. dateStr,
		"script: " .. scriptName,
		"path: " .. scriptPath,
		"]]",
		""
	}, "\n")
end

local function processOutput(str, scriptInst)
	str = str:gsub("%-%- https://lua%.expert%/", "")

	local lines = {}
	for l in str:gmatch("[^\n]*") do
		table.insert(lines, l)
	end

	local chunks = {}
	for i = 1, #lines, 600 do
		table.insert(chunks, table.concat(lines, "\n", i, math.min(i + 599, #lines)))
	end

	local scriptName = scriptInst and scriptInst.Name or "output"
	local scriptPath = scriptInst and scriptInst:GetFullName() or "unknown"

	local final = {}

	for i, chunk in ipairs(chunks) do
		table.insert(final, buildWatermark(scriptName, scriptPath))
		table.insert(final, chunk)
		if i ~= #chunks then
			table.insert(final, "--// break;")
		end
	end

	return table.concat(final, "\n")
end
	
btn.MouseButton1Click:Connect(function()
	local ok,inst = pcall(function()
		return loadstring("return "..input.Text)()
	end)

	if not ok then
		safeText(output,"--// invalid")
		return
	end

	local s,r = pcall(function()
		local b = getscriptbytecode(inst)
		local e = crypt.base64.encode(b)

		local res = request({
			Url="https://api.lua.expert/decompile",
			Method="POST",
			Headers={["Content-Type"]="application/json"},
			Body=Services.Http:JSONEncode({script=e})
		})

		local raw = tostring(res.Body)
		return processOutput(raw, inst)
	end)

	if s then
		current = r
		safeText(output,r)
	else
		safeText(output,"--// failed")
	end
end)

copyBtn.MouseButton1Click:Connect(function()
	if setclipboard and current ~= "" then
		setclipboard(current)
	end
end)

dlBtn.MouseButton1Click:Connect(function()
	dlBtn.Text = "..."
	if current == "" then return end
	if not isfolder("decompiler") then makefolder("decompiler") end
	local name = os.date("%Y-%m-%d_%H-%M-%S")
	writefile("decompiler/"..name..".lua", current)
	dlBtn.Text = "download"
end)
