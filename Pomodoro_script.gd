extends Node


const SWITCH = preload("res://switch_sound.wav")
const START = preload("res://pause_play_sound.wav")
const TIMEUP = preload("res://Rick roll.wav")

onready var play_button = $Control/play_button
onready var pause_button = $Control/pause_button
onready var switch_button = $Control/switch
onready var stop_button = $Control/stop

onready var label = $Control/text_label
onready var switch_label =  $Control/switch/Label
onready var cancel_label = $Control/stop/Label
onready var ratio_label = $Control/ratio
onready var study_label = $Control/study_count
onready var play_label = $Control/play_count

onready var timer = $Timer
onready var update_tween = $Control/ColorRect/Tween
onready var bg = $Control/bg
onready var progress_bar = $Control/ColorRect/progress_bar

enum {
	FOCUS,
	RECESS
}

var state = FOCUS

var studied_time = 0
var recess_time = 0
var progress = 0
	
func _ready():
	timer.wait_time = 3600
	

# warning-ignore:unused_argument
func _physics_process(delta):
	match state:
		FOCUS:
			focus_state()
		RECESS:
			recess_state()
	if timer.time_left > 0 == true:
		switch_button.visible = false
		switch_button.disabled = true
		ratio_label.visible = false
		study_label.visible = false
		play_label.visible = false
		label.text = "%d:%02d" % [floor(timer.time_left / 60), int(timer.time_left) % 60]
	else:
		switch_button.visible = true
		switch_button.disabled = false
		ratio_label.visible = true
		study_label.visible = true
		play_label.visible = true
		
				
func focus_state():
	switch_label.text = "focus"
	switch_label.modulate = Color8(255, 85, 81)
	cancel_label.modulate = Color8(255, 85, 81)
	bg.modulate = Color8(255, 85, 81)
	pause_button.modulate = Color8(255, 85, 81)
	play_button.modulate = Color8(255, 85, 81)
	progress_bar.material.set("shader_param/water_color_1", Color8(254, 194, 192))
	progress_bar.material.set("shader_param/water_color_2", Color8(255, 68, 64))
	#progress_bar.modulate = Color8(255, 85, 81)


func recess_state():
	switch_label.text = "play"
	switch_label.modulate = Color8(3, 172, 164)
	cancel_label.modulate = Color8(3, 172, 164)
	bg.modulate = Color8(3, 172, 164)
	pause_button.modulate = Color8(3, 172, 164)
	play_button.modulate = Color8(3, 172, 164)
	progress_bar.material.set("shader_param/water_color_1", Color8(191, 255, 252))
	progress_bar.material.set("shader_param/water_color_2", Color8(0, 198, 189))
	#progress_bar.modulate = Color8(3, 172, 164)


func _on_switch_pressed():
	if timer.time_left == 0:
		$Audio.stream = SWITCH
		$Audio.play()
		if state == FOCUS:
			state = RECESS
			label.text = "20:00"
			timer.wait_time = 1200
		elif state == RECESS:
			state = FOCUS
			label.text = "60:00"
			timer.wait_time = 3600


func _on_play_button_pressed():
	$Audio.stream = START
	$Audio.play()
	
	play_button.visible  = false
	play_button.disabled = true
	
	pause_button.visible = true
	pause_button.disabled = false
	
	stop_button.visible = false
	stop_button.disabled = true
	
	if timer.time_left == 0:
		update_tween.interpolate_property(progress_bar.get_material(), "shader_param/percentage", 1, 0, 2, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		update_tween.start()
		yield(get_tree().create_timer(2), "timeout")
		timer.start()
		update_tween.interpolate_property(progress_bar.get_material(), "shader_param/percentage", 0, 1, timer.time_left, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		update_tween.start()
		return
	update_tween.set_active(true)
	timer.paused = false


func _on_pause_button_pressed():
	$Audio.stream = START
	$Audio.play()
	timer.paused = true
	stop_button.visible = true
	stop_button.disabled = false
	update_tween.set_active(false)
	common_button_task()


func _on_Timer_timeout():
	var elapsed_time = timer.wait_time - timer.time_left
	if state == FOCUS:
		studied_time += elapsed_time
	elif state == RECESS:
		recess_time += elapsed_time
	process_time()
	common_button_task()
	$Audio.stream = TIMEUP
	$Audio.play()

	
func common_button_task():
	pause_button.visible = false
	pause_button.disabled = true
	
	play_button.visible = true
	play_button.disabled = false	

func _on_stop_pressed():
	$Audio.stream = SWITCH
	$Audio.play()
	
	var elapsed_time = timer.wait_time - timer.time_left
	
	var current_tween_time = stepify(update_tween.tell()/timer.wait_time, 0.001)
	update_tween.stop_all()
	update_tween.set_active(true)
	print(current_tween_time)
	update_tween.interpolate_property(progress_bar.get_material(), "shader_param/percentage", current_tween_time, 1, 5, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	update_tween.start()
	
	timer.paused = false
	timer.stop()
	if state == FOCUS:
		studied_time += elapsed_time
		label.text = "60:00"
		timer.wait_time = 3600
	elif state == RECESS:
		recess_time += elapsed_time
		label.text = "20:00"
		timer.wait_time = 1200
		
	process_time()
	
	stop_button.visible = false
	stop_button.disabled = true
	
func process_time():
	if floor(studied_time / 60) != 1:
		study_label.text = "WORK: %s mins" % [floor(studied_time / 60)]
	else:
		study_label.text = "WORK: 1 min" 
		
	if floor(recess_time / 60) != 1:
		play_label.text = "PLAY: %s mins" % [floor(recess_time / 60)]
	else:
		play_label.text = "PLAY: 1 min"
	
	ratio_label.text = "work-play \nratio \n \n %s work for \n %s play" % [ratio_calculator(FOCUS), ratio_calculator(RECESS)]
			
func ratio_calculator(mode):
	if mode == FOCUS:
		if floor(studied_time / 60) == 0:
			return "0 mins"
		if floor(studied_time / 60) == 1:
			return "1 min"
		if floor(recess_time / 60) != 0 and floor(studied_time / 60) != 1:
			return (str(stepify((floor(studied_time / 60)/floor(recess_time / 60)), 0.01)) + " mins")
		
	if mode == RECESS:
		if floor(recess_time / 60) == 0:
			return "0 mins"
		if floor(studied_time / 60) != 0:
			return "1 min"
		else:
			return "0 mins"
