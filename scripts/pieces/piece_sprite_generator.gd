class_name PieceSpriteGenerator

## Generates an ImageTexture from a PieceShape.
## Each cell is rendered as a padded, beveled rectangle on a transparent background.
## Image dimensions: (bounding_cols * CELL_PX) wide × (bounding_rows * CELL_PX) tall.
## The origin cell (offset 0,0) within the image is at
##   (−min_col * CELL_PX, −min_row * CELL_PX).

const CELL_PX := 32
const PADDING := 4   # transparent gap between cell edge and painted area (px)
const BEVEL   := 2   # pixel thickness of highlight / shadow strips

static func generate(shape: PieceShape, base_color: Color) -> ImageTexture:
	return ImageTexture.create_from_image(_generate_image(shape, base_color))

## Generates a 32×32 icon: the sprite scaled to fit 30×30, centered, with a
## 1-pixel dark border on all sides. Sub-pixel scaling is intentional.
static func generate_icon(shape: PieceShape, base_color: Color) -> ImageTexture:
	const ICON_SIZE: int   = 32
	const BORDER: int      = 1
	const INNER: int       = ICON_SIZE - BORDER * 2   # 30

	var full_img: Image = _generate_image(shape, base_color)
	var full_w: int     = full_img.get_width()
	var full_h: int     = full_img.get_height()

	# Scale to fit within INNER×INNER, preserving aspect ratio.
	var scale: float    = minf(float(INNER) / float(full_w), float(INNER) / float(full_h))
	var scaled_w: int   = maxi(1, int(full_w * scale))
	var scaled_h: int   = maxi(1, int(full_h * scale))
	full_img.resize(scaled_w, scaled_h, Image.INTERPOLATE_BILINEAR)

	# Blit centered into a 32×32 image.
	var icon: Image = Image.create(ICON_SIZE, ICON_SIZE, false, Image.FORMAT_RGBA8)
	var ox: int     = BORDER + (INNER - scaled_w) / 2
	var oy: int     = BORDER + (INNER - scaled_h) / 2
	icon.blit_rect(full_img, Rect2i(0, 0, scaled_w, scaled_h), Vector2i(ox, oy))

	# 1-pixel border on all four edges.
	var border_color: Color = Color(0.08, 0.08, 0.08, 1.0)
	icon.fill_rect(Rect2i(0,                   0,                   ICON_SIZE, BORDER),    border_color)
	icon.fill_rect(Rect2i(0,                   ICON_SIZE - BORDER,  ICON_SIZE, BORDER),    border_color)
	icon.fill_rect(Rect2i(0,                   0,                   BORDER,    ICON_SIZE), border_color)
	icon.fill_rect(Rect2i(ICON_SIZE - BORDER,  0,                   BORDER,    ICON_SIZE), border_color)

	return ImageTexture.create_from_image(icon)

static func _generate_image(shape: PieceShape, base_color: Color) -> Image:
	var bb: Rect2i   = shape.get_bounding_rect()
	var img_w: int   = bb.size.y * CELL_PX   # width  = num_cols * CELL_PX
	var img_h: int   = bb.size.x * CELL_PX   # height = num_rows * CELL_PX
	var img: Image   = Image.create(img_w, img_h, false, Image.FORMAT_RGBA8)
	# Image.create initialises every pixel to (0,0,0,0) — fully transparent.

	var light: Color = base_color.lightened(0.35)
	var dark: Color  = base_color.darkened(0.40)

	var use_circle: bool = shape.cell_style == PieceShape.CellStyle.CIRCLE
	for offset: Vector2i in shape.offsets:
		var ix: int = (offset.y - bb.position.y) * CELL_PX
		var iy: int = (offset.x - bb.position.x) * CELL_PX
		if use_circle:
			_draw_cell_circle(img, ix, iy, base_color, light, dark)
		else:
			_draw_cell(img, ix, iy, base_color, light, dark)

	return img

## Returns the pixel offset of the origin cell (offset 0,0) within an image
## generated for the given shape. Use this to align the sprite to the cursor.
static func origin_offset(shape: PieceShape) -> Vector2:
	var bb: Rect2i = shape.get_bounding_rect()
	return Vector2(bb.position.y, bb.position.x) * CELL_PX

## Draws a circle into one CELL_PX × CELL_PX region of img.
## The outer BEVEL pixels of the circle radius form a directional bevel ring:
## top-left arc is lighter, bottom-right arc is darker.
static func _draw_cell_circle(
		img: Image, ix: int, iy: int,
		base: Color, light: Color, dark: Color) -> void:
	var cx: float = ix + CELL_PX * 0.5
	var cy: float = iy + CELL_PX * 0.5
	var r: float       = (CELL_PX - PADDING * 2) * 0.5
	var r_sq: float    = r * r
	var r_inner: float = r - BEVEL
	var r_inner_sq: float = r_inner * r_inner
	for py: int in range(iy, iy + CELL_PX):
		for px: int in range(ix, ix + CELL_PX):
			var dx: float    = float(px) - cx + 0.5  # use pixel centre
			var dy: float    = float(py) - cy + 0.5
			var dist_sq: float = dx * dx + dy * dy
			if dist_sq > r_sq:
				continue
			if dist_sq > r_inner_sq:
				# Bevel ring: top-left arc = light, bottom-right arc = dark.
				img.set_pixel(px, py, light if dx + dy < 0.0 else dark)
			else:
				img.set_pixel(px, py, base)

static func _draw_cell(
		img: Image, ix: int, iy: int,
		base: Color, light: Color, dark: Color) -> void:
	var x0: int = ix + PADDING
	var y0: int = iy + PADDING
	var w: int  = CELL_PX - PADDING * 2
	var h: int  = CELL_PX - PADDING * 2

	# Base fill.
	img.fill_rect(Rect2i(x0, y0, w, h), base)

	# Bevel highlight — top strip (full width), left strip (between top/bottom strips).
	img.fill_rect(Rect2i(x0,              y0,              w,              BEVEL), light)
	img.fill_rect(Rect2i(x0,              y0 + BEVEL,      BEVEL, h - BEVEL * 2), light)

	# Bevel shadow — bottom strip (full width), right strip (between top/bottom strips).
	img.fill_rect(Rect2i(x0,              y0 + h - BEVEL,  w,              BEVEL), dark)
	img.fill_rect(Rect2i(x0 + w - BEVEL,  y0 + BEVEL,      BEVEL, h - BEVEL * 2), dark)
