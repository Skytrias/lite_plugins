local common = require "core.common"
local DocView = require "core.docview"

local draw_line_text = DocView.draw_line_text
local highlights = {
--   ["TODO:"] = { common.color "#662222" },
  ["TODO%(.-%):"] = { common.color "#662222" },
--   ["NOTE:"] = { common.color "#224477" },
  ["NOTE%(.-%):"] = { common.color "#224477" },
}

function DocView:draw_line_text(idx, x, y)
  for key, val in pairs(highlights) do
    local text = self.doc.lines[idx]
    local s, e = text:find(key)
    if s then
      local x1 = x + self:get_col_x_offset(idx, s)
      local x2 = x + self:get_col_x_offset(idx, e + 1)
      renderer.draw_rect(x1, y, x2 - x1, self:get_line_height(), val)
    end
  end

  draw_line_text(self, idx, x, y)
end

