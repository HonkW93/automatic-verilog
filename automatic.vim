"-----------------------------------------------------------------------------
" Vim Plugin for Verilog Code Automactic Generation 
" Author:         HonkW
" Website:        https://honk.wang
" Last Modified:  2021/05/08 23:41
"------------------------------------------------------------------------------
" Modification History:
" Date          By              Version                 Change Description")
"------------------------------------------------------------------------------
" 2021/3/26     HonkW           1.0.0                   First copy from zhangguo's vimscript
" 2021/4/5      HonkW           1.0.1                   Finish AutoInst & Autopara
" 2021/4/19     HonkW           1.0.2                   Finish GetReg
" 2021/4/24     HonkW           1.0.3                   Add read .sv file 
" 2021/4/30     HonkW           1.0.4                   Bug fixed & Add " ',' feature for AutoPara
" 2021/5/8      HonkW           1.0.5                   Compatible with vim 7.4
" For vim version 7.x or above
"-----------------------------------------------------------------------------
"Update 记录脚本更新{{{1
autocmd BufWrite automatic.vim call UpdateVimscriptLastModifyTime()
function UpdateVimscriptLastModifyTime()
    let line = getline(5)
    if line =~ '\" Last Modified'
        call setline(5,"\" Last Modified:  " . strftime("%Y/%m/%d %H:%M"))
    endif
endfunction
"}}}1

"Version 启动判断{{{1
if version < 700        "如果vim版本低于7.0则无效,类似写法为 if v:version < 703,代表版本低于7.3
   finish
endif
if exists("vlog_plugin")
   finish
endif
let vlog_plugin = 1
"}}}1

"Config 配置参数{{{1

"Position 确定信号对齐位置{{{2
let s:name_pos_max = 32
let s:symbol_pos_max = 64
let s:start_pos  = 4
let s:start_prefix = repeat(' ',s:start_pos)
"}}}2

"AutoInst 自动例化配置{{{2
let s:IO_DIR = 1        "add //input or //output in the end of instance
let s:INST_NEW = 1      "add //INST_NEW if port has been newly added to the module
let s:INST_DEL = 1      "add //INST_DEL if port has been deleted from the module
"}}}2

"AutoPara 自动参数配置{{{2
let s:ONLY_PORT = 1     "add only port parameter definition,ignore parameter = value; definition
let s:PARA_NEW = 1      "add //PARA_NEW if parameter has been newly added to the module
let s:PARA_DEL = 1      "add //PARA_DEL if parameter has been deleted from the module
"}}}2

"Timing Wave 定义波形{{{2
let s:sig_offset = 13           "Signal offset 
"let s:sig_offset = 13+4         "Signal offset (0 is clk posedge, 4 is clk negedge)
let s:clk_period = 8            "Clock period
let s:clk_num = 16              "Number of clocks generated
let s:cq_trans = 1              "Signal transition started N spaces after clock transition
let s:wave_max_wd = s:sig_offset + s:clk_num*s:clk_period       "Maximum Width
"}}}2

" Verilog Type 定义Verilog变量类型{{{2

"Port 端口类型
let s:VlogTypePort =                  '\<input\>\|'
let s:VlogTypePort = s:VlogTypePort . '\<output\>\|'
let s:VlogTypePort = s:VlogTypePort . '\<inout\>'

"Data 数据类型
let s:VlogTypeData =                  '\<wire\>\|'
let s:VlogTypeData = s:VlogTypeData . '\<reg\>\|'
let s:VlogTypeData = s:VlogTypeData . '\<parameter\>\|'
let s:VlogTypeData = s:VlogTypeData . '\<localparam\>\|'
let s:VlogTypeData = s:VlogTypeData . '\<genvar\>\|'
let s:VlogTypeData = s:VlogTypeData . '\<integer\>'

"Calculation 计算类型
let s:VlogTypeCalc =                  '\<assign\>\|'
let s:VlogTypeCalc = s:VlogTypeCalc . '\<always\>'

"Structure 结构类型
let s:VlogTypeStru =                  '\<module\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<endmodule\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<function\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<endfunction\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<task\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<endtask\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<generate\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<endgenerate\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<begin\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<end\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<case\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<casex\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<casez\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<endcase\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<default\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<for\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<if\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<define\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<ifdef\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<ifndef\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<elsif\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<else\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<endif\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<celldefine\>\|'
let s:VlogTypeStru = s:VlogTypeStru . '\<endcelldefine\>'

"Others 其他类型
let s:VlogTypeOthe =                  '\<posedge\>\|'
let s:VlogTypeOthe = s:VlogTypeOthe . '\<negedge\>\|'
let s:VlogTypeOthe = s:VlogTypeOthe . '\<timescale\>\|'
let s:VlogTypeOthe = s:VlogTypeOthe . '\<initial\>\|'
let s:VlogTypeOthe = s:VlogTypeOthe . '\<forever\>\|'
let s:VlogTypeOthe = s:VlogTypeOthe . '\<specify\>\|'
let s:VlogTypeOthe = s:VlogTypeOthe . '\<endspecify\>\|'
let s:VlogTypeOthe = s:VlogTypeOthe . '\<include\>\|'
let s:VlogTypeOthe = s:VlogTypeOthe . '\<or\>'

"() 括号包含
let s:VlogTypePre  = '\('
let s:VlogTypePost = '\)'
let s:VlogTypeConn = '\|'

let s:VlogTypePorts = s:VlogTypePre . s:VlogTypePort . s:VlogTypePost
let s:VlogTypeDatas = s:VlogTypePre . s:VlogTypeData . s:VlogTypePost
let s:VlogTypeCalcs = s:VlogTypePre . s:VlogTypeCalc . s:VlogTypePost
let s:VlogTypeStrus = s:VlogTypePre . s:VlogTypeStru . s:VlogTypePost
let s:VlogTypeOthes = s:VlogTypePre . s:VlogTypeOthe . s:VlogTypePost

"Keywords 关键词类型
let s:VlogKeyWords  = s:VlogTypePre . s:VlogTypePort . s:VlogTypeConn .  s:VlogTypeData . s:VlogTypeConn. s:VlogTypeCalc . s:VlogTypeConn. s:VlogTypeStru . s:VlogTypeConn. s:VlogTypeOthe . s:VlogTypePost

"Not Keywords 非关键词类型
let s:not_keywords_pattern = s:VlogKeyWords . '\@!\(\<\w\+\>\)'

"}}}2

"}}}1

"Keys 快捷键{{{1

"Menu 菜单栏{{{2

"TimingWave 时序波形{{{3
amenu &Verilog.Wave.AddClk                                              :call AddClk()<CR>
amenu &Verilog.Wave.AddSig                                              :call AddSig()<CR>
amenu &Verilog.Wave.AddBus                                              :call AddBus()<CR>
amenu &Verilog.Wave.AddBlk                                              :call AddBlk()<CR>
amenu &Verilog.Wave.AddNeg                                              :call AddNeg()<CR>
amenu &Verilog.Wave.-Operation-                                         :
amenu &Verilog.Wave.Invert<TAB><C-F8>                                   :call Invert()<CR>
"}}}3

