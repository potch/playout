local gfx <const> = playdate.graphics
local geo <const> = playdate.geometry

-- inherit property values from parent nodes
local function inheritProperty(name, node, fallback)
  local cursor = node
  local value
  local style
  repeat
    style = cursor.properties.style or {}
    value = style[name] or cursor.properties[name]
    cursor = cursor.parent
  until value or (not cursor)
  return value or fallback
end

-- generate a list of offsets for drawing stroke outlines
local function strokeOffsets(radius)
  local offsets = {}
  for x = -radius, radius do
    for y = -radius, radius do
      if x * x + y * y <= radius * radius then
        table.insert(offsets, { x, y })
      end
    end
  end
  return offsets
end

local function round(n)
  return math.floor(n)
end

local floor = math.floor

local function tableFromDefaults(options, defaults)
  options = options or {}
  local t = table.shallowcopy(options)
  for key, val in pairs(defaults) do
    t[key] = options[key] or defaults[key]
  end
  return t
end

-- constants for box layout
local kDirectionVertical = 1
local kDirectionHorizontal = 2

local kAlignStart = 1
local kAlignCenter = 2
local kAlignEnd = 3
local kAlignStretch = 4

local kAnchorTopLeft = 1
local kAnchorTopCenter = 2
local kAnchorTopRight = 3
local kAnchorCenterLeft = 4
local kAnchorCenter = 5
local kAnchorCenterRight = 6
local kAnchorBottomLeft = 7
local kAnchorBottomCenter = 8
local kAnchorBottomRight = 9

-- generic box node
local box = {}
box.__index = box

local defaultBoxProperties = {
  minWidth = 1,
  minHeight = 1,
  maxWidth = 400,
  maxHeight = 240,
  width = nil,
  height = nil,
  scroll = false,
  direction = kDirectionVertical,
  padding = 0,
  paddingTop = nil,
  paddingLeft = nil,
  paddingRight = nil,
  paddingBottom = nil,
  backgroundColor = nil,
  backgroundAlpha = nil,
  nineSlice = nil,
  hAlign = kAlignCenter,
  vAlign = kAlignCenter,
  selfAlign = nil,
  border = 0,
  borderColor = gfx.kColorBlack,
  borderRadius = 0,
  spacing = 0,
  font = nil,
  fontFamily = nil,
  flex = nil,
  shadow = nil,
  shadowAlpha = 0
}

local defaultDrawContext = {
  maxWidth = math.huge,
  maxHeight = math.huge
}

function box.new(properties, children)
  properties = properties or {}
  local o = {
    properties = tableFromDefaults(properties, defaultBoxProperties),
    children = children or {},
    childRects = nil,
    parent = nil,
    scrollPos = 0,
    style = properties.style or nil
  }
  setmetatable(o, box)
  return o
end

function box:appendChild(child)
  table.insert(self.children, child)
  child.parent = self
end

function box:insertChild(position, child)
  table.insert(self.children, position, child)
  child.parent = self
end

