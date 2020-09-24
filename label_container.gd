extends Control

# 羅生門（芥川龍之介）より抜粋
# https://www.aozora.gr.jp/cards/000879/files/127_15260.html
export(String, MULTILINE) var message = "ただ、所々%ruby{丹塗,にぬり}の%ruby{剥,は}げた、\n大きな%ruby{円柱,まるばしら}に、\n%ruby{蟋蟀,きりぎりす}が一匹とまっている"
export(int) var SPACING = 24
export(int) var SPACING_EXTRA = 3

var rubies: Array = []

# ルビ指定を含むテキストのパース
# ルビ指定はrubies配列に格納し、ルビを除くテキストを返す
func parse() -> String:
	var _message: String = message
	var regex = RegEx.new()
	regex.compile("%ruby\\{(?<text>.+?),(?<ruby>.+?)\\}")
	var i = 0
	var regex_result = regex.search(_message)
	while regex_result:
		var start_idx: int = regex_result.get_start("text")
		var text: String = regex_result.get_string("text")
		var ruby: String = regex_result.get_string("ruby")
		var end_idx: int = start_idx + text.length() + 1 + ruby.length() + 1
		# %ruby{ の 6文字分
		start_idx -= 6
		var m_left: String = _message.substr(i, start_idx)
		var m_right: String = _message.substr(end_idx)
		_message = m_left + text + m_right
		rubies.push_back({"t_idx": m_left.length(), "t_len": text.length(), "text": ruby})
		regex_result = regex.search(_message)
	return _message
		
# メッセージにルビを適用する
func apply():
	var m_label: Label = $Message	
	var m_font: DynamicFont = m_label.get("custom_fonts/font")
	for ruby in rubies:
		# ルビ用Labelを複製
		var r_label: Label = $_Ruby.duplicate()
		var r_font: DynamicFont = r_label.get("custom_fonts/font").duplicate()
		r_label.set("custom_fonts/font", r_font)
		# ルビを指定
		r_label.text = ruby.text
		# ルビのLabelが最小となるように設定
		r_label.rect_size = Vector2(0,0)
		add_child(r_label)
		
		# サイズ・テキスト類の取得
		# ルビ
		var r_size: Vector2 = r_font.get_string_size(ruby.text)
		var r_len: int = r_label.text.length()
		# テキスト
		var t_text: String = m_label.text.substr(ruby.t_idx, ruby.t_len)
		var t_size: Vector2 = m_font.get_string_size(t_text)
		# メッセージ
		var m_text: String = m_label.text
		var m_size: Vector2 = m_font.get_string_size(m_text)
		var m_text_lines: Array = m_text.split("\n")
		m_size.y += m_size.y * (m_text_lines.size() - 1)
		var _li = 0
		# ルビの存在する行
		var m_text_line: String = m_text_lines[_li]
		var _lidx: int = m_text_line.length()
		while _lidx < ruby.t_idx:
			_li += 1
			m_text_line = m_text_lines[_li]
			_lidx += m_text_line.length() + 1
		var m_text_line_size: Vector2 = m_font.get_string_size(m_text_line)
		# メッセージのうち、テキスト直前までのもの
		var m_pre_text: String = m_text.substr(0, ruby.t_idx)
		var m_pre_size: Vector2 = m_font.get_string_size(m_pre_text)
		var m_pre_nl_count: int = m_pre_text.count("\n")
		m_pre_size.y += m_pre_size.y * m_pre_nl_count
		# メッセージのテキスト直前までのもののうち、改行以降のもの
		var m_pre_after_nl_idx: int = m_pre_text.find_last("\n")
		var m_pre_after_nl_size: Vector2 = m_font.get_string_size(m_pre_text.substr(m_pre_after_nl_idx + 1)) if m_pre_after_nl_idx >= 0 else m_pre_size

		# ルビ長が対象より短い場合、スペースを入れて埋める
		if r_size.x < t_size.x:
			r_font.extra_spacing_char = int((t_size.x - r_size.x) / r_len)
			r_size.x += (r_len - 1) * r_font.extra_spacing_char
			
		# いい感じにルビ位置を設定する
		# SPACING/SPACING_EXTRAでルビ位置を微調整している
		var x_spacing: float = 0
		match (m_label.align):
			Label.ALIGN_CENTER:
				x_spacing = (m_label.rect_size.x - m_text_line_size.x) / 2
			Label.ALIGN_RIGHT:
				x_spacing = (m_label.rect_size.x - m_text_line_size.x)
		var y_spacing: float = 0
		match (m_label.valign):
			Label.VALIGN_CENTER:
				y_spacing = (m_label.rect_size.y - m_size.y) / 2
			Label.VALIGN_BOTTOM:
				y_spacing = (m_label.rect_size.y - m_size.y)
			Label.VALIGN_FILL:
				y_spacing += ((m_label.rect_size.y - m_size.y) / (m_text_lines.size() - 1)) * m_pre_nl_count
		var r_pos_x: float = x_spacing + (int(m_pre_after_nl_size.x) % int(m_label.rect_size.x))
		var r_pos_y: float = y_spacing + (m_text_line_size.y * m_pre_nl_count + SPACING - r_size.y + SPACING_EXTRA * m_pre_nl_count)
		var r_pos: Vector2 = Vector2(r_pos_x, r_pos_y)
		r_pos.x += (t_size.x - r_size.x) / 2
		r_label.rect_position = r_pos
		r_label.visible = true

func _ready():
	# メッセージにルビ指定を除くテキストを指定
	$Message.text = parse()
	# ルビを適用
	apply()



