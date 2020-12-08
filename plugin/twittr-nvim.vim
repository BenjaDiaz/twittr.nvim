fun! TwittrNvimPlugin()
    lua for k in pairs(package.loaded) do if k:match("^twittr%-nvim") then package.loaded[k] = nil end end
    lua require("twittr-nvim").open_timeline()
endfun

augroup TwittrNvimPlugin
    autocmd!
    autocmd FileType twittr-nvim autocmd CursorMoved <buffer> lua require("twittr-nvim").update_preview()
augroup END

hi def link TwittrHeader      Number
