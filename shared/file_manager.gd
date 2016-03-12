
extends Node

var file_lines_cache = {}

func get_file_lines(path):
	"""Returns an array of the lines of the file at `path`"""
	
	if !file_lines_cache.has(path): # Nothing in cache, we have to read the file anew
		var file = File.new()
		var error = file.open(path, File.READ)
		
		if error != OK:
			return [] # Don't save to file_lines_cache, so that we would retry the next time
		else:
			file_lines_cache[path] = [] # We write directly in the cache
			
			while !file.eof_reached():
				file_lines_cache[path].push_back(file.get_line())
	
	return file_lines_cache[path] # Return from cache, since we are now sure the entry exists 

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