return {
	Open = function(Manager,door)
		door.Parent.door.Transparency = 1
		return true
	end,
	Close = function(Manager,door)
		door.Parent.door.Transparency = 0
		return true
	end,
}