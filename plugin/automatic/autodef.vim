"-----------------------------------------------------------------------------
" Vim Plugin for Verilog Code Automactic Generation 
" Author:         HonkW
" Website:        https://honk.wang
" Last Modified:  2022/09/18 17:29
" File:           autodef.vim
" Note:           AutoDef function partly from zhangguo's vimscript
"                 Progress bar based off code from "progressbar widget" plugin by
"                 Andreas Politz, slightly modified:
"                 http://www.vim.org/scripts/script.php?script_id=2006
"------------------------------------------------------------------------------

"Sanity checks 启动判断{{{1
if exists("g:loaded_automatic_verilog_autodef")
    finish
endif
let g:loaded_automatic_verilog_autodef = 1
"}}}1

"Defaults 默认配置{{{1

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
let s:VlogTypeData = s:VlogTypeData . '\<defparam\>\|'
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

"AutoDef/AutoWire/AutoReg Config 自动定义/线网/寄存器配置
"+-----------------+--------------------------------------------------------------+
"|     st_pos      |                        start position                        |
"+-----------------+--------------------------------------------------------------+
"|    name_pos     |                     signal name position                     |
"+-----------------+--------------------------------------------------------------+
"|     sym_pos     |                     symbol name position                     |
"+-----------------+--------------------------------------------------------------+
"|     reg_new     | add //REG_NEW if register has been newly added to the module |
"+-----------------+--------------------------------------------------------------+
"|     reg_del     |  add //REG_DEL if register has been deleted from the module  |
"+-----------------+--------------------------------------------------------------+
"|    wire_new     |  add //WIRE_NEW if wire has been newly added to the module   |
"+-----------------+--------------------------------------------------------------+
"|    wire_del     |   add //WIRE_DEL if wire has been deleted from the module    |
"+-----------------+--------------------------------------------------------------+
"| unresolved_flag |            add //unresolved if wire is unresolved            |
"+-----------------+--------------------------------------------------------------+
"|   reg_rmv_io    |               remove declared io from autoreg                |
"+-----------------+--------------------------------------------------------------+
"|   wire_rmv_io   |               remove declared io from autowire               |
"+-----------------+--------------------------------------------------------------+
"|       mv        |     move declared define(reg/wire) to down below autodef     |
"+-----------------+--------------------------------------------------------------+
"|   tail_nalign   |   don't do alignment in tail when autoreg/autowire/autodef   |
"+-----------------+--------------------------------------------------------------+
let g:_ATV_AUTODEF_DEFAULTS = {
            \'st_pos':          4,
            \'name_pos':        32,
            \'sym_pos':         64,
            \'reg_new':         1,
            \'reg_del':         1,
            \'wire_new':        1,
            \'wire_del':        1,
            \'unresolved_flag': 0,
            \'reg_rmv_io':      1,        
            \'wire_rmv_io':     1,
            \'mv':              0,        
            \'tail_nalign':     0    
            \}
for s:key in keys(g:_ATV_AUTODEF_DEFAULTS)
    if !exists('g:atv_autodef_' . s:key)
        let g:atv_autodef_{s:key} = copy(g:_ATV_AUTODEF_DEFAULTS[s:key])
    endif
endfor
let s:st_prefix = repeat(' ',g:atv_autodef_st_pos)

"Progressbar 进度条支持
let s:atv_pb_en = 0

"}}}1

"Keys 快捷键{{{1
amenu 9998.4.1 &Verilog.AutoDef.AutoDef()<TAB>                                   :call g:AutoDef()<CR>
amenu 9998.4.2 &Verilog.AutoDef.AutoReg()<TAB>                                   :call g:AutoReg()<CR>
amenu 9998.4.3 &Verilog.AutoDef.AutoWire()<TAB>                                  :call g:AutoWire()<CR>
amenu 9998.4.4 &Verilog.AutoDef.KillAutoDef()<TAB>                               :call g:KillAutoDef()<CR>
amenu 9998.4.5 &Verilog.AutoDef.KillAutoReg()<TAB>                               :call g:KillAutoReg()<CR>
amenu 9998.4.6 &Verilog.AutoDef.KillAutoWire()<TAB>                              :call g:KillAutoWire()<CR>

if !hasmapto(':call g:AutoReg()<ESC>')
    map <S-F6>      :call g:AutoReg()<ESC>
endif
if !hasmapto(':call g:AutoWire()<ESC>')
    map <S-F7>      :call g:AutoWire()<ESC>
endif
if !hasmapto(':call g:AutoDef()<ESC>')
    map <S-F8>      :call g:AutoDef()<ESC>
endif
"}}}1

"AutoReg 自动寄存器{{{1
"--------------------------------------------------
" Function: AutoReg
" Input: 
"   N/A
" Description:
"   autoreg all register
" Output:
"   Formatted autoreg code
" Note:
"   list of signal sequences
"    0      1             2      3            4         5
"   ['reg', specify type, width, signal_name, resolved, seq]
"---------------------------------------------------
function! g:AutoReg() abort
    "Record current position
    let orig_idx = line('.')
    let orig_col = col('.')

    "AutoReg all start from top line
    call cursor(1,1)

    while 1
        "Put cursor to /*autoreg*/ line
        if search('\/\*autoreg\*\/','W') == 0
            break
        endif

        "read from current buffer
        let lines = getline(1,line('$'))

        "Get keep register & update register list
        let [keep_reg_list,upd_reg_list] = s:GetDeclReg(lines)

        "Get reg names {name : value}
        let reg_names = s:GetReg(lines)

        "Remove reg from reg_names that want to be keep when autoreg
        "   reg_names = {signal_name : value }
        for name in keep_reg_list
            if has_key(reg_names,name)
                call remove(reg_names,name)
            endif
        endfor

        "Kill all contents between //Start of automatic reg and //End of automatic reg
        "Current position must be at /*autoreg*/ line
        call s:KillAutoReg()

        "Draw register, use reg_names to cover update register list
        "if reg_names has new reg_name that's never in upd_reg_list, add //REG_NEW
        "if reg_names has same reg_name that's in upd_reg_list, cover
        "if reg_names doesn't have reg_name that's in upd_reg_list, add //REG_DEL
        let lines = s:DrawReg(reg_names,upd_reg_list)

        "Append registers definition
        call append(line('.'),lines)

        "Only autoreg once
        break

    endwhile

    "cursor back
    call cursor(orig_idx,orig_col)
endfunction
"}}}1

"AutoWire 自动线网{{{1
"--------------------------------------------------
" Function: AutoWire
" Input: 
"   N/A
" Description:
"   autowire all wire
" Output:
"   Formatted autowire code
" Note:
"   list of signal sequences
"    0      1             2      3            4         5
"   ['wire', specify type, width, signal_name, resolved, seq]
"---------------------------------------------------
function g:AutoWire() abort
    "Record current position
    let orig_idx = line('.')
    let orig_col = col('.')

    "AutoWire all start from top line
    call cursor(1,1)

    while 1
        "Put cursor to /*autowire*/ line
        if search('\/\*autowire\*\/','W') == 0
            break
        endif

        "read from current buffer
        let lines = getline(1,line('$'))

        "Get keep wire & update wire list
        let [keep_wire_list,upd_wire_list] = s:GetDeclWire(lines)

        "Get wire names {name : value}
        let wire_names = s:GetWire(lines)

        "Remove wire from wire_names that want to be keep when autowire
        "   wire_names = {signal_name : value }
        for name in keep_wire_list
            if has_key(wire_names,name)
                call remove(wire_names,name)
            endif
        endfor

        "Kill all contents between //Start of automatic wire and //End of automatic wire 
        "Current position must be at /*autowire*/ line
        call s:KillAutoWire()

        "Draw wire, use wire_names to cover update wire list
        "if wire_names has new wire_name that's never in upd_wire_list, add //WIRE_NEW
        "if wire_names has same wire_name that's in upd_wire_list, cover
        "if wire_names doesn't have wire_name that's in upd_wire_list, add //WIRE_DEL
        let lines = s:DrawWire(wire_names,upd_wire_list)

        "Append wires definition
        call append(line('.'),lines)

        "Only autowire once
        break

    endwhile

    "cursor back
    call cursor(orig_idx,orig_col)
endfunction
"}}}1

"AutoDef 自动定义所有信号{{{1
"--------------------------------------------------
" Function: AutoDef
" Input: 
"   N/A
" Description:
"   autodef all signals
"   namely, autodef = autoreg + autowire
" Output:
"   Formatted autodef code
"---------------------------------------------------
function g:AutoDef() abort
    let prefix = s:st_prefix

    "Record current position
    let orig_idx = line('.')
    let orig_col = col('.')
    let save_foldenable = &foldenable
    execute ':'.'let &foldenable=0'

    "AutoDef all start from top line
    call cursor(1,1)

    while 1
        "Put cursor to /*autodef*/ line
        if search('\/\*autodef\*\/','W') == 0
            break
        endif

        "Kill all contents between //Start of automatic define and //End of automatic define 
        "Current position must be at /*autodef*/ line
        "call s:KillAutoDef()

        "darw //Start of automatic define
        if search('\/\/Start of automatic define','W') != 0
        else
            call append(line('.'),prefix.'//Start of automatic define')
            call cursor(line('.')+1,1)
        endif

        "AutoReg(){{{2
        "add /*autoreg*/
        call append(line('.'),'/*autoreg*/')
        "cursor + 1
        call cursor(line('.')+1,1)
        "AutoReg
        call g:AutoReg()
        "delete /*autoreg*/
        execute ':'.line('.').'d'
        "cursor to end
        call search('\/\/End of automatic reg','W')
        "}}}2

        "AutoWire(){{{2
        "add /*autowire*/
        call append(line('.'),'/*autowire*/')
        "cursor + 1
        call cursor(line('.')+1,1)
        "AutoReg
        call g:AutoWire()
        "delete /*autowire*/
        execute ':'.line('.').'d'
        "cursor to end
        call search('\/\/End of automatic wire','W')
        "}}}2

        if search('\/\/End of automatic define','W')
        else
            call append(line('.'),prefix.'//End of automatic define')
        endif

        "Only autodef once
        break

    endwhile

    "Put cursor back to original position
    let &foldenable = save_foldenable
    call cursor(orig_idx,orig_col)

    "Move other define down below //End of automatic define
    if g:atv_autodef_mv == 1
        call s:DefMove()
    endif

endfunction
"}}}1

"KillAutoReg Kill自动寄存器{{{1
"--------------------------------------------------
" Function: KillAutoReg
" Input: 
"   N/A
" Output:
"   Killed autoreg code
"---------------------------------------------------
function! g:KillAutoReg() abort

    "Record current position
    let orig_idx = line('.')
    let orig_col = col('.')

    "KillAutoReg all start from top line
    call cursor(1,1)

    while 1
        "Put cursor to /*autoreg*/ line
        if search('\/\*autoreg\*\/','W') == 0
            break
        endif

        "Kill all contents between //Start of automatic reg and //End of automatic reg
        "Current position must be at /*autoreg*/ line
        call s:KillAutoReg()

        "only kill autoreg once
        break
    endwhile

    "cursor back
    call cursor(orig_idx,orig_col)

endfunction
"}}}1

"KillAutoWire Kill自动线网{{{1
"--------------------------------------------------
" Function: KillAutoWire
" Input: 
"   N/A
" Output:
"   Killed autowire code
"---------------------------------------------------
function g:KillAutoWire() abort

    "Record current position
    let orig_idx = line('.')
    let orig_col = col('.')

    "AutoWire all start from top line
    call cursor(1,1)

    while 1
        "Put cursor to /*autowire*/ line
        if search('\/\*autowire\*\/','W') == 0
            break
        endif

        "Kill all contents between //Start of automatic wire and //End of automatic wire 
        "Current position must be at /*autowire*/ line
        call s:KillAutoWire()

        "only autowire once
        break
    endwhile

    "cursor back
    call cursor(orig_idx,orig_col)

endfunction
"}}}1

