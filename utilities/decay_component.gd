@tool
class_name DecayComponent
extends Node2D

## Damage of the decay
@export var decay_strength: float = 1.0

## How often decay happens in seconds
@export var decay_tick_rate: float = 1.0:
	set(tr):
		if tr <= 0:
			return
		decay_tick_rate = tr

@export var health_component: HealthComponent

@onready var timer: Timer = $Timer

func _ready() -> void:
	assert(health_component, "Decay Component needs to target a health component")
	timer.wait_time = decay_tick_rate


func start_decay() -> void:
	timer.start()


func stop_decay() -> void:
	timer.stop()


func _on_timer_timeout() -> void:
	#print("Decay Timer Timeout")
	health_component.take_damage(decay_strength)
