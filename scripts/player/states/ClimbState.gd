class_name ClimbState
extends CatState

func enter() -> void:
	cat.velocity = Vector2.ZERO
	cat.global_position.y = cat.active_line.global_position.y + 12.0
	AudioManager.play_sfx(&"grab")

func exit() -> void:
	cat.active_line = null
	cat.grab_lock = 0.24

func physics_update(_delta: float) -> void:
	if not is_instance_valid(cat.active_line):
		cat.change_state(Cat.State.JUMP)
		return
	if cat.consume_jump():
		return
	if cat.control_enabled and Input.is_action_just_pressed("drop"):
		cat.velocity.y = 70.0
		cat.change_state(Cat.State.JUMP)
		return
	var left: float = cat.active_line.global_position.x - cat.active_line.length * 0.5 + 7.0
	var right: float = cat.active_line.global_position.x + cat.active_line.length * 0.5 - 7.0
	cat.global_position.x = clampf(cat.global_position.x, left, right)
	cat.velocity = Vector2(cat.axis * cat.climb_speed, 0.0)
	if (cat.global_position.x <= left and cat.axis < 0.0) or (cat.global_position.x >= right and cat.axis > 0.0):
		cat.velocity.x = 0.0
