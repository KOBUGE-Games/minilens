
extends Node

var file_lines_cache = {}
var file_passwords = {}

func _open_file_wrapper(file, path, flag): # Private
	if file_passwords.has(path):
		return file.open_encrypted_with_pass(path, flag, file_passwords[path])
	else:
		return file.open(path, flag)

func set_file_password(path, password):
	file_passwords[path] = password

func get_file_lines(path):
	"""Returns an array of the lines of the file at `path`"""
	
	if !file_lines_cache.has(path): # Nothing in cache, we have to read the file anew
		var file = File.new()
		var error = _open_file_wrapper(file, path, File.READ)
		
		if error != OK:
			return [] # Don't save to file_lines_cache, so that we would retry the next time
		else:
			file_lines_cache[path] = [] # We write directly in the cache
			
			while !file.eof_reached():
				file_lines_cache[path].push_back(file.get_line())
	
	return file_lines_cache[path] # Return from cache, since we are now sure the entry exists

func set_file_lines(path, lines):
	"""Update the array of the lines of the file at `path`"""
	
	var file = File.new()
	var error = _open_file_wrapper(file, path, File.WRITE)
	
	if error != OK:
		return error # Don't save to file_lines_cache, so that it would still be a valid representation of the real file
	else:
		file_lines_cache[path] = Array(lines) # We write to the cache
		
		for line in file_lines_cache[path]:
			file.store_line(line)
		
	file.close()
	
	return OK

func get_file_contents(path):
	"""Returns a string of the whole contents of the file at `path`"""
	
	var lines = get_file_lines(path)
	var buffer = ""
	var first_line = true
	
	for line in lines:
		if first_line:
			buffer = line # If we join the empty butter with a newline, we would have to cut it off
			first_line = false
		else:
			buffer = str(buffer, "\n", line)
	
	return buffer

func set_file_contents(path, buffer):
	"""Update the whole contents of the file at `path`"""
	
	return set_file_lines(path, buffer.split("\n"))