"Code Snippet 代码段{{{3
amenu &Verilog.Code.Always@.always\ @(posedge\ or\ posedge)<TAB><;al>   :call AlBpp()<CR>
amenu &Verilog.Code.Always@.always\ @(posedge\ or\ negedge)             :call AlBpn()<CR>
amenu &Verilog.Code.Always@.always\ @(*)                                :call AlB()<CR>
amenu &Verilog.Code.Always@.always\ @(negedge\ or\ negedge)             :call AlBnn()<CR>
amenu &Verilog.Code.Always@.always\ @(posedge)                          :call AlBp()<CR>
amenu &Verilog.Code.Always@.always\ @(negedge)                          :call AlBn()<CR>
amenu &Verilog.Code.Header.AddHeader<TAB><;header>                      :call AddHeader()<CR>
amenu &Verilog.Code.Comment.SingleLineComment<TAB><;//>                 :call AutoComment()<CR>
amenu &Verilog.Code.Comment.MultiLineComment<TAB>Visual-Mode\ <;/*>     :call AutoComment2()<CR>
amenu &Verilog.Code.Comment.CurLineAddComment<TAB><;/$>                 :call AddCurLineComment()<CR>
amenu &Verilog.Code.Template.LoadTemplate<TAB>                          :call LoadTemplate()<CR>

"Auto
amenu &Verilog.AutoInst.AutoInst(1)<TAB>All                             :call AutoInst(1)<CR>
amenu &Verilog.AutoInst.AutoInst(0)<TAB>One                             :call AutoInst(0)<CR>

amenu &Verilog.AutoPara.AutoPara(1)<TAB>All                             :call AutoPara(1)<CR>
amenu &Verilog.AutoPara.AutoPara(0)<TAB>One                             :call AutoPara(0)<CR>

"}}}3

"}}}2

"Keyboard 键盘快捷键{{{2

"Insert Time 插入时间{{{3
imap <F2> <C-R>=strftime("%x")<CR>
"}}}3

"Invert Wave 时序波形翻转{{{3
map <C-F8>      :call Invert()<ESC>
"}}}3

"Auto {{{3
map <S-F3>      :call AutoInst(0)<ESC>
map <S-F4>      :call AutoPara(0)<ESC>
"}}}3

"Code Snippet 代码段{{{3
"Add Always 添加always块
map ;al         :call AlBpp()<CR>i
"Add Header 添加文件头
map ;header     :call AddHeader()<CR> 
"Add Comment 添加注释
map ;//         :call AutoComment()<ESC>
map ;/*         <ESC>:call AutoComment2()<ESC>
map ;/$         :call AddCurLineComment()<ESC>
"}}}3

"}}}2

"}}}1

"Function 功能函数{{{1

"TimingWave 时序波形{{{2

function AddClk() "{{{3
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
"}}}3

function AddSig() "{{{3
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
endfunction "}}}3

function AddBus() "{{{3
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
endfunction "}}}3

function AddNeg() "{{{3
    let lnum = s:GetSigNameLineNum()
    if lnum == -1
        return
    endif
    let line = getline(lnum)
    if line =~ 'neg\s*$'
        return
    endif
    call setline(lnum,line." neg")
endfunction "}}}3

function AddBlk() "{{{3
    let ret = []
    let ret0 = "//          "
    let ret0 = ret0 . repeat(' ',s:clk_num*s:clk_period+1)
    call add(ret,ret0)
    let lnum = line(".")
    let col = col(".")
    call append(line("."),ret)
    call cursor(lnum+1,col)
endfunction "}}}3

function Invert() "{{{3
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

    "from 0 to posedge+cq_trans-1{{{4
    let res_top = strpart(top,0,posedge+s:cq_trans-1)
    let res_mid = strpart(mid,0,posedge+s:cq_trans-1)
    let res_bot = strpart(bot,0,posedge+s:cq_trans-1)
    "}}}4

    "from posedge+cq_trans to (posedge+clk_period)(i.e.next_posedge)+cq_trans-1{{{4
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
    "}}}4

    "from posedge+clk_period+cq_trans to max{{{4
    let res_top = res_top .strpart(top,posedge+s:cq_trans+s:clk_period-is_bus,s:wave_max_wd-1)
    let res_mid = res_mid .strpart(mid,posedge+s:cq_trans+s:clk_period-is_bus,s:wave_max_wd-1)
    let res_bot = res_bot .strpart(bot,posedge+s:cq_trans+s:clk_period-is_bus,s:wave_max_wd-1)
    "}}}4

    call setline(lnum-1,res_top)
    call setline(lnum,res_mid)
    call setline(lnum+1,res_bot)

endfunction 
"}}}3

"Sub-Funciton-For-Invert(){{{3

function s:GetSigNameLineNum() "{{{4
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
endfunction "}}}4

function s:GetPosedge(signeg) "{{{4
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
endfunction "}}}4

function s:SigLastClkIsHigh(lnum,posedge,negedge) "{{{4
    let ret = 0
    let line = getline(a:lnum - 1)
    if line[a:posedge-1] =~ '-'
        let ret = 1
    endif
    return ret
endfunction "}}}4

function s:SigCurClkIsHigh(lnum,posedge,negedge) "{{{4
    let ret = 0
    let line = getline(a:lnum - 1)
    if line[a:negedge-1] =~ '-'
        let ret = 1
    endif
    return ret
endfunction "}}}4

function s:SigNextClkIsHigh(lnum,posedge,negedge) "{{{4
    let ret = 0
    let line = getline(a:lnum - 1)
    if line[a:negedge+s:clk_period-1] =~ '-'
        let ret = 1
    endif
    return ret
endfunction "}}}4

function s:BusCurClkHaveChg(lnum,posedge,negedge) "{{{4
    let ret = 0
    let line = getline(a:lnum)
    if line[a:posedge+s:cq_trans-1] =~ 'X'
        let ret = 1
    endif
    return ret
endfunction "}}}4

function s:SigIsNeg() "{{{4
    let ret = 0
    let lnum = s:GetSigNameLineNum()
    if getline(lnum) =~ 'neg\s*$'
        let ret = 1
    endif
    return ret
endfunction "}}}4

"}}}3

"}}}2

"AutoTemplate 快速新建.v文件{{{2

autocmd BufNewFile *.v call AutoTemplate()

function AutoTemplate() "{{{3
    let filename = expand("%")
    let modulename = matchstr(filename,'\w\+')
    call AddHeader()
    call append(22, "`timescale 1ns/1ps")
    call append(23, "")
    call append(24, "module " . modulename  )
    call append(25, "(")
    call append(26, "clk")
    call append(27, "rst")
    call append(28, ");")
    call append(29, "")
    call append(30, "endmodule")
endfunction "}}}3

"}}}2

"Update Last Modify Time 更新写入时间{{{2

autocmd BufWrite *.v call UpdateLastModifyTime()

function UpdateLastModifyTime() "{{{3
    let line = getline(8)
    if line =~ '// Last Modified'
        call setline(8,"// Last Modified : " . strftime("%Y/%m/%d %H:%M"))
    endif
endfunction "}}}3

"}}}2

"Code Snippet 代码段{{{2

function AddHeader() "{{{3
    let line = getline(1)
    if line =~ '// +FHDR'               "已有文件头的文件不再添加
        return
    endif
    
    let author = g:vimrc_author
    let company = g:vimrc_company
    let project = g:vimrc_prject
    let device = g:vimrc_device
    let email = g:vimrc_email
    let website = g:vimrc_website

    let filename = expand("%")          "记录当前文件名
    let timelen = strlen(strftime("%x"))
    let authorlen = strlen(author)

    call append(0 , "// +FHDR----------------------------------------------------------------------------")
    call append(1 , "// Project Name  : ".project)
    call append(2 , "// Device        : ".device)
    call append(3 , "// Author        : ".author)
    call append(4 , "// Email         : ".email)
    call append(5 , "// Website       : ".website)
    call append(6 , "// Create On     : ".strftime("%Y/%m/%d %H:%M"))
    call append(7 , "// Last Modified : ".strftime("%Y/%m/%d %H:%M"))
    call append(8 , "// File Name     : ".filename)
    call append(9 , "// Description   :")
    call append(10, "//         ")
    call append(11, "// ")
    call append(12, "// Copyright (c) ".strftime("%Y ") . company . ".")
    call append(13, "// ALL RIGHTS RESERVED")
    call append(14, "// ")
    call append(15, "// ---------------------------------------------------------------------------------")
    call append(16, "// Modification History:")
    call append(17, "// Date         By              Version                 Change Description")
    call append(18, "// ---------------------------------------------------------------------------------")
    call append(19, "// ".strftime("%x").repeat(" ", 13-timelen).author.repeat(" ", 16-authorlen)."1.0                     Original")
    call append(20, "// ")
    call append(21, "// -FHDR----------------------------------------------------------------------------")
    call cursor(11,10)

endfunction "}}}3

function AlBpp() "{{{3
    let lnum = line(".")
    for idx in range(1,8)
        call append(lnum,"")
    endfor
    call setline(lnum+1,"    always@(posedge clk or posedge rst)")
    call setline(lnum+2,"    begin")
    call setline(lnum+3,"        if(rst)begin")
    call setline(lnum+4,"             ")
    call setline(lnum+5,"        end")
    call setline(lnum+6,"        else begin")
    call setline(lnum+7,"             ")
    call setline(lnum+8,"        end")
    call setline(lnum+9,"    end")
    call cursor(lnum+4,13)
endfunction "}}}3

function AlBpn() "{{{3
    let lnum = line(".")
    for idx in range(1,11)
        call append(lnum,"")
    endfor
    call setline(lnum+1 ,"    always@(posedge clk or negedge rst_n)")
    call setline(lnum+2 ,"    begin")
    call setline(lnum+3 ,"        if(!rst_n)begin")
    call setline(lnum+4 ,"            ")
    call setline(lnum+5 ,"        end ")
    call setline(lnum+6 ,"        else if()begin")
    call setline(lnum+7 ,"            ")
    call setline(lnum+8 ,"        end") 
    call setline(lnum+9 ,"        else begin")
    call setline(lnum+10,"            ")
    call setline(lnum+11,"        end")
    call setline(lnum+12,"    end")
    call cursor(lnum+3,13)
endfunction "}}}3

function AlB() "{{{3
    let lnum = line(".")
    for idx in range(1,3)
        call append(lnum,"")
    endfor
    call setline(lnum+1 ,"    always@(*)")
    call setline(lnum+2 ,"    begin")
    call setline(lnum+3 ,"        ")
    call setline(lnum+4 ,"    end")
    call cursor(lnum+2,9)
endfunction "}}}3

function AlBnn() "{{{3
    let lnum = line(".")
    for idx in range(1,11)
        call append(lnum,"")
    endfor
    call setline(lnum+1 ,"    always@(negedge clk or negedge rst_n)")
    call setline(lnum+2 ,"    begin")
    call setline(lnum+3 ,"        if(!rst_n) begin")
    call setline(lnum+4 ,"            ")
    call setline(lnum+5 ,"        end")
    call setline(lnum+6 ,"        else if()begin")
    call setline(lnum+7 ,"            ")
    call setline(lnum+8 ,"        end")
    call setline(lnum+9 ,"        else begin")
    call setline(lnum+10,"            ")
    call setline(lnum+11,"        end")
    call setline(lnum+12,"    end")
    call cursor(lnum+3,13)
endfunction "}}}3

function AlBp() "{{{3
    let lnum = line(".")
    for idx in range(1,8)
        call append(lnum,"")
    endfor
    call setline(lnum+1,"    always@(posedge clk)")
    call setline(lnum+2,"    begin")
    call setline(lnum+3,"        if()begin")
    call setline(lnum+4,"            ")
    call setline(lnum+5,"        end")
    call setline(lnum+6,"        else begin")
    call setline(lnum+7,"            ")
    call setline(lnum+8,"        end")
    call setline(lnum+9,"    end")
    call cursor(lnum+3,13)
endfunction "}}}3

function AlBn() "{{{3
    let lnum = line(".")
    for idx in range(1,8)
        call append(lnum,"")
    endfor
    call setline(lnum+1,"    always@(negedge clk)")
    call setline(lnum+2,"    begin")
    call setline(lnum+3,"        if()begin")
    call setline(lnum+4,"            ")
    call setline(lnum+5,"        end")
    call setline(lnum+6,"        else begin")
    call setline(lnum+7,"            ")
    call setline(lnum+8,"        end")
    call setline(lnum+9,"    end")
    call cursor(lnum+3,13)
endfunction "}}}3

function AutoComment() "{{{3
    let lnum = line(".")
    let line = getline(lnum)

    if line =~ '^\/\/ by .* \d\d\d\d-\d\d-\d\d'
        let tmp_line = substitute(line,'^\/\/ by .* \d\d\d\d-\d\d-\d\d | ','','')
    else
        let tmp_line = '// by ' . g:vimrc_author . ' ' . strftime("%Y-%m-%d") . ' | ' . line
    endif
    call setline(lnum,tmp_line)
endfunction "}}}3

function AutoComment2() "{{{3
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
            call append(line("'<")-1,'/*----------------  by '.g:vimrc_author.' '.strftime("%Y-%m-%d").'  ---------------------')
            call append(line("'>")  ,'------------------  by '.g:vimrc_author.' '.strftime("%Y-%m-%d").'  -------------------*/')
            let lnum = line(".")
        endif
    endif

    call cursor(lnum,col)

endfunction "}}}3

function AddCurLineComment() "{{{3
    let lnum = line(".")
    let line = getline(lnum)
    let tmp_line = line . ' // ' . g:vimrc_author . ' ' . strftime("%Y-%m-%d") . ' |'
    call setline(lnum,tmp_line)
    normal $
endfunction "}}}3

"}}}2

"Input2Output definition 转换input/output{{{2

function Input2Output() "{{{3
    let lnum = line(".")
    let line = getline(lnum)
    if line =~ '^\s*\/\/' || line =~ '^\s*$'
        return 0
    endif

    if line =~ '\<input\>\s\?'
        let line = substitute(line,'\<input\>\s\?','output','')
    elseif line =~ '\<output\>'
        let line = substitute(line,'\<output\>','input ','')
    endif

    call setline(lnum,line)
endfunction "}}}3

"}}}2

"}}}1

"Automatic 自动化功能{{{1

"Main Function 自动化主函数{{{2

