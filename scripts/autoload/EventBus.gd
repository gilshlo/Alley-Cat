extends Node
## Global signals carry values, never references to scene-owned nodes.

signal run_started()
signal score_changed(score: int, multiplier: int)
signal lives_changed(lives: int)
signal room_entered(room_id: int, attempt_id: int)
signal room_finished(room_id: int, won: bool, points: int)
signal run_over(final_score: int)
signal notification(text: String)
signal cat_hurt(world_position: Vector2)
## impact_speed is the downward speed immediately before move_and_slide().
signal cat_landed(world_position: Vector2, impact_speed: float)
