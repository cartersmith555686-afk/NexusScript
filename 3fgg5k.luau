--[[
	================================================================
	 NEXUS  ·  client-side tool panel
	================================================================
	 Paste this whole file into your executor and run it.

	   ·  drag the title bar to move the window
	   ·  RIGHT SHIFT shows / hides it
	   ·  Tools   -> launches each source listed in TOOLS below
	   ·  Utility -> native toggles (anti-afk, fullbright, fog)
	   ·  Console -> runs whatever you paste

	 Tool sources move around over time. If one fails, drop a fresh
	 raw.githubusercontent.com link into TOOLS and re-run.
	================================================================
]]

------------------------------------------------------------------
-- services
------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer

------------------------------------------------------------------
-- config
------------------------------------------------------------------
local CONFIG = {
	title = "NEXUS",
	version = "1.0",
	width = 672,
	height = 436,
	toggleKey = Enum.KeyCode.RightShift,
	accent = Color3.fromRGB(126, 142, 255),
	accentAlt = Color3.fromRGB(196, 128, 255),
	useBlur = true,
	useTextures = true,
}

local P = {
	text = Color3.fromRGB(234, 238, 252),
	muted = Color3.fromRGB(138, 147, 178),
	dim = Color3.fromRGB(96, 104, 132),
	good = Color3.fromRGB(112, 228, 172),
	bad = Color3.fromRGB(255, 118, 132),
	warn = Color3.fromRGB(255, 198, 112),
}

local FONT = {
	black = Enum.Font.GothamBlack or Enum.Font.GothamBold or Enum.Font.Gotham,
	bold = Enum.Font.GothamBold or Enum.Font.Gotham,
	med = Enum.Font.GothamMedium or Enum.Font.Gotham,
	reg = Enum.Font.Gotham,
	mono = Enum.Font.Code or Enum.Font.Gotham,
}

------------------------------------------------------------------
-- tool catalogue
------------------------------------------------------------------
local TOOLS = {
	{
		name = "Dex Explorer",
		desc = "Instance tree viewer with a property editor and decompiler.",
		tag = "Explorer",
		accent = Color3.fromRGB(112, 176, 255),
		source = "https://raw.githubusercontent.com/peyton2465/Dex/master/out.lua",
	},
	{
		name = "Hydroxide",
		desc = "Upvalue scanner and remote proxy with a clean object browser.",
		tag = "Explorer",
		accent = Color3.fromRGB(120, 214, 214),
		source = "https://raw.githubusercontent.com/Upbolt/Hydroxide/master/src/init.lua",
	},
	{
		name = "Remote Spy",
		desc = "Live remote traffic logger with argument decompilation.",
		tag = "Spy",
		accent = Color3.fromRGB(196, 140, 255),
		source = "https://raw.githubusercontent.com/exoliner/remotespy/main/RemoteSpy.lua",
	},
	{
		name = "SimpleSpy",
		desc = "Logs fires and invokes, and can replay them with new arguments.",
		tag = "Spy",
		accent = Color3.fromRGB(255, 164, 208),
		source = "https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpySource.lua",
	},
	{
		name = "OctoSpy",
		desc = "Lightweight multi-scope spy for remotes, hooks and methods.",
		tag = "Spy",
		accent = Color3.fromRGB(255, 186, 120),
		source = "https://raw.githubusercontent.com/Chocolaterie/OctoSpy/main/OctoSpy.lua",
	},
	{
		name = "Infinite Yield",
		desc = "The classic admin-style command bar for client-side control.",
		tag = "Hub",
		accent = Color3.fromRGB(150, 240, 150),
		source = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",
	},
}

------------------------------------------------------------------
-- tiny build helpers
------------------------------------------------------------------
local function make(class, props)
	local inst = Instance.new(class)
	local parent = props.Parent
	props.Parent = nil
	for key, value in next, props do
		-- one bad property should never take the whole panel down
		local ok, err = pcall(function()
			inst[key] = value
		end)
		if not ok then
			warn("[Nexus] " .. tostring(class) .. "." .. tostring(key) .. " -> " .. tostring(err))
		end
	end
	inst.Parent = parent
	return inst
end

local function tween(inst, time, props, style, dir)
	local info = TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
	local t = TweenService:Create(inst, info, props)
	t:Play()
	return t
end

local function round(inst, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = inst
	return corner
end

local function outline(inst, color, thickness, transparency)
	local line = Instance.new("UIStroke")
	line.Color = color or Color3.new(1, 1, 1)
	line.Thickness = thickness or 1
	line.Transparency = transparency or 0.86
	line.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	line.Parent = inst
	return line
end

local function attachRipple(button)
	button.ClipsDescendants = true

	button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local inset = GuiService:GetGuiInset()
		local mouse = UserInputService:GetMouseLocation() - inset
		local relative = mouse - button.AbsolutePosition

		local dot = Instance.new("Frame")
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = UDim2.fromOffset(relative.X, relative.Y)
		dot.Size = UDim2.fromOffset(0, 0)
		dot.BackgroundColor3 = Color3.new(1, 1, 1)
		dot.BackgroundTransparency = 0.78
		dot.BorderSizePixel = 0
		dot.ZIndex = button.ZIndex + 1
		dot.Parent = button
		round(dot, 999)

		local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 1.7
		tween(dot, 0.5, {
			Size = UDim2.fromOffset(size, size),
			BackgroundTransparency = 1,
		}, Enum.EasingStyle.Quart)
		task.delay(0.55, function()
			if dot then
				dot:Destroy()
			end
		end)
	end)
end

