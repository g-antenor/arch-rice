local M = {}
function M.setup()
 if vim.g.dark_mountain_watching then return end
 vim.g.dark_mountain_watching = true
 local group=vim.api.nvim_create_augroup("DarkMountainTheme",{clear=true})
 local state=(vim.env.XDG_STATE_HOME or (vim.env.HOME.."/.local/state")).."/dark-mountain"
 local function reload() if vim.g.colors_name=="dark-mountain" then vim.cmd.colorscheme("dark-mountain") end end
 vim.api.nvim_create_autocmd("FocusGained",{group=group,callback=reload})
 local watcher=vim.uv.new_fs_event()
 if watcher then
  watcher:start(state,{},vim.schedule_wrap(function(err,file) if not err and file=="theme.json" then reload() end end))
  vim.api.nvim_create_autocmd("VimLeavePre",{group=group,callback=function() watcher:stop();if not watcher:is_closing() then watcher:close() end end})
 end
end
return M
