"-----------------------------------------------------------------------------
" Vim Plugin for Verilog Code Automactic Generation 
" Author:         HonkW
" Website:        https://honk.wang
" Last Modified:  2022/01/06 21:52
" File:           timewave.vim
" Note:           Timewave function totally copy from zhangguo's vimscript,only add mapping
"------------------------------------------------------------------------------

"Sanity checks 启动判断{{{1
if exists("g:loaded_automatic_verilog_timewave")
    finish
endif
let g:loaded_automatic_verilog_timewave = 1

"Record update 记录脚本更新
autocmd BufWrite timewave.vim call s:UpdateVimscriptLastModifyTime()
function s:UpdateVimscriptLastModifyTime()
    let line = getline(5)
    if line =~ '\" Last Modified'
        call setline(5,"\" Last Modified:  " . strftime("%Y/%m/%d %H:%M"))
    endif
endfunction
"}}}1

"Defaults 默认设置{{{1
let g:_ATV_TIMEWAVE_DEFAULTS = {
            \'sig_offset':    13,        
            \'clk_period':    8,
            \'clk_num':       16,
            \'cq_trans':      2
            \}

for s:key in keys(g:_ATV_TIMEWAVE_DEFAULTS)
    if !exists('g:atv_timewave_' . s:key)
        let g:atv_timewave_{s:key} = copy(g:_ATV_TIMEWAVE_DEFAULTS[s:key])
    endif
endfor

"let s:sig_offset = 13+4                                    "signal offset (0 is clk posedge, 4 is clk negedge)
let s:sig_offset = g:atv_timewave_sig_offset                "signal offset
let s:clk_period = g:atv_timewave_clk_period                "clock period
let s:clk_num = g:atv_timewave_clk_num                      "number of clocks generated
let s:cq_trans = g:atv_timewave_cq_trans                    "signal transition started n spaces after clock transition
let s:wave_max_wd = s:sig_offset + s:clk_num*s:clk_period   "maximum width
"}}}1

"Menu&Mapping 菜单栏和快捷键{{{1
amenu &Verilog.Wave.AddClk                                              :call <SID>AddClk()<CR>
amenu &Verilog.Wave.AddSig                                              :call <SID>AddSig()<CR>
amenu &Verilog.Wave.AddBus                                              :call <SID>AddBus()<CR>
amenu &Verilog.Wave.AddBlk                                              :call <SID>AddBlk()<CR>
amenu &Verilog.Wave.AddNeg                                              :call <SID>AddNeg()<CR>
amenu &Verilog.Wave.-Operation-                                         :
amenu &Verilog.Wave.Invert                                              :call <SID>Invert()<CR>
if !hasmapto('<Leader>clk')
    nnoremap <Leader>clk                                                :call <SID>AddClk()<CR>
endif
if !hasmapto('<Leader>sig')
    nnoremap <Leader>sig                                                :call <SID>AddSig()<CR>
endif
if !hasmapto('<Leader>bus')
    nnoremap <Leader>bus                                                :call <SID>AddBus()<CR>
endif
if !hasmapto('<Leader>blk')
    nnoremap <Leader>blk                                                :call <SID>AddBlk()<CR>
endif
if !hasmapto('<Leader>neg')
    nnoremap <Leader>neg                                                :call <SID>AddNeg()<CR>
endif
if !hasmapto('<Leader>inv')
    nnoremap <Leader>inv                                                :call <SID>Invert()<CR>
endif
noremap <script> <Plug>Atv_Timewave_AddClk;                             :call <SID>AddClk()<CR>
noremap <script> <Plug>Atv_Timewave_AddSig;                             :call <SID>AddSig()<CR>
noremap <script> <Plug>Atv_Timewave_AddBus;                             :call <SID>AddBus()<CR>
noremap <script> <Plug>Atv_Timewave_AddBlk;                             :call <SID>AddBlk()<CR>
noremap <script> <Plug>Atv_Timewave_AddNeg;                             :call <SID>AddNeg()<CR>
noremap <script> <Plug>Atv_Timewave_Invert;                             :call <SID>Invert()<CR>
"}}}1

function s:AddClk() "{{{1
    let ret = []
    let ret0 = "//  .   .   ."
    let ret1 = "//          +"
    let ret2 = "// clk      |"
    let ret3 = "//          +"
    let format = '%' . s:clk_period/2 . 'd'
    for idx in range(1,s:clk_num)
        let ret0 = ret0 . printf(format,idx) . repeat(' ',s:clk_period/2)
        let ret1 = ret1 . repeat('-',s:clk_period/2-1)
        let ret2 = ret2 . repeat(' ',s:clk_period/2-1)
        let ret3 = ret3 . repeat(' ',s:clk_period/2-1)
        let ret1 = ret1 . '+'
        let ret2 = ret2 . '|'
        let ret3 = ret3 . '+'
        let ret1 = ret1 . repeat(' ',s:clk_period/2-1)
        let ret2 = ret2 . repeat(' ',s:clk_period/2-1)
        let ret3 = ret3 . repeat('-',s:clk_period/2-1)
        let ret1 = ret1 . '+'
        let ret2 = ret2 . '|'
        let ret3 = ret3 . '+'
    endfor
    call add(ret,ret0)
    call add(ret,ret1)
    call add(ret,ret2)
    call add(ret,ret3)
    let lnum = line(".")
    let col = col(".")
    call append(line("."),ret)
    call cursor(lnum+4,col)
