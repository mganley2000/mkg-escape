class_name FloorChunk
extends Node2D
## The live nodes for one floor while it's near the camera. Built from
## FloorData and torn down when it scrolls away; any changes (dead monsters,
## collected items, monster positions) are written back to FloorData.

var world: WorldManager
var index := 0
var data: FloorData
var monsters: Array = []
var pickups: Array = []
var segments: Array = []


func build(w: WorldManager, fi: int, d: FloorData) -> void:
	world = w
	index = fi
	data = d
	position = Vector2(0, GameConst.floor_y(fi))

	var x := 0.0
	while x < GameConst.FLOOR_WIDTH:
		var seg := WallSegment.new()
		seg.setup(self, x, minf(x + GameConst.SEGMENT_WIDTH, GameConst.FLOOR_WIDTH))
		add_child(seg)
		segments.append(seg)
		x += GameConst.SEGMENT_WIDTH

	var slab := SlabStrip.new()
	slab.setup(self)
	add_child(slab)

	for c in world.connectors_up(fi):
		var view := ConnectorView.new()
		view.setup(c, d.band)
		add_child(view)

	var torch_color := ArtLib.torch_color(d.band)
	for t in d.torches:
		var torch := Torch.new()
		torch.setup(world, Vector2(float(t["x"]), float(t["h"])), torch_color)
		add_child(torch)

	if fi == GameConst.TOP_FLOOR:
		var surface := SurfaceView.new()
		surface.setup(world, world.exit_x())
		add_child(surface)

	for i in d.spawns.size():
		var s: Dictionary = d.spawns[i]
		if not s["alive"]:
			continue
		var m := Monster.new()
		m.setup(world, self, i, s)
		add_child(m)
		monsters.append(m)

	for i in d.pickups.size():
		if d.pickups[i]["alive"]:
			spawn_pickup(i, false)


func spawn_pickup(i: int, pop: bool) -> void:
	var p := Pickup.new()
	p.setup(self, i, data.pickups[i], pop)
	add_child(p)
	pickups.append(p)


func collect_pickup(p: Pickup) -> void:
	data.pickups[p.data_index]["alive"] = false
	pickups.erase(p)
	p.queue_free()


func on_monster_died(m: Monster) -> void:
	data.spawns[m.spawn_index]["alive"] = false
	monsters.erase(m)


func refresh_decals(x: float) -> void:
	var i := clampi(int(x / GameConst.SEGMENT_WIDTH), 0, segments.size() - 1)
	segments[i].queue_redraw()


func persist() -> void:
	for m in monsters:
		data.spawns[m.spawn_index]["x"] = m.position.x