"AutoInst 自动例化{{{3
"--------------------------------------------------
" Function: AutoInst
" Input: 
"   mode : mode for autoinst
" Description:
"   mode = 1, autoinst all instance
"   mode = 0, autoinst only one instance
" Output:
"   Formatted autoinst code
" Note:
"   list of port sequences
"            0     1        2       3       4       5            6          7
"   value = [type, sequence,io_dir, width1, width2, signal_name, last_port, line ]
"   io_seqs = {seq : value }
"   io_names = {signal_name : value }
"---------------------------------------------------
function AutoInst(mode)
    try
        "Get directory list by scaning line
        let [dirlist,rec] = s:GetDirList()
    endtry

    try
        "Get file-dir dictionary & module-file dictionary ahead of all process
        let files = s:GetFileDirDicFromList(dirlist,rec)
        let modules = s:GetModuleFileDict(files)
    endtry

    "record current position
    let orig_idx = line('.')
    let orig_col = col('.')

    "AutoInst all start from top line, AutoInst once start from first /*autoinst*/ line
    if a:mode == 1
        call cursor(1,1)
    elseif a:mode == 0
        call cursor(line('.'),1)
    else
        echohl ErrorMsg | echo "Error input for AutoInst(),input mode = ".a:mode| echohl None
        return
    endif

    while 1
        "put cursor to /*autoinst*/ line
        if search('\/\*autoinst\*\/','W') == 0
            break
        endif

        try
            "get module_name & inst_name
            let [module_name,inst_name,idx1,idx2] = s:GetInstModuleName()
            if module_name == '' || inst_name == ''
                echohl ErrorMsg | echo "Cannot find module_name or inst_name from line ".line('.') | echohl None
                return
            endif
        endtry

        try
            "get inst io list
            let keep_io_list = s:GetInstIO(getline(idx1,line('.')))
            let upd_io_list = s:GetInstIO(getline(line('.'),idx2))
        endtry

        try
            "get io sequences {seq : value}
            if has_key(modules,module_name)
                let file = modules[module_name]
                let dir = files[file]
                "read file
                let lines = readfile(dir.'/'.file)
                "io sequences
                let io_seqs = s:GetIO(lines,'seq')
                let io_names = s:GetIO(lines,'name')
            else
                echohl ErrorMsg | echo "file: ".module_name.".v does not exist in cur dir ".getcwd() | echohl None
                return
            endif
        endtry

        "remove io from io_seqs that want to be keep when autoinst
        "   value = [type, sequence, io_dir, width1, width2, signal_name, last_port, line ]
        "   io_seqs = {seq : value }
        "   io_names = {signal_name : value }
        for name in keep_io_list
            if has_key(io_names,name)
                let value = io_names[name]
                let seq = value[1]
                call remove(io_seqs,seq)
            endif
        endfor

        "note: current position must be at /*autoinst*/ line
        try
            "kill all contents under /*autoinst*/
            call s:KillAutoInst()
        endtry

        "draw io port, use io_seqs to cover update io list
        "if io_seqs has new signal_name that's never in upd_io_list, add //INST_NEW
        "if io_seqs has same signal_name that's in upd_io_list, cover
        "if io_seqs doesn't have signal_name that's in upd_io_list, add //INST_DEL
        "config: [1,     1,       1       ] default
        "        [IO_DIR,INST_NEW,INST_DEL]
        "        0 for close, 1 for open
        let config = [s:IO_DIR,s:INST_NEW,s:INST_DEL]
        let lines = s:DrawIO(io_seqs,upd_io_list,config)
        "delete current line );
        let line = substitute(getline(line('.')),')\s*;','','')
        call setline(line('.'),line)
        "append io port and );
        call add(lines,s:start_prefix.');')
        call append(line('.'),lines)

        "mode = 0, only autoinst once
        if a:mode == 0
            break
        endif

    endwhile

    "put cursor back to original position
    call cursor(orig_idx,orig_col)

endfunction
"}}}3

"AutoPara 自动参数{{{3
"--------------------------------------------------
" Function: AutoPara
" Input: 
"   mode : mode for autoinstparam
" Description:
"   mode = 1, autoinstparam all parameter
"   mode = 0, autoinstparam only one parameter
" Output:
"   Formatted autoinstparam code
" Note:
"   list of parameter sequences
"    0     1         2               3                4
"   [type, sequence, parameter_name, parameter_value ,last_parameter]
"   para_seqs = {seq : value }
"   para_names = {parameter_name : value }
"---------------------------------------------------
function AutoPara(mode)

    try
        "Get directory list by scaning line
        let [dirlist,rec] = s:GetDirList()
    endtry

    try
        "Get file-dir dictionary & module-file dictionary ahead of all process
        let files = s:GetFileDirDicFromList(dirlist,rec)
        let modules = s:GetModuleFileDict(files)
    endtry

    "record current position
    let orig_idx = line('.')
    let orig_col = col('.')

    "AutoPara all start from top line, AutoPara once start from first /*autoinstparam*/ line
    if a:mode == 1
        call cursor(1,1)
    elseif a:mode == 0
        call cursor(line('.'),1)
    else
        echohl ErrorMsg | echo "Error input for AutoPara(),input mode = ".a:mode| echohl None
        return
    endif

    while 1
        "put cursor to /*autoinstparam*/ line
        if search('\/\*autoinstparam\*\/','W') == 0
            break
        endif

        try
            "get module_name
            let [module_name,inst_name,idx1,idx2] = s:GetParaModuleName()

            if module_name == '' || inst_name == ''
                echohl ErrorMsg | echo "Cannot find module_name or inst_name from line ".line('.') | echohl None
                return
            endif
        endtry

        try
            "get inst parameter list
            let keep_para_list = s:GetInstPara(getline(idx1,line('.')))
            let upd_para_list = s:GetInstPara(getline(line('.'),idx2))
        endtry

        try
            "get para sequences {seq : value}
            if has_key(modules,module_name)
                let file = modules[module_name]
                let dir = files[file]
                "read file
                let lines = readfile(dir.'/'.file)
                "parameter sequences
                let para_seqs = s:GetPara(lines,'seq')
                let para_names = s:GetPara(lines,'name')
            else
                echohl ErrorMsg | echo "file: ".module_name.".v does not exist in cur dir ".getcwd() | echohl None
                return
            endif
        endtry

        "remove parameter from para_seqs that want to be keep when autoinstparam
        "   value = [type, sequence, parameter_name, parameter_value ,last_parameter]
        "   para_seqs = {seq : value }
        "   para_names = {parameter_name : value }
        for name in keep_para_list
            if has_key(para_names,name)
                let value = para_names[name]
                let seq = value[1]
                call remove(para_seqs,seq)
            endif
        endfor

        "note: current position must be at /*autoinstparam*/ line
        try
            "kill all contents under /*autoinstparam*/
            call s:KillAutoPara(inst_name)
        endtry

        "draw parameter, use para_seqs to cover update parameter list
        "if para_seqs has new parameter_name that's never in upd_para_list, add //PARA_NEW
        "if para_seqs has same parameter_name that's in upd_para_list, cover
        "if para_seqs doesn't have parameter_name that's in upd_para_list, add //PARA_DEL
        "config: [1,     1,       1       ] default
        "        [ONLY_PORT,PARA_NEW,PARA_DEL]
        "        0 for close, 1 for open
        let config = [s:ONLY_PORT,s:PARA_NEW,s:PARA_DEL]
        let lines = s:DrawPara(para_seqs,upd_para_list,config)

        "delete current line )
        let line = substitute(getline(line('.')),')\s*','','')
        call setline(line('.'),line)
        "append parameter and )
        call add(lines,s:start_prefix.')')
        call append(line('.'),lines)

        "mode = 0, only autoinst once
        if a:mode == 0
            break
        endif

    endwhile

    "put cursor back to original position
    call cursor(orig_idx,orig_col)

endfunction

"}}}3

"}}}2

"Sub Function 辅助函数{{{2

"-------------------------------------------------------------------
"                             AutoInst
"-------------------------------------------------------------------
"AutoInst-Get
"GetIO 获取输入输出端口{{{3
"--------------------------------------------------
" Function: GetIO
" Input: 
"   lines : all lines to get IO port
"   mode : different use of keys
"          seq -> use seq as key
"          name -> use signal_name as key
" Description:
"   Get io port info from declaration
"   e.g
"   module_name #(
"       parameter A = 16 
"       parameter B = 4'd11
"       parameter C = 16'h55
"   )
"   (
"       input       clk,
"       input       rst,
"       input       port_a,
"       output reg  port_b_valid,
"       output reg [31:0] port_b
"   );
"   e.g io port sequences
"   [type, sequence, io_dir, width1, width2, signal_name, last_port, line ]
"   [wire,1,input,'c0','c0',clk,0,'       input       clk,']
"   [reg,5,output,31,0,port_b,0,'    output reg [31:0] port_b']
" Output:
"   list of port sequences(including comment lines)
"    0     1         2       3       4       5            6          7
"   [type, sequence, io_dir, width1, width2, signal_name, last_port, line ]
"---------------------------------------------------
function s:GetIO(lines,mode)
    let idx = 0
    let seq = 0
    let wait_module = 1
    let wait_port = 1
    let io_seqs = {}
    while idx < len(a:lines)
        let idx = idx + 1
        let idx = s:SkipCommentLine(2,idx,a:lines)  "skip pair comment line
        if idx == -1
            echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
        endif
        let line = a:lines[idx-1]

        "find module first
        if line =~ '^\s*module'
            let wait_module = 0
        endif

        "until module,skip
        if wait_module == 1
            continue
        endif

        "no port definition, never record io_seqs
        if wait_port == 1 && line =~ ')\s*;' && len(io_seqs) > 0
            let seq = 0
            let io_seqs = {}
        endif

        if wait_module == 0
            "null line
            if line =~ '^\s*$'
                "if two adjacent lines are both null lines, delete last line
                if has_key(io_seqs,seq)
                    let value = io_seqs[seq]
                    if value[0] == 'keep' && value[7] =~ '^\s*$' && line =~ '^\s*$'
                        let idx = idx + 1
                        continue
                    endif
                endif
                "record first null line
                "           [type,  sequence, io_dir, width1, width2, signal_name, last_port, line ]
                let value = ['keep',seq,     '',     'c0',   'c0',   'NULL',          0,         '']
                call extend(io_seqs, {seq : value})
                let seq = seq + 1
            " `ifdef `ifndef & single comment line
            elseif line =~ '^\s*\`\(if\|else\|endif\)' || (line =~ '^\s*\/\/' && line !~ '^\s*\/\/\s*{{{')
                "           [type,  sequence, io_dir, width1, width2, signal_name, last_port, line ]
                let value = ['keep',seq,     '',     'c0',   'c0',   line,        0,         line]
                call extend(io_seqs, {seq : value})
                let seq = seq + 1
            "}}}
            " input/output ports
            elseif line =~ '^\s*'. s:VlogTypePorts
                let wait_port = 0
                "delete abnormal
                if line =~ '\<signed\>\|\<unsigned\>'
                    let line = substitute(line,'\<signed\>\|\<unsigned\>','','')
                endif

                "type reg/wire
                let type = 'none'
                if line =~ '\<reg\>'
                    let type = 'reg'
                elseif line =~ '\<wire\>'
                    let type = 'wire'
                endif

                "io direction input/output/inout
                let io_dir = matchstr(line,s:VlogTypePorts)

                "width
                let width = matchstr(line,'\[.*\]')                 
                let width = substitute(width,'\s*','','g')          "delete redundant space
                let width1 = matchstr(width,'\v\[\zs\S+\ze:.*\]')   
                let width2 = matchstr(width,'\v\[.*:\zs\S+\ze\]')   

                if width1 == ''
                    let width1 = 'c0'
                endif
                if width2 == ''
                    let width2 = 'c0'
                endif

                "name
                let line = substitute(line,io_dir,'','')
                let line = substitute(line,type,'','')
                let line = substitute(line,'\[.*:.*\]','','')
                let name = matchstr(line,'\w\+')
                if name == ''
                    let name = 'NULL'
                endif

                "           [type,sequence,io_dir, width1, width2, signal_name, last_port, line ]
                let value = [type,seq,     io_dir, width1, width2, name,        0,         '']
                call extend(io_seqs, {seq : value})
                let seq = seq + 1
            else
            endif

            "abnormal break
            if line =~ '^\s*\<always\>' || line =~ '^\s*\<assign\>' || line =~ '^\s*\<endmodule\>' || line =~ '\<autodef\>'
                break
            endif

        endif
    endwhile

    "find last_port
    let seq = len(io_seqs)
    while seq >= 0
        let seq = seq - 1
        if has_key(io_seqs,seq)
            let value = io_seqs[seq]
            let type = value[0]
            if type !~ 'keep'
                let value[7] = 1
                call extend(io_seqs,{seq : value})
                break
            end
        endif
    endwhile

    "remove last useless line
    let seq = len(io_seqs)
    while seq >= 0
        let seq = seq - 1
        if has_key(io_seqs,seq)
            let value = io_seqs[seq]
            let type = value[0]
            let line = value[7]
            if type !~ 'keep' || line !~ '^\s*$'
                break
            else
                call remove(io_seqs,seq)
            end
        endif
    endwhile

    "remove first useless line
    let seq = 0
    while seq <= len(io_seqs)
        let seq = seq + 1
        if has_key(io_seqs,seq)
            let value = io_seqs[seq]
            let type = value[0]
            let line = value[7]
            if type !~ 'keep' || line !~ '^\s*$'
                break
            else
                call remove(io_seqs,seq)
            end
        endif
    endwhile

    if a:mode == 'seq'
        return io_seqs
    elseif a:mode == 'name'
        let io_names = {}
        for seq in keys(io_seqs)
            let value = io_seqs[seq]
            let name = value[5]
            if name !~ 'keep'
                call extend(io_names,{name : value})
            endif
        endfor
        return io_names
    else
        echohl ErrorMsg | echo "Error mode input for function GetIO! mode = ".a:mode| echohl None
    endif