"KillAutoDef Kill自动定义所有信号{{{1
"--------------------------------------------------
" Function: KillAutoDef
" Input: 
"   N/A
" Output:
"   Killed autodef code
"---------------------------------------------------
function g:KillAutoDef() abort
    let prefix = s:st_prefix

    "Record current position
    let orig_idx = line('.')
    let orig_col = col('.')

    "AutoDef all start from top line
    call cursor(1,1)

    while 1
        "Put cursor to /*autodef*/ line
        if search('\/\*autodef\*\/','W') == 0
            break
        endif

        "Kill all contents between //Start of automatic define and //End of automatic define 
        "Current position must be at /*autodef*/ line
        call s:KillAutoDef()

        "only autodef once
        break
    endwhile

    "cursor back
    call cursor(orig_idx,orig_col)

endfunction
"}}}1

"Sub Function 辅助函数{{{1

"-------------------------------------------------------------------
"                             AutoReg
"-------------------------------------------------------------------
"AutoReg-Get
"GetReg 获取reg{{{2
"--------------------------------------------------
" Function: GetReg
" Input: 
"   lines : all lines to get reg
" Description:
"   Get reg info from declaration and always block
"   e.g
"   module_name
"   (
"       input       clk,
"       input       rst,
"       input       port_m,
"       output reg  c,
"       output reg [31:0] port_n,
"       output reg  port_n_valid
"   );
"
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
"           b = 0;
"           c <= 0;
"       end
"       else begin
"           b = 10'd9;
"           c <= 10'd122;
"       end
"   end
"
"   e.g reg sequences
"   ['reg', 'freg', width, 'a', 1, sequence]
"   ['reg', 'creg', width, 'b', 1, sequence]
"   reg c is ommited because it exists in port io
"
" Output:
"   list of signal sequences
"    0     1             2      3            4         5
"   [type, specify type, width, signal_name, resolved, seq]
"---------------------------------------------------
function s:GetReg(lines)
    let lines = copy(a:lines)
    let reg_names = s:GetAllSig(a:lines,'reg')
    return reg_names
endfunction
"}}}2

"GetfReg 获取非阻塞类型reg{{{2
"--------------------------------------------------
" Function: GetfReg
" Input: 
"   lines : all lines to get freg
" Description:
"   Get freg info from always block
" Output:
"   width_names    
"    0     1            2      3               4            5                6             7
"   [seqs, signal_name, lines, left_width_nrs, left_widths, right_width_nrs, right_widths, right_signal_link]
"---------------------------------------------------
function s:GetfReg(lines)
    let idx = 1
    let seq = 0
    let width_names = {}

    while idx < len(a:lines)
        "skip comment line
        let idx = g:AutoVerilog_SkipCommentLine(0,idx,a:lines)
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
                let idx_inblock = g:AutoVerilog_SkipCommentLine(0,idx_inblock,a:lines)
                if idx_inblock == -1
                    echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
                endif
                let line = a:lines[idx_inblock-1]
                "delete comment in line
                let line = substitute(line,'\/\/.*$','','')
                "meet another always block, assign statement, wire/reg or instance, break
                if line =~ '^\s*'.s:VlogTypeCalcs || line =~ '^\s*'.s:VlogTypeDatas
\               || line =~ '/\*\<autoinst\>\*/' || line =~ '\s*\.\w\+(.*)' 
\               || idx_inblock == len(a:lines) || line =~ '^\s*\<endmodule\>' 
                    break
                else
                    "match a <= ...; or {a,b[1:0],c} <= ...;
                    "exception:
                    "1. for (i=0;i<=30;i=i+1)
                    "2. if(a<=30)begin
                    "3. defparam info_fifo.lpm_width = 4;
                    if (line =~ '\v((for\s*\(.*)|((else\s*)?if\s*\(.*))@<!\w+\s*(\[.*\])?\s*\<\=' ||
                      \ line =~ '{.*}\s*<=')
                        let left = matchstr(line,'\v\s*\zs((\w+\s*(\[.*\])?)|(\{.*\}))\ze\s*\<\=')
                        let right = matchstr(line,'<=\s*\zs.*\ze\s*')
                        let match_flag = 1
                    elseif (line =~ '\v((for\s*\(.*))@<!\w+\s*(\[.*\])?\s*\=[^=]' ||
                          \ line =~ '{.*}\s*=[^=]')
                        let left = matchstr(line,'\v\s*\zs((\w+\s*(\[.*\])?)|(\{.*\}))\ze\s*\=[^=]')
                        let right = matchstr(line,'[^=]=\s*\zs.*\ze\s*')
                        let match_flag = 1
                    else
                        let match_flag = 0
                    endif
                    if match_flag == 1
                        "get name first
                        let reg_name_list = s:GetSigName(left)

                        "width_names    
                        "    0     1            2      3               4            5                6             7
                        "   [seqs, signal_name, lines, left_width_nrs, left_widths, right_width_nrs, right_widths, right_signal_link]

                        "sigle signal, find its signal width 
                        if len(reg_name_list) == 1
                            let seq = seq + 1
                            let reg_name = reg_name_list[0]
                            "find width from left side, e.g. reg_a[4:0] (same time initialize width_names)
                            let width_names = s:GetLeftWidth(left,seq,reg_name,line,width_names)

                            "find width from right side. e.g. 3'd5 reg_b[4:3]
                            let width_names = s:GetRightWidth(right,reg_name,width_names)

                        "multi signal concatenation, don't calculate signal width anymore. e.g. {reg_a,reg_b,reg_c[2:0]}
                        else
                            for reg_name in reg_name_list
                                let seq = seq + 1
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

    return width_names

endfunction
"}}}2

"GetcReg 获取阻塞类型reg{{{2
"--------------------------------------------------
" Function: GetcReg
" Almost same logic as GetfReg
" Refer to GetfReg for function Description
"---------------------------------------------------
function s:GetcReg(lines)
    let idx = 1
    let seq = 0
    let width_names = {}

    while idx < len(a:lines)
        "skip comment line
        let idx = g:AutoVerilog_SkipCommentLine(0,idx,a:lines)
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
                let idx_inblock = g:AutoVerilog_SkipCommentLine(0,idx_inblock,a:lines)
                if idx_inblock == -1
                    echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
                endif
                let line = a:lines[idx_inblock-1]
                "delete comment in line
                let line = substitute(line,'\/\/.*$','','')
                "meet another always block, assign statement, wire/reg or instance, break
                if line =~ '^\s*'.s:VlogTypeCalcs || line =~ '^\s*'.s:VlogTypeDatas
\               || line =~ '/\*\<autoinst\>\*/' || line =~ '\s*\.\w\+(.*)' 
\               || idx_inblock == len(a:lines) || line =~ '^\s*\<endmodule\>' 
                    break
                else
                    "match a <= ...; or {a,b[1:0],c} <= ...;
                    "exception:
                    "1. for (i=0;i<=30;i=i+1)
                    "2. if(a<=30)begin
                    if (line =~ '\v((for\s*\(.*)|((else\s*)?if\s*\(.*))@<!\w+\s*(\[.*\])?\s*\<\=' ||
                      \ line =~ '{.*}\s*<=')
                        let left = matchstr(line,'\v\s*\zs((\w+\s*(\[.*\])?)|(\{.*\}))\ze\s*\<\=')
                        let right = matchstr(line,'<=\s*\zs.*\ze\s*')
                        let match_flag = 1
                    elseif (line =~ '\v((for\s*\(.*))@<!\w+\s*(\[.*\])?\s*\=[^=]' ||
                          \ line =~ '{.*}\s*=[^=]')
                        let left = matchstr(line,'\v\s*\zs((\w+\s*(\[.*\])?)|(\{.*\}))\ze\s*\=[^=]')
                        let right = matchstr(line,'[^=]=\s*\zs.*\ze\s*')
                        let match_flag = 1
                    else
                        let match_flag = 0
                    endif
                    if match_flag == 1
                        "get name first
                        let reg_name_list = s:GetSigName(left)

                        "width_names    
                        "    0     1            2      3               4            5                6             7
                        "   [seqs, signal_name, lines, left_width_nrs, left_widths, right_width_nrs, right_widths, right_signal_link]

                        "sigle signal, find its signal width 
                        if len(reg_name_list) == 1
                            let seq = seq + 1
                            let reg_name = reg_name_list[0]
                            "find width from left side, e.g. reg_a[4:0] (same time initialize width_names)
                            let width_names = s:GetLeftWidth(left,seq,reg_name,line,width_names)

                            "find width from right side. e.g. 3'd5 reg_b[4:3]
                            let width_names = s:GetRightWidth(right,reg_name,width_names)

                        "multi signal concatenation, don't calculate signal width anymore. e.g. {reg_a,reg_b,reg_c[2:0]}
                        else
                            for reg_name in reg_name_list
                                let seq = seq + 1
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

    return width_names

endfunction
"}}}2

"GetDeclReg 获取已经声明的reg{{{2
"--------------------------------------------------
" Function: GetDeclReg
" Input: 
"   N/A
" Description:
"   lines : lines to get declared register
"
" e.g. get decl_reg and auto_reg
"
"    reg  [3:0]                  m                               ;
"    reg  [4:0]                  n                               ;
"    /*autoreg*/
"    //Start of automatic reg
"    //Define flip-flop registers here
"    reg  [3:0]                  a                               ;
"    reg  [WIDTH-1:0]            qqq                             ;
"    //Define combination registers here
"    reg  [5:0]                  creg;
"    //End of automatic reg
"
" Output:
"   decl_reg : register declared outside /*autoreg*/
"   auto_reg : register declared inside /*autoreg*/
" e.g.
"   decl_reg = [m,n]
"   auto_reg = [a,qqq,creg]
"---------------------------------------------------
function s:GetDeclReg(lines)
    let decl_reg = []
    let auto_reg = []
    let idx = 1

    while idx < len(a:lines)
        "skip comment line
        let idx = g:AutoVerilog_SkipCommentLine(2,idx,a:lines)
        if idx == -1
            echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
        endif
        let line = a:lines[idx-1]

        "comment detect,judege if it's start
        if line =~ '\/\/.*$'
            if line =~ '\/\/Start of automatic reg'
                "start of autoreg
                while 1
                    let idx = idx + 1
                    let line = getline(idx)
                    "end of autoreg
                    if line =~ '\/\/End of automatic reg'
                        break
                    "abnormal end
                    elseif line =~ 'endmodule' || idx == line('$')
                        echohl ErrorMsg | echo "Error running GetDeclReg! Get //Start of automatic reg but abonormally quit!"| echohl None
                        break
                    "middle
                    elseif line =~ '^\s*reg'
                        let name = matchstr(line,'^\s*reg\s\+\(\[.*\]\)\?\s*\zs\w\+\ze')
                        call add(auto_reg,name)
                    endif
                endwhile
            else
                "delete comment
                let line = substitute(line,'\/\/.*$','','')
            endif
        endif

        while line =~ '^\s*reg\s\+\(\[.\{-\}\]\)\?\s*.\{-\}\s*;\s*'
            "delete abnormal
            if line =~ '\<signed\>\|\<unsigned\>'
                let line = substitute(line,'\<signed\>\|\<unsigned\>','','')
            endif
            let names = matchstr(line,'^\s*reg\s\+\(\[.\{-\}\]\)\?\s*\zs.\{-\}\ze\s*;\s*')
            "in case style of reg a = {b,c,d};
            let names = substitute(names,'\(\/\/\)\@<!=.*$','','')
            "in case style of reg [1:0] a,b,c;
            for name in split(names,',')
                let name = matchstr(name,'\w\+')
                call add(decl_reg,name)
            endfor
            let line = substitute(line,'^\s*reg\s\+\(\[.\{-\}\]\)\?\s*.\{-\}\s*;\s*','','')
        endwhile

        let idx = idx + 1
    endwhile

    return [decl_reg,auto_reg] 
endfunction
"}}}2

