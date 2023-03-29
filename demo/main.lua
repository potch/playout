-- sdk libs
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics

-- local libs
import "../playout.lua"
import "test"

fonts = {
  normal = gfx.getSystemFont(gfx.font.kVariantNormal),
  bold = gfx.getSystemFont(gfx.font.kVariantBold)
}

local button = {
  padding = 4,
  paddingLeft = 16,
  borderRadius = 12,
  border = 2,
  shadow = 3,
  shadowAlpha = 1/4,
  backgroundColor = gfx.kColorWhite,
  font = fonts.bold
}

local buttonHover = {
  padding = 4,
  paddingLeft = 16,
  borderRadius = 12,
  border = 2,
  shadow = 3,
  shadowAlpha = 1/4,
  backgroundColor = gfx.kColorWhite,
  backgroundAlpha = 1/2,
  font = fonts.bold,
  paddingBottom = 5,
  shadow = 5,
}

local menu = nil
local menuImg, menuSprite, menuTimer
local selectedIndex = 1

local pointer
local pointerPos = nil
local pointerTimer

local logo = gfx.image.new("images/tmm-block.png")

local testResultMessage
local selected

local function setPointerPos()
  selected = menu.tabIndex[selectedIndex]
  local menuRect = menuSprite:getBoundsRect()

  pointerPos = getRectAnchor(selected.rect, playout.kAnchorCenterLeft):
    offsetBy(getRectAnchor(menuRect, playout.kAnchorTopLeft):unpack())  
end

local function nextMenuItem()
  selectedIndex = selectedIndex + 1
  if selectedIndex > #menu.tabIndex then
    selectedIndex = 1
  end
  setPointerPos()
end

local function prevMenuItem()
  selectedIndex = selectedIndex - 1
  if selectedIndex < 1 then
    selectedIndex = #menu.tabIndex
  end
  setPointerPos()
end

for f = 1, #testRunner.failedDetails do
  local result = testRunner.failedDetails[f];
  print(result.group .. ' > ' .. result.name)
  print("  expected: " .. tostring(result.expected))
  print("  actual: " .. tostring(result.actual))
end

local function createMenu(ui)
  local box = ui.box
  local image = ui.image
  local text = ui.text

  return box({
    maxWidth = 380,
    backgroundColor = gfx.kColorWhite,
    borderRadius = 9,
    border = 2,
    direction = playout.kDirectionHorizontal,
    vAlign = playout.kAlignStretch,
    shadow = 8,
    shadowAlpha = 1/3
  }, {
    box({
      padding = 12,
      spacing = 10,
      backgroundColor = gfx.kColorBlack,
      backgroundAlpha = 7/8,
      borderRadius = 9,
      border = 2
    }, {
      box({
        border = 2,
        padding = 6,
        borderRadius = 5,
        backgroundColor = gfx.kColorWhite
      }, { image(logo) }),
      box({
        paddingLeft = 6,
        paddingTop = 3,
        paddingBottom = 1,
      }, { text("playout", { stroke = 4 }) }),
    }),
    box({
      spacing = 12,
      paddingTop = 16,
      paddingLeft = 20,
      hAlign = playout.kAlignStart
    }, { 
      text("Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
      text(testResultMessage),
      box({
        direction = playout.kDirectionHorizontal,
        spacing = 12,
        paddingLeft = 16,
        paddingTop = 12,
        paddingBottom = 0,
        vAlign = playout.kAlignEnd,
      }, { 
        box({ style = button }, { text("cancel", { id = "no", stroke = 2, tabIndex = 1 } ) } ),
        box({ flex = 1 }),
        box({ style = button }, { text("okay", { id = "yes", stroke = 2, tabIndex = 2 } ) } ),
      })
    })
  })
end

local inputHandlers = {
  rightButtonDown = nextMenuItem,
  downButtonDown = nextMenuItem,
  leftButtonDown = prevMenuItem,
  upButtonDown = prevMenuItem,
  AButtonDown = function ()
    local selected = menu.tabIndex[selectedIndex]
    if selected == menu:get("yes") then
      menuSprite:moveBy(0, 4)
      menuSprite:update()
    end
    if selected == menu:get("no") then
      menuSprite:moveBy(0, -4)
      menuSprite:update()
    end
    setPointerPos()
  end
}

function setup()
  -- run tests (see test.lua)
  testRunner:run()
  testResultMessage = "Tests: *" .. testRunner.passed .. "/" .. testRunner.total .. "* passed."
  if testRunner.passed < testRunner.total then
    testResultMessage = testResultMessage .. " Oops"
  else
    testResultMessage = testResultMessage .. " Nice!"
  end

  -- attach input handlers
  playdate.inputHandlers.push(inputHandlers)

  -- setup menu
  menu = playout.tree:build(createMenu)
  menu:computeTabIndex()
  menuImg = menu:draw()
  menuSprite = gfx.sprite.new(menuImg)
  menuSprite:moveTo(200, 400)
  menuSprite:add()

  -- setup bg sprite
  local bg = gfx.image.new("images/mountains.png")
  gfx.sprite.setBackgroundDrawingCallback(
    function(x, y, width, height)
      gfx.setClipRect(x, y, width, height)
      bg:draw(0, 0)
      gfx.clearClipRect()
    end
  )

  -- setup pointer
  local pointerImg = gfx.image.new("images/pointer")
  pointer = gfx.sprite.new(pointerImg)
  pointer:setRotation(90)
  pointer:setZIndex(1)
  pointer:add()
  setPointerPos()

  -- setup pointer animation
  pointerTimer = playdate.timer.new(500, -18, -14, playdate.easingFunctions.inOutSine)
  pointerTimer.repeats = true
  pointerTimer.reverses = true

  -- setup menu animation
  menuTimer = playdate.timer.new(500, 400, 100, playdate.easingFunctions.outCubic)
  menuTimer.timerEndedCallback = setPointerPos
end

-- frame callback
function playdate.update()
  if menuTimer.timeLeft > 0 then
    menuSprite:moveTo(200, menuTimer.value)
    menuSprite:update()
  end

  pointer:moveTo(
    pointerPos:offsetBy(pointerTimer.value, 0)
  )
  pointer:update()

  playdate.timer.updateTimers()
  playdate.drawFPS()
end

setup()