endfunction
"}}}3

"GetInstIO 获取例化端口{{{3
"--------------------------------------------------
" Function: GetInstIO
" Input: 
"   lines : lines to get inst IO port
" Description:
"   Get inst io port info from lines
"   e.g_1
"   module_name #(
"       .A_PARAMETER (A_PARAMETER)
"       .B_PARAMETER (B_PARAMETER)
"   )
"   inst_name
"   (
"       .clk(clk),
"       .rst(rst),
"       /*autoinst*/
"       .port_a(port_a),
"       .port_b_valid(port_b_valid),
"       .port_b(port_b)
"   );
"
"   e.g_2
"   (.clk(clk),
"    .rst(rst),
"    /*autoinst*/
"    .port_a(port_a),
"    .port_b_valid(port_b_valid),
"    .port_b(port_b)
"   );
"
" Output:
"   list of port sequences(according to input lines)
"   e.g_1
"   inst_io_list = ['clk','rst']
"   e.g_2
"   inst_io_list = ['port_a','port_b_valid','port_b']
"---------------------------------------------------
function s:GetInstIO(lines)
    let idx = 0
    let inst_io_list = []
    while idx < len(a:lines)
        let idx = idx + 1
        let idx = s:SkipCommentLine(2,idx,a:lines)  "skip pair comment line
        if idx == -1
            echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
        endif
        let line = a:lines[idx-1]
        if line =~ '\.\s*\w\+\s*(.*)'
            let port = matchstr(line,'\.\s*\zs\w\+\ze\s*(.*)')
            call add(inst_io_list,port)
        endif
    endwhile
    return inst_io_list
endfunction
"}}}3

"GetInstModuleName 获取例化名和模块名{{{3
"--------------------------------------------------
" Function: GetInstModuleName
" Input: 
"   Must put cursor to /*autoinst*/ position
" Description:
" e.g
"   module_name #(
"       .A_PARAMETER (A_PARAMETER)
"       .B_PARAMETER (B_PARAMETER)
"   )
"   inst_name
"   (
"       ......
"       /*autoinst*/
"       ......
"   );
" Output:
"   module_name and inst_name
"   idx1: line index of inst_name
"   idx2: line index of );
"---------------------------------------------------
function s:GetInstModuleName()
    "record original idx & col to cursor back to orginal place
    let orig_idx = line('.')
    let orig_col = col('.')

    "get module_name & inst_name by search function
    let idx = line('.')
    let inst_name = ''
    let module_name= ''
    let wait_simicolon_pair = 0
    let wait_module_name = 0

    while 1
        "skip function must have lines input
        let idx = s:SkipCommentLine(1,idx,getline(1,line('$')))
        if idx == -1
            echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
        endif
        "afer skip, still use current buffer
        let line = getline(idx)

        "abnormal break
        if wait_simicolon_pair == 1
            if idx == 0 || getline(idx) =~ '^\s*module' || getline(idx) =~ ');' || getline(idx) =~ '(.*)\s*;'
                echohl ErrorMsg | echo "Abnormal break when GetInstModuleName, idx = ".idx| echohl None
                let [module_name,inst_name,idx1,idx2] = ['','',0,0]
                break
            endif
        endif

        "get inst_name
        if line =~ '('
            let wait_simicolon_pair = 1
            "find position of '('
            let col = match(line,'(')
            call cursor(idx,col+1)
            "search for pair ()
            if searchpair('(','',')') > 0
                let index = line('.')
                let col = col('.')
            else
                echohl ErrorMsg | echo "() pair not-match in autoinst, line: ".index." colunm: ".col | echohl None
            endif
            "search for next none-blank character
            call search('\S')
            "if it is ';' then pair
            if getline('.')[col('.')-1] == ';'
                "place cursor back to where ')' pair
                call cursor(index,col)

                "record ); position
                let idx2 = line('.')

                call searchpair('(','',')','bW')
                "find position of inst_name
                call search('\w\+','b')
                "get inst_name
                let inst_name = expand('<cword>')

                "record inst_name position
                let idx1 = line('.')

                let wait_module_name = 1
            endif
        endif

        "get module_name
        if wait_module_name == 1
            "search for last none-blank character
            call search('\S','bW')
            "parameter exists
            if getline('.')[col('.')-1] == ')'
                if searchpair('(','',')','bW') > 0
                    let index = line('.')
                    let col = col('.')
                else
                    echohl ErrorMsg | echo "() pair not-match in parameter, line: ".index." colunm: ".col | echohl None
                endif
                call search('\w\+','bW')
            else
                call search('\w\+','bW')
            endif
            let module_name = expand('<cword>')
            break
        endif

        let idx = idx -1

    endwhile

    "cursor back
    call cursor(orig_idx,orig_col)

    return [module_name,inst_name,idx1,idx2]

endfunction
"}}}3

"AutoInst-Kill
"KillAutoInst 删除所有输入输出端口例化{{{3
"--------------------------------------------------
" Function: KillAutoInst
" Input: 
"   Must put cursor to /*autoinst*/ position
" Description:
" e.g kill all declaration after /*autoinst*/
"    
"   module_name
"   inst_name
"   (   
"       .clk        (clk),      //input
"       /*autoinst*/
"       .port_b     (port_b)    //output
"   );
"   
"   --------------> after KillAutoInst
"
"   module_name
"   inst_name
"   (   
"       .clk        (clk),      //input
"       /*autoinst*/);
"
" Output:
"   line after kill
"---------------------------------------------------
function s:KillAutoInst() 
    let orig_idx = line('.')
    let orig_col = col('.')
    let idx = line('.')
    let line = getline(idx)
    if line =~ '/\*\<autoinst\>'
        "if current line end with ');', one line
        if line =~');\s*$'
            return
        else
            "keep current line
            let line = substitute(line,'\*/.*$','\*/);','')
            call setline(idx,line)
            "if current line not end with ');', multi-line
            let idx = idx + 1
            while 1
                let line = getline(idx)
                "end of inst
                if line =~ ');\s*$'
                    "call deletebufline('%',idx)
                    execute ':'.idx.'d'
                    break
                "abnormal end
                elseif line =~ 'endmodule' || idx == line('$')
                    echohl ErrorMsg | echo "Error running KillAutoInst! Kill abnormally till the end!"| echohl None
                    break
                "middle
                else
                    "call deletebufline('%',idx)
                    execute ':'.idx.'d'
                endif
            endwhile
        endif
    else
        echohl ErrorMsg | echo "Error running KillAutoInst! Kill line not match /*autoinst*/ !"| echohl None
    endif
    "cursor back
    call cursor(orig_idx,orig_col)
endfunction
"}}}3

"AutoInst-Draw 
"DrawIO 按格式输出例化IO口{{{3
"--------------------------------------------------
" Function: DrawIO
" Input: 
"   io_seqs : new inst io sequences for align
"   io_list : old inst io name list
"   config: configuration for output
    "config: [1,     1,       1       ] default
    "        [io_dir,INST_NEW,INST_DEL]
    "        0 for close, 1 for open
" Description:
" e.g draw io port sequences
"   [wire,1,input,'c0','c0',clk,0,'       input       clk,']
"   [reg,5,output,31,0,port_b,0,'    output reg [31:0] port_b']
"   module_name
"   inst_name
"   (
"       .clk        (clk),      //input
"       .port_b     (port_b)    //output
"   );
"
" Output:
"   line that's aligned
"   e.g
"       .signal_name   (signal_name[width1:width2]      ), //io_dir
"---------------------------------------------------
function s:DrawIO(io_seqs,io_list,config)
    let prefix = s:start_prefix.repeat(' ',4)

    "guarantee spaces width
    let max_lbracket_len = 0
    let max_rbracket_len = 0
    for seq in sort(keys(a:io_seqs),'n')
        let value = a:io_seqs[seq]
        let type = value[0]
        if type != 'keep' 
            let name = value[5]
            if value[3] == 'c0' || value[4] == 'c0'
                let width = ''
            else
                let width = '['.value[3].':'.value[4].']'
            endif
            let max_lbracket_len = max([max_lbracket_len,len(prefix)+1+len(name)+4,s:name_pos_max])
            let max_rbracket_len = max([max_rbracket_len,max_lbracket_len+1+len(name)+len(width)+4,s:symbol_pos_max])
        endif
    endfor

    "Draw IO
    let lines = []
    let last_port_flag = 0
    let io_list = copy(a:io_list)
    let config = copy(a:config)
    for seq in sort(keys(a:io_seqs),'n')
        let value = a:io_seqs[seq]
        let type = value[0]
        let line = value[7]
        "add single line comment line
        if type == 'keep' 
            if line =~ '^\s*\/\/'
                let line = prefix.line
                call add(lines,line)
            endif
        else
            "Format IO sequences
            "   [type, sequence, io_dir, width1, width2, signal_name, last_port, line ]
            "name
            let name = value[5]
            "name2bracket
            let name2bracket = repeat(' ',max_lbracket_len-len(prefix)-len(name)-1)
            "width
            if value[3] == 'c0' || value[4] == 'c0'
                let width = ''
            else
                let width = '['.value[3].':'.value[4].']'
            endif
            "width2bracket
            let width2bracket = repeat(' ',max_rbracket_len-max_lbracket_len-1-len(name)-len(width))
            "comma
            let last_port = value[6]
            if last_port == 1
                let comma = ' '      "space
                let last_port_flag = 1  "special case: last port has been put in keep_io_list, there exist no last_port
            else
                let comma = ','      "comma exists
            endif
            "io_dir
            let io_dir = value[2]

            "Draw IO by Config
            "empty list, default
            if io_list == []
                if config[0] == 1
                    let line = prefix.'.'.name.name2bracket.'('.name.width.width2bracket.')'.comma.' //'.io_dir
                else
                    let line = prefix.'.'.name.name2bracket.'('.name.width.width2bracket.')'.comma
                endif
            "update list,draw io by config
            else
                if config[0] == 1
                    let line = prefix.'.'.name.name2bracket.'('.name.width.width2bracket.')'.comma.' //'.io_dir
                else
                    let line = prefix.'.'.name.name2bracket.'('.name.width.width2bracket.')'.comma
                endif
                "process //INST_NEW
                let io_idx = index(io_list,name) 
                "name not exist in old io_list, add //INST_NEW
                if io_idx == -1
                    if config[1] == 1
                        let line = line . ' // INST_NEW'
                    else
                        let line = line
                    endif
                "name already exist in old io_list,cover
                else
                    let line = line
                    call remove(io_list,io_idx)
                endif
            endif

            call add(lines,line)

        endif
    endfor

    "special case: last port has been put in keep_io_list, there exist no last_port
    if last_port_flag == 0
        "set last item as last_port
        let lines[-1] = substitute(lines[-1],',',' ','') 
    endif

    if io_list == []
    "remain port in io_list
    else
        if config[2] == 1
            for name in io_list
                let line = prefix.'//INST_DEL: Port '.name.' has been deleted.'
                call add(lines,line)
            endfor
        endif
    endif

    return lines