function box:layout(context)
  context = tableFromDefaults(context, defaultDrawContext)
  local props = self.properties
  if self.style then props = tableFromDefaults(self.style, props) end
  local constrainedWidth = math.min(context.maxWidth, (props.width or props.maxWidth))
  local constrainedHeight = math.min(context.maxHeight, (props.height or props.maxHeight))
  local isVertical = props.direction == kDirectionVertical
  local children = self.children

  if props.scroll then
    if isVertical then
      constrainedHeight = math.huge
    else
      constrainedWidth = math.huge
    end
  end

  -- compute padding from shorthands
  local paddingTop = props.paddingTop or props.padding
  local paddingLeft = props.paddingLeft or props.padding
  local paddingRight = props.paddingRight or props.paddingLeft or props.padding
  local paddingBottom = props.paddingBottom or props.paddingTop or props.padding
  local shadow = props.shadow or 0

  local availableWidth = constrainedWidth - paddingLeft - paddingRight
  local availableHeight = constrainedHeight - paddingTop - paddingBottom - shadow

  local childRects = {}
  self.childRects = childRects
  local child
  local childFlex
  local remainingHeight = availableHeight
  local remainingWidth = availableWidth
  local intrinsicWidth = 0
  local intrinsicHeight = 0
  local totalFlex = 0

  for i = 1, #children do
    if i > 1 then
      if isVertical then
        remainingHeight = remainingHeight - props.spacing
        intrinsicHeight = intrinsicHeight + props.spacing
      else
        remainingWidth = remainingWidth - props.spacing
        intrinsicWidth = intrinsicWidth + props.spacing
      end
    end
    childFlex = nil
    child = children[i]
    -- determine intrinsic size of child node
    local childRect = child:layout({
      maxWidth = remainingWidth,
      maxHeight = remainingHeight,
      path = context.path .. '.' .. (child.properties.id or i)
    })
    -- accumulate flex if specified
    childFlex = child.properties.flex
    childRects[i] = childRect
    if childFlex then
      totalFlex = totalFlex + child.properties.flex
    end
    if isVertical then
      if not childFlex then
        remainingHeight = remainingHeight - childRect.height
      end
      intrinsicHeight = intrinsicHeight + childRect.height
      intrinsicWidth = math.max(intrinsicWidth, childRect.width)
    else
      if not childFlex then
        remainingWidth = remainingWidth - childRect.width
      end
      intrinsicWidth = intrinsicWidth + childRect.width
      intrinsicHeight = math.max(intrinsicHeight, childRect.height)
    end
  end

  local actualWidth = constrainedWidth
  local actualHeight = constrainedHeight
  if not props.width then
    if (not isVertical) and totalFlex > 0 then
      actualWidth = constrainedWidth
    else
      actualWidth = math.max(props.minWidth, math.min(intrinsicWidth + paddingLeft + paddingRight, props.maxWidth))
      remainingWidth = 0
    end
  end
  if not props.height then
    if isVertical and totalFlex > 0 then
      actualHeight = constrainedHeight
    else
      actualHeight = math.max(props.minHeight, math.min(intrinsicHeight + paddingTop + paddingBottom + shadow, props.maxHeight))
      remainingHeight = 0
    end
  end

  local rect = geo.rect.new(0, 0, floor(actualWidth), floor(actualHeight))
  local innerWidth = actualWidth - paddingLeft - paddingRight
  local innerHeight = actualHeight - paddingTop - paddingBottom - shadow

  local child, x, y, childProps, align, flexRatio

  -- set initial layout position
  if isVertical then
    y = paddingTop
    if totalFlex == 0 then
      if props.vAlign == kAlignCenter then y = y + floor(remainingHeight / 2) end
      if props.vAlign == kAlignEnd then y = y + remainingHeight end
    end
  else
    x = paddingLeft
    if totalFlex == 0 then
      if props.hAlign == kAlignCenter then x = x + floor(remainingWidth / 2) end
      if props.hAlign == kAlignEnd then x = x + remainingWidth end
    end
  end

  for i = 1, #childRects do
    child = childRects[i]
    childProps = children[i].properties or {}
    childFlex = childProps.flex

    local align

    if isVertical then
      x = paddingLeft
      align = childProps.selfAlign or props.hAlign
      if align == kAlignCenter then x = x + round(innerWidth - child.width) / 2 end
      if align == kAlignEnd then x = x + innerWidth - child.width end
    else
      y = paddingTop
      align = childProps.selfAlign or props.vAlign
      if align == kAlignCenter then y = y + round(innerHeight - child.height) / 2 end
      if align == kAlignEnd then y = y + innerHeight - child.height end
    end

    -- generate final layout rect for child node
    if childFlex then
      flexRatio = childFlex / totalFlex
      if isVertical then
        if align == kAlignStretch then
          childRects[i] = geo.rect.new(x, y, innerWidth, floor(flexRatio * remainingHeight))
        else
          childRects[i] = geo.rect.new(x, y, child.width, floor(flexRatio * remainingHeight))
        end
      else
        if align == kAlignStretch then
          childRects[i] = geo.rect.new(x, y, floor(flexRatio * remainingWidth), innerHeight)
        else
          childRects[i] = geo.rect.new(x, y, floor(flexRatio * remainingWidth), child.height)
        end
      end
      child = childRects[i]
    else
      if align == kAlignStretch then
        if isVertical then
          child.width = innerWidth
        else
          child.height = innerHeight
        end
      end
      child:offset(x, y)
    end

    -- move positioning cursor to next position
    if isVertical then
      y = y + child.height + props.spacing
    else
      x = x + child.width + props.spacing
    end
  end
  return rect
end

