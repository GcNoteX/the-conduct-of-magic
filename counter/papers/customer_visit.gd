class_name CustomerVisit
extends Resource

## One customer at the counter: the day they come, their commission slip and any papers they show.

## The day they come, counting from 1
@export var day: int = 1
@export var slip: CommissionSlip
@export var adventurer_id: AdventurerId
@export var permit: Permit