endfunction
"}}}3

"-------------------------------------------------------------------
"                             AutoPara
"-------------------------------------------------------------------
"AutoPara-Get
"GetPara 获取参数列表{{{3
"--------------------------------------------------
" Function: GetPara
" Input: 
"   lines : all lines to get parameter
"   mode : different use of keys
"          seq -> use seq as key
"          name -> use signal_name as key
" Description:
"   Get parameter info from declaration
"   e.g
"   module_name #(
"       parameter A = 16,
"       parameter B = 4'd11,
"       parameter C = 16'h55
"   )
"   inst_name
"   (
"       input       clk,
"       input       rst,
"       input       port_a,
"       output reg  port_b_valid,
"       output reg [31:0] port_b
"   );
"   parameter D = 10_0000;
"   parameter E = 'HEAD';
"
"   e.g parameter sequences
"   [type, sequence, parameter_name, parameter_value ,last_parameter]
"   [port,1,'A', '16',0]
"   [port,2,'B', '4'd11',0]
"   [port,3,'C', '16'h55',1]
"   [decl,4,'D', '10_0000',0]
"   [decl,5,'E', ''HEAD'',0]
"
" Output:
"   list of parameter sequences
"    0     1         2               3                4
"   [type, sequence, parameter_name, parameter_value ,last_parameter]
"---------------------------------------------------
function s:GetPara(lines,mode)
    let idx = 0

    "wait for parameter 
    let wait_module = 1
    let wait_left_braket = 1
    let wait_port_para = 1
    let wait_right_braket = 1
    let wait_decl_para = 1

    "record port & declaration parameter
    let port_para_lines = []
    let decl_para_lines = []
    let port_para_list = []
    let decl_para_list = []

    let para_seqs = {}

    while idx < len(a:lines)
        let idx = idx + 1
        let idx = s:SkipCommentLine(0,idx,a:lines)  "skip all comment line
        if idx == -1
            echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
        endif
        let line = a:lines[idx-1]
        "delete comment line in the middle
        let line = substitute(line,'\/\/.*','','')

        "find module 
        if line =~ '^\s*module'
            let wait_module = 0
        endif

        "until module,skip 
        if wait_module == 1 
            continue
        endif

        "find #(
        if wait_module == 0 && line =~ '#\s*('
            let wait_left_braket = 0
        endif
        "find port parameter 
        if wait_left_braket == 0 && line =~ 'parameter'
            let wait_port_para = 0
        endif

        "record port parameter line
        if wait_port_para == 0 && wait_right_braket == 1 
            call add(port_para_lines,line)
        endif

        "find )
        if wait_port_para == 0 && line =~ ')'
            let wait_right_braket = 0
        endif

        "record normal parameter 
        if wait_right_braket == 0 && line =~ 'parameter'
            let wait_decl_para = 0
        endif

        "record normal parameter 
        if wait_decl_para == 0
            call add(decl_para_lines,line)
        endif

        "find ; wait for parameter again
        if wait_decl_para == 0 && line =~ ';'
            let wait_decl_para = 1
        endif

    endwhile

    "unify to use ',' as spliter 
    let port_para = substitute(join(port_para_lines),')',',','g')
    let decl_para = substitute(join(decl_para_lines),';',',','g')
   
    "find para_list
    call substitute(port_para,'\w\+\s*=\s*\S\+\ze\s*,','\=add(port_para_list,submatch(0))','g')
    call substitute(decl_para,'\w\+\s*=\s*\S\+\ze\s*,','\=add(decl_para_list,submatch(0))','g')

    "get para_seqs
    let seq = 0
    for para in port_para_list
        let seq = seq + 1
        let type = 'port'
        let p_name = matchstr(para,'\w\+\ze\s*=')
        let p_value = matchstr(para,'=\s*\zs\S\+')
        if para == port_para_list[-1]
            let last_para = 1
        else
            let last_para = 0
        endif
        "           [type, sequence, parameter_name, parameter_value ,last_parameter]
        let value = [type, seq     , p_name        , p_value         ,last_para]
        call extend(para_seqs, {seq : value})
    endfor

    for para in decl_para_list
        let seq = seq + 1
        let type = 'decl'
        let p_name = matchstr(para,'\w\+\ze\s*=')
        let p_value = matchstr(para,'=\s*\zs\S\+')
        "           [type, sequence, parameter_name, parameter_value ,last_parameter]
        let value = [type, seq     , p_name        , p_value         ,last_para]
        call extend(para_seqs, {seq : value})
    endfor

    if a:mode == 'seq'
        return para_seqs
    elseif a:mode == 'name'
        let para_names = {}
        for seq in keys(para_seqs)
            let value = para_seqs[seq]
            let p_name = value[2]
            call extend(para_names,{p_name : value})
        endfor
        return para_names
    else
        echohl ErrorMsg | echo "Error mode input for function GetPara! mode = ".a:mode| echohl None
    endif

endfunction
"}}}3

"GetInstPara 获取例化参数{{{3
"--------------------------------------------------
" Function: GetInstPara
" Input: 
"   lines : lines to get inst parameter
" Description:
"   Get inst parameter info from lines
"   e.g_1
"   module_name #(
"       .A_PARAMETER (A_PARAMETER),
"       .B_PARAMETER (B_PARAMETER)
"   )
"   inst_name
"   (
"       ......
"   );
"
"   e.g_2
"   module_name 
"   #(
"       .C_PARAMETER (C_PARAMETER), .D_PARAMETER (D_PARAMETER),
"       .E_PARAMETER (E_PARAMETER)
"       
"   )
"   inst_name
"   (......);
"
" Output:
"   list of parameter sequences(according to input lines)
"   e.g_1
"   inst_para_list = ['A_PARAMETER','B_PARAMETER']
"   e.g_2
"   inst_para_list = ['C_PARAMETER','D_PARAMETER','E_PARAMETER']
"---------------------------------------------------
function s:GetInstPara(lines)
    let idx = 0
    let inst_para_list = []
    while idx < len(a:lines)
        let idx = idx + 1
        let idx = s:SkipCommentLine(2,idx,a:lines)  "skip pair comment line
        if idx == -1
            echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
        endif
        let line = a:lines[idx-1]
        if line =~ '\.\s*\w\+\s*(.*)'
            call substitute(line,'\.\s*\zs\w\+\ze\s*(.*)','\=add(inst_para_list,submatch(0))','g')
        endif
    endwhile
    return inst_para_list
endfunction
"}}}3

"GetParaModuleName 获取参数位置和模块名{{{3
"--------------------------------------------------
" Function: GetParaModuleName
" Input: 
"   Must put cursor to /*autoinstparam*/ position
" Description:
" e.g
"   module_name #(
"       /*autoinstparam*/
"       .A_PARAMETER (A_PARAMETER)
"       .B_PARAMETER (B_PARAMETER)
"   )
"   inst_name
"   (
"       ......
"   );
" Output:
"   module_name
"   idx1: line index of module_name
"   idx2: line index of )
"---------------------------------------------------
function s:GetParaModuleName()
    "record original idx & col to cursor back to orginal place
    let orig_idx = line('.')
    let orig_col = col('.')

    "get module_name & inst_name by search function
    let idx = line('.')
    let module_name = ''
    let inst_name = ''
    let wait_simicolon_pair = 0

    while 1
        "skip function must have lines input
        let idx = s:SkipCommentLine(1,idx,getline(1,line('$')))
        if idx == -1
            echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
        endif
        "afer skip, still use current buffer
        let line = getline(idx)

        "abnormal break
        if wait_simicolon_pair == 1
            if idx == 0 || getline(idx) =~ '^\s*module' || getline(idx) =~ ');' || getline(idx) =~ '(.*)\s*;'
                echohl ErrorMsg | echo "Abnormal break when GetInstModuleName, idx = ".idx| echohl None
                let [module_name,inst_name,idx1,idx2] = ['','',0,0]
                break
            endif
        endif

        "get module_name
        if line =~ '#\s*('
            let wait_simicolon_pair = 1
            "find position of '#('
            let col = match(line,'#\s*\zs(')
            call cursor(idx,col+1)
            "search for pair ()
            if searchpair('(','',')') > 0
                let index = line('.')
                let col = col('.')
            else
                echohl ErrorMsg | echo "() pair not-match in autopara, line: ".index." colunm: ".col | echohl None
                return
            endif

            "record ) position
            let idx2 = line('.')
            "get inst_name
            call search('\w\+')
            let inst_name = expand('<cword>')

            "find position of module_name
            call cursor(index,col)
            call searchpair('(','',')','bW')
            call search('\w\+','b')

            "get module_name
            let module_name = expand('<cword>')

            "record module_name position
            let idx1 = line('.')
            
            break
        endif

        let idx = idx -1

    endwhile

    if wait_simicolon_pair == 0
        let [module_name,inst_name,idx1,idx2] = ['','',0,0]
        echohl ErrorMsg | echo "No parameter definition '#(' find here!"| echohl None
        return
    endif

    "cursor back
    call cursor(orig_idx,orig_col)

    return [module_name,inst_name,idx1,idx2]

endfunction
"}}}3