------------------------------------------------------------------
-- screen gui
------------------------------------------------------------------
local function build()
	if typeof(getgenv) == "function" and getgenv().NexusPanel then
		pcall(function()
			getgenv().NexusPanel:Destroy()
		end)
		getgenv().NexusPanel = nil
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "NexusPanel"
	gui.Enabled = true
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 9999

	local function tryParent(target)
		if not target then
			return false
		end
		local ok = pcall(function()
			gui.Parent = target
		end)
		return ok and gui.Parent ~= nil
	end

	local placed = false

	local okCore, core = pcall(function()
		return game:GetService("CoreGui")
	end)
	if okCore then
		placed = tryParent(core)
	end

	if not placed and typeof(gethui) == "function" then
		local okHui, hui = pcall(gethui)
		if okHui then
			placed = tryParent(hui)
		end
	end

	if not placed then
		placed = tryParent(Player:WaitForChild("PlayerGui"))
	end

	if not placed then
		error("no usable container for the panel")
	end
	if typeof(syn) == "table" and syn.protect_gui then
		pcall(syn.protect_gui, gui)
	end
	if typeof(getgenv) == "function" then
		getgenv().NexusPanel = gui
	end

	-- the blur is only applied at the very end, once the window is proven to
	-- exist, so a failed build can never leave the screen washed out again
	local blur

	------------------------------------------------------------------
	-- notifications
	------------------------------------------------------------------
	local toastHolder = make("Frame", {
		Parent = gui,
		Name = "Toasts",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -18, 0, 18),
		Size = UDim2.fromOffset(300, 420),
		BackgroundTransparency = 1,
		ZIndex = 200,
	})
	make("UIListLayout", {
		Parent = toastHolder,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	})

	local TOAST_COLORS = { good = P.good, bad = P.bad, info = CONFIG.accent, warn = P.warn }
	local toastCount = 0

	local function notify(titleText, bodyText, kind)
		toastCount = toastCount + 1
		local color = TOAST_COLORS[kind] or CONFIG.accent

		local slot = make("Frame", {
			Parent = toastHolder,
			Size = UDim2.fromOffset(300, 62),
			BackgroundTransparency = 1,
			LayoutOrder = toastCount,
		})

		local toast = make("Frame", {
			Parent = slot,
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromOffset(320, 0),
			BackgroundColor3 = Color3.fromRGB(23, 25, 36),
			BackgroundTransparency = 0.05,
			ZIndex = 201,
		})
		round(toast, 12)
		outline(toast, color, 1, 0.72)

		local bar = make("Frame", {
			Parent = toast,
			Position = UDim2.fromOffset(0, 13),
			Size = UDim2.new(0, 3, 1, -26),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			ZIndex = 202,
		})
		round(bar, 2)

		make("TextLabel", {
			Parent = toast,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 11),
			Size = UDim2.new(1, -30, 0, 15),
			Font = FONT.bold,
			Text = titleText,
			TextSize = 13,
			TextColor3 = P.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 203,
		})

		make("TextLabel", {
			Parent = toast,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 29),
			Size = UDim2.new(1, -30, 0, 24),
			Font = FONT.reg,
			Text = bodyText,
			TextSize = 11,
			TextColor3 = P.muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 203,
		})

		local progress = make("Frame", {
			Parent = toast,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 12, 1, -7),
			Size = UDim2.new(1, -24, 0, 2),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			ZIndex = 203,
		})
		round(progress, 2)

		tween(toast, 0.45, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quart)
		tween(progress, 3.4, { Size = UDim2.new(0, 0, 0, 2), BackgroundTransparency = 0.8 }, Enum.EasingStyle.Linear)

		task.delay(3.7, function()
			tween(toast, 0.3, {
				Position = UDim2.fromOffset(320, 0),
				BackgroundTransparency = 1,
			}, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
			task.delay(0.34, function()
				slot:Destroy()
			end)
		end)
	end

	------------------------------------------------------------------
	-- window shell
	------------------------------------------------------------------
	local root = make("CanvasGroup", {
		Parent = gui,
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(CONFIG.width * 0.94, CONFIG.height * 0.94),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Rotation = -3,
		ZIndex = 10,
	})

	-- soft shadow (stacked frames, no assets required)
	for i = 1, 3 do
		local shadow = make("Frame", {
			Parent = root,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, 10 * i, 1, 14 * i),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.9 - i * 0.06,
			BorderSizePixel = 0,
			ZIndex = 1,
		})
		round(shadow, 18 + i * 4)
	end

	local body = make("Frame", {
		Parent = root,
		Name = "Body",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(14, 15, 23),
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 2,
	})
	round(body, 16)
	local bodyStroke = outline(body, Color3.fromRGB(255, 255, 255), 1, 0.86)

	local bodyGradient = make("UIGradient", {
		Parent = body,
		Rotation = 20,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(17, 18, 27)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(23, 25, 40)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 16, 25)),
		}),
	})

	-- drifting accent glows
	local glowA = make("Frame", {
		Parent = body,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.15, 0, 0.1, 0),
		Size = UDim2.fromOffset(340, 340),
		BackgroundColor3 = CONFIG.accent,
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		ZIndex = 2,
	})
	round(glowA, 999)

	local glowB = make("Frame", {
		Parent = body,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.88, 0, 0.92, 0),
		Size = UDim2.fromOffset(300, 300),
		BackgroundColor3 = CONFIG.accentAlt,
		BackgroundTransparency = 0.94,
		BorderSizePixel = 0,
		ZIndex = 2,
	})
	round(glowB, 999)

	TweenService:Create(glowA, TweenInfo.new(9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Position = UDim2.new(0.35, 0, 0.4, 0),
		BackgroundTransparency = 0.9,
	}):Play()

	TweenService:Create(glowB, TweenInfo.new(11, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Position = UDim2.new(0.65, 0, 0.6, 0),
		BackgroundTransparency = 0.9,
	}):Play()

	-- texture layers (built-in client textures, always available)
	local smoke
	if CONFIG.useTextures then
		smoke = make("ImageLabel", {
			Parent = body,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = "rbxasset://textures/particles/smoke_main.dds",
			ImageColor3 = Color3.fromRGB(120, 130, 210),
			ImageTransparency = 0.94,
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim.new(0, 260),
			ZIndex = 3,
		})

		local sparkleTexture = make("ImageLabel", {
			Parent = body,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = "rbxasset://textures/particles/sparkles_main.dds",
			ImageColor3 = Color3.fromRGB(190, 200, 255),
			ImageTransparency = 0.96,
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim.new(0, 210),
			ZIndex = 3,
		})
		sparkleTexture.Name = "Sparkles"
	end

	-- floating dust motes
	for i = 1, 16 do
		local dot = make("Frame", {
			Parent = body,
			Size = UDim2.fromOffset(2, 2),
			Position = UDim2.fromScale(math.random(), math.random()),
			BackgroundColor3 = (i % 2 == 0) and CONFIG.accent or CONFIG.accentAlt,
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			ZIndex = 4,
		})
		round(dot, 3)
		TweenService:Create(dot, TweenInfo.new(
			3 + math.random() * 4,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut,
			-1,
			true
		), {
			Position = UDim2.fromScale(math.random(), math.random()),
			BackgroundTransparency = 0.92,
		}):Play()
	end

	------------------------------------------------------------------
	-- top bar
	------------------------------------------------------------------
	local topbar = make("Frame", {
		Parent = body,
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundTransparency = 1,
		ZIndex = 20,
	})

	local title = make("TextLabel", {
		Parent = topbar,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(20, 0),
		Size = UDim2.new(0, 130, 1, 0),
		Font = FONT.black,
		Text = CONFIG.title,
		TextSize = 19,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 21,
	})
	make("UIGradient", {
		Parent = title,
		Rotation = 12,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(176, 186, 255)),
		}),
	})

	local badge = make("TextLabel", {
		Parent = topbar,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.92,
		Position = UDim2.fromOffset(146, 19),
		Size = UDim2.fromOffset(40, 16),
		Font = FONT.med,
		Text = "v" .. CONFIG.version,
		TextSize = 10,
		TextColor3 = P.muted,
		ZIndex = 21,
	})
	round(badge, 8)
	outline(badge, Color3.new(1, 1, 1), 1, 0.9)

	local function controlButton(glyph, xOffset, size)
		local btn = make("TextButton", {
			Parent = topbar,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, xOffset, 0.5, 0),
			Size = UDim2.fromOffset(size or 26, size or 26),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 1,
			Text = glyph,
			Font = FONT.bold,
			TextSize = (size and 16) or 14,
			TextColor3 = P.muted,
			AutoButtonColor = false,
			ZIndex = 22,
		})
		round(btn, (size or 26) / 2)

		btn.MouseEnter:Connect(function()
			tween(btn, 0.16, { BackgroundTransparency = 0.9, TextColor3 = P.text })
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, 0.16, { BackgroundTransparency = 1, TextColor3 = P.muted })
		end)
		attachRipple(btn)
		return btn
	end

	local btnClose = controlButton("×", -14, 28)
	local btnMin = controlButton("-", -48, 28)
	btnMin.TextSize = 17

	make("Frame", {
		Parent = body,
		Position = UDim2.fromOffset(16, 52),
		Size = UDim2.new(1, -32, 0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		ZIndex = 19,
	})

	------------------------------------------------------------------
	-- lower half (fades out when minimised)
	------------------------------------------------------------------
	local lower = make("CanvasGroup", {
		Parent = body,
		Position = UDim2.fromOffset(0, 52),
		Size = UDim2.new(1, 0, 1, -52),
		BackgroundTransparency = 1,
		ZIndex = 5,
	})

	local sidebar = make("Frame", {
		Parent = lower,
		Size = UDim2.new(0, 170, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 6,
	})

	make("TextLabel", {
		Parent = sidebar,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 14),
		Size = UDim2.new(1, -24, 0, 12),
		Font = FONT.bold,
		Text = "TOOLCHEST",
		TextSize = 9,
		TextColor3 = P.dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 7,
	})

	local tabHolder = make("Frame", {
		Parent = sidebar,
		Position = UDim2.fromOffset(10, 34),
		Size = UDim2.new(1, -20, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 7,
	})
	make("UIListLayout", {
		Parent = tabHolder,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	make("Frame", {
		Parent = lower,
		Position = UDim2.fromOffset(170, 14),
		Size = UDim2.new(0, 1, 1, -28),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		ZIndex = 6,
	})

	local content = make("Frame", {
		Parent = lower,
		Position = UDim2.fromOffset(190, 16),
		Size = UDim2.new(1, -208, 1, -34),
		BackgroundTransparency = 1,
		ZIndex = 6,
	})

	------------------------------------------------------------------
	-- sidebar footer
	------------------------------------------------------------------
	local footer = make("Frame", {
		Parent = sidebar,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundTransparency = 1,
		ZIndex = 7,
	})

	make("Frame", {
		Parent = footer,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -28, 0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		ZIndex = 8,
	})

	local statusDot = make("Frame", {
		Parent = footer,
		Position = UDim2.fromOffset(14, 20),
		Size = UDim2.fromOffset(6, 6),
		BackgroundColor3 = P.good,
		BorderSizePixel = 0,
		ZIndex = 9,
	})
	round(statusDot, 3)
	TweenService:Create(statusDot, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		BackgroundTransparency = 0.8,
	}):Play()

	make("TextLabel", {
		Parent = footer,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(26, 14),
		Size = UDim2.new(1, -34, 0, 16),
		Font = FONT.med,
		Text = "READY",
		TextSize = 10,
		TextColor3 = P.muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 9,
	})

	local fpsLabel = make("TextLabel", {
		Parent = footer,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 14),
		Size = UDim2.new(0, 80, 0, 16),
		Font = FONT.mono,
		Text = "-- FPS",
		TextSize = 10,
		TextColor3 = P.dim,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 9,
	})

	local frames, elapsed = 0, 0
	RunService.RenderStepped:Connect(function(dt)
		frames = frames + 1
		elapsed = elapsed + dt
		if elapsed >= 0.5 then
			fpsLabel.Text = string.format("%d FPS", math.floor(frames / elapsed + 0.5))
			frames, elapsed = 0, 0
		end
	end)

	task.spawn(function()
		while gui.Parent do
			local ok, value = pcall(function()
				return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
			end)
			if ok and typeof(value) == "number" then
				statusDot.BackgroundColor3 = (value < 180) and P.good or P.warn
			end
			task.wait(4)
		end
	end)

	------------------------------------------------------------------
	-- page system
	------------------------------------------------------------------
	local pages = {}
	local tabs = {}
	local activeTab

	local function switchTab(name)
		if activeTab == name then
			return
		end
		activeTab = name

		for tabName, page in next, pages do
			if tabName == name then
				page.Visible = true
				page.GroupTransparency = 1
				page.Position = UDim2.fromOffset(0, 14)
				tween(page, 0.36, {
					GroupTransparency = 0,
					Position = UDim2.fromOffset(0, 0),
				}, Enum.EasingStyle.Quint)
			elseif page.Visible then
				local closing = tween(page, 0.16, {
					GroupTransparency = 1,
					Position = UDim2.fromOffset(0, -10),
				}, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
				closing.Completed:Connect(function()
					if activeTab ~= tabName then
						page.Visible = false
					end
				end)
			end
		end

		for tabName, entry in next, tabs do
			local on = tabName == name
			tween(entry.fill, 0.24, { BackgroundTransparency = on and 0.88 or 1 })
			tween(entry.label, 0.24, { TextColor3 = on and P.text or P.muted })
			tween(entry.bar, 0.3, { Size = UDim2.new(0, 3, 0, on and 18 or 0) }, Enum.EasingStyle.Back)
			tween(entry.chevron, 0.24, { TextTransparency = on and 0.1 or 1 })
		end
	end

	local function makeTab(name, label, order)
		local btn = make("TextButton", {
			Parent = tabHolder,
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = order,
			ZIndex = 8,
		})
		round(btn, 10)

		local fill = make("Frame", {
			Parent = btn,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = CONFIG.accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 8,
		})
		round(fill, 10)
		make("UIGradient", {
			Parent = fill,
			Rotation = 15,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, CONFIG.accent),
				ColorSequenceKeypoint.new(1, CONFIG.accentAlt),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.45),
				NumberSequenceKeypoint.new(1, 0.95),
			}),
		})

		local bar = make("Frame", {
			Parent = btn,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.new(0, 3, 0, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			ZIndex = 11,
		})
		round(bar, 2)

		local text = make("TextLabel", {
			Parent = btn,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 0),
			Size = UDim2.new(1, -32, 1, 0),
			Font = FONT.med,
			Text = label,
			TextSize = 12,
			TextColor3 = P.muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 10,
		})

		local chevron = make("TextLabel", {
			Parent = btn,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(10, 16),
			Font = FONT.bold,
			Text = ">",
			TextSize = 11,
			TextColor3 = Color3.new(1, 1, 1),
			TextTransparency = 1,
			ZIndex = 10,
		})

		btn.MouseEnter:Connect(function()
			if activeTab ~= name then
				tween(fill, 0.18, { BackgroundTransparency = 0.95 })
				tween(text, 0.18, { TextColor3 = P.text })
			end
		end)
		btn.MouseLeave:Connect(function()
			if activeTab ~= name then
				tween(fill, 0.18, { BackgroundTransparency = 1 })
				tween(text, 0.18, { TextColor3 = P.muted })
			end
		end)
		btn.MouseButton1Click:Connect(function()
			switchTab(name)
		end)
		attachRipple(btn)

		tabs[name] = { button = btn, fill = fill, label = text, bar = bar, chevron = chevron }
		return btn
	end

	local function makePage(name, order)
		local page = make("CanvasGroup", {
			Parent = content,
			Name = name .. "Page",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			GroupTransparency = 1,
			Position = UDim2.fromOffset(0, 14),
			Visible = false,
			ZIndex = 7,
		})
		pages[name] = page
		return page
	end

	local function pageHeader(page, heading, sub)
		make("TextLabel", {
			Parent = page,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 24),
			Font = FONT.black,
			Text = heading,
			TextSize = 20,
			TextColor3 = P.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 8,
		})
		make("TextLabel", {
			Parent = page,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 26),
			Size = UDim2.new(1, 0, 0, 16),
			Font = FONT.reg,
			Text = sub,
			TextSize = 11,
			TextColor3 = P.muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 8,
		})
	end

	makeTab("tools", "Tools", 1)
	makeTab("utility", "Utility", 2)
	makeTab("console", "Console", 3)

	------------------------------------------------------------------
	-- tools page
	------------------------------------------------------------------
	local toolsPage = makePage("tools", 1)
	pageHeader(toolsPage, "Tool Library", "one click injects the source, no copy-pasting")

	local searchShell = make("Frame", {
		Parent = toolsPage,
		Position = UDim2.fromOffset(0, 52),
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.95,
		BorderSizePixel = 0,
		ZIndex = 8,
	})
	round(searchShell, 10)
	local searchStroke = outline(searchShell, Color3.new(1, 1, 1), 1, 0.9)

	local searchInput = make("TextBox", {
		Parent = searchShell,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -24, 1, 0),
		Font = FONT.med,
		Text = "",
		PlaceholderText = "Search tools...",
		PlaceholderColor3 = P.dim,
		TextSize = 12,
		TextColor3 = P.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = 9,
	})

	local list = make("ScrollingFrame", {
		Parent = toolsPage,
		Position = UDim2.fromOffset(0, 98),
		Size = UDim2.new(1, 0, 1, -98),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Color3.fromRGB(104, 112, 150),
		ScrollBarImageTransparency = 0.45,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 8,
	})
	make("UIListLayout", {
		Parent = list,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	make("UIPadding", {
		Parent = list,
		PaddingRight = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 10),
	})

	local cards = {}

	local function makeCard(tool, order)
		local card = make("TextButton", {
			Parent = list,
			Size = UDim2.new(1, -6, 0, 64),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.945,
			Text = "",
			AutoButtonColor = false,
			ClipsDescendants = true,
			LayoutOrder = order,
			ZIndex = 9,
		})
		round(card, 12)
		local cardStroke = outline(card, Color3.new(1, 1, 1), 1, 0.9)

		local iconHolder = make("Frame", {
			Parent = card,
			Position = UDim2.fromOffset(12, 12),
			Size = UDim2.fromOffset(40, 40),
			BackgroundColor3 = tool.accent,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			ZIndex = 10,
		})
		round(iconHolder, 11)
		make("UIGradient", {
			Parent = iconHolder,
			Rotation = 35,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, tool.accent),
				ColorSequenceKeypoint.new(1, tool.accent:Lerp(CONFIG.accentAlt, 0.65)),
			}),
		})
		local iconScale = make("UIScale", { Parent = iconHolder, Scale = 1 })

		make("TextLabel", {
			Parent = iconHolder,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Font = FONT.black,
			Text = string.sub(tool.name, 1, 1),
			TextSize = 18,
			TextColor3 = Color3.new(1, 1, 1),
			ZIndex = 11,
		})

		make("TextLabel", {
			Parent = card,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(62, 13),
			Size = UDim2.new(1, -244, 0, 16),
			Font = FONT.bold,
			Text = tool.name,
			TextSize = 13,
			TextColor3 = P.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 10,
		})

		make("TextLabel", {
			Parent = card,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(62, 31),
			Size = UDim2.new(1, -244, 0, 16),
			Font = FONT.reg,
			Text = tool.desc,
			TextSize = 11,
			TextColor3 = P.muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 10,
		})

		local chip = make("TextLabel", {
			Parent = card,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -84, 0.5, 0),
			Size = UDim2.fromOffset(72, 20),
			BackgroundColor3 = tool.accent,
			BackgroundTransparency = 0.87,
			BorderSizePixel = 0,
			Font = FONT.med,
			Text = tool.tag,
			TextSize = 10,
			TextColor3 = tool.accent:Lerp(Color3.new(1, 1, 1), 0.5),
			ZIndex = 10,
		})
		round(chip, 6)

		local pill = make("TextButton", {
			Parent = card,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(64, 28),
			BackgroundColor3 = tool.accent,
			BackgroundTransparency = 0.82,
			Text = "OPEN",
			Font = FONT.bold,
			TextSize = 10,
			TextColor3 = Color3.new(1, 1, 1),
			AutoButtonColor = false,
			ZIndex = 11,
		})
		round(pill, 8)

		local sheen
		local function playSheen()
			if not sheen then
				sheen = make("Frame", {
					Parent = card,
					Size = UDim2.new(0, 80, 1.8, 0),
					Position = UDim2.fromOffset(-100, -20),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 0.94,
					BorderSizePixel = 0,
					Rotation = 18,
					ZIndex = 12,
				})
				make("UIGradient", {
					Parent = sheen,
					Rotation = 0,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(0.5, 0.2),
						NumberSequenceKeypoint.new(1, 1),
					}),
				})
			end
			sheen.Position = UDim2.fromOffset(-110, -20)
			tween(sheen, 0.7, {
				Position = UDim2.fromOffset(card.AbsoluteSize.X + 20, -20),
			}, Enum.EasingStyle.Quart)
		end

		local busy = false
		local function activate()
			if busy then
				return
			end
			busy = true
			pill.Text = "..."

			task.spawn(function()
				while busy do
					tween(pill, 0.35, { BackgroundTransparency = 0.5 })
					task.wait(0.35)
					tween(pill, 0.35, { BackgroundTransparency = 0.82 })
					task.wait(0.35)
				end
			end)

			task.spawn(function()
				local ok, err = pcall(function()
					local source = game:HttpGet(tool.source)
					local chunk = loadstring(source)
					if not chunk then
						error("loadstring returned nil")
					end
					chunk()
				end)

				busy = false
				pill.Text = "OPEN"
				tween(pill, 0.2, { BackgroundTransparency = 0.82 })

				if ok then
					notify(tool.name, "source loaded", "good")
				else
					notify(tool.name .. " failed", tostring(err), "bad")
				end
			end)
		end

		card.MouseEnter:Connect(function()
			tween(card, 0.2, { BackgroundTransparency = 0.9 })
			tween(cardStroke, 0.2, { Transparency = 0.72, Color = tool.accent })
			tween(iconScale, 0.28, { Scale = 1.08 }, Enum.EasingStyle.Back)
			tween(pill, 0.2, { BackgroundTransparency = 0.7 })
			playSheen()
		end)
		card.MouseLeave:Connect(function()
			tween(card, 0.2, { BackgroundTransparency = 0.945 })
			tween(cardStroke, 0.2, { Transparency = 0.9, Color = Color3.new(1, 1, 1) })
			tween(iconScale, 0.28, { Scale = 1 })
			tween(pill, 0.2, { BackgroundTransparency = 0.82 })
		end)
		pill.MouseEnter:Connect(function()
			tween(pill, 0.16, { BackgroundTransparency = 0.55 })
		end)
		pill.MouseLeave:Connect(function()
			tween(pill, 0.16, { BackgroundTransparency = 0.82 })
		end)

		card.MouseButton1Click:Connect(activate)
		pill.MouseButton1Click:Connect(activate)
		attachRipple(card)

		local entry = { frame = card, tool = tool, pill = pill }
		cards[#cards + 1] = entry
		return entry
	end

	for index, tool in ipairs(TOOLS) do
		makeCard(tool, index)
	end

	local emptyLabel = make("TextLabel", {
		Parent = list,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -6, 0, 60),
		Font = FONT.med,
		Text = "nothing matches that search",
		TextSize = 12,
		TextColor3 = P.dim,
		Visible = false,
		ZIndex = 10,
	})
	emptyLabel.LayoutOrder = 99

	searchInput.Focused:Connect(function()
		tween(searchStroke, 0.2, { Transparency = 0.55, Color = CONFIG.accent })
	end)
	searchInput.FocusLost:Connect(function()
		tween(searchStroke, 0.2, { Transparency = 0.9, Color = Color3.new(1, 1, 1) })
	end)

	searchInput:GetPropertyChangedSignal("Text"):Connect(function()
		local query = string.lower(searchInput.Text)
		local shown = 0
		for _, entry in ipairs(cards) do
			local haystack = string.lower(entry.tool.name .. " " .. entry.tool.desc .. " " .. entry.tool.tag)
			local matches = query == "" or string.find(haystack, query, 1, true) ~= nil
			entry.frame.Visible = matches
			if matches then
				shown = shown + 1
			end
		end
		emptyLabel.Visible = shown == 0
	end)

	------------------------------------------------------------------
	-- utility page
	------------------------------------------------------------------
	local utilityPage = makePage("utility", 2)
	pageHeader(utilityPage, "Utility", "native toggles, nothing is downloaded")

	local utilityList = make("ScrollingFrame", {
		Parent = utilityPage,
		Position = UDim2.fromOffset(0, 52),
		Size = UDim2.new(1, 0, 1, -52),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Color3.fromRGB(104, 112, 150),
		ScrollBarImageTransparency = 0.45,
		ZIndex = 8,
	})
	make("UIListLayout", {
		Parent = utilityList,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	make("UIPadding", {
		Parent = utilityList,
		PaddingRight = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 10),
	})

	local function makeToggleRow(label, sub, order, onChange)
		local row = make("Frame", {
			Parent = utilityList,
			Size = UDim2.new(1, -6, 0, 56),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.945,
			BorderSizePixel = 0,
			LayoutOrder = order,
			ZIndex = 9,
		})
		round(row, 12)
		local rowStroke = outline(row, Color3.new(1, 1, 1), 1, 0.9)

		make("TextLabel", {
			Parent = row,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 12),
			Size = UDim2.new(1, -100, 0, 16),
			Font = FONT.bold,
			Text = label,
			TextSize = 12,
			TextColor3 = P.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 10,
		})
		make("TextLabel", {
			Parent = row,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 29),
			Size = UDim2.new(1, -100, 0, 16),
			Font = FONT.reg,
			Text = sub,
			TextSize = 10,
			TextColor3 = P.muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 10,
		})

		local track = make("TextButton", {
			Parent = row,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -16, 0.5, 0),
			Size = UDim2.fromOffset(42, 22),
			BackgroundColor3 = Color3.fromRGB(56, 60, 82),
			Text = "",
			AutoButtonColor = false,
			ZIndex = 10,
		})
		round(track, 11)

		local knob = make("Frame", {
			Parent = track,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 3, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 11,
		})
		round(knob, 8)

		local state = false
		local function setState(value)
			state = value
			tween(knob, 0.26, {
				Position = UDim2.new(0, value and 23 or 3, 0.5, 0),
			}, Enum.EasingStyle.Back)
			tween(track, 0.22, {
				BackgroundColor3 = value and CONFIG.accent or Color3.fromRGB(56, 60, 82),
			})
			tween(rowStroke, 0.22, { Transparency = value and 0.7 or 0.9, Color = value and CONFIG.accent or Color3.new(1, 1, 1) })
			onChange(value)
		end

		track.MouseButton1Click:Connect(function()
			setState(not state)
		end)
		track.MouseEnter:Connect(function()
			tween(track, 0.16, { BackgroundTransparency = 0.1 })
		end)
		track.MouseLeave:Connect(function()
			tween(track, 0.16, { BackgroundTransparency = 0 })
		end)

		return setState
	end

	-- anti afk
	local antiAfkConnection
	makeToggleRow("Anti-AFK", "keeps you in the server while you are away", 1, function(on)
		if on then
			antiAfkConnection = Player.Idled:Connect(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		elseif antiAfkConnection then
			antiAfkConnection:Disconnect()
			antiAfkConnection = nil
		end
	end)

	-- fullbright
	local savedLighting
	makeToggleRow("Fullbright", "flattens lighting so nothing hides in shadows", 2, function(on)
		if on then
			savedLighting = savedLighting or {
				Brightness = Lighting.Brightness,
				ClockTime = Lighting.ClockTime,
				GlobalShadows = Lighting.GlobalShadows,
				Ambient = Lighting.Ambient,
				OutdoorAmbient = Lighting.OutdoorAmbient,
			}
			Lighting.Brightness = 3
			Lighting.ClockTime = 14
			Lighting.GlobalShadows = false
			Lighting.Ambient = Color3.fromRGB(150, 150, 150)
			Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 170)
		elseif savedLighting then
			for key, value in next, savedLighting do
				Lighting[key] = value
			end
			savedLighting = nil
		end
	end)

	-- fog
	local savedFog
	makeToggleRow("No Fog", "clears fog and atmosphere haze", 3, function(on)
		if on then
			savedFog = savedFog or {
				FogEnd = Lighting.FogEnd,
				FogStart = Lighting.FogStart,
				Atmospheres = {},
			}
			Lighting.FogEnd = 100000
			Lighting.FogStart = 0
			for _, child in ipairs(Lighting:GetChildren()) do
				if child:IsA("Atmosphere") then
					savedFog.Atmospheres[child] = { Density = child.Density, Haze = child.Haze }
					child.Density = 0
					child.Haze = 0
				end
			end
		elseif savedFog then
			Lighting.FogEnd = savedFog.FogEnd
			Lighting.FogStart = savedFog.FogStart
			for atmosphere, values in next, savedFog.Atmospheres do
				if atmosphere.Parent then
					atmosphere.Density = values.Density
					atmosphere.Haze = values.Haze
				end
			end
			savedFog = nil
		end
	end)

	------------------------------------------------------------------
	-- console page
	------------------------------------------------------------------
	local consolePage = makePage("console", 3)
	pageHeader(consolePage, "Console", "paste a script and run it in this game")

	local editorShell = make("Frame", {
		Parent = consolePage,
		Position = UDim2.fromOffset(0, 52),
		Size = UDim2.new(1, 0, 1, -108),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.96,
		BorderSizePixel = 0,
		ZIndex = 8,
	})
	round(editorShell, 12)
	local editorStroke = outline(editorShell, Color3.new(1, 1, 1), 1, 0.9)

	local editor = make("TextBox", {
		Parent = editorShell,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.new(1, -24, 1, -20),
		Font = FONT.mono,
		Text = "",
		PlaceholderText = "-- paste a script here, then press RUN",
		PlaceholderColor3 = P.dim,
		TextSize = 12,
		TextColor3 = P.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		MultiLine = true,
		ClearTextOnFocus = false,
		ZIndex = 9,
	})

	local runButton = make("TextButton", {
		Parent = consolePage,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.fromOffset(110, 34),
		BackgroundColor3 = CONFIG.accent,
		BackgroundTransparency = 0.15,
		Text = "RUN",
		Font = FONT.bold,
		TextSize = 11,
		TextColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		ZIndex = 9,
	})
	round(runButton, 10)

	local pasteButton = make("TextButton", {
		Parent = consolePage,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 120, 1, 0),
		Size = UDim2.fromOffset(100, 34),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.93,
		Text = "PASTE",
		Font = FONT.bold,
		TextSize = 11,
		TextColor3 = P.muted,
		AutoButtonColor = false,
		ZIndex = 9,
	})
	round(pasteButton, 10)

	local consoleStatus = make("TextLabel", {
		Parent = consolePage,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, -9),
		Size = UDim2.new(1, -260, 0, 16),
		Font = FONT.reg,
		Text = "",
		TextSize = 11,
		TextColor3 = P.dim,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 9,
	})

	local function setStatus(text, kind)
		consoleStatus.Text = text
		consoleStatus.TextColor3 = (kind == "bad" and P.bad) or (kind == "good" and P.good) or P.dim
	end

	runButton.MouseEnter:Connect(function()
		tween(runButton, 0.16, { BackgroundTransparency = 0 })
	end)
	runButton.MouseLeave:Connect(function()
		tween(runButton, 0.16, { BackgroundTransparency = 0.15 })
	end)
	pasteButton.MouseEnter:Connect(function()
		tween(pasteButton, 0.16, { BackgroundTransparency = 0.88, TextColor3 = P.text })
	end)
	pasteButton.MouseLeave:Connect(function()
		tween(pasteButton, 0.16, { BackgroundTransparency = 0.93, TextColor3 = P.muted })
	end)

	runButton.MouseButton1Click:Connect(function()
		local chunk, compileError = loadstring(editor.Text)
		if not chunk then
			setStatus("compile error", "bad")
			notify("Compile error", tostring(compileError), "bad")
			return
		end
		local ok, runtimeError = pcall(chunk)
		if ok then
			setStatus("ran successfully", "good")
			notify("Script", "finished without errors", "good")
		else
			setStatus("runtime error", "bad")
			notify("Runtime error", tostring(runtimeError), "bad")
		end
	end)

	pasteButton.MouseButton1Click:Connect(function()
		if typeof(getclipboard) == "function" then
			local ok, clip = pcall(getclipboard)
			if ok and typeof(clip) == "string" and #clip > 0 then
				editor.Text = clip
				setStatus("pasted from clipboard", "good")
				return
			end
		end
		setStatus("clipboard unavailable", "bad")
	end)

	attachRipple(runButton)
	attachRipple(pasteButton)

	------------------------------------------------------------------
	-- window behaviour
	------------------------------------------------------------------
	local minimized = false

	local function setMinimized(state)
		minimized = state
		if state then
			tween(lower, 0.26, { GroupTransparency = 1 }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
			tween(root, 0.34, { Size = UDim2.fromOffset(CONFIG.width, 52) }, Enum.EasingStyle.Quart)
			btnMin.Text = "+"
		else
			tween(root, 0.4, { Size = UDim2.fromOffset(CONFIG.width, CONFIG.height) }, Enum.EasingStyle.Back)
			tween(lower, 0.3, { GroupTransparency = 0 }, Enum.EasingStyle.Quart)
			btnMin.Text = "-"
		end
	end

	btnMin.MouseButton1Click:Connect(function()
		setMinimized(not minimized)
	end)

	local function shutdown()
		task.spawn(function()
			tween(root, 0.24, {
				GroupTransparency = 1,
				Size = UDim2.fromOffset(CONFIG.width * 0.94, CONFIG.height * 0.94),
			}, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
			if blur then
				tween(blur, 0.3, { Size = 0 }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
			end
			task.wait(0.34)
			if blur then
				blur:Destroy()
			end
			gui:Destroy()
			if typeof(getgenv) == "function" and getgenv().NexusPanel == gui then
				getgenv().NexusPanel = nil
			end
		end)
	end

	btnClose.MouseButton1Click:Connect(shutdown)

	-- dragging
	local dragging = false
	local dragStart
	local startOffset = Vector2.new(0, 0)

	topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startOffset = Vector2.new(root.Position.X.Offset, root.Position.Y.Offset)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
		local limitX = math.max(60, viewport.X / 2 - 60)
		local limitY = math.max(40, viewport.Y / 2 - 40)

		local nextX = math.clamp(startOffset.X + (input.Position.X - dragStart.X), -limitX, limitX)
		local nextY = math.clamp(startOffset.Y + (input.Position.Y - dragStart.Y), -limitY, limitY)

		root.Position = UDim2.new(0.5, nextX, 0.5, nextY)
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	-- show / hide
	local visible = true
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode ~= CONFIG.toggleKey then
			return
		end
		visible = not visible
		if visible then
			root.Visible = true
			tween(root, 0.24, { GroupTransparency = 0 })
		else
			tween(root, 0.18, { GroupTransparency = 1 })
			task.delay(0.18, function()
				if not visible then
					root.Visible = false
				end
			end)
		end
	end)

	------------------------------------------------------------------
	-- ambient animation loop
	------------------------------------------------------------------
	task.spawn(function()
		local angle = 20
		while gui.Parent do
			angle = (angle + 0.35) % 360
			bodyGradient.Rotation = angle

			if smoke then
				local now = os.clock()
				smoke.ImageRectOffset = Vector2.new((now * 9) % 260, (now * 5) % 260)
			end

			bodyStroke.Transparency = 0.86 + math.sin(os.clock() * 0.8) * 0.04

			task.wait(1 / 30)
		end
	end)

	------------------------------------------------------------------
	-- intro
	------------------------------------------------------------------
	switchTab("tools")

	tween(root, 0.55, {
		GroupTransparency = 0,
		Size = UDim2.fromOffset(CONFIG.width, CONFIG.height),
		Rotation = 0,
	}, Enum.EasingStyle.Quart)

	-- if a tween ever gets swallowed, force the window on screen anyway
	task.delay(1.5, function()
		if not minimized and root.Parent then
			root.GroupTransparency = 0
			root.Rotation = 0
			root.Size = UDim2.fromOffset(CONFIG.width, CONFIG.height)
		end
	end)

	for index, entry in ipairs(cards) do
		local scale = make("UIScale", { Parent = entry.frame, Scale = 0.94 })
		task.delay(0.08 + index * 0.04, function()
			tween(scale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
		end)
	end

	notify("Nexus ready", "right shift hides the panel", "info")

	if CONFIG.useBlur then
		blur = Instance.new("BlurEffect")
		blur.Name = "NexusBlur"
		blur.Size = 0
		blur.Parent = Lighting
		tween(blur, 0.6, { Size = 11 }, Enum.EasingStyle.Quart)
	end
end

------------------------------------------------------------------
-- if the build above fell over, say so instead of failing silently
------------------------------------------------------------------
local built, buildError = pcall(build)

if not built then
	local message = tostring(buildError)
	warn("[Nexus] build failed: " .. message)
	print("[Nexus] build failed: " .. message)

	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("BlurEffect") and child.Name == "NexusBlur" then
			child:Destroy()
		end
	end

	if typeof(getgenv) == "function" and getgenv().NexusPanel then
		pcall(function()
			getgenv().NexusPanel:Destroy()
		end)
		getgenv().NexusPanel = nil
	end

	local errorGui = Instance.new("ScreenGui")
	errorGui.Name = "NexusError"
	errorGui.ResetOnSpawn = false
	errorGui.IgnoreGuiInset = true
	errorGui.DisplayOrder = 10000
	pcall(function()
		errorGui.Parent = Player:WaitForChild("PlayerGui")
	end)

	local frame = make("Frame", {
		Parent = errorGui,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(440, 210),
		BackgroundColor3 = Color3.fromRGB(28, 16, 22),
		BorderSizePixel = 0,
	})
	round(frame, 14)
	outline(frame, Color3.fromRGB(255, 118, 132), 1, 0.5)

	make("TextLabel", {
		Parent = frame,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(20, 18),
		Size = UDim2.new(1, -40, 0, 20),
		Font = FONT.bold,
		Text = "Nexus could not start",
		TextSize = 16,
		TextColor3 = Color3.fromRGB(255, 158, 168),
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	make("TextLabel", {
		Parent = frame,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(20, 46),
		Size = UDim2.new(1, -40, 1, -110),
		Font = FONT.mono,
		Text = message,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(226, 214, 224),
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})

	make("TextLabel", {
		Parent = frame,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 20, 1, -16),
		Size = UDim2.new(1, -40, 0, 18),
		Font = FONT.reg,
		Text = "Screenshot this card and send it back - it names what broke.",
		TextSize = 11,
		TextColor3 = Color3.fromRGB(150, 140, 158),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
end
