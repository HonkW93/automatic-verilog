"-----------------------------------------------------------------------------
" Vim Plugin for Verilog Code Automactic Generation 
" Author:         HonkW
" Website:        https://honk.wang
" Last Modified:  2022/08/05 21:28
" File:           snippet.vim
" Note:           Snippet function partly from zhangguo's vimscript,partly from load_template
"------------------------------------------------------------------------------

"Sanity checks 启动判断{{{1
if exists("g:loaded_automatic_verilog_snippet")
    finish
endif
let g:loaded_automatic_verilog_snippet = 1

"Record update 记录脚本更新
autocmd BufWrite snippet.vim call s:UpdateVimscriptLastModifyTime()
function s:UpdateVimscriptLastModifyTime()
    let line = getline(5)
    if line =~ '\" Last Modified'
        call setline(5,"\" Last Modified:  " . strftime("%Y/%m/%d %H:%M"))
    endif
endfunction
"}}}1

"Defaults 默认设置{{{1
let g:_ATV_SNIPPET_DEFAULTS = {
            \'author':      'HonkW',
            \'company':     'NB Co.,Ltd.',
            \'project':     'IC_Design',
            \'device':      'Xilinx',
            \'email':       'contact@honk.wang',
            \'website':     'honk.wang',
            \'albpp_file':  expand("<sfile>:p:h").'/template/albpp.v',
            \'albpp_pos':   '4,13',
            \'albpn_file':  expand("<sfile>:p:h").'/template/albpn.v',
            \'albpn_pos':   '4,13',
            \'albnn_file':  expand("<sfile>:p:h").'/template/albnn.v',
            \'albnn_pos':   '4,13',
            \'albn_file':   expand("<sfile>:p:h").'/template/albn.v',
            \'albn_pos':    '4,13',
            \'albp_file':   expand("<sfile>:p:h").'/template/albp.v',
            \'albp_pos':    '4,13',
            \'alb_file':    expand("<sfile>:p:h").'/template/alb.v',
            \'alb_pos':     '3,9',
            \'att_file':    expand("<sfile>:p:h").'/template/auto_template.v',
            \'att_en':      0
            \}
for s:key in keys(g:_ATV_SNIPPET_DEFAULTS)
    if !exists('g:atv_snippet_' . s:key)
        let g:atv_snippet_{s:key} = copy(g:_ATV_SNIPPET_DEFAULTS[s:key])
    endif
    if s:key =~ 'alb.*_file'
        let g:atv_snippet_{s:key} = expand(g:atv_snippet_{s:key})
    endif
endfor
"}}}1

