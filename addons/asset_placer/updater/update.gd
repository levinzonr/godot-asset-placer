extends RefCounted
class_name PluginUpdate

var version: Version
var change_log: String
var download_url: String



func _init(version: String, change_log: String, download_url: String):
	self.version = Version.new(version)
	self.change_log = change_log
	self.download_url = download_url
