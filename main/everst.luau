local safe_ref = typeof(cloneref) == 'function' and cloneref or function(instance)
	return instance
end

local players = safe_ref(game:GetService('Players'))
local user_input_service = safe_ref(game:GetService('UserInputService'))
local tween_service = safe_ref(game:GetService('TweenService'))
local text_service = safe_ref(game:GetService('TextService'))
local http_service = safe_ref(game:GetService('HttpService'))
local core_gui = safe_ref(game:GetService('CoreGui'))

local http_request = (syn and syn.request) or (http and http.request) or http_request or request
local get_asset = getcustomasset or getsynasset

local clamp = math.clamp
local floor = math.floor
local max = math.max
local min = math.min

local DEFAULT_WIDTH = 720
local DEFAULT_HEIGHT = 480
local MIN_WIDTH = 560
local MIN_HEIGHT = 380
local MAX_WIDTH = 1100
local MAX_HEIGHT = 780

local SIDEBAR_EXPANDED = 168
local SIDEBAR_COLLAPSED = 58
local HEADER_HEIGHT = 52
local FOOTER_HEIGHT = 54
local RADIUS = 10

local ROOT_FOLDER = 'Everst'
local CONFIG_FOLDER = 'Everst/configs'
local BG_FOLDER = 'Everst/backgrounds'
local BG_STORE_PATH = 'Everst/backgrounds/saved.json'
local USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36'

local FONT_FAMILY = 'rbxasset://fonts/families/GothamSSm.json'

local THEME = {
	root = Color3.fromRGB(16, 16, 16),
	sidebar = Color3.fromRGB(20, 20, 20),
	group = Color3.fromRGB(23, 23, 23),
	element = Color3.fromRGB(36, 36, 36),
	element_hover = Color3.fromRGB(48, 48, 48),
	element_press = Color3.fromRGB(66, 66, 66),
	stroke = Color3.fromRGB(38, 38, 38),
	stroke_active = Color3.fromRGB(120, 120, 120),
	text = Color3.fromRGB(255, 255, 255),
	text_sub = Color3.fromRGB(180, 180, 180),
	text_dim = Color3.fromRGB(110, 110, 110),
	accent = Color3.fromRGB(255, 255, 255),
	success = Color3.fromRGB(96, 214, 130),
	warning = Color3.fromRGB(240, 190, 80),
	error = Color3.fromRGB(240, 96, 96),
}

local function get_interface_parent()
	if typeof(gethui) == 'function' then
		local ok, result = pcall(gethui)
		if ok and result then
			return result
		end
	end

	local core_ok = pcall(function()
		return core_gui.Name
	end)

	if core_ok then
		return core_gui
	end

	local local_player = players.LocalPlayer
	if local_player then
		return local_player:WaitForChild('PlayerGui')
	end

	return core_gui
end

local interface_parent = get_interface_parent()
local old_interface = interface_parent:FindFirstChild('_everst')
if old_interface then
	old_interface:Destroy()
end

local library = {}
library.__index = library

local function tween(instance, duration, properties, style, direction)
	local object = tween_service:Create(
		instance,
		TweenInfo.new(duration, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
		properties
	)
	object:Play()
	return object
end

local function create(class_name, properties)
	local instance = Instance.new(class_name)
	local parent = nil

	for property, value in properties do
		if property == 'Parent' then
			parent = value
		else
			instance[property] = value
		end
	end

	instance.Parent = parent
	return instance
end

local function corner(instance, radius)
	return create('UICorner', {
		CornerRadius = UDim.new(0, radius),
		Parent = instance,
	})
end

local function pill(instance)
	return create('UICorner', {
		CornerRadius = UDim.new(1, 0),
		Parent = instance,
	})
end

local function stroke(instance, color, thickness)
	return create('UIStroke', {
		Color = color or THEME.stroke,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = instance,
	})
end

local function refresh_stroke_on_resize(instance, ui_stroke)
	instance:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
		ui_stroke.Enabled = false
		ui_stroke.Enabled = true
	end)
end

local function padding(instance, top, bottom, left, right)
	return create('UIPadding', {
		PaddingTop = UDim.new(0, top),
		PaddingBottom = UDim.new(0, bottom),
		PaddingLeft = UDim.new(0, left),
		PaddingRight = UDim.new(0, right),
		Parent = instance,
	})
end

local function vertical_list(instance, gap)
	return create('UIListLayout', {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, gap or 0),
		Parent = instance,
	})
end

local function font(weight)
	return Font.new(FONT_FAMILY, weight or Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
end

local function text_label(properties)
	properties.BackgroundTransparency = 1
	properties.BorderSizePixel = 0
	properties.FontFace = properties.FontFace or font()
	properties.TextColor3 = properties.TextColor3 or THEME.text_sub
	return create('TextLabel', properties)
end

local function divider(parent, position, size, z_index)
	return create('Frame', {
		BackgroundColor3 = THEME.stroke,
		Position = position,
		Size = size,
		BorderSizePixel = 0,
		ZIndex = z_index or 1,
		Parent = parent,
	})
end

local function create_grip(parent, position, anchor_point, z_index)
	local grip = create('TextButton', {
		BackgroundTransparency = 1,
		AnchorPoint = anchor_point or Vector2.new(1, 0.5),
		Position = position or UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(18, 16),
		Text = '',
		AutoButtonColor = false,
		BorderSizePixel = 0,
		ZIndex = z_index or 4,
		Parent = parent,
	})

	local bars = {}

	for index = 1, 3 do
		local bar = create('Frame', {
			BackgroundColor3 = THEME.text_dim,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 3 + (index - 1) * 4, 0.5, 0),
			Size = UDim2.fromOffset(2, 10),
			BorderSizePixel = 0,
			ZIndex = (z_index or 4) + 1,
			Parent = grip,
		})
		pill(bar)
		table.insert(bars, bar)
	end

	local function set_color(color)
		for _, bar in bars do
			tween(bar, 0.15, { BackgroundColor3 = color })
		end
	end

	grip.MouseEnter:Connect(function()
		set_color(THEME.text_sub)
	end)

	return grip, set_color
end

local function normalize_name(value)
	local normalized = string.lower(tostring(value or ''))
	return (normalized:match('^%s*(.-)%s*$'))
end

local function shallow_copy(source)
	local copy = {}
	for index, value in source or {} do
		copy[index] = value
	end
	return copy
end

local function key_from_name(name)
	if type(name) ~= 'string' then
		return nil
	end

	local ok, result = pcall(function()
		return Enum.KeyCode[name]
	end)

	if ok then
		return result
	end

	return nil
end

local function knob_color_for(accent)
	local luminance = accent.R * 0.299 + accent.G * 0.587 + accent.B * 0.114
	return luminance > 0.55 and Color3.fromRGB(18, 18, 18) or Color3.fromRGB(255, 255, 255)
end

local function decimals_of(step)
	local fraction = tostring(step):match('%.(%d+)')
	return fraction and #fraction or 0
end

local function snap(value, step)
	local snapped = floor(value / step + 0.5) * step
	return tonumber(string.format('%.' .. decimals_of(step) .. 'f', snapped))
end

local function ensure_folder(path)
	if typeof(makefolder) ~= 'function' then
		return false
	end

	if typeof(isfolder) == 'function' then
		local ok, exists = pcall(isfolder, path)
		if ok and exists then
			return true
		end
	end

	return pcall(makefolder, path)
end

local function file_exists(path)
	if typeof(isfile) ~= 'function' then
		return false
	end

	local ok, result = pcall(isfile, path)
	return ok and result == true
end

local function hash_string(value)
	local hash = 5381
	for index = 1, #value do
		hash = (hash * 33 + string.byte(value, index)) % 4294967296
	end
	return string.format('%08x', hash)
end

local function detect_image_kind(data)
	if type(data) ~= 'string' or #data < 4 then
		return nil
	end

	if string.sub(data, 1, 4) == '\137PNG' then
		return 'png'
	end

	if string.byte(data, 1) == 0xFF and string.byte(data, 2) == 0xD8 and string.byte(data, 3) == 0xFF then
		return 'jpg'
	end

	if string.sub(data, 1, 3) == 'GIF' then
		return 'gif'
	end

	return nil
end

local function download_bytes(url)
	if http_request then
		local ok, response = pcall(http_request, {
			Url = url,
			Method = 'GET',
			Headers = {
				['User-Agent'] = USER_AGENT,
				['Accept'] = 'image/png,image/jpeg,image/*;q=0.8,*/*;q=0.5',
			},
		})

		if ok and type(response) == 'table' then
			local body = response.Body or response.body
			local code = tonumber(response.StatusCode or response.Status or response.status_code)
			if type(body) == 'string' and (code == nil or (code >= 200 and code < 300)) then
				return body
			end
		end
	end

	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)

	if ok and type(body) == 'string' and #body > 0 then
		return body
	end

	error('download failed', 0)
end

function library._connect(self, signal, callback)
	local connection = signal:Connect(callback)
	table.insert(self._connections, connection)
	return connection
end

function library.close_all_dropdowns(self)
	for _, dropdown in self._active_dropdowns do
		if dropdown._open then
			dropdown:unfold(false)
		end
	end
end

function library._save(self)
	if not self._autosave then
		return
	end

	self._save_token += 1
	local token = self._save_token

	task.delay(1, function()
		if token == self._save_token then
			self:save_config('autosave', true)
		end
	end)
end

function library.get_flag(self, flag)
	return self._flags[flag]
end

function library.set_flag(self, flag, value)
	local setter = self._setters[flag]
	if setter then
		setter(value)
	else
		self._flags[flag] = value
	end
end

function library.save_config(self, name, silent)
	local clean = tostring(name or ''):gsub('[^%w_%- ]', ''):match('^%s*(.-)%s*$')

	if clean == '' then
		if not silent then
			self:notify('Enter a valid config name', 'warning')
		end
		return false
	end

	if typeof(writefile) ~= 'function' then
		if not silent then
			self:notify('Executor does not support writefile', 'error')
		end
		return false
	end

	ensure_folder(ROOT_FOLDER)
	ensure_folder(CONFIG_FOLDER)

	local ok = pcall(function()
		writefile(CONFIG_FOLDER .. '/' .. clean .. '.json', http_service:JSONEncode(self._flags))
	end)

	if not silent then
		self:notify(ok and ('Config saved: ' .. clean) or 'Failed to save config', ok and 'success' or 'error')
	end

	return ok
end

function library.load_config(self, name, silent)
	local clean = tostring(name or ''):match('^%s*(.-)%s*$')
	local path = CONFIG_FOLDER .. '/' .. clean .. '.json'

	if clean == '' or not file_exists(path) then
		if not silent then
			self:notify('Config not found', 'warning')
		end
		return false
	end

	local ok, decoded = pcall(function()
		return http_service:JSONDecode(readfile(path))
	end)

	if not ok or type(decoded) ~= 'table' then
		if not silent then
			self:notify('Config file is corrupted', 'error')
		end
		return false
	end

	for flag, value in decoded do
		local setter = self._setters[flag]
		if setter then
			pcall(setter, value)
		else
			self._flags[flag] = value
		end
	end

	if not silent then
		self:notify('Config loaded: ' .. clean, 'success')
	end

	return true
end

function library.list_configs(self)
	local names = {}

	if typeof(listfiles) ~= 'function' then
		return names
	end

	ensure_folder(ROOT_FOLDER)
	ensure_folder(CONFIG_FOLDER)

	local ok, files = pcall(listfiles, CONFIG_FOLDER)
	if not ok or type(files) ~= 'table' then
		return names
	end

	for _, path in files do
		local name = tostring(path):match('([^/\\]+)%.json$')
		if name then
			table.insert(names, name)
		end
	end

	table.sort(names)
	return names