"AutoReg-Kill
"KillAutoReg 删除所有自动寄存器声明"{{{2
"--------------------------------------------------
" Function: KillAutoReg
" Input: 
"   Must put cursor to /*autoreg*/ position
" Description:
" e.g kill all declaration after /*autoreg*/
"    /*autoreg*/
"    //Start of automatic reg
"    //Define flip-flop registers here
"    reg  [3:0]                  a                               ;
"    reg  [WIDTH-1:0]            qqq                             ;
"    //Define combination registers here
"    reg  [5:0]                  creg;
"    //End of automatic reg
"
"   --------------> after KillAutoReg
"
"    /*autoreg*/
"
" Output:
"   line after kill
"   kill all between //Start of automatic reg & //End of automatic reg
"---------------------------------------------------
function s:KillAutoReg() 
    let orig_idx = line('.')
    let orig_col = col('.')
    let idx = line('.')
    let line = getline(idx)
    let kill_busy = 0
    if line =~ '/\*\<autoreg\>'
        "keep current line
        let idx = idx + 1
        while 1
            let line = getline(idx)
            "start of autoreg
            if line =~ '\/\/Start of automatic reg'
                execute ':'.idx.'d'
                let kill_busy = 1
            elseif kill_busy == 1
                "end of autoreg
                if line =~ '\/\/End of automatic reg'
                    "call deletebufline('%',idx)
                    execute ':'.idx.'d'
                    break
                "abnormal end
                elseif line =~ 'endmodule' || idx == line('$')
                    echohl ErrorMsg | echo "Error running KillAutoReg! Kill abnormally till the end!"| echohl None
                    break
                "middle
                else
                    "call deletebufline('%',idx)
                    execute ':'.idx.'d'
                endif
            else
                let idx = idx + 1
                "never start, normal end 
                if line =~ 'endmodule' || idx == line('$')
                    break
                endif
            endif 
        endwhile
    else
        echohl ErrorMsg | echo "Error running KillAutoReg! Kill line not match /*autoreg*/ !"| echohl None
    endif

    "cursor back
    call cursor(orig_idx,orig_col)
endfunction 
"}}}2

"AutoReg-Draw
"DrawReg 按格式输出例化register{{{2
"--------------------------------------------------
" Function: DrawReg
" Input: 
"   reg_names : new reg names for align
"   reg_list : old reg name list
"
" Description:
" e.g draw reg sequences
"    0     1             2      3            4         5
"   [type, specify type, width, signal_name, resolved, seq]
"   ['reg', 'freg', '', 'a', 1, sequence]
"   ['reg', 'creg', '[10:0]', 'b', 1, sequence]
"       reg             a;
"       reg  [10:0]     b;
"
" Output:
"   line that's aligned
"   e.g
"       reg  [WIDTH1:WIDTH2]     reg_name;
"---------------------------------------------------
function s:DrawReg(reg_names,reg_list)
    let prefix = s:st_prefix
    let reg_list = copy(a:reg_list)

    "guarantee spaces width{{{3
    let max_lname_len = 0
    let max_rsemicol_len = 0
    for name in keys(a:reg_names)
        "    0     1             2      3            4         5
        "   [type, specify type, width, signal_name, resolved, seq]
        let value = a:reg_names[name]
        let type = value[0]
        if type == 'reg'
            let name = value[3]
            let width = value[2]
            "calculate maximum len of position to Draw
            "let line = prefix.'reg'.'  '.width.width2name.name.name2semicol.semicol
            let max_lname_len = max([max_lname_len,len(prefix)+len('reg  ')+len(width)+4,g:atv_autodef_name_pos])
            let max_rsemicol_len = max([max_rsemicol_len,max_lname_len+len(name)+4,g:atv_autodef_sym_pos])
        endif
    endfor
    "}}}3

    "draw reg{{{3
    let lines = []

    "reg_list can be changed in function, therefore record if it's empty first
    if reg_list == []
        let reg_list_empty = 1
    else
        let reg_list_empty = 0
    endif

    "recover freg_seqs & creg_seqs{{{4
    let freg_seqs = {}
    let creg_seqs = {}
    for name in keys(a:reg_names)
        "Format reg sequences
        "    0     1             2      3            4         5
        "   [type, specify type, width, signal_name, resolved, seq]
        let value = a:reg_names[name]
        let stype = value[1]
        let seq = value[5]
        if stype == 'freg'
            call extend(freg_seqs,{seq : value})
        endif
        if stype == 'creg'
            call extend(creg_seqs,{seq : value})
        endif
    endfor
    "}}}4

    "darw //Start of automatic reg{{{4
    call add(lines,prefix.'//Start of automatic reg')
    "}}}4

    "darw //Define flip-flop registers here{{{4
    call add(lines,prefix.'//Define flip-flop registers here')
    "}}}4

    "draw freg{{{4
    for seq in sort(map(keys(freg_seqs),'str2nr(v:val)'),g:atv_sort_funcref)
        let value = freg_seqs[seq]
        "Format reg sequences
        "    0     1             2      3            4         5
        "   [type, specify type, width, signal_name, resolved, seq]

        "width
        let width = value[2]

        "width2name
        let width2name = repeat(' ',max_lname_len-len(prefix)-len(width)-len('reg  '))

        "name
        let name = value[3]

        "name2semicol
        "don't align tail if config
        if g:atv_autodef_tail_nalign == 1
            let name2semicol = ''
        else
            let name2semicol = repeat(' ',max_rsemicol_len-max_lname_len-len(name))
        endif

        "semicol
        let semicol = ';'

        "Draw reg by config
        "empty list, default
        if reg_list_empty == 1
            let line = prefix.'reg'.'  '.width.width2name.name.name2semicol.semicol
        "update list,draw reg by config
        else
            let line = prefix.'reg'.'  '.width.width2name.name.name2semicol.semicol
            "process //REG_NEW
            let reg_idx = index(reg_list,name) 
            "name not exist in old reg_list, add //REG_NEW
            if reg_idx == -1
                if g:atv_autodef_reg_new == 1
                    let line = line . ' // REG_NEW'
                else
                    let line = line
                endif
            "name already exist in old reg_list,cover
            else
                let line = line
                call remove(reg_list,reg_idx)
            endif
        endif
        "process //unresolved
        if g:atv_autodef_unresolved_flag == 1
            let resolved = value[4]
            if resolved == 0
                let line = line.'// unresolved'
            else
                let line = line
            endif
        endif

        call add(lines,line)

    endfor
    "}}}4

    "darw //Define combination registers here{{{4
    call add(lines,prefix.'//Define combination registers here')
    "}}}4

    "draw creg{{{4
    for seq in sort(map(keys(creg_seqs),'str2nr(v:val)'),g:atv_sort_funcref)
        let value = creg_seqs[seq]
        "Format reg sequences
        "    0       1         2       3       4            5 
        "   [type, sequence, width1, width2, signal_name, lines]

        "width
        let width = value[2]

        "width2name
        let width2name = repeat(' ',max_lname_len-len(prefix)-len(width)-len('reg  '))

        "name
        let name = value[3]

        "name2semicol
        "don't align tail if config
        if g:atv_autodef_tail_nalign == 1
            let name2semicol = ''
        else
            let name2semicol = repeat(' ',max_rsemicol_len-max_lname_len-len(name))
        endif

        "semicol
        let semicol = ';'

        "Draw reg by config
        "empty list, default
        if reg_list_empty == 1
            let line = prefix.'reg'.'  '.width.width2name.name.name2semicol.semicol
        "update list,draw reg by config
        else
            let line = prefix.'reg'.'  '.width.width2name.name.name2semicol.semicol
            "process //REG_NEW
            let reg_idx = index(reg_list,name) 
            "name not exist in old reg_list, add //REG_NEW
            if reg_idx == -1
                if g:atv_autodef_reg_new == 1
                    let line = line . ' // REG_NEW'
                else
                    let line = line
                endif
            "name already exist in old reg_list,cover
            else
                let line = line
                call remove(reg_list,reg_idx)
            endif
        endif
        "process //unresolved
        if g:atv_autodef_unresolved_flag == 1
            let resolved = value[4]
            if resolved == 0
                let line = line.'// unresolved'
            else
                let line = line
            endif
        endif

        call add(lines,line)

    endfor
    "}}}4

    if reg_list == []
    "remain register in reg_list
    else
        if g:atv_autodef_reg_del == 1
            for name in reg_list
                let line = prefix.'//REG_DEL: Register '.name.' has been deleted.'
                call add(lines,line)
            endfor
        endif
    endif

    "draw //End of automatic reg{{{4
    call add(lines,prefix.'//End of automatic reg')
    "}}}4

    "}}}3

    if lines == []
        echohl ErrorMsg | echo "Error reg_names input for function DrawReg! reg_names is empty!" | echohl None
    endif

    return lines

endfunction
"}}}2

"-------------------------------------------------------------------
"                             AutoWire
"-------------------------------------------------------------------
"AutoWire-Get
"GetWire 获取wire{{{2
"--------------------------------------------------
" Function: GetWire
" Input: 
"   lines : all lines to get wire
" Description:
"   Get wire info from instantce and assign block
"   e.g
"   module_name
"   inst_name
"   (
"       .clk(clk),
"       .rst(rst),
"       .port_m(port_m),
"       .c(c),
"       .port_n(port_n),
"       .port_n_valid(port_n_valid)
"   );
"
"   assign d = c_i + a_i;
"
"   e.g wire sequences
"   ['awire', seq, 'c0', 'c0', 'd', lines]
"   ['iwire', seq, 9,    0, 'c', lines]
"
" Output:
"   list of wire sequences
"    0       1         2       3       4            5 
"   [type, sequence, width1, width2, signal_name, lines]
"---------------------------------------------------
function s:GetWire(lines)
    let lines = copy(a:lines)
    let wire_names = s:GetAllSig(a:lines,'wire')
    return wire_names
endfunction
"}}}2

"GetaWire 获取assign类型wire{{{2
"--------------------------------------------------
" Function: GetaWire
" Input: 
"   lines : all lines to assign wire
" Description:
"   Get awire info from assign block
" Output:
"   width_names    
"    0     1            2      3               4            5                6             7
"   [seqs, signal_name, lines, left_width_nrs, left_widths, right_width_nrs, right_widths, right_signal_link]
"---------------------------------------------------
function s:GetaWire(lines)
    let idx = 1
    let seq = 0
    let width_names = {}
    let reg_names = {}

    while idx < len(a:lines)
        "skip comment line
        let idx = g:AutoVerilog_SkipCommentLine(0,idx,a:lines)
        if idx == -1
            echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
        endif
        let line = a:lines[idx-1]
        "delete // comment
        let line = substitute(line,'\/\/.*$','','')

        let assign_flag = 0
        "find assign wire
        if line =~ '^\s*\<assign\>\s*.*[^=]=[^=].*;\s*$'
            let assign_flag = 1
        elseif line =~ '^\s*\<assign\>\s*.*[^=]=[^=][^;]*$'
            let assign_flag = 1
            let idx_inblock = idx + 1
            let multi_line = line
            "find signals in block
            while 1
                "skip comment line
                let idx_inblock = g:AutoVerilog_SkipCommentLine(0,idx_inblock,a:lines)
                if idx_inblock == -1
                    echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
                endif
                let line = a:lines[idx_inblock-1]
                let line = substitute(line,'\/\/.*$','','')
                "meet end break
                if line =~ ';\s*$'
                    let multi_line = multi_line.line
                    break
                "meet another always block, assign statement, wire/reg or instance, break
                elseif line =~ '^\s*'.s:VlogTypeCalcs || line =~ '^\s*'.s:VlogTypeDatas
\               || line =~ '/\*\<autoinst\>\*/' || line =~ '\s*\.\w\+(.*)' 
\               || idx_inblock == len(a:lines) || line =~ '^\s*\<endmodule\>' 
                    break
                else
                    let multi_line = multi_line.line
                endif
                let idx_inblock = idx_inblock + 1
            endwhile
            let line = multi_line
        else
            let assign_flag = 0
        endif

        if assign_flag == 1
            "match assign a[2:0] = ...; or assign {a,b[1:0],c} = ...;
            "exception:
            "1. for (i=0;i<30;i=i+1)
            if line =~ '^\s*\<assign\>\s*\w\+\s*\(\[.*\]\)\?\s*[^=]=[^=]' || line =~ '^\s*\<assign\>\s*{.*}'
                let left = matchstr(line,'\<assign\>\s*\zs.\{-\}\ze\s*=[^=]')
                let right = matchstr(line,'\<assign\>\s*.\{-\}\s*=\zs[^=].*\ze\s*')

                "get name first
                let reg_name_list = s:GetSigName(left)

                "width_names    
                "    0     1            2      3               4            5                6             7
                "   [seqs, signal_name, lines, left_width_nrs, left_widths, right_width_nrs, right_widths, right_signal_link]

                "sigle signal, find its signal width 
                if len(reg_name_list) == 1
                    let seq = seq + 1
                    let reg_name = reg_name_list[0]
                    "find width from left side, e.g. reg_a[4:0] (same time initialize width_names)
                    let width_names = s:GetLeftWidth(left,seq,reg_name,line,width_names)

                    "find width from right side. e.g. 3'd5 reg_b[4:3]
                    let width_names = s:GetRightWidth(right,reg_name,width_names)

                "multi signal concatenation, don't calculate signal width anymore. e.g. {reg_a,reg_b,reg_c[2:0]}
                else
                    for reg_name in reg_name_list
                        let seq = seq + 1
                        let width_names = s:GetLeftWidth(reg_name,seq,reg_name,line,width_names)
                    endfor
                endif
            endif
        endif
        let idx = idx + 1
    endwhile

    return width_names

endfunction
"}}}2

"GetiWire 获取inst类型wire{{{2
"--------------------------------------------------
" Function: GetiWire
" Input: 
"   lines : lines to get inst io wire
" Description:
"   Get inst io wire info from lines
"   e.g
"   module_name #(
"       .A_PARAMETER (A_PARAMETER)
"       .B_PARAMETER (B_PARAMETER)
"   )
"   inst_name
"   (
"       .clk(s_clk),
"       .rst(s_rst),
"       .in_test(10'd0),
"       /*autoinst*/
"       .port_a(port_a_o[4:0]),
"       .port_b_valid(port_b_valid),
"       .port_b(port_b)
"   );
"
" Output:
"   width_names    
"    0     1            2      3             4            5         6
"   [seqs, signal_name, lines, module_names, conn_widths, resolved, stype]
"---------------------------------------------------
function s:GetiWire(lines,files,modules,reg_width_names,decl_reg,io_names)
    let width_names = {}

    "Get current module io
    let module_io_names = copy(a:io_names)

    "Delete Inst Parameter lines
    let lines = s:GetiWire_DelPara(a:lines)

    let idx = 0
    let seq = 0
    "Record current position
    let orig_idx = line('.')
    let orig_col = col('.')
    "Progressbar
    if s:atv_pb_en == 1
        let pb = NewSimpleProgressBar("Getting inst wire :",len(lines)) 
    endif
    while idx < len(lines)
        let idx = idx + 1
        if s:atv_pb_en == 1
            call pb.incr(1)
        endif

        "Skip Comment{{{3
        let idx = g:AutoVerilog_SkipCommentLine(2,idx,lines)  "skip pair comment line
        if idx == -1
            echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
        endif
        let line = lines[idx-1]
        "delete // comment
        let line = substitute(line,'\/\/.*$','','')
        "}}}3

        "Get module_name & inst_io_names{{{3
        "find instance line e.g. .inst_a(conn_b),
        let idx2 = 0
        if line =~ '\.\s*\w\+\s*(.\{-\})'
            "
            "Put cursor to /*autoinst*/ line
            call cursor(idx,1)
            try
                "Get module_name & inst_name
                let [module_name,inst_name,idx1,idx2,idx3] = g:AutoVerilog_GetInstModuleName()

                "Get io names {name: value}
                if has_key(a:modules,module_name)
                    let file = a:modules[module_name]
                    let dir = a:files[file]
                    let inst_io_names = g:AutoVerilog_GetIO(readfile(dir.'/'.file),'name')
                else
                    echohl ErrorMsg | echo "file: ".module_name.".v does not exist in cur dir ".getcwd() | echohl None
                    let inst_io_names = {}
                endif
            endtry
        endif
        "}}}3
        
        "Get inst wire{{{3
        "
        "  .port_a  (   connection_b[10:0]  )
        "    |              |          |
        "   port           conn       conn_width
        "  
        "  port_width can be found in the instance file's io declaration
        "
        "in case abnormal get module_name, idx2 must be bigger than idx
        if idx2 >= idx
            "echo 'module_name = '.module_name
            for idx in range(idx1,idx2)
                let line = lines[idx-1]
                "delete comment
                let line = substitute(line,'\/\/.*$','','')
                " [^.] is used to find only one inst
                " * is used to avoid bracket inside braket
                "e.g. .do(r_tx_data_12[(2+3-1:0)]));
                while line =~ '\.\s*\w\+\s*([^.]*)'
                    let seq = seq + 1
                    let port = matchstr(line,'\.\s*\zs\w\+\ze\s*([^.]*)')
                    let conn = matchstr(line,'\.\s*\w\+\s*(\s*\zs[^.]*\ze\s*)')    "connection
                    "there might exist double bracket for this kind of match,delete them
                    "e.g. .do(r_tx_data_12)); match conn will be r_tx_data_12)
                    while conn =~ ')\s*$'
                        let conn = substitute(conn,')\s*$','','')
                    endwhile
                    let conn_name = matchstr(conn,'\w\+')                           "connection name
                    let conn_width = matchstr(conn,'\[.*\]')                        "connection width

                    "record inst line here
                    let inst_line = line

                    "delete match pattern for next loop
                    "used for multi inst in the same line e.g. .wire_a(wire_a), .wire_b(wire_b)
                    let line = substitute(line,'\.\s*\w\+\s*([^.]*)','','')

                    "only find wire,omit useless pattern 
                    "e.g.   .wire_a(1'b1) .wire_b() .wire_c(0)
                    if (substitute(conn,'\w\+\s*\(\[.*\]\)\?\s*','','') != '') || (substitute(conn,'\s*','','') == '') || (substitute(conn,'\s*\d\+\s*','','') == '')
                        continue
                    endif

                    "find wire status from several aspects:
                    "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    "  | status |     definition      |             type             |  result   |  resolved  |
                    "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    "  |   -1   | error get from inst |              /               |   wire    | unresolved |
                    "  +--------+---------------------+------------------------------+-----------+------------+
                    "  |   0    |  besides all below  |              /               |   wire    | unresolved |
                    "  +--------+---------------------+------------------------------+-----------+------------+
                    "  |   1    |   define in inst    |         output/inout         |   wire    |  resolved  |
                    "  +--------+---------------------+------------------------------+-----------+------------+
                    "  |   2    |   define in inst    |            input             | undefined |  resolved  |
                    "  +--------+---------------------+------------------------------+-----------+------------+
                    "  |   3    |  define in current  |             reg              | not wire  |     /      |
                    "  +--------+---------------------+------------------------------+-----------+------------+
                    "  |   4    |  define in current  | output/inout/input(reg/wire) |  defined  |     /      |
                    "  +--------+---------------------+------------------------------+-----------+------------+
                    "  status priority 4=3 > 2=1 > 0
                    "
                    let wire_status = 0
                    let stype = 'iwire'

                    "if it's not input(output/inout), it must be wire
                    if has_key(inst_io_names,port)
                        "    0     1         2       3       4       5            6          7
                        "   [type, sequence, io_dir, width1, width2, signal_name, last_port, line ]
                        let value = inst_io_names[port] 
                        let io_dir = value[2]
                        if io_dir != 'input'
                            let wire_status = 1
                        else
                            let wire_status = 2
                        endif
                        "specify type to substitute iwire
                        let type = value[0]
                        if type == 'logic' || type == 'real'
                            let stype = type
                        else
                            let stype = 'iwire'
                        endif
                    else
                        let wire_status = -1
                        echohl ErrorMsg | echo "Error when get ".port." from ".module_name| echohl None
                    endif

                    "if it's reg, it can't be wire
                    if ( has_key(a:reg_width_names,conn_name) ) || ( index(a:decl_reg,conn_name) != -1 )
                        let wire_status = 3
                    endif

                    "if it's io, it can't be used to declare wire
                    if has_key(module_io_names,conn_name) 
                        let wire_status = 4
                    endif

                    "use only signal that can be wire
                    if wire_status <= 2
                        "if error get inst wire from inst file, unresolved
                        if wire_status == -1
                            let conn_width = conn_width
                        else
                            "if connection width not exist, use port_width
                            if conn_width == '' 
                                if value[3] == 'c0' || value[4] == 'c0'
                                    let port_width = ''
                                else
                                    let port_width = '['.value[3].':'.value[4].']'
                                endif
                                let conn_width = port_width
                            "if conneciton width exist, use connection width
                            else
                                let conn_width = conn_width
                            endif
                        endif

                        "inst wire
                        "       .port_a (port_a_o [4:0]),
                        if has_key(width_names,conn_name)
                            let old_value = width_names[conn_name]
                            let seqs = add(old_value[0],seq)
                            let inst_lines = add(old_value[2],inst_line)
                            let module_names = add(old_value[3],module_name)
                            let conn_widths = add(old_value[4],conn_width)
                        else
                            let seqs = [seq]
                            let inst_lines = [inst_line]
                            let module_names = [module_name]
                            let conn_widths = [conn_width]
                        endif

                        "resolved
                        if wire_status <= 0
                            let resolved = 0
                        else
                            let resolved = 1
                        endif

                                "   width_names
                                "    0     1            2           3             4            5         6
                                "   [seqs, signal_name, lines,      module_names, conn_widths, resolved, type]
                        let value = [seqs, conn_name,   inst_lines, module_names, conn_widths, resolved, stype]
                        
                        call extend(width_names,{conn_name : value})
                        "echo 'name = '.conn_name.join(conn_widths)
                        "if wire_status != -1
                        "    echo 'inst = '.port.port_width
                        "else
                        "    echo 'inst = '.port.''
                        "endif

                    endif
                endwhile
            endfor
            if s:atv_pb_en == 1
                call pb.incr(idx2-idx)
            endif
            let idx = idx2
        endif
        "}}}3
        
    endwhile
    "Put cursor back to original position
    call cursor(orig_idx,orig_col)
    "Progressbar restore
    if s:atv_pb_en == 1
        call pb.restore()
    endif

    return width_names

endfunction
"}}}2

"GetiWire_DelPara 删除inst parameter避免阻碍获取inst类型wire{{{2
"--------------------------------------------------
" Function: GetiWire_DelPara
" Input: 
"   lines : lines to delete
" Description:
"   Delete only inst parameter lines
"   e.g
"   module_name #(
"       .A_PARAMETER (A_PARAMETER),
"       .B_PARAMETER (B_PARAMETER)
"   )
"   inst_name
"   ( ...  );
"
"   after deleteion: 
"
"   module_name #(
"       
"       
"   )
"   inst_name
"   ( ...  );
"
"   Delete // comments by the way
" Output:
"   lines after deletion
"---------------------------------------------------
function s:GetiWire_DelPara(lines)
    let idx = 0
    let flag_num = 0
    let flag_lbracket = 0
    let flag_rbracket = 0
    let pdel_lines = []
    let multi_line = ''
    while idx < len(a:lines)
        let idx = idx + 1
        let line = a:lines[idx-1]
        "delete comment
        let line = substitute(line,'\/\/.*$','','')
        "record #
        if line =~ '#'
            let multi_line = ''
            let flag_num = 1
            let flag_rbracket = 0
            let flag_lbracket = 0
        endif
        "find #(
        if flag_num == 1 
            let multi_line = multi_line.line
            "still find
            if multi_line =~ '#\s*$' 
            "find line
            elseif multi_line =~ '#\s*(' 
                let flag_lbracket = 1
            "abonormal end
            else
                let flag_num = 0
            endif
        endif
        "find inst parameter
        if flag_num == 1 && flag_lbracket == 1 && flag_rbracket == 0 
            while line =~ '\.\s*\w\+\s*([^.]*)'
                "when match, first delete multiple inner bracket
                "e.g. .ADDR_CFG_LAST ( 32*(ROOT_CHN_NUM) )
                let inner_bracket = matchstr(line,'([^()]*)')
                if line =~ '\V'.matchstr(line,'\.s*\w\+\s*').inner_bracket
                    let line = substitute(line,'\V'.matchstr(line,'\.s*\w\+\s*').inner_bracket,'','')
                else
                    let line = substitute(line,'([^()]*)','','')
                    continue
                endif
            endwhile
        endif
        "end
        if flag_num == 1 && flag_lbracket == 1 && line =~ ')' 
            let flag_rbracket = 1
            let flag_lbracket = 0
            let flag_num = 0
        endif
        call add(pdel_lines,line)
    endwhile
    return pdel_lines
endfunction
"}}}2

"GetDeclWire 获取已经声明的wire{{{2
"--------------------------------------------------
" Function: GetDeclWire
" Input: 
"   N/A
" Description:
"   lines : lines to get declared wire
"
" e.g. get decl_wire and auto_wire
"
"    wire [3:0]                  m                               ;
"    wire [4:0]                  n                               ;
"    /*autowire*/
"    //Start of automatic wire
"    //Define assign wires here
"    wire [3:0]                  a                               ;
"    wire [WIDTH-1:0]            qqq                             ;
"    //Define instance wires here
"    wire [5:0]                  iwire;
"    //End of automatic wire
"
" Output:
"   decl_wire : wire declared outside /*autowire*/
"   auto_wire : wire declared inside /*autowire*/
" e.g.
"   decl_wire = [m,n]
"   auto_wire = [a,qqq,iwire]
"---------------------------------------------------
function s:GetDeclWire(lines)
    let decl_wire = []
    let auto_wire = []
    let idx = 1

    while idx < len(a:lines)
        "skip comment line
        let idx = g:AutoVerilog_SkipCommentLine(2,idx,a:lines)
        if idx == -1
            echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
        endif
        let line = a:lines[idx-1]

        "comment detect,judege if it's start
        if line =~ '\/\/.*$'
            if line =~ '\/\/Start of automatic wire'
                "start of autowire
                while 1
                    let idx = idx + 1
                    let line = getline(idx)
                    "end of autowire
                    if line =~ '\/\/End of automatic wire'
                        break
                    "abnormal end
                    elseif line =~ 'endmodule' || idx == line('$')
                        echohl ErrorMsg | echo "Error running GetDeclWire! Get //Start of automatic wire but abonormally quit!"| echohl None
                        break
                    "middle
                    elseif line =~ '^\s*wire'
                        let name = matchstr(line,'^\s*wire\s\+\(\[.*\]\)\?\s*\zs\w\+\ze')
                        call add(auto_wire,name)
                    endif
                endwhile
            else
                "delete comment
                let line = substitute(line,'\/\/.*$','','')
            endif
        endif

        while line =~ '^\s*wire\s\+\(\[.\{-\}\]\)\?\s*.\{-\}\s*;\s*'
            "delete abnormal
            if line =~ '\<signed\>\|\<unsigned\>'
                let line = substitute(line,'\<signed\>\|\<unsigned\>','','')
            endif
            let names = matchstr(line,'^\s*wire\s\+\(\[.\{-\}\]\)\?\s*\zs.\{-\}\ze\s*;\s*')
            "in case style of wire a = {b,c,d};
            let names = substitute(names,'\(\/\/\)\@<!=.*$','','')
            "in case style of wire [1:0] a,b,c;
            for name in split(names,',')
                let name = matchstr(name,'\w\+')
                call add(decl_wire,name)
            endfor
            let line = substitute(line,'^\s*wire\s\+\(\[.\{-\}\]\)\?\s*.\{-\}\s*;\s*','','')
        endwhile

        let idx = idx + 1
    endwhile

    return [decl_wire,auto_wire] 
endfunction
"}}}2

"AutoWire-Kill
"KillAutoWire 删除所有自动线网声明"{{{2
"--------------------------------------------------
" Function: KillAutoWire
" Input: 
"   Must put cursor to /*autowire*/ position
" Description:
" e.g kill all declaration after /*autowire*/
"    /*autowire*/
"    //Start of automatic wire
"    //Define assign wires here
"    wire [3:0]                  a                               ;
"    wire [WIDTH-1:0]            qqq                             ;
"    //Define instance wires here
"    wire [5:0]                  iwire;
"    //End of automatic wire
"
"   --------------> after KillAutoWire
"
"    /*autowire*/
"
" Output:
"   line after kill
"   kill all between //Start of automatic wire & //End of automatic wire
"---------------------------------------------------
function s:KillAutoWire() 
    let orig_idx = line('.')
    let orig_col = col('.')
    let idx = line('.')
    let line = getline(idx)
    let kill_busy = 0
    if line =~ '/\*\<autowire\>'
        "keep current line
        let idx = idx + 1
        while 1
            let line = getline(idx)
            "start of autowire
            if line =~ '\/\/Start of automatic wire'
                execute ':'.idx.'d'
                let kill_busy = 1
            elseif kill_busy == 1
                "end of autowire
                if line =~ '\/\/End of automatic wire'
                    "call deletebufline('%',idx)
                    execute ':'.idx.'d'
                    break
                "abnormal end
                elseif line =~ 'endmodule' || idx == line('$')
                    echohl ErrorMsg | echo "Error running KillAutoWire! Kill abnormally till the end!"| echohl None
                    break
                "middle
                else
                    "call deletebufline('%',idx)
                    execute ':'.idx.'d'
                endif
            else
                let idx = idx + 1
                "never start, normal end 
                if line =~ 'endmodule' || idx == line('$')
                    break
                endif
            endif 
        endwhile
    else
        echohl ErrorMsg | echo "Error running KillAutoWire! Kill line not match /*autowire*/ !"| echohl None
    endif

    "cursor back
    call cursor(orig_idx,orig_col)
endfunction 
"}}}2

"AutoWire-Draw
"DrawWire 按格式输出例化wire{{{2
"--------------------------------------------------
" Function: DrawWire
" Input: 
"   wire_names : new wire names for align
"   wire_list : old wire name list
"
" Description:
" e.g draw wire sequences
"    0     1             2      3            4         5
"   [type, specify type, width, signal_name, resolved, seq]
"   ['wire', 'awire', '', 'a', 1, sequence]
"   ['wire', 'iwire', '[10:0]', 'b', 1, sequence]
"       wire            a;
"       wire [10:0]     b;
"
" Output:
"   line that's aligned
"   e.g
"       wire  [WIDTH1:WIDTH2]     wire_name;
"---------------------------------------------------
function s:DrawWire(wire_names,wire_list)
    let prefix = s:st_prefix
    let wire_list = copy(a:wire_list)

    "guarantee spaces width{{{3
    let max_lname_len = 0
    let max_rsemicol_len = 0
    for name in keys(a:wire_names)
        "    0     1             2      3            4         5
        "   [type, specify type, width, signal_name, resolved, seq]
        let value = a:wire_names[name]
        let type = value[0]
        let stype = value[1]
        if type == 'wire'
            let name = value[3]
            let width = value[2]
            "calculate maximum len of position to Draw
            "let line = prefix.'wire'.' '.width.width2name.name.name2semicol.semicol
            if stype == 'iwire' || stype == 'awire'
                let stype = 'wire'
            else
                "logic & real
            endif
            let max_lname_len = max([max_lname_len,len(prefix)+len(stype)+len(' ')+len(width)+4,g:atv_autodef_name_pos])
            let max_rsemicol_len = max([max_rsemicol_len,max_lname_len+len(name)+4,g:atv_autodef_sym_pos])
        endif
    endfor
    "}}}3

    "draw wire{{{3
    let lines = []

    "wire_list can be changed in function, therefore record if it's empty first
    if wire_list == []
        let wire_list_empty = 1
    else
        let wire_list_empty = 0
    endif

    "recover awire_seqs & iwire_seqs{{{4
    let awire_seqs = {}
    let iwire_seqs = {}
    for name in keys(a:wire_names)
        "Format wire sequences
        "    0     1             2      3            4         5
        "   [type, specify type, width, signal_name, resolved, seq]
        let value = a:wire_names[name]
        let stype = value[1]
        let seq = value[5]
        if stype == 'awire'
            call extend(awire_seqs,{seq : value})
        endif
        if stype == 'iwire' || stype == 'logic' || stype == 'real'
            call extend(iwire_seqs,{seq : value})
        endif
    endfor
    "}}}4

    "darw //Start of automatic wire{{{4
    call add(lines,prefix.'//Start of automatic wire')
    "}}}4

    "darw //Define assign wires here{{{4
    call add(lines,prefix.'//Define assign wires here')
    "}}}4

    "draw awire{{{4
    for seq in sort(map(keys(awire_seqs),'str2nr(v:val)'),g:atv_sort_funcref)
        let value = awire_seqs[seq]
        "Format wire sequences
        "    0     1             2      3            4         5
        "   [type, specify type, width, signal_name, resolved, seq]

        "width
        let width = value[2]

        "width2name
        let width2name = repeat(' ',max_lname_len-len(prefix)-len(width)-len('wire '))

        "name
        let name = value[3]

        "name2semicol
        "don't align tail if config
        if g:atv_autodef_tail_nalign == 1
            let name2semicol = ''
        else
            let name2semicol = repeat(' ',max_rsemicol_len-max_lname_len-len(name))
        endif

        "semicol
        let semicol = ';'

        "Draw wire by config
        "empty list, default
        if wire_list_empty == 1
            let line = prefix.'wire'.' '.width.width2name.name.name2semicol.semicol
        "update list,draw wire by config
        else
            let line = prefix.'wire'.' '.width.width2name.name.name2semicol.semicol
            "process //WIRE_NEW
            let wire_idx = index(wire_list,name) 
            "name not exist in old wire_list, add //WIRE_NEW
            if wire_idx == -1
                if g:atv_autodef_wire_new == 1
                    let line = line . ' // WIRE_NEW'
                else
                    let line = line
                endif
            "name already exist in old wire_list,cover
            else
                let line = line
                call remove(wire_list,wire_idx)
            endif
        endif
        "process //unresolved
        if g:atv_autodef_unresolved_flag == 1
            let resolved = value[4]
            if resolved == 0
                let line = line.'// unresolved'
            else
                let line = line
            endif
        endif

        call add(lines,line)

    endfor
    "}}}4

    "darw //Define instance wires here{{{4
    call add(lines,prefix.'//Define instance wires here')
    "}}}4

    "draw iwire{{{4
    for seq in sort(map(keys(iwire_seqs),'str2nr(v:val)'),g:atv_sort_funcref)
        let value = iwire_seqs[seq]
        "Format wire sequences
        "    0     1             2      3            4         5
        "   [type, specify type, width, signal_name, resolved, seq]

        "width
        let width = value[2]

        "width2name
        let stype = value[1]
        if stype == 'iwire' || stype == 'awire'
            let stype = 'wire'
        else
            "logic & real
        endif
        let width2name = repeat(' ',max_lname_len-len(prefix)-len(width)-len(stype)-len(' '))

        "name
        let name = value[3]

        "name2semicol
        "don't align tail if config
        if g:atv_autodef_tail_nalign == 1
            let name2semicol = ''
        else
            let name2semicol = repeat(' ',max_rsemicol_len-max_lname_len-len(name))
        endif

        "semicol
        let semicol = ';'

        "Draw wire by config
        "empty list, default
        if wire_list_empty == 1
            let line = prefix.stype.' '.width.width2name.name.name2semicol.semicol
        "update list,draw wire by config
        else
            let line = prefix.stype.' '.width.width2name.name.name2semicol.semicol
            "process //WIRE_NEW
            let wire_idx = index(wire_list,name) 
            "name not exist in old wire_list, add //WIRE_NEW
            if wire_idx == -1
                if g:atv_autodef_wire_new == 1
                    let line = line . ' // WIRE_NEW'
                else
                    let line = line
                endif
            "name already exist in old wire_list,cover
            else
                let line = line
                call remove(wire_list,wire_idx)
            endif
        endif
        "process //unresolved
        if g:atv_autodef_unresolved_flag == 1
            let resolved = value[4]
            if resolved == 0
                let line = line.'// unresolved'
            else
                let line = line
            endif
        endif

        call add(lines,line)

    endfor
    "}}}4

    if wire_list == []
    "remain wire in wire_list
    else
        if g:atv_autodef_wire_del == 1
            for name in wire_list
                let line = prefix.'//WIRE_DEL: Wire '.name.' has been deleted.'
                call add(lines,line)
            endfor
        endif
    endif

    "draw //End of automatic wire{{{4
    call add(lines,prefix.'//End of automatic wire')
    "}}}4

    "}}}3

    if lines == []
        echohl ErrorMsg | echo "Error wire_names input for function DrawWire! wire_names is empty!" | echohl None
    endif

    return lines

endfunction
"}}}2

"-------------------------------------------------------------------
"                             AutoDef
"-------------------------------------------------------------------
"AutoDef-Kill
"KillAutoDef 删除所有自动线网声明"{{{2
"--------------------------------------------------
" Function: KillAutoDef
" Input: 
"   Must put cursor to /*autodef*/ position
" Description:
" e.g kill all declaration after /*autodef*/
"    /*autodef*/
"    //Start of automatic define
"    ...
"    //End of automatic define
"
"   --------------> after KillAutoDef
"
"    /*autodef*/
"
" Output:
"   line after kill
"   kill all between //Start of automatic define & //End of automatic define
"---------------------------------------------------
function s:KillAutoDef() 
    let orig_idx = line('.')
    let orig_col = col('.')
    let idx = line('.')
    let line = getline(idx)
    let kill_busy = 0
    if line =~ '/\*\<autodef\>'
        "keep current line
        let idx = idx + 1
        while 1
            let line = getline(idx)
            "start of autodef
            if line =~ '\/\/Start of automatic define'
                execute ':'.idx.'d'
                let kill_busy = 1
            elseif kill_busy == 1
                "end of autowire
                if line =~ '\/\/End of automatic define'
                    "call deletebufline('%',idx)
                    execute ':'.idx.'d'
                    break
                "abnormal end
                elseif line =~ 'endmodule' || idx == line('$')
                    echohl ErrorMsg | echo "Error running KillAutoDef! Kill abnormally till the end!"| echohl None
                    break
                "middle
                else
                    "call deletebufline('%',idx)
                    execute ':'.idx.'d'
                endif
            else
                let idx = idx + 1
                "never start, normal end 
                if line =~ 'endmodule' || idx == line('$')
                    break
                endif
            endif 
        endwhile
    else
        echohl ErrorMsg | echo "Error running KillAutoDef! Kill line not match /*autodef*/ !"| echohl None
    endif

    "cursor back
    call cursor(orig_idx,orig_col)
endfunction 
"}}}2

"AutoDef-Move 
"DefMove 移动所有自动线网声明"{{{2
"--------------------------------------------------
" Function: DefMove
" Input: 
"   
" Description:
"   Move all declaration outside
"   //Start of automatic define 
"   &
"   //End of automatic define
"   to the position below
"   //End of automatic define
"
" e.g.
"   reg [2:0]   a;
"   .....
"   //Start of automatic define
"   ....
"   reg [2:0]   b;
"   //End of automatic define
"   .....
"   reg [2:0]   c;
"
"   --------------> after DefMove
"
"   //Start of automatic define
"   ....
"   reg [2:0]   b;
"   //End of automatic define
"   reg [2:0]   a;
"   reg [2:0]   c;
"   .....
"
" Output:
"   line after move
"---------------------------------------------------
function s:DefMove() 
    let lines = getline(1,line('$'))
    let [keep_reg_list,upd_reg_list] = s:GetDeclReg(lines)
    let [keep_wire_list,upd_wire_list] = s:GetDeclWire(lines)
    let orig_idx = line('.')
    let orig_col = col('.')
    let idx = 0
    let keep_lines = []
    "mark all definie outside automatic define
    while idx < len(lines)
        let idx = idx + 1
        let idx = g:AutoVerilog_SkipCommentLine(2,idx,lines)  "skip pair comment line
        if idx == -1
            echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
        endif
        let line = lines[idx-1]
        let orig_line = line
        if line =~ '\<signed\>\|\<unsigned\>'
            let line = substitute(line,'\<signed\>\|\<unsigned\>','','')
        elseif line =~ '\/\/.*$'
            let line = substitute(line,'\/\/.*$','','')
        endif
        for reg in keep_reg_list
            if line !~ '^\s*\/\/' && line =~ '^\s*reg\s\+\(\[.\{-\}\]\)\?\s*'.'\<'.reg.'\>'
                call add(keep_lines,orig_line)
                call remove(keep_reg_list,index(keep_reg_list,reg))
                execute ':'.idx.'normal A//keep_reg'
                break
            endif
        endfor
        for wire in keep_wire_list
            if line !~ '^\s*\/\/' && line =~ '^\s*wire\s\+\(\[.\{-\}\]\)\?\s*'.'\<'.wire.'\>'
                call add(keep_lines,orig_line)
                call remove(keep_wire_list,index(keep_wire_list,wire))
                execute ':'.idx.'normal A//keep_wire'
                break
            endif
        endfor
    endwhile
    call cursor(orig_idx,orig_col)
    "append all define
    call cursor(1,1)
    call search('\/\/End of automatic define','W')
    call append(line('.'),keep_lines)
    "delete all scattered define
    execute ':silent! '.'g/^\s*reg.*\/\/keep_reg/d'
    execute ':silent! '.'g/^\s*wire.*\/\/keep_wire/d'
    "cursor back
    call cursor(1,1)
    call search('\/\*autodef\*\/','W')
endfunction
"}}}2

"Only for test use!!!!!!!!!!
function TestAutoVerilog() "{{{2

"    let lines = getline(1,line('$'))
"    let [sig_names,io_names,reg_width_names,awire_width_names,iwire_width_names] = s:GetAllSig(lines,'all')
"
"    "test wire use {{{3
"
"    let lines = getline(1,line('$'))
"
"    "gather all signals together
"
"    let io_names = g:AutoVerilog_GetIO(lines,'name')
"    
"    let reg_names = reg_width_names
"
"    "test reg {{{4
"    let cnt0 = 0
"    for name in keys(reg_names)
"        let cnt0 += 1
"    endfor
"    "echo cnt0
"
"    let cnt1 = 0
"    for line in lines
"        if line =~ '^\s*reg\s.*;\s*.*$'
"            let name = matchstr(line,'^\s*reg\s*\(\[.*\]\)\?\s*\zs\w\+\ze\s*;\s*.*$')
"            let cnt1 += 1
"            "echo name
"            if has_key(reg_names,name)
"                call remove(reg_names,name)
"            else
"                "call append(line('$'),name)
"            endif
"        endif
"    endfor
"    "echo cnt1
"
"    let err_flag = 0
"    let err_regs = []
"    if cnt0 != cnt1
"        for reg in keys (reg_names)
"            let err_flag = 1
"            call add(err_regs,reg)
"        endfor
"        if err_flag == 1
"            echo 'err!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
"            echo cnt0
"            echo cnt1
"            call append(line('$'),'reg remain-----')
"            call append(line('$'),err_regs)
"        else
"            echo 'reg match right!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
"        endif
"    else
"        echo 'reg match right!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
"    endif
"    "}}}4
"    
"    "test wire {{{4
"    
"    "io wire
"    let iowire_names = {}
"    for name in keys(io_names)
"        "   [type, sequence, io_dir, width1, width2, signal_name, last_port, line ]
"        let value = io_names[name]
"        let type = value[0]
"        if type == 'wire' || type == 'none'
"            call extend(iowire_names, {name : value})
"        endif
"    endfor
"
"    "iwire and awire
"    let awire_width_names = copy(awire_width_names)
"    let iwire_width_names = copy(iwire_width_names)
"    let orig_awire_width_names = copy(awire_width_names)
"    let orig_iwire_width_names = copy(iwire_width_names)
"
"    "iwire{{{5
"    let cnt_iwire = 0
"    for wire in keys(iwire_width_names)
"        let cnt_iwire += 1
"    endfor
"
"    let cnt_assign_iwire = 0
"    let cnt_assign_wire = 0
"    for wire in keys (awire_width_names)
"        let cnt_assign_wire += 1
"        if has_key(iwire_width_names,wire)
"            let cnt_assign_iwire += 1
"            call remove(iwire_width_names,wire)
"            continue
"        endif
"    endfor
"
"    "declared wire in iwire
"    let cnt_decl_iwire = 0
"    let decl_wire = {}
"    for line in lines
"        if line =~ '^\s*wire.*;\s*.*$'
"            "let name = matchstr(line,'^\s*wire\s*\(\[.*\]\)\?\s*\zs\w\+\ze.*;\s*\(\/\/.*\)\?\s*$')
"            while line =~ '^\s*wire\s\+\(\[.\{-\}\]\)\?\s*.\{-\}\s*;\s*'
"                "delete abnormal
"                if line =~ '\<signed\>\|\<unsigned\>'
"                    let line = substitute(line,'\<signed\>\|\<unsigned\>','','')
"                elseif line =~ '\/\/.*$'
"                    let line = substitute(line,'\/\/.*$','','')
"                endif
"                let names = matchstr(line,'^\s*wire\s\+\(\[.\{-\}\]\)\?\s*\zs.\{-\}\ze\s*;\s*')
"                "in case style of wire a = {b,c,d};
"                let names = substitute(names,'\(\/\/\)\@<!=.*$','','')
"                "in case style of wire [1:0] a,b,c;
"                for name in split(names,',')
"                    let name = matchstr(name,'\w\+')
"                    call extend(decl_wire,{name : ""})
"                    if has_key(iwire_width_names,name)
"                        let cnt_decl_iwire += 1
"                        call remove(iwire_width_names,name)
"                    endif
"                endfor
"                let line = substitute(line,'^\s*wire\s\+\(\[.\{-\}\]\)\?\s*.\{-\}\s*;\s*','','')
"            endwhile
"        endif
"    endfor
"
"    if len(iwire_width_names) == 0
"        echo 'iwire match right!!!!!!!!!!!!!!!!!!!!!'
"    else
"        echo 'iwire not all match'
"        call append(line('$'),'iwire remain-----')
"        for name in keys ( iwire_width_names )
"            call append(line('$'),name)
"        endfor
"    endif
"    "}}}5
"    
"    "all wire {{{5
"    let all_wire_names = {}
"    let awire_width_names = orig_awire_width_names
"    let iwire_width_names = orig_iwire_width_names
"
"    for wire in keys(iwire_width_names)
"        call extend(all_wire_names,{wire : ""})
"    endfor
"
"    for wire in keys(awire_width_names)
"        call extend(all_wire_names,{wire : ""})
"    endfor
"
"    for wire in keys(iowire_names)
"        call extend(all_wire_names,{wire : ""})
"    endfor
"
"    for name in keys(decl_wire)
"        if has_key(all_wire_names,name)
"            call remove(decl_wire,name)
"        endif
"    endfor
"
"    if len(decl_wire) == 0
"        echo 'decl wire match right!!!!!!!!!!!!!!!!!!!!!'
"    else
"        echo 'decl wire not all match'
"        call append(line('$'),'decl wire remain-----')
"        for name in keys ( decl_wire)
"            call append(line('$'),name)
"        endfor
"    endif
"    "}}}5
"    
"    "}}}4
"
"   "}}}3
"
"    call AutoWire()

     let file = s:GetFileList()
     "let file = s:GetTags()
    
endfunction "}}}2

"-------------------------------------------------------------------
"                            Universal
"-------------------------------------------------------------------
"Universal-GetSigName
"{{{2 GetSigName 获取信号名称
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
"}}}2

"Universal-GetLeftWidth 
"GetLeftWidth 获取左半部分信号宽度{{{2
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
            let width1 = matchstr(width,'\[\zs.*\ze\]')
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
"}}}2

"Universal-GetRightWidth
"GetRightWidth 获取右半部分信号宽度{{{2
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
    "Note: only match once, don't match pattern like 3'd3+4'd1
    if right =~ '^\(`\?\w\+\|\d\+\)' . "'" . '[bhd].*;' && substitute(right,'^\(`\?\w\+\|\d\+\)'."'".'[bhd]\w*','','')==';'
        "pure number width e.g. 5'd0 -> signal_a[4:0]
        if right =~ '^\d\+' . "'" . '[bhd].*'
            let width = matchstr(right,'\d\+')   
            call add(right_width_nrs,str2nr(width)-1)
            call add(right_width_nrs,0)
        "parameter type input width e.g. WIDTH'hff -> signal_a[WIDTH-1:0]
        elseif right =~ '^`\?\w\+\' . "'" . '[bhd].*'
            let width1 = matchstr(right,'`\?\w\+').'-1'
            let width2 = '0'
            call add(right_widths,[width1,width2])
        endif

    "match signal[N], N may be `define or parameter or number
    "Note: only match once, don't match pattern like a[7]+b[17] && a[7:0]
    elseif right =~ '^\~\?\w\+\[[^:]*\];' && substitute(right,'^\~\?\w\+\[[^:]\{-}\]','','') == ';'
        let width1 = matchstr(right,'\v\[\zs.*\ze\]')   
        let width2 = ''
        "pure number width e.g. signal_a[4]
        if substitute(width1,'\d\+','','g') == ''
            call add(right_width_nrs,0)
        "parameter type input width e.g. signal_a[WIDTH]
        else
            call add(right_widths,[width1,width2])
        endif
        
    "match signal[M:N] or ~signal[M:N], M and N may be `define or parameter or number
    "Note: only match once, don't match pattern like a[7:0]+b[7:0]
    elseif right =~ '^\~\?\w\+\[.\{-}:.\{-}\];' && substitute(right,'^\~\?\w\+\[.\{-}:.\{-}\]','','') == ';' 
            let width1 = matchstr(right,'\v\[\zs.{-}\ze:.{-}\]')   
            let width2 = matchstr(right,'\v\[.{-}:\zs.{-}\ze\]')
            "pure number width e.g. signal_a[3:0]
            if substitute(width1,'\d\+','','g') == '' && substitute(width2,'\d\+','','g') == ''
                call add(right_width_nrs,str2nr(width1))
                call add(right_width_nrs,str2nr(width2))
            "parameter type input width e.g. signal_a[WIDTH-1:0]
            "calculation type e.g. signal_a[2*3-1:0] signal_b[4/2-1:0]
            else
                call add(right_widths,[width1,width2])
            endif

    "match signal0 == signa11 or signal0 != signal1
    elseif right =~ '^(\?\w\+\(\[.*\]\)\?==\w\+\(\[.*\]\)\?)\?;' || right =~ '^(\?\w\+\(\[.*\]\)\?!=\w\+\(\[.*\]\)\?)\?;' 
        call add(right_width_nrs,0)

    "match &signal0 |signal0 or ^signal0
    elseif right =~ '^[\^&|]\w\+\(\[.*\]\)\?;'
        call add(right_width_nrs,0)

    "match pure signal0 or ~signal0
    elseif right =~ '^\~\?\w\+;'
        "pure number, ignore
        if right =~ '^\~\?\d\+;'
        else
            let s0 = matchstr(right,'^\~\?\zs\w\+\ze;')
            call extend(right_signal_link,{s0 : ['max','']})  "get maximum signal
        endif

    "match sel ? signal0 : signal1
    elseif right =~ '^.*?\w\+\(\[.*\]\)\?:\w\+\(\[.*\]\)\?;'
        let s0 = matchstr(right,'^.*?\zs\w\+\ze\(\[.*\]\)\?:\w\+\(\[.*\]\)\?;')
        let width0 = matchstr(right,'^.*?\w\+\zs\(\[.*\]\)\?\ze:\w\+\(\[.*\]\)\?;')
        let s1 = matchstr(right,'^.*?\w\+\(\[.*\]\)\?:\zs\w\+\ze\(\[.*\]\)\?;')
        let width1 = matchstr(right,'^.*?\w\+\(\[.*\]\)\?:\w\+\zs\(\[.*\]\)\?\ze;')
        call extend(right_signal_link,{s0 : ['max',width0]})  "get maximum signal
        call extend(right_signal_link,{s1 : ['max',width1]})

    "match {signal0,signal1[1:0],signal2......}
    elseif right =~ '^{.*}'
        "while 1
        "    if right =~ '\w\+\[.\{-\}\]'
        "        let s0 = matchstr(right,'\w\+')
        "        let width = matchstr(right,'\[.\{-\}\]')
        "        let right = substitute(right,'\w\+\[.\{-\}\]','','')
        "    else
        "        let s0 = matchstr(right,'\w\+')
        "        let width = ''
        "        let right = substitute(right,'\w\+','','')
        "    endif

        "    if s0 == ''
        "        break
        "    else
        "        call extend(right_signal_link,{s0 : ['add',width]}) "get width addtion
        "    endif
        "endwhile
        let content = matchstr(right,'^{\zs.*\ze}')
        let signals = split(content,',')
        for signal in signals
            if substitute(signal,'\w\+\[.\{-\}\]','','') == ''
                let s0 = matchstr(signal,'\w\+')
                let width = matchstr(signal,'\[.\{-\}\]')
            elseif substitute(signal,'\w\+','','') == ''
                let s0 = matchstr(signal,'\w\+')
                let width = ''
            else
                let s0 = signal
                let width = ''
            endif
            call extend(right_signal_link,{s0 : ['add',width]}) "get width addtion
        endfor

    "match signal0 & signal1 | signal2 ^ signal3
    elseif right =~ '^\~\?\w\+\(\[.\{-\}\]\)\?\([\&\|\^]\~\?\w\+\(\[.\{-\}\]\)\?\)\+;'
        while 1
            let s0 = matchstr(right,'\w\+')
            let width = matchstr(right,'\w\+\zs[.\{-\}\]\ze')
            if s0 == ''
                break
            else
                let right = substitute(right,'\w\+\(\[.\{-\}\]\)\?','','')
                call extend(right_signal_link,{s0 : ['max',width]}) "get maximum signal
            endif
        endwhile

    "match signal0 + signal1 + signal2
    elseif right =~ '^(\?\w\+\(\[.*\]\)\?'.'+'.'\w\+\(\[.*\]\)\?'.'.*;'
        "remove ()
        let right = substitute(right,'(','','')
        let right = substitute(right,')','','')
        "find signal
        let signals = split(right,'+')
        for signal in signals
            if substitute(signal,'\w\+\[.\{-\}\]','','') == ''
                let s0 = matchstr(signal,'\w\+')
                let width = matchstr(signal,'\[.\{-\}\]')
            elseif substitute(signal,'\w\+','','') == ''
                let s0 = matchstr(signal,'\w\+')
                let width = ''
            else
                let s0 = signal
                let width = ''
            endif
            call extend(right_signal_link,{s0 : ['max+1',width]}) "get  maximum signal,width add 1
        endfor
    else
    "can't recognize right side of 'd4
    "
    "Unresolved

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

"}}}2

"Universal-GetSig
"GetAllSig 获取所有信号{{{2
"--------------------------------------------------
" Function: GetAllSig
" Input:
"   lines : all lines to get IO port
"   mode : mode for signals getting
"          reg  -> mode for GetReg
"          wire -> mode for GetWire 
"           -> ......
"           
" Description:
"   +------+--------------------+
"   | type | specify type       |
"   +------+--------------------+
"   | io   | input output inout |
"   +------+--------------------+
"   | reg  | creg freg          |
"   +------+--------------------+
"   | wire | iwire awire        |
"   +------+--------------------+
"
" Output:
"   list of signal sequences
"    0     1             2      3            4         5
"   [type, specify type, width, signal_name, resolved, seq]
"---------------------------------------------------
function s:GetAllSig(lines,mode)
    let sig_names = {}

    "io{{{3
    "   list of port sequences(including comment lines)
    "    0     1         2       3       4       5            6          7
    "   [type, sequence, io_dir, width1, width2, signal_name, last_port, line ]
    let io_names = g:AutoVerilog_GetIO(a:lines,'name')
    for name in keys(io_names)
        let value = io_names[name]
        let type = value[0]
        let seq = value[1]
        if type != 'keep'
            let io_dir = value[2]
            if value[3] == 'c0' || value[4] == 'c0'
                let width = ''
            else
                let width = '['.value[3].':'.value[4].']'
            endif
            "   io always resolved
            "   list of signal sequences
            "    0     1             2      3            4         5
            "   [type, specify type, width, signal_name, resolved, seq]
            let value = ['io',io_dir,width,name,1,seq]
            call extend(sig_names,{name : value})
        endif
    endfor
    "}}}3

    "reg{{{3
    let reg_names = {}
    "   list of width_names    
    "    0     1            2      3               4            5                6             7
    "   [seqs, signal_name, lines, left_width_nrs, left_widths, right_width_nrs, right_widths, right_signal_link]
    let freg_width_names = s:GetfReg(a:lines) 
    let creg_width_names = s:GetcReg(a:lines) 
    let reg_width_names = copy(freg_width_names)
    call extend(reg_width_names,creg_width_names,"error")

    "remove reg exists in io
    if g:atv_autodef_reg_rmv_io == 1
        for name in keys(reg_width_names)
            if has_key(io_names,name)
                call remove(reg_width_names,name)
            endif
        endfor
    endif

    "record reg
    for name in keys(reg_width_names)
        if has_key(freg_width_names,name)
            let type = 'freg'
        else
            let type = 'creg'
        endif
        let value = reg_width_names[name]
        let seqs = value[0]
        let left_width_nrs = value[3]
        let left_widths = value[4]
        let right_width_nrs = value[5]
        let right_widths = value[6]
        let right_signal_link = value[7]
        let resolved = 1
        if left_widths != []
            let [width1,width2] = left_widths[0]
            if width1 != ''
                if width2 != ''
                    let width = '['.width1.':'.width2.']'
                else
                    let width = '['.width1.']'
                endif
            else
                let width == ''
            endif
        elseif left_width_nrs != []
            let width1 = max(left_width_nrs)
            let width2 = min(left_width_nrs)
            if width1 == 0 && width2 == 0
                let width = ''
            else
                let width = '['.width1.':'.width2.']'
            endif
        elseif right_widths != []
            let [width1,width2] = right_widths[0]
            if width1 != ''
                if width2 != ''
                    let width = '['.width1.':'.width2.']'
                else
                    let width = '['.width1.']'
                endif
            else
                let width = ''
            endif
        elseif right_width_nrs != []
            let width1 = max(right_width_nrs)
            let width2 = min(right_width_nrs)
            if width1 == 0 && width2 == 0
                let width = ''
            else
                let width = '['.width1.':'.width2.']'
            endif
        elseif right_signal_link != {}
            let width = ''
            let resolved = 0
        else
            let width = ''
            let resolved = 0
        endif

        "   list of signal sequences
        "    0     1             2      3            4         5
        "   [type, specify type, width, signal_name, resolved, seq]
        let value = ['reg',type,width,name,resolved,seqs[0]]
        call extend(reg_names,{name : value})
        call extend(sig_names,{name : value})
    endfor
    "Get declared register
    let [decl_reg,auto_reg] = s:GetDeclReg(a:lines)
    "}}}3

"    "print reg test {{{3
"    for name in keys(reg_names)
"        let value = reg_names[name]
"        "    0     1             2      3            4         5
"        "   [type, specify type, width, signal_name, resolved, seq]
"        let width = value[2]
"        let type = value[1]
"        let resolved = value[4]
"        echo " name==" . name . repeat(" ",32-strlen(name)).
"                    \" width==" . width . repeat(" ",16-strlen(width)).
"                    \" type==" . type . repeat(" ",8-strlen(type)).
"                    \" resolved==" . resolved . repeat(" ",8-strlen(resolved))
"    endfor
"    "}}}3

    if a:mode == 'reg'
        return reg_names
    endif

    "awire{{{3
    "   list of width_names    
    "    0     1            2      3               4            5                6             7
    "   [seqs, signal_name, lines, left_width_nrs, left_widths, right_width_nrs, right_widths, right_signal_link]
    let wire_names = {}
    let awire_width_names = s:GetaWire(a:lines) 
    "remove awire exists in io
    if g:atv_autodef_wire_rmv_io == 1
        for name in keys(awire_width_names)
            if has_key(io_names,name)
                call remove(awire_width_names,name)
            endif
        endfor
    endif
    "record awire
    for name in keys(awire_width_names)
        let type = 'awire'
        let value = awire_width_names[name]
        let seqs = value[0]
        let left_width_nrs = value[3]
        let left_widths = value[4]
        let right_width_nrs = value[5]
        let right_widths = value[6]
        let right_signal_link = value[7]
        let resolved = 1
        if left_widths != []
            let [width1,width2] = left_widths[0]
            if width1 != ''
                if width2 != ''
                    let width = '['.width1.':'.width2.']'
                else
                    let width = '['.width1.']'
                endif
            else
                let width == ''
            endif
        elseif left_width_nrs != []
            let width1 = max(left_width_nrs)
            let width2 = min(left_width_nrs)
            if width1 == 0 && width2 == 0
                let width = ''
            else
                let width = '['.width1.':'.width2.']'
            endif
        elseif right_widths != []
            let [width1,width2] = right_widths[0]
            if width1 != ''
                if width2 != ''
                    let width = '['.width1.':'.width2.']'
                else
                    let width = '['.width1.']'
                endif
            else
                let width = ''
            endif
        elseif right_width_nrs != []
            let width1 = max(right_width_nrs)
            let width2 = min(right_width_nrs)
            if width1 == 0 && width2 == 0
                let width = ''
            else
                let width = '['.width1.':'.width2.']'
            endif
        elseif right_signal_link != {}
            let width = ''
            let resolved = 0
        else
            let width = ''
            let resolved = 0
        endif

        "   list of signal sequences
        "    0     1             2      3            4         5
        "   [type, specify type, width, signal_name, resolved, seq]
        let value = ['wire',type,width,name,resolved,seqs[0]]
        call extend(wire_names,{name : value})
        call extend(sig_names,{name : value})
    endfor
    "}}}3

    "iwire{{{3
    "   list of width_names
    "    0     1            2           3             4            5
    "   [seqs, signal_name, lines,      module_names, conn_widths, resolved]
    "Get module-file-dir dictionary
    let [files,modules] = g:AutoVerilog_GetModuleFileDirDic()

    "Get iwire
    "remove io, declared register and register from them
    let iwire_width_names = s:GetiWire(a:lines,files,modules,reg_width_names,decl_reg,io_names)
    "}}}3

"    "print awire test {{{3
"    for name in keys(sig_names)
"        "    0     1             2      3            4         5
"        "   [type, specify type, width, signal_name, resolved, seq]
"        let value = sig_names[name]
"        if value[1] == 'awire'
"            let width = value[2]
"            let resolved = value[4]
"            echo " name==" . name . repeat(" ",32-strlen(name)).
"                        \" width==" . width . repeat(" ",16-strlen(width)).
"                        \" resolved==" . resolved . repeat(" ",8-strlen(resolved))
"        endif
"    endfor
"    "}}}3
  
"    "print iwire test {{{3
"    for name in keys(iwire_width_names)
"        let value = iwire_width_names[name]
"        let widths = value[4]
"        let resolved = value[5]
"        echo " name==" . name . repeat(" ",32-strlen(name)).
"                    \" width==" . widths[0] . repeat(" ",16-strlen(widths[0])).
"                    \" resolved==" . resolved . repeat(" ",8-strlen(resolved))
"    endfor
"    "}}}3

    "wire{{{3
    for name in keys(iwire_width_names)
        let iwire_value = iwire_width_names[name]
        let iwire_resolved = iwire_value[5]
        let iwire_seqs = iwire_value[0]

        "iwire and awire duplicate
        if has_key(wire_names,name)
            let awire_value = wire_names[name]
            let awire_resolved = awire_value[4] 

            if awire_value[1] != 'awire'
                echohl ErrorMsg | echo "Error signal in inst wire but not an assign wire."| echohl None
            endif

            "use awire
            if awire_resolved == 1 && iwire_resolved == 0
            "use iwire
            else
                let conn_widths = iwire_value[4]
                let stype = iwire_value[6]
                "   list of signal sequences
                "    0     1             2      3            4         5
                "   [type, specify type, width, signal_name, resolved, seq]
                let value = ['wire',stype,conn_widths[-1],name,0,iwire_seqs[0]]
                call extend(sig_names,{name : value})
                call extend(wire_names,{name : value})
            endif
        "only iwire
        else
            let conn_widths = iwire_value[4]
            let stype = iwire_value[6]
            "   list of signal sequences
            "    0     1             2      3            4         5
            "   [type, specify type, width, signal_name, resolved, seq]
            let value = ['wire',stype,conn_widths[-1],name,iwire_resolved,iwire_seqs[0]]
            call extend(sig_names,{name : value})
            call extend(wire_names,{name : value})
        endif
    endfor
    "}}}3

"    "print all signal test {{{3
"    let io_sigs = {}
"    let reg_sigs = {}
"    let wire_sigs = {}
"    for name in keys(sig_names)
"        let value = sig_names[name]
"        let sig_type = value[0]
"        if sig_type == 'io'
"            call extend(io_sigs,{name : value})
"        endif
"        if sig_type == 'reg'
"            call extend(reg_sigs,{name : value})
"        endif
"        if sig_type == 'wire'
"            call extend(wire_sigs,{name : value})
"        endif
"    endfor
"
"    for name in keys(io_sigs)
"        let value = io_sigs[name]
"        let sig_type = value[0]
"        let type = value[1]
"        let width = value[2]
"        let resolved = value[4]
"        echo "type==". sig_type . repeat(" ", 8-strlen(sig_type)) . 
"                    \" name==" . name . repeat(" ",32-strlen(name)).
"                    \" dtype==" . type . repeat(" ",8-strlen(type)).
"                    \" width==" . width . repeat(" ",16-strlen(width)).
"    endfor
"
"    for name in keys(reg_sigs)
"        let value = reg_sigs[name]
"        let sig_type = value[0]
"        let type = value[1]
"        let width = value[2]
"        let resolved = value[4]
"        echo "type==". sig_type . repeat(" ", 8-strlen(sig_type)) . 
"                    \" name==" . name . repeat(" ",32-strlen(name)).
"                    \" dtype==" . type . repeat(" ",8-strlen(type)).
"                    \" width==" . width . repeat(" ",16-strlen(width)).
"                    \" resolved==" . resolved . repeat(" ",8-strlen(resolved))
"    endfor
"
"    for name in keys(wire_sigs)
"        let value = wire_sigs[name]
"        let sig_type = value[0]
"        let type = value[1]
"        let width = value[2]
"        let resolved = value[4]
"        echo "type==". sig_type . repeat(" ", 8-strlen(sig_type)) . 
"                    \" name==" . name . repeat(" ",32-strlen(name)).
"                    \" dtype==" . type . repeat(" ",8-strlen(type)).
"                    \" width==" . width . repeat(" ",16-strlen(width)).
"                    \" resolved==" . resolved . repeat(" ",8-strlen(resolved))
"    endfor
"    "}}}3
    
    if a:mode == 'wire'
        return wire_names
    endif

    return [sig_names,io_names,reg_width_names,awire_width_names,iwire_width_names]

endfunction
"}}}2

"}}}1

"Progressbar in the statusline 进度条显示{{{1
"Author      : politza@fh-trier.de
"Last change : 2007-09-01
"Version     : 1.0
if exists('*vim#widgets#progressbar#NewSimpleProgressBar')
    delfunction vim#widgets#progressbar#NewSimpleProgressBar
endif
let s:progressbar = {}
let s:cpo=&cpo
set cpo-=C
"Function: NewSimpleProgressBar {{{2
"Create a new progressbar 
"Args: title   : string
"      max_value : int
"      winnr   : int ( optional , default=current_win )
"Returns: new progressbar , if vim version supports it
"         {}              , if not
func! NewSimpleProgressBar(title, max_value, ...)
  if !has("statusline")
    return {}
  endif
  "Optional arg : winnr 
  let winnr = a:0 ? a:1 : winnr()
  let b = copy(s:progressbar)
  let b.title = a:title
  let b.max_value = a:max_value
  let b.cur_value = 0
  let b.winnr = winnr
  let b.items = { 'title' : { 'color' : 'Statusline' }, 'bar' : { 'fillchar' : ' ', 'color' : 'Statusline' , 'fillcolor' : 'DiffDelete' , 'bg' : 'Statusline' } , 'counter' : { 'color' : 'Statusline' } }
  let b.stl_save = getwinvar(winnr,"&statusline")
  let b.lst_save = &laststatus"
  return b
endfun
"}}}2
"Function: progressbar.setStyle {{{2
"Alter colors and the fillchar
"Args: item    : string ( title,bar or counter )
"      style   : hash , e.g. { 'color' : 'Comment' }
"
"valid style values :
"title   => color      : Highlight group
"counter => color      : Highlight group
"bar     => color      : Highlight group for the empty part of the bar,
"                        since it is empty only the bgcolor will be used.
"bar     => fillcolor  : Highlight group for the filled part of the bar.
"bar     => fillchar   : Char to use for the progressing bar, default is <space>.
func! s:progressbar.setStyle( item, style)
  if a:item !~? '^\(title\|bar\|counter\)$'
    throw "progressbar.setStyle : Unknown item -> ".a:item."!"
  elseif type(a:style) != type({})
    throw "progressbar.setStyle : arg#2 must be a hash !"
  endif
  for k in keys(a:style)
    let self.items[a:item][k] = a:style[k]
  endfor
endfun
"}}}2
"Function: progressbar.paint() {{{2
"(Re)paint the statusbar in the coressponding window.
"Note: Will automatically be called after a valid increment.
func! s:progressbar.paint()
  let max_len = winwidth(self.winnr)-1
  let t_len = strlen(self.title)+1+1
  let c_len  = 2*strlen(self.max_value)+1+1+1
  let pb_len = max_len - t_len - c_len - 2
  let cur_pb_len = (pb_len*self.cur_value)/self.max_value

  let t_color = self.items.title.color
  let b_fcolor = self.items.bar.fillcolor
  let b_color = self.items.bar.color
  let c_color = self.items.counter.color
  let fc= strpart(self.items.bar.fillchar." ",0,1)

  let stl =  "%#".t_color."#%-( ".self.title." %)".
            \"%#".b_color."#|".
            \"%#".b_fcolor."#%-(".repeat(fc,cur_pb_len)."%)".
            \"%#".b_color."#".repeat(" ",pb_len-cur_pb_len)."|".
            \"%=%#".c_color."#%( ".repeat(" ",(strlen(self.max_value) - strlen(self.cur_value))).self.cur_value."/".self.max_value."  %)"
  set laststatus=2
  call setwinvar(self.winnr,"&stl",stl)
  redraw
endfun
"}}}2
"Function: progressbar.restore() {{{2
"Restore the statusline to its former value
"Note: Always put this in a finally block,
"      that way the statusline will always
"      be restored.
func! s:progressbar.restore()
  call setwinvar(self.winnr,"&stl",self.stl_save)
  let &laststatus=self.lst_save
  redraw
endfun
"}}}2
"Function: progressbar.incr() {{{2
"Increment the statusbar.
"checks if newvalue > 0 && newvalue < max_value
"and repaints.
"Args: incr    : int ( positive or negative , default = +1 )
func! s:progressbar.incr( ... )
  let i = a:0 ? a:1 : 1
  let i+=self.cur_value
  let i = i < 0 ? 0 : i > self.max_value ?  self.max_value : i
  let self.cur_value = i
  call self.paint()
  return self.cur_value
endfun
"}}}2
let &cpo=s:cpo
unlet s:cpo
"}}}1

