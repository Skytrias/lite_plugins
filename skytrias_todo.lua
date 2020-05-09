local common = require "core.common"
local DocView = require "core.docview"
local style = require "core.style"

local draw_line_text = DocView.draw_line_text

local topic_color = { common.color "#443366" }
local sub_topic_color = { common.color "#115555" }
local numbers_done_color = { common.color "#117711" }
local numbers_color = { common.color "#771111" }

function DocView:draw_line_text(idx, x, y)
	-- removes the .c part or any other file extension
	local file_name = self:get_name():match"([^.]*).(.*)"

	if file_name == "todo" then
		local text = self.doc.lines[idx]
		local brace_op_s, brace_op_e = text:find("{");
		-- find any tabs that have no tab infront of it
		local tab_s, tab_e = text:find("\t[^\t].+");

		-- once inside a brace
		if brace_op_s then
			local lh = self:get_line_height()
			local x1, x2 = 0, 0

			if tab_s then
				x1 = x + self:get_col_x_offset(idx, tab_s + 1)
      	x2 = x + self:get_col_x_offset(idx, tab_e)
			else
      	x2 = x + self:get_col_x_offset(idx, brace_op_e)
			end

			local font = self:get_font()
			local lw = font:get_width(" ")

			local tasks_finished_count = 0
			local task_count = 0
			local below_index = 1
			local below_line = self.doc.lines[idx + below_index]
			local brace_cl_s, _ = below_line:find("}")

			-- cond that the closed brace has to equal the tab start or the standard 1
			local cond = true
			if tab_s then
				cond = brace_cl_s == tab_s
			else
				cond = brace_cl_s == 1
			end

			while not (brace_cl_s and cond) and below_line do
				local any_characters = below_line:find("[a-z]")
				local any_large_characters = below_line:find("[A-Z]")
				local other_brace_start, _ = below_line:find("{")
				local finish_token, _ = below_line:find("\t[.][^\t]")

				if not other_brace_start and (any_characters or any_large_characters) then
					task_count = task_count + 1

					if finish_token then
						tasks_finished_count = tasks_finished_count + 1
					end
				end

				below_index = below_index + 1
				below_line = self.doc.lines[idx + below_index]

				if below_line then
					brace_cl_s, _ = below_line:find("}")

					if tab_s then
						cond = brace_cl_s == tab_s + 1
					else
						cond = brace_cl_s == 1
					end
				end
			end

			if tab_s then
      	renderer.draw_rect(x1, y, x2 - x1, lh, sub_topic_color)
			else
  			renderer.draw_rect(x, y, self.size.x, lh, topic_color)
			end

			renderer.draw_rect(x2 + 4 * lw, y, 5 * lw, lh, numbers_color)
			renderer.draw_rect(x2 + 4 * lw, y, (tasks_finished_count / task_count) * 5 * lw, lh, numbers_done_color)
			renderer.draw_text(font, tasks_finished_count .. " / " .. task_count, x2 + 4 * lw, y, style.text)

-- 			if tab_s then
-- 				renderer.draw_text(font, brace_cl_s .. "   " .. tab_s .. "   " .. tostring(cond), x2 + 29 * lw, y, style.text)
-- 			else
-- 				renderer.draw_text(font, brace_cl_s .. "   " .. 1 .. "   " .. tostring(cond), x2 + 29 * lw, y, style.text)
-- 			end
		end
	end

	draw_line_text(self, idx, x, y)
end
