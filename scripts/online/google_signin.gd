class_name GoogleSignIn
extends RefCounted
## Đăng nhập Google trên bản web: cầu nối JavaScriptBridge tới `window.eclipseGoogle` (định nghĩa trong
## tools/web/shell.html, dùng Google Identity Services). Nút Google là nút thật của trình duyệt phủ lên canvas
## (trình duyệt chỉ cho cửa sổ đăng nhập mở khi người dùng bấm vào nút của chính Google).
## Chỉ lấy ID token và phát tín hiệu; máy chủ mới là nơi xác minh token (OnlineService.login_google).
## Bản không phải web: supported() = false, không làm gì.

signal credential_received(id_token: String)
signal failed(reason: String)

var _on_credential: JavaScriptObject
var _on_error: JavaScriptObject


static func supported() -> bool:
	return OS.has_feature("web")


## Hiện nút Google với Client ID của máy chủ. Trả về false nếu không chạy được (không phải web, thiếu thư viện).
func show_button(client_id: String) -> bool:
	if not supported() or client_id.is_empty():
		return false
	var win := JavaScriptBridge.get_interface("window")
	if win == null or win.eclipseGoogle == null:
		failed.emit("GOOGLE_NO_BRIDGE")
		return false
	_on_credential = JavaScriptBridge.create_callback(_credential_from_js)
	_on_error = JavaScriptBridge.create_callback(_error_from_js)
	win.eclipseGoogle.show(client_id, _on_credential, _on_error)
	return true


func hide_button() -> void:
	if not supported():
		return
	var win := JavaScriptBridge.get_interface("window")
	if win != null and win.eclipseGoogle != null:
		win.eclipseGoogle.hide()


func _credential_from_js(args: Array) -> void:
	if args.size() > 0 and not str(args[0]).is_empty():
		credential_received.emit(str(args[0]))


func _error_from_js(args: Array) -> void:
	failed.emit(str(args[0]) if args.size() > 0 else "GOOGLE_ERROR")
