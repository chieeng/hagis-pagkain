class_name DebugTools
extends RefCounted
## Command-line helpers for checking the game without a person playing it.
##   godot -- --autoplay --nosave --shots=C:/path/to/folder
## --autoplay  plays by itself (mostly correct throws, some misses) and quits at the end
## --nosave    does not read or write the save file or play log
## --shots=DIR saves screenshots of key moments into DIR


static func has_arg(name: String) -> bool:
	return name in OS.get_cmdline_user_args()


static func arg_value(prefix: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(prefix + "="):
			return a.substr(prefix.length() + 1)
	return ""


## Saves a screenshot if --shots=DIR was given. Call with `await`.
static func snap(node: Node, file_name: String) -> void:
	var dir := arg_value("--shots")
	if dir == "":
		return
	await RenderingServer.frame_post_draw
	var img := node.get_viewport().get_texture().get_image()
	img.save_png(dir.path_join(file_name + ".png"))
