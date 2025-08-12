extends RefCounted
class_name PluginUpdaterHttpClient

var _client = HTTPClient.new()

signal client_response(body: PackedByteArray)


func client_get(url: String):
	AssetPlacerAsync.instance.enqueue(func(): 
		var response = _client_get(url)
		call_deferred("emit_signal", "client_response", response)
	)

	
	
func _client_get(url: String) -> PackedByteArray:
	var parts = url.split("/", false, 2)
	var host = parts[0] + "//" + parts[1]
	_client.connect_to_host(host)
	_do_connection_polling()
	_client.request(HTTPClient.METHOD_GET,  "/" + parts[2], [])
	_do_response_polling()
	
	if _client.get_response_code() in [301, 302, 308]:
		var location = _client.get_response_headers_as_dictionary()["Location"]
		_client.close()
		await_disconection()
		return _client_get(location)
	
	var response = _do_response_body_polling()	
	_client.close()
	return response

func _do_response_body_polling() -> PackedByteArray:
	var response_body = PackedByteArray()
	while _client.get_status() == HTTPClient.STATUS_BODY:
		_client.poll()
		var chunk = _client.read_response_body_chunk()
		if chunk.size() != 0:
			response_body +=  chunk
			
	return response_body	

func _do_connection_polling():
	while _is_connecting():
		_client.poll()
		
func _do_response_polling():
	while _is_wating_for_response():
		_client.poll()


func _is_wating_for_response() -> bool:
	return _client.get_status() == HTTPClient.STATUS_REQUESTING
	

func await_disconection():
	while(_client.get_status() != HTTPClient.STATUS_DISCONNECTED):
		_client.poll()	

func _is_connecting() -> bool:
	var status = _client.get_status()
	return status == HTTPClient.STATUS_CONNECTING or status == HTTPClient.STATUS_RESOLVING