end

function library.delete_config(self, name)
	local path = CONFIG_FOLDER .. '/' .. tostring(name or '') .. '.json'

	if file_exists(path) and typeof(delfile) == 'function' then
		pcall(delfile, path)
		self:notify('Config deleted: ' .. tostring(name), 'success')
		return true
	end

	self:notify('Config not found', 'warning')
	return false
end

function library.new(options)
	options = options or {}

	local is_mobile = user_input_service.TouchEnabled
		and not (user_input_service.KeyboardEnabled and user_input_service.MouseEnabled)

	local size = options.size

	local self = setmetatable({
		_title = options.title or 'Everst',
		_subtitle = options.subtitle or 'v1.0',
		_accent = options.accent or THEME.accent,
		_autosave = options.autosave == true,
		_save_token = 0,
		_connections = {},
		_flags = {},
		_setters = {},
		_tabs = {},
		_tab_registry = {},
		_categories = {},
		_category_registry = {},
		_category_order = 0,
		_loose_tabs = 0,
		_active_tab = nil,
		_active_dropdowns = {},
		_keybind_entries = {},
		_keybind_list_visible = false,
		_is_mobile = is_mobile,
		_ui_scale = 1,
		_width = size and size.X or DEFAULT_WIDTH,
		_height = size and size.Y or DEFAULT_HEIGHT,
		_label_text_size = is_mobile and 15 or 14,
		_small_text_size = is_mobile and 12 or 11,
		_sidebar_collapsed = false,
		_ui_open = true,
		_visibility_token = 0,
		_dragging = false,
		_resizing = false,
		_group_dragging = false,
		_slider_dragging = false,
		_notification_order = 0,
		_bg_active = false,
		_bg_dim_amount = 55,
		_bg_surfaces = {},
		_bg_token = 0,
		_bg_store = { active = nil, items = {} },
	}, library)

	if self._autosave and file_exists(CONFIG_FOLDER .. '/autosave.json') then
		local ok, decoded = pcall(function()
			return http_service:JSONDecode(readfile(CONFIG_FOLDER .. '/autosave.json'))
		end)
		if ok and type(decoded) == 'table' then
			self._flags = decoded
		end
	end

	self:_build()
	self:_build_keybind_list()
	self:_load_background_store()

	if self._apply_scale then
		self._apply_scale()
	end

	library.current = self
	return self
end

library._new = library.new

function library._build(self)
	if typeof(set_thread_identity) == 'function' then
		pcall(set_thread_identity, 6)
	end

	local gui = create('ScreenGui', {
		Name = '_everst',
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 100,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = interface_parent,
	})

	if syn and syn.protect_gui then
		pcall(syn.protect_gui, gui)
	end

	self._ui = gui

	local container = create('Frame', {
		Name = '_window',
		BackgroundColor3 = THEME.root,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 0),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Active = true,
		Parent = gui,
	})

	corner(container, RADIUS)
	refresh_stroke_on_resize(container, stroke(container))

	local ui_scale = create('UIScale', { Parent = container })
	self._ui_scale_object = ui_scale

	local bg_holder = create('Frame', {
		Name = '_background',
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		ZIndex = 0,
		Parent = container,
	})
	corner(bg_holder, RADIUS)

	local bg_dim = create('Frame', {
		Name = '_background_dim',
		BackgroundColor3 = Color3.fromRGB(12, 12, 12),
		BackgroundTransparency = 1 - (self._bg_dim_amount / 100),
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 1,
		Parent = container,
	})
	corner(bg_dim, RADIUS)

	self._bg_holder = bg_holder
	self._bg_dim = bg_dim

	tween(container, 0.5, { Size = UDim2.fromOffset(self._width, self._height) })

	local notification_holder = create('Frame', {
		Name = '_notifications',
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.fromOffset(560, 220),
		ZIndex = 199,
		Parent = gui,
	})

	create('UIListLayout', {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = notification_holder,
	})

	self._notification_scale = create('UIScale', { Parent = notification_holder })
	self._notification_holder = notification_holder

	self._apply_scale = function()
		if self._is_mobile then
			local camera = workspace.CurrentCamera
			local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)

			if gui.AbsoluteSize.Y > 0 then
				viewport = gui.AbsoluteSize
			end

			self._ui_scale = clamp(
				min((viewport.X / 1400) * 1.35, (viewport.X * 0.94) / self._width, (viewport.Y * 0.92) / self._height),
				0.5,
				1.35
			)
		else
			self._ui_scale = 1
		end

		ui_scale.Scale = self._ui_scale
		self._notification_scale.Scale = self._ui_scale

		if self._keybind_scale then
			self._keybind_scale.Scale = self._ui_scale
		end
	end

	self._apply_scale()

	if workspace.CurrentCamera then
		self:_connect(workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'), function()
			task.defer(self._apply_scale)
		end)
	end

	local mobile_toggle = create('TextButton', {
		BackgroundColor3 = THEME.sidebar,
		Position = UDim2.fromOffset(18, 54),
		Size = UDim2.fromOffset(44, 44),
		Text = '',
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Visible = self._is_mobile,
		ZIndex = 100,
		Parent = gui,
	})

	pill(mobile_toggle)
	stroke(mobile_toggle)

	text_label({
		Size = UDim2.fromScale(1, 1),
		Text = 'E',
		TextColor3 = THEME.text,
		TextSize = 17,
		ZIndex = 101,
		Parent = mobile_toggle,
	})

	local sidebar_clip = create('Frame', {
		Name = '_sidebar',
		BackgroundTransparency = 1,
		Size = UDim2.new(0, SIDEBAR_EXPANDED, 1, 0),
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = container,
	})

	local sidebar_fill = create('Frame', {
		Name = '_sidebar_fill',
		BackgroundColor3 = THEME.sidebar,
		Size = UDim2.new(1, RADIUS * 2, 1, 0),
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = sidebar_clip,
	})
	corner(sidebar_fill, RADIUS)

	divider(sidebar_clip, UDim2.new(1, -1, 0, 0), UDim2.new(0, 1, 1, 0), 6)

	local logo_area = create('Frame', {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
		Active = true,
		ZIndex = 3,
		Parent = sidebar_clip,
	})

	local logo_title = text_label({
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.new(1, -64, 1, 0),
		Text = self._title,
		TextColor3 = THEME.text,
		TextSize = self._is_mobile and 19 or 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 4,
		Parent = logo_area,
	})

	local collapse_button = create('TextButton', {
		BackgroundColor3 = THEME.element,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -25, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
		FontFace = font(),
		Text = '«',
		TextColor3 = THEME.text_sub,
		TextSize = 14,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = logo_area,
	})

	corner(collapse_button, 7)
	stroke(collapse_button)

	collapse_button.MouseEnter:Connect(function()
		tween(collapse_button, 0.15, { BackgroundColor3 = THEME.element_hover, TextColor3 = THEME.text })
	end)

	collapse_button.MouseLeave:Connect(function()
		tween(collapse_button, 0.15, { BackgroundColor3 = THEME.element, TextColor3 = THEME.text_sub })
	end)

	divider(logo_area, UDim2.new(0, 12, 1, -1), UDim2.new(1, -24, 0, 1), 4)

	local tabs_container = create('ScrollingFrame', {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, HEADER_HEIGHT),
		Size = UDim2.new(1, 0, 1, -(HEADER_HEIGHT + FOOTER_HEIGHT)),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollBarImageTransparency = 1,
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
		ClipsDescendants = true,
		ZIndex = 3,
		Parent = sidebar_clip,
	})

	padding(tabs_container, 4, 12, 10, 10)
	vertical_list(tabs_container, 4)

	local footer = create('Frame', {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 1, -FOOTER_HEIGHT),
		Size = UDim2.new(1, 0, 0, FOOTER_HEIGHT),
		ZIndex = 3,
		Parent = sidebar_clip,
	})

	divider(footer, UDim2.new(0, 12, 0, 0), UDim2.new(1, -24, 0, 1), 4)

	local avatar = create('ImageLabel', {
		BackgroundColor3 = THEME.element,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 29, 0.5, 0),
		Size = UDim2.fromOffset(30, 30),
		BorderSizePixel = 0,
		Image = '',
		ZIndex = 4,
		Parent = footer,
	})

	pill(avatar)
	stroke(avatar)

	local local_player = players.LocalPlayer

	if local_player then
		task.spawn(function()
			local ok, image = pcall(function()
				return players:GetUserThumbnailAsync(
					local_player.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size48x48
				)
			end)
			if ok and image and avatar.Parent then
				avatar.Image = image
			end
		end)
	end

	local footer_text = create('Frame', {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(52, 0),
		Size = UDim2.new(1, -60, 1, 0),
		ZIndex = 4,
		Parent = footer,
	})

	text_label({
		Position = UDim2.new(0, 0, 0.5, -15),
		Size = UDim2.new(1, 0, 0, 16),
		Text = local_player and local_player.DisplayName or 'Player',
		TextColor3 = THEME.text,
		TextSize = self._label_text_size,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 5,
		Parent = footer_text,
	})

	text_label({
		Position = UDim2.new(0, 0, 0.5, 2),
		Size = UDim2.new(1, 0, 0, 14),
		Text = self._subtitle,
		TextColor3 = THEME.text_dim,
		TextSize = self._small_text_size,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 5,
		Parent = footer_text,
	})

	local main_content = create('Frame', {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(SIDEBAR_EXPANDED, 0),
		Size = UDim2.new(1, -SIDEBAR_EXPANDED, 1, 0),
		ZIndex = 2,
		Parent = container,
	})

	local topbar = create('Frame', {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
		Active = true,
		ZIndex = 5,
		Parent = main_content,
	})

	local topbar_title = text_label({
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.new(1, -110, 1, 0),
		Text = '',
		RichText = true,
		TextColor3 = THEME.text,
		TextSize = self._label_text_size + 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
		Parent = topbar,
	})

	local close_button = create('TextButton', {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
		FontFace = font(),
		Text = '×',
		TextColor3 = THEME.text_dim,
		TextSize = 22,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		ZIndex = 7,
		Parent = topbar,
	})

	close_button.MouseEnter:Connect(function()
		tween(close_button, 0.15, { TextColor3 = THEME.error })
	end)

	close_button.MouseLeave:Connect(function()
		tween(close_button, 0.15, { TextColor3 = THEME.text_dim })
	end)

	close_button.MouseButton1Click:Connect(function()
		self:change_visibility(false)
	end)

	local topbar_grip, set_topbar_grip_color =
		create_grip(topbar, UDim2.new(1, -46, 0.5, 0), Vector2.new(1, 0.5), 6)

	divider(topbar, UDim2.new(0, 0, 1, -1), UDim2.new(1, 0, 0, 1), 6)

	local sections_viewport = create('Frame', {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, HEADER_HEIGHT),
		Size = UDim2.new(1, 0, 1, -HEADER_HEIGHT),
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = main_content,
	})

	local sections = create('Folder', { Parent = sections_viewport })

	self._container = container
	self._sidebar_clip = sidebar_clip
	self._sidebar_fill = sidebar_fill
	self._logo_title = logo_title
	self._collapse_button = collapse_button
	self._tabs_container = tabs_container
	self._footer_text = footer_text
	self._avatar = avatar
	self._main_content = main_content
	self._topbar_title = topbar_title
	self._sections_viewport = sections_viewport
	self._sections = sections

	collapse_button.MouseButton1Click:Connect(function()
		self:set_sidebar_collapsed(not self._sidebar_collapsed)
	end)

	local resizer = create('TextButton', {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, 0),
		Size = UDim2.fromOffset(22, 22),
		Text = '',
		AutoButtonColor = false,
		ZIndex = 80,
		Parent = container,
	})

	local resize_dots = {}
	local dot_layout = {
		{ UDim2.new(1, -6, 1, -6), UDim2.fromOffset(6, 2) },
		{ UDim2.new(1, -6, 1, -6), UDim2.fromOffset(2, 6) },
		{ UDim2.new(1, -10, 1, -10), UDim2.fromOffset(2, 2) },
	}

	for _, layout in dot_layout do
		local dot = create('Frame', {
			BackgroundColor3 = THEME.text_dim,
			AnchorPoint = Vector2.new(1, 1),
			Position = layout[1],
			Size = layout[2],
			BorderSizePixel = 0,
			ZIndex = 81,
			Parent = resizer,
		})
		pill(dot)
		table.insert(resize_dots, dot)
	end

	local function set_resizer_color(color)
		for _, dot in resize_dots do
			tween(dot, 0.15, { BackgroundColor3 = color })
		end
	end

	resizer.MouseEnter:Connect(function()
		set_resizer_color(THEME.text_sub)
	end)

	resizer.MouseLeave:Connect(function()
		if not self._resizing then
			set_resizer_color(THEME.text_dim)
		end
	end)

	local resize_start = nil
	local resize_start_w = self._width
	local resize_start_h = self._height
	local resize_start_pos = nil

	resizer.InputBegan:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		self._resizing = true
		self._dragging = false
		resize_start = input.Position
		resize_start_w = self._width
		resize_start_h = self._height
		resize_start_pos = container.Position
		set_resizer_color(THEME.text)
		self:close_all_dropdowns()

		local connection
		connection = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				connection:Disconnect()
				self._resizing = false
				set_resizer_color(THEME.text_dim)
			end
		end)
	end)

	local function begin_window_drag(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		if self._resizing or self._group_dragging or self._slider_dragging then
			return
		end

		self._dragging = true
		self._drag_start = input.Position
		self._container_position = container.Position
		set_topbar_grip_color(THEME.text)
		self:close_all_dropdowns()

		local connection
		connection = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				connection:Disconnect()
				self._dragging = false
				set_topbar_grip_color(THEME.text_dim)
			end
		end)
	end

	topbar.InputBegan:Connect(begin_window_drag)
	topbar_grip.InputBegan:Connect(begin_window_drag)
	logo_area.InputBegan:Connect(begin_window_drag)

	self:_connect(user_input_service.InputChanged, function(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		if self._resizing and resize_start then
			local scale = self._ui_scale
			local dx = (input.Position.X - resize_start.X) / scale
			local dy = (input.Position.Y - resize_start.Y) / scale
			local new_w = clamp(floor(resize_start_w + dx + 0.5), MIN_WIDTH, MAX_WIDTH)
			local new_h = clamp(floor(resize_start_h + dy + 0.5), MIN_HEIGHT, MAX_HEIGHT)

			self._width = new_w
			self._height = new_h
			container.Size = UDim2.fromOffset(new_w, new_h)
			container.Position = UDim2.new(
				resize_start_pos.X.Scale,
				resize_start_pos.X.Offset + (new_w - resize_start_w) * 0.5,
				resize_start_pos.Y.Scale,
				resize_start_pos.Y.Offset + (new_h - resize_start_h) * 0.5
			)
			return
		end

		if self._dragging and self._drag_start then
			local delta = (input.Position - self._drag_start) / self._ui_scale

			tween(container, 0.08, {
				Position = UDim2.new(
					self._container_position.X.Scale,
					self._container_position.X.Offset + delta.X,
					self._container_position.Y.Scale,
					self._container_position.Y.Offset + delta.Y
				),
			}, Enum.EasingStyle.Sine)
		end
	end)

	self:_connect(user_input_service.InputBegan, function(input, processed)
		if processed then
			return
		end

		local key = key_from_name(self._flags.minimize) or Enum.KeyCode.RightShift

		if input.KeyCode == key then
			self:change_visibility(not self._ui_open)
		end
	end)

	mobile_toggle.MouseButton1Click:Connect(function()
		self:change_visibility(not self._ui_open)
	end)
end

function library.set_sidebar_collapsed(self, collapsed)
	self._sidebar_collapsed = collapsed == true
	local state = self._sidebar_collapsed
	local width = state and SIDEBAR_COLLAPSED or SIDEBAR_EXPANDED

	tween(self._sidebar_clip, 0.35, { Size = UDim2.new(0, width, 1, 0) })
	tween(self._main_content, 0.35, {
		Position = UDim2.fromOffset(width, 0),
		Size = UDim2.new(1, -width, 1, 0),
	})

	self._collapse_button.Text = state and '»' or '«'
	tween(self._collapse_button, 0.35, {
		Position = state and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(1, -25, 0.5, 0),
	})

	tween(self._avatar, 0.35, {
		Position = state and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0, 29, 0.5, 0),
	})

	if state then
		self._logo_title.Visible = false
		self._footer_text.Visible = false
	else
		task.delay(0.15, function()
			if not self._sidebar_collapsed then
				self._logo_title.Visible = true
				self._footer_text.Visible = true
			end
		end)
	end

	for _, category in self._categories do
		category:_apply_collapsed(state)
	end

	for _, tab in self._tabs do
		tab._label.Visible = not state
		tween(tab._icon, 0.35, {
			Position = state and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0, 20, 0.5, 0),
		})
	end