"AutoPara-Kill
"KillAutoPara 删除所有参数例化"{{{3
"--------------------------------------------------
" Function: KillAutoPara
" Input: 
"   inst_name
" Description:
" e.g kill all declaration after /*autoinstparam*/
"    
"   module_name #(
"       /*autoinstparam*/
"       .A      (16             ),
"       .B      (4'd11          ),
"       .C      (16'h55         ),
"       .D      (10_0000        ),
"       .E      ('HEAD'         )
"   )inst_name
"   
"   module_name #(
"       /*autoinstparam*/
"       .A      (16             ),
"       .B      (4'd11          ),
"       .C      (16'h55         ),
"       .D      (10_0000        ),
"       .E      ('HEAD'         ))inst_name
"
"   --------------> after KillAutoPara
"
"   module_name #(
"       /*autoinstparam*/)
"   inst_name
"
" Output:
"   line after kill
"   kill untill inst_name
"---------------------------------------------------
function s:KillAutoPara(inst_name) 
    let orig_idx = line('.')
    let orig_col = col('.')
    let idx = line('.')
    let line = getline(idx)
    if line =~ '/\*\<autoinstparam\>'
        "if current line end with ')', one line
        if line =~')\s*$'
            return
        else
            "keep current line
            let line = substitute(line,'\*/.*$','\*/)','')
            call setline(idx,line)
            "if current line not end with ')', multi-line
            let idx = idx + 1
            while 1
                let line = getline(idx)
                "end of inst
                if line =~ a:inst_name
                    let redundant = matchstr(line,'^\s*\zs.*\ze'.a:inst_name)
                    let line = substitute(line,redundant,'','')
                    call setline(idx,line)
                    break
                "abnormal end
                elseif line =~ 'endmodule' || idx == line('$')
                    echohl ErrorMsg | echo "Error running KillAutoInst! Kill abnormally till the end!"| echohl None
                    break
                "middle
                else
                    "call deletebufline('%',idx)
                    execute ':'.idx.'d'
                endif
            endwhile
        endif
    else
        echohl ErrorMsg | echo "Error running KillAutoPara! Kill line not match /*autoinstparam*/ !"| echohl None
    endif
    "cursor back
    call cursor(orig_idx,orig_col)
endfunction 
"}}}3

"AutoPara-Draw
"DrawPara 按格式输出例化parameter{{{3
"--------------------------------------------------
" Function: DrawPara
" Input: 
"   para_seqs : new inst para sequences for align
"   para_list : old inst para name list
"   config: configuration for output
    "config: [1,        1,       1       ] default
    "        [ONLY_PORT,PARA_NEW,PARA_DEL]
    "        0 for close, 1 for open
" Description:
" e.g draw parameter sequences
"   [type, sequence, parameter_name, parameter_value ,last_parameter]
"   [port,1,'A', '16',0]
"   [port,2,'B', '4'd11',0]
"   [port,3,'C', '16'h55',1]
"   [decl,4,'D', '10_0000',0]
"   [decl,5,'E', ''HEAD'',0]
"
"   module_name #(
"       /*autoinstparam*/
"       .A      (16             ),
"       .B      (4'd11          ),
"       .C      (16'h55         ),
"       .D      (10_0000        ),
"       .E      ('HEAD'         ),
"   )
"   inst_name
"   (
"       ...
"   );
"
" Output:
"   line that's aligned
"   e.g
"       .parameter_name   (parameter_value      ),
"       .parameter_name   (parameter_value      )  //last_parameter
"---------------------------------------------------
function s:DrawPara(para_seqs,para_list,config)
    let prefix = s:start_prefix.repeat(' ',4)

    "guarantee spaces width
    let max_lbracket_len = 0
    let max_rbracket_len = 0
    for seq in sort(keys(a:para_seqs),'n')
        let value = a:para_seqs[seq]
        let p_name = value[2]
        let p_value = value[3]
        let max_lbracket_len = max([max_lbracket_len,len(prefix)+1+len(p_name)+4,s:name_pos_max])
        let max_rbracket_len = max([max_rbracket_len,max_lbracket_len+1+len(p_value)+4,s:symbol_pos_max])
    endfor

    "Draw Para
    let lines = []
    let para_list = a:para_list
    let config = a:config

    "find last_seq for config[0] = 0
    if len(keys(a:para_seqs)) > 0
        let seq_list = keys(a:para_seqs)
        let last_seq = seq_list[-1]
    else
        echohl ErrorMsg | echo "Error para_seqs input for function DrawPara! para_seqs length = ".len(keys(a:para_seqs))| echohl None
        echohl ErrorMsg | echo "Possibly no parameter exist" | echohl None
    endif

    "para_list can be changed in function, therefore record if it's empty first
    if para_list == []
        let para_list_empty = 1
    else
        let para_list_empty = 0
    endif

    for seq in sort(keys(a:para_seqs),'n')
        let value = a:para_seqs[seq]
        "Format parameter sequences
        "   [type, sequence, parameter_name, parameter_value ,last_parameter]

        "p_value
        let p_value = value[3]
        "p_name
        let p_name = value[2]
        "name2bracket
        let name2bracket = repeat(' ',max_lbracket_len-len(prefix)-len(p_name)-1)
        "value2bracket
        let value2bracket = repeat(' ',max_rbracket_len-max_lbracket_len-1-len(p_value))

        "last_para
        "use all parameter
        if config[0] == 0
            if seq == last_seq
                let last_para = 1
            else
                let last_para = 0
            endif
        "use only port parameter
        else
            let last_para = value[4]
        endif

        "comma
        if last_para == 1
            let comma = ' '      "space
        else
            let comma = ','      "comma exists
        endif

        "type
        let type = value[0]

        "Draw para by Config
        "Only draw port or draw all
        if (config[0] == 1 && type == 'port') || (config[0] == 0)
            "empty list, default
            if para_list_empty == 1
                let line = prefix.'.'.p_name.name2bracket.'('.p_value.value2bracket.')'.comma
            "update list,draw para by config
            else
                let line = prefix.'.'.p_name.name2bracket.'('.p_value.value2bracket.')'.comma
                "process //INST_NEW
                let para_idx = index(para_list,p_name) 
                "name not exist in old para_list, add //INST_NEW
                if para_idx == -1
                    if config[1] == 1
                        let line = line . ' // PARA_NEW'
                    else
                        let line = line
                    endif
                "name already exist in old para_list,cover
                else
                    let line = line
                    call remove(para_list,para_idx)
                endif
            endif

            call add(lines,line)

        endif
    endfor

    if para_list == []
    "remain port in para_list
    else
        if config[2] == 1
            for p_name in para_list
                let line = prefix.'//PARA_DEL: Parameter '.p_name.' has been deleted.'
                call add(lines,line)
            endfor
        endif
    endif

    "special case: last parameter has been put in keep_para_list, there exist no last_parameter
    "set last item as last_port
    let lines[-1] = substitute(lines[-1],',',' ','') 

    if lines == []
        echohl ErrorMsg | echo "Error para_seqs input for function DrawPara! para_seqs has no parameter definition!" | echohl None
    endif

    return lines

endfunction
"}}}3

"-------------------------------------------------------------------
"                             AutoInstWire
"-------------------------------------------------------------------



"-------------------------------------------------------------------
"                             AutoReg
"-------------------------------------------------------------------
"AutoReg-Get
"GetReg 获取reg{{{3
"--------------------------------------------------
" Function: GetReg
" Input: 
"   lines : all lines to get reg
"   mode : different use of keys
"          seq -> use seq as key
"          name -> use signal_name as key
" Description:
"   Get reg info from declaration and always block
"   e.g_1
"   module_name
"   inst_name
"   (
"       input       clk,
"       input       rst,
"       input       port_a,
"       output reg  port_b_valid,
"       output reg [31:0] port_b
"   );
"
"   e.g_2 
"   always@(posedge clk or posedge rst)
"   begin
"       if(rst)begin
"           a <= 0;
"       end
"       else begin
"           a <= a + 1;
"       end
"   end
"
"   always@(*)
"   begin
"       if(rst)begin
"           b <= 0;
"       end
"       else begin
"           b <= 10'd9;
"       end
"   end
"
"   e.g reg sequences
"
" Output:
"
"---------------------------------------------------
function GetReg()
    "------------------------
    "read file
    let lines = readfile(expand('%'))
    "------------------------
    
    "io names
    let io_names = s:GetIO(lines,'name')

    "io reg names
    let ioreg_names = {}
    for name in keys(io_names)
        "   [type, sequence, io_dir, width1, width2, signal_name, last_port, line ]
        let value = io_names[name]
        let type = value[0]
        if type == 'reg'
            call extend(ioreg_names, {name: value})
        endif
    endfor

    "flip-flop reg names
    let freg_names = s:GetfReg(lines,'name')

    "combination logic reg names
    let creg_names = s:GetcReg(lines,'name')



    "let creg_seqs = s:GetcReg(lines,'seq')
    "for seq in sort(keys(creg_seqs),'N')
    "    let value = creg_seqs[seq]
    "    let name = value[4]
    "    let type = value[0]
    "    let seq = value[1]
    "    let width1 = value[2]
    "    let width2 = value[3]
    "    echo name.'  type: '.type.'  seq :'.seq.'  ['.width1.':'.width2.']'
    "endfor

endfunction
"}}}3

"GetfReg 获取非阻塞类型reg{{{3
"--------------------------------------------------
" Function: GetfReg
" Input: 
"   lines : all lines to get freg
"   mode : different use of keys
"          seq -> use seq as key
"          name -> use signal_name as key
" Description:
"   Get freg info from always block
"
"   e.g_2 
"   always@(posedge clk or posedge rst)
"   begin
"       if(rst)begin
"           a <= 0;
"       end
"       else begin
"           a <= a + 1;
"       end
"   end
"
"   always@(*)
"   begin
"       if(rst)begin
"           b <= 0;
"       end
"       else begin
"           b <= 10'd9;
"       end
"   end
"
"   e.g reg sequences
"   ['freg', sequence, width1, width2, signal_name, lines]
"
"   ['freg',seq,'c0','c0','a',['    a <= 0;','   a <= a + 1;']]
"   ['freg',seq,9,0,'b',['    b <= 0;','   b <= 10'd9;']]
"
" Output:
"   list of reg sequences
"    0       1         2       3       4            5 
"   ['freg', sequence, width1, width2, signal_name, lines]
"---------------------------------------------------
function s:GetfReg(lines,mode)
    let idx = 1
    let seq = 0
    let width_names = {}
    let reg_names = {}

    while idx < len(a:lines)
        "skip comment line
        let idx = s:SkipCommentLine(0,idx,a:lines)
        if idx == -1
            echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
        endif
        let line = a:lines[idx-1]
        "find flip-flop reg
        if line =~ '^\s*\<always\>\s*@\s*(\s*\<\(posedge\|negedge\)\>'
            let idx_inblock = idx + 1
            "find signals in block
            while 1
                "skip comment line
                let idx_inblock = s:SkipCommentLine(0,idx_inblock,a:lines)
                if idx_inblock == -1
                    echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
                endif
                let line = a:lines[idx_inblock-1]
                "meet another always block, assign statement or instance, break
                if line =~ '^\s*\<always\>' || line =~ '^\s*\<assign\>' || line =~ '^\s*\<endmodule\>' || line =~ '/\*\<autoinst\>\*/' || line =~ '\s*\.\w\+(.*)' || idx_inblock == len(a:lines)
                    break
                else
                    if line =~ '.*<=.*'
                        let seq = seq + 1
                        let left = matchstr(line,'\s*\zs.*\ze\s*<=')
                        let right = matchstr(line,'<=\s*\zs.*\ze\s*')

                        "get name first
                        let reg_name_list = s:GetSigName(left)

                        "width_names    
                        "    0     1            2      3               4            5                6             7
                        "   [seqs, signal_name, lines, left_width_nrs, left_widths, right_width_nrs, right_widths, right_signal_link]
                        
                        "sigle signal, find its signal width 
                        if len(reg_name_list) == 1
                            let reg_name = reg_name_list[0]
                            "find width from left side, e.g. reg_a[4:0] (same time initialize width_names)
                            let width_names = s:GetLeftWidth(left,seq,reg_name,line,width_names)

                            "find width from right side. e.g. 3'd5 reg_b[4:3]
                            let width_names = s:GetRightWidth(right,reg_name,width_names)

                        "multi signal concatenation, don't calculate signal width anymore. e.g. {reg_a,reg_b,reg_c[2:0]}
                        else
                            for reg_name in reg_name_list
                                let width_names = s:GetLeftWidth(reg_name,seq,reg_name,line,width_names)
                            endfor
                        endif

                    endif
                endif
                let idx_inblock = idx_inblock + 1
            endwhile
        endif
        let idx = idx + 1
    endwhile

    "GetSig
    if a:mode == 'name'
        let reg_names = s:GetSig('freg',width_names,'name')
        return reg_names
    elseif a:mode == 'seq'
        let reg_seqs = s:GetSig('freg',width_names,'seq')
        return reg_seqs
    else
        echohl ErrorMsg | echo "Error mode input for function GetfReg! mode = ".a:mode| echohl None
    endif

endfunction
"}}}3

"GetcReg 获取阻塞类型reg{{{3
"--------------------------------------------------
" Function: GetcReg
" Almost same logic as GetfReg
" Refer GetfReg for function Description
"---------------------------------------------------
function s:GetcReg(lines,mode)

    let idx = 1
    let seq = 0
    let width_names = {}
    let reg_names = {}

    while idx < len(a:lines)
        "skip comment line
        let idx = s:SkipCommentLine(0,idx,a:lines)
        if idx == -1
            echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
        endif
        let line = a:lines[idx-1]
        "ignore flip-flop reg
        if line =~ '^\s*\<always\>\s*@\s*(\s*\<\(posedge\|negedge\)\>'

        "find combination reg
        elseif line =~ '^\s*\<always\>'
            let idx_inblock = idx + 1
            "find signals in block
            while 1
                "skip comment line
                let idx_inblock = s:SkipCommentLine(0,idx_inblock,a:lines)
                if idx_inblock == -1
                    echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
                endif
                let line = a:lines[idx_inblock-1]
                "meet another always block, assign statement or instance, break
                if line =~ '^\s*\<always\>' || line =~ '^\s*\<assign\>' || line =~ '^\s*\<endmodule\>' || line =~ '/\*\<autoinst\>\*/' || line =~ '\s*\.\w\+(.*)' || idx_inblock == len(a:lines)
                    break
                else
                    if line =~ '.*=.*'
                        let seq = seq + 1
                        let left = matchstr(line,'\s*\zs.*\ze\s*=')
                        let right = matchstr(line,'=\s*\zs.*\ze\s*')

                        "get name first
                        let reg_name_list = s:GetSigName(left)

                        "width_names    
                        "    0     1            2      3               4            5                6             7
                        "   [seqs, signal_name, lines, left_width_nrs, left_widths, right_width_nrs, right_widths, right_signal_link]
                        
                        "sigle signal, find its signal width 
                        if len(reg_name_list) == 1
                            let reg_name = reg_name_list[0]
                            "find width from left side, e.g. reg_a[4:0] (same time initialize width_names)
                            let width_names = s:GetLeftWidth(left,seq,reg_name,line,width_names)

                            "find width from right side. e.g. 3'd5 reg_b[4:3]
                            let width_names = s:GetRightWidth(right,reg_name,width_names)

                        "multi signal concatenation, don't calculate signal width anymore. e.g. {reg_a,reg_b,reg_c[2:0]}
                        else
                            for reg_name in reg_name_list
                                let width_names = s:GetLeftWidth(reg_name,seq,reg_name,line,width_names)
                            endfor
                        endif

                    endif
                endif
                let idx_inblock = idx_inblock + 1
            endwhile
        endif
        let idx = idx + 1
    endwhile

    "GetSig
    let reg_names = s:GetSig('creg',width_names,'name')

    if a:mode == 'name'
        let reg_names = s:GetSig('creg',width_names,'name')
        return reg_names
    elseif a:mode == 'seq'
        let reg_seqs = s:GetSig('creg',width_names,'seq')
        return reg_seqs
    else
        echohl ErrorMsg | echo "Error mode input for function GetcReg! mode = ".a:mode| echohl None
    endif

endfunction
"}}}3

"-------------------------------------------------------------------
"                             AutoWire
"-------------------------------------------------------------------


"-------------------------------------------------------------------
"                             AutoDef
"-------------------------------------------------------------------


"-------------------------------------------------------------------
"                            Universal
"-------------------------------------------------------------------
"Universal-GetSigName
"{{{3 GetSigName 获取信号名称
"--------------------------------------------------
" Function: GetSigName
" Input: 
"   str : input string
" Description:
" e.g1
"   data[7:0]
"
" e.g2
"   {data1[7:0],data2[5:1],data3}
"
" Output:
"   list of names
"
" e.g1
"   [data]
"
" e.g2
"   [data1,data2,data3]
"---------------------------------------------------
function s:GetSigName(str)
    let name_list = []
    if a:str =~ '{.*}'
        let str = matchstr(a:str,'{\zs.*\ze}') 
        let str = substitute(str,'\s*','','g')        "delete redundant space
        let str_list = split(str,',')
        for str in str_list
            let name = matchstr(str,'\w\+')
            call add(name_list,name)
        endfor
    else
        let name_list = [matchstr(a:str,'\w\+')]
    endif
    return name_list
endfunction
"}}}3

"Universal-GetLeftWidth 
"GetLeftWidth 获取左半部分信号宽度{{{3
"--------------------------------------------------
" Function: GetLeftWidth
" Input:
"   left : left side of the sentence
"   seq : sequences of the signal
"   line : orginal line
"   width_names = {signal_name : value} 
" Description:
" e.g1
"   signal_a[3:0]
" e.g2
"   signal_a[WIDTH-1:0]
" e.g3
"   signal_a[2*3-1:0] signal_b[4/2-1:0]
" e.g4
"   signal_a[1]
"
"   seqs : record sequence list
"   lines : record orginal line list
"   left_width_nrs : record width list that's pure number
"   left_widths : record width list that's not a pure number, like WIDTH-1 or 2*3-1
"
" Output:
"   list of signal widths
"   value = 
"    0     1            2      3               4            5                6             7
"   [seqs, signal_name, lines, left_width_nrs, left_widths, right_width_nrs, right_widths, right_signal_link]
"---------------------------------------------------
function s:GetLeftWidth(left,seq,name,line,width_names)

    "    0     1            2      3               4
    "   [seqs, signal_name, lines, left_width_nrs, left_widths ......]

    "get value already exist in width_names
    if has_key(a:width_names,a:name)
        let old_value = a:width_names[a:name]
        let seqs = add(old_value[0],a:seq)
        let lines = add(old_value[2],a:line)
        let left_width_nrs = old_value[3]
        let left_widths = old_value[4]
        let right_width_nrs = old_value[5]
        let right_widths = old_value[6]
        let right_signal_link = old_value[7]
    else
        let seqs = [a:seq]
        let lines = [a:line]
        let left_width_nrs = []
        let left_widths = []
        let right_width_nrs = []
        let right_widths = []
        let right_signal_link = {}
    endif

    "get width
    "left have width
    if a:left =~ '\[.*\]'
        let width = matchstr(a:left,'\[.*\]')                 
        let width = substitute(width,'\s*','','g')          "delete redundant space
        "left have two width e.g. signal_t[2:0] signal_a[WIDTH-1:0]
        if width =~ '[.*:.*]'
            let width1 = matchstr(width,'\v\[\zs\S+\ze:.*\]')   
            let width2 = matchstr(width,'\v\[.*:\zs\S+\ze\]')
            "pure number width e.g. signal_a[3:0]
            if substitute(width1,'\d\+','','g') == '' && substitute(width2,'\d\+','','g') == ''
                call add(left_width_nrs,str2nr(width1))
                call add(left_width_nrs,str2nr(width2))
            "parameter type input width e.g. signal_a[WIDTH-1:0]
            "calculation type e.g. signal_a[2*3-1:0] signal_b[4/2-1:0]
            else
                call add(left_widths,[width1,width2])
            endif
        "left have one width of pure number e.g. [1]
        elseif width =~ '\[\d\]'
            call add(left_width_nrs,str2nr(matchstr(width,'\[\zs\d\ze\]')))
        "keep original  e.g. reg_a[cnt]
        else
            let width1 = matchstr('[\zs.*\ze]')
            let width2 = ''
            call add(left_widths,[width1,width2])
        endif
    "left don't have width e.g. signal_a, add nothing
    else

    endif

    "pair up width_names
            "    0     1            2      3               4
            "   [seqs, signal_name, lines, left_width_nrs, left_widths ......]
    let value = [seqs, a:name,      lines, left_width_nrs, left_widths, right_width_nrs, right_widths, right_signal_link]

    call extend(a:width_names,{a:name : value})

    return a:width_names

endfunction
"}}}3

"Universal-GetRightWidth
"GetRightWidth 获取右半部分信号宽度{{{3
"--------------------------------------------------
" Function: GetRightWidth
" Input:
"   right : right side of the sentence
"   width_names = {signal_name : value} 
" Description:
" e.g1                                  
"   16'hffff;                           --------> right_width_nrs
"   `WIDTH'hffff;                       --------> right_widths
" e.g2
"   signal_a[3];                        --------> right_width_nrs
" e.g3
"   signal_a[WIDTH-1:0];                --------> right_widths
" e.g4
"   signal_a[2*3-1:0];signal_b[4/2-1:0];--------> right_widths
" e.g5
"   signal_a[5:0];                      --------> right_width_nrs
" e.g6                                  
"   signal_a; or ~signal_a; or !signal_a; --------> right_signal_link
" e.g7                                  
"   {signal_a,signal_b,signal_c[2:0]};    --------> right_signal_link
" e.g8                                  
"   signal_a&signal_b&signal_c[2:0];      --------> right_signal_link
" e.g9                                  
"   en ? signal_b : signal_c[2:0];        --------> right_signal_link
"
"   right_width_nrs : record width list that's pure number
"   right_widths : record width list that's not a pure number, like WIDTH-1 or 2*3-1
"   right_signal_link : record width that's link to a signal or a few signals
"
" Output:
"   list of signal widths
"   value = 
"    0     1            2      3               4            5                6             7
"   [seqs, signal_name, lines, left_width_nrs, left_widths, right_width_nrs, right_widths, right_signal_link]
"---------------------------------------------------
function s:GetRightWidth(right,name,width_names)

    "    0     1                    5                6             7
    "   [seqs, signal_name, ......, right_width_nrs, right_widths, right_signal_link]

    "value already exist in width_names
    let old_value = a:width_names[a:name]
    let right_width_nrs = old_value[5]
    let right_widths = old_value[6]
    let right_signal_link = old_value[7]

    "get width
    let right = substitute(a:right,'\s*','','g')                    "delete redundant space
    let right = substitute(right,'#`\?\w\+\(\.\w\+\)\?','','')      "for delay like #0.1

    "match M'bN or M'hN or M'dN
    "M may be `define or parameter or number
    if right =~ '^\(`\?\w\+\|\d\+\)' . "'" . '[bhd].*'
        "pure number width e.g. 5'd0 -> signal_a[4:0]
        if right =~ '^\d\+' . "'" . '[bhd].*'
            let width = matchstr(right,'\d\+')   
            call add(right_width_nrs,str2nr(width)-1)
            call add(right_width_nrs,0)
        "parameter type input width e.g. WIDTH'hff -> signal_a[WIDTH-1:0]
        elseif right =~ '^`\?\w\+\' . "'" . '[bhd].*'
            let width = matchstr(right,'`\?\w\+')   
            call add(right_widths,[width.'-1','0'])
        endif

    "match signal[N], N is integer number
    elseif right =~ '^\~\?\w\+\[\d\+\];'
        call add(right_width_nrs,0)
        
    "match signal[M:N], M and N is integer number
    elseif right =~ '^\~\?\w\+\[.*:.*\];'
            let width1 = matchstr(right,'\v\[\zs\S+\ze:.*\]')   
            let width2 = matchstr(right,'\v\[.*:\zs\S+\ze\]')
            "pure number width e.g. signal_a[3:0]
            if substitute(width1,'\d\+','','g') == '' && substitute(width2,'\d\+','','g') == ''
                call add(right_width_nrs,str2nr(width1))
                call add(right_width_nrs,str2nr(width2))
            "parameter type input width e.g. signal_a[WIDTH-1:0]
            "calculation type e.g. signal_a[2*3-1:0] signal_b[4/2-1:0]
            else
                call add(right_widths,[width1,width2])
            endif

    "match signal0 == signal1
    elseif right =~ '^(\?\w\+==\w\+)\?;'
        call add(right_width_nrs,0)

    "match &signal0 |signal0 or ^signal0
    elseif right =~ '^[\^&|]\w\+;'
        call add(right_width_nrs,0)

    "match signal0 or ~signal0
    elseif right =~ '^\~\?\w\+;'
        "pure number, ignore
        if right =~ '^\~\?\d\+;'
        else
            let s0 = matchstr(right,'^\~\?\zs\w\+\ze;')
            call extend(right_signal_link,{s0 : ''})
        endif

    "match sel ? signal0 : signal1
    elseif right =~ '^\~\?\w\+?\w\+:\w\+;'
        let s0 = matchstr(right,'^\~\?\w\+?\zs\w\+\ze:\w\+;')
        let s1 = matchstr(right,'^\~\?\w\+?\w\+:\zs\w\+\ze;')
        call extend(right_signal_link,{s0 : ''})
        call extend(right_signal_link,{s1 : ''})

    "match {signal0,signal1[1:0],signal2......}
    elseif right =~ '^{.*}'
        while 1
            if right =~ '\w\+\[.*\]'
                let s0 = matchstr(right,'\w\+')
                let width = matchstr(right,'\[.*\]')
                let right = substitute(right,'\w\+\[.*\]','','')
            else
                let s0 = matchstr(right,'\w\+')
                let width = ''
                let right = substitute(right,'\w\+','','')
            endif

            if s0 == ''
                break
            else
                call extend(right_signal_link,{s0 : ['+',width]})
            endif
        endwhile

    "match signal0 & signal1 | signal2 ^ signal3
    elseif right =~ '^\~\?\w\+\([\&\|\^]\~\?\w\+\)\+;'
        while 1
            let s0 = matchstr(right,'\w\+')
            if s0 == ''
                break
            else
                let right = substitute(right,'\w\+','','')
                call extend(right_signal_link,{s0 : ''})
            endif
        endwhile
    else
    "can't recognize right side of 'd4

    endif

    "pair up width_names
    "    0     1                    5                6             7
    "   [seqs, signal_name, ......, right_width_nrs, right_widths, right_signal_link]
    let value = old_value
    let value[5] = right_width_nrs
    let value[6] = right_widths
    let value[7] = right_signal_link

    call extend(a:width_names,{a:name : value})

    return a:width_names

endfunction

"}}}3

"Universal-GetSig
"GetSig 获取信号列表{{{3
"--------------------------------------------------
" Function: GetSig
" Input:
"   type : signal type
"   list of signal widths
"   value = 
"    0     1            2      3               4            5                6             7
"   [seqs, signal_name, lines, left_width_nrs, left_widths, right_width_nrs, right_widths, right_signal_link]
"   mode : different use of keys
"          seq -> use seq as key
"          name -> use signal_name as key
" Description:
"   seqs : record sequence list
"   lines : record orginal line list
"   left_width_nrs : record left-width list that's pure number
"   left_widths : record left-width list that's not a pure number, like WIDTH-1 or 2*3-1
"   right_width_nrs : record right-width list that's pure number
"   right_widths : record right-width list that's not a pure number, like WIDTH-1 or 2*3-1
"   right_signal_link : record right-width that's link to a signal or a few signals
" Output:
"   list of signal sequences
"    0     1         2       3       4            5 
"   [type, sequence, width1, width2, signal_name, lines]
"---------------------------------------------------
function s:GetSig(type,width_names,mode)

    let sig_names = {}
    "left_width_nrs & left_widths & right_width_nrs & right_widths 
    "process and add width1 & width2
    for name in keys(a:width_names)
        let value = a:width_names[name]
        let seqs = value[0]
        let lines = value[2]
        let left_width_nrs = value[3]
        let left_widths = value[4]
        let right_width_nrs = value[5]
        let right_widths = value[6]
        let right_signal_link = value[7]

        "1. exist width that is not a number type, use first width declaration of this signal
        "e.g.
        "parameter type input width e.g. reg_a[WIDTH-1:0]
        "calculation type e.g. reg_a[2*3-1:0] reg_b[4/2-1:0]
        "2. only exist width that is a number type, use maximum & minimum number as width. 
        "e.g. 
        "reg_t[2:1] reg_t[0] -> width1 = 2, width2 = 0
        
        "first judge left width
        if left_widths != []
            let [width1,width2] = left_widths[0]
        elseif left_width_nrs != []
            let width1 = max(left_width_nrs)
            let width2 = min(left_width_nrs)
        elseif right_widths != []
            let [width1,width2] = right_widths[0]
        elseif right_width_nrs != []
            let width1 = max(right_width_nrs)
            let width2 = min(right_width_nrs)
        elseif right_signal_link != {}
            "--------------------------------signal link------------------------------
            let width1 = 'c0'
            let width2 = 'c0'
        else
            "no width
            let width1 = 'c0'
            let width2 = 'c0'
        endif

        "use first sequence as signal sequence
        "   [type, sequence, width1, width2, signal_name, line]
        let sig_value = [a:type,seqs[0],width1,width2,name,lines]
        call extend(sig_names,{name : sig_value})
    endfor

    if a:mode == 'name'
        return sig_names
    elseif a:mode == 'seq'
        let sig_seqs = {}
        for name in keys(sig_names)
            let value = sig_names[name]
            let seq = value[1]
            call extend(sig_seqs,{seq : value})
        endfor
        return sig_seqs
    else
        echohl ErrorMsg | echo "Error mode input for function GetSig! mode = ".a:mode| echohl None
    endif
    
endfunction
"}}}3

"Others
"{{{3 GetDirList 获取需要例化的文件夹名以及是否递归
"--------------------------------------------------
" Function: GetDirList
" Input: 
"   Lines look like: 
"   verilog-library-directories:()
"   verilog-library-directories-recursive:0
" Description:
" e.g
"   verilog-library-directories:("test" ".")
"   verilog-library-directories-recursive:1
" Output:
"   dirlist and recursive flag
"   e.g.
"       dirlist = ['test','.']
"       rec = 1
"---------------------------------------------------
function s:GetDirList()
    let dirlist = [] 
    let rec = 0
    let lines = getline(1,line('$'))
    for line in lines
        "find directories
        if line =~ 'verilog-library-directories:(.*)'
            let dir = matchstr(line,'verilog-library-directories:(\zs.*\ze)')
            call substitute(dir,'"\zs\S*\ze"','\=add(dirlist,submatch(0))','g')
        endif
        "find recursive
        if line =~ 'verilog-library-directories-recursive:'
            let rec = matchstr(line,'verilog-library-directories-recursive:\s*\zs\d\ze\s*$')
            if rec != '0' && rec != '1'
                echohl ErrorMsg | echo "Error input for verilog-library-directories-recursive = ".rec| echohl None
            endif
        endif
    endfor
    "default
    let dir = '.'       
    if dirlist == [] 
        let dirlist = [dir]
    endif

    return [dirlist,str2nr(rec)]

endfunction
"}}}3

"GetFileDirDict 获取文件名文件夹关系{{{3
"--------------------------------------------------
" Function : GetFileDirDicFromList
" Input: 
"   dirlist: directory list
"   rec: recursively
" Description:
"   get file-dir dictionary from dirlist
" Output:
"   files  : file-dir dictionary(.v file)
"          e.g  ALU.v -> ./hdl/core
"---------------------------------------------------
function s:GetFileDirDicFromList(dirlist,rec)
    let files = {}
    for dir in a:dirlist
        let files = s:GetFileDirDic(dir,a:rec,files)
    endfor
    return files
endfunction

"--------------------------------------------------
" Function: GetFileDirDic
" Input: 
"   dir : directory
"   rec : recursive
"   files : dictionary to store
" Description:
"   rec = 1, recursively get inst-file dictionary (.v or .sv file) 
"   rec = 0, normally get inst-file dictionary (.v or .sv file)
" Output:
"   files : files-directory dictionary(.v or .sv file)
"---------------------------------------------------
function s:GetFileDirDic(dir,rec,files)
    "let filelist = readdir(a:dir,{n -> n =~ '.v$\|.sv$'})
    let filedirlist = glob(a:dir.'/'.'*',0,1)
    let idx = 0
    while idx <len(filedirlist)
        let file = fnamemodify(filedirlist[idx],':t')
        let filedirlist[idx] = file
        let idx = idx + 1
    endwhile

    let filelist = filter(copy(filedirlist),'v:val =~ ".v$" || v:val =~ ".sv$"')

    for file in filelist
        if has_key(a:files,file)
            echohl ErrorMsg | echo "Same file ".file." exist in both ".a:dir." and ".a:files[file]."! Only use one as directory"| echohl None
        endif
        call extend (a:files,{file : a:dir})
    endfor

    if a:rec
        "for item in readdir(a:dir)
        for item in filedirlist
            if isdirectory(a:dir.'/'.item)
                call s:GetFileDirDic(a:dir.'/'.item,1,a:files)
            endif
        endfor
    endif
    return a:files

endfunction

"}}}3

"GetModuleFileDict 获取模块名和文件名关系{{{3
"--------------------------------------------------
" Function : GetModuleFileDict
" Input: 
"   files: file-dir dictionary
"          e.g  ALU.v -> ./hdl/core
" Description:
"   get module-file dictionary from file-dir dictionary
" Output:
"   modules: module-file dictionary
"          e.g  ALU -> ALU.v
"---------------------------------------------------
function s:GetModuleFileDict(files)
    let modules = {}
    for file in keys(a:files)
        let dir = a:files[file]
        "find module in ./hdl/core/ALU.v
        let lines = readfile(dir.'/'.file)  
        let module = ''
        for line in lines
            if line =~ '^\s*module\s*\w\+'
                let module = matchstr(line,'^\s*module\s*\zs\w\+')
                break
            endif
        endfor
        if module == ''
            call extend(modules,{'NULL' : file})
        else
            call extend(modules,{module : file})
        endif
    endfor
    return modules
endfunction
"}}}3

"SkipCommentLine 跳过注释行{{{3
"--------------------------------------------------
" Function: SkipCommentLine
" Input: 
"   mode : mode for search up/down
"          0 -> search down
"          1 -> search up
"          2 -> search down, but ignore //......
"          3 -> search up, but ignore //......
"   idx  : start line index of searching
"   lines: content of lines for searching 
" Description:
"   Skip comment line of 
"       1. //..........
"       2. /*......
"            ......
"            ......*/
"       3. ignore comment line of /*....*/
"          since it might be /*autoinst*/
" Output:
"   next line index that's not a comment line
"---------------------------------------------------
function s:SkipCommentLine(mode,idx,lines)
    let comment_pair = 0
    if a:mode == 0
        let start_pattern = '^\s*/\*'
        let start_symbol = '\*/'
        let end_pattern = '\*/\s*$'
        let end_symbol = '/\*'
        let single_pattern = '^\s*\/\/'
        let end = len(a:lines)
        let stride = 1
    elseif a:mode == 1
        let start_pattern = '\*/\s*$'
        let start_symbol = '/\*'
        let end_pattern = '^\s*/\*'
        let end_symbol = '\*/'
        let single_pattern = '^\s*\/\/'
        let end = 1
        let stride = -1
    elseif a:mode == 2
        let start_pattern = '^\s*/\*'
        let start_symbol = '\*/'
        let end_pattern = '\*/\s*$'
        let end_symbol = '/\*'
        let single_pattern = 'HonkW is always is most handsome man!'
        let end = len(a:lines)
        let stride = 1
    elseif a:mode == 3
        let start_pattern = '\*/\s*$'
        let start_symbol = '/\*'
        let end_pattern = '^\s*/\*'
        let end_symbol = '\*/'
        let single_pattern = 'HonkW is always is most handsome man!'
        let end = 1
        let stride = -1
    else
        echohl ErrorMsg | echo "Error mode input for function SkipCommentLine! mode = ".a:mode| echohl None
    endif

    for idx in range(a:idx,end,stride)
        let line = a:lines[idx-1]
        "/* symbol at top of the line
        if line =~ start_pattern  && line !~ start_symbol
            let comment_pair = 1
            continue
        "*/ symbol at end of the line
        elseif line =~ end_pattern && line !~ end_symbol
            let comment_pair = 0
            continue
        elseif comment_pair == 1        "comment pair /* ... */
            continue
        elseif line =~ single_pattern   "comment line //
            continue
        else                            "not comment, return
            return idx
        endif
    endfor

    return -1
endfunction
"}}}3

"}}}2

"}}}1

