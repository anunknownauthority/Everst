local _cloneref = typeof(cloneref) == 'function' and cloneref or function(instance)
	return instance
end

local players = _cloneref(game:GetService('Players'))
local user_input_service = _cloneref(game:GetService('UserInputService'))
local tween_service = _cloneref(game:GetService('TweenService'))
local text_service = _cloneref(game:GetService('TextService'))
local http_service = _cloneref(game:GetService('HttpService'))
local run_service = _cloneref(game:GetService('RunService'))
local content_provider = _cloneref(game:GetService('ContentProvider'))
local core_gui = _cloneref(game:GetService('CoreGui'))

local http_request = (syn and syn.request) or (http and http.request) or http_request or request
local get_asset = getcustomasset or getsynasset

local _new_instance = Instance.new
local _new_tween_info = TweenInfo.new
local _new_udim = UDim.new
local _new_udim2 = UDim2.new
local _udim2_from_offset = UDim2.fromOffset
local _udim2_from_scale = UDim2.fromScale
local _new_vector2 = Vector2.new

local _clamp = math.clamp
local _floor = math.floor
local _ceil = math.ceil
local _max = math.max
local _min = math.min

local _clear = table.clear
local _find = table.find
local _insert = table.insert
local _sort = table.sort
local _concat = table.concat
local _tcreate = table.create

local _defer = task.defer
local _delay = task.delay
local _spawn = task.spawn
local _wait = task.wait
local _create_tween = tween_service.Create

local _pairs = pairs
local _ipairs = ipairs
local _pcall = pcall
local _tostring = tostring
local _tonumber = tonumber
local _type = type

local DEFAULT_WIDTH = 720
local DEFAULT_HEIGHT = 480
local MIN_WIDTH = 540
local MIN_HEIGHT = 360
local MAX_WIDTH = 1100
local MAX_HEIGHT = 780

local SIDEBAR_EXPANDED = 160
local SIDEBAR_COLLAPSED = 56

local BG_ROOT = 'Everst'
local BG_FOLDER = 'Everst/backgrounds'
local BG_STORE_PATH = 'Everst/backgrounds/saved.json'
local CACHE_VERSION = 3
local MAX_FRAMES = 60
local MAX_DIMENSION = 768
local MAX_PARSED_FRAMES = 1500
local MAX_CANVAS_PIXELS = 16777216
local CONNECTIONS = 6
local FIRST_CHUNK = 524288
local MIN_PART_SIZE = 262144
local START_BUDGET = 0.005
local MIN_BUDGET = 0.0012
local MAX_BUDGET = 0.012
local SEGMENT = 65536
local USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36'

local function get_interface_parent()
	if typeof(gethui) == 'function' then
		local ok, result = _pcall(gethui)
		if ok and result then
			return result
		end
	end

	local core_ok = _pcall(function()
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

local library = {
	_config = {},
	_flags = {},
	_current = nil,
}
library.__index = library

local function create_new(class_name, properties)
	local instance = _new_instance(class_name)

	for property, value in properties do
		if property ~= 'Parent' then
			instance[property] = value
		end
	end

	instance.Parent = properties.Parent
	return instance
end

local function create_round(instance, radius)
	return create_new('UICorner', {
		CornerRadius = _new_udim(0, radius),
		Parent = instance,
	})
end

local function create_pill(instance)
	return create_new('UICorner', {
		CornerRadius = _new_udim(1, 0),
		Parent = instance,
	})
end

local function create_outline(instance, refresh)
	local stroke = create_new('UIStroke', {
		Color = Color3.fromRGB(35, 35, 35),
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = instance,
	})

	if refresh then
		instance:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
			stroke.Enabled = false
			stroke.Enabled = true
		end)
	end

	return stroke
end

local function create_vertical_list(instance, gap)
	return create_new('UIListLayout', {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = _new_udim(0, gap or 0),
		Parent = instance,
	})
end

local function create_padding(instance, top, bottom, left, right)
	return create_new('UIPadding', {
		PaddingTop = _new_udim(0, top),
		PaddingBottom = _new_udim(0, bottom),
		PaddingLeft = _new_udim(0, left),
		PaddingRight = _new_udim(0, right),
		Parent = instance,
	})
end

local function create_label(properties)
	properties.BackgroundTransparency = 1
	properties.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	properties.TextColor3 = properties.TextColor3 or Color3.fromRGB(180, 180, 180)
	properties.BorderSizePixel = 0

	return create_new('TextLabel', properties)
end

local function create_divider(parent, position, size)
	return create_new('Frame', {
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		Position = position,
		Size = size,
		BorderSizePixel = 0,
		Parent = parent,
	})
end

local function create_grip(parent, position, anchor_point, z_index)
	local grip = create_new('TextButton', {
		BackgroundTransparency = 1,
		AnchorPoint = anchor_point or _new_vector2(1, 0.5),
		Position = position or _new_udim2(1, 0, 0.5, 0),
		Size = _new_udim2(0, 18, 0, 16),
		Text = '',
		AutoButtonColor = false,
		BorderSizePixel = 0,
		ZIndex = z_index or 4,
		Parent = parent,
	})

	local bars = {}

	for index = 1, 3 do
		local bar = create_new('Frame', {
			BackgroundColor3 = Color3.fromRGB(100, 100, 100),
			AnchorPoint = _new_vector2(0, 0.5),
			Position = _new_udim2(0, 3 + (index - 1) * 4, 0.5, 0),
			Size = _new_udim2(0, 2, 0, 10),
			BorderSizePixel = 0,
			ZIndex = (z_index or 4) + 1,
			Parent = grip,
		})

		create_pill(bar)
		_insert(bars, bar)
	end

	local function set_color(color)
		for _, bar in bars do
			_create_tween(tween_service, bar, _new_tween_info(0.15), {
				BackgroundColor3 = color,
			}):Play()
		end
	end

	return grip, set_color
end

local function normalize_name(value)
	local normalized = string.lower(_tostring(value or ''))
	normalized = string.gsub(normalized, '^%s+', '')
	return string.gsub(normalized, '%s+$', '')
end

local function shallow_copy(source)
	local copy = {}
	for index, value in source or {} do
		copy[index] = value
	end
	return copy
end

local function round_number(number, decimals)
	local multiplier = 10 ^ (decimals or 0)
	return _floor(number * multiplier + 0.5 - (number < 0 and 1 or 0)) / multiplier
end

local function resolve_runtime(self)
	if self ~= library and _type(self) == 'table' and self._tabs then
		return self
	end
	return library._current
end

local function ensure_folder(path)
	if typeof(makefolder) ~= 'function' then
		return false
	end
	local exists = false
	if typeof(isfolder) == 'function' then
		local ok, res = _pcall(isfolder, path)
		exists = ok and res == true
	end
	if not exists then
		local ok = _pcall(makefolder, path)
		return ok
	end
	return true
end

local function file_exists(path)
	if typeof(isfile) ~= 'function' then
		return false
	end
	local ok, res = _pcall(isfile, path)
	return ok and res == true
end

local function hash_string(s)
	local h = 5381
	for i = 1, #s do
		h = (h * 33 + string.byte(s, i)) % 4294967296
	end
	return string.format('%08x', h)
end

local function header_get(headers, name)
	if _type(headers) ~= 'table' then
		return nil
	end
	for k, v in _pairs(headers) do
		if _type(k) == 'string' and string.lower(k) == name then
			return _tostring(v)
		end
	end
	return nil
end

local function make_headers(range)
	local headers = {
		['User-Agent'] = USER_AGENT,
		['Accept'] = 'image/gif,image/png,image/jpeg,image/*;q=0.8,*/*;q=0.5',
	}
	if range then
		headers['Range'] = range
	end
	return headers
end

local function send_http_request(url, headers)
	local ok, res = _pcall(http_request, {
		Url = url,
		Method = 'GET',
		Headers = headers,
	})
	if not ok or _type(res) ~= 'table' then
		return nil
	end
	local body = res.Body or res.body
	if _type(body) ~= 'string' then
		return nil
	end
	local code = _tonumber(res.StatusCode or res.Status or res.status_code)
	return code, body, res.Headers or res.headers
end

local function download_url_bytes(url, on_progress)
	if not http_request then
		local ok, body = _pcall(function()
			return game:HttpGet(url)
		end)
		if ok and _type(body) == 'string' and #body > 0 then
			return body
		end
		error('http request unavailable', 0)
	end

	if on_progress then
		on_progress(0.05, 'Downloading...')
	end

	local code, body, headers = send_http_request(url, make_headers('bytes=0-' .. (FIRST_CHUNK - 1)))
	if body and code == 200 then
		if on_progress then
			on_progress(1, 'Downloaded')
		end
		return body
	end

	if body and code == 206 then
		local range = header_get(headers, 'content-range')
		local total = range and _tonumber(string.match(range, '/(%d+)%s*$'))
		if total and #body >= total then
			if on_progress then
				on_progress(1, 'Downloaded')
			end
			return body
		end

		if total and total > #body then
			local first = #body
			local remaining = total - first
			local parts = _clamp(_ceil(remaining / MIN_PART_SIZE), 1, CONNECTIONS)
			local part_size = _ceil(remaining / parts)
			local results = _tcreate(parts)
			local pending = parts
			local done_parts = 0

			for j = 1, parts do
				local from = first + (j - 1) * part_size
				local to = _min(total - 1, from + part_size - 1)
				local expected = to - from + 1
				_spawn(function()
					_pcall(function()
						for _ = 1, 3 do
							local c, b = send_http_request(url, make_headers('bytes=' .. from .. '-' .. to))
							if b and c == 206 and #b == expected then
								results[j] = b
								break
							end
						end
					end)
					done_parts += 1
					pending -= 1
					if on_progress then
						on_progress(_clamp(done_parts / parts, 0.05, 1), string.format('Downloading %d%%', _floor((done_parts / parts) * 100)))
					end
				end)
			end

			while pending > 0 do
				_wait()
			end

			local complete = true
			for j = 1, parts do
				if not results[j] then
					complete = false
					break
				end
			end

			if complete then
				local data = body .. _concat(results)
				if #data == total then
					return data
				end
			end
		end
	end

	local c, b = send_http_request(url, make_headers(nil))
	if b and (c == nil or (c >= 200 and c < 300)) then
		if on_progress then
			on_progress(1, 'Downloaded')
		end
		return b
	end

	error('download failed (' .. _tostring(c) .. ')', 0)
end

local function detect_image_kind(data)
	if _type(data) ~= 'string' or #data < 4 then
		return nil
	end
	if string.sub(data, 1, 3) == 'GIF' then
		return 'gif'
	end
	if string.sub(data, 1, 4) == '\137PNG' then
		return 'png'
	end
	if string.byte(data, 1) == 0xFF and string.byte(data, 2) == 0xD8 and string.byte(data, 3) == 0xFF then
		return 'jpg'
	end
	return nil
end

local gif_codec_available = typeof(buffer) == 'table' and typeof(bit32) == 'table'
local T0, T1, T2, T3 = {}, {}, {}, {}
local MASKS = {}
local LIMITS = {}
local dPos = _tcreate(4096, 0)
local dLen = _tcreate(4096, 0)

if gif_codec_available then
	local band, bxor, lshift, rshift = bit32.band, bit32.bxor, bit32.lshift, bit32.rshift

	for i = 0, 255 do
		local c = i
		for _ = 1, 8 do
			if band(c, 1) == 1 then
				c = bxor(0xEDB88320, rshift(c, 1))
			else
				c = rshift(c, 1)
			end
		end
		T0[i] = c
	end

	for i = 0, 255 do
		local c = T0[i]
		c = bxor(rshift(c, 8), T0[band(c, 255)])
		T1[i] = c
		c = bxor(rshift(c, 8), T0[band(c, 255)])
		T2[i] = c
		c = bxor(rshift(c, 8), T0[band(c, 255)])
		T3[i] = c
	end

	for s = 1, 12 do
		MASKS[s] = lshift(1, s) - 1
		LIMITS[s] = lshift(1, s)
	end
end

