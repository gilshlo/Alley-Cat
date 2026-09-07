class_name WalkState
extends CatState

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if cat.consume_jump():
		return
	if not cat.is_on_floor():
		cat.change_state(Cat.State.JUMP)
	elif cat.axis == 0.0:
		cat.change_state(Cat.State.IDLE)
