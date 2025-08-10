extends RefCounted
class_name Version

var major: int
var minor: int
var patch: int
var identifier: Identifier


enum Track {
	Alpha = 0,
	Beta = 1,
	ReleaseCandidate = 2,
}

class Identifier: 
	var track: Track
	var number: int
	
	func _to_string() -> String:
		var _track: String
		match track:
			Track.Alpha: _track = "alpha"
			Track.Beta: _track = "beta"
			Track.ReleaseCandidate: _track = "rc"
		return "%s%d" % [_track, number]

func _init(version: String):
	var regex := RegEx.new()
	regex.compile(r"^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:-(?P<prerelease>(?:[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)))?(?:\+(?P<build>[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$")
	
	var result := regex.search(version)
	if result:
		major = int(result.get_string("major"))
		minor = int(result.get_string("minor"))
		patch = int(result.get_string("patch"))
		var _identifier = result.get_string("prerelease") if result.get_string("prerelease") != "" else ""
		self.identifier = _parse_identifier(_identifier)


func _to_string():
	var main = "%s.%s.%s" % [major, minor, patch]
	return main if identifier == null else main + "-%s" % identifier._to_string()


func changelog_version() -> String:
	var main = "%s%s%s" % [major, minor, patch]
	return main if identifier == null else main + "---%s" % identifier ._to_string()
	
	
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

func compare_prerelease(id1: Identifier, id2: Identifier) -> int:
	
	if id1 == null:
		return 1
	if id2 == null:
		return -1
	
	if id1.track == id2.track:
		var diff = id1.number - id2.number;
		return clampi(diff, -1, 1)
	else:
		var track_diff = (id1.track - id2.track)
		return clamp(track_diff, -1, 1)

static func _parse_identifier(text: String) -> Identifier:
	
	if text.is_empty(): return null
	
	# Match alpha04, beta03, rc12 (case-insensitive)
	var regex := RegEx.new()
	regex.compile(r"(?i)^(alpha|beta|rc)(\d+)$")
	
	var match := regex.search(text.strip_edges())
	if not match:
		push_error("Invalid identifier format: %s" % text)
		return null
	
	var track_str := match.get_string(1).to_lower()
	var number_str := match.get_string(2)
	
	var track_map := {
		"alpha": Track.Alpha,
		"beta": Track.Beta,
		"rc": Track.ReleaseCandidate
	}
	
	var id := Identifier.new()
	id.track = track_map[track_str]
	id.number = int(number_str)
	return id
