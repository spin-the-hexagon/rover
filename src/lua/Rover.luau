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

--!strict

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

function Rover.subcontext_internal(next: Context, content: (instance: any) -> ()): ()
	local prev = context

	context = next
	
	content(next.container)

	context = prev
end

function Rover.drawInstance_internal(
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

	Rover.subcontext_internal({ 
		container = instance
	}, content)
end

function Rover.render(container: Instance, content: () -> nil) : ()
	Rover.subcontext_internal({
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

	Rover.subcontext_internal({
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
			Rover.subcontext_internal(snapshot, function()
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

-- AUTOGEN

return Rover