function box:draw(rect)
  local props = self.properties
  if self.style then props = tableFromDefaults(self.style, props) end
  local border = props.border

  self.rect = rect
  local r = rect

  if props.backgroundColor then
    if props.shadow then
      gfx.setColor(gfx.kColorBlack)
      gfx.setDitherPattern(props.shadowAlpha or 0)
      gfx.fillRoundRect(r, props.borderRadius)
      gfx.setColor(props.backgroundColor)
      if props.backgroundAlpha then
        gfx.setDitherPattern(props.backgroundAlpha)
      end
      gfx.fillRoundRect(r.x, r.y, r.width, r.height - props.shadow, props.borderRadius)
    else
      gfx.setColor(props.backgroundColor)
      if props.backgroundAlpha then
        gfx.setDitherPattern(props.backgroundAlpha)
      end
      gfx.fillRoundRect(r, props.borderRadius)
    end
  end

  -- figure out why nineslice leaks memory all over the place
  -- if props.nineSlice then
  --   props.nineSlice:drawInRect(rect)
  -- end

  if border > 0 then
    gfx.setColor(props.borderColor)
    gfx.setLineWidth(border)
    gfx.setStrokeLocation(gfx.kStrokeInside)
    if props.shadow then
      gfx.drawRoundRect(r.x, r.y, r.width, r.height - props.shadow, props.borderRadius)
    else
      gfx.drawRoundRect(r, props.borderRadius)
    end
  end

  for i = 1, #self.children do
    local child = self.children[i]
    local drawRect = self.childRects[i]:offsetBy(r.x, r.y)
    child:draw(drawRect)
  end
end

-- text node
local text = {}
text.__index = text

local defaultTextProperties = {
  font = nil,
  fontFamily = nil,
  alignment = kTextAlignment.left,
  leading = nil,
  flex = nil,
  wrap = true,
  stroke = 0,
  color = nil
}

function text.new(textContent, properties)
  properties = properties or {}
  local o = {
    text = textContent,
    properties = tableFromDefaults(properties, defaultTextProperties),
    parent = nil,
    style = properties.style or nil
  }
  setmetatable(o, text)
  return o
end

function text:layout(context)
  context = tableFromDefaults(context, defaultDrawContext)
  local props = self.properties
  if self.style then props = tableFromDefaults(self.style, props) end
  local maxWidth = context.maxWidth or math.huge
  local maxHeight = context.maxHeight or math.huge

  gfx.pushContext()
  local font = inheritProperty("font", self, nil)
  local fontFamily = inheritProperty("fontFamily", self, nil)
  if font then
    gfx.setFont(font)
  end
  if fontFamily then
    gfx.setFontFamily(fontFamily)
  end
  if props.wrap then
    local idealWidth, idealHeight = gfx.getTextSizeForMaxWidth(self.text, maxWidth, props.leading)
    local width = idealWidth
    local height = math.min(idealHeight, maxHeight)
    gfx.popContext()
    return geo.rect.new(0, 0, width, height)
  end

  local width, height = gfx.getTextSize(self.text)
  gfx.popContext()

  return geo.rect.new(0, 0, math.min(width, maxWidth), height)
end

function text:draw(rect)
  local props = self.properties
  local alignment = props.alignment;
  self.rect = rect

  gfx.pushContext()
  local font = inheritProperty("font", self, nil)
  local fontFamily = inheritProperty("fontFamily", self, nil)
  if font then
    gfx.setFont(font)
  end
  if fontFamily then
    gfx.setFontFamily(fontFamily)
  end
  if props.stroke > 0 then
    local offsets = strokeOffsets(props.stroke)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    for _, o in pairs(offsets) do
      gfx.drawTextInRect(self.text, rect:offsetBy(o[1], o[2]), props.leading, "...", alignment)
    end
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
  end
  if props.color then
    if props.color == gfx.kColorBlack then
      gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    end
    if props.color == gfx.kColorWhite then
      gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    end
  end
  gfx.drawTextInRect(self.text, rect, props.leading, "...", alignment)
  gfx.setImageDrawMode(gfx.kDrawModeCopy)
  gfx.popContext()
end

-- image node
local image = {}
image.__index = image

local defaultImageProperties = {
}

function image.new(img, properties)
  properties = properties or {}
  local o = {
    img = img,
    properties = tableFromDefaults(properties, defaultImageProperties),
    parent = nil,
    width = img.width,
    height = img.height
  }
  setmetatable(o, image)
  return o
end

function image:layout(context)
  return geo.rect.new(0, 0, self.width, self.height)
end

function image:draw(rect)
  self.rect = rect
  self.img:draw(rect.x, rect.y)
end

-- top-level tree