endfunction 
"}}}1

function s:AddSig() "{{{1
    let ret = []
    let ret0 = "//          "
    let ret1 = "// sig      "
    let ret2 = "//          "
    let ret0 = ret0 . repeat(' ',s:clk_num*s:clk_period+1)
    let ret1 = ret1 . repeat(' ',s:clk_num*s:clk_period+1)
    let ret2 = ret2 . repeat('-',s:clk_num*s:clk_period+1)
    call add(ret,ret0)
    call add(ret,ret1)
    call add(ret,ret2)
    let lnum = line(".")
    let col = col(".")
    call append(line("."),ret)
    call cursor(lnum+3,col)
endfunction "}}}1

function s:AddBus() "{{{1
    let ret = []
    let ret0 = "//          "
    let ret1 = "// bus      "
    let ret2 = "//          "
    let ret0 = ret0 . repeat('-',s:clk_num*s:clk_period+1)
    let ret1 = ret1 . repeat(' ',s:clk_num*s:clk_period+1)
    let ret2 = ret2 . repeat('-',s:clk_num*s:clk_period+1)
    call add(ret,ret0)
    call add(ret,ret1)
    call add(ret,ret2)
    let lnum = line(".")
    let col = col(".")
    call append(line("."),ret)
    call cursor(lnum+3,col)
endfunction "}}}1

function s:AddNeg() "{{{1
    let lnum = s:GetSigNameLineNum()
    if lnum == -1
        return
    endif
    let line = getline(lnum)
    if line =~ 'neg\s*$'
        return
    endif
    call setline(lnum,line." neg")
endfunction "}}}1

function s:AddBlk() "{{{1
    let ret = []
    let ret0 = "//          "
    let ret0 = ret0 . repeat(' ',s:clk_num*s:clk_period+1)
    call add(ret,ret0)
    let lnum = line(".")
    let col = col(".")
    call append(line("."),ret)
    call cursor(lnum+1,col)
endfunction "}}}1

function s:Invert() "{{{1
"   e.g
"   clk_period = 8
"   clk_num = 16
"   cq_trans = 1
"
"1  .   .   .   1       2       3       4       5       6       7       8       9      10      11      12      13      14      15      16    
"2          +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +
"3 clk      |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |
"4          +   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+
"5
"6                           +-------+                                                                                                       
"7 sig                       |*      |                                                                                                       
"8          -----------------+       +-------------------------------------------------------------------------------------------------------
"1.........13..............29......37
"
    let lnum = s:GetSigNameLineNum()    "7
    if lnum == -1
        return
    endif

    let top = getline(lnum-1)   "line 6
    let mid = getline(lnum)     "line 7
    let bot = getline(lnum+1)   "line 8

    let signeg = s:SigIsNeg()                   "detect negative marker 
    let posedge = s:GetPosedge(signeg)          "detect nearest posedge     29
    let negedge = posedge + s:clk_period/2      "detect next negedge        33
    let next_posedge = posedge + s:clk_period   "detect next posedge        37 

    let last = s:SigLastClkIsHigh(lnum,posedge,negedge)     "detect line 6, col 29 is not '-'   last = 0
    let cur = s:SigCurClkIsHigh(lnum,posedge,negedge)       "detect line 6, col 33 is '-'       cur = 1
    let next = s:SigNextClkIsHigh(lnum,posedge,negedge)     "detect line 6, col 37 is '-'       next = 1
    let chg = s:BusCurClkHaveChg(lnum,posedge,negedge)      "judge if bus marker 'X' to see if already changed

    "from 0 to posedge+cq_trans-1{{{2
    let res_top = strpart(top,0,posedge+s:cq_trans-1)
    let res_mid = strpart(mid,0,posedge+s:cq_trans-1)
    let res_bot = strpart(bot,0,posedge+s:cq_trans-1)
    "}}}2

    "from posedge+cq_trans to (posedge+clk_period)(i.e.next_posedge)+cq_trans-1{{{2
    let init_top_char = ' '
    let init_mid_char = ' '
    let init_bot_char = ' '
    let top_char = ' '
    let mid_char = ' '
    let bot_char = ' '
    let is_bus = 0

    if top[negedge] =~ '-' && bot[negedge] =~ '-'           "two lines, must be bus
        let is_bus = 1
        if chg
            let init_top_char = '-'
            let init_mid_char = ' '
            let init_bot_char = '-'
        else
            let init_top_char = ' '
            let init_mid_char = 'X'
            let init_bot_char = ' '
        endif
        let top_char = '-'
        let mid_char = ' '
        let bot_char = '-'
        let res_top = res_top . init_top_char
        let res_mid = res_mid . init_mid_char
        let res_bot = res_bot . init_bot_char
        for idx in range(1,s:clk_period-1)
            let res_top = res_top . top_char
            let res_mid = res_mid . mid_char
            let res_bot = res_bot . bot_char
        endfor
    else                                                    "one line or none, signal
        if last == cur
            if cur                                          "last=1 cur=1 both high
                let init_top_char = '+'
                let init_mid_char = '|'
                let init_bot_char = '+'
                let top_char = ' '
                let bot_char = '-'
            else
                let init_top_char = '+'                     "last=0 cur=0 both low 
                let init_mid_char = '|'
                let init_bot_char = '+'
                let top_char = '-'
                let bot_char = ' '
            endif
        else
            if cur                                          "last=0 cur=1 posedge
                let init_top_char = ' '
                let init_mid_char = ' '
                let init_bot_char = '-'
                let top_char = ' '
                let bot_char = '-'
            else
                let init_top_char = '-'                     "last=1 cur=0 negedge
                let init_mid_char = ' '
                let init_bot_char = ' '
                let top_char = '-'
                let bot_char = ' '
            endif
        endif

        let res_top = res_top . init_top_char
        let res_mid = res_mid . init_mid_char
        let res_bot = res_bot . init_bot_char
        for idx in range(1,s:clk_period-1)
            let res_top = res_top . top_char
            let res_mid = res_mid . mid_char
            let res_bot = res_bot . bot_char
        endfor

        if next == cur                                      "cur=next=1 or 0
            let init_top_char = '+'
            let init_mid_char = '|'
            let init_bot_char = '+'
        else
            if cur
                let init_top_char = ' '
                let init_mid_char = ' '
                let init_bot_char = '-'
            else
                let init_top_char = '-'
                let init_mid_char = ' '
                let init_bot_char = ' '
            endif
        endif
        let res_top = res_top . init_top_char
        let res_mid = res_mid . init_mid_char
        let res_bot = res_bot . init_bot_char
    endif
    "}}}2

    "from posedge+clk_period+cq_trans to max{{{2
    let res_top = res_top .strpart(top,posedge+s:cq_trans+s:clk_period-is_bus,s:wave_max_wd-1)
    let res_mid = res_mid .strpart(mid,posedge+s:cq_trans+s:clk_period-is_bus,s:wave_max_wd-1)
    let res_bot = res_bot .strpart(bot,posedge+s:cq_trans+s:clk_period-is_bus,s:wave_max_wd-1)
    "}}}2

    call setline(lnum-1,res_top)
    call setline(lnum,res_mid)
    call setline(lnum+1,res_bot)