end

function library.reset_size(self)
	self._width = DEFAULT_WIDTH
	self._height = DEFAULT_HEIGHT
	self._container.Position = UDim2.fromScale(0.5, 0.5)

	if self._ui_open then
		tween(self._container, 0.35, { Size = UDim2.fromOffset(self._width, self._height) })
	end
end

function library.change_visibility(self, state)
	self._ui_open = state
	self._visibility_token += 1
	local token = self._visibility_token
	local container = self._container

	if state then
		container.Visible = true
		tween(container, 0.4, { Size = UDim2.fromOffset(self._width, self._height) })
	else
		self:close_all_dropdowns()
		local closing = tween(container, 0.3, { Size = UDim2.fromOffset(0, 0) })
		closing.Completed:Once(function()
			if self._visibility_token == token and not self._ui_open then
				container.Visible = false
			end
		end)
	end
end

function library.destroy(self)
	for _, connection in self._connections do
		connection:Disconnect()
	end

	table.clear(self._connections)

	if self._ui then
		self._ui:Destroy()
	end
end

function library.notify(self, message, kind, duration)
	if type(kind) == 'number' then
		duration = kind
		kind = nil
	end

	duration = duration or 3

	local text = (tostring(message or ''):gsub('[\r\n]+', ' '))
	text = text:match('^%s*(.-)%s*$')

	if text == '' or not self._notification_holder then
		return
	end

	local colors = {
		info = self._accent,
		success = THEME.success,
		warning = THEME.warning,
		error = THEME.error,
	}

	local color = colors[kind or 'info'] or self._accent

	local text_width =
		text_service:GetTextSize(text, self._label_text_size, Enum.Font.GothamSemibold, Vector2.new(1000, 34)).X
	local width = clamp(text_width + 50, 120, 520)

	self._notification_order += 1

	local note = create('Frame', {
		Name = '_notification',
		BackgroundColor3 = THEME.sidebar,
		BackgroundTransparency = 1,
		LayoutOrder = self._notification_order,
		Size = UDim2.fromOffset(width - 16, 0),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 200,
		Parent = self._notification_holder,
	})

	corner(note, 8)

	local note_stroke = stroke(note)
	note_stroke.Transparency = 1

	local dot = create('Frame', {
		BackgroundColor3 = color,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.fromOffset(6, 6),
		BorderSizePixel = 0,
		ZIndex = 201,
		Parent = note,
	})

	pill(dot)

	local note_label = text_label({
		Position = UDim2.fromOffset(30, 0),
		Size = UDim2.new(1, -40, 1, 0),
		Text = text,
		TextColor3 = THEME.text,
		TextSize = self._label_text_size,
		TextTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 201,
		Parent = note,
	})

	tween(note, 0.3, { BackgroundTransparency = 0, Size = UDim2.fromOffset(width, 34) })
	tween(note_label, 0.25, { TextTransparency = 0 })
	tween(note_stroke, 0.25, { Transparency = 0 })
	tween(dot, 0.25, { BackgroundTransparency = 0 })

	task.delay(duration, function()
		if not note.Parent then
			return
		end

		tween(note, 0.3, {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(width - 16, 0),
		}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		tween(note_label, 0.2, { TextTransparency = 1 })
		tween(note_stroke, 0.2, { Transparency = 1 })
		tween(dot, 0.2, { BackgroundTransparency = 1 })
	end)

	task.delay(duration + 0.35, function()
		if note.Parent then
			note:Destroy()
		end
	end)
end

function library._refresh_bg_surface(self)
	local active = self._bg_active

	if self._bg_dim then
		self._bg_dim.Visible = active
		self._bg_dim.BackgroundTransparency = 1 - (self._bg_dim_amount / 100)
	end

	if self._sidebar_fill then
		self._sidebar_fill.BackgroundTransparency = active and 0.4 or 0
	end

	for _, surface in self._bg_surfaces do
		if surface.Parent then
			surface.BackgroundTransparency = active and 0.25 or 0
		end
	end
end

function library._stop_bg_playback(self)
	for _, child in self._bg_holder:GetChildren() do
		if child:IsA('ImageLabel') then
			child:Destroy()
		end
	end
end

function library._apply_static_bg(self, image)
	self:_stop_bg_playback()

	local label = create('ImageLabel', {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ScaleType = Enum.ScaleType.Crop,
		Image = image,
		ZIndex = 0,
		Parent = self._bg_holder,
	})

	corner(label, RADIUS)

	self._bg_active = true
	self:_refresh_bg_surface()
end

function library.set_background_dim(self, percent)
	self._bg_dim_amount = clamp(tonumber(percent) or 55, 0, 95)
	self:_refresh_bg_surface()
	self:_save_background_store()
end

function library.clear_background(self, skip_save)
	self._bg_token += 1
	self:_stop_bg_playback()
	self._bg_active = false
	self._bg_store.active = nil
	self:_refresh_bg_surface()

	if not skip_save then
		self:_save_background_store()
	end
end

function library._save_background_store(self)
	if typeof(writefile) ~= 'function' then
		return
	end

	ensure_folder(ROOT_FOLDER)
	ensure_folder(BG_FOLDER)

	pcall(function()
		writefile(
			BG_STORE_PATH,
			http_service:JSONEncode({
				active = self._bg_store.active,
				dim = self._bg_dim_amount,
				items = self._bg_store.items,
			})
		)
	end)
end

function library._get_saved_bg_names(self)
	local names = {}
	for _, item in self._bg_store.items do
		table.insert(names, item.name)
	end
	return names
end

function library._find_saved_bg(self, name)
	local target = normalize_name(name)
	for index, item in self._bg_store.items do
		if normalize_name(item.name) == target then
			return item, index
		end
	end
	return nil, nil
end

function library.apply_saved_background(self, name)
	local item = self:_find_saved_bg(name)

	if not item then
		return false
	end

	if item.kind == 'asset' and item.asset then
		self:_apply_static_bg(item.asset)
	elseif item.file and file_exists(item.file) and get_asset then
		local ok, asset = pcall(get_asset, item.file)
		if not ok or not asset then
			self:notify('Saved background files missing', 'warning')
			return false
		end
		self:_apply_static_bg(asset)
	else
		self:notify('Saved background files missing', 'warning')
		return false
	end

	self._bg_store.active = item.name
	self:_save_background_store()
	return true
end

function library.delete_saved_background(self, name)
	local item, index = self:_find_saved_bg(name)

	if not item then
		return false
	end

	table.remove(self._bg_store.items, index)

	if self._bg_store.active and normalize_name(self._bg_store.active) == normalize_name(item.name) then
		self:clear_background(true)
	end

	if item.file and file_exists(item.file) and typeof(delfile) == 'function' then
		pcall(delfile, item.file)
	end

	self:_save_background_store()
	return true
end

function library._load_background_store(self)
	if typeof(readfile) ~= 'function' or not file_exists(BG_STORE_PATH) then
		return
	end

	local ok, decoded = pcall(function()
		return http_service:JSONDecode(readfile(BG_STORE_PATH))
	end)

	if not ok or type(decoded) ~= 'table' then
		return
	end

	if type(decoded.dim) == 'number' then
		self._bg_dim_amount = clamp(decoded.dim, 0, 95)
	end

	if type(decoded.items) == 'table' then
		for _, item in decoded.items do
			if type(item) == 'table' and type(item.name) == 'string' and type(item.kind) == 'string' then
				table.insert(self._bg_store.items, item)
			end
		end
	end

	if type(decoded.active) == 'string' then
		task.defer(function()
			self:apply_saved_background(decoded.active)
		end)
	end
end

function library.upload_background(self, source, custom_name, progress, on_complete)
	local trimmed = tostring(source or ''):match('^%s*(.-)%s*$')

	local function finish(success, name)
		if progress then
			progress:set_visible(false)
		end
		if on_complete then
			on_complete(success, name)
		end
	end

	if trimmed == '' then
		self:notify('Enter a PNG, JPEG, URL, file path, or asset ID', 'warning')
		return
	end

	self._bg_token += 1
	local token = self._bg_token

	local function unique_name(preferred)
		local base = tostring(preferred or ''):match('^%s*(.-)%s*$')
		if base == '' then
			base = 'background'
		end
		base = base:sub(1, 32)
		local candidate = base
		local suffix = 2
		while self:_find_saved_bg(candidate) do
			candidate = base:sub(1, 26) .. ' (' .. suffix .. ')'
			suffix += 1
		end
		return candidate
	end

	local function derive_name(raw)
		if custom_name and custom_name:match('%S') then
			return unique_name(custom_name)
		end
		local tail = raw:match('([^/\\?#]+)%??[^/\\]*$')
		return unique_name(tail or ('bg_' .. hash_string(raw):sub(1, 6)))
	end

	if trimmed:match('^rbxassetid://%d+$') or trimmed:match('^%d+$') then
		local asset_id = trimmed:match('^%d+$') and ('rbxassetid://' .. trimmed) or trimmed
		local name = unique_name(custom_name and custom_name ~= '' and custom_name or ('asset_' .. asset_id:match('%d+')))

		table.insert(self._bg_store.items, { name = name, kind = 'asset', asset = asset_id, source = trimmed })
		self:_apply_static_bg(asset_id)
		self._bg_store.active = name
		self:_save_background_store()
		self:notify('Background saved: ' .. name, 'success')
		finish(true, name)
		return
	end

	task.spawn(function()
		if progress then
			progress:set_visible(true)
			progress:set(0.15, 'Loading image...')
		end

		local ok, result = pcall(function()
			if typeof(writefile) ~= 'function' or not get_asset then
				error('writefile and getcustomasset are required', 0)
			end

			ensure_folder(ROOT_FOLDER)
			ensure_folder(BG_FOLDER)

			local bytes
			if trimmed:match('^https?://') then
				bytes = download_bytes(trimmed)
			elseif file_exists(trimmed) then
				bytes = readfile(trimmed)
			elseif file_exists(BG_FOLDER .. '/' .. trimmed) then
				bytes = readfile(BG_FOLDER .. '/' .. trimmed)
			else
				error('enter a valid URL, file path, or asset ID', 0)
			end

			if self._bg_token ~= token then
				error('cancelled', 0)
			end

			local kind = detect_image_kind(bytes)

			if kind == 'gif' then
				error('GIF is not supported, use PNG or JPEG', 0)
			end

			if not kind then
				error('file is not a valid PNG or JPEG', 0)
			end

			if progress then
				progress:set(0.7, 'Saving...')
			end

			local path = BG_FOLDER .. '/' .. hash_string(trimmed .. kind) .. (kind == 'png' and '.png' or '.jpg')
			writefile(path, bytes)

			local asset = get_asset(path)
			if not asset then
				error('getcustomasset failed', 0)
			end

			local name
			for _, item in self._bg_store.items do
				if item.file == path then
					name = item.name
					break
				end
			end

			if not name then
				name = derive_name(trimmed)
				table.insert(self._bg_store.items, { name = name, kind = kind, file = path, source = trimmed })
			end

			self:_apply_static_bg(asset)
			self._bg_store.active = name
			self:_save_background_store()
			return name
		end)

		if ok then
			if progress then
				progress:set(1, 'Ready')
			end
			self:notify('Background saved: ' .. result, 'success')
			task.delay(0.8, function()
				finish(true, result)
			end)
		elseif result ~= 'cancelled' then
			self:notify('Upload failed: ' .. tostring(result), 'error')
			finish(false)
		end
	end)
end

function library._build_keybind_list(self)
	local list = create('Frame', {
		Name = '_keybind_list',
		BackgroundColor3 = THEME.sidebar,
		Position = UDim2.new(0, 16, 0.2, 0),
		Size = UDim2.fromOffset(240, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
		Active = true,
		Parent = self._ui,
	})

	self._keybind_scale = create('UIScale', { Scale = self._ui_scale, Parent = list })

	corner(list, 8)
	refresh_stroke_on_resize(list, stroke(list))
	vertical_list(list)

	local header = create('Frame', {
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		Size = UDim2.new(1, 0, 0, 34),
		Parent = list,
	})

	create('ImageLabel', {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		Image = 'rbxassetid://10723416765',
		ImageColor3 = THEME.text,
		Parent = header,
	})

	text_label({
		Position = UDim2.fromOffset(32, 0),
		Size = UDim2.new(1, -60, 1, 0),
		Text = 'Keybinds',
		TextColor3 = THEME.text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	local grip, set_grip_color = create_grip(header, UDim2.new(1, -10, 0.5, 0), Vector2.new(1, 0.5), 4)

	divider(header, UDim2.new(0, 0, 1, -1), UDim2.new(1, 0, 0, 1), 3)

	local content = create('Frame', {
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = list,
	})

	vertical_list(content, 2)
	padding(content, 6, 8, 12, 12)

	self._keybind_list_frame = list
	self._keybind_list_content = content

	local dragging = false
	local drag_start = nil
	local start_position = nil

	local function begin_drag(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		dragging = true
		drag_start = input.Position
		start_position = list.Position
		set_grip_color(THEME.text)

		local connection
		connection = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				connection:Disconnect()
				dragging = false
				set_grip_color(THEME.text_dim)
			end
		end)
	end

	list.InputBegan:Connect(begin_drag)
	grip.InputBegan:Connect(begin_drag)

	self:_connect(user_input_service.InputChanged, function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local delta = (input.Position - drag_start) / self._ui_scale
			tween(list, 0.08, {
				Position = UDim2.new(
					start_position.X.Scale,
					start_position.X.Offset + delta.X,
					start_position.Y.Scale,
					start_position.Y.Offset + delta.Y
				),
			}, Enum.EasingStyle.Sine)
		end
	end)
end

function library.update_keybind_list(self)
	if not self._keybind_list_content then
		return
	end

	for _, child in self._keybind_list_content:GetChildren() do
		if child:IsA('Frame') then
			child:Destroy()
		end
	end

	local has_any = false

	for _, entry in self._keybind_entries do
		if entry.key_name and entry.key_name ~= '' then
			has_any = true

			local row = create('Frame', {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 24),
				Parent = self._keybind_list_content,
			})

			local enabled = self._flags[entry.flag]
			local color = enabled and THEME.text or THEME.text_dim
			local display = '[ ' .. entry.key_name .. ' ]'
			local info_width =
				text_service:GetTextSize(display, 14, Enum.Font.GothamSemibold, Vector2.new(1000, 24)).X + 4

			text_label({
				Size = UDim2.new(1, -(info_width + 10), 1, 0),
				Text = entry.title,
				TextColor3 = color,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			})

			text_label({
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(info_width, 18),
				Text = display,
				TextColor3 = color,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = row,
			})
		end
	end

	self._keybind_list_frame.Visible = self._keybind_list_visible and has_any
end

function library.create_category(self, name)
	self._category_order += 1

	local window = self
	local index = self._category_order
	local is_first = index == 1
	local expanded_height = is_first and 26 or 34

	local holder = create('Frame', {
		Name = name,
		BackgroundTransparency = 1,
		LayoutOrder = index * 1000,
		Size = UDim2.new(1, 0, 0, expanded_height),
		Parent = self._tabs_container,
	})

	local label = text_label({
		Size = UDim2.fromScale(1, 1),
		Text = tostring(name):upper(),
		TextSize = self._small_text_size,
		TextColor3 = THEME.text_dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		Parent = holder,
	})

	padding(label, 0, 6, 10, 0)

	local line = create('Frame', {
		BackgroundColor3 = THEME.stroke,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(20, 1),
		BorderSizePixel = 0,
		Visible = false,
		Parent = holder,
	})

	local manager = { _name = name, _tab_count = 0 }

	function manager:_apply_collapsed(collapsed)
		label.Visible = not collapsed
		line.Visible = collapsed and not is_first
		holder.Size = UDim2.new(1, 0, 0, collapsed and (is_first and 2 or 12) or expanded_height)
	end

	function manager:create_tab(title, icon)
		self._tab_count += 1
		return window:create_tab(title, icon, self._name, index * 1000 + self._tab_count)
	end

	manager:_apply_collapsed(self._sidebar_collapsed)

	table.insert(self._categories, manager)

	local key = normalize_name(name)
	self._category_registry[key] = self._category_registry[key] or {}
	table.insert(self._category_registry[key], manager)

	return manager
end

function library._style_tab(self, tab, active, instant)
	local duration = instant and 0 or 0.35

	tween(tab._btn, duration, { BackgroundTransparency = active and 0 or 1 })
	tween(tab._label, duration, { TextColor3 = active and THEME.text or THEME.text_sub })
	tween(tab._icon, duration, { ImageColor3 = active and THEME.text or THEME.text_sub })
	tween(tab._indicator, duration, {
		Size = UDim2.fromOffset(3, active and 16 or 0),
		BackgroundTransparency = active and 0 or 1,
	})
end

function library._select_tab(self, tab, instant)
	if not tab._enabled then
		return
	end

	self._active_tab = tab
	self:close_all_dropdowns()

	local category = tab._category and (tostring(tab._category) .. '  /  ') or ''
	self._topbar_title.Text = string.format(
		'<font color="rgb(110,110,110)">%s</font>%s',
		category,
		tab._title
	)

	for _, other in self._tabs do
		other._active = other == tab
		self:_style_tab(other, other == tab, instant)
	end

	for _, section in self._sections:GetChildren() do
		section.Visible = section == tab._left or section == tab._right
	end

	if not instant then
		tab._left.Position = UDim2.new(0, 12, 0, 10)
		tab._right.Position = UDim2.new(0.5, 4, 0, 10)
		tween(tab._left, 0.4, { Position = UDim2.new(0, 12, 0, 0) })
		tween(tab._right, 0.4, { Position = UDim2.new(0.5, 4, 0, 0) })
	end
end

function library.create_tab(self, title, icon, category_name, layout_order)
	local window = self

	icon = icon or 'rbxassetid://10709812159'

	if type(icon) == 'number' or (type(icon) == 'string' and icon:match('^%d+$')) then
		icon = 'rbxassetid://' .. tostring(icon)
	end

	if not layout_order then
		self._loose_tabs += 1
		layout_order = self._loose_tabs
	end

	local button = create('TextButton', {
		Name = title,
		BackgroundColor3 = THEME.element,
		BackgroundTransparency = 1,
		LayoutOrder = layout_order,
		Size = UDim2.new(1, 0, 0, 34),
		Text = '',
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Parent = self._tabs_container,
	})

	corner(button, 8)

	local indicator = create('Frame', {
		BackgroundColor3 = self._accent,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 4, 0.5, 0),
		Size = UDim2.fromOffset(3, 0),
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = button,
	})

	pill(indicator)

	local icon_label = create('ImageLabel', {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = self._sidebar_collapsed and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0, 20, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		Image = icon,
		ImageColor3 = THEME.text_sub,
		Parent = button,
	})

	local label = text_label({
		Position = UDim2.fromOffset(38, 0),
		Size = UDim2.new(1, -46, 1, 0),
		Text = title,
		TextSize = self._label_text_size,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Visible = not self._sidebar_collapsed,
		Parent = button,
	})

	local function create_section(position, size)
		local section = create('ScrollingFrame', {
			BackgroundTransparency = 1,
			Position = position,
			Size = size,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70),
			VerticalScrollBarInset = Enum.ScrollBarInset.None,
			ClipsDescendants = true,
			Visible = false,
			Parent = self._sections,
		})

		padding(section, 14, 16, 2, 4)
		vertical_list(section, 12)
		return section
	end

	local left_section = create_section(UDim2.new(0, 12, 0, 0), UDim2.new(0.5, -16, 1, 0))
	local right_section = create_section(UDim2.new(0.5, 4, 0, 0), UDim2.new(0.5, -16, 1, 0))

	local tab = {
		_btn = button,
		_label = label,
		_icon = icon_label,
		_indicator = indicator,
		_left = left_section,
		_right = right_section,
		_active = false,
		_enabled = true,
		_title = title,
		_category = category_name,
	}

	local manager = {
		_data = tab,
		_title = title,
		_groups = {},
		_group_registry = {},
	}

	table.insert(self._tabs, tab)

	local key = normalize_name(title)
	self._tab_registry[key] = self._tab_registry[key] or {}
	table.insert(self._tab_registry[key], manager)

	if #self._tabs == 1 then
		self:_select_tab(tab, true)
	end

	button.MouseButton1Click:Connect(function()
		self:_select_tab(tab)
	end)

	button.MouseEnter:Connect(function()
		if not tab._active and tab._enabled then
			tween(button, 0.2, { BackgroundTransparency = 0.6 })
			tween(label, 0.2, { TextColor3 = Color3.fromRGB(220, 220, 220) })
			tween(icon_label, 0.2, { ImageColor3 = Color3.fromRGB(220, 220, 220) })
		end
	end)

	button.MouseLeave:Connect(function()
		if not tab._active then
			tween(button, 0.2, { BackgroundTransparency = 1 })
			tween(label, 0.2, { TextColor3 = THEME.text_sub })
			tween(icon_label, 0.2, { ImageColor3 = THEME.text_sub })
		end
	end)

	function manager:select()
		window:_select_tab(tab)
	end

	function manager:set_enabled(state)
		tab._enabled = state == true
		button.Active = tab._enabled
		icon_label.ImageTransparency = tab._enabled and 0 or 0.65
		label.TextTransparency = tab._enabled and 0 or 0.65

		if not tab._enabled and window._active_tab == tab then
			for _, candidate in window._tabs do
				if candidate ~= tab and candidate._enabled then
					window:_select_tab(candidate)
					break
				end
			end
		end
	end

	function manager:is_enabled()
		return tab._enabled
	end

	local function sorted_groups(section)
		local groups = {}
		for _, child in section:GetChildren() do
			if child:IsA('Frame') then
				table.insert(groups, child)
			end
		end
		table.sort(groups, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		return groups
	end

	local function normalize_orders(section)
		for index, frame in sorted_groups(section) do
			frame.LayoutOrder = index
		end
	end

	function manager:create_group(group_title, side)
		local values = {}

		if type(group_title) == 'table' then
			values = group_title
		else
			values.title = group_title
			values.side = side
		end

		values.title = values.title or 'Group'
		values.side = values.side == 'right' and 'right' or 'left'

		local parent_section = values.side == 'left' and left_section or right_section

		local group_manager = {
			_title = values.title,
			_side = values.side,
			_order = 0,
		}

		local function next_order()
			group_manager._order += 1
			return group_manager._order
		end

		local group_frame = create('Frame', {
			BackgroundColor3 = THEME.group,
			BackgroundTransparency = window._bg_active and 0.25 or 0,
			LayoutOrder = #sorted_groups(parent_section) + 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Parent = parent_section,
		})

		group_manager._frame = group_frame
		table.insert(window._bg_surfaces, group_frame)

		corner(group_frame, 9)
		local group_outline = stroke(group_frame)
		refresh_stroke_on_resize(group_frame, group_outline)
		padding(group_frame, 12, 13, 12, 12)
		vertical_list(group_frame, 10)

		local header = create('Frame', {
			BackgroundTransparency = 1,
			LayoutOrder = 0,
			Size = UDim2.new(1, 0, 0, 14),
			Parent = group_frame,
		})

		text_label({
			Size = UDim2.new(1, -24, 1, 0),
			Text = tostring(values.title):upper(),
			TextColor3 = THEME.text_dim,
			TextSize = window._small_text_size,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = header,
		})

		local grip, set_grip_color = create_grip(header, UDim2.new(1, 0, 0.5, 0), Vector2.new(1, 0.5), 4)

		local drag_active = false

		local function update_placement(pointer)
			local viewport = window._sections_viewport
			local mid_x = viewport.AbsolutePosition.X + viewport.AbsoluteSize.X * 0.5
			local target = pointer.X < mid_x and left_section or right_section

			if group_frame.Parent ~= target then
				local previous = group_frame.Parent
				group_frame.Parent = target
				group_manager._side = target == left_section and 'left' or 'right'
				if previous then
					normalize_orders(previous)
				end
			end

			local siblings = {}
			for _, child in sorted_groups(target) do
				if child ~= group_frame then
					table.insert(siblings, child)
				end
			end

			local insert_at = 1
			for _, sibling in siblings do
				if pointer.Y > sibling.AbsolutePosition.Y + sibling.AbsoluteSize.Y * 0.5 then
					insert_at += 1
				end
			end

			table.insert(siblings, insert_at, group_frame)

			for index, frame in siblings do
				frame.LayoutOrder = index
			end
		end

		grip.MouseLeave:Connect(function()
			if not drag_active then
				set_grip_color(THEME.text_dim)
			end
		end)

		grip.InputBegan:Connect(function(input)
			if
				input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			drag_active = true
			window._group_dragging = true
			set_grip_color(THEME.text)
			tween(group_outline, 0.15, { Color = THEME.stroke_active })

			local move_connection = user_input_service.InputChanged:Connect(function(move)
				if
					drag_active
					and (
						move.UserInputType == Enum.UserInputType.MouseMovement
						or move.UserInputType == Enum.UserInputType.Touch
					)
				then
					update_placement(move.Position)
				end
			end)

			local end_connection
			end_connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					drag_active = false
					window._group_dragging = false
					set_grip_color(THEME.text_dim)
					tween(group_outline, 0.2, { Color = THEME.stroke })
					move_connection:Disconnect()
					end_connection:Disconnect()
				end
			end)
		end)

		local function register(flag, setter)
			if flag then
				window._setters[flag] = setter
			end
		end

		function group_manager:create_label(text, label_values)
			if type(text) == 'table' then
				label_values = text
				text = label_values.title or label_values.text
			end

			label_values = label_values or {}

			local frame = create('Frame', {
				BackgroundTransparency = 1,
				LayoutOrder = next_order(),
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				Parent = group_frame,
			})

			local label_object = text_label({
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 16),
				Text = tostring(text or ''),
				TextColor3 = label_values.dim and THEME.text_dim or THEME.text_sub,
				TextSize = label_values.dim and window._small_text_size + 1 or window._label_text_size,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = frame,
			})

			local label_manager = {}

			function label_manager:set_text(new_text)
				label_object.Text = tostring(new_text or '')
			end

			function label_manager:set_visible(state)
				frame.Visible = state == true
			end

			return label_manager
		end

		function group_manager:create_separator()
			divider(group_frame, UDim2.new(), UDim2.new(1, 0, 0, 1)).LayoutOrder = next_order()
		end

		function group_manager:create_toggle(flag, toggle_values)
			if type(flag) == 'table' then
				toggle_values = flag
				flag = toggle_values.flag
			end

			toggle_values = toggle_values or {}

			local state = toggle_values.default == true or toggle_values.Default == true

			if flag and window._flags[flag] ~= nil then
				state = window._flags[flag] == true
			elseif flag then
				window._flags[flag] = state
			end

			local row = create('Frame', {
				BackgroundTransparency = 1,
				LayoutOrder = next_order(),
				Size = UDim2.new(1, 0, 0, 24),
				Parent = group_frame,
			})

			local label = text_label({
				Size = UDim2.new(1, -44, 1, 0),
				Text = toggle_values.title or 'Toggle',
				TextSize = window._label_text_size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			})

			local switch = create('Frame', {
				BackgroundColor3 = THEME.element,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(34, 18),
				BorderSizePixel = 0,
				Parent = row,
			})

			pill(switch)

			local knob_off = UDim2.new(0, 3, 0.5, 0)
			local knob_on = UDim2.new(0, 34 - 12 - 3, 0.5, 0)

			local knob = create('Frame', {
				BackgroundColor3 = THEME.text_sub,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = knob_off,
				Size = UDim2.fromOffset(12, 12),
				BorderSizePixel = 0,
				Parent = switch,
			})

			pill(knob)

			local active_tweens = {}

			local function play(instance, properties)
				local object = tween(instance, 0.3, properties)
				table.insert(active_tweens, object)
			end

			local function apply(animate)
				for _, object in active_tweens do
					object:Cancel()
				end
				table.clear(active_tweens)

				local switch_color = state and window._accent or THEME.element
				local knob_color = state and knob_color_for(window._accent) or THEME.text_sub
				local label_color = state and THEME.text or THEME.text_sub
				local knob_position = state and knob_on or knob_off

				if animate then
					play(switch, { BackgroundColor3 = switch_color })
					play(knob, { Position = knob_position, BackgroundColor3 = knob_color })
					play(label, { TextColor3 = label_color })
				else
					switch.BackgroundColor3 = switch_color
					knob.BackgroundColor3 = knob_color
					knob.Position = knob_position
					label.TextColor3 = label_color
				end
			end

			local function set_state(value, animate)
				state = value == true
				apply(animate)

				if flag then
					window._flags[flag] = state
					window:_save()
				end

				if toggle_values.callback then
					toggle_values.callback(state)
				end

				if toggle_values.is_keybind then
					window:update_keybind_list()
				end
			end

			local click = create('TextButton', {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Text = '',
				ZIndex = 1,
				Parent = row,
			})

			click.MouseEnter:Connect(function()
				if not state then
					tween(label, 0.2, { TextColor3 = Color3.fromRGB(215, 215, 215) })
				end
			end)

			click.MouseLeave:Connect(function()
				if not state then
					tween(label, 0.2, { TextColor3 = THEME.text_sub })
				end
			end)

			click.MouseButton1Click:Connect(function()
				set_state(not state, true)
			end)

			apply(false)

			if toggle_values.is_keybind and not window._is_mobile then
				local bind_flag = flag and (flag .. '_key') or nil
				local key = bind_flag and key_from_name(window._flags[bind_flag]) or nil
				local picking = false
				local gap = 44

				local bind_button = create('TextButton', {
					BackgroundColor3 = THEME.element,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -gap, 0.5, 0),
					Size = UDim2.fromOffset(26, 22),
					Text = '',
					AutoButtonColor = false,
					BorderSizePixel = 0,
					ZIndex = 2,
					Parent = row,
				})

				corner(bind_button, 6)

				local bind_icon = create('ImageLabel', {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(14, 14),
					Image = 'rbxassetid://10709818996',
					ImageColor3 = THEME.text_sub,
					ZIndex = 3,
					Parent = bind_button,
				})

				local bind_text = text_label({
					Size = UDim2.fromScale(1, 1),
					Text = '',
					TextColor3 = THEME.text,
					TextSize = window._small_text_size + 1,
					Visible = false,
					ZIndex = 3,
					Parent = bind_button,
				})

				local function refit(text)
					local width = text_service:GetTextSize(
						text,
						window._small_text_size + 1,
						Enum.Font.GothamSemibold,
						Vector2.new(1000, 22)
					).X
					local final = max(26, width + 14)
					bind_button.Size = UDim2.fromOffset(final, 22)
					label.Size = UDim2.new(1, -(gap + final + 8), 1, 0)
				end

				local function show_key()
					if key then
						bind_icon.Visible = false
						bind_text.Visible = true
						bind_text.Text = key.Name
						refit(key.Name)
					else
						bind_icon.Visible = true
						bind_text.Visible = false
						refit('')
					end
				end

				show_key()

				bind_button.MouseButton1Click:Connect(function()
					picking = true
					bind_icon.Visible = false
					bind_text.Visible = true
					bind_text.Text = '...'
					refit('...')
					tween(bind_button, 0.2, { BackgroundColor3 = THEME.element_press })
				end)

				local function commit_key(new_key)
					key = new_key
					picking = false
					show_key()
					tween(bind_button, 0.2, { BackgroundColor3 = THEME.element })

					if bind_flag then
						window._flags[bind_flag] = key and key.Name or nil
						window:_save()
					end

					for _, entry in window._keybind_entries do
						if entry.flag == flag then
							entry.key_name = key and key.Name or nil
							break
						end
					end

					window:update_keybind_list()
				end

				window:_connect(user_input_service.InputBegan, function(input, processed)
					if picking then
						if input.UserInputType == Enum.UserInputType.Keyboard then
							if input.KeyCode == Enum.KeyCode.Escape then
								picking = false
								show_key()
								tween(bind_button, 0.2, { BackgroundColor3 = THEME.element })
							elseif input.KeyCode == Enum.KeyCode.Backspace then
								commit_key(nil)
							elseif input.KeyCode ~= Enum.KeyCode.Unknown then
								commit_key(input.KeyCode)
							end
						end
					elseif not processed and key and input.KeyCode == key then
						set_state(not state, true)
					end
				end)

				table.insert(window._keybind_entries, {
					flag = flag,
					title = toggle_values.title or 'Toggle',
					key_name = key and key.Name or nil,
				})

				window:update_keybind_list()

				if bind_flag then
					window._setters[bind_flag] = function(value)
						commit_key(key_from_name(value))
					end
				end
			end

			register(flag, function(value)
				set_state(value == true, true)
			end)

			local toggle_manager = {}

			function toggle_manager:set_value(value)
				set_state(value == true, true)
			end

			function toggle_manager:get_value()
				return state
			end

			return toggle_manager
		end

		function group_manager:create_slider(flag, slider_values)
			if type(flag) == 'table' then
				slider_values = flag
				flag = slider_values.flag
			end

			slider_values = slider_values or {}

			local minimum = slider_values.minimum or 0
			local maximum = slider_values.maximum or 100
			local step = slider_values.increment or (slider_values.rounding and 0.1 or 1)
			local suffix = slider_values.suffix or ''
			local default = slider_values.default ~= nil and slider_values.default or minimum

			if flag and window._flags[flag] ~= nil then
				default = window._flags[flag]
			elseif flag then
				window._flags[flag] = default
			end

			local value = clamp(default, minimum, maximum)

			local row = create('Frame', {
				BackgroundTransparency = 1,
				LayoutOrder = next_order(),
				Size = UDim2.new(1, 0, 0, 34),
				Parent = group_frame,
			})

			text_label({
				Size = UDim2.new(1, -70, 0, 16),
				Text = slider_values.title or 'Slider',
				TextSize = window._label_text_size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			})

			local value_label = text_label({
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.fromOffset(64, 16),
				Text = tostring(value) .. suffix,
				TextColor3 = THEME.text,
				TextSize = window._label_text_size,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = row,
			})

			local track_button = create('TextButton', {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 18),
				Size = UDim2.new(1, 0, 0, 16),
				Text = '',
				AutoButtonColor = false,
				Parent = row,
			})

			local track = create('Frame', {
				BackgroundColor3 = THEME.element,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 0, 6),
				BorderSizePixel = 0,
				Parent = track_button,
			})

			pill(track)

			local fill = create('Frame', {
				BackgroundColor3 = window._accent,
				Size = UDim2.new(clamp((value - minimum) / (maximum - minimum), 0, 1), 0, 1, 0),
				BorderSizePixel = 0,
				Parent = track,
			})

			pill(fill)

			local knob = create('Frame', {
				BackgroundColor3 = THEME.text,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(12, 12),
				BorderSizePixel = 0,
				Parent = fill,
			})

			pill(knob)

			local dragging = false

			local function commit(new_value, animate_fill)
				value = clamp(snap(new_value, step), minimum, maximum)
				local position = clamp((value - minimum) / (maximum - minimum), 0, 1)
				value_label.Text = tostring(value) .. suffix

				if animate_fill then
					tween(fill, 0.08, { Size = UDim2.new(position, 0, 1, 0) })
				else
					fill.Size = UDim2.new(position, 0, 1, 0)
				end

				if flag then
					window._flags[flag] = value
					window:_save()
				end

				if slider_values.callback then
					slider_values.callback(value)
				end
			end

			local function from_input(input)
				local width = track.AbsoluteSize.X
				if width <= 0 then
					return
				end
				local position = clamp((input.Position.X - track.AbsolutePosition.X) / width, 0, 1)
				commit(minimum + (maximum - minimum) * position, true)
			end

			track_button.MouseEnter:Connect(function()
				tween(knob, 0.15, { Size = UDim2.fromOffset(14, 14) })
			end)

			track_button.MouseLeave:Connect(function()
				if not dragging then
					tween(knob, 0.15, { Size = UDim2.fromOffset(12, 12) })
				end
			end)

			track_button.InputBegan:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					dragging = true
					window._slider_dragging = true
					tween(knob, 0.15, { Size = UDim2.fromOffset(16, 16) })
					from_input(input)
				end
			end)

			window:_connect(user_input_service.InputEnded, function(input)
				if
					dragging
					and (
						input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch
					)
				then
					dragging = false
					window._slider_dragging = false
					tween(knob, 0.15, { Size = UDim2.fromOffset(12, 12) })
				end
			end)

			window:_connect(user_input_service.InputChanged, function(input)
				if
					dragging
					and (
						input.UserInputType == Enum.UserInputType.MouseMovement
						or input.UserInputType == Enum.UserInputType.Touch
					)
				then
					from_input(input)
				end
			end)

			register(flag, function(new_value)
				if type(new_value) == 'number' then
					commit(new_value, true)
				end
			end)

			local slider_manager = {}

			function slider_manager:set_value(new_value)
				commit(clamp(new_value, minimum, maximum), true)
			end

			function slider_manager:get_value()
				return value
			end

			return slider_manager
		end

		function group_manager:create_progress(progress_values)
			progress_values = progress_values or {}

			local row = create('Frame', {
				BackgroundTransparency = 1,
				LayoutOrder = next_order(),
				Size = UDim2.new(1, 0, 0, 28),
				Visible = progress_values.visible == true,
				Parent = group_frame,
			})

			local status = text_label({
				Size = UDim2.new(1, -50, 0, 14),
				Text = progress_values.title or 'Loading...',
				TextSize = window._small_text_size + 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			})

			local percent = text_label({
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.fromOffset(44, 14),
				Text = '0%',
				TextColor3 = THEME.text,
				TextSize = window._small_text_size + 1,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = row,
			})

			local track = create('Frame', {
				BackgroundColor3 = THEME.element,
				Position = UDim2.fromOffset(0, 20),
				Size = UDim2.new(1, 0, 0, 6),
				BorderSizePixel = 0,
				Parent = row,
			})

			pill(track)

			local fill = create('Frame', {
				BackgroundColor3 = window._accent,
				Size = UDim2.new(0, 0, 1, 0),
				BorderSizePixel = 0,
				Parent = track,
			})

			pill(fill)

			local progress_manager = {}

			function progress_manager:set(fraction, text)
				local clamped = clamp(tonumber(fraction) or 0, 0, 1)
				if text then
					status.Text = tostring(text)
				end
				percent.Text = string.format('%d%%', floor(clamped * 100 + 0.5))
				tween(fill, 0.15, { Size = UDim2.new(clamped, 0, 1, 0) })
			end

			function progress_manager:set_visible(state)
				row.Visible = state == true
			end

			return progress_manager
		end

		function group_manager:create_button(flag, button_values)
			if type(flag) == 'table' then
				button_values = flag
			end

			button_values = button_values or {}

			local button = create('TextButton', {
				BackgroundColor3 = THEME.element,
				LayoutOrder = next_order(),
				Size = UDim2.new(1, 0, 0, 28),
				FontFace = font(),
				Text = button_values.title or 'Button',
				TextColor3 = THEME.text_sub,
				TextSize = window._label_text_size,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				Parent = group_frame,
			})

			corner(button, 7)

			button.MouseEnter:Connect(function()
				tween(button, 0.15, { BackgroundColor3 = THEME.element_hover, TextColor3 = THEME.text })
			end)

			button.MouseLeave:Connect(function()
				tween(button, 0.2, { BackgroundColor3 = THEME.element, TextColor3 = THEME.text_sub })
			end)

			button.MouseButton1Down:Connect(function()
				tween(button, 0.08, { BackgroundColor3 = THEME.element_press })
			end)

			button.MouseButton1Up:Connect(function()
				tween(button, 0.2, { BackgroundColor3 = THEME.element_hover })
			end)

			button.MouseButton1Click:Connect(function()
				if button_values.callback then
					button_values.callback()
				end
			end)

			local button_manager = {}

			function button_manager:set_title(text)
				button.Text = tostring(text)
			end

			function button_manager:set_visible(state)
				button.Visible = state == true
			end

			return button_manager
		end

		function group_manager:create_textbox(flag, textbox_values)
			if type(flag) == 'table' then
				textbox_values = flag
				flag = textbox_values.flag
			end

			textbox_values = textbox_values or {}

			local height = max(26, tonumber(textbox_values.height) or 28)
			local value = tostring(textbox_values.default or '')

			if flag and window._flags[flag] ~= nil then
				value = tostring(window._flags[flag])
			elseif flag then
				window._flags[flag] = value
			end

			local row = create('Frame', {
				BackgroundTransparency = 1,
				LayoutOrder = next_order(),
				Size = UDim2.new(1, 0, 0, height + 22),
				Visible = textbox_values.visible ~= false,
				Parent = group_frame,
			})

			text_label({
				Size = UDim2.new(1, 0, 0, 16),
				Text = textbox_values.title or 'Text',
				TextSize = window._label_text_size,
				TextColor3 = THEME.text_sub,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			})

			local multi_line = textbox_values.multi_line == true

			local textbox = create('TextBox', {
				BackgroundColor3 = THEME.element,
				Position = UDim2.fromOffset(0, 22),
				Size = UDim2.new(1, 0, 0, height),
				ClearTextOnFocus = false,
				MultiLine = multi_line,
				PlaceholderText = textbox_values.placeholder or '...',
				PlaceholderColor3 = THEME.text_dim,
				Text = value,
				TextColor3 = THEME.text,
				TextSize = window._label_text_size,
				TextWrapped = multi_line,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = multi_line and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
				FontFace = font(),
				BorderSizePixel = 0,
				Parent = row,
			})

			corner(textbox, 7)
			padding(textbox, multi_line and 6 or 0, multi_line and 6 or 0, 10, 10)

			local outline = stroke(textbox, THEME.element)

			textbox.Focused:Connect(function()
				tween(outline, 0.2, { Color = THEME.stroke_active })
				tween(textbox, 0.2, { BackgroundColor3 = THEME.element_hover })
			end)

			textbox.FocusLost:Connect(function(enter_pressed)
				tween(outline, 0.2, { Color = THEME.element })
				tween(textbox, 0.2, { BackgroundColor3 = THEME.element })

				value = textbox.Text

				if flag then
					window._flags[flag] = value
					window:_save()
				end

				if textbox_values.callback then
					textbox_values.callback(value, enter_pressed)
				end
			end)

			register(flag, function(new_value)
				value = tostring(new_value or '')
				textbox.Text = value
			end)

			local textbox_manager = {}

			function textbox_manager:get_value()
				return textbox.Text
			end

			function textbox_manager:set_value(new_value)
				value = tostring(new_value or '')
				textbox.Text = value
			end

			function textbox_manager:clear()
				self:set_value('')
			end

			function textbox_manager:focus()
				textbox:CaptureFocus()
			end

			function textbox_manager:set_visible(state)
				row.Visible = state == true
			end

			return textbox_manager
		end

		function group_manager:create_dropdown(flag, dropdown_values)
			if type(flag) == 'table' then
				dropdown_values = flag
				flag = dropdown_values.flag
			end

			dropdown_values = dropdown_values or {}
			dropdown_values.options = dropdown_values.options or {}

			local multi = dropdown_values.multi == true or dropdown_values.multi_dropdown == true

			local manager = {
				_open = false,
				_options = {},
				_buttons = {},
				_selected = {},
				_current = nil,
			}

			local initial = dropdown_values.default

			if flag and window._flags[flag] ~= nil then
				initial = window._flags[flag]
			end

			if multi then
				if type(initial) == 'table' then
					for index, value in initial do
						if type(index) == 'string' and value == true then
							manager._selected[index] = true
						elseif type(value) == 'string' then
							manager._selected[value] = true
						end
					end
				end
			elseif initial ~= nil then
				manager._current = tostring(initial)
			elseif not dropdown_values.empty_text and dropdown_values.options[1] ~= nil then
				manager._current = tostring(dropdown_values.options[1])
			end

			local wrapper = create('Frame', {
				BackgroundTransparency = 1,
				LayoutOrder = next_order(),
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				Parent = group_frame,
			})

			vertical_list(wrapper, 6)

			text_label({
				LayoutOrder = 0,
				Size = UDim2.new(1, 0, 0, 16),
				Text = dropdown_values.title or 'Dropdown',
				TextSize = window._label_text_size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = wrapper,
			})

			local box = create('Frame', {
				BackgroundColor3 = THEME.element,
				LayoutOrder = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Parent = wrapper,
			})

			corner(box, 7)
			vertical_list(box)

			local head = create('Frame', {
				BackgroundTransparency = 1,
				LayoutOrder = 0,
				Size = UDim2.new(1, 0, 0, 28),
				Parent = box,
			})

			local selected_text = text_label({
				Position = UDim2.fromOffset(10, 0),
				Size = UDim2.new(1, -34, 1, 0),
				Text = '',
				TextSize = window._label_text_size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = head,
			})

			local chevron = create('ImageLabel', {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(1, -16, 0.5, 0),
				Size = UDim2.fromOffset(12, 12),
				Image = 'rbxassetid://10734899821',
				ImageColor3 = THEME.text_sub,
				Parent = head,
			})

			local options_list = create('ScrollingFrame', {
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 0),
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				BorderSizePixel = 0,
				ScrollBarThickness = 0,
				ScrollBarImageTransparency = 1,
				VerticalScrollBarInset = Enum.ScrollBarInset.None,
				ClipsDescendants = true,
				Parent = box,
			})

			vertical_list(options_list)

			local function target_height()
				return min(#manager._options * 26, 5 * 26)
			end

			local function refresh_height()
				if manager._open then
					tween(options_list, 0.25, { Size = UDim2.new(1, 0, 0, target_height()) })
				end
			end

			local function is_selected(name)
				if multi then
					return manager._selected[name] == true
				end
				return manager._current == name
			end

			local function paint()
				if multi then
					local names = {}
					for _, option in manager._options do
						if manager._selected[option] then
							table.insert(names, option)
						end
					end
					selected_text.Text = #names > 0 and table.concat(names, ', ') or 'None'
					selected_text.TextColor3 = #names > 0 and THEME.text or THEME.text_dim
				else
					selected_text.Text = manager._current or dropdown_values.empty_text or 'None'
					selected_text.TextColor3 = manager._current and THEME.text or THEME.text_dim
				end

				for name, entry in manager._buttons do
					local selected = is_selected(name)
					tween(entry.label, 0.2, { TextColor3 = selected and THEME.text or THEME.text_sub })
					tween(entry.dot, 0.2, { BackgroundTransparency = selected and 0 or 1 })
				end
			end

			local function emit()
				local value
				if multi then
					value = {}
					for name, selected in manager._selected do
						if selected then
							value[name] = true
						end
					end
				else
					value = manager._current
				end

				if flag then
					window._flags[flag] = value
					window:_save()
				end

				if dropdown_values.callback then
					dropdown_values.callback(value)
				end
			end

			local function choose(name)
				if multi then
					manager._selected[name] = not manager._selected[name] or nil
					paint()
					emit()
					return
				end

				manager._current = name
				paint()
				manager:unfold(false)
				emit()
			end

			local function add_option(name)
				name = tostring(name)

				if table.find(manager._options, name) then
					return
				end

				table.insert(manager._options, name)

				local button = create('TextButton', {
					BackgroundTransparency = 1,
					LayoutOrder = #manager._options,
					Size = UDim2.new(1, 0, 0, 26),
					Text = '',
					AutoButtonColor = false,
					Parent = options_list,
				})

				local option_label = text_label({
					Position = UDim2.fromOffset(10, 0),
					Size = UDim2.new(1, -34, 1, 0),
					Text = name,
					TextSize = window._label_text_size,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Parent = button,
				})

				local dot = create('Frame', {
					BackgroundColor3 = window._accent,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(1, -16, 0.5, 0),
					Size = UDim2.fromOffset(6, 6),
					BorderSizePixel = 0,
					Parent = button,
				})

				pill(dot)

				manager._buttons[name] = { button = button, label = option_label, dot = dot }

				button.MouseEnter:Connect(function()
					tween(option_label, 0.15, { TextColor3 = THEME.text })
					tween(button, 0.15, { BackgroundTransparency = 0.85, BackgroundColor3 = THEME.text })
				end)

				button.MouseLeave:Connect(function()
					tween(option_label, 0.15, { TextColor3 = is_selected(name) and THEME.text or THEME.text_sub })
					tween(button, 0.15, { BackgroundTransparency = 1 })
				end)

				button.MouseButton1Click:Connect(function()
					choose(name)
				end)
			end

			function manager:set_options(options, selected)
				for _, entry in self._buttons do
					entry.button:Destroy()
				end

				table.clear(self._options)
				table.clear(self._buttons)

				for _, option in options or {} do
					add_option(option)
				end

				if multi then
					table.clear(self._selected)
					if type(selected) == 'table' then
						for index, value in selected do
							if type(index) == 'string' and value == true then
								self._selected[index] = true
							elseif type(value) == 'string' then
								self._selected[value] = true
							end
						end
					end
				elseif selected ~= nil and table.find(self._options, tostring(selected)) then
					self._current = tostring(selected)
				elseif self._current and not table.find(self._options, self._current) then
					self._current = nil
				end

				paint()
				refresh_height()
			end

			function manager:add_option(option, select_added)
				add_option(option)
				refresh_height()
				if select_added then
					self:set_value(option, true)
				else
					paint()
				end
			end

			function manager:set_value(value, silent)
				if multi then
					table.clear(self._selected)
					if type(value) == 'table' then
						for index, selected in value do
							if type(index) == 'string' and selected == true then
								self._selected[index] = true
							elseif type(selected) == 'string' then
								self._selected[selected] = true
							end
						end
					end
				elseif value == nil then
					self._current = nil
				else
					value = tostring(value)
					if not table.find(self._options, value) then
						return false
					end
					self._current = value
				end

				paint()

				if not silent then
					emit()
				end

				return true
			end

			function manager:get_value()
				if multi then
					return shallow_copy(self._selected)
				end
				return self._current
			end

			function manager:unfold(force)
				local opening = force
				if opening == nil then
					opening = not self._open
				end

				if opening == self._open then
					return
				end

				if opening then
					for _, other in window._active_dropdowns do
						if other ~= self and other._open then
							other:unfold(false)
						end
					end
				end

				self._open = opening

				tween(chevron, 0.3, { Rotation = opening and 180 or 0 })

				if opening then
					options_list.CanvasPosition = Vector2.new(0, 0)
					tween(options_list, 0.35, { Size = UDim2.new(1, 0, 0, target_height()) })
				else
					tween(options_list, 0.3, { Size = UDim2.new(1, 0, 0, 0) })
				end
			end

			local head_button = create('TextButton', {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Text = '',
				ZIndex = 10,
				Parent = head,
			})

			head_button.MouseEnter:Connect(function()
				tween(box, 0.2, { BackgroundColor3 = THEME.element_hover })
			end)

			head_button.MouseLeave:Connect(function()
				tween(box, 0.2, { BackgroundColor3 = THEME.element })
			end)

			head_button.MouseButton1Click:Connect(function()
				manager:unfold()
			end)

			for _, option in dropdown_values.options do
				add_option(option)
			end

			paint()

			table.insert(window._active_dropdowns, manager)

			register(flag, function(value)
				manager:set_value(value)
			end)

			return manager
		end

		function group_manager:create_keybind(flag, keybind_values)
			if type(flag) == 'table' then
				keybind_values = flag
				flag = keybind_values.flag
			end

			keybind_values = keybind_values or {}

			local key = keybind_values.default or Enum.KeyCode.RightShift

			if flag and window._flags[flag] ~= nil then
				key = key_from_name(window._flags[flag]) or key
			elseif flag then
				window._flags[flag] = key.Name
			end

			local picking = false

			local row = create('Frame', {
				BackgroundTransparency = 1,
				LayoutOrder = next_order(),
				Size = UDim2.new(1, 0, 0, 24),
				Parent = group_frame,
			})

			text_label({
				Size = UDim2.new(0.55, 0, 1, 0),
				Text = keybind_values.title or 'Keybind',
				TextSize = window._label_text_size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			})

			local bind_button = create('TextButton', {
				BackgroundColor3 = THEME.element,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(36, 22),
				AutomaticSize = Enum.AutomaticSize.X,
				FontFace = font(),
				Text = key.Name,
				TextColor3 = THEME.text,
				TextSize = window._small_text_size + 1,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				Parent = row,
			})

			corner(bind_button, 6)
			padding(bind_button, 0, 0, 9, 9)

			bind_button.MouseButton1Click:Connect(function()
				picking = true
				bind_button.Text = '...'
				tween(bind_button, 0.2, { BackgroundColor3 = THEME.element_press })
			end)

			local function set_key(new_key)
				key = new_key
				picking = false
				bind_button.Text = key.Name
				tween(bind_button, 0.2, { BackgroundColor3 = THEME.element })

				if flag then
					window._flags[flag] = key.Name
					window:_save()
				end
			end

			window:_connect(user_input_service.InputBegan, function(input, processed)
				if picking then
					if
						input.UserInputType == Enum.UserInputType.Keyboard
						and input.KeyCode ~= Enum.KeyCode.Unknown
					then
						if input.KeyCode == Enum.KeyCode.Escape then
							picking = false
							bind_button.Text = key.Name
							tween(bind_button, 0.2, { BackgroundColor3 = THEME.element })
						else
							set_key(input.KeyCode)
						end
					end
				elseif not processed and input.KeyCode == key then
					if keybind_values.callback then
						keybind_values.callback()
					end
				end
			end)

			register(flag, function(value)
				local resolved = key_from_name(value)
				if resolved then
					set_key(resolved)
				end
			end)

			local keybind_manager = {}

			function keybind_manager:set_key(new_key)
				set_key(new_key)
			end

			function keybind_manager:get_key()
				return key
			end

			return keybind_manager
		end

		table.insert(manager._groups, group_manager)

		local group_key = normalize_name(values.title)
		manager._group_registry[group_key] = manager._group_registry[group_key] or {}
		table.insert(manager._group_registry[group_key], group_manager)

		return group_manager
	end

	return manager
end

local everst = library.new({
	title = 'Everst',
	subtitle = 'Auto Parry  ·  v1.0',
	autosave = false,
})

local parry_category = everst:create_category('Auto Parry')
local main_tab = parry_category:create_tab('Main', 'rbxassetid://10709812159')

local parry_group = main_tab:create_group('Parry', 'left')

parry_group:create_toggle('auto_parry', {
	title = 'Auto Parry',
	default = false,
	is_keybind = true,
	callback = function(state)
		everst:notify(state and 'Auto parry enabled' or 'Auto parry disabled', state and 'success' or 'info')
	end,
})

parry_group:create_slider('parry_distance', {
	title = 'Parry Distance',
	minimum = 5,
	maximum = 60,
	default = 24,
	suffix = ' st',
})

parry_group:create_slider('parry_accuracy', {
	title = 'Accuracy',
	minimum = 0,
	maximum = 100,
	default = 85,
	suffix = '%',
})

parry_group:create_dropdown('parry_mode', {
	title = 'Mode',
	options = { 'Legit', 'Rage', 'Adaptive' },
	default = 'Adaptive',
})

local filter_group = main_tab:create_group('Filters', 'right')

filter_group:create_toggle('ignore_teammates', {
	title = 'Ignore Teammates',
	default = true,
})

filter_group:create_toggle('only_targeted', {
	title = 'Only When Targeted',
	default = false,
})

filter_group:create_separator()

filter_group:create_dropdown('target_priority', {
	title = 'Priority',
	options = { 'Closest', 'Fastest', 'Strongest', 'Lowest Health' },
	multi = true,
})

filter_group:create_keybind('panic_key', {
	title = 'Panic Key',
	default = Enum.KeyCode.X,
	callback = function()
		everst:notify('Panic key pressed', 'warning')
	end,
})

local visual_category = everst:create_category('Visual')

local background_tab = visual_category:create_tab('Background')
local skin_tab = visual_category:create_tab('Skin Changer', 'rbxassetid://10723416765')
local unlock_tab = visual_category:create_tab('Unlock', 'rbxassetid://10709812159')
local emotes_tab = visual_category:create_tab('Emotes', 'rbxassetid://10734941499')

local sword_group = skin_tab:create_group('Sword', 'left')

local sword_name_box = sword_group:create_textbox('sword_name', {
	title = 'Sword Name',
	placeholder = 'Enter a sword name...',
	default = "Witch's Curse",
})

sword_group:create_button({
	title = 'Apply Sword',
	callback = function()
		local name = sword_name_box:get_value()
		if name == '' then
			everst:notify('Enter a sword name first', 'warning')
			return
		end
		everst:notify('Applied sword: ' .. name, 'success')
	end,
})

sword_group:create_button({
	title = 'Clear Sword',
	callback = function()
		sword_name_box:clear()
		everst:notify('Sword cleared')
	end,
})

local effects_group = skin_tab:create_group('Effects', 'right')

effects_group:create_toggle('sword_trail', {
	title = 'Sword Trail',
	default = false,
})

effects_group:create_slider('trail_length', {
	title = 'Trail Length',
	minimum = 1,
	maximum = 10,
	default = 4,
	increment = 0.5,
})

effects_group:create_dropdown('trail_style', {
	title = 'Trail Style',
	options = { 'Smooth', 'Pulse', 'Lightning' },
	default = 'Smooth',
})

local unlock_group = unlock_tab:create_group('Unlocks', 'left')

unlock_group:create_label('Unlock cosmetics client-side for preview.', { dim = true })
unlock_group:create_toggle('unlock_swords', { title = 'Unlock All Swords' })
unlock_group:create_toggle('unlock_auras', { title = 'Unlock All Auras' })

local emote_group = emotes_tab:create_group('Emotes', 'left')

emote_group:create_dropdown('emote_pick', {
	title = 'Emote',
	options = { 'Wave', 'Dance', 'Salute', 'Bow' },
	default = 'Wave',
})

emote_group:create_button({
	title = 'Play Emote',
	callback = function()
		everst:notify('Playing emote')
	end,
})

local bg_group = background_tab:create_group('Background', 'left')

local bg_name_box = bg_group:create_textbox({
	title = 'Background Name',
	placeholder = 'Optional name...',
})

local bg_source_box = bg_group:create_textbox({
	title = 'PNG / JPEG URL or File',
	placeholder = 'https://... or rbxassetid://...',
})

local bg_progress = bg_group:create_progress({
	title = 'Uploading...',
	visible = false,
})

bg_group:create_button({
	title = 'Upload & Apply',
	callback = function()
		everst:upload_background(
			bg_source_box:get_value(),
			bg_name_box:get_value(),
			bg_progress,
			function(success, saved_name)
				if success then
					bg_source_box:clear()
					bg_name_box:clear()
					task.defer(function()
						if everst._bg_saved_dropdown then
							everst._bg_saved_dropdown:set_options(everst:_get_saved_bg_names(), saved_name)
						end
					end)
				end
			end
		)
	end,
})

local bg_manage_group = background_tab:create_group('Saved', 'right')

local bg_saved_dropdown = bg_manage_group:create_dropdown({
	title = 'Saved Backgrounds',
	options = everst:_get_saved_bg_names(),
	default = everst._bg_store.active,
	empty_text = 'None',
	callback = function(selected)
		if selected and selected ~= '' then
			everst:apply_saved_background(selected)
		end
	end,
})

everst._bg_saved_dropdown = bg_saved_dropdown

bg_manage_group:create_slider({
	title = 'Background Dim',
	minimum = 0,
	maximum = 95,
	default = everst._bg_dim_amount,
	suffix = '%',
	callback = function(value)
		everst:set_background_dim(value)
	end,
})

bg_manage_group:create_button({
	title = 'Remove Selected',
	callback = function()
		local current = bg_saved_dropdown:get_value()
		if current and everst:delete_saved_background(current) then
			bg_saved_dropdown:set_options(everst:_get_saved_bg_names(), everst._bg_store.active)
			everst:notify('Removed background: ' .. tostring(current), 'success')
		else
			everst:notify('No saved background selected', 'warning')
		end
	end,
})

bg_manage_group:create_button({
	title = 'Clear Background',
	callback = function()
		everst:clear_background()
		bg_saved_dropdown:set_value(nil, true)
		everst:notify('Background cleared')
	end,
})

local menu_category = everst:create_category('Menu')
local settings_tab = menu_category:create_tab('Settings', 'rbxassetid://10734941499')

local interface_group = settings_tab:create_group('Interface', 'left')

interface_group:create_keybind('minimize', {
	title = 'Toggle UI',
	default = Enum.KeyCode.RightShift,
})

interface_group:create_toggle('keybind_list', {
	title = 'Keybind List',
	default = false,
	callback = function(state)
		everst._keybind_list_visible = state
		everst:update_keybind_list()
	end,
})

interface_group:create_toggle('collapse_sidebar', {
	title = 'Collapse Sidebar',
	default = false,
	callback = function(state)
		everst:set_sidebar_collapsed(state)
	end,
})

interface_group:create_button({
	title = 'Reset Window Size',
	callback = function()
		everst:reset_size()
		everst:notify('Window size reset')
	end,
})

interface_group:create_button({
	title = 'Unload UI',
	callback = function()
		everst:destroy()
	end,
})

local config_group = settings_tab:create_group('Configs', 'right')

local config_name_box = config_group:create_textbox({
	title = 'Config Name',
	placeholder = 'my_config',
})

local config_dropdown = config_group:create_dropdown({
	title = 'Saved Configs',
	options = everst:list_configs(),
	empty_text = 'None',
})

config_group:create_button({
	title = 'Save Config',
	callback = function()
		local name = config_name_box:get_value()
		if everst:save_config(name) then
			config_dropdown:set_options(everst:list_configs(), name)
		end
	end,
})

config_group:create_button({
	title = 'Load Selected',
	callback = function()
		local selected = config_dropdown:get_value()
		if selected then
			everst:load_config(selected)
		else
			everst:notify('Select a config first', 'warning')
		end
	end,
})

config_group:create_button({
	title = 'Delete Selected',
	callback = function()
		local selected = config_dropdown:get_value()
		if selected and everst:delete_config(selected) then
			config_dropdown:set_options(everst:list_configs())
		end
	end,
})

config_group:create_button({
	title = 'Refresh List',
	callback = function()
		config_dropdown:set_options(everst:list_configs(), config_dropdown:get_value())
	end,
})

everst:notify('Everst loaded', 'success')

return library
