local core = require "core"
local translate = require "core.doc.translate"
local DocView = require "core.docview"
local command = require "core.command"

local on_text_input = DocView.on_text_input
local simple_completions = {
  ["("] = ")",
  ["["] = "]",
  ["\""] = "\"",
  ["\'"] = "\'",
}
local word_completions = {
  ["then"] = "end",
  ["do"] = "end",
}
local last_char_written = nil

-- TODO(Skytrias): make these not work in quotes or comments
DocView.on_text_input = function(self, ...)
  on_text_input(self, ...)

  local doc = core.active_view.doc
  local was_whitespace = last_char_written == " "

  -- single char completion
  local line2, col2 = doc:get_selection()
  local line1, col1 = doc:position_offset(line2, col2, translate.previous_char)
  local text = doc:get_text(line1, col1, line2, col2)
  if was_whitespace and text == "{" then
    command.perform("doc:newline")
    command.perform("doc:newline")
    doc:insert(line2 + 2, col2, "}")
    doc:set_selection(line2 + 1, col2)
    command.perform("doc:indent")
  end

  -- simple insertion
  if simple_completions[text] then
    doc:insert(line2, col2, simple_completions[text])
  end

  -- used for c to create a pointer assignment with c
  if not was_whitespace and text == "-" then
    doc:insert(line2, col2, ">")
    doc:set_selection(line2, col2 + 1)
  end

   -- full word completion
  line1, col1 = doc:position_offset(line2, col2, translate.previous_word_boundary)
  text = doc:get_text(line1, col1, line2, col2)
  if word_completions[text] then
    command.perform("doc:newline")
    command.perform("doc:newline")
    doc:insert(line2 + 2, col2, word_completions[text])
    doc:set_selection(line2 + 1, col2)
    command.perform("doc:indent")
  end

  last_char_written = text
end