"Menu&Mapping 菜单栏和快捷键{{{1
amenu &Verilog.Code.Always@.always\ @(posedge\ or\ posedge)<TAB><<Leader>al>    :call <SID>AlBpp()<CR>
amenu &Verilog.Code.Always@.always\ @(posedge\ or\ negedge)                     :call <SID>AlBpn()<CR>
amenu &Verilog.Code.Always@.always\ @(*)                                        :call <SID>AlB()<CR>
amenu &Verilog.Code.Always@.always\ @(negedge\ or\ negedge)                     :call <SID>AlBnn()<CR>
amenu &Verilog.Code.Always@.always\ @(posedge)                                  :call <SID>AlBp()<CR>
amenu &Verilog.Code.Always@.always\ @(negedge)                                  :call <SID>AlBn()<CR>
amenu &Verilog.Code.Header.AddHeader<TAB><<Leader>hd>                           :call <SID>AddHeader()<CR>
amenu &Verilog.Code.Comment.SingleLineComment<TAB><<Leader>//>                  :call <SID>AutoComment()<CR>
amenu &Verilog.Code.Comment.MultiLineComment<TAB>Visual-Mode\ <<Leader>/*>      <Esc>:call <SID>AutoComment2()<CR>
amenu &Verilog.Code.Comment.CurLineAddComment<TAB><Leader>/$>                   :call <SID>AddCurLineComment()<CR>
if !hasmapto('<Leader>hd')
    nnoremap <Leader>hd                                                 :call <SID>AddHeader()<CR>
endif
if !hasmapto('<Leader>al')
    nnoremap <Leader>al                                                 :call <SID>AlBpp()<CR>
endif
if !hasmapto('<Leader>//','n')
    nnoremap <Leader>//                                                 :call <SID>AutoComment()<CR>
endif
if !hasmapto('<Leader>//','v')
    vnoremap <Leader>//                                                 <Esc>:call <SID>AutoComment2()<CR>
endif
if !hasmapto('<Leader>/e')
    nnoremap <Leader>/e                                                 :call <SID>AddCurLineComment()<CR>
endif
noremap <script> <Plug>Atv_Snippet_AddHeader;                           :call <SID>AddHeader()<CR>
noremap <script> <Plug>Atv_Snippet_AlBpp;                               :call <SID>AlBpp()<CR>
noremap <script> <Plug>Atv_Snippet_AlBpn;                               :call <SID>AlBpn()<CR>
noremap <script> <Plug>Atv_Snippet_AlB;                                 :call <SID>AlB()<CR>
noremap <script> <Plug>Atv_Snippet_AlBnn;                               :call <SID>AlBnn()<CR>
noremap <script> <Plug>Atv_Snippet_AlBp;                                :call <SID>AlBp()<CR>
noremap <script> <Plug>Atv_Snippet_AlBn;                                :call <SID>AlBn()<CR>
noremap <script> <Plug>Atv_Snippet_AutoComment;                         :call <SID>AutoComment()<CR>
noremap <script> <Plug>Atv_Snippet_AutoComment2;                        <Esc>:call <SID>AutoComment2()<CR>
noremap <script> <Plug>Atv_Snippet_AddCurLineComment;                   :call <SID>AddCurLineComment()<CR>
"}}}1

"Header

function s:AddHeader() "{{{1
    let line = getline(1)
    if line =~ '// +FHDR'               "Do not add header if existed
        return
    endif
    let filename = expand("%:t")
    let timelen = strlen(strftime("%Y/%m/%d"))
    let authorlen = strlen(g:atv_snippet_author)
    let lnum = 0
    call append(lnum,  "// +FHDR----------------------------------------------------------------------------")
    let lnum = lnum + 1
    if g:atv_snippet_project != ''
        call append(lnum,  "// Project Name  : ".g:atv_snippet_project)
        let lnum = lnum + 1
    endif
    if g:atv_snippet_device != ''
        call append(lnum,  "// Device        : ".g:atv_snippet_device)
        let lnum = lnum + 1
    endif
    if g:atv_snippet_author != ''
        call append(lnum,  "// Author        : ".g:atv_snippet_author)
        let lnum = lnum + 1
    endif
    if g:atv_snippet_email != ''
        call append(lnum,  "// Email         : ".g:atv_snippet_email)
        let lnum = lnum + 1
    endif
    if g:atv_snippet_website != ''
        call append(lnum,  "// Website       : ".g:atv_snippet_website)
        let lnum = lnum + 1
    endif
    call append(lnum,    "// Created On    : ".strftime("%Y/%m/%d %H:%M"))
    call append(lnum+1,  "// Last Modified : ".strftime("%Y/%m/%d %H:%M"))
    call append(lnum+2,  "// File Name     : ".filename)
    call append(lnum+3,  "// Description   :")
    call append(lnum+4,  "//         ")
    let lnum = lnum + 5
    let cursor_lnum = lnum
    if g:atv_snippet_company != ''
        call append(lnum,   "// Copyright (c) ".strftime("%Y ") . g:atv_snippet_company . ".")
        call append(lnum+1, "// ALL RIGHTS RESERVED")
        let lnum = lnum + 2
    endif
    call append(lnum,    "// ")
    call append(lnum+1,  "// ---------------------------------------------------------------------------------")
    call append(lnum+2,  "// Modification History:")
    call append(lnum+3,  "// Date         By              Version                 Change Description")
    call append(lnum+4,  "// ---------------------------------------------------------------------------------")
    call append(lnum+5,  "// ".strftime("%Y/%m/%d").repeat(" ", 13-timelen).g:atv_snippet_author.repeat(" ", 16-authorlen)."1.0                     Original")
    call append(lnum+6,  "// -FHDR----------------------------------------------------------------------------")
    let s:header_lnum = lnum + 6
    call cursor(cursor_lnum,10)
endfunction 
"}}}1

"Update Last Modify Time{{{1
augroup filetype_verilog
    "incase of no detection of systemverilog, don't use FileType
    autocmd BufWrite *.v call s:UpdateLastModifyTime()
    autocmd BufWrite *.sv call s:UpdateLastModifyTime()
augroup END
function s:UpdateLastModifyTime() "{{{2
    let idx = 0
    for line in getline(1,10)
        let idx = idx + 1
        if line =~ '// Last Modified'
            call setline(idx,"// Last Modified : " . strftime("%Y/%m/%d %H:%M"))
            return
        endif
    endfor
endfunction "}}}2
"}}}1

"AutoTemplate{{{1
augroup filetype_verilog
    autocmd BufNewFile *.v call s:AutoTemplate()
augroup END

function s:AutoTemplate() "{{{2
    if g:atv_snippet_att_en == 0
        return
    endif
    let lines = readfile(g:atv_snippet_att_file)
    if lines[0] =~ '\$header'
        call s:AddHeader()
        let lnum = s:header_lnum + 1
        let lines = lines[1:-1]
    else
        let lnum = 0
    endif
    let tpl_lines = []
    for line in lines
        if line =~ '\$module_name'
            let line = substitute(line,'\$module_name',matchstr(expand("%"),'\w\+'),'')
        endif
        call add(tpl_lines,line)
    endfor
    call append(lnum, tpl_lines)
endfunction "}}}2
"}}}1

"Always Block

function s:AlBpp() "{{{1
    let lines = readfile(g:atv_snippet_albpp_file)
    let lnum = line(".")-1
    call append(lnum,lines)
    let pos = split(g:atv_snippet_albpp_pos,',')
    call cursor(lnum+pos[0],pos[1])
endfunction "}}}1

function s:AlBpn() "{{{1
    let lines = readfile(g:atv_snippet_albpn_file)
    let lnum = line(".")-1
    call append(lnum,lines)
    let pos = split(g:atv_snippet_albpn_pos,',')
    call cursor(lnum+pos[0],pos[1])
endfunction "}}}1

function s:AlBnn() "{{{1
    let lines = readfile(g:atv_snippet_albnn_file)
    let lnum = line(".")-1
    call append(lnum,lines)
    let pos = split(g:atv_snippet_albnn_pos,',')
    call cursor(lnum+pos[0],pos[1])
endfunction "}}}1

function s:AlBp() "{{{1
    let lines = readfile(g:atv_snippet_albp_file)
    let lnum = line(".")-1
    call append(lnum,lines)
    let pos = split(g:atv_snippet_albp_pos,',')
    call cursor(lnum+pos[0],pos[1])
endfunction "}}}1

function s:AlBn() "{{{1
    let lines = readfile(g:atv_snippet_albn_file)
    let lnum = line(".")-1
    call append(lnum,lines)
    let pos = split(g:atv_snippet_albn_pos,',')
    call cursor(lnum+pos[0],pos[1])
endfunction "}}}1

function s:AlB() "{{{1
    let lines = readfile(g:atv_snippet_alb_file)
    let lnum = line(".")-1
    call append(lnum,lines)
    let pos = split(g:atv_snippet_alb_pos,',')
    call cursor(lnum+pos[0],pos[1])
endfunction "}}}1

"Comment

function s:AutoComment() "{{{1
    let lnum = line(".")
    let line = getline(lnum)
    if line =~ '^\/\/ by .* \d\d\d\d-\d\d-\d\d'
        let tmp_line = substitute(line,'^\/\/ by .* \d\d\d\d-\d\d-\d\d | ','','')
    else
        let tmp_line = '// by ' . g:atv_snippet_author . ' ' . strftime("%Y-%m-%d") . ' | ' . line
    endif
    call setline(lnum,tmp_line)
endfunction "}}}1

function s:AutoComment2() "{{{1
    let col = col(".")
    let lnum = line(".")
    if line("'<") == lnum || line("'>") == lnum
        if getline(line("'<")) =~ '^/\*'
            '<
            execute "normal dd"
            '>
            execute "normal dd"
            if lnum != line("'<")
                let lnum = line("'>")-1
            endif
        else
            call append(line("'<")-1,'/*----------------  by '.g:atv_snippet_author.' '.strftime("%Y-%m-%d").'  ---------------------')
            call append(line("'>")  ,'------------------  by '.g:atv_snippet_author.' '.strftime("%Y-%m-%d").'  -------------------*/')
            let lnum = line(".")
        endif
    endif
    call cursor(lnum,col)
endfunction "}}}1

function s:AddCurLineComment() "{{{1
    let lnum = line(".")
    let line = getline(lnum)
    let tmp_line = line . ' // ' . g:atv_snippet_author . ' ' . strftime("%Y-%m-%d") . ' |'
    call setline(lnum,tmp_line)
    normal $
endfunction "}}}1
