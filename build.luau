-- Automatic code generation for Rover
-- Copyright (C) 2024  Andy
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.


-- Rover
-- an experimental roblox framework
-- by Andy

--!nocheck
-- Typechecking is disabled due to the sheer number of autogen types

local Rover = {}

-- Signals
export type SignalConnection<T> = {
	close: () -> (),
	callback: (next: T) -> ()
}
export type Signal<T> = {
	bind: (callback: (next: T) -> ()) -> SignalConnection<T>,
	get: () -> T,
	isASignal: "signal",
	modify: (modify: (old: T) -> T) -> T
}
export type State<T> = Signal<T> & {
	set: (next: T) -> ()
}
export type Derived<T> = Signal<T> & {
	close: () -> ()
}

-- Basic signal
function coreSignal<T>(value: T): (Signal<T>, (value: T) -> nil)
	local signal = {
		isASignal = "signal"
	} :: Signal<T>

	local activeValue = value

	function signal.get(): T
		return activeValue
	end

	local bindings: {SignalConnection<T>} = {}

	function signal.bind(callback: (T) -> ()): SignalConnection<T>
		local binding = {
			callback = callback
		}

		function binding.close(): ()
			table.remove(
				bindings,
				table.find(bindings, binding)
			)
		end

		table.insert(bindings, binding)

		callback(activeValue)

		return binding
	end

	local function set(next: T)
		if activeValue == next then
			return
		end

		activeValue = next

		for _, binding in ipairs(bindings) do
			binding.callback(next)
		end
	end

	function signal.modify(modify: (T) -> T)
		set(modify(activeValue))

		return activeValue
	end

	return signal, set
end

-- State
function Rover.state<T>(value: T): State<T>
	local signal, set = coreSignal(value)

	local state = signal :: State<T>

	function state.set(next: T): ()
		set(next)
	end

	return state
end

-- Derived
function Rover.fuse<T>(transformation: () -> T, ...: Signal<any>): Derived<T>
	local signal, set = coreSignal(transformation())

	local derived = signal :: Derived<T>

	local listeners = {}

	for _, sub in ipairs({...}) do
		sub.bind(function(_): ()
			set(transformation())
		end)
	end

	function derived.close(): ()
		for _, listener in ipairs(listeners) do
			listener.close()
		end
	end

	return derived
end

function Rover.derived<T, U>(base: Signal<T>, transformation: (state: T) -> U): Derived<U>
	return Rover.fuse(function(): U
		return transformation(base.get())
	end, base)
end

function Rover.realize<T>(data: T | Signal<T>): Signal<T>
	if type(data) == "table" and data.isASignal == "signal" then		
		return data
	else
		return Rover.state(data :: T)
	end
end

-- Rendering
export type Context = {
	container: Instance,
	fragment: Fragment?
}

local context: Context

function Rover.subcontext_internal_039eaddbd4712a(next: Context, content: (instance: any) -> ()): ()
	local prev = context

	context = next
	
	content(next.container)

	context = prev
end

function Rover.drawInstance_internal_039eaddbd4712a(
	clazz: string, 
	props: { [string]: any },
	content: (instance: any) -> ()
): ()
	local instance = Instance.new(clazz)

	for key, value in pairs(props) do
		if value ~= nil then
			Rover.realize(value).bind(function(next): ()
				(instance :: any)[key] = next
			end)
		end
	end

	instance.Parent = context.container

	if context.fragment then
		table.insert(context.fragment.content, instance)
	end

	Rover.subcontext_internal_039eaddbd4712a({ 
		container = instance
	}, content)
end

function Rover.render(container: Instance, content: () -> nil) : ()
	Rover.subcontext_internal_039eaddbd4712a({
		container = container
	}, content)
end

export type Fragment = {
	content: {Instance},
	close: () -> ()
}

function Rover.fragment(content: () -> nil): Fragment
	local fragment = {
		content = {}
	} :: Fragment

	function fragment.close()
		for _, child in ipairs(fragment.content) do
			child.Parent = nil
		end
	end

	Rover.subcontext_internal_039eaddbd4712a({
		container = context.container,
		fragment = fragment
	}, content)

	return fragment
end

export type If = {
	Else: (content: () -> ()) -> ()
}