local function decode_and_cache_gif(gif_bytes, folder, should_cancel, on_progress)
	if not gif_codec_available then
		error('buffer or bit32 unavailable for GIF decoding', 0)
	end
	if typeof(writefile) ~= 'function' or not get_asset then
		error('writefile and getcustomasset are required for GIFs', 0)
	end

	local readu8, readu16, readu32 = buffer.readu8, buffer.readu16, buffer.readu32
	local writeu8, writeu16, writeu32 = buffer.writeu8, buffer.writeu16, buffer.writeu32
	local bcopy, bfill = buffer.copy, buffer.fill
	local band, bor, bxor = bit32.band, bit32.bor, bit32.bxor
	local lshift, rshift = bit32.lshift, bit32.rshift

	local frame_dt = 1 / 60
	local dt_conn = run_service.Heartbeat:Connect(function(dt)
		frame_dt = dt
	end)

	local function cleanup_dt()
		if dt_conn then
			dt_conn:Disconnect()
			dt_conn = nil
		end
	end

	local ok, result_w, result_h, result_urls, result_delays, result_loops = _pcall(function()
		local budget = START_BUDGET
		local deadline = os.clock() + budget

		local function pace()
			if os.clock() < deadline then
				return
			end
			_wait()
			if should_cancel() then
				error('cancelled', 0)
			end
			if frame_dt > (1 / 60) * 1.3 + 0.002 then
				budget = _max(MIN_BUDGET, budget * 0.7)
			else
				budget = _min(MAX_BUDGET, budget * 1.1)
			end
			deadline = os.clock() + budget
		end

		local function crc_update(c, buf, offset, len)
			local i = offset
			local last = offset + len
			local stop = last - 3
			while i < stop do
				c = bxor(c, readu32(buf, i))
				c = bxor(
					bxor(T3[band(c, 255)], T2[band(rshift(c, 8), 255)]),
					bxor(T1[band(rshift(c, 16), 255)], T0[rshift(c, 24)])
				)
				i += 4
			end
			while i < last do
				c = bxor(T0[band(bxor(c, readu8(buf, i)), 255)], rshift(c, 8))
				i += 1
			end
			return c
		end

		local function crc32_paced(buf, offset, len)
			local c = 0xFFFFFFFF
			local pos = offset
			local last = offset + len
			while pos < last do
				local n = _min(SEGMENT, last - pos)
				c = crc_update(c, buf, pos, n)
				pos += n
				pace()
			end
			return bxor(c, 0xFFFFFFFF)
		end

		local function adler_update(a, b, buf, offset, len)
			local i = offset
			local last = offset + len
			while i < last do
				local chunk_end = _min(i + 5552, last)
				local word_stop = chunk_end - 3
				while i < word_stop do
					local w = readu32(buf, i)
					a += band(w, 255)
					b += a
					a += band(rshift(w, 8), 255)
					b += a
					a += band(rshift(w, 16), 255)
					b += a
					a += rshift(w, 24)
					b += a
					i += 4
				end
				while i < chunk_end do
					a += readu8(buf, i)
					b += a
					i += 1
				end
				a %= 65521
				b %= 65521
			end
			return a, b
		end

		local function adler32_paced(buf, len)
			local a, b = 1, 0
			local pos = 0
			while pos < len do
				local n = _min(SEGMENT, len - pos)
				a, b = adler_update(a, b, buf, pos, n)
				pos += n
				pace()
			end
			return bor(lshift(b, 16), a)
		end

		local function write_u32_be(buf, off, v)
			writeu8(buf, off, rshift(v, 24))
			writeu8(buf, off + 1, band(rshift(v, 16), 255))
			writeu8(buf, off + 2, band(rshift(v, 8), 255))
			writeu8(buf, off + 3, band(v, 255))
		end

		local function new_png_context(w, h)
			local row_size = 1 + w * 4
			local raw_len = row_size * h
			local num_blocks = _ceil(raw_len / 65535)
			local zlib_len = 2 + num_blocks * 5 + raw_len + 4
			local png = buffer.create(57 + zlib_len)
			local raw = buffer.create(raw_len)

			buffer.writestring(png, 0, '\137PNG\r\n\26\n')
			write_u32_be(png, 8, 13)
			buffer.writestring(png, 12, 'IHDR')
			write_u32_be(png, 16, w)
			write_u32_be(png, 20, h)
			writeu8(png, 24, 8)
			writeu8(png, 25, 6)
			writeu8(png, 26, 0)
			writeu8(png, 27, 0)
			writeu8(png, 28, 0)
			write_u32_be(png, 29, bxor(crc_update(0xFFFFFFFF, png, 12, 17), 0xFFFFFFFF))

			write_u32_be(png, 33, zlib_len)
			buffer.writestring(png, 37, 'IDAT')
			writeu8(png, 41, 0x78)
			writeu8(png, 42, 0x01)
			for k = 0, num_blocks - 1 do
				local hp = 43 + k * 65540
				local bl = _min(65535, raw_len - k * 65535)
				writeu8(png, hp, (k == num_blocks - 1) and 1 or 0)
				writeu16(png, hp + 1, bl)
				writeu16(png, hp + 3, bxor(bl, 0xFFFF))
			end

			local iend = 45 + zlib_len
			write_u32_be(png, iend, 0)
			buffer.writestring(png, iend + 4, 'IEND')
			write_u32_be(png, iend + 8, 0xAE426082)

			return {
				raw = raw,
				png = png,
				rowSize = row_size,
				rawLen = raw_len,
				zlibLen = zlib_len,
				adlerPos = 43 + num_blocks * 5 + raw_len,
			}
		end

		local function finish_png(ctx)
			local raw, png = ctx.raw, ctx.png
			local remaining = ctx.rawLen
			local src = 0
			local dst = 48
			while remaining > 0 do
				local bl = _min(65535, remaining)
				bcopy(png, dst, raw, src, bl)
				src += bl
				remaining -= bl
				dst += bl + 5
			end
			write_u32_be(png, ctx.adlerPos, adler32_paced(raw, ctx.rawLen))
			write_u32_be(png, 41 + ctx.zlibLen, crc32_paced(png, 37, 4 + ctx.zlibLen))
			return buffer.tostring(png)
		end

		local function lzw_decode(data, data_len, min_code, out, out_len)
			if min_code < 1 or min_code > 8 then
				return 0
			end
			local clear_code = lshift(1, min_code)
			local end_code = clear_code + 1
			local code_size = min_code + 1
			local next_code = end_code + 1
			local pos, last_pos, last_len = 0, 0, 0
			local have_prev = false
			local bit_buf, bit_cnt, byte_pos = 0, 0, 0
			local ticks = 0

			while pos < out_len do
				while bit_cnt < code_size do
					if byte_pos >= data_len then
						return pos
					end
					bit_buf += lshift(readu8(data, byte_pos), bit_cnt)
					byte_pos += 1
					bit_cnt += 8
				end
				local code = band(bit_buf, MASKS[code_size])
				bit_buf = rshift(bit_buf, code_size)
				bit_cnt -= code_size

				if code == clear_code then
					code_size = min_code + 1
					next_code = end_code + 1
					have_prev = false
				elseif code == end_code then
					return pos
				else
					local cur_len
					if code < clear_code then
						writeu8(out, pos, code)
						cur_len = 1
					elseif code < next_code then
						local l = dLen[code]
						local avail = out_len - pos
						if l > avail then
							l = avail
						end
						if l == 1 then
							writeu8(out, pos, readu8(out, dPos[code]))
						else
							bcopy(out, pos, out, dPos[code], l)
						end
						cur_len = l
					elseif code == next_code and have_prev then
						local avail = out_len - pos
						if avail > last_len then
							bcopy(out, pos, out, last_pos, last_len)
							writeu8(out, pos + last_len, readu8(out, last_pos))
							cur_len = last_len + 1
						else
							bcopy(out, pos, out, last_pos, avail)
							cur_len = avail
						end
					else
						return pos
					end

					if have_prev and next_code < 4096 then
						dPos[next_code] = last_pos
						dLen[next_code] = last_len + 1
						next_code += 1
						if next_code == LIMITS[code_size] and code_size < 12 then
							code_size += 1
						end
					end

					last_pos = pos
					last_len = cur_len
					pos += cur_len
					have_prev = true

					ticks += 1
					if ticks >= 4096 then
						ticks = 0
						pace()
					end
				end
			end
			return pos
		end

		local function skip_blocks(g, n, off)
			while off < n do
				local size = readu8(g, off)
				off += 1
				if size == 0 then
					break
				end
				off += size
			end
			return off
		end

		local function parse_gif(s)
			local n = #s
			if n < 13 or string.sub(s, 1, 3) ~= 'GIF' then
				return nil, 'not a valid gif'
			end
			local g = buffer.fromstring(s)
			local sw = readu16(g, 6)
			local sh = readu16(g, 8)
			local packed = readu8(g, 10)
			local off = 13
			local g_off, g_size = nil, 0
			if band(packed, 0x80) ~= 0 then
				g_size = lshift(1, band(packed, 7) + 1)
				g_off = off
				off += g_size * 3
			end

			local frames = {}
			local loop_count = 0
			local delay, disposal, t_idx = 0, 0, nil

			while off < n and #frames < MAX_PARSED_FRAMES do
				local bt = readu8(g, off)
				off += 1
				if bt == 0x3B then
					break
				elseif bt == 0x21 then
					if off >= n then
						break
					end
					local lbl = readu8(g, off)
					off += 1
					if lbl == 0xF9 then
						if off + 5 <= n and readu8(g, off) >= 4 then
							local gp = readu8(g, off + 1)
							disposal = band(rshift(gp, 2), 7)
							delay = readu16(g, off + 2) / 100
							t_idx = (band(gp, 1) == 1) and readu8(g, off + 4) or nil
						end
					elseif lbl == 0xFF then
						if off + 12 <= n and readu8(g, off) == 11 and buffer.readstring(g, off + 1, 11) == 'NETSCAPE2.0' then
							local o2 = off + 12
							if o2 + 4 <= n and readu8(g, o2) >= 3 and readu8(g, o2 + 1) == 1 then
								loop_count = readu16(g, o2 + 2)
							end
						end
					end
					off = skip_blocks(g, n, off)
				elseif bt == 0x2C then
					if off + 9 > n then
						break
					end
					local fl = readu16(g, off)
					local ft = readu16(g, off + 2)
					local fw = readu16(g, off + 4)
					local fh = readu16(g, off + 6)
					local ip = readu8(g, off + 8)
					off += 9
					local ct_off, ct_size = g_off, g_size
					if band(ip, 0x80) ~= 0 then
						ct_size = lshift(1, band(ip, 7) + 1)
						ct_off = off
						off += ct_size * 3
					end
					if off >= n then
						break
					end
					local min_code = readu8(g, off)
					off += 1

					local total = 0
					local p = off
					while p < n do
						local size = readu8(g, p)
						p += 1
						if size == 0 then
							break
						end
						if p + size > n then
							size = n - p
						end
						total += size
						p += size
					end

					local data = buffer.create(total)
					local q, w = off, 0
					while w < total do
						local size = readu8(g, q)
						q += 1
						if size == 0 then
							break
						end
						if q + size > n then
							size = n - q
						end
						bcopy(data, w, g, q, size)
						w += size
						q += size
					end
					off = p

					local d = delay
					if d <= 0.01 then
						d = 0.1
					end
					frames[#frames + 1] = {
						left = fl,
						top = ft,
						width = fw,
						height = fh,
						delay = d,
						disposal = disposal,
						tIdx = t_idx,
						ctOff = ct_off,
						ctSize = ct_size,
						minCode = min_code,
						interlace = band(ip, 0x40) ~= 0,
						data = data,
						dataLen = total,
					}
					delay, disposal, t_idx = 0, 0, nil
				else
					break
				end
			end

			if #frames == 0 then
				return nil, 'gif has no frames'
			end

			if sw == 0 or sh == 0 then
				for _, f in _ipairs(frames) do
					sw = _max(sw, f.left + f.width)
					sh = _max(sh, f.top + f.height)
				end
			end

			return {
				buf = g,
				width = sw,
				height = sh,
				frames = frames,
				loopCount = loop_count,
			}
		end

		local function build_row_map(h)
			local map = _tcreate(h)
			local r = 0
			local passes = { { 0, 8 }, { 4, 8 }, { 2, 4 }, { 1, 2 } }
			for _, pass in _ipairs(passes) do
				local y = pass[1]
				while y < h do
					r += 1
					map[r] = y
					y += pass[2]
				end
			end
			return map
		end

		local function draw_frame(canvas, sw, sh, gbuf, f, dec, dec_len)
			local pal = _tcreate(256, 0)
			local ct_off = f.ctOff
			if ct_off then
				for i = 0, _min(f.ctSize, 256) - 1 do
					local o = ct_off + i * 3
					pal[i + 1] = 0xFF000000 + readu8(gbuf, o) + readu8(gbuf, o + 1) * 256 + readu8(gbuf, o + 2) * 65536
				end
			end
			if f.tIdx then
				pal[f.tIdx + 1] = 0
			end

			local fw, fh, fl, ft = f.width, f.height, f.left, f.top
			local eff_w = _min(fw, sw - fl)
			if eff_w <= 0 then
				return
			end
			local rows = _ceil(dec_len / fw)
			local row_map = f.interlace and build_row_map(fh) or nil

			for r = 0, rows - 1 do
				local y = row_map and row_map[r + 1] or r
				local cy = ft + y
				if cy < sh then
					local s = r * fw
					local e = s + _min(eff_w, dec_len - s)
					local d = (cy * sw + fl) * 4
					while s < e do
						local c = pal[readu8(dec, s) + 1]
						if c ~= 0 then
							writeu32(canvas, d, c)
						end
						s += 1
						d += 4
					end
				end
				pace()
			end
		end

		if on_progress then
			on_progress(0.05, 'Parsing GIF...')
		end
		_wait()

		local gif, parse_err = parse_gif(gif_bytes)
		if not gif then
			error(parse_err, 0)
		end

		local sw, sh = gif.width, gif.height
		if sw < 1 or sh < 1 or sw * sh > MAX_CANVAS_PIXELS then
			error('unsupported gif size', 0)
		end

		local frames = gif.frames
		local total = #frames
		local stride = _max(1, _ceil(total / MAX_FRAMES))
		local scale = _min(1, MAX_DIMENSION / _max(sw, sh))
		local out_w = _max(1, _floor(sw * scale + 0.5))
		local out_h = _max(1, _floor(sh * scale + 0.5))
		local direct = out_w == sw and out_h == sh

		local canvas_bytes = sw * sh * 4
		local canvas = buffer.create(canvas_bytes)
		local saved = nil
		local ctx = new_png_context(out_w, out_h)
		local raw = ctx.raw
		local row_size = ctx.rowSize

		local xmap, ymap
		if not direct then
			xmap = _tcreate(out_w)
			for x = 1, out_w do
				xmap[x] = _min(sw - 1, _floor((x - 0.5) * sw / out_w)) * 4
			end
			ymap = _tcreate(out_h)
			for y = 1, out_h do
				ymap[y] = _min(sh - 1, _floor((y - 0.5) * sh / out_h)) * sw * 4
			end
		end

		local max_area = 1
		for i = 1, total do
			local f = frames[i]
			local a = f.width * f.height
			if a <= MAX_CANVAS_PIXELS and a > max_area then
				max_area = a
			end
		end
		local dec = buffer.create(max_area)

		local urls, delays = {}, {}
		local emitted = 0

		for i = 1, total do
			local f = frames[i]
			local disposal = f.disposal

			if disposal == 3 then
				saved = saved or buffer.create(canvas_bytes)
				bcopy(saved, 0, canvas, 0, canvas_bytes)
			end

			local fw, fh = f.width, f.height
			local area = fw * fh
			if area > 0 and area <= MAX_CANVAS_PIXELS and f.dataLen > 0 then
				local dec_len = lzw_decode(f.data, f.dataLen, f.minCode, dec, area)
				if dec_len > 0 then
					draw_frame(canvas, sw, sh, gif.buf, f, dec, dec_len)
				end
			end
			f.data = nil

			if (i - 1) % stride == 0 then
				emitted += 1
				delays[emitted] = f.delay

				if direct then
					local row_bytes = sw * 4
					for y = 0, out_h - 1 do
						bcopy(raw, y * row_size + 1, canvas, y * row_bytes, row_bytes)
					end
				else
					for y = 0, out_h - 1 do
						local src_row = ymap[y + 1]
						local d = y * row_size + 1
						for x = 1, out_w do
							writeu32(raw, d, readu32(canvas, src_row + xmap[x]))
							d += 4
						end
						pace()
					end
				end

				local png_data = finish_png(ctx)
				local path = folder .. '/frame' .. emitted .. '.png'
				writefile(path, png_data)
				png_data = nil
				local asset = get_asset(path)
				if not asset then
					error('getcustomasset failed', 0)
				end
				urls[emitted] = asset
			else
				delays[emitted] += f.delay
			end

			if disposal == 2 then
				local x0 = _max(0, f.left)
				local x1 = _min(sw, f.left + fw)
				local y0 = _max(0, f.top)
				local y1 = _min(sh, f.top + fh)
				if x1 > x0 then
					for y = y0, y1 - 1 do
						bfill(canvas, (y * sw + x0) * 4, 0, (x1 - x0) * 4)
					end
				end
			elseif disposal == 3 and saved then
				bcopy(canvas, 0, saved, 0, canvas_bytes)
			end

			local pct = i / total
			if on_progress then
				on_progress(pct, string.format('Processing %d%%', _floor(pct * 100)))
			end
			pace()
		end

		_pcall(function()
			writefile(
				folder .. '/info.json',
				http_service:JSONEncode({
					version = CACHE_VERSION,
					frameCount = #urls,
					w = out_w,
					h = out_h,
					loops = gif.loopCount,
					delays = delays,
				})
			)
		end)

		return out_w, out_h, urls, delays, gif.loopCount
	end)

	cleanup_dt()

	if not ok then
		error(result_w, 0)
	end

	return result_w, result_h, result_urls, result_delays, result_loops
