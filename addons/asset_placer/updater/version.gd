extends RefCounted
class_name Version

var major: int
var minor: int
var patch: int
var identifier: String

func _init(version: String):
	var regex := RegEx.new()
	regex.compile(r"^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:-(?P<prerelease>(?:[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)))?(?:\+(?P<build>[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$")
	
	var result := regex.search(version)
	if result:
		major = int(result.get_string("major"))
		minor = int(result.get_string("minor"))
		patch = int(result.get_string("patch"))
		identifier = result.get_string("prerelease") if result.get_string("prerelease") != "" else ""


func _to_string():
	var main = "%s.%s.%s" % [major, minor, patch]
	return main if identifier.is_empty() else main + "-%s" % identifier


func changelog_version() -> String:
	var main = "%s%s%s" % [major, minor, patch]
	return main if identifier.is_empty() else main + "---%s" % identifier 
	
	
func compare_to(other: Version) -> int:
	# Compare MAJOR
	if major < other.major:
		return -1
	elif major > other.major:
		return 1
	
	# Compare MINOR
	if minor < other.minor:
		return -1
	elif minor > other.minor:
		return 1
	
	# Compare PATCH
	if patch < other.patch:
		return -1
	elif patch > other.patch:
		return 1
	
	# Compare prerelease identifiers
	return compare_prerelease(identifier, other.identifier)

func compare_prerelease(id1: String, id2: String) -> int:
	# Empty identifier means release version (highest precedence)
	var pre1 = id1.split(".") if id1 != "" else []
	var pre2 = id2.split(".") if id2 != "" else []
	
	if pre1.empty() and pre2.empty():
		return 0
	if pre1.empty():
		return 1  # release > prerelease
	if pre2.empty():
		return -1 # prerelease < release
	
	var len_min = min(pre1.size(), pre2.size())
	for i in range(len_min):
		var part1 = pre1[i]
		var part2 = pre2[i]
		
		var is_num1 = part1.is_valid_integer()
		var is_num2 = part2.is_valid_integer()
		
		if is_num1 and is_num2:
			var n1 = int(part1)
			var n2 = int(part2)
			if n1 < n2:
				return -1
			elif n1 > n2:
				return 1
		elif is_num1 and not is_num2:
			return -1  # numeric < alphanumeric
		elif not is_num1 and is_num2:
			return 1
		else:
			if part1 < part2:
				return -1
			elif part1 > part2:
				return 1

	# If all matched so far, shorter prerelease wins
	if pre1.size() < pre2.size():
		return -1
	elif pre1.size() > pre2.size():
		return 1
	
	return 0