local tree = {}
tree.__index = tree

local treeBuilders = {
  box = box.new,
  image = image.new,
  text = text.new
}

local defaultTreeOptions = {
  useCache = true
}

function tree.new(root, options)
  options = tableFromDefaults(options, defaultTreeOptions)
  local o = {
    root = root or box.new(),
    rect = nil,
    img = nil,
    sprite = nil,
    useCache = options.useCache,
    tabIndex = nil
  }
  if o.useCache then
    o.cache = {}
  end
  setmetatable(o, tree)

  -- set parent-child relationships
  function walk(node)
    if node.children then
      for i = 1, #node.children do
        node.children[i].parent = node
        walk(node.children[i])
      end
    end
  end

  walk(root)

  return o
end

function tree:build(builder)
  return tree.new(builder(treeBuilders))
end

function tree:layout()
  local rect = self.root:layout({
    maxWidth = 400,
    maxHeight = 240,
    tree = self,
    path = 'root'
  })
  self.rect = rect
end

function tree:draw()
  if not self.rect then
    self:layout()
  end
  local rect = self.rect
  -- avoid needless reallocations
  if not self.img or self.img.width ~= rect.width or self.img.height ~= rect.height then
    self.img = gfx.image.new(rect.width, rect.height)
  else
    self.img:clear(gfx.kColorClear)
  end
  gfx.pushContext(self.img)
  self.root:draw(rect)
  gfx.popContext()
  if self.sprite then
    self.sprite:setImage(self.img)
  end
  return self.img
end

function tree:asSprite()
  self.sprite = gfx.sprite.new()
  self:draw()
  return self.sprite
end

function tree:get(id)
  if self.useCache and self.cache[id] then
    return self.cache[id]
  end

  function walk(node)
    if node.properties and node.properties.id == id then
      return node
    end
    if node.children then
      for i = 1, #node.children do
        local found = walk(node.children[i])
        if found then
          if self.useCache then
            self.cache[id] = found
          end
          return found
        end
      end
    end
  end

  return walk(self.root)
end

function tree:computeTabIndex(id)
  local tabIndex = {}

  function walk(node)
    if node.properties and node.properties.tabIndex then
      table.insert(tabIndex, node)
    end
    if node.children then
      for i = 1, #node.children do
        walk(node.children[i])
      end
    end
  end

  walk(self.root)
  
  table.sort(tabIndex, function(a, b)
    return a.properties.tabIndex < b.properties.tabIndex
  end)

  self.tabIndex = tabIndex
end

-- util

function getRectAnchor(r, anchor)
  horizontal = horizontal or kAlignCenter
  vertical = vertical or kAlignCenter
  local p = geo.point.new
  local cx = r.x + r.width / 2
  local cy = r.y + r.height / 2

  if anchor == kAnchorTopLeft then return p(r.left, r.top) end
  if anchor == kAnchorTopCenter then return p(cx, r.top) end
  if anchor == kAnchorTopRight then return p(r.right, r.top) end
  if anchor == kAnchorCenterLeft then return p(r.left, cy) end
  if anchor == kAnchorCenter then return p(cx, cy) end
  if anchor == kAnchorCenterRight then return p(r.right, cy) end
  if anchor == kAnchorBottomLeft then return p(r.left, r.bottom) end
  if anchor == kAnchorBottomCenter then return p(cx, r.bottom) end
  if anchor == kAnchorBottomRight then return p(r.right, r.bottom) end
  return p(cx, cy)
end

-- interface

playout = {
  box = box,
  text = text,
  tree = tree,
  image = image,
  kDirectionHorizontal = kDirectionHorizontal,
  kDirectionVertical = kDirectionVertical,

  kAlignStart = kAlignStart,
  kAlignCenter = kAlignCenter,
  kAlignEnd = kAlignEnd,
  kAlignStretch = kAlignStretch,

  getRectAnchor = getRectAnchor,

  kAnchorTopLeft = kAnchorTopLeft,
  kAnchorTopCenter = kAnchorTopCenter,
  kAnchorTopRight = kAnchorTopRight,
  kAnchorCenterLeft = kAnchorCenterLeft,
  kAnchorCenter = kAnchorCenter,
  kAnchorCenterRight = kAnchorCenterRight,
  kAnchorBottomLeft = kAnchorBottomLeft,
  kAnchorBottomCenter = kAnchorBottomCenter,
  kAnchorBottomRight = kAnchorBottomRight,
}
