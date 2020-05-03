local core = require "core"
local common = require "core.common"
local config = require "core.config"
local command = require "core.command"
local style = require "core.style"
local keymap = require "core.keymap"
local translate = require "core.doc.translate"
local RootView = require "core.rootview"
local DocView = require "core.docview"

local max_suggestions = 6

local symbols = {}


core.add_thread(function()
  local cache = setmetatable({}, { __mode = "k" })

  local function get_symbols(doc)
    local i = 1
    local s = {}
    while i < #doc.lines do
      for sym in doc.lines[i]:gmatch(config.symbol_pattern) do
        s[sym] = true
      end
      i = i + 1
      if i % 100 == 0 then coroutine.yield() end
    end
    return s
  end

  local function cache_is_valid(doc)
    local c = cache[doc]
    return c and c.last_change_id == doc:get_change_id()
  end

  while true do
    -- lift all symbols from all docs
    local t = {}
    for _, doc in ipairs(core.docs) do
      -- update the cache if the doc has changed since the last iteration
      if not cache_is_valid(doc) then
        cache[doc] = {
          last_change_id = doc:get_change_id(),
          symbols = get_symbols(doc)
        }
      end
      -- update symbol set with doc's symbol set
      for sym in pairs(cache[doc].symbols) do
        t[sym] = true
      end
      coroutine.yield()
    end

    -- update symbols list
    symbols = {}
    for sym in pairs(t) do
      table.insert(symbols, sym)
    end

    -- wait for next scan
    local valid = true
    while valid do
      coroutine.yield(1)
      for _, doc in ipairs(core.docs) do
        if not cache_is_valid(doc) then
          valid = false
        end
      end
    end

  end
end)


local partial = ""
local suggestions_idx = 1
local suggestions = {}
local last_active_view
local last_line, last_col


local function reset_suggestions()
  suggestions_idx = 1
  suggestions = {}
end


local function get_partial_symbol()
  local doc = core.active_view.doc
  local line2, col2 = doc:get_selection()
  local line1, col1 = doc:position_offset(line2, col2, translate.start_of_word)
  return doc:get_text(line1, col1, line2, col2)
end


local function get_active_view()
  if getmetatable(core.active_view) == DocView then
    last_active_view = core.active_view
    return core.active_view
  end
end


local function get_suggestions_rect(av)
  if #suggestions == 0 then
    return 0, 0, 0, 0
  end

  local line, col = av.doc:get_selection()
  local x, y = av:get_line_screen_position(line)
  x = x + av:get_col_x_offset(line, col - #partial)
  y = y + av:get_line_height() + style.padding.y
  local font = av:get_font()
  local th = font:get_height()

  local max_width = 0
  for i, sym in ipairs(suggestions) do
    max_width = math.max(max_width, font:get_width(sym))
  end

  return
    x - style.padding.x,
    y - style.padding.y,
    max_width + style.padding.x * 2,
    #suggestions * (th + style.padding.y) + style.padding.y
end

-- patch event logic into RootView
local on_text_input = RootView.on_text_input
local update = RootView.update

RootView.on_text_input = function(...)
  on_text_input(...)

  local av = get_active_view()
  if av then
    -- update partial symbol and suggestions
    partial = get_partial_symbol()
    if #partial >= 2 then
      local t = common.fuzzy_match(symbols, partial)
      for i = 1, max_suggestions do
        suggestions[i] = t[i]
      end
      last_line, last_col = av.doc:get_selection()
    else
      reset_suggestions()
    end

    -- scroll if rect is out of bounds of view
    local _, y, _, h = get_suggestions_rect(av)
    local limit = av.position.y + av.size.y
    if y + h > limit then
      av.scroll.to.y = av.scroll.y + y + h - limit
    end
  end
end


RootView.update = function(...)
  update(...)

  local av = get_active_view()
  if av then
    -- reset suggestions if caret was moved
    local line, col = av.doc:get_selection()
    if line ~= last_line or col ~= last_col then
      reset_suggestions()
    end
  end
end

local function predicate()
  return get_active_view() and #suggestions > 0
end


command.add(predicate, {
  ["autocomplete:complete"] = function()
    local doc = core.active_view.doc
    local line, col = doc:get_selection()
    local text = suggestions[suggestions_idx]
    doc:insert(line, col, text)
    doc:remove(line, col, line, col - #partial)
    doc:set_selection(line, col + #text - #partial)
    partial = text

    local av = get_active_view()
    last_line, last_col = av.doc:get_selection()

    if suggestions_idx < #suggestions then
      suggestions_idx = suggestions_idx + 1
    else
      suggestions_idx = 1
    end
  end,

  ["autocomplete:reverse-complete"] = function()
    local doc = core.active_view.doc
    local line, col = doc:get_selection()
    local text = suggestions[suggestions_idx]
    doc:insert(line, col, text)
    doc:remove(line, col, line, col - #partial)
    doc:set_selection(line, col + #text - #partial)
    partial = text

    local av = get_active_view()
    last_line, last_col = av.doc:get_selection()

    if suggestions_idx > 1 then
      suggestions_idx = suggestions_idx - 1
    else
      suggestions_idx = #suggestions
    end
  end,

  ["autocomplete:cancel"] = function()
    reset_suggestions()
  end,
})


keymap.add {
  ["tab"] = "autocomplete:complete",
  ["shift+tab"] = "autocomplete:reverse-complete",
  ["escape"] = "autocomplete:cancel",
}