end

local function load_cached_gif(folder)
	if not (typeof(readfile) == 'function' and get_asset) then
		return nil
	end
	local info_path = folder .. '/info.json'
	if not file_exists(info_path) then
		return nil
	end

	local ok, info = _pcall(function()
		return http_service:JSONDecode(readfile(info_path))
	end)
	if not ok or _type(info) ~= 'table' or info.version ~= CACHE_VERSION then
		return nil
	end

	local count = info.frameCount
	if _type(count) ~= 'number' or count < 1 or _type(info.delays) ~= 'table' or #info.delays ~= count then
		return nil
	end

	local urls, delays = {}, {}
	for i = 1, count do
		local path = folder .. '/frame' .. i .. '.png'
		if not file_exists(path) then
			return nil
		end
		local ok_asset, asset = _pcall(get_asset, path)
		if not ok_asset or not asset then
			return nil
		end
		urls[i] = asset
		local d = info.delays[i]
		delays[i] = (_type(d) == 'number' and d > 0) and d or 0.1
	end

	return info.w, info.h, urls, delays, _tonumber(info.loops) or 0
end

function library._save(self)
	return true
end

function library.load(self)
	return self._flags
end

function library.close_all_dropdowns(self)
	for _, dropdown in self._active_dropdowns do
		if dropdown._state then
			dropdown:unfold(false)
		end
	end
end

function library._new(runtime_type)
	local is_mobile = user_input_service.TouchEnabled
		and not (user_input_service.KeyboardEnabled and user_input_service.MouseEnabled)

	local self = setmetatable({
		_tab = 0,
		_tabs = {},
		_tab_registry = {},
		_categories = {},
		_category_registry = {},
		_active_tab = nil,
		_layout_order = 0,
		_category_order = 0,
		_type = runtime_type,
		_config = library._config,
		_flags = library._flags,
		_active_dropdowns = {},
		_keybind_entries = {},
		_keybind_list_visible = false,
		_is_mobile = is_mobile,
		_ui_scale = 1,
		_width = DEFAULT_WIDTH,
		_height = DEFAULT_HEIGHT,
		_sidebar_collapsed = false,
		_label_text_size = is_mobile and 15 or 14,
		_small_text_size = is_mobile and 11 or 10,
		_ui_open = true,
		_visibility_token = 0,
		_size_tween = nil,
		_dragging = false,
		_resizing = false,
		_group_dragging = false,
		_slider_dragging = false,
		_drag_start = nil,
		_container_position = nil,
		_ui = nil,
		_container = nil,
		_sidebar = nil,
		_sidebar_tint = nil,
		_logo_title = nil,
		_collapse_button = nil,
		_pin = nil,
		_tabs_container = nil,
		_main_content = nil,
		_sections_viewport = nil,
		_sections = nil,
		_topbar = nil,
		_topbar_title = nil,
		_ui_scale_object = nil,
		_keybind_scale = nil,
		_keybind_list_content = nil,
		_keybind_list_frame = nil,
		_notification_holder = nil,
		_notification_scale = nil,
		_notification_order = 0,
		_apply_scale = nil,
		_bg_holder = nil,
		_bg_dim = nil,
		_bg_active = false,
		_bg_dim_amount = 55,
		_bg_gif_conn = nil,
		_bg_token = 0,
		_bg_store = {
			active = nil,
			dim = 55,
			items = {},
		},
		_bg_groups = {},
	}, library)

	library._current = self

	self:_init()
	self:_init_keybind_list()
	self:_load_bg_store()

	if self._apply_scale then
		self._apply_scale()
	end

	return self
end

library.new = library._new

