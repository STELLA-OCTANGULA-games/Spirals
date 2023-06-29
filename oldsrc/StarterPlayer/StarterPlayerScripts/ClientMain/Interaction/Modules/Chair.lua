return function(movementManager,interactable)
	print("Ran chair module.")
	movementManager.DeselectInteract()
	wait(1)
	movementManager.SetDebounce(false)
end