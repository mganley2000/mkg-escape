class_name NameGenerator
extends RefCounted
## Syllable-based fantasy names for heroes who don't pick their own.

const STARTS := ["Bran", "Thor", "Kael", "Mor", "Ul", "Vor", "Ash", "Dra", "Eld", "Fen", "Gar", "Hal", "Jor", "Kor", "Mal", "Nor", "Rag", "Sar", "Tor", "Wul", "Ys", "Bjor", "Cael", "Dun"]
const MIDDLES := ["", "", "", "a", "e", "i", "o", "ar", "en", "ri", "ul"]
const ENDS := ["ric", "gar", "win", "mund", "dan", "las", "vik", "rok", "ath", "nor", "ek", "is", "orn", "wyn"]
const TITLES := ["the Grim", "the Bold", "the Lost", "Ironhand", "the Unbroken", "Ashborn", "the Wary", "Gravewalker", "the Hungry", "Deepborn"]


static func generate(rng: RandomNumberGenerator = null) -> String:
	var r: RandomNumberGenerator = rng
	if r == null:
		r = RandomNumberGenerator.new()
		r.randomize()
	var hero_name: String = STARTS[r.randi() % STARTS.size()] + MIDDLES[r.randi() % MIDDLES.size()] + ENDS[r.randi() % ENDS.size()]
	if r.randf() < 0.35:
		hero_name += " " + TITLES[r.randi() % TITLES.size()]
	return hero_name