function library._init(self)
	if typeof(set_thread_identity) == 'function' then
		_pcall(set_thread_identity, 6)
	end

	local _main = create_new('ScreenGui', {
		Name = '_everst',
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = interface_parent,
	})

	if syn and syn.protect_gui then
		_pcall(syn.protect_gui, _main)
	end

	self._ui = _main

	local container = create_new('Frame', {
		BackgroundColor3 = Color3.fromRGB(18, 18, 18),
		AnchorPoint = _new_vector2(0.5, 0.5),
		Position = _new_udim2(0.5, 0, 0.5, 0),
		Size = _new_udim2(0, 0, 0, 0),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Active = true,
		Parent = _main,
	})

	create_round(container, 8)
	create_outline(container, true)

	local bg_holder = create_new('Frame', {
		Name = '_background_holder',
		BackgroundTransparency = 1,
		Size = _udim2_from_scale(1, 1),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 0,
		Parent = container,
	})

	local bg_dim = create_new('Frame', {
		Name = '_background_dim',
		BackgroundColor3 = Color3.fromRGB(14, 14, 14),
		BackgroundTransparency = 1 - (self._bg_dim_amount / 100),
		Size = _udim2_from_scale(1, 1),
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 1,
		Parent = container,
	})

	self._bg_holder = bg_holder
	self._bg_dim = bg_dim

	self._size_tween = _create_tween(
		tween_service,
		container,
		_new_tween_info(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{
			Size = _udim2_from_offset(self._width, self._height),
		}
	)
	self._size_tween:Play()

	local ui_scale = create_new('UIScale', {
		Parent = container,
	})

	self._ui_scale_object = ui_scale

	local notification_holder = create_new('Frame', {
		Name = '_notifications',
		BackgroundTransparency = 1,
		AnchorPoint = _new_vector2(0.5, 1),
		Position = _new_udim2(0.5, 0, 1, -24),
		Size = _new_udim2(0, 560, 0, 180),
		BorderSizePixel = 0,
		ZIndex = 199,
		Parent = _main,
	})

	create_new('UIListLayout', {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = _new_udim(0, 6),
		Parent = notification_holder,
	})

	local notification_scale = create_new('UIScale', {
		Scale = self._ui_scale,
		Parent = notification_holder,
	})

	self._notification_holder = notification_holder
	self._notification_scale = notification_scale

	local apply_scale = function()
		if self._is_mobile then
			local camera = workspace.CurrentCamera
			local viewport_size = camera and camera.ViewportSize or _new_vector2(1280, 720)

			if self._ui and self._ui.AbsoluteSize.Y > 0 then
				viewport_size = self._ui.AbsoluteSize
			end

			local screen_scale = (viewport_size.X / 1400) * 1.35
			self._ui_scale = _clamp(
				_min(screen_scale, (viewport_size.X * 0.94) / self._width, (viewport_size.Y * 0.92) / self._height),
				0.5,
				1.35
			)
		else
			self._ui_scale = 1
		end

		local scale = self._ui_scale
		ui_scale.Scale = scale

		if self._keybind_scale then
			self._keybind_scale.Scale = scale
		end

		if self._notification_scale then
			self._notification_scale.Scale = scale
		end

		_defer(function()
			if self._active_tab and self._pin and self._sidebar then
				local button = self._active_tab._btn
				local pin_y = (button.AbsolutePosition.Y - self._sidebar.AbsolutePosition.Y + button.AbsoluteSize.Y / 2)
						/ self._ui_scale
					- 8
				self._pin.Position = _new_udim2(0, 10, 0, pin_y)
			end
		end)
	end

	self._apply_scale = apply_scale
	apply_scale()

	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
			_defer(apply_scale)
		end)
	end

	local mobile_toggle = create_new('TextButton', {
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
		AnchorPoint = _new_vector2(0, 0),
		Position = _new_udim2(0, 18, 0, 54),
		Size = _new_udim2(0, 44, 0, 44),
		Text = '',
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Visible = self._is_mobile,
		Active = true,
		ZIndex = 100,
		Parent = _main,
	})

	create_pill(mobile_toggle)
	create_outline(mobile_toggle)

	create_label({
		Size = _udim2_from_scale(1, 1),
		Text = 'E',
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 101,
		Parent = mobile_toggle,
	})

	local sidebar = create_new('Frame', {
		BackgroundColor3 = Color3.fromRGB(16, 16, 16),
		BackgroundTransparency = 1,
		Size = _new_udim2(0, SIDEBAR_EXPANDED, 1, 0),
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = container,
	})

	create_divider(sidebar, _new_udim2(1, -1, 0, 48), _new_udim2(0, 1, 1, -48))

	local logo_area = create_new('Frame', {
		BackgroundTransparency = 1,
		Size = _new_udim2(1, 0, 0, 48),
		Active = true,
		ZIndex = 3,
		Parent = sidebar,
	})

	local logo_title = create_label({
		Position = _new_udim2(0, 20, 0, 0),
		Size = _new_udim2(1, -56, 1, 0),
		Text = 'Everst',
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = self._is_mobile and 19 or 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
		Parent = logo_area,
	})

	local collapse_button = create_new('TextButton', {
		BackgroundColor3 = Color3.fromRGB(28, 28, 28),
		AnchorPoint = _new_vector2(1, 0.5),
		Position = _new_udim2(1, -12, 0.5, 0),
		Size = _new_udim2(0, 24, 0, 24),
		FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
		Text = '«',
		TextColor3 = Color3.fromRGB(180, 180, 180),
		TextSize = 14,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = logo_area,
	})

	create_round(collapse_button, 6)
	create_outline(collapse_button)

	collapse_button.MouseEnter:Connect(function()
		_create_tween(tween_service, collapse_button, _new_tween_info(0.15), {
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			TextColor3 = Color3.fromRGB(255, 255, 255),
		}):Play()
	end)

	collapse_button.MouseLeave:Connect(function()
		_create_tween(tween_service, collapse_button, _new_tween_info(0.15), {
			BackgroundColor3 = Color3.fromRGB(28, 28, 28),
			TextColor3 = Color3.fromRGB(180, 180, 180),
		}):Play()
	end)

	create_divider(logo_area, _new_udim2(0, 0, 1, -1), _new_udim2(1, 0, 0, 1))

	local pin = create_new('Frame', {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Position = _new_udim2(0, 10, 0, 0),
		Size = _new_udim2(0, 4, 0, 16),
		BorderSizePixel = 0,
		ZIndex = 50,
		Parent = sidebar,
	})

	create_pill(pin)

	local tabs_container = create_new('ScrollingFrame', {
		BackgroundTransparency = 1,
		Position = _new_udim2(0, 0, 0, 48),
		Size = _new_udim2(1, 0, 1, -48),
		CanvasSize = _new_udim2(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = sidebar,
	})

	tabs_container.ScrollBarThickness = 0
	tabs_container.ScrollBarImageTransparency = 1
	tabs_container.VerticalScrollBarInset = Enum.ScrollBarInset.None
	tabs_container.HorizontalScrollBarInset = Enum.ScrollBarInset.None
	tabs_container.ClipsDescendants = true
	create_padding(tabs_container, 6, 16, 10, 10)
	create_vertical_list(tabs_container, 6)

	tabs_container:GetPropertyChangedSignal('CanvasPosition'):Connect(function()
		if self._active_tab then
			local button = self._active_tab._btn
			local pin_y = (button.AbsolutePosition.Y - self._sidebar.AbsolutePosition.Y + button.AbsoluteSize.Y / 2)
					/ self._ui_scale
				- 8
			pin.Position = _new_udim2(0, 10, 0, pin_y)
		end
	end)

	local main_content = create_new('Frame', {
		BackgroundTransparency = 1,
		Position = _new_udim2(0, SIDEBAR_EXPANDED, 0, 0),
		Size = _new_udim2(1, -SIDEBAR_EXPANDED, 1, 0),
		ZIndex = 2,
		Parent = container,
	})

	local topbar = create_new('Frame', {
		BackgroundTransparency = 1,
		Size = _new_udim2(1, 0, 0, 48),
		Active = true,
		ZIndex = 5,
		Parent = main_content,
	})

	local topbar_title = create_label({
		Position = _new_udim2(0, 16, 0, 0),
		Size = _new_udim2(1, -56, 1, 0),
		Text = '',
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = self._label_text_size,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = 0.15,
		ZIndex = 6,
		Parent = topbar,
	})

	local topbar_grip, set_topbar_grip_color = create_grip(topbar, _new_udim2(1, -16, 0.5, 0), _new_vector2(1, 0.5), 6)

	local topbar_divider = create_divider(topbar, _new_udim2(0, 0, 1, -1), _new_udim2(1, 0, 0, 1))
	topbar_divider.ZIndex = 6

	local sections_viewport = create_new('Frame', {
		BackgroundTransparency = 1,
		Position = _new_udim2(0, 0, 0, 48),
		Size = _new_udim2(1, 0, 1, -48),
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = main_content,
	})

	local sections = create_new('Folder', {
		Parent = sections_viewport,
	})

	function self:set_sidebar_collapsed(collapsed)
		self._sidebar_collapsed = collapsed == true
		local target_w = self._sidebar_collapsed and SIDEBAR_COLLAPSED or SIDEBAR_EXPANDED
		local tween_info = _new_tween_info(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

		_create_tween(tween_service, sidebar, tween_info, {
			Size = _new_udim2(0, target_w, 1, 0),
		}):Play()

		_create_tween(tween_service, main_content, tween_info, {
			Position = _new_udim2(0, target_w, 0, 0),
			Size = _new_udim2(1, -target_w, 1, 0),
		}):Play()

		if self._sidebar_collapsed then
			logo_title.Visible = false
			collapse_button.Text = '»'
			collapse_button.AnchorPoint = _new_vector2(0.5, 0.5)
			_create_tween(tween_service, collapse_button, tween_info, {
				Position = _new_udim2(0.5, 0, 0.5, 0),
			}):Play()
		else
			collapse_button.Text = '«'
			collapse_button.AnchorPoint = _new_vector2(1, 0.5)
			_create_tween(tween_service, collapse_button, tween_info, {
				Position = _new_udim2(1, -12, 0.5, 0),
			}):Play()
			_delay(0.12, function()
				if not self._sidebar_collapsed then
					logo_title.Visible = true
				end
			end)
		end

		for _, category in self._categories do
			category:_apply_collapsed(self._sidebar_collapsed)
		end

		for _, tab_data in self._tabs do
			if tab_data._label then
				tab_data._label.Visible = not self._sidebar_collapsed
			end
		end

		_delay(0.36, function()
			if self._active_tab and self._pin and self._sidebar then
				local button = self._active_tab._btn
				local pin_y = (button.AbsolutePosition.Y - self._sidebar.AbsolutePosition.Y + button.AbsoluteSize.Y / 2)
						/ self._ui_scale
					- 8
				_create_tween(tween_service, self._pin, _new_tween_info(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Position = _new_udim2(0, 10, 0, pin_y),
				}):Play()
			end
		end)
	end

	collapse_button.MouseButton1Click:Connect(function()
		self:set_sidebar_collapsed(not self._sidebar_collapsed)
	end)

	local resizer = create_new('TextButton', {
		BackgroundTransparency = 1,
		AnchorPoint = _new_vector2(1, 1),
		Position = _new_udim2(1, 0, 1, 0),
		Size = _new_udim2(0, 20, 0, 20),
		Text = '',
		AutoButtonColor = false,
		BorderSizePixel = 0,
		ZIndex = 80,
		Parent = container,
	})

	local resize_lines = {}
	local line_configs = {
		{ pos = _new_udim2(1, -5, 1, -5), size = _new_udim2(0, 6, 0, 2) },
		{ pos = _new_udim2(1, -5, 1, -5), size = _new_udim2(0, 2, 0, 6) },
		{ pos = _new_udim2(1, -9, 1, -9), size = _new_udim2(0, 2, 0, 2) },
	}

	for _, cfg in line_configs do
		local dot = create_new('Frame', {
			BackgroundColor3 = Color3.fromRGB(95, 95, 95),
			AnchorPoint = _new_vector2(1, 1),
			Position = cfg.pos,
			Size = cfg.size,
			BorderSizePixel = 0,
			ZIndex = 81,
			Parent = resizer,
		})
		create_pill(dot)
		_insert(resize_lines, dot)
	end

	local function set_resizer_color(color)
		for _, line in resize_lines do
			_create_tween(tween_service, line, _new_tween_info(0.15), {
				BackgroundColor3 = color,
			}):Play()
		end
	end

	resizer.MouseEnter:Connect(function()
		set_resizer_color(Color3.fromRGB(220, 220, 220))
	end)

	resizer.MouseLeave:Connect(function()
		if not self._resizing then
			set_resizer_color(Color3.fromRGB(95, 95, 95))
		end
	end)

	local resize_start = nil
	local resize_start_w = self._width
	local resize_start_h = self._height
	local resize_start_pos = nil
	local resize_ended_conn = nil

	resizer.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			self._resizing = true
			self._dragging = false
			resize_start = input.Position
			resize_start_w = self._width
			resize_start_h = self._height
			resize_start_pos = container.Position
			set_resizer_color(Color3.fromRGB(255, 255, 255))
			self:close_all_dropdowns()

			if resize_ended_conn then
				resize_ended_conn:Disconnect()
			end

			resize_ended_conn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					if resize_ended_conn then
						resize_ended_conn:Disconnect()
						resize_ended_conn = nil
					end
					self._resizing = false
					set_resizer_color(Color3.fromRGB(95, 95, 95))
				end
			end)
		end
	end)

	local input_ended_connection = nil

	local function on_drag(input)
		if self._resizing or self._group_dragging or self._slider_dragging then
			return
		end

		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			self._dragging = true
			self._drag_start = input.Position
			self._container_position = container.Position
			set_topbar_grip_color(Color3.fromRGB(255, 255, 255))
			self:close_all_dropdowns()

			if input_ended_connection then
				input_ended_connection:Disconnect()
				input_ended_connection = nil
			end

			input_ended_connection = input.Changed:Connect(function()
				if input.UserInputState ~= Enum.UserInputState.End then
					return
				end

				if input_ended_connection then
					input_ended_connection:Disconnect()
					input_ended_connection = nil
				end

				self._dragging = false
				set_topbar_grip_color(Color3.fromRGB(100, 100, 100))
			end)
		end
	end

	topbar_grip.MouseEnter:Connect(function()
		set_topbar_grip_color(Color3.fromRGB(220, 220, 220))
	end)

	topbar_grip.MouseLeave:Connect(function()
		if not self._dragging then
			set_topbar_grip_color(Color3.fromRGB(100, 100, 100))
		end
	end)

	topbar.InputBegan:Connect(on_drag)
	topbar_grip.InputBegan:Connect(on_drag)
	logo_area.InputBegan:Connect(on_drag)

	user_input_service.InputChanged:Connect(function(input)
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

			local new_w = _clamp(_floor(resize_start_w + dx + 0.5), MIN_WIDTH, MAX_WIDTH)
			local new_h = _clamp(_floor(resize_start_h + dy + 0.5), MIN_HEIGHT, MAX_HEIGHT)
			local actual_dx = new_w - resize_start_w
			local actual_dy = new_h - resize_start_h

			self._width = new_w
			self._height = new_h
			container.Size = _udim2_from_offset(new_w, new_h)
			container.Position = _new_udim2(
				resize_start_pos.X.Scale,
				resize_start_pos.X.Offset + actual_dx * 0.5,
				resize_start_pos.Y.Scale,
				resize_start_pos.Y.Offset + actual_dy * 0.5
			)
			return
		end

		if self._dragging and self._drag_start then
			local scale = self._ui_scale
			local delta = (input.Position - self._drag_start) / scale

			_create_tween(tween_service, container, _new_tween_info(0.12), {
				Position = _new_udim2(
					self._container_position.X.Scale,
					self._container_position.X.Offset + delta.X,
					self._container_position.Y.Scale,
					self._container_position.Y.Offset + delta.Y
				),
			}):Play()
		end
	end)

	function self:reset_size()
		self._width = DEFAULT_WIDTH
		self._height = DEFAULT_HEIGHT
		container.Position = _new_udim2(0.5, 0, 0.5, 0)

		if self._ui_open then
			_create_tween(
				tween_service,
				container,
				_new_tween_info(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{
					Size = _udim2_from_offset(self._width, self._height),
				}
			):Play()
		end
	end

	function self:change_visibility(state)
		self._ui_open = state
		self._visibility_token += 1
		local token = self._visibility_token

		if self._size_tween then
			self._size_tween:Cancel()
			self._size_tween = nil
		end

		if state then
			container.Visible = true
			self._size_tween = _create_tween(
				tween_service,
				container,
				_new_tween_info(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{
					Size = _udim2_from_offset(self._width, self._height),
				}
			)
			self._size_tween:Play()
		else
			self:close_all_dropdowns()
			self._size_tween = _create_tween(
				tween_service,
				container,
				_new_tween_info(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{
					Size = _new_udim2(0, 0, 0, 0),
				}
			)
			self._size_tween.Completed:Once(function()
				if self._visibility_token == token and not self._ui_open then
					container.Visible = false
				end
			end)
			self._size_tween:Play()
		end
	end

	user_input_service.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end

		local minimize_flag = self._flags.minimize
		local minimize_key = Enum.KeyCode.RightShift

		if minimize_flag then
			local success, result = _pcall(function()
				return Enum.KeyCode[minimize_flag]
			end)

			if success and result then
				minimize_key = result
			end
		end

		if input.KeyCode == minimize_key then
			self:change_visibility(not self._ui_open)
		end
	end)

	mobile_toggle.MouseButton1Click:Connect(function()
		self:change_visibility(not self._ui_open)
	end)

	self._container = container
	self._sidebar = sidebar
	self._logo_title = logo_title
	self._collapse_button = collapse_button
	self._pin = pin
	self._tabs_container = tabs_container
	self._main_content = main_content
	self._sections_viewport = sections_viewport
	self._sections = sections
	self._topbar = topbar
	self._topbar_title = topbar_title
end

function library._stop_bg_playback(self)
	if self._bg_gif_conn then
		self._bg_gif_conn:Disconnect()
		self._bg_gif_conn = nil
	end
	if self._bg_holder then
		for _, child in self._bg_holder:GetChildren() do
			child:Destroy()
		end
	end
end

function library._refresh_bg_surface(self)
	local active = self._bg_active
	if self._bg_dim then
		self._bg_dim.Visible = active
		self._bg_dim.BackgroundTransparency = 1 - (self._bg_dim_amount / 100)
	end
	if self._sidebar then
		self._sidebar.BackgroundTransparency = active and 0.55 or 1
	end
	for _, group_frame in self._bg_groups do
		if group_frame and group_frame.Parent then
			group_frame.BackgroundTransparency = active and 0.22 or 0
		end
	end
end

function library.set_background_dim(self, percent)
	self._bg_dim_amount = _clamp(_tonumber(percent) or 55, 0, 95)
	self._bg_store.dim = self._bg_dim_amount
	self:_refresh_bg_surface()
	self:_save_bg_store()
end

function library.clear_background(self, skip_save)
	self._bg_token += 1
	self:_stop_bg_playback()
	self._bg_active = false
	self._bg_store.active = nil
	self:_refresh_bg_surface()
	if not skip_save then
		self:_save_bg_store()
	end
end

function library._apply_static_bg(self, image_url)
	self:_stop_bg_playback()
	if not self._bg_holder then
		return
	end

	create_new('ImageLabel', {
		BackgroundTransparency = 1,
		Size = _udim2_from_scale(1, 1),
		ScaleType = Enum.ScaleType.Crop,
		Image = image_url,
		ZIndex = 0,
		Parent = self._bg_holder,
	})

	self._bg_active = true
	self:_refresh_bg_surface()
end

function library._apply_gif_bg(self, urls, delays, loops)
	self:_stop_bg_playback()
	if not self._bg_holder or #urls == 0 then
		return
	end

	local count = #urls
	local labels = _tcreate(count)
	local total_duration = 0

	for i = 1, count do
		local lbl = create_new('ImageLabel', {
			Name = 'Frame' .. i,
			Size = _udim2_from_scale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScaleType = Enum.ScaleType.Crop,
			Image = urls[i],
			Visible = i == 1,
			ZIndex = 0,
			Parent = self._bg_holder,
		})
		labels[i] = lbl
		total_duration += delays[i]
	end

	_spawn(function()
		_pcall(function()
			content_provider:PreloadAsync(labels)
		end)
	end)

	local idx = 1
	local elapsed = 0

	self._bg_gif_conn = run_service.RenderStepped:Connect(function(dt)
		if not self._ui_open or not self._container or not self._container.Visible then
			return
		end
		if count <= 1 or total_duration <= 0 then
			return
		end
		elapsed += dt
		if elapsed < delays[idx] then
			return
		end
		if elapsed > total_duration * 2 then
			elapsed = elapsed % total_duration
		end
		local next_idx = idx
		while elapsed >= delays[next_idx] do
			elapsed -= delays[next_idx]
			next_idx += 1
			if next_idx > count then
				next_idx = 1
			end
		end
		if next_idx ~= idx then
			labels[next_idx].Visible = true
			labels[idx].Visible = false
			idx = next_idx
		end
	end)

	self._bg_active = true
	self:_refresh_bg_surface()
end

function library._save_bg_store(self)
	if typeof(writefile) ~= 'function' then
		return
	end
	ensure_folder(BG_ROOT)
	ensure_folder(BG_FOLDER)
	_pcall(function()
		writefile(
			BG_STORE_PATH,
			http_service:JSONEncode({
				version = CACHE_VERSION,
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
		_insert(names, item.name)
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

	self._bg_token += 1
	local token = self._bg_token

	if item.kind == 'asset' and item.asset then
		self:_apply_static_bg(item.asset)
		self._bg_store.active = item.name
		self:_save_bg_store()
		return true
	end

	if (item.kind == 'png' or item.kind == 'jpg') and item.file and file_exists(item.file) and get_asset then
		local ok, asset = _pcall(get_asset, item.file)
		if ok and asset then
			self:_apply_static_bg(asset)
			self._bg_store.active = item.name
			self:_save_bg_store()
			return true
		end
	end

	if item.kind == 'gif' and item.folder then
		local _, _, urls, delays, loops = load_cached_gif(item.folder)
		if urls then
			if self._bg_token == token then
				self:_apply_gif_bg(urls, delays, loops)
				self._bg_store.active = item.name
				self:_save_bg_store()
			end
			return true
		end
	end

	self:notify('Saved background files missing')
	return false
end

function library.delete_saved_background(self, name)
	local item, idx = self:_find_saved_bg(name)
	if not item then
		return false
	end

	table.remove(self._bg_store.items, idx)

	if self._bg_store.active and normalize_name(self._bg_store.active) == normalize_name(item.name) then
		self:clear_background(true)
	end

	if item.file and file_exists(item.file) and typeof(delfile) == 'function' then
		_pcall(delfile, item.file)
	end
	if item.folder and typeof(delfolder) == 'function' then
		_pcall(delfolder, item.folder)
	end

	self:_save_bg_store()
	return true
end

function library._load_bg_store(self)
	if typeof(readfile) ~= 'function' or not file_exists(BG_STORE_PATH) then
		return
	end

	local ok, decoded = _pcall(function()
		return http_service:JSONDecode(readfile(BG_STORE_PATH))
	end)

	if not ok or _type(decoded) ~= 'table' then
		return
	end

	if _type(decoded.dim) == 'number' then
		self._bg_dim_amount = _clamp(decoded.dim, 0, 95)
		self._bg_store.dim = self._bg_dim_amount
	end

	if _type(decoded.items) == 'table' then
		for _, item in decoded.items do
			if _type(item) == 'table' and _type(item.name) == 'string' and _type(item.kind) == 'string' then
				_insert(self._bg_store.items, item)
			end
		end
	end

	if _type(decoded.active) == 'string' then
		self._bg_store.active = decoded.active
		_defer(function()
			self:apply_saved_background(decoded.active)
		end)
	end
end

function library.upload_background(self, source, custom_name, progress_bar, on_complete)
	local trimmed = _tostring(source or ''):gsub('^%s+', ''):gsub('%s+$', '')
	if trimmed == '' then
		self:notify('Enter a PNG, JPEG, GIF URL, file, or asset ID')
		return
	end

	self._bg_token += 1
	local token = self._bg_token

	local function unique_bg_name(preferred)
		local base = _tostring(preferred or ''):gsub('^%s+', ''):gsub('%s+$', '')
		if base == '' then
			base = 'background'
		end
		base = base:sub(1, 36)
		local candidate = base
		local suffix = 2
		while self:_find_saved_bg(candidate) do
			candidate = base:sub(1, 30) .. ' (' .. suffix .. ')'
			suffix += 1
		end
		return candidate
	end

	local function derive_name(raw)
		if custom_name and custom_name:gsub('%s+', '') ~= '' then
			return unique_bg_name(custom_name)
		end
		local tail = raw:match('([^/\\?#]+)%??[^/\\]*$')
		if tail and tail ~= '' then
			return unique_bg_name(tail)
		end
		return unique_bg_name('bg_' .. hash_string(raw):sub(1, 6))
	end

	if trimmed:match('^rbxassetid://%d+$') or trimmed:match('^%d+$') then
		local asset_id = trimmed:match('^%d+$') and ('rbxassetid://' .. trimmed) or trimmed
		local entry_name = unique_bg_name(custom_name and custom_name ~= '' and custom_name or ('asset_' .. asset_id:match('%d+')))
		local item = {
			name = entry_name,
			kind = 'asset',
			asset = asset_id,
			source = trimmed,
		}
		_insert(self._bg_store.items, item)
		self:_apply_static_bg(asset_id)
		self._bg_store.active = entry_name
		self:_save_bg_store()
		self:notify('Background saved: ' .. entry_name)
		if on_complete then
			on_complete(true, entry_name)
		end
		return
	end

	_spawn(function()
		local function report_progress(pct, status_text)
			if self._bg_token ~= token then
				return
			end
			if progress_bar then
				progress_bar:set_visible(true)
				progress_bar:set(pct, status_text)
			end
		end

		local ok, err = _pcall(function()
			ensure_folder(BG_ROOT)
			ensure_folder(BG_FOLDER)

			local raw_bytes = nil

			if file_exists(trimmed) and typeof(readfile) == 'function' then
				raw_bytes = readfile(trimmed)
			elseif file_exists(BG_FOLDER .. '/' .. trimmed) and typeof(readfile) == 'function' then
				raw_bytes = readfile(BG_FOLDER .. '/' .. trimmed)
			elseif trimmed:match('^https?://') then
				raw_bytes = download_url_bytes(trimmed, report_progress)
			else
				error('enter a valid URL, file path, or asset ID', 0)
			end

			if self._bg_token ~= token then
				error('cancelled', 0)
			end

			local kind = detect_image_kind(raw_bytes)
			if not kind then
				error('file is not a valid PNG, JPEG, or GIF', 0)
			end

			local key = hash_string(trimmed .. '|' .. kind .. '|' .. MAX_DIMENSION .. '|' .. MAX_FRAMES)

			if kind == 'png' or kind == 'jpg' then
				if typeof(writefile) ~= 'function' or not get_asset then
					error('writefile and getcustomasset are required', 0)
				end

				local ext = kind == 'png' and '.png' or '.jpg'
				local file_path = BG_FOLDER .. '/' .. key .. ext
				writefile(file_path, raw_bytes)
				raw_bytes = nil

				local asset = get_asset(file_path)
				if not asset then
					error('getcustomasset failed', 0)
				end

				if self._bg_token ~= token then
					error('cancelled', 0)
				end

				local existing = nil
				for _, item in self._bg_store.items do
					if item.file == file_path then
						existing = item
						break
					end
				end

				local entry_name = existing and existing.name or derive_name(trimmed)
				if not existing then
					_insert(self._bg_store.items, {
						name = entry_name,
						kind = kind,
						file = file_path,
						source = trimmed,
					})
				end

				self:_apply_static_bg(asset)
				self._bg_store.active = entry_name
				self:_save_bg_store()

				if progress_bar then
					progress_bar:set_visible(false)
				end
				self:notify('Background saved: ' .. entry_name)
				if on_complete then
					on_complete(true, entry_name)
				end
				return
			end

			local folder = BG_FOLDER .. '/' .. key
			ensure_folder(folder)

			local cw, ch, curls, cdelays, cloops = load_cached_gif(folder)
			if not cw then
				cw, ch, curls, cdelays, cloops = decode_and_cache_gif(
					raw_bytes,
					folder,
					function()
						return self._bg_token ~= token
					end,
					report_progress
				)
			end
			raw_bytes = nil

			if self._bg_token ~= token then
				error('cancelled', 0)
			end

			local existing = nil
			for _, item in self._bg_store.items do
				if item.folder == folder then
					existing = item
					break
				end
			end

			local entry_name = existing and existing.name or derive_name(trimmed)
			if not existing then
				_insert(self._bg_store.items, {
					name = entry_name,
					kind = 'gif',
					folder = folder,
					source = trimmed,
				})
			end

			self:_apply_gif_bg(curls, cdelays, cloops)
			self._bg_store.active = entry_name
			self:_save_bg_store()

			report_progress(1, 'Ready')
			_delay(1.2, function()
				if self._bg_token == token and progress_bar then
					progress_bar:set_visible(false)
				end
			end)

			self:notify('GIF background saved: ' .. entry_name)
			if on_complete then
				on_complete(true, entry_name)
			end
		end)

		if not ok then
			if err ~= 'cancelled' then
				if progress_bar then
					progress_bar:set_visible(false)
				end
				self:notify('Upload failed: ' .. _tostring(err))
				if on_complete then
					on_complete(false)
				end
			end
		end
	end)
end

function library.update_tabs(self, tab)
	if self._topbar_title then
		self._topbar_title.Text = tab._title or ''
	end

	for _, tab_data in self._tabs do
		local btn = tab_data._btn
		local tab_icon = btn:FindFirstChildWhichIsA('ImageLabel')
		local tab_label = tab_data._label

		if tab_data == tab then
			tab_data._active = true

			_create_tween(tween_service, btn, _new_tween_info(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0,
			}):Play()

			if tab_label then
				_create_tween(
					tween_service,
					tab_label,
					_new_tween_info(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{
						TextColor3 = Color3.fromRGB(255, 255, 255),
					}
				):Play()
			end

			if tab_icon then
				_create_tween(
					tween_service,
					tab_icon,
					_new_tween_info(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{
						ImageColor3 = Color3.fromRGB(255, 255, 255),
					}
				):Play()
			end

			local target_y = (btn.AbsolutePosition.Y - self._sidebar.AbsolutePosition.Y + btn.AbsoluteSize.Y / 2)
					/ self._ui_scale
				- 8

			if self._pin.BackgroundTransparency == 1 then
				self._pin.Position = _new_udim2(0, 10, 0, target_y)
				self._pin.BackgroundTransparency = 0
			else
				_create_tween(
					tween_service,
					self._pin,
					_new_tween_info(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{
						Position = _new_udim2(0, 10, 0, target_y),
					}
				):Play()
			end

			continue
		end

		if tab_data._active then
			tab_data._active = false

			_create_tween(tween_service, btn, _new_tween_info(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				BackgroundTransparency = 1,
			}):Play()

			if tab_label then
				_create_tween(
					tween_service,
					tab_label,
					_new_tween_info(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{
						TextColor3 = Color3.fromRGB(180, 180, 180),
					}
				):Play()
			end

			if tab_icon then
				_create_tween(
					tween_service,
					tab_icon,
					_new_tween_info(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{
						ImageColor3 = Color3.fromRGB(180, 180, 180),
					}
				):Play()
			end
		end
	end
end

function library.update_sections(self, left_section, right_section)
	for _, object in self._sections:GetChildren() do
		if object == left_section or object == right_section then
			object.Visible = true
			continue
		end

		object.Visible = false
	end
end

function library._find_category(self, name)
	local runtime = resolve_runtime(self)
	if not runtime then
		return nil
	end

	local matches = runtime._category_registry[normalize_name(name)]
	return matches and matches[1] or nil
end

function library._find_tab(self, name, category_name)
	local runtime = resolve_runtime(self)
	if not runtime then
		return nil
	end

	local matches = runtime._tab_registry[normalize_name(name)]
	if not matches then
		return nil
	end

	if category_name then
		local normalized_category = normalize_name(category_name)
		for _, tab_manager in matches do
			if normalize_name(tab_manager._category) == normalized_category then
				return tab_manager
			end
		end
		return nil
	end

	return matches[1]
end

function library._find_group(self, tab_manager, name, side)
	if not tab_manager then
		return nil
	end

	local matches = tab_manager._group_registry[normalize_name(name)]
	if not matches then
		return nil
	end

	if side then
		for _, group_manager in matches do
			if group_manager._side == normalize_name(side) then
				return group_manager
			end
		end
		return nil
	end

	if #matches == 1 then
		return matches[1]
	end

	return nil
end

function library.create_category(self, name)
	local runtime = self

	self._category_order = (self._category_order or 0) + 1
	self._layout_order = 0

	local category_index = self._category_order
	local base_order = category_index * 1000
	local expanded_height = category_index == 1 and 19 or 26

	local category_holder = create_new('Frame', {
		Name = name,
		BackgroundTransparency = 1,
		LayoutOrder = base_order,
		Size = _new_udim2(1, 0, 0, expanded_height),
		Parent = self._tabs_container,
	})

	local category_label = create_label({
		Size = _udim2_from_scale(1, 1),
		Text = name:upper(),
		TextSize = runtime._small_text_size + 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		TextTransparency = 0.2,
		Parent = category_holder,
	})

	create_padding(category_label, 0, 4, 10, 0)

	local category_line = create_new('Frame', {
		BackgroundColor3 = Color3.fromRGB(45, 45, 45),
		AnchorPoint = _new_vector2(0.5, 0.5),
		Position = _new_udim2(0.5, 0, 0.5, 0),
		Size = _new_udim2(0, 20, 0, 1),
		BorderSizePixel = 0,
		Visible = false,
		Parent = category_holder,
	})

	local category_manager = {
		_holder = category_holder,
		_label = category_label,
		_line = category_line,
		_name = name,
		_base_order = base_order,
		_expanded_height = expanded_height,
		_is_first = category_index == 1,
		_tab_count = 0,
	}

	function category_manager:_apply_collapsed(collapsed)
		if collapsed then
			self._label.Visible = false
			self._line.Visible = not self._is_first
			self._holder.Size = _new_udim2(1, 0, 0, self._is_first and 2 or 8)
		else
			self._line.Visible = false
			self._label.Visible = true
			self._holder.Size = _new_udim2(1, 0, 0, self._expanded_height)
		end
	end

	category_manager:_apply_collapsed(self._sidebar_collapsed)

	function category_manager:create_tab(title, icon)
		self._tab_count += 1
		return runtime:create_tab(title, icon, self._base_order + self._tab_count, self._name)
	end

	_insert(self._categories, category_manager)

	local category_name = normalize_name(name)
	self._category_registry[category_name] = self._category_registry[category_name] or {}
	_insert(self._category_registry[category_name], category_manager)

	return category_manager
end

function library.create_tab(self, title, icon, layout_order, category_name)
	local tab_manager = {
		_title = title,
		_category = category_name,
		_groups = {},
		_group_registry = {},
	}
	local runtime = self

	icon = icon or 'rbxassetid://10709812159'
	if _type(icon) == 'number' then
		icon = `rbxassetid://{icon}`
	elseif _type(icon) == 'string' and icon:match('^%d+$') then
		icon = `rbxassetid://{icon}`
	end

	if not layout_order then
		self._layout_order += 1
		layout_order = self._category_order * 1000 + self._layout_order
	end

	local first_tab = #self._tabs == 0

	local tab_button = create_new('TextButton', {
		Name = title,
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 1,
		LayoutOrder = layout_order,
		Size = _new_udim2(1, 0, 0, 32),
		Text = '',
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Parent = self._tabs_container,
	})

	create_round(tab_button, 6)

	create_new('ImageLabel', {
		BackgroundTransparency = 1,
		AnchorPoint = _new_vector2(0, 0.5),
		Position = _new_udim2(0, 10, 0.5, 0),
		Size = _new_udim2(0, 16, 0, 16),
		Image = icon,
		ImageColor3 = Color3.fromRGB(180, 180, 180),
		Parent = tab_button,
	})

	local tab_label = create_label({
		Position = _new_udim2(0, 34, 0, 0),
		Size = _new_udim2(1, -44, 1, 0),
		Text = title,
		TextSize = runtime._label_text_size,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Visible = not runtime._sidebar_collapsed,
		Parent = tab_button,
	})

	local function create_section(position, size)
		local section = create_new('ScrollingFrame', {
			BackgroundTransparency = 1,
			Position = position,
			Size = size,
			CanvasSize = _new_udim2(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BorderSizePixel = 0,
			Visible = false,
			Parent = self._sections,
		})

		section.ScrollBarThickness = 0
		section.ScrollBarImageTransparency = 1
		section.VerticalScrollBarInset = Enum.ScrollBarInset.None
		section.HorizontalScrollBarInset = Enum.ScrollBarInset.None
		section.ClipsDescendants = true
		create_padding(section, 16, 16, 2, 2)
		create_vertical_list(section, 12)

		return section
	end

	local left_section = create_section(_new_udim2(0, 12, 0, 0), _new_udim2(0.5, -16, 1, 0))
	local right_section = create_section(_new_udim2(0.5, 4, 0, 0), _new_udim2(0.5, -16, 1, 0))

	local tab_data = {
		_btn = tab_button,
		_label = tab_label,
		_left = left_section,
		_right = right_section,
		_active = false,
		_enabled = true,
		_title = title,
		_category = category_name,
		_manager = tab_manager,
	}

	tab_manager._data = tab_data
	_insert(self._tabs, tab_data)
	self._tab += 1

	if first_tab then
		self:update_tabs(tab_data)
		self:update_sections(left_section, right_section)
		self._active_tab = tab_data
	end

	tab_button.MouseButton1Click:Connect(function()
		if not tab_data._enabled then
			return
		end

		self._active_tab = tab_data
		self:update_tabs(tab_data)
		self:update_sections(left_section, right_section)
	end)

	function tab_manager:set_enabled(state)
		local enabled = state == true
		tab_data._enabled = enabled
		tab_button.Active = enabled
		tab_button.Selectable = enabled

		local tab_icon = tab_button:FindFirstChildWhichIsA('ImageLabel')

		if tab_icon then
			tab_icon.ImageTransparency = enabled and 0 or 0.65
		end

		if tab_label then
			tab_label.TextTransparency = enabled and 0 or 0.65
		end

		if not enabled and runtime._active_tab == tab_data then
			for _, candidate in runtime._tabs do
				if candidate ~= tab_data and candidate._enabled then
					runtime._active_tab = candidate
					runtime:update_tabs(candidate)
					runtime:update_sections(candidate._left, candidate._right)
					break
				end
			end
		end
	end

	function tab_manager:is_enabled()
		return tab_data._enabled
	end

	local function get_sorted_groups(section)
		local groups = {}
		for _, child in section:GetChildren() do
			if child:IsA('Frame') then
				_insert(groups, child)
			end
		end
		_sort(groups, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		return groups
	end

	local function normalize_section_orders(section)
		local groups = get_sorted_groups(section)
		for index, frame in groups do
			frame.LayoutOrder = index
		end
	end

	function tab_manager:create_group(group_title, side)
		local group_values = {}

		if _type(group_title) == 'table' then
			group_values = group_title
		else
			group_values.title = group_title
			group_values.side = side
		end

		group_values.title = group_values.title or 'group'
		group_values.side = (group_values.side == 'right') and 'right' or 'left'

		local parent_section = group_values.side == 'left' and left_section or right_section
		local initial_order = #get_sorted_groups(parent_section) + 1

		local group_manager = {
			_size = 0,
			_order = 0,
			_title = group_values.title,
			_side = group_values.side,
			_tab = tab_manager,
		}

		local function next_row_order()
			group_manager._order += 1
			return group_manager._order
		end

		local group_frame = create_new('Frame', {
			BackgroundColor3 = Color3.fromRGB(22, 22, 22),
			BackgroundTransparency = runtime._bg_active and 0.22 or 0,
			LayoutOrder = initial_order,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = _new_udim2(1, 0, 0, 0),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Parent = parent_section,
		})

		group_manager._frame = group_frame
		_insert(runtime._bg_groups, group_frame)

		create_round(group_frame, 8)
		local group_outline = create_outline(group_frame, true)
		create_padding(group_frame, 12, 12, 12, 12)
		create_vertical_list(group_frame, 8)

		local group_header = create_new('Frame', {
			BackgroundTransparency = 1,
			LayoutOrder = 0,
			Size = _new_udim2(1, 0, 0, 14),
			Parent = group_frame,
		})

		create_label({
			Size = _new_udim2(1, -24, 1, 0),
			Text = _tostring(group_values.title):upper(),
			TextSize = runtime._small_text_size + 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTransparency = 0.2,
			Parent = group_header,
		})

		local group_grip, set_group_grip_color = create_grip(group_header, _new_udim2(1, 0, 0.5, 0), _new_vector2(1, 0.5), 4)

		local group_drag_active = false
		local group_end_conn = nil
		local group_move_conn = nil

		group_grip.MouseEnter:Connect(function()
			set_group_grip_color(Color3.fromRGB(220, 220, 220))
		end)

		group_grip.MouseLeave:Connect(function()
			if not group_drag_active then
				set_group_grip_color(Color3.fromRGB(100, 100, 100))
			end
		end)

		local function update_group_placement(pointer_pos)
			local viewport = runtime._sections_viewport
			if not viewport then
				return
			end

			local mid_x = viewport.AbsolutePosition.X + viewport.AbsoluteSize.X * 0.5
			local target_section = pointer_pos.X < mid_x and left_section or right_section

			if group_frame.Parent ~= target_section then
				local old_section = group_frame.Parent
				group_frame.Parent = target_section
				group_manager._side = target_section == left_section and 'left' or 'right'
				if old_section then
					normalize_section_orders(old_section)
				end
			end

			local siblings = {}
			for _, child in get_sorted_groups(target_section) do
				if child ~= group_frame then
					_insert(siblings, child)
				end
			end

			local insert_index = 1
			for _, sibling in siblings do
				local sibling_mid_y = sibling.AbsolutePosition.Y + sibling.AbsoluteSize.Y * 0.5
				if pointer_pos.Y > sibling_mid_y then
					insert_index += 1
				end
			end

			_insert(siblings, insert_index, group_frame)
			for index, frame in siblings do
				frame.LayoutOrder = index
			end
		end

		group_grip.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				group_drag_active = true
				runtime._group_dragging = true
				set_group_grip_color(Color3.fromRGB(255, 255, 255))
				_create_tween(tween_service, group_outline, _new_tween_info(0.15), {
					Color = Color3.fromRGB(110, 110, 110),
				}):Play()

				if group_move_conn then
					group_move_conn:Disconnect()
				end

				group_move_conn = user_input_service.InputChanged:Connect(function(move_input)
					if
						group_drag_active
						and (
							move_input.UserInputType == Enum.UserInputType.MouseMovement
							or move_input.UserInputType == Enum.UserInputType.Touch
						)
					then
						update_group_placement(move_input.Position)
					end
				end)

				if group_end_conn then
					group_end_conn:Disconnect()
				end

				group_end_conn = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						group_drag_active = false
						runtime._group_dragging = false
						set_group_grip_color(Color3.fromRGB(100, 100, 100))
						_create_tween(tween_service, group_outline, _new_tween_info(0.2), {
							Color = Color3.fromRGB(35, 35, 35),
						}):Play()

						if group_move_conn then
							group_move_conn:Disconnect()
							group_move_conn = nil
						end
						if group_end_conn then
							group_end_conn:Disconnect()
							group_end_conn = nil
						end
					end
				end)
			end
		end)

		function group_manager:create_toggle(flag, _values)
			if _type(flag) == 'table' then
				_values = flag
				flag = _values.flag
			end

			_values = _values or {}
			local state = _values.default or _values.Default or false

			local toggle_frame = create_new('Frame', {
				BackgroundTransparency = 1,
				LayoutOrder = next_row_order(),
				Size = _new_udim2(1, 0, 0, 24),
				Parent = group_frame,
			})

			local toggle_label = create_label({
				Size = _new_udim2(1, -40, 1, 0),
				Text = _values.title or 'Toggle',
				TextSize = runtime._label_text_size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = toggle_frame,
			})

			local switch_background = create_new('Frame', {
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				AnchorPoint = _new_vector2(1, 0.5),
				Position = _new_udim2(1, 0, 0.5, 0),
				Size = _new_udim2(0, 30, 0, 18),
				BorderSizePixel = 0,
				Parent = toggle_frame,
			})

			create_pill(switch_background)

			local knob_inset = (18 - 12) / 2
			local knob_off = _new_udim2(0, knob_inset, 0.5, 0)
			local knob_on = _new_udim2(0, 30 - 12 - knob_inset, 0.5, 0)

			local switch_knob = create_new('Frame', {
				BackgroundColor3 = Color3.fromRGB(180, 180, 180),
				AnchorPoint = _new_vector2(0, 0.5),
				Position = knob_off,
				Size = _new_udim2(0, 12, 0, 12),
				BorderSizePixel = 0,
				Parent = switch_background,
			})

			create_pill(switch_knob)

			local toggle_tween_info = _new_tween_info(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			local toggle_tweens = {}

			local function cancel_toggle_tweens()
				for _, tween in toggle_tweens do
					tween:Cancel()
				end
				_clear(toggle_tweens)
			end

			local function play_toggle_tween(instance, properties)
				local tween = _create_tween(tween_service, instance, toggle_tween_info, properties)
				_insert(toggle_tweens, tween)
				tween:Play()
			end

			local function apply_toggle(animate)
				local bg_color = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(40, 40, 40)
				local knob_color = state and Color3.fromRGB(18, 18, 18) or Color3.fromRGB(180, 180, 180)
				local knob_pos = state and knob_on or knob_off
				local label_color = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)

				cancel_toggle_tweens()

				if animate then
					play_toggle_tween(switch_background, { BackgroundColor3 = bg_color })
					play_toggle_tween(switch_knob, { Position = knob_pos, BackgroundColor3 = knob_color })
					play_toggle_tween(toggle_label, { TextColor3 = label_color })
				else
					switch_background.BackgroundColor3 = bg_color
					switch_knob.Position = knob_pos
					switch_knob.BackgroundColor3 = knob_color
					toggle_label.TextColor3 = label_color
				end
			end

			local function set_toggle(value, animate)
				state = value
				apply_toggle(animate)

				if flag then
					runtime._flags[flag] = state
					runtime:_save()
				end

				if _values.callback then
					_values.callback(state)
				end

				if _values.is_keybind then
					runtime:update_keybind_list()
				end
			end

			local click_button = create_new('TextButton', {
				BackgroundTransparency = 1,
				Size = _udim2_from_scale(1, 1),
				Text = '',
				Parent = toggle_frame,
			})

			if _values.is_keybind and not runtime._is_mobile then
				local bind_text_size = runtime._label_text_size
				local bind_right = 34

				toggle_label.Size = _new_udim2(1, -(bind_right + 24 + 8), 1, 0)

				local bind_button = create_new('TextButton', {
					BackgroundColor3 = Color3.fromRGB(40, 40, 40),
					AnchorPoint = _new_vector2(1, 0.5),
					Position = _new_udim2(1, -bind_right, 0.5, 0),
					Size = _new_udim2(0, 24, 0, 22),
					Text = '',
					AutoButtonColor = false,
					BorderSizePixel = 0,
					ZIndex = 2,
					Parent = toggle_frame,
				})

				create_round(bind_button, 6)

				local bind_icon = create_new('ImageLabel', {
					BackgroundTransparency = 1,
					AnchorPoint = _new_vector2(0.5, 0.5),
					Position = _new_udim2(0.5, 0, 0.5, 0),
					Size = _new_udim2(0, 14, 0, 14),
					Image = 'rbxassetid://10709818996',
					ImageColor3 = Color3.fromRGB(180, 180, 180),
					Parent = bind_button,
				})

				local bind_text = create_label({
					Size = _udim2_from_scale(1, 1),
					Text = '',
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = bind_text_size,
					Visible = false,
					Parent = bind_button,
				})

				local function fit_bind_button(key_name)
					local text_width = text_service:GetTextSize(
						key_name,
						bind_text_size,
						Enum.Font.GothamSemibold,
						_new_vector2(1000, 22)
					).X
					local bind_width = _max(24, text_width + 12)

					bind_button.Size = _new_udim2(0, bind_width, 0, 22)
					toggle_label.Size = _new_udim2(1, -(bind_right + bind_width + 8), 1, 0)
				end

				local bind_flag = flag and `{flag}_key` or nil
				local key = nil
				local picking = false

				if bind_flag and runtime._flags[bind_flag] ~= nil then
					local success, result = _pcall(function()
						return Enum.KeyCode[runtime._flags[bind_flag]]
					end)

					if success and result then
						key = result
						bind_icon.Visible = false
						bind_text.Visible = true
						bind_text.Text = key.Name
						fit_bind_button(key.Name)
					end
				end

				bind_button.MouseButton1Click:Connect(function()
					picking = true
					bind_icon.Visible = false
					bind_text.Visible = true
					bind_text.Text = '...'
					bind_button.Size = _new_udim2(0, 24, 0, 22)
					toggle_label.Size = _new_udim2(1, -(bind_right + 24 + 8), 1, 0)

					_create_tween(tween_service, bind_button, _new_tween_info(0.2), {
						BackgroundColor3 = Color3.fromRGB(55, 55, 55),
					}):Play()
				end)

				user_input_service.InputBegan:Connect(function(input, processed)
					if picking then
						if
							input.UserInputType == Enum.UserInputType.Keyboard
							and input.KeyCode ~= Enum.KeyCode.Unknown
						then
							key = input.KeyCode
							bind_text.Text = key.Name
							picking = false
							fit_bind_button(key.Name)

							_create_tween(tween_service, bind_button, _new_tween_info(0.2), {
								BackgroundColor3 = Color3.fromRGB(40, 40, 40),
							}):Play()

							if bind_flag then
								runtime._flags[bind_flag] = key.Name
								runtime:_save()
							end

							for _, entry in runtime._keybind_entries do
								if entry.flag == flag then
									entry.key_name = key.Name
									break
								end
							end

							runtime:update_keybind_list()
						end
					elseif not processed and key and input.KeyCode == key then
						set_toggle(not state, true)
					end
				end)
			end

			if flag and runtime._flags[flag] ~= nil then
				state = runtime._flags[flag]
			elseif flag then
				runtime._flags[flag] = state
			end

			apply_toggle(false)

			if _values.is_keybind and not runtime._is_mobile then
				local bind_flag = flag and `{flag}_key` or nil
				local initial_key_name = nil

				if bind_flag and runtime._flags[bind_flag] ~= nil then
					local success, result = _pcall(function()
						return Enum.KeyCode[runtime._flags[bind_flag]]
					end)

					if success and result then
						initial_key_name = result.Name
					end
				end

				_insert(runtime._keybind_entries, {
					flag = flag,
					title = _values.title or 'Toggle',
					key_name = initial_key_name,
				})

				runtime:update_keybind_list()
			end

			click_button.MouseButton1Click:Connect(function()
				set_toggle(not state, true)
			end)

			local toggle_manager = {}

			function toggle_manager:set_value(value)
				set_toggle(value == true, true)
			end

			function toggle_manager:get_value()
				return state
			end

			return toggle_manager
		end

		function group_manager:create_slider(flag, _values)
			if _type(flag) == 'table' then
				_values = flag
				flag = _values.flag
			end

			_values = _values or {}
			local minimum = _values.minimum or 0
			local maximum = _values.maximum or 100
			local default = _values.default ~= nil and _values.default or minimum

			if flag and runtime._flags[flag] ~= nil then
				default = runtime._flags[flag]
			elseif flag then
				runtime._flags[flag] = default
			end

			local value = _clamp(default, minimum, maximum)

			local slider_frame = create_new('Frame', {
				BackgroundTransparency = 1,
				LayoutOrder = next_row_order(),
				Size = _new_udim2(1, 0, 0, 30),
				Parent = group_frame,
			})

			create_label({
				Size = _new_udim2(1, -56, 0, 16),
				Text = _values.title or 'Slider',
				TextSize = runtime._label_text_size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = slider_frame,
			})

			local value_label = create_label({
				AnchorPoint = _new_vector2(1, 0),
				Position = _new_udim2(1, 0, 0, 0),
				Size = _new_udim2(0, 48, 0, 16),
				Text = _tostring(value),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = runtime._label_text_size,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = slider_frame,
			})

			local track_button = create_new('TextButton', {
				BackgroundTransparency = 1,
				Position = _new_udim2(0, 0, 0, 16),
				Size = _new_udim2(1, 0, 1, -16),
				Text = '',
				AutoButtonColor = false,
				BorderSizePixel = 0,
				Parent = slider_frame,
			})

			local track_background = create_new('Frame', {
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				AnchorPoint = _new_vector2(0, 0.5),
				Position = _new_udim2(0, 0, 0.5, 0),
				Size = _new_udim2(1, 0, 0, 6),
				BorderSizePixel = 0,
				Parent = track_button,
			})

			create_pill(track_background)

			local track_fill = create_new('Frame', {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Size = _new_udim2(_clamp((value - minimum) / (maximum - minimum), 0, 1), 0, 1, 0),
				BorderSizePixel = 0,
				Parent = track_background,
			})

			create_pill(track_fill)

			local knob = create_new('Frame', {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				AnchorPoint = _new_vector2(0.5, 0.5),
				Position = _new_udim2(1, 0, 0.5, 0),
				Size = _new_udim2(0, 12, 0, 12),
				BorderSizePixel = 0,
				Parent = track_fill,
			})

			create_pill(knob)

			local slider_dragging = false

			local function update_slider(input)
				local width = track_background.AbsoluteSize.X
				if width <= 0 then
					return
				end

				local position = _clamp((input.Position.X - track_background.AbsolutePosition.X) / width, 0, 1)
				local raw_value = minimum + ((maximum - minimum) * position)

				value = round_number(raw_value, _values.rounding and 1 or 0)
				value_label.Text = _tostring(value)

				_create_tween(tween_service, track_fill, _new_tween_info(0.08), {
					Size = _new_udim2(position, 0, 1, 0),
				}):Play()

				if flag then
					runtime._flags[flag] = value
					runtime:_save()
				end

				if _values.callback then
					_values.callback(value)
				end
			end

			track_button.InputBegan:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					slider_dragging = true
					runtime._slider_dragging = true
					update_slider(input)
				end
			end)

			user_input_service.InputEnded:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					if slider_dragging then
						slider_dragging = false
						runtime._slider_dragging = false
					end
				end
			end)

			user_input_service.InputChanged:Connect(function(input)
				if
					slider_dragging
					and (
						input.UserInputType == Enum.UserInputType.MouseMovement
						or input.UserInputType == Enum.UserInputType.Touch
					)
				then
					update_slider(input)
				end
			end)

			local slider_manager = {}

			function slider_manager:set_value(new_value)
				value = _clamp(new_value, minimum, maximum)
				local position = _clamp((value - minimum) / (maximum - minimum), 0, 1)
				value_label.Text = _tostring(value)
				track_fill.Size = _new_udim2(position, 0, 1, 0)

				if flag then
					runtime._flags[flag] = value
					runtime:_save()
				end

				if _values.callback then
					_values.callback(value)
				end
			end

			function slider_manager:get_value()
				return value
			end

			return slider_manager
		end

		function group_manager:create_progress(_values)
			_values = _values or {}

			local progress_frame = create_new('Frame', {
				BackgroundTransparency = 1,
				LayoutOrder = next_row_order(),
				Size = _new_udim2(1, 0, 0, 26),
				Visible = _values.visible == true,
				Parent = group_frame,
			})

			local status_label = create_label({
				Size = _new_udim2(1, -48, 0, 14),
				Text = _values.title or 'Loading...',
				TextSize = runtime._small_text_size + 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = progress_frame,
			})

			local pct_label = create_label({
				AnchorPoint = _new_vector2(1, 0),
				Position = _new_udim2(1, 0, 0, 0),
				Size = _new_udim2(0, 44, 0, 14),
				Text = '0%',
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = runtime._small_text_size + 1,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = progress_frame,
			})

			local track = create_new('Frame', {
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				Position = _new_udim2(0, 0, 0, 18),
				Size = _new_udim2(1, 0, 0, 6),
				BorderSizePixel = 0,
				Parent = progress_frame,
			})

			create_pill(track)

			local fill = create_new('Frame', {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Size = _new_udim2(0, 0, 1, 0),
				BorderSizePixel = 0,
				Parent = track,
			})

			create_pill(fill)

			local progress_manager = {}

			function progress_manager:set(fraction, text)
				local clamped = _clamp(_tonumber(fraction) or 0, 0, 1)
				if text then
					status_label.Text = _tostring(text)
				end
				pct_label.Text = string.format('%d%%', _floor(clamped * 100 + 0.5))
				_create_tween(tween_service, fill, _new_tween_info(0.1), {
					Size = _new_udim2(clamped, 0, 1, 0),
				}):Play()
			end

			function progress_manager:set_visible(state)
				progress_frame.Visible = state == true
			end

			return progress_manager
		end

		function group_manager:create_button(flag, _values)
			if _type(flag) == 'table' then
				_values = flag
			end

			_values = _values or {}

			local button = create_new('TextButton', {
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				LayoutOrder = next_row_order(),
				Size = _new_udim2(1, 0, 0, 26),
				FontFace = Font.new(
					'rbxasset://fonts/families/GothamSSm.json',
					Enum.FontWeight.SemiBold,
					Enum.FontStyle.Normal
				),
				Text = _values.title or 'Button',
				TextColor3 = Color3.fromRGB(180, 180, 180),
				TextSize = runtime._label_text_size,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				Parent = group_frame,
			})

			create_round(button, 6)

			button.MouseEnter:Connect(function()
				_create_tween(tween_service, button, _new_tween_info(0.15), {
					TextColor3 = Color3.fromRGB(255, 255, 255),
				}):Play()
			end)

			button.MouseLeave:Connect(function()
				_create_tween(tween_service, button, _new_tween_info(0.15), {
					TextColor3 = Color3.fromRGB(180, 180, 180),
				}):Play()
			end)

			button.MouseButton1Click:Connect(function()
				button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)

				_create_tween(tween_service, button, _new_tween_info(0.2), {
					BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				}):Play()

				if _values.callback then
					_values.callback()
				end
			end)
		end

		function group_manager:create_textbox(flag, _values)
			if _type(flag) == 'table' then
				_values = flag
				flag = _values.flag
			end

			_values = _values or {}

			local box_height = _max(24, _tonumber(_values.height) or 26)
			local raw_value = _tostring(_values.default or '')
			local textbox_frame = create_new('Frame', {
				BackgroundTransparency = 1,
				LayoutOrder = next_row_order(),
				Size = _new_udim2(1, 0, 0, box_height + 20),
				Visible = _values.visible ~= false,
				Parent = group_frame,
			})

			create_label({
				Size = _new_udim2(1, 0, 0, 16),
				Text = _values.title or 'Text',
				TextSize = runtime._label_text_size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = textbox_frame,
			})

			local textbox = create_new('TextBox', {
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				Position = _new_udim2(0, 0, 0, 20),
				Size = _new_udim2(1, 0, 0, box_height),
				ClearTextOnFocus = false,
				MultiLine = _values.multi_line == true,
				PlaceholderText = _values.placeholder or '...',
				PlaceholderColor3 = Color3.fromRGB(130, 130, 130),
				Text = raw_value,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = runtime._label_text_size,
				TextTransparency = 0.1,
				TextWrapped = _values.multi_line == true,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = _values.multi_line and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
				FontFace = Font.new(
					'rbxasset://fonts/families/GothamSSm.json',
					Enum.FontWeight.SemiBold,
					Enum.FontStyle.Normal
				),
				BorderSizePixel = 0,
				Parent = textbox_frame,
			})

			create_round(textbox, 6)
			create_padding(textbox, _values.multi_line and 6 or 0, _values.multi_line and 6 or 0, 10, 10)

			local changing_text = false
			local rendered_value = raw_value

			local function render_value()
				local displayed_value = raw_value

				if _values.display then
					local display_success, transformed = _pcall(_values.display, raw_value)
					if display_success and transformed ~= nil then
						displayed_value = _tostring(transformed)
					end
				end

				rendered_value = displayed_value
				changing_text = true
				textbox.Text = displayed_value
				changing_text = false
			end

			textbox:GetPropertyChangedSignal('Text'):Connect(function()
				if changing_text or textbox.Text == rendered_value then
					return
				end

				raw_value = textbox.Text
				render_value()
			end)

			render_value()

			textbox.FocusLost:Connect(function(enter_pressed)
				if flag then
					runtime._flags[flag] = raw_value
					runtime:_save()
				end

				if _values.callback then
					_values.callback(raw_value, enter_pressed)
				end
			end)

			local textbox_manager = {}

			function textbox_manager:get_value()
				return raw_value
			end

			function textbox_manager:set_value(value)
				raw_value = _tostring(value or '')
				render_value()
			end

			function textbox_manager:clear()
				self:set_value('')
			end

			function textbox_manager:focus()
				textbox:CaptureFocus()
			end

			function textbox_manager:set_visible(state)
				textbox_frame.Visible = state == true
			end

			return textbox_manager
		end

		function group_manager:create_dropdown(flag, _values)
			if _type(flag) == 'table' then
				_values = flag
				flag = _values.flag
			end

			_values = _values or {}
			_values.options = _values.options or {}

			local is_multi = _values.multi_dropdown or _values.multi or false
			local hide_selected_option = _values.hide_selected_option == true and not is_multi
			local dropdown_manager = {
				_state = false,
				_locked_open = false,
				_size = 0,
				_content_height = 0,
				_options = {},
				_option_buttons = {},
				_selected = {},
			}

			local default = _values.default or (is_multi and {} or _values.options[1])

			if flag and runtime._flags[flag] ~= nil then
				default = runtime._flags[flag]
			end

			if is_multi and _type(default) == 'table' then
				for _index, value in _pairs(default) do
					if _type(_index) == 'string' and value == true then
						dropdown_manager._selected[_index] = true
					elseif _type(value) == 'string' then
						dropdown_manager._selected[value] = true
					end
				end
			end

			local dropdown_frame = create_new('Frame', {
				BackgroundTransparency = 1,
				LayoutOrder = next_row_order(),
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = _new_udim2(1, 0, 0, 0),
				ClipsDescendants = true,
				Parent = group_frame,
			})

			create_vertical_list(dropdown_frame, 4)

			create_label({
				LayoutOrder = 0,
				Size = _new_udim2(1, 0, 0, 16),
				Text = _values.title or 'Dropdown',
				TextSize = runtime._label_text_size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = dropdown_frame,
			})

			local select_box = create_new('Frame', {
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				LayoutOrder = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = _new_udim2(1, 0, 0, 0),
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Parent = dropdown_frame,
			})

			create_round(select_box, 6)
			create_vertical_list(select_box)

			local header = create_new('Frame', {
				BackgroundTransparency = 1,
				LayoutOrder = 0,
				Size = _new_udim2(1, 0, 0, 24),
				Parent = select_box,
			})

			local selected_text = create_label({
				Position = _new_udim2(0, 10, 0, 0),
				Size = _new_udim2(1, _values.hide_icon and -20 or -32, 1, 0),
				Text = '',
				TextSize = runtime._label_text_size,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = header,
			})

			create_new('UIGradient', {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.7, 0),
					NumberSequenceKeypoint.new(0.9, 0.5),
					NumberSequenceKeypoint.new(1, 1),
				}),
				Parent = selected_text,
			})

			if not _values.hide_icon then
				create_new('ImageLabel', {
					BackgroundTransparency = 1,
					AnchorPoint = _new_vector2(1, 0.5),
					Position = _new_udim2(1, -10, 0.5, 0),
					Size = _new_udim2(0, 12, 0, 12),
					Image = 'rbxassetid://10734899821',
					ImageColor3 = Color3.fromRGB(180, 180, 180),
					Parent = header,
				})
			end

			local options_list = create_new('ScrollingFrame', {
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				Size = _new_udim2(1, 0, 0, 0),
				CanvasSize = _new_udim2(0, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				BorderSizePixel = 0,
				Parent = select_box,
			})

			options_list.ScrollBarThickness = 0
			options_list.ScrollBarImageTransparency = 1
			options_list.VerticalScrollBarInset = Enum.ScrollBarInset.None
			options_list.HorizontalScrollBarInset = Enum.ScrollBarInset.None
			options_list.ClipsDescendants = true
			create_vertical_list(options_list)

			local function update_size()
				local visible_options = 0
				for _, option in dropdown_manager._options do
					if not hide_selected_option or option ~= default then
						visible_options += 1
					end
				end

				local content_height = visible_options * 24
				dropdown_manager._content_height = content_height
				dropdown_manager._size = _min(content_height, 5 * 24)

				if dropdown_manager._state then
					options_list.Size = _new_udim2(1, 0, 0, dropdown_manager._size)
				end
			end

			local function update_selected_text()
				if not is_multi then
					selected_text.Text = _tostring(default or _values.empty_text or 'None')
					selected_text.TextColor3 = default and Color3.fromRGB(255, 255, 255)
						or Color3.fromRGB(180, 180, 180)
					selected_text.TextTransparency = default and 0.2 or 0
					return
				end

				local selected = ''
				for option, value in _pairs(dropdown_manager._selected) do
					if value then
						selected = selected .. option .. ', '
					end
				end

				selected_text.Text = selected == '' and 'None' or selected:sub(1, -3)
				selected_text.TextColor3 = selected ~= '' and Color3.fromRGB(255, 255, 255)
					or Color3.fromRGB(180, 180, 180)
			end

			local function update_option_labels()
				for _, child in options_list:GetChildren() do
					if child:IsA('TextButton') then
						local option_label = child:FindFirstChildWhichIsA('TextLabel')
						if option_label then
							local selected = is_multi and dropdown_manager._selected[option_label.Text]
								or option_label.Text == default

							child.Visible = not hide_selected_option or not selected
							option_label.TextColor3 = selected and Color3.fromRGB(255, 255, 255)
								or Color3.fromRGB(180, 180, 180)
							option_label.TextTransparency = selected and 0.2 or 0.5
						end
					end
				end

				update_size()
			end

			local function save_selection(value)
				if flag then
					runtime._flags[flag] = value
					runtime:_save()
				end

				if _values.callback then
					_values.callback(value)
				end
			end

			local function select_option(object)
				if is_multi then
					dropdown_manager._selected[object] = not dropdown_manager._selected[object]

					local selected = {}
					for option, value in _pairs(dropdown_manager._selected) do
						if value then
							selected[option] = true
						end
					end

					update_selected_text()
					update_option_labels()
					save_selection(selected)
					return
				end

				default = object
				update_selected_text()
				update_option_labels()
				dropdown_manager:unfold(false)
				save_selection(object)
			end

			local function add_option(object)
				object = _tostring(object)

				if _find(dropdown_manager._options, object) then
					return
				end

				_insert(dropdown_manager._options, object)

				local option_button = create_new('TextButton', {
					BackgroundTransparency = 1,
					LayoutOrder = #dropdown_manager._options,
					Size = _new_udim2(1, 0, 0, 24),
					Text = '',
					Visible = not hide_selected_option or object ~= default,
					AutoButtonColor = false,
					Parent = options_list,
				})
				dropdown_manager._option_buttons[object] = option_button

				local selected = is_multi and dropdown_manager._selected[object] or object == default
				local option_label = create_label({
					Position = _new_udim2(0, 10, 0, 0),
					Size = _new_udim2(1, -20, 1, 0),
					Text = object,
					TextColor3 = selected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180),
					TextSize = runtime._label_text_size,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextTransparency = selected and 0.2 or 0.5,
					Parent = option_button,
				})

				option_button.MouseEnter:Connect(function()
					_create_tween(tween_service, option_label, _new_tween_info(0.2), {
						TextTransparency = 0,
					}):Play()
				end)

				option_button.MouseLeave:Connect(function()
					local current_selected = is_multi and dropdown_manager._selected[object] or object == default
					_create_tween(tween_service, option_label, _new_tween_info(0.2), {
						TextTransparency = current_selected and 0.2 or 0.5,
					}):Play()
				end)

				option_button.MouseButton1Click:Connect(function()
					select_option(object)
				end)

				update_size()
			end

			function dropdown_manager:set_options(options, selected)
				for _, child in options_list:GetChildren() do
					if child:IsA('TextButton') then
						child:Destroy()
					end
				end

				_clear(self._options)
				_clear(self._option_buttons)

				for _, option in options or {} do
					add_option(option)
				end

				if is_multi then
					_clear(self._selected)
					if _type(selected) == 'table' then
						for index, value in _pairs(selected) do
							if _type(index) == 'string' and value == true then
								self._selected[index] = true
							elseif _type(value) == 'string' then
								self._selected[value] = true
							end
						end
					end
				else
					if selected and _find(self._options, _tostring(selected)) then
						default = _tostring(selected)
					elseif not _find(self._options, default) then
						default = self._options[1]
					end
				end

				update_size()
				update_selected_text()
				update_option_labels()
			end

			function dropdown_manager:add_option(option, select_added)
				add_option(option)
				if select_added then
					self:set_value(option, true)
				end
			end

			function dropdown_manager:set_value(value, silent)
				if is_multi then
					_clear(self._selected)
					if _type(value) == 'table' then
						for index, selected in _pairs(value) do
							if _type(index) == 'string' and selected == true then
								self._selected[index] = true
							elseif _type(selected) == 'string' then
								self._selected[selected] = true
							end
						end
					end

					update_selected_text()
					update_option_labels()

					if not silent then
						save_selection(shallow_copy(self._selected))
					end

					return true
				end

				if value == nil then
					default = nil
					update_selected_text()
					update_option_labels()
					return true
				end

				value = _tostring(value)
				if not _find(self._options, value) then
					return false
				end

				default = value
				update_selected_text()
				update_option_labels()

				if not silent then
					save_selection(value)
				end

				return true
			end

			function dropdown_manager:get_value()
				return is_multi and shallow_copy(self._selected) or default
			end

			function dropdown_manager:unfold(force_state)
				local opening = force_state
				if opening == nil then
					opening = not self._state
				end

				if self._locked_open and not opening then
					return
				end

				if opening == self._state then
					return
				end

				if opening then
					for _, dropdown in runtime._active_dropdowns do
						if dropdown ~= self and dropdown._state then
							dropdown:unfold(false)
						end
					end
				end

				self._state = opening

				if self._state then
					options_list.CanvasPosition = _new_vector2(0, 0)
					_create_tween(
						tween_service,
						options_list,
						_new_tween_info(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
						{
							Size = _new_udim2(1, 0, 0, self._size),
						}
					):Play()
				else
					local tween = _create_tween(
						tween_service,
						options_list,
						_new_tween_info(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
						{
							Size = _new_udim2(1, 0, 0, 0),
						}
					)
					tween.Completed:Once(function()
						if not self._state then
							options_list.CanvasPosition = _new_vector2(0, 0)
						end
					end)
					tween:Play()
				end
			end

			function dropdown_manager:set_locked_open(state)
				self._locked_open = state == true
				if self._locked_open then
					self:unfold(true)
				end
			end

			local header_button = create_new('TextButton', {
				BackgroundTransparency = 1,
				Size = _udim2_from_scale(1, 1),
				Text = '',
				ZIndex = 10,
				Parent = header,
			})

			header_button.MouseButton1Click:Connect(function()
				dropdown_manager:unfold()
			end)

			for _, option in _values.options do
				add_option(option)
			end

			update_selected_text()
			update_option_labels()

			_insert(runtime._active_dropdowns, dropdown_manager)

			return dropdown_manager
		end

		function group_manager:create_keybind(flag, _values)
			if _type(flag) == 'table' then
				_values = flag
				flag = _values.flag
			end

			_values = _values or {}
			local default = _values.default or Enum.KeyCode.RightShift

			if flag and runtime._flags[flag] ~= nil then
				local success, result = _pcall(function()
					return Enum.KeyCode[runtime._flags[flag]]
				end)

				if success and result then
					default = result
				end
			elseif flag then
				runtime._flags[flag] = default.Name
			end

			local key = default
			local picking = false

			local keybind_frame = create_new('Frame', {
				BackgroundTransparency = 1,
				LayoutOrder = next_row_order(),
				Size = _new_udim2(1, 0, 0, 24),
				Parent = group_frame,
			})

			create_label({
				Size = _new_udim2(0.5, 0, 1, 0),
				Text = _values.title or 'Keybind',
				TextSize = runtime._label_text_size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = keybind_frame,
			})

			local bind_button = create_new('TextButton', {
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				AnchorPoint = _new_vector2(1, 0.5),
				Position = _new_udim2(1, 0, 0.5, 0),
				Size = _new_udim2(0, 36, 0, 22),
				AutomaticSize = Enum.AutomaticSize.X,
				FontFace = Font.new(
					'rbxasset://fonts/families/GothamSSm.json',
					Enum.FontWeight.SemiBold,
					Enum.FontStyle.Normal
				),
				Text = key.Name,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = runtime._label_text_size,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				Parent = keybind_frame,
			})

			create_round(bind_button, 6)
			create_padding(bind_button, 0, 0, 8, 8)

			bind_button.MouseButton1Click:Connect(function()
				picking = true
				bind_button.Text = '...'

				_create_tween(tween_service, bind_button, _new_tween_info(0.2), {
					BackgroundColor3 = Color3.fromRGB(55, 55, 55),
				}):Play()
			end)

			user_input_service.InputBegan:Connect(function(input, processed)
				if picking then
					if
						input.UserInputType == Enum.UserInputType.Keyboard
						and input.KeyCode ~= Enum.KeyCode.Unknown
					then
						key = input.KeyCode
						bind_button.Text = key.Name
						picking = false

						_create_tween(tween_service, bind_button, _new_tween_info(0.2), {
							BackgroundColor3 = Color3.fromRGB(40, 40, 40),
						}):Play()

						if flag then
							runtime._flags[flag] = key.Name
							runtime:_save()
						end
					end
				elseif not processed and input.KeyCode == key then
					if _values.callback then
						_values.callback()
					end
				end
			end)

			local keybind_manager = {}

			function keybind_manager:set_key(new_key)
				key = new_key
				bind_button.Text = key.Name
				if flag then
					runtime._flags[flag] = key.Name
					runtime:_save()
				end
			end

			function keybind_manager:get_key()
				return key
			end

			return keybind_manager
		end

		_insert(tab_manager._groups, group_manager)

		local group_name = normalize_name(group_values.title)
		tab_manager._group_registry[group_name] = tab_manager._group_registry[group_name] or {}
		_insert(tab_manager._group_registry[group_name], group_manager)

		return group_manager
	end

	local tab_name = normalize_name(title)
	self._tab_registry[tab_name] = self._tab_registry[tab_name] or {}
	_insert(self._tab_registry[tab_name], tab_manager)

	return tab_manager
end

function library.update_keybind_list(self)
	if not self._keybind_list_content or not self._keybind_list_frame then
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

			local row = create_new('Frame', {
				BackgroundTransparency = 1,
				Size = _new_udim2(1, 0, 0, 24),
				Parent = self._keybind_list_content,
			})

			local is_enabled = self._flags[entry.flag]
			local display_text = `[ {entry.key_name} ]`
			local text_color = is_enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)

			local info_width = text_service:GetTextSize(
				display_text,
				14,
				Enum.Font.GothamSemibold,
				_new_vector2(1000, 24)
			).X + 4

			create_label({
				Size = _new_udim2(1, -(info_width + 10), 1, 0),
				Text = entry.title,
				TextColor3 = text_color,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			})

			create_label({
				AnchorPoint = _new_vector2(1, 0.5),
				Position = _new_udim2(1, 0, 0.5, 0),
				Size = _new_udim2(0, info_width, 0, 18),
				Text = display_text,
				TextColor3 = text_color,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = row,
			})
		end
	end

	self._keybind_list_frame.Visible = self._keybind_list_visible and has_any
end

function library._init_keybind_list(self)
	local keybind_list = create_new('Frame', {
		Name = '_keybind_list',
		BackgroundColor3 = Color3.fromRGB(18, 18, 18),
		Position = _new_udim2(0, 16, 0.2, 0),
		Size = _new_udim2(0, 250, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
		Active = true,
		Parent = self._ui,
	})

	local keybind_scale = create_new('UIScale', {
		Scale = self._ui_scale,
		Parent = keybind_list,
	})

	self._keybind_scale = keybind_scale

	create_round(keybind_list, 6)
	create_outline(keybind_list, true)
	create_vertical_list(keybind_list)

	local keybind_list_header = create_new('Frame', {
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		Size = _new_udim2(1, 0, 0, 32),
		Parent = keybind_list,
	})

	create_new('ImageLabel', {
		BackgroundTransparency = 1,
		AnchorPoint = _new_vector2(0, 0.5),
		Position = _new_udim2(0, 12, 0.5, 0),
		Size = _new_udim2(0, 14, 0, 14),
		Image = 'rbxassetid://10723416765',
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		Parent = keybind_list_header,
	})

	create_label({
		Size = _udim2_from_scale(1, 1),
		Text = 'Keybinds',
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = keybind_list_header,
	})

	local keybind_grip, set_keybind_grip_color =
		create_grip(keybind_list_header, _new_udim2(1, -10, 0.5, 0), _new_vector2(1, 0.5), 4)

	create_divider(keybind_list_header, _new_udim2(0, 0, 1, -1), _new_udim2(1, 0, 0, 1))

	local keybind_content = create_new('Frame', {
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = _new_udim2(1, 0, 0, 0),
		Parent = keybind_list,
	})

	create_vertical_list(keybind_content, 2)
	create_padding(keybind_content, 6, 8, 12, 12)

	self._keybind_list_frame = keybind_list
	self._keybind_list_content = keybind_content

	local keybind_dragging = false
	local keybind_drag_start = nil
	local keybind_list_position = nil

	local function begin_keybind_drag(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			keybind_dragging = true
			keybind_drag_start = input.Position
			keybind_list_position = keybind_list.Position
			set_keybind_grip_color(Color3.fromRGB(255, 255, 255))

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					keybind_dragging = false
					set_keybind_grip_color(Color3.fromRGB(100, 100, 100))
				end
			end)
		end
	end

	keybind_grip.MouseEnter:Connect(function()
		set_keybind_grip_color(Color3.fromRGB(220, 220, 220))
	end)

	keybind_grip.MouseLeave:Connect(function()
		if not keybind_dragging then
			set_keybind_grip_color(Color3.fromRGB(100, 100, 100))
		end
	end)

	keybind_list.InputBegan:Connect(begin_keybind_drag)
	keybind_grip.InputBegan:Connect(begin_keybind_drag)

	user_input_service.InputChanged:Connect(function(input)
		if not keybind_dragging then
			return
		end

		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			local scale = self._ui_scale
			local delta = (input.Position - keybind_drag_start) / scale

			_create_tween(tween_service, keybind_list, _new_tween_info(0.12), {
				Position = _new_udim2(
					keybind_list_position.X.Scale,
					keybind_list_position.X.Offset + delta.X,
					keybind_list_position.Y.Scale,
					keybind_list_position.Y.Offset + delta.Y
				),
			}):Play()
		end
	end)
end

function library.notify(self, message)
	self = resolve_runtime(self)
	if not self or not self._notification_holder then
		return
	end

	local text = _tostring(message or ''):gsub('[\r\n]+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
	if text == '' then
		return
	end

	local text_width =
		text_service:GetTextSize(text, self._label_text_size, Enum.Font.GothamSemibold, _new_vector2(1000, 26)).X
	local width = _clamp(text_width + 24, 72, 540)

	self._notification_order += 1

	local notification = create_new('Frame', {
		Name = '_notification',
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
		BackgroundTransparency = 1,
		LayoutOrder = self._notification_order,
		Size = _new_udim2(0, width - 12, 0, 0),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 200,
		Parent = self._notification_holder,
	})

	create_round(notification, 6)

	local notification_outline = create_outline(notification)
	notification_outline.Transparency = 1

	local notification_label = create_label({
		Position = _new_udim2(0, 10, 0, 0),
		Size = _new_udim2(1, -20, 1, 0),
		Text = text,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = self._label_text_size,
		TextTransparency = 1,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 201,
		Parent = notification,
	})

	_create_tween(
		tween_service,
		notification,
		_new_tween_info(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{
			BackgroundTransparency = 0,
			Size = _new_udim2(0, width, 0, 26),
		}
	):Play()
	_create_tween(
		tween_service,
		notification_label,
		_new_tween_info(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{
			TextTransparency = 0.1,
		}
	):Play()
	_create_tween(
		tween_service,
		notification_outline,
		_new_tween_info(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{
			Transparency = 0,
		}
	):Play()

	_delay(2.7, function()
		if not notification.Parent then
			return
		end

		_create_tween(
			tween_service,
			notification,
			_new_tween_info(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{
				BackgroundTransparency = 1,
				Size = _new_udim2(0, width - 12, 0, 0),
			}
		):Play()
		_create_tween(
			tween_service,
			notification_label,
			_new_tween_info(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{
				TextTransparency = 1,
			}
		):Play()
		_create_tween(
			tween_service,
			notification_outline,
			_new_tween_info(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{
				Transparency = 1,
			}
		):Play()
	end)

	_delay(3, function()
		if notification.Parent then
			notification:Destroy()
		end
	end)
end

local everst = library._new()

local main_category = everst:create_category('main')
local general_tab = main_category:create_tab('General', 'rbxassetid://10709812159')

local controls_group = general_tab:create_group('Controls', 'left')
controls_group:create_toggle('feature_enabled', {
	title = 'Enable Feature',
	default = false,
	is_keybind = true,
	callback = function(state)
		everst:notify(state and 'Feature enabled' or 'Feature disabled')
	end,
})

controls_group:create_slider('feature_intensity', {
	title = 'Intensity',
	minimum = 0,
	maximum = 100,
	default = 50,
	rounding = false,
	callback = function(value)
	end,
})

controls_group:create_dropdown('feature_mode', {
	title = 'Mode',
	options = { 'Standard', 'Fast', 'Smooth' },
	default = 'Standard',
	callback = function(selected)
	end,
})

local actions_group = general_tab:create_group('Actions', 'right')
actions_group:create_button({
	title = 'Test Notification',
	callback = function()
		everst:notify('Everst is running')
	end,
})

actions_group:create_textbox('custom_input', {
	title = 'Input',
	placeholder = 'Type here...',
	callback = function(text)
		if text ~= '' then
			everst:notify(`Input: {text}`)
		end
	end,
})

actions_group:create_dropdown('multi_select', {
	title = 'Targets',
	options = { 'Alpha', 'Beta', 'Gamma', 'Delta' },
	multi = true,
	callback = function(selected)
	end,
})

local menu_category = everst:create_category('menu')
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
	title = 'Close UI',
	callback = function()
		everst:change_visibility(false)
	end,
})

local bg_group = settings_tab:create_group('Background', 'right')
local bg_name_box = bg_group:create_textbox({
	title = 'Background Name',
	placeholder = 'Optional name...',
})

local bg_source_box = bg_group:create_textbox({
	title = 'PNG / JPEG / GIF URL or File',
	placeholder = 'https://... or rbxassetid://...',
})

local bg_progress = bg_group:create_progress({
	title = 'Uploading...',
	visible = false,
})

local bg_saved_dropdown
bg_saved_dropdown = bg_group:create_dropdown({
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

bg_group:create_button({
	title = 'Upload & Apply',
	callback = function()
		everst:upload_background(
			bg_source_box:get_value(),
			bg_name_box:get_value(),
			bg_progress,
			function(success, saved_name)
				if success then
					bg_saved_dropdown:set_options(everst:_get_saved_bg_names(), saved_name)
					bg_source_box:clear()
					bg_name_box:clear()
				end
			end
		)
	end,
})

bg_group:create_slider({
	title = 'Background Dim',
	minimum = 0,
	maximum = 95,
	default = everst._bg_dim_amount,
	rounding = false,
	callback = function(value)
		everst:set_background_dim(value)
	end,
})

bg_group:create_button({
	title = 'Remove Selected',
	callback = function()
		local current = bg_saved_dropdown:get_value()
		if current and everst:delete_saved_background(current) then
			bg_saved_dropdown:set_options(everst:_get_saved_bg_names(), everst._bg_store.active)
			everst:notify('Removed background: ' .. _tostring(current))
		else
			everst:notify('No saved background selected')
		end
	end,
})

bg_group:create_button({
	title = 'Clear Background',
	callback = function()
		everst:clear_background()
		bg_saved_dropdown:set_value(nil, true)
		everst:notify('Background cleared')
	end,
})

return library
