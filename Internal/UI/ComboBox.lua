--[[

MIT License

Copyright (c) 2019 Mitchell Davis <coding.jackalope@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]]

local Cursor = require(SLAB_PATH .. '.Internal.Core.Cursor')
local DrawCommands = require(SLAB_PATH .. '.Internal.Core.DrawCommands')
local Input = require(SLAB_PATH .. '.Internal.UI.Input')
local Mouse = require(SLAB_PATH .. '.Internal.Input.Mouse')
local Region = require(SLAB_PATH .. '.Internal.UI.Region')
local Style = require(SLAB_PATH .. '.Style')
local Tooltip = require(SLAB_PATH .. '.Internal.UI.Tooltip')
local Window = require(SLAB_PATH .. '.Internal.UI.Window')

local ComboBox = {}
local Instances = {}
local Active = nil

local MIN_WIDTH = 150.0
local MIN_HEIGHT = 150.0

local function GetInstance(Id)
	if Instances[Id] == nil then
		local Instance = {}
		Instance.IsOpen = false
		Instance.WasOpened = false
		Instance.WinH = 0.0
		Instances[Id] = Instance
	end
	return Instances[Id]
end

function ComboBox.Begin(Id, Options)
	Options = Options ~= nil and Options or {}
	Options.Tooltip = Options.Tooltip == nil and "" or Options.Tooltip
	Options.W = Options.W == nil and MIN_WIDTH or Options.W
	Options.WinH = Options.WinH == nil and MIN_HEIGHT or Options.WinH
	Options.Selected = Options.Selected == nil and "" or Options.Selected

	local Instance = GetInstance(Id)
	local WinItemId = Window.GetItemId(Id)
	local X, Y = Cursor.GetPosition()
	local W = Options.W
	local H = Style.Font:getHeight()
	local Radius = H * 0.35
	local InputBgColor = Style.ComboBoxColor

	Instance.X = X
	Instance.Y = Y
	Instance.W = W
	Instance.H = H
	Instance.WinH = math.min(Instance.WinH, Options.WinH)

	local DropDownX = X + W
	local DropDownW = Radius * 4.0
	local DropDownColor = Style.ComboBoxDropDownColor

	local MouseX, MouseY = Window.GetMousePosition()
	local MouseClicked = Mouse.IsClicked(1)

	Instance.WasOpened = Instance.IsOpen

	local IsObstructed = Window.IsObstructedAtMouse()

	if not IsObstructed and X <= MouseX and MouseX <= X + W + DropDownW and Y <= MouseY and MouseY <= Y + H then
		Tooltip.Begin(Options.Tooltip)
		Window.SetHotItem(WinItemId)
		InputBgColor = Style.ComboBoxHoveredColor
		DropDownColor = Style.ComboBoxDropDownHoveredColor

		if MouseClicked then
			Instance.IsOpen = not Instance.IsOpen

			if Instance.IsOpen then
				Window.SetStackLock(Id .. '_combobox')
			end
		end
	end

	Input.Begin(Id .. '_Input', {ReadOnly = true, Text = Options.Selected, Align = 'left', W = W, H = H, BgColor = InputBgColor})

	Cursor.SameLine()

	DrawCommands.Rectangle('fill', X + W, Y, Radius * 4.0, H, DropDownColor)
	DrawCommands.Triangle('fill', X + W + Radius * 2.0, Y + H - Radius * 1.35, Radius, 'south', Style.ComboBoxArrowColor)

	Cursor.SetItemBounds(X, Y, W, H)
	Cursor.AdvanceY(H)

	Window.AddItem(X, Y, W + DropDownW, H, WinItemId)

	if Instance.IsOpen then
		Window.Begin(Id .. '_combobox',
		{
			X = X - 1.0,
			Y = Y + H,
			W = W,
			H = Instance.WinH,
			AllowResize = false,
			BgColor = Style.ComboBoxDropDownBgColor,
			AutoSizeWindow = false,
			AllowFocus = false,
			Layer = Window.GetLayer(),
			AutoSizeContent = true
		})
		Active = Instance
	end

	return Instance.IsOpen
end

function ComboBox.End()
	local Y = 0.0
	local H = 0.0

	if Active ~= nil then
		Y, H = Active.Y, Active.H
		local ContentW, ContentH = Window.GetContentSize()
		Active.WinH = ContentH
		if Mouse.IsClicked(1) and Active.WasOpened and not Region.IsHoverScrollBar(Window.GetId()) then
			Active.IsOpen = false
			Active = nil
			Window.SetStackLock(nil)
		end
	end

	Window.End()
	DrawCommands.SetLayer('Normal')

	if Y ~= 0.0 and H ~= 0.0 then
		Cursor.SetY(Y)
		Cursor.AdvanceY(H)
	end
end

return ComboBox
