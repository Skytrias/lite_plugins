local core = require "core"
local translate = require "core.doc.translate"
local DocView = require "core.docview"
local command = require "core.command"

local on_text_input = DocView.on_text_input
local completions = {
  { "fori", [[for (i32 i = 0; i = ; i++) {

}]], 20, 0,
  },
  { "forj", [[for (i32 j = 0; j = ; j++) {

}]], 20, 0,
  },
  { "forw", [[for (i32 i = 0; i = GRID_WIDTH; i++) {

}]], 0, 1,
  },
  { "forh", [[for (i32 i = 0; i = GRID_HEIGHT; i++) {

}]], 0, 1,
  },
  { "if", [[if () {

}]], 4, 0,
  },
}

-- TODO(Skytrias): indent new lines to current indentation
DocView.on_text_input = function(self, ...)
  on_text_input(self, ...)

  local doc = core.active_view.doc
  local line2, col2 = doc:get_selection()
  local line1, col1 = doc:position_offset(line2, col2, translate.start_of_word)
  local text = doc:get_text(line1, col1, line2, col2)

  for i, _ in pairs(completions) do
    if text == completions[i][1] then
      doc:remove(line1, col1, line2, col2)
      doc:insert(line1, col1, completions[i][2])
      doc:set_selection(line1 + completions[i][4], col1 + completions[i][3])
    end
  end
end
