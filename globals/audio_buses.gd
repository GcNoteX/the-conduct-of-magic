class_name AudioBuses
extends RefCounted

## Names of the audio buses in default_bus_layout.tres, so code never spells them out. Music and
## SFX each send to Master, so a settings menu can set their volumes apart.

const MASTER := &"Master"
const MUSIC := &"Music"
const SFX := &"SFX"
