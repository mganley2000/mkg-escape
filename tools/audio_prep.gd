extends SceneTree
## Offline helper for preparing third-party WAV sources.
##
##   godot --headless --path . -s tools/audio_prep.gd -- scan <file.wav>...
##       prints format, length and detected onsets (for multi-shot recordings)
##   godot --headless --path . -s tools/audio_prep.gd -- cut <src.wav> <dst.wav> <start_s> <length_s> [gain]
##       writes a mono 16-bit slice with a short fade-in and an exponential
##       fade-out, peak-normalised to -1 dBFS and then scaled by gain

const WINDOW_S := 0.01


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("usage: scan <files...> | cut <src> <dst> <start> <len> [gain]")
		quit(1)
		return
	match args[0]:
		"scan":
			for path in args.slice(1):
				_scan(path)
		"cut":
			_cut(args[1], args[2], float(args[3]), float(args[4]), float(args[5]) if args.size() > 5 else 1.0)
	quit()


## Decodes a WAV into mono float samples in -1..1.
func _mono(path: String) -> Dictionary:
	var wav := AudioStreamWAV.load_from_file(path)
	if wav == null:
		push_error("cannot load " + path)
		return {}
	var data := wav.data
	var ch := 2 if wav.stereo else 1
	var out := PackedFloat32Array()
	match wav.format:
		AudioStreamWAV.FORMAT_16_BITS:
			var frames := data.size() / (2 * ch)
			out.resize(frames)
			for i in frames:
				var s := 0.0
				for c in ch:
					s += data.decode_s16((i * ch + c) * 2) / 32768.0
				out[i] = s / ch
		AudioStreamWAV.FORMAT_8_BITS:
			var frames := data.size() / ch
			out.resize(frames)
			for i in frames:
				var s := 0.0
				for c in ch:
					s += data.decode_s8(i * ch + c) / 128.0
				out[i] = s / ch
		_:
			push_error("unsupported format %d in %s" % [wav.format, path])
			return {}
	return {"samples": out, "rate": wav.mix_rate, "stereo": wav.stereo, "format": wav.format}


func _scan(path: String) -> void:
	match path.get_extension().to_lower():
		"ogg":
			print("%s  len=%.2fs" % [path.get_file(), AudioStreamOggVorbis.load_from_file(path).get_length()])
			return
		"mp3":
			print("%s  len=%.2fs" % [path.get_file(), AudioStreamMP3.load_from_file(path).get_length()])
			return
	var d := _mono(path)
	if d.is_empty():
		return
	var s: PackedFloat32Array = d["samples"]
	var rate: int = d["rate"]
	var win := int(rate * WINDOW_S)
	var env := PackedFloat32Array()
	var peak := 0.0
	for i in range(0, s.size() - win, win):
		var m := 0.0
		for j in win:
			m = maxf(m, absf(s[i + j]))
		env.append(m)
		peak = maxf(peak, m)
	var onsets: Array[String] = []
	var quiet := 99
	for i in env.size():
		if env[i] > peak * 0.35 and quiet >= 15:
			onsets.append("%.2f" % (i * WINDOW_S))
			quiet = 0
		elif env[i] < peak * 0.12:
			quiet += 1
	print("%s  rate=%d stereo=%s len=%.2fs peak=%.2f onsets=[%s]" % [
		path.get_file(), rate, d["stereo"], s.size() / float(rate), peak, ", ".join(onsets)])


func _cut(src: String, dst: String, start: float, length: float, gain: float) -> void:
	var d := _mono(src)
	if d.is_empty():
		return
	var s: PackedFloat32Array = d["samples"]
	var rate: int = d["rate"]
	var a := clampi(int(start * rate), 0, s.size())
	var b := clampi(int((start + length) * rate), a, s.size())
	var seg := s.slice(a, b)
	var peak := 0.0001
	for v in seg:
		peak = maxf(peak, absf(v))
	var norm := 0.89 / peak * gain
	var fade_in := int(0.002 * rate)
	var tail := int(seg.size() * 0.45)
	var bytes := PackedByteArray()
	bytes.resize(seg.size() * 2)
	for i in seg.size():
		var v := seg[i] * norm
		if i < fade_in:
			v *= float(i) / fade_in
		var from_end := seg.size() - i
		if from_end < tail:
			v *= pow(float(from_end) / tail, 2.0)
		bytes.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var out := AudioStreamWAV.new()
	out.format = AudioStreamWAV.FORMAT_16_BITS
	out.mix_rate = rate
	out.stereo = false
	out.data = bytes
	DirAccess.make_dir_recursive_absolute(dst.get_base_dir())
	var err := out.save_to_wav(dst)
	print("cut %s [%.2f +%.2f] -> %s (%s)" % [src.get_file(), start, length, dst, error_string(err)])
