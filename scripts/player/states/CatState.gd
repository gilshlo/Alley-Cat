class_name CatState
extends RefCounted
## State objects never own the cat; the cat releases them on scene teardown.
var cat: Cat

func enter() -> void:
	return

func exit() -> void:
	return

func physics_update(delta: float) -> void:
	cat.apply_gravity(delta)
	cat.steer(delta)
