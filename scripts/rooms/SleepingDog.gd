class_name SleepingDog
extends Node2D

signal awakened()
signal alert_changed(value: float)

@export var hearing_radius: float = 175.0
@export var wake_threshold: float = 1.0
@export var recovery_per_second: float = 0.045
var alert: float = 0.0
var awake: bool = false
var _age: float = 0.0

func _physics_process(delta: float) -> void:
	_age += delta
	if not awake:
		alert = maxf(0.0, alert - recovery_per_second * delta)
	queue_redraw()

func add_noise(amount: float, source: Vector2) -> void:
	if awake:
		return
	# Inverse linear attenuation within the hearing radius, with a small
	# room-wide contribution for repeated impacts far from the sleeping dog.
	var attenuation: float = clampf(1.0 - source.distance_to(global_position) / hearing_radius, 0.08, 1.0)
	alert = clampf(alert + maxf(0.0, amount) * attenuation, 0.0, wake_threshold)
	alert_changed.emit(alert / wake_threshold)
	if alert >= wake_threshold:
		wake()

func wake() -> void:
	if awake:
		return
	awake = true
	alert = wake_threshold
	AudioManager.play_sfx(&"bark", 0.8)
	awakened.emit()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-35, 10, 70, 8), Color("956574"))
	var breathing: float = sin(_age * 2.0) * 1.5 if not awake else -6.0
	draw_rect(Rect2(-26, -9 + breathing, 44, 21), Color("b68a70"))
	draw_rect(Rect2(-33, -4 + breathing, 19, 16), Color("d6ac86"))
	draw_rect(Rect2(-21, -9 + breathing, 7, 12), Color("725566"))
	draw_line(Vector2(-30, 2 + breathing), Vector2(-26, 2 + breathing), Color("533f53"), 2.0)
	if awake:
		draw_rect(Rect2(-30, -7, 4, 4), Color("ff7878"))
	else:
		draw_string(ThemeDB.fallback_font, Vector2(-5, -24 + sin(_age) * 3), "z Z", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("c7b8d7"))
