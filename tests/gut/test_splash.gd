extends GutTest

## The studio splash fades in, holds and fades out, then hands over to the main menu once. Any
## key or click hands over straight away. The hand-over is swapped for a counter here, so the
## test scene isn't replaced by the menu.

const SPLASH_SCENE := preload("res://menus/splash_screen.tscn")

var _splash: SplashScreen
var _hand_overs := 0


func before_each() -> void:
	_hand_overs = 0
	_splash = SPLASH_SCENE.instantiate()
	_splash.hand_over = func() -> void: _hand_overs += 1
	_splash.set_process(false)  # Only advance() moves the splash on
	add_child_autofree(_splash)


func test_fades_in_holds_and_fades_out() -> void:
	assert_eq(_splash.opacity(), 0.0, "it starts hidden")
	_splash.advance(SplashScreen.FADE_IN_SECONDS / 2.0)
	assert_almost_eq(_splash.opacity(), 0.5, 0.01, "half way through fading in")
	_splash.advance(SplashScreen.FADE_IN_SECONDS / 2.0 + SplashScreen.HOLD_SECONDS / 2.0)
	assert_eq(_splash.opacity(), 1.0, "fully shown while it holds")
	_splash.advance(SplashScreen.HOLD_SECONDS / 2.0 + SplashScreen.FADE_OUT_SECONDS / 2.0)
	assert_almost_eq(_splash.opacity(), 0.5, 0.01, "half way through fading out")
	assert_eq(_hand_overs, 0, "the menu waits until the splash is over")


func test_hands_over_once_when_it_ends() -> void:
	assert_almost_eq(_splash.total_seconds(), 2.5, 0.01, "the splash runs about 2.5 seconds")
	_splash.advance(_splash.total_seconds())
	assert_true(_splash.is_finished(), "the splash is over")
	assert_eq(_hand_overs, 1, "the main menu opens")
	_splash.advance(1.0)
	assert_eq(_hand_overs, 1, "and only once")


func test_a_key_skips_it() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	_splash._unhandled_input(key)
	assert_eq(_hand_overs, 1, "a key press opens the menu straight away")
	_splash.advance(_splash.total_seconds())
	assert_eq(_hand_overs, 1, "and the splash doesn't open it again")


func test_a_click_skips_it() -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	_splash._unhandled_input(click)
	assert_eq(_hand_overs, 1, "a click opens the menu straight away")


func test_releasing_a_key_does_not_skip_it() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = false
	_splash._unhandled_input(key)
	assert_eq(_hand_overs, 0, "letting go of a key doesn't skip it")


func test_is_the_main_scene() -> void:
	assert_eq(
		ProjectSettings.get_setting("application/run/main_scene"),
		"res://menus/splash_screen.tscn",
		"the game starts on the splash"
	)
