testRunner = {
  tests = {},
  total = 0,
  passed = 0,
  failed = 0,
  failedDetails = {}
}

local box = playout.box.new
local text = playout.text.new
local image = playout.image.new

function testRunner:test(label, fn)
  table.insert(self.tests, { label, fn })
end

function testRunner:run()
  local group

  function assert(name, actual, expected)
    self.total = self.total + 1
    if expected == actual then
      self.passed = self.passed + 1
    else
      self.failed = self.failed + 1
      table.insert(self.failedDetails, {
        group = group,
        name = name,
        expected = expected,
        actual = actual
      })
    end
  end

  for t = 1, #self.tests do
    local test = self.tests[t]
    group = test[1]
    test[2](assert)
  end
end

testRunner:test("basics", function (assert)
  local tree = playout.tree.new(
    box({ width = 200, height = 100 })
  )

  assert('tree creates', (tree ~= nil), true)
  assert('tree has root', tree.root ~= nil, true)
  assert('box has no children', #tree.root.children, 0)

  local text = text("Hello", { id = "text" })
  tree.root:appendChild(text)

  assert('appendChild adds child', #tree.root.children, 1)
  assert('text has content', tree.root.children[1].text, "Hello")
  assert('get by id', tree:get("text"), text)
end)


testRunner:test("anchoring", function (assert)
  local rect = playdate.geometry.rect.new(10, 20, 30, 40)
  local point = playdate.geometry.point.new

  assert("point equality", point(1, 2), point(1, 2))

  assert("top left", playout.getRectAnchor(rect, playout.kAnchorTopLeft), point(10, 20))
  assert("top center", playout.getRectAnchor(rect, playout.kAnchorTopCenter), point(25, 20))
  assert("top right", playout.getRectAnchor(rect, playout.kAnchorTopRight), point(40, 20))

  assert("center left", playout.getRectAnchor(rect, playout.kAnchorCenterLeft), point(10, 40))
  assert("center", playout.getRectAnchor(rect, playout.kAnchorCenterCenter), point(25, 40))
  assert("center right", playout.getRectAnchor(rect, playout.kAnchorCenterRight), point(40, 40))

  assert("bottom left", playout.getRectAnchor(rect, playout.kAnchorBottomLeft), point(10, 60))
  assert("bottom canter", playout.getRectAnchor(rect, playout.kAnchorBottomCenter), point(25, 60))
  assert("bottom right", playout.getRectAnchor(rect, playout.kAnchorBottomRight), point(40, 60))
end)


testRunner:test("tabIndex", function (assert)
  local tree = playout.tree.new(
    box({ tabIndex = 2 }, {
      box({ tabIndex = 1 }),
      text("test", { tabIndex = 3 })
    })
  )

  assert("tabIndex is nil at first", tree.tabIndex, nil)
  tree:computeTabIndex()
  assert("tabIndex is computed", #tree.tabIndex, 3)
  tree.root.properties.border = 1
  assert("tabIndex refs", tree.tabIndex[2], tree.root)
  assert("tabIndex refs are live", tree.tabIndex[2].properties.border, 1)
end)

testRunner:test("flex", function (assert)
  local tree = playout.tree.new(
    box({
      width = 200, height = 100, direction = playout.kDirectionHorizontal
    }, {
      box({ width = 50, height = 10 }),
      box({ flex = 1, width = 20, height = 20 })
    })
  )

  tree:layout()
  assert("static sizing", tree.root.childRects[1].width, 50)
  assert("flex sizing", tree.root.childRects[2].width, 150)
  
  tree.root.children[1].properties.flex = 7
  tree:layout()
  assert("flex 7 sizing", tree.root.childRects[1].width, 175)
  assert("flex 1 sizing", tree.root.childRects[2].width, 25)
end)