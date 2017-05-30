tool
extends Node2D

export var offset = 0
export var centered = false

func _ready():
	if get_parent() extends Control:
		get_parent().connect("resized", self, "repos_to_parent_control")
		repos_to_parent_control()
	elif get_parent() extends CanvasItem:
		get_parent().connect("item_rect_changed", self, "resize_to_parent_canvasitem")
		resize_to_parent_canvasitem()

func _exit_tree():
	if get_parent() extends Control:
		get_parent().disconnect("resized", self, "repos_to_parent_control")
	elif get_parent() extends CanvasItem:
		get_parent().disconnect("item_rect_changed", self, "resize_to_parent_canvasitem")

func resize_to(target_size):
	var original_size = get_item_rect().size
	var target_size_rotated = target_size.rotated(get_rot())
	target_size_rotated = Vector2(abs(target_size_rotated.x), abs(target_size_rotated.y))
	set_scale(target_size_rotated / original_size)
	if !centered:
		set_pos(target_size * (Vector2(0.5,0.5) + Vector2(-0.5, -0.5).rotated(get_rot())))

func repos_to_parent_control():
	set_pos(Vector2(get_parent().get_size().x-offset, 0))

func resize_to_parent_canvasitem():
	resize_to(get_parent().get_item_rect())
