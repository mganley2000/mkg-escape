class_name GameConst
extends RefCounted
## World dimensions shared by generation, rendering and gameplay.
##
## Floor 0 is the deepest. Each floor's walking surface sits at floor_y(i);
## y grows downward, so higher floors have more negative y. Below the surface
## is a SLAB-thick stone floor; above it is HEADROOM of open room.

const FLOOR_COUNT := 200
const TOP_FLOOR := FLOOR_COUNT - 1
const FLOOR_HEIGHT := 128.0
const SLAB := 16.0
const HEADROOM := FLOOR_HEIGHT - SLAB
const FLOOR_WIDTH := 7680.0
const EDGE_MARGIN := 180.0
const SEGMENT_WIDTH := 480.0
const MAX_VISIBLE_FLOORS := 10
const STAIRS_RUN := 176.0
const STAIRS_STEPS := 8
const INTERACT_RANGE := 26.0
const BAND_SIZE := 40
const BAND_COUNT := 5
## Characters stand slightly into the walkway strip for a sense of depth.
const FOOT_Y := -3.0


static func floor_y(index: int) -> float:
	return -float(index) * FLOOR_HEIGHT


static func floor_index_at_y(y: float) -> int:
	return int(floorf(-y / FLOOR_HEIGHT))


static func band_of(index: int) -> int:
	return clampi(index / BAND_SIZE, 0, BAND_COUNT - 1)