endfunction 
"}}}1

"Sub-Funciton-For-Invert(){{{1

function s:GetSigNameLineNum() "{{{2
    let lnum = -1
    let cur_lnum = line(".")
    if getline(cur_lnum) =~ '^\/\/\s*\(sig\|bus\)'
        let lnum = cur_lnum
    elseif getline(cur_lnum-1) =~ '^\/\/\s*\(sig\|bus\)'
        let lnum = cur_lnum-1
    elseif getline(cur_lnum+1) =~ '^\/\/\s*\(sig\|bus\)'
        let lnum = cur_lnum+1
    endif
    return lnum
endfunction "}}}2

function s:GetPosedge(signeg) "{{{2
    "calculate the width between col(".") and the nearest posedge
    if a:signeg == 0
        let ret = col(".") - s:sig_offset
        while 1
            if ret >= s:clk_period
                let ret = ret - s:clk_period
            else
                break
            endif
        endwhile
        return col(".") - ret
    else
        let ret = col(".") - s:sig_offset + s:clk_period/2
        while 1
            if ret >= s:clk_period
                let ret = ret - s:clk_period
            else
                break
            endif
        endwhile
        return col(".") - ret
    endif
endfunction "}}}2

function s:SigLastClkIsHigh(lnum,posedge,negedge) "{{{2
    let ret = 0
    let line = getline(a:lnum - 1)
    if line[a:posedge-1] =~ '-'
        let ret = 1
    endif
    return ret
endfunction "}}}2

function s:SigCurClkIsHigh(lnum,posedge,negedge) "{{{2
    let ret = 0
    let line = getline(a:lnum - 1)
    if line[a:negedge-1] =~ '-'
        let ret = 1
    endif
    return ret
endfunction "}}}2

function s:SigNextClkIsHigh(lnum,posedge,negedge) "{{{2
    let ret = 0
    let line = getline(a:lnum - 1)
    if line[a:negedge+s:clk_period-1] =~ '-'
        let ret = 1
    endif
    return ret
endfunction "}}}2

function s:BusCurClkHaveChg(lnum,posedge,negedge) "{{{2
    let ret = 0
    let line = getline(a:lnum)
    if line[a:posedge+s:cq_trans-1] =~ 'X'
        let ret = 1
    endif
    return ret
endfunction "}}}2

function s:SigIsNeg() "{{{2
    let ret = 0
    let lnum = s:GetSigNameLineNum()
    if getline(lnum) =~ 'neg\s*$'
        let ret = 1
    endif
    return ret
endfunction "}}}2

"}}}1
