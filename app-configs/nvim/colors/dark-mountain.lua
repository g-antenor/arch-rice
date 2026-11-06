vim.cmd("highlight clear")
vim.g.colors_name = "dark-mountain"
vim.o.termguicolors = true
local function json(path)
 local ok,lines=pcall(vim.fn.readfile,path)
 if not ok then return {} end
 local parsed,value=pcall(vim.json.decode,table.concat(lines,"\n"))
 return parsed and value or {}
end
local state=(vim.env.XDG_STATE_HOME or (vim.env.HOME.."/.local/state")).."/dark-mountain"
local c=json(state.."/theme.json")
local source=vim.uv.fs_realpath(vim.fn.stdpath("config"))
local themes=source and json(vim.fs.dirname(vim.fs.dirname(source)).."/themes.json") or {}
local colors=(themes[c.name or "mountain"] or {}).ansi or {"#303030","#ac8a8c","#8aac8b","#aca98a","#8f8aac","#ac8aac","#8aacab","#e7e7e7"}
local fg,muted,accent,surface=c.text or "#e7e7e7",c.muted or "#999999",c.accent or "#8f8aac",c.surface or "#101010"
local function hl(name,value) vim.api.nvim_set_hl(0,name,value) end
hl("Normal",{fg=fg,bg="NONE"});hl("NormalNC",{fg=fg,bg="NONE"})
hl("NormalFloat",{fg=fg,bg=surface});hl("FloatBorder",{fg=c.border or "#303030",bg=surface})
hl("Pmenu",{fg=fg,bg=surface});hl("PmenuSel",{fg="#000000",bg=accent,bold=true})
hl("Visual",{bg="#303030"});hl("Search",{fg="#000000",bg=accent})
hl("CursorLine",{bg=surface});hl("CursorLineNr",{fg=accent,bold=true});hl("LineNr",{fg=muted})
hl("Comment",{fg=muted,italic=true});hl("String",{fg=colors[3]});hl("Number",{fg=colors[7]})
hl("Function",{fg=accent});hl("Identifier",{fg=fg});hl("Statement",{fg=colors[6],bold=true})
hl("Type",{fg=colors[4]});hl("Special",{fg=colors[7]});hl("Constant",{fg=colors[6]})
hl("ErrorMsg",{fg=c.danger or colors[2]});hl("DiagnosticError",{fg=c.danger or colors[2]})
hl("DiagnosticWarn",{fg=colors[4]});hl("DiagnosticInfo",{fg=accent});hl("DiagnosticHint",{fg=muted})
hl("StatusLine",{fg=fg,bg=surface});hl("StatusLineNC",{fg=muted,bg=surface})
hl("WinSeparator",{fg=c.border or "#303030"});hl("Title",{fg=accent,bold=true})
hl("Directory",{fg=accent});hl("SpecialKey",{fg=muted});hl("EndOfBuffer",{fg=surface})
for i,color in ipairs(colors) do vim.g["terminal_color_"..(i-1)]=color end