function Rover.If(condition: Signal<boolean>, content: () -> ()): If
	local fragment: Fragment? = nil
	local snapshot = context
	
	condition.bind(function(next: boolean) 
		if next then
			Rover.subcontext_internal_039eaddbd4712a(snapshot, function()
				fragment = Rover.fragment(content)
			end)
		else
			if fragment then
				fragment.close()
				fragment = nil
			end
		end
	end)

	return {
		Else = function(nextContent: () -> ())
			return Rover.If(
				Rover.derived(condition,
					function(v: boolean) return not v end
				),
				nextContent
			)
		end
	}
end

type ListEntry<T> = {
	fragment: Fragment,
	state: Derived<T>
}

function Rover.Each<T>(children: Signal<{T}>, content: (state: Signal<T>, index: number) -> ())
	local elements: {ListEntry<T>} = {}

	children.bind(function(next: {T})
		-- Shrink until it's length of array
		while #elements > #next do
			local lastElement = table.remove(elements, #elements)

			if lastElement then
				lastElement.fragment.close()
				lastElement.state.close()
			end
		end

		-- Grow
		while #elements < #next do
			local index = #elements + 1

			local state = Rover.derived(children, function(all: {T}) 
				return all[index]
			end)

			table.insert(elements, {
				state = state,
				fragment = Rover.fragment(function() content(state, index) end)
			})
		end
	end)
end

-- BEGIN AUTOGEN
-- Types
type _CanvasGroupProps = {
	GroupColor3: Color3 | Signal<Color3> | nil,
	GroupTransparency: number | Signal<number> | nil
} & _GuiObjectProps
type _FrameProps = {
	Style: Enum.FrameStyle | Signal<Enum.FrameStyle> | nil
} & _GuiObjectProps
type _GuiBaseProps = {

} & _InstanceProps
type _GuiBase2dProps = {
	AbsolutePosition: Vector2 | Signal<Vector2> | nil,
	AbsoluteRotation: number | Signal<number> | nil,
	AbsoluteSize: Vector2 | Signal<Vector2> | nil,
	AutoLocalize: boolean | Signal<boolean> | nil,
	Localize: boolean | Signal<boolean> | nil,
	RootLocalizationTable: LocalizationTable | Signal<LocalizationTable> | nil,
	SelectionBehaviorDown: Enum.SelectionBehavior | Signal<Enum.SelectionBehavior> | nil,
	SelectionBehaviorLeft: Enum.SelectionBehavior | Signal<Enum.SelectionBehavior> | nil,
	SelectionBehaviorRight: Enum.SelectionBehavior | Signal<Enum.SelectionBehavior> | nil,
	SelectionBehaviorUp: Enum.SelectionBehavior | Signal<Enum.SelectionBehavior> | nil,
	SelectionGroup: boolean | Signal<boolean> | nil
} & _GuiBaseProps
type _GuiButtonProps = {
	AutoButtonColor: boolean | Signal<boolean> | nil,
	Modal: boolean | Signal<boolean> | nil,
	Selected: boolean | Signal<boolean> | nil,
	Style: Enum.ButtonStyle | Signal<Enum.ButtonStyle> | nil
} & _GuiObjectProps
type _GuiLabelProps = {

} & _GuiObjectProps
type _GuiObjectProps = {
	Active: boolean | Signal<boolean> | nil,
	AnchorPoint: Vector2 | Signal<Vector2> | nil,
	AutomaticSize: Enum.AutomaticSize | Signal<Enum.AutomaticSize> | nil,
	BackgroundColor: BrickColor | Signal<BrickColor> | nil,
	BackgroundColor3: Color3 | Signal<Color3> | nil,
	BackgroundTransparency: number | Signal<number> | nil,
	BorderColor: BrickColor | Signal<BrickColor> | nil,
	BorderColor3: Color3 | Signal<Color3> | nil,
	BorderMode: Enum.BorderMode | Signal<Enum.BorderMode> | nil,
	BorderSizePixel: number | Signal<number> | nil,
	ClipsDescendants: boolean | Signal<boolean> | nil,
	Draggable: boolean | Signal<boolean> | nil,
	GuiState: Enum.GuiState | Signal<Enum.GuiState> | nil,
	Interactable: boolean | Signal<boolean> | nil,
	LayoutOrder: number | Signal<number> | nil,
	NextSelectionDown: GuiObject | Signal<GuiObject> | nil,
	NextSelectionLeft: GuiObject | Signal<GuiObject> | nil,
	NextSelectionRight: GuiObject | Signal<GuiObject> | nil,
	NextSelectionUp: GuiObject | Signal<GuiObject> | nil,
	Position: UDim2 | Signal<UDim2> | nil,
	Rotation: number | Signal<number> | nil,
	Selectable: boolean | Signal<boolean> | nil,
	SelectionImageObject: GuiObject | Signal<GuiObject> | nil,
	SelectionOrder: number | Signal<number> | nil,
	Size: UDim2 | Signal<UDim2> | nil,
	SizeConstraint: Enum.SizeConstraint | Signal<Enum.SizeConstraint> | nil,
	Transparency: number | Signal<number> | nil,
	Visible: boolean | Signal<boolean> | nil,
	ZIndex: number | Signal<number> | nil
} & _GuiBase2dProps
type _ImageButtonProps = {
	HoverImage: unknown | Signal<unknown> | nil,
	Image: unknown | Signal<unknown> | nil,
	ImageColor3: Color3 | Signal<Color3> | nil,
	ImageRectOffset: Vector2 | Signal<Vector2> | nil,
	ImageRectSize: Vector2 | Signal<Vector2> | nil,
	ImageTransparency: number | Signal<number> | nil,
	IsLoaded: boolean | Signal<boolean> | nil,
	PressedImage: unknown | Signal<unknown> | nil,
	ResampleMode: Enum.ResamplerMode | Signal<Enum.ResamplerMode> | nil,
	ScaleType: Enum.ScaleType | Signal<Enum.ScaleType> | nil,
	SliceCenter: Rect | Signal<Rect> | nil,
	SliceScale: number | Signal<number> | nil,
	TileSize: UDim2 | Signal<UDim2> | nil
} & _GuiButtonProps
type _ImageLabelProps = {
	Image: unknown | Signal<unknown> | nil,
	ImageColor3: Color3 | Signal<Color3> | nil,
	ImageRectOffset: Vector2 | Signal<Vector2> | nil,
	ImageRectSize: Vector2 | Signal<Vector2> | nil,
	ImageTransparency: number | Signal<number> | nil,
	IsLoaded: boolean | Signal<boolean> | nil,
	ResampleMode: Enum.ResamplerMode | Signal<Enum.ResamplerMode> | nil,
	ScaleType: Enum.ScaleType | Signal<Enum.ScaleType> | nil,
	SliceCenter: Rect | Signal<Rect> | nil,
	SliceScale: number | Signal<number> | nil,
	TileSize: UDim2 | Signal<UDim2> | nil
} & _GuiLabelProps
type _InstanceProps = {
	Archivable: boolean | Signal<boolean> | nil,
	ClassName: string | Signal<string> | nil,
	Name: string | Signal<string> | nil,
	Parent: Instance | Signal<Instance> | nil,
	RobloxLocked: boolean | Signal<boolean> | nil,
	Sandboxed: boolean | Signal<boolean> | nil,
	UniqueId: unknown | Signal<unknown> | nil,
	archivable: boolean | Signal<boolean> | nil,
	className: string | Signal<string> | nil
}
type _ScrollingFrameProps = {
	AbsoluteCanvasSize: Vector2 | Signal<Vector2> | nil,
	AbsoluteWindowSize: Vector2 | Signal<Vector2> | nil,
	AutomaticCanvasSize: Enum.AutomaticSize | Signal<Enum.AutomaticSize> | nil,
	BottomImage: unknown | Signal<unknown> | nil,
	CanvasPosition: Vector2 | Signal<Vector2> | nil,
	CanvasSize: UDim2 | Signal<UDim2> | nil,
	ElasticBehavior: Enum.ElasticBehavior | Signal<Enum.ElasticBehavior> | nil,
	HorizontalScrollBarInset: Enum.ScrollBarInset | Signal<Enum.ScrollBarInset> | nil,
	MidImage: unknown | Signal<unknown> | nil,
	ScrollBarImageColor3: Color3 | Signal<Color3> | nil,
	ScrollBarImageTransparency: number | Signal<number> | nil,
	ScrollBarThickness: number | Signal<number> | nil,
	ScrollingDirection: Enum.ScrollingDirection | Signal<Enum.ScrollingDirection> | nil,
	ScrollingEnabled: boolean | Signal<boolean> | nil,
	TopImage: unknown | Signal<unknown> | nil,
	VerticalScrollBarInset: Enum.ScrollBarInset | Signal<Enum.ScrollBarInset> | nil,
	VerticalScrollBarPosition: Enum.VerticalScrollBarPosition | Signal<Enum.VerticalScrollBarPosition> | nil
} & _GuiObjectProps
type _TextBoxProps = {
	ClearTextOnFocus: boolean | Signal<boolean> | nil,
	ContentText: string | Signal<string> | nil,
	CursorPosition: number | Signal<number> | nil,
	Font: Font | Signal<Font> | nil,
	FontFace: Font | Signal<Font> | nil,
	FontSize: Enum.FontSize | Signal<Enum.FontSize> | nil,
	LineHeight: number | Signal<number> | nil,
	MaxVisibleGraphemes: number | Signal<number> | nil,
	MultiLine: boolean | Signal<boolean> | nil,
	PlaceholderColor3: Color3 | Signal<Color3> | nil,
	PlaceholderText: string | Signal<string> | nil,
	RichText: boolean | Signal<boolean> | nil,
	SelectionStart: number | Signal<number> | nil,
	ShowNativeInput: boolean | Signal<boolean> | nil,
	Text: string | Signal<string> | nil,
	TextBounds: Vector2 | Signal<Vector2> | nil,
	TextColor: BrickColor | Signal<BrickColor> | nil,
	TextColor3: Color3 | Signal<Color3> | nil,
	TextDirection: Enum.TextDirection | Signal<Enum.TextDirection> | nil,
	TextEditable: boolean | Signal<boolean> | nil,
	TextFits: boolean | Signal<boolean> | nil,
	TextScaled: boolean | Signal<boolean> | nil,
	TextSize: number | Signal<number> | nil,
	TextStrokeColor3: Color3 | Signal<Color3> | nil,
	TextStrokeTransparency: number | Signal<number> | nil,
	TextTransparency: number | Signal<number> | nil,
	TextTruncate: Enum.TextTruncate | Signal<Enum.TextTruncate> | nil,
	TextWrap: boolean | Signal<boolean> | nil,
	TextWrapped: boolean | Signal<boolean> | nil,
	TextXAlignment: Enum.TextXAlignment | Signal<Enum.TextXAlignment> | nil,
	TextYAlignment: Enum.TextYAlignment | Signal<Enum.TextYAlignment> | nil
} & _GuiObjectProps
type _TextButtonProps = {
	ContentText: string | Signal<string> | nil,
	Font: Font | Signal<Font> | nil,
	FontFace: Font | Signal<Font> | nil,
	FontSize: Enum.FontSize | Signal<Enum.FontSize> | nil,
	LineHeight: number | Signal<number> | nil,
	LocalizedText: string | Signal<string> | nil,
	MaxVisibleGraphemes: number | Signal<number> | nil,
	RichText: boolean | Signal<boolean> | nil,
	Text: string | Signal<string> | nil,
	TextBounds: Vector2 | Signal<Vector2> | nil,
	TextColor: BrickColor | Signal<BrickColor> | nil,
	TextColor3: Color3 | Signal<Color3> | nil,
	TextDirection: Enum.TextDirection | Signal<Enum.TextDirection> | nil,
	TextFits: boolean | Signal<boolean> | nil,
	TextScaled: boolean | Signal<boolean> | nil,
	TextSize: number | Signal<number> | nil,
	TextStrokeColor3: Color3 | Signal<Color3> | nil,
	TextStrokeTransparency: number | Signal<number> | nil,
	TextTransparency: number | Signal<number> | nil,
	TextTruncate: Enum.TextTruncate | Signal<Enum.TextTruncate> | nil,
	TextWrap: boolean | Signal<boolean> | nil,
	TextWrapped: boolean | Signal<boolean> | nil,
	TextXAlignment: Enum.TextXAlignment | Signal<Enum.TextXAlignment> | nil,
	TextYAlignment: Enum.TextYAlignment | Signal<Enum.TextYAlignment> | nil
} & _GuiButtonProps
type _TextLabelProps = {
	ContentText: string | Signal<string> | nil,
	Font: Font | Signal<Font> | nil,
	FontFace: Font | Signal<Font> | nil,
	FontSize: Enum.FontSize | Signal<Enum.FontSize> | nil,
	LineHeight: number | Signal<number> | nil,
	LocalizedText: string | Signal<string> | nil,
	MaxVisibleGraphemes: number | Signal<number> | nil,
	RichText: boolean | Signal<boolean> | nil,
	Text: string | Signal<string> | nil,
	TextBounds: Vector2 | Signal<Vector2> | nil,
	TextColor: BrickColor | Signal<BrickColor> | nil,
	TextColor3: Color3 | Signal<Color3> | nil,
	TextDirection: Enum.TextDirection | Signal<Enum.TextDirection> | nil,
	TextFits: boolean | Signal<boolean> | nil,
	TextScaled: boolean | Signal<boolean> | nil,
	TextSize: number | Signal<number> | nil,
	TextStrokeColor3: Color3 | Signal<Color3> | nil,
	TextStrokeTransparency: number | Signal<number> | nil,
	TextTransparency: number | Signal<number> | nil,
	TextTruncate: Enum.TextTruncate | Signal<Enum.TextTruncate> | nil,
	TextWrap: boolean | Signal<boolean> | nil,
	TextWrapped: boolean | Signal<boolean> | nil,
	TextXAlignment: Enum.TextXAlignment | Signal<Enum.TextXAlignment> | nil,
	TextYAlignment: Enum.TextYAlignment | Signal<Enum.TextYAlignment> | nil
} & _GuiLabelProps
type _UIAspectRatioConstraintProps = {
	AspectRatio: number | Signal<number> | nil,
	AspectType: Enum.AspectType | Signal<Enum.AspectType> | nil,
	DominantAxis: Enum.DominantAxis | Signal<Enum.DominantAxis> | nil
} & _UIConstraintProps
type _UIBaseProps = {

} & _InstanceProps
type _UIComponentProps = {

} & _UIBaseProps
type _UIConstraintProps = {

} & _UIComponentProps
type _UICornerProps = {
	CornerRadius: UDim | Signal<UDim> | nil
} & _UIComponentProps
type _UIFlexItemProps = {
	FlexMode: Enum.UIFlexMode | Signal<Enum.UIFlexMode> | nil,
	GrowRatio: number | Signal<number> | nil,
	ItemLineAlignment: Enum.ItemLineAlignment | Signal<Enum.ItemLineAlignment> | nil,
	ShrinkRatio: number | Signal<number> | nil
} & _UIComponentProps
type _UIGradientProps = {
	Color: ColorSequence | Signal<ColorSequence> | nil,
	Enabled: boolean | Signal<boolean> | nil,
	Offset: Vector2 | Signal<Vector2> | nil,
	Rotation: number | Signal<number> | nil,
	Transparency: NumberSequence | Signal<NumberSequence> | nil
} & _UIComponentProps
type _UIGridLayoutProps = {
	AbsoluteCellCount: Vector2 | Signal<Vector2> | nil,
	AbsoluteCellSize: Vector2 | Signal<Vector2> | nil,
	CellPadding: UDim2 | Signal<UDim2> | nil,
	CellSize: UDim2 | Signal<UDim2> | nil,
	FillDirectionMaxCells: number | Signal<number> | nil,
	StartCorner: Enum.StartCorner | Signal<Enum.StartCorner> | nil
} & _UIGridStyleLayoutProps
type _UIGridStyleLayoutProps = {
	AbsoluteContentSize: Vector2 | Signal<Vector2> | nil,
	FillDirection: Enum.FillDirection | Signal<Enum.FillDirection> | nil,
	HorizontalAlignment: Enum.HorizontalAlignment | Signal<Enum.HorizontalAlignment> | nil,
	SortOrder: Enum.SortOrder | Signal<Enum.SortOrder> | nil,
	VerticalAlignment: Enum.VerticalAlignment | Signal<Enum.VerticalAlignment> | nil
} & _UILayoutProps
type _UILayoutProps = {

} & _UIComponentProps
type _UIListLayoutProps = {
	HorizontalFlex: Enum.UIFlexAlignment | Signal<Enum.UIFlexAlignment> | nil,
	ItemLineAlignment: Enum.ItemLineAlignment | Signal<Enum.ItemLineAlignment> | nil,
	Padding: UDim | Signal<UDim> | nil,
	VerticalFlex: Enum.UIFlexAlignment | Signal<Enum.UIFlexAlignment> | nil,
	Wraps: boolean | Signal<boolean> | nil
} & _UIGridStyleLayoutProps
type _UIPaddingProps = {
	PaddingBottom: UDim | Signal<UDim> | nil,
	PaddingLeft: UDim | Signal<UDim> | nil,
	PaddingRight: UDim | Signal<UDim> | nil,
	PaddingTop: UDim | Signal<UDim> | nil
} & _UIComponentProps
type _UIPageLayoutProps = {
	Animated: boolean | Signal<boolean> | nil,
	Circular: boolean | Signal<boolean> | nil,
	CurrentPage: GuiObject | Signal<GuiObject> | nil,
	EasingDirection: Enum.EasingDirection | Signal<Enum.EasingDirection> | nil,
	EasingStyle: Enum.EasingStyle | Signal<Enum.EasingStyle> | nil,
	GamepadInputEnabled: boolean | Signal<boolean> | nil,
	Padding: UDim | Signal<UDim> | nil,
	ScrollWheelInputEnabled: boolean | Signal<boolean> | nil,
	TouchInputEnabled: boolean | Signal<boolean> | nil,
	TweenTime: number | Signal<number> | nil
} & _UIGridStyleLayoutProps
type _UIScaleProps = {
	Scale: number | Signal<number> | nil
} & _UIComponentProps
type _UISizeConstraintProps = {
	MaxSize: Vector2 | Signal<Vector2> | nil,
	MinSize: Vector2 | Signal<Vector2> | nil
} & _UIConstraintProps
type _UIStrokeProps = {
	ApplyStrokeMode: Enum.ApplyStrokeMode | Signal<Enum.ApplyStrokeMode> | nil,
	Color: Color3 | Signal<Color3> | nil,
	Enabled: boolean | Signal<boolean> | nil,
	LineJoinMode: Enum.LineJoinMode | Signal<Enum.LineJoinMode> | nil,
	Thickness: number | Signal<number> | nil,
	Transparency: number | Signal<number> | nil
} & _UIComponentProps
type _UITableLayoutProps = {
	FillEmptySpaceColumns: boolean | Signal<boolean> | nil,
	FillEmptySpaceRows: boolean | Signal<boolean> | nil,
	MajorAxis: Enum.TableMajorAxis | Signal<Enum.TableMajorAxis> | nil,
	Padding: UDim2 | Signal<UDim2> | nil
} & _UIGridStyleLayoutProps
type _UITextSizeConstraintProps = {
	MaxTextSize: number | Signal<number> | nil,
	MinTextSize: number | Signal<number> | nil
} & _UIConstraintProps
type _VideoFrameProps = {
	IsLoaded: boolean | Signal<boolean> | nil,
	Looped: boolean | Signal<boolean> | nil,
	Playing: boolean | Signal<boolean> | nil,
	Resolution: Vector2 | Signal<Vector2> | nil,
	TimeLength: number | Signal<number> | nil,
	TimePosition: number | Signal<number> | nil,
	Video: unknown | Signal<unknown> | nil,
	Volume: number | Signal<number> | nil
} & _GuiObjectProps
type _ViewportFrameProps = {
	Ambient: Color3 | Signal<Color3> | nil,
	CurrentCamera: Camera | Signal<Camera> | nil,
	ImageColor3: Color3 | Signal<Color3> | nil,
	ImageTransparency: number | Signal<number> | nil,
	LightColor: Color3 | Signal<Color3> | nil,
	LightDirection: Vector3 | Signal<Vector3> | nil
} & _GuiObjectProps
-- Code
function Rover.CanvasGroup(props: _CanvasGroupProps, content: ((elm: CanvasGroup) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("CanvasGroup", props, content or function() end)
end

function Rover.Frame(props: _FrameProps, content: ((elm: Frame) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("Frame", props, content or function() end)
end

function Rover.GuiBase(props: _GuiBaseProps, content: ((elm: GuiBase) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("GuiBase", props, content or function() end)
end

function Rover.GuiBase2d(props: _GuiBase2dProps, content: ((elm: GuiBase2d) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("GuiBase2d", props, content or function() end)
end

function Rover.GuiButton(props: _GuiButtonProps, content: ((elm: GuiButton) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("GuiButton", props, content or function() end)
end

function Rover.GuiLabel(props: _GuiLabelProps, content: ((elm: GuiLabel) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("GuiLabel", props, content or function() end)
end

function Rover.GuiObject(props: _GuiObjectProps, content: ((elm: GuiObject) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("GuiObject", props, content or function() end)
end

function Rover.ImageButton(props: _ImageButtonProps, content: ((elm: ImageButton) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("ImageButton", props, content or function() end)
end

function Rover.ImageLabel(props: _ImageLabelProps, content: ((elm: ImageLabel) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("ImageLabel", props, content or function() end)
end

function Rover.Instance(props: _InstanceProps, content: ((elm: Instance) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("Instance", props, content or function() end)
end

function Rover.ScrollingFrame(props: _ScrollingFrameProps, content: ((elm: ScrollingFrame) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("ScrollingFrame", props, content or function() end)
end

function Rover.TextBox(props: _TextBoxProps, content: ((elm: TextBox) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("TextBox", props, content or function() end)
end

function Rover.TextButton(props: _TextButtonProps, content: ((elm: TextButton) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("TextButton", props, content or function() end)
end

function Rover.TextLabel(props: _TextLabelProps, content: ((elm: TextLabel) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("TextLabel", props, content or function() end)
end

function Rover.UIAspectRatioConstraint(props: _UIAspectRatioConstraintProps, content: ((elm: UIAspectRatioConstraint) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("UIAspectRatioConstraint", props, content or function() end)
end

function Rover.UIBase(props: _UIBaseProps, content: ((elm: UIBase) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("UIBase", props, content or function() end)
end

function Rover.UIComponent(props: _UIComponentProps, content: ((elm: UIComponent) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("UIComponent", props, content or function() end)
end

function Rover.UIConstraint(props: _UIConstraintProps, content: ((elm: UIConstraint) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("UIConstraint", props, content or function() end)
end

function Rover.UICorner(props: _UICornerProps, content: ((elm: UICorner) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("UICorner", props, content or function() end)
end

function Rover.UIFlexItem(props: _UIFlexItemProps, content: ((elm: UIFlexItem) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("UIFlexItem", props, content or function() end)
end

function Rover.UIGradient(props: _UIGradientProps, content: ((elm: UIGradient) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("UIGradient", props, content or function() end)
end

function Rover.UIGridLayout(props: _UIGridLayoutProps, content: ((elm: UIGridLayout) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("UIGridLayout", props, content or function() end)
end

function Rover.UIGridStyleLayout(props: _UIGridStyleLayoutProps, content: ((elm: UIGridStyleLayout) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("UIGridStyleLayout", props, content or function() end)
end

function Rover.UILayout(props: _UILayoutProps, content: ((elm: UILayout) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("UILayout", props, content or function() end)
end

function Rover.UIListLayout(props: _UIListLayoutProps, content: ((elm: UIListLayout) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("UIListLayout", props, content or function() end)
end

function Rover.UIPadding(props: _UIPaddingProps, content: ((elm: UIPadding) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("UIPadding", props, content or function() end)
end

function Rover.UIPageLayout(props: _UIPageLayoutProps, content: ((elm: UIPageLayout) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("UIPageLayout", props, content or function() end)
end

function Rover.UIScale(props: _UIScaleProps, content: ((elm: UIScale) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("UIScale", props, content or function() end)
end

function Rover.UISizeConstraint(props: _UISizeConstraintProps, content: ((elm: UISizeConstraint) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("UISizeConstraint", props, content or function() end)
end

function Rover.UIStroke(props: _UIStrokeProps, content: ((elm: UIStroke) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("UIStroke", props, content or function() end)
end

function Rover.UITableLayout(props: _UITableLayoutProps, content: ((elm: UITableLayout) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("UITableLayout", props, content or function() end)
end

function Rover.UITextSizeConstraint(props: _UITextSizeConstraintProps, content: ((elm: UITextSizeConstraint) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("UITextSizeConstraint", props, content or function() end)
end

function Rover.VideoFrame(props: _VideoFrameProps, content: ((elm: VideoFrame) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("VideoFrame", props, content or function() end)
end

function Rover.ViewportFrame(props: _ViewportFrameProps, content: ((elm: ViewportFrame) -> ())?): ()
	Rover.drawInstance_internal_039eaddbd4712a("ViewportFrame", props, content or function() end)
end

-- END AUTOGEN

return Rover
