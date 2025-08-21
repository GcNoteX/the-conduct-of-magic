class_name HealthComponent
extends Node2D

signal health_updated
signal health_depleted

@export var max_health: float = 100:
	set(m):
		if m <= 0:
			max_health = 1
		else:
			max_health = m

@export var health: float = 100:
	set(h):
		if h < 0:
			health = 0
			emit_signal("health_updated")
			emit_signal("health_depleted")
		else:
			health = min(h, max_health)
			emit_signal("health_updated")

func take_damage(damage: float) -> void:
	health -= damage

func heal_health(healing: float) -> void:
	health += healing
