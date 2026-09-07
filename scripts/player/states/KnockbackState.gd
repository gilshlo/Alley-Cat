class_name KnockbackState
extends CatState

func physics_update(delta: float) -> void:
	cat.apply_gravity(delta)
	cat.velocity.x = move_toward(cat.velocity.x, 0.0, 230.0 * delta)
	cat.knockback_time = maxf(cat.knockback_time - delta, 0.0)
	if cat.knockback_time == 0.0:
		cat.change_state(Cat.State.IDLE if cat.is_on_floor() else Cat.State.JUMP)
