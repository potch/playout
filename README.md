# Playout

UI library and box model for Playdate

[Support this project on Itch.io 🕹](https://twentyminutemile.itch.io/playout)

## Installation

If you are using [toybox](https://github.com/jm/toybox), you can run

```
toybox add potch/playout
```

Otherwise the library is a single file you can clone/copy into your project.

## Demo

If you'd like to run the demo, you'll need the Playdate SDK. Then run:
```sh
pdc demo
```
and open the resulting packaged in the Playdate Simulator.

If you want to develop/experiment on the library or demo and you have `node` installed you can run the following:

```
npm install
npm start
```

Which will build and launch the demo, and re-build after any changes.

# API Docs

# `playout.box`

Box-based layout element. supports 1-dimensional layout (horizontal or vertical) with 2-dimensional alignment and flexible sizing.

## Methods

### `playout.box.new(properties, [children])`

Creates a new `playout.box`. Takes a table of `properties` and a list of `children`.

Children can be other `box`es, `image`s, or `text`.

Returns a `playout.box`.

#### Supported `properties`:

| property | description | default value |
| -------- | ----------- | ------------- |
backgroundAlpha | opacity of box fill, drawn as a dither pattern. | 0 (full)
backgroundColor | color to fill the box when drawing | `nil` (transparent)
border | thickness of border on box | 0
borderColor | color of border (if > 0) | `playdate.graphics.kColorBlack`
borderRadius | corner radius to use when drawing the box | 0
direction | direction of layout. can be horizontal (children will be in a row) or vertical (children will be in a column) | `playout.kDirectionVertical`
flex | if set (non-zero), box will grow proporitonally to fill extra layout space in its parent. | `nil`
font | font to use when drawing text in children. | `nil` (default)
fontFamily | font family to use when drawing text in children. takes precedence over `font`, and allows for rich formatting. | `nil`
hAlign | how to horizontally align children. see [Alignment](#alignment) | `playout.kAlignCenter`
height | height of the box. if not specified, box will be the height of its contents plus padding, spacing, etc. (but no larger than `maxHeight`) | `nil`
id | unique `string` used for lookups via [`playout.tree.get`](#playout-tree-get-id) | nil
maxHeight | maximum height of the box | 240
maxWidth | maximum width of the box | 400
minHeight | minimum height of the box | 1
minWidth | minimum width of the box | 1
padding | amount of inset, in pixels, between box children and the edge | 0
paddingBottom | bottom padding. defaults to `paddingTop` or `padding` value if provided, in that order | `nil`
paddingLeft | left padding. defaults to `padding` value if provided, in that order | `nil`
paddingRight | right padding. defaults to `paddingLeft` or `padding` value if provided, in that order | `nil`
paddingTop | top padding. defaults to `padding` value if provided | `nil`
selfAlign | override the box alignment from that provided by its parent. if parent's `direction` is horizontal, affects vertical alignment, if vertical, affects horizontal alignment | `nil` (no override)
shadow | size of shadow in pixels to draw under the box. note the shadow subtracts from the overall available height of the box | `nil` (no shaow)
shadowAlpha | how "dark" the shadow is, from 0..1. drawn using dither. | 0 (full opacity)
spacing | how much space should be between each child of the box | 0
style | see [Style Reuse](#styling) | nill
tabIndex | defines position for sequential lookups by `playout.tree.tabIndex`. | nil
vAlign | how to vertically align children. see [Alignment](#alignment) | `playout.kAlignCenter`
width | width of the box. if not specified, box will be the width of its contents plus padding, spacing, etc. (but no larger than `maxWidth`) | `nil`


### `playout.box:appendChild(child)`

Add a child (text, image, or other box) to the box.


### `playout.box:insertChild(child, position)`

Add a child (text, image, or other box) to the box at a specified position. e.g. `insertChild(child, 1)` would add the child as the first child.


### `playout.box:layout([context])`

Computes the layout of the box and all children recursively. Returns a `playout.geometry.rect` with the computed size. Usually indirectly called by `playout.tree:layout`.

`context` is a table with the following properties:

property | description | default
--- | --- | ---
maxWidth | maximum width the box can be, regardless of its contents | `math.huge` (no limit)
maxHeight | maximum height the box can be, regardless of its content | `math.huge` (no limit)


### `playout.box:draw(rect)`

Draw the box and all its children using their visual properties in the current drawing context within the specified `rect`. Usually called indirectly by `playout.tree.draw` with pre-computed `rect`s generated during `:layout`.



## properties

### `playout.box.properties`

table of properties, provided via initial creation.

### `playout.box.children`

list of children, managed via `appendChild`, `insertChild`, or `playout.tree`.

### `playout.box.childRects`

List of rects corresponding to `children`, determined during `:layout`. Will be `nil` if layout hasn't been called yet.

### `playout.box.parent`

Reference to a parent `box`, if any. set by `appendChild`, `insertChild`, or `playout.tree`. If children were changed directly via `.children`, their `parent` will not be set. read only.

### `playout.box.style`

see [Style Reuse](#styling).



# `playout.text`

Layout element for text content. supports fonts, outlines, and text wrapping.

## methods

### `playout.text.new(text, [properties])`

Creates a new `playout.text`. Takes a string of `text` and an optional table of `properties`.

Returns a `playout.text`

#### Supported `properties`:

property | description | default
--- | --- | ---
font | which `playdate.graphics.font` to use to render text. this property can be inherited from parent `box`es. | `nil` (currently set font),
fontFamily | which `playdate.graphics.fontFamily` to use to render text. allows for rich text formatting. If set, overrides `font`. this property can be inherited from parent `box`es. | `nil`,
alignment | text alignment | `kTextAlignment.left`,
leading | leading adjusment | `nil` (none),
flex | if set (non-zero), text will grow proporitonally to fill extra layout space in its parent. | `nil`,
wrap | whether to line-wrap text | true,
stroke | radius of outline to render around the text- will be rendered in white. useful to contrast text against a background. | 0,
color | color to render text- overrides `font`'s natural color. `playdate.graphics.kColorBlack` or `kColorWhite`. | `nil` (use defualt font color)

### `playout.text:layout(context)`

Computes the layout and dimensions of renderered text. Returns a `playout.geometry.rect` with the computed size. Usually indirectly called by `playout.tree:layout`.

### `playout.text:draw(rect)`

Renders text into the provided `playout.geometry.rect`. Usually called indirectly by `playout.tree:draw`.

## Properties

Changing properties will require re-running `layout` and `draw` to see the changes.

### `playout.text.text`

Value of text string to render. changing this will likely require re-computing layout.

### `playout.text.properties`

Table of properties, provided via initial creation.

### `playout.text.parent`

Reference to a parent `box`, if any. set by `appendChild`, `insertChild`, or `playout.tree`. If children were changed directly via `.children`, their `parent` will not be set. read only.

### `playout.text.style`

See [Style Reuse](#styling).


# `playout.image`

Allows for the incorporation of `playdate.graphics.image` into a layout.

## Methods

### `playout.image.new(image, [properties])`

Creates a new `playout.image`. Takes a `playdate.graphics.image` and an optional table of `properties`.

`image` nodes are sized to the `width` and `height` of their corresponding `playdate.graphics.image`, which is used in layout.

Returns a `playout.image`.

### `playout.text:layout(context)`

Calculates a `play

### `playout.text:draw(rect)`

## Properties

### `playout.text.parent`

Reference to a parent `box`, if any. set by `appendChild`, `insertChild`, or `playout.tree`. If children were changed directly via `.children`, their `parent` will not be set. Read only.



# `playout.tree`

Structure for creating/accessing a tree of `playout` nodes. This is the recommended way to create, layout, and draw layouts.

## Methods

### `playout.tree.new([root, [options])`

Create a new `playout.tree`. Takes `root`, the top-level note of the tree (a `box`, `text`, or `image`), as well as a table of `options`.

#### Supported `options`:

option | description | default
--- | --- | ---
useCache | Whether or not to cache nodes looked up using `tree:get(id)`. Makes subsequent lookups faster. | true

### `playout.tree:layout()`

Compute the layout of all children recursively, starting at `root`.

### `playout.tree.draw()`

Returns a `playdate.graphics.image` containing the rendered tree. Will run `tree:layout` if it has not yet been run. To save on memory, this method will store and re-use the same image for subsequent re-renders (at `tree.img`), provided the computed layout dimensions of the tree haven't changed. Will automatically update an associated sprite if created with `playout.tree:asSprite`

### `playout.tree:asSprite()`

Creates a new `playdate.graphics.sprite`, draws the tree into the sprite, and returns the sprite. Future calls to `tree:draw` will automatically update the sprite's image.

### `playout.tree:get(id)`

Find a node in the tree based on its `properties.id`. Will recursively walk the tree to find the node. Returns the first node with matching `id`, or `nil` if no match was found. If `tree.useCache` is `true`, subsequent lookups will skip walking the tree.

### `playout.tree:computeTabIndex()`

Computes a sequential list of nodes in the tree which have the `tabIndex` property set. Higher `tabIndex` values will be sorted later in the list. Useful for interactivity and menuing. The computed list will be store in the `playout.tree.tabIndex` property, which is `nil` until this method is called.

## Properties

### `playout.tree.root`

The top node of the layout tree.

### `playout.tree.tabIndex`

An ordered list of nodes, sorted by their `tabIndex` property. Useful for interactivity and menuing. Will be `nil` until `playout.tree:computeTabIndex()` is called.

### `playout.tree.rect`

A `playdate.geometry.rect` representing the dimensions of the tree after the last call to `playout.tree:layout()`

### `playout.tree.img`

A `playdate.graphics.image` containing the latest results of calling `playout.tree:draw()`

### `playout.tree.sprite`

A `playout.graphics.sprite`, populated after calling `playout.tree:asSprite()`


# Utilities and Constants

## Alignment

Used for `hAlign` and `vAlign` properties:

### `playout.kAlignStart`

Children are aligned to the start of the box (left for `hAlign`, top for `vAlign`).

### `playout.kAlignCenter`

Children are aligned to the center of the box (rounded down in the case of an odd width).

### `playout.kAlignEnd`

Children are aligned to the end of the box (right for `hAlign`, bottom for `vAlign`).

### `playout.kAlignStretch`

Resizes children to fill the available remaining space.

Only valid for off-axis alignment. If `direction` is vertical, valid for `hAlign`, if `directon` is horizontal, valid for `vAlign`. When used in `selfAlign`, always refers to the off-axis direction.


## Anchoring

### `playout.getRectAnchor(r, anchor)`

Returns a `playdate.geometry.point` for a given `anchor` position on the the provided `playdate.geometry.rect`:

```
playout.kAnchorTopLeft
playout.kAnchorTopCenter
playout.kAnchorTopRight
playout.kAnchorCenterLeft
playout.kAnchorCenter
playout.kAnchorCenterRight
playout.kAnchorBottomLeft
playout.kAnchorBottomCenter
playout.kAnchorBottomRight
```

## Direction

Used for specifying the direction of box layout, horizontal or vertical:

```
playout.kDirectionVertical
playout.kDirectionHorizontal
```

# Styling

All node types (`box`, `image`, and `text`) can take an optional `style` property. This is a table of properties that will override any properties provided at creation or default values. Can be used to define repeatable common collections of properties.

Example

```lua
local button = {
  padding = 4,
  border = 2,
  borderRadius = 4,
  shadow = 2
}

local options = playout.tree.new(
  playout.box.new({
    direction = playout.kDirectionHorizontal,
    spacing = 8
  }, {
    playout.box.new({ style = button, tabIndex = 1 }, { playout.text.new("Cancel") }),
    playout.box.new({ style = button, tabIndex = 2 }, { playout.text.new("Okay") }),
  })
)
```

