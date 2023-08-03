"-----------------------------------------------------------------------------
" Vim Plugin for Verilog Code Automactic Generation 
" Author:         HonkW
" Website:        https://honk.wang
" Last Modified:  2023/08/03 18:12
" File:           autoinst.vim
" Note:           AutoInst function partly from zhangguo's vimscript
"------------------------------------------------------------------------------

"Sanity checks 启动判断{{{1
if exists("g:loaded_automatic_verilog_autoinst")
    finish
endif
let g:loaded_automatic_verilog_autoinst = 1
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

"AutoInst Config 自动例化配置
"+--------------+---------------------------------------------------------------------------------------+
"|    st_pos    |                                    start position                                     |
"+--------------+---------------------------------------------------------------------------------------+
"|   name_pos   |                                 signal name position                                  |
"+--------------+---------------------------------------------------------------------------------------+
"|   sym_pos    |                                 symbol name position                                  |
"+--------------+---------------------------------------------------------------------------------------+
"|    io_dir    |                    add //input or //output in the end of instance                     |
"+--------------+---------------------------------------------------------------------------------------+
"| io_dir_name  |                    default io_dir name, can be changed to 'I O IO'                    |
"+--------------+---------------------------------------------------------------------------------------+
"|   inst_new   |               add //INST_NEW if port has been newly added to the module               |
"+--------------+---------------------------------------------------------------------------------------+
"|   inst_del   |                add //INST_DEL if port has been deleted from the module                |
"+--------------+---------------------------------------------------------------------------------------+
"|   keep_chg   |                            keep changed inst io by changes                            |
"+--------------+---------------------------------------------------------------------------------------+
"|  keep_name   |                             keep changed inst io by name                              |
"+--------------+---------------------------------------------------------------------------------------+
"|    ls_cnt    |                                add left space after (                                 |
"+--------------+---------------------------------------------------------------------------------------+
"|    rs_cnt    |                               add right space before )                                |
"+--------------+---------------------------------------------------------------------------------------+
"| tail_nalign  |                       don't do alignment in tail when autoinst                        |
"+--------------+---------------------------------------------------------------------------------------+
"|  incl_cmnt   |              include comment line of // (/*...*/ will always be ignored)              |
"+--------------+---------------------------------------------------------------------------------------+
"|  incl_ifdef  |                           include ifdef like `ifdef `endif                            |
"+--------------+---------------------------------------------------------------------------------------+
"|  95_support  |                                 Support Verilog-1995                                  |
"+--------------+---------------------------------------------------------------------------------------+
"|   add_dir    |                            add //Instance ...directory...                             |
"+--------------+---------------------------------------------------------------------------------------+
"| add_dir_keep | add //Instance ...directory... but directory keep original format(ENV VAR like $HOME) |
"+--------------+---------------------------------------------------------------------------------------+
"| itf_support  |                                   iterface support                                    |
"+--------------+---------------------------------------------------------------------------------------+
"|  incl_width  |                             instance signal include width                             |
"+--------------+---------------------------------------------------------------------------------------+
let g:_ATV_AUTOINST_DEFAULTS = {
            \'st_pos':      4,
            \'name_pos':    32,
            \'sym_pos':     64,
            \'style':     0,
            \'ls_cnt':      0,
            \'rs_cnt':      0,
            \'tail_nalign': 0,    
            \'add_dir':     0,    
            \'add_dir_keep':0,
            \'tcmt_delim':  ' //',
            \'io_dir':      1,
            \'io_dir_name': 'input output inout interface',
            \'inst_new':    1,
            \'inst_tstp':   0,
            \'inst_tstp_fmt':"%Y.%m.%d %H:%M",
            \'inst_del':    1,
            \'usr_cmnt':    0,
            \'keep_chg':    1,        
            \'keep_name':   1,        
            \'incl_cmnt':   1,
            \'incl_ifdef':  1,    
            \'95_support':  0,    
            \'itf_support': 0,    
            \'incl_width':  1
            \}
for s:key in keys(g:_ATV_AUTOINST_DEFAULTS)
    if !exists('g:atv_autoinst_' . s:key)
        let g:atv_autoinst_{s:key} = copy(g:_ATV_AUTOINST_DEFAULTS[s:key])
    endif
endfor
"cfg pre process
let s:st_prefix = repeat(' ',g:atv_autoinst_st_pos)
let s:lspace = repeat(' ',g:atv_autoinst_ls_cnt)
let s:rspace = repeat(' ',g:atv_autoinst_rs_cnt)

if g:atv_autoinst_keep_chg == 0
    let g:atv_autoinst_keep_name = 0
endif

if g:atv_autoinst_tail_nalign == 0 
    let g:atv_autoinst_rs_cnt = 0
endif

"}}}1

"Keys 快捷键{{{1
amenu 9998.2.1 &Verilog.AutoInst.AutoInst(0)<TAB>One                             :call g:AutoInst(0)<CR>
amenu 9998.2.2 &Verilog.AutoInst.AutoInst(1)<TAB>All                             :call g:AutoInst(1)<CR>
amenu 9998.2.3 &Verilog.AutoInst.KillAutoInst(0)<TAB>One                         :call g:KillAutoInst(0)<CR>
amenu 9998.2.4 &Verilog.AutoInst.KillAutoInst(1)<TAB>All                         :call g:KillAutoInst(1)<CR>

if !hasmapto(':call g:AutoInst(0)<ESC>')
    map <S-F3>      :call g:AutoInst(0)<ESC>
endif
"}}}1

"AutoInst 自动例化{{{1
"--------------------------------------------------
" Function: AutoInst
" Input: 
"   mode : mode for autoinst
" Description:
"   autoinst for inst module
"   mode = 1, autoinst all instance
"   mode = 0, autoinst only one instance
" Output:
"   Formatted autoinst code
" Note:
"   list of port sequences
"            0     1         2       3       4       5            6          7     8      9
"   value = [type, sequence, io_dir, width1, width2, signal_name, last_port, line, width, first_port ]
"
"   io_seqs = {seq : value }
"   io_names = {signal_name : value }
"---------------------------------------------------
function! g:AutoInst(mode)
    "Get module-file-dir dictionary
    let [files,modules] = g:AutoVerilog_GetModuleFileDirDic()

    "Record current position
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
        "Put cursor to /*autoinst*/ line
        if search('\/\*autoinst\*\/','W') == 0
            break
        endif

        "Skip comment line //
        if getline('.') =~ '^\s*\/\/'
            continue
        endif

        "Get module_name & inst_name
        let [module_name,inst_name,idx1,idx2,idx3] = g:AutoVerilog_GetInstModuleName()

        "Get keep inst io & update inst io list 
        let keep_io_list = s:GetInstIO(getline(idx1,line('.')))
        let upd_io_list = s:GetInstIO(getline(line('.'),idx2))
        let chg_lines = getline(line('.'),idx2)

        "Get io sequences {sequence : value}
        if has_key(modules,module_name)
            let file = modules[module_name]
            let dir = files[file]
            "read file
            let lines = readfile(dir.'/'.file)
            "reserve only module lines, in case of multiple module in same file
            let lines = g:AutoVerilog_RsvModuleLine(lines,module_name)

            "get add_dir by g:atv_crossdir_dirs e.g. F:/vim/test.v ->$VIM/test.v
            if g:atv_autoinst_add_dir_keep == 1
                for exp_dir in keys(g:atv_crossdir_dirs)
                    if dir =~ escape(exp_dir,'\/')
                        let dir = substitute(dir,escape(exp_dir,'\/'),g:atv_crossdir_dirs[exp_dir],'')
                        break
                    endif
                endfor
            endif
            let add_dir = dir.'/'.file

            "io sequences
            let io_seqs = g:AutoVerilog_GetIO(lines,'seq')
            let io_names = g:AutoVerilog_GetIO(lines,'name')
        else
            echohl ErrorMsg | echo "No file with module name ".module_name." exist in cur dir ".getcwd() | echohl None
            if a:mode == 1
                continue
            elseif a:mode == 0
                return
            else
                echohl ErrorMsg | echo "Error input for AutoInst(),input mode = ".a:mode| echohl None
                return
            endif
        endif

        "Get changed inst io names && comment names
        let [chg_io_names,tcmt_names] = s:GetChangedInstIO(chg_lines,io_names)

        "Remove io from io_seqs that want to be keep when autoinst
        "   value = [type, sequence, io_dir, width1, width2, signal_name, last_port, line, width, first_port ]
        "   io_seqs = {sequence : value }
        "   io_names = {signal_name : value }
        for name in keep_io_list
            if has_key(io_names,name)
                let value = io_names[name]
                let seq = value[1]
                call remove(io_seqs,seq)
            endif
        endfor

        "Kill all contents under /*autoinst*/
        "Current position must be at /*autoinst*/ line
        call s:KillAutoInst()

        "Draw io port, use io_seqs to cover update io list
        "if io_seqs has new signal_name that's never in upd_io_list, add //INST_NEW
        "if io_seqs has same signal_name that's in upd_io_list, cover
        "if io_seqs doesn't have signal_name that's in upd_io_list, add //INST_DEL
        "if io_seqs connection has been changed, keep it
        "if io_seqs connection has comments, keep it
        let lines = s:DrawIO(io_seqs,upd_io_list,chg_io_names,tcmt_names)

        "Delete current line );
        let line = substitute(getline(line('.')),')\s*;','','')
        call setline(line('.'),line)
        "Append io port and );
        call add(lines,s:st_prefix.');')
        call append(line('.'),lines)

        "Add instance directory before autoinst
        if g:atv_autoinst_add_dir == 1
            let idx = idx3-1
            if getline(idx) =~ '^\s*/\/\Instance'
                if getline(idx) =~ '//Instance: '.add_dir
                else
                    call append(idx-1,s:st_prefix.'//Instance: '.add_dir)
                    let orig_dir_idx = line('.')
                    let orig_dir_col = col('.')
                    execute ':'.idx3.'d'
                    call cursor(orig_dir_idx,orig_dir_col)
                endif
            else
                call append(idx,s:st_prefix.'//Instance: '.add_dir)
            endif
        endif

        "mode = 0, only autoinst once
        if a:mode == 0
            break
        "mode = 1, autoinst all
        endif

    endwhile

    "Put cursor back to original position
    call cursor(orig_idx,orig_col)

endfunction
"}}}1

"KillAutoInst Kill自动例化{{{1
"--------------------------------------------------
" Function: KillAutoInst
" Input: 
"   mode : mode for kill autoinst
" Description:
"   autoinst for inst module
"   mode = 1, kill all autoinst instance
"   mode = 0, kill only one autoinst instance
" Output:
"   Killed autoinst code
"---------------------------------------------------
function! g:KillAutoInst(mode) abort

    "Record current position
    let orig_idx = line('.')
    let orig_col = col('.')

    "AutoInst all start from top line, AutoInst once start from first /*autoinst*/ line
    if a:mode == 1
        call cursor(1,1)
    elseif a:mode == 0
        call cursor(line('.'),1)
    else
        echohl ErrorMsg | echo "Error input for KillAutoInst(),input mode = ".a:mode| echohl None
        return
    endif

    while 1
        "Put cursor to /*autoinst*/ line
        if search('\/\*autoinst\*\/','W') == 0
            break
        endif

        "Skip comment line //
        if getline('.') =~ '^\s*\/\/'
            continue
        endif

        "Kill all contents under /*autoinst*/
        "Current position must be at /*autoinst*/ line
        call s:KillAutoInst()

        "mode = 0, only kill autoinst once
        if a:mode == 0
            break
        "mode = 1, kill autoinst all
        endif
    endwhile

    "cursor back
    call cursor(orig_idx,orig_col)

endfunction
"}}}1

"Sub Function 辅助函数{{{1

"AutoInst-Get
"AutoVerilog_GetIO 获取输入输出端口{{{2
"--------------------------------------------------
" Function: AutoVerilog_GetIO
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
"   [type, sequence, io_dir, width1, width2, signal_name, last_port, line, width, first_port ]
"   [wire,1,input,'c0','c0',clk,0,'       input       clk,','']
"   [reg,5,output,31,0,port_b,0,'    output reg [31:0] port_b','[31:0]']
" Output:
"   list of port sequences(including comment lines)
"    0     1         2       3       4       5            6          7     8      9
"   [type, sequence, io_dir, width1, width2, signal_name, last_port, line, width, first_port ]
"---------------------------------------------------
function g:AutoVerilog_GetIO(lines,mode)
    let idx = 0
    let seq = 0
    let wait_module = 1
    let wait_port = 1
    let func_flag = 0
    let interface_flag = 1
    let io_seqs = {}

    "get io seqs from line {{{3
    while idx < len(a:lines)
        let idx = idx + 1
        let idx = g:AutoVerilog_SkipCommentLine(2,idx,a:lines)  "skip pair comment line
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

        "skip function & endfunction
        if line =~ '^\s*function'
            let func_flag = 1
        endif
        if func_flag == 1
            if line =~ 'endfunction\s*$'
                let func_flag = 0
            else
                continue
            endif
        endif

        "no port definition, never record io_seqs
        if wait_port == 1 && line =~ ')\s*;' && len(io_seqs) > 0
            let seq = 0
            let io_seqs = {}
        endif

        if wait_module == 0
            "null line{{{4
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
                "           [type,  sequence, io_dir, width1, width2, signal_name, last_port, line, width, first_port ]
                let value = ['keep',seq,     '',     'c0',   'c0',   'NULL',       0,         '',   '',    '']
                call extend(io_seqs, {seq : value})
                let seq = seq + 1
            "}}}4

            " `ifdef `ifndef & single comment line {{{5
            elseif line =~ '^\s*\`\(if\|elsif\|else\|endif\)' || (line =~ '^\s*\/\/' && line !~ '^\s*\/\/\s*{{{')
                "           [type,  sequence, io_dir, width1, width2, signal_name, last_port, line, width, first_port ]
                let value = ['keep',seq,     '',     'c0',   'c0',    line,        0,         line, '',    '']
                call extend(io_seqs, {seq : value})
                let seq = seq + 1
            "}}}5
            "}}}4
            
            "input/output/inout ports{{{4
            elseif line =~ '^\s*'. s:VlogTypePorts || line =~ '^\s*(\s*'.s:VlogTypePorts || line =~ '^\s*,\s*'.s:VlogTypePorts
                let wait_port = 0
                "delete abnormal
                if line =~ '\<signed\>\|\<unsigned\>'
                    let line = substitute(line,'\<signed\>\|\<unsigned\>','','')
                elseif line =~ '\/\/.*$'
                    let line = substitute(line,'\/\/.*$','','')
                endif

                "type reg/wire
                let type = 'none'
                if line =~ '\<reg\>'
                    let type = 'reg'
                elseif line =~ '\<wire\>'
                    let type = 'wire'
                elseif line =~ '\<real\>'
                    let type = 'real'
                elseif line =~ '\<logic\>'
                    let type = 'logic'
                endif

                "io direction input/output/inout
                let io_dir = matchstr(line,s:VlogTypePorts)

                "width
                let width = matchstr(line,'\[.\{-\}\]')                 
                let width = substitute(width,'\s*','','g')          "delete redundant space
                let width1 = matchstr(width,'\v\[\zs\S+\ze:.*\]')   
                let width2 = matchstr(width,'\v\[.*:\zs\S+\ze\]')   

                if width == ''
                    let width1 = 'c0'
                    let width2 = 'c0'
                else
                    "[`DEFINT_PARA]
                    if width1 == '' && width2 == ''
                        let width1 = matchstr(width,'\[\zs.*\ze\]')
                        let width2 = 'c0'
                    "[5]
                    elseif width1 == ''
                        let width1 = 'c0'
                    elseif width2 == ''
                        let width2 = 'c0'
                    endif
                endif

                "name
                let line = substitute(line,io_dir,'','')
                let line = substitute(line,'\<reg\>\|\<wire\>\|\<real\>\|\<logic\>','','')
                let line = substitute(line,'\[.\{-\}\]','','')

                "ignore list like input [7:0] a[7:0];
                if line =~ '\[.*\]'
                    let width1 = 'c0'
                    let width2 = 'c0'
                    let line = substitute(line,'\[.*\]','','')
                endif

                "get width string
                if g:atv_autoinst_incl_width == 0       "if config,never output width
                    let width = ''
                elseif width2 == 'c0'
                    if width1 == 'c0' 
                        let width = ''
                    else
                        let width = '['.width1.']'
                    endif
                elseif width1 != 'c0'
                    let width = '['.width1.':'.width2.']'
                else
                    let width = ''
                endif

                "for types like input aa,bb,cc;
                let names = split(line,',')
                for name in names
                    let name = substitute(name,'\s*','','g')          "delete redundant space
                    let name = matchstr(name,'\w\+')
                    if name != ''
                        "dict       [type,sequence,io_dir, width1, width2, signal_name, last_port, line, width, first_port ]
                        let value = [type,seq,     io_dir, width1, width2, name,        0,         '',   width, '']
                        call extend(io_seqs, {seq : value})
                        let seq = seq + 1
                    endif
                endfor
            "}}}4

            "sv interface {{{4
            elseif (line =~ '^\s*'    . s:not_keywords_pattern.'\.\='.'\w*'.'\s\+'.'\w\+' 
              \ || line =~ '^\s*(\s*'. s:not_keywords_pattern.'\.\='.'\w*'.'\s\+'.'\w\+' 
              \ || line =~ '^\s*,\s*'. s:not_keywords_pattern.'\.\='.'\w*'.'\s\+'.'\w\+')
              \ && g:atv_autoinst_itf_support == 1

                let wait_port = 0

                "skip matcth outside module(); no interface
                if interface_flag == 0
                    continue
                endif

                "delete abnormal
                if line =~ '\/\/.*$'
                    let line = substitute(line,'\/\/.*$','','')
                endif

                "type interface,use line&signal_name as ifname&name
                let type = 'interface'
                let io_dir = 'interface'
                let ifname = matchstr(line,'\zs\w\+\.\=\w*\ze'.'\s\+'.'\w\+')
                let name = matchstr(line,'\w\+\.\=\w*'.'\s\+'.'\zs\w\+\ze')

                "           [type,  sequence, io_dir, width1, width2, signal_name, last_port, line,     width, first_port ]
                let value = [type,  seq,      io_dir, 'c0',   'c0',   name,        0,         ifname,   '',    '']
                call extend(io_seqs, {seq : value})
                let seq = seq + 1

                "for types like chip_bus a_bus,b_bus,c_bus; problem might exists
            endif
            "}}}4

            "break{{{4
            "abnormal break
            if line =~ '^\s*\<always\>' || line =~ '^\s*\<assign\>' || line =~ '^\s*\<endmodule\>'
                if wait_port == 1
                    echohl ErrorMsg | echo "Error when GetIO! No io port but always/assign/endmodule show up!"| echohl None
                endif
                break
            endif
            
            if line =~ ')\s*;\s*$' "find end of port declaration
                let interface_flag = 0     "break all interface
                "verilog-1995,input/output/inout may appear outside bracket
                "verilog-2001 or above, break here
                if g:atv_autoinst_95_support == 0
                    break
                endif
            endif
            "}}}4

        endif
    endwhile
    "}}}3

    "find last_port&first_port{{{3
    let seq = len(io_seqs)
    while seq >= 0
        let seq = seq - 1
        if has_key(io_seqs,seq)
            let value = io_seqs[seq]
            let type = value[0]
            if type !~ 'keep'
                let value[6] = 1
                call extend(io_seqs,{seq : value})
                break
            end
        endif
    endwhile
    let seq = -1
    while seq <= len(io_seqs)
        let seq = seq + 1
        if has_key(io_seqs,seq)
            let value = io_seqs[seq]
            let type = value[0]
            if type !~ 'keep'
                let value[9] = 1
                call extend(io_seqs,{seq : value})
                break
            end
        endif
    endwhile
    "}}}3

    "remove useless line{{{3
    let seq = len(io_seqs)
    while seq >= 0
        let seq = seq - 1
        if has_key(io_seqs,seq)
            let value = io_seqs[seq]
            let type = value[0]
            let line = value[7]
            if type =~ 'keep' && line =~ '^\s*$'
                call remove(io_seqs,seq)
            else
                break
            end
        endif
    endwhile
    let seq = 0
    while seq <= len(io_seqs)
        let seq = seq + 1
        if has_key(io_seqs,seq)
            let value = io_seqs[seq]
            let type = value[0]
            let line = value[7]
            if type =~ 'keep' && line =~ '^\s*$'
                call remove(io_seqs,seq)
            else
                break
            end
        endif
    endwhile
    "}}}3

    "output by mode{{{3
    if a:mode == 'seq'
        return io_seqs
    elseif a:mode == 'name'
        let io_names = {}
        for seq in keys(io_seqs)
            let value = io_seqs[seq]
            let name = value[5]
            call extend(io_names,{name : value})
        endfor
        return io_names
    else
        echohl ErrorMsg | echo "Error mode input for function GetIO! mode = ".a:mode| echohl None
    endif
    "}}}3

endfunction
"}}}2

"GetInstIO 获取例化端口{{{2
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
        let idx = g:AutoVerilog_SkipCommentLine(2,idx,a:lines)  "skip pair comment line
        if idx == -1
            echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
        endif

        let line = a:lines[idx-1]
        "delete // comment
        let line = substitute(line,'\/\/.*$','','')
        while line =~ '\.\s*\w\+\s*(.\{-\})'
            let port = matchstr(line,'\.\s*\zs\w\+\ze\s*(.\{-\})')
            call add(inst_io_list,port)
            let line = substitute(line,'\.\s*\w\+\s*(.\{-\})','','')
        endwhile
    endwhile
    return inst_io_list
endfunction
"}}}2

"GetChangedInstIO 获取修改过的例化端口{{{2
"--------------------------------------------------
" Function: GetChangedInstIO
" Input: 
"   lines : lines to get inst IO port
"   io_names = {signal_name : value }
" Description:
"   Get changed inst io port info from lines
"   Get user tail comment frome lines
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
"   dict of changed port (according to input lines)
"   e.g_1
"   cinst_names = {
"                   'clk':'s_clk'
"                   'rst':'s_rst'
"                   'in_test':'10'd0'
"                   'port_a':'port_a_o[4:0]'
"                 }
"---------------------------------------------------
function s:GetChangedInstIO(lines,io_names)
    let idx = 0
    let cinst_names = {}
    let tcmt_names = {}
    let io_names = copy(a:io_names)
    while idx < len(a:lines)
        let idx = idx + 1
        let idx = g:AutoVerilog_SkipCommentLine(2,idx,a:lines)  "skip pair comment line
        if idx == -1
            echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
        endif
        let line = a:lines[idx-1]
        if line =~ '\.\s*\w\+\s*(.*)'
            let inst_name = matchstr(line,'\.\s*\zs\w\+\ze\s*(.*)')
            "record user tail comment
            let tcmt = matchstr(line,'\/\/\zs[^/]*\ze$')                            "skip //...//...
            call extend(tcmt_names,{inst_name : tcmt})
            "record connection
            let conn = matchstr(line,'\.\s*\w\+\s*(\zs.*\ze\(\/\/.*\)\@<!)')        "connection,skip comment
            let conn = substitute(conn,'^\s*','','')                                "delete space from the start for alignment
            let conn = substitute(conn,'\s*$','','')                                "delete space in the end for alignment
            let conn_name = matchstr(conn,'\w\+')                                   "connection name
            if inst_name != conn_name
                call extend(cinst_names,{inst_name : conn})
            elseif has_key(io_names,inst_name)
                let value = io_names[inst_name]
                let type = value[0]
                if type != 'keep' 
                    let name = value[5]
                    let width = value[8]
                    let conn_inst = name.width
                endif
                "keep inst by signal name or by signal change
                if g:atv_autoinst_keep_name == 0
                    if conn_inst != conn
                        call extend(cinst_names,{inst_name : conn})
                    endif
                endif
            endif
        endif
    endwhile
    return [cinst_names,tcmt_names]
endfunction
"}}}2

"AutoVerilog_GetInstModuleName 获取例化名和模块名{{{2
"--------------------------------------------------
" Function: AutoVerilog_GetInstModuleName
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
"   idx3: line index of module_name
"---------------------------------------------------
function g:AutoVerilog_GetInstModuleName()
    "record original idx & col to cursor back to orginal place
    let orig_idx = line('.')
    let orig_col = col('.')

    "get module_name & inst_name by search function
    let idx = line('.')
    let inst_name = ''
    let module_name= ''
    let wait_semicolon_pair = 0
    let wait_module_name = 0

    while 1
        "skip function must have lines input
        let idx = g:AutoVerilog_SkipCommentLine(1,idx,getline(1,line('$')))
        if idx == -1
            echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
        endif
        "afer skip, still use current buffer
        let line = getline(idx)

        "abnormal break
        if wait_semicolon_pair == 1
            if idx == 0 || getline(idx) =~ '^\s*module' || getline(idx) =~ ');' || getline(idx) =~ '(.*)\s*;'
                echohl ErrorMsg | echo "Abnormal break when GetInstModuleName, idx = ".idx| echohl None
                let [module_name,inst_name,idx1,idx2,idx3] = ['','',0,0,0]
                break
            endif
        endif

        "get inst_name
        if line =~ '('
            let left_simicolon_list = []
            call substitute(line,'(','\=add(left_simicolon_list,submatch(0))','g')

            "find position of '('
            "in case of problem like 
            "   Register #(.WIDTH(32), .INIT(EXC_Vector_Base_Reset)) PC (
            "must get all column number of '('
            let col_match = line
            let cols = []
            let pos = 0

            while col_match =~ '('
                call add(cols,match(col_match,'(') + pos)
                let pos = pos + 1
                let col_match = substitute(col_match,'(','','')
            endwhile

            for col in cols
                call cursor(idx,col+1)
                "search for pair ()
                if searchpair('(','',')','nW') <= 0
                    let index = line('.')
                    let col = col('.')
                    echohl ErrorMsg | echo "() pair not-match in autoinst, line: ".index." colunm: ".col | echohl None
                    return
                else
                    "searchpair() may err pair when 
                    "( ..... //)
                    ")
                    "exist
                    "use % instead
                    execute 'normal %'
                    let index = line('.')
                    let col = col('.')
                endif
                "search for none-blank character,skip comment
                call search('\(\/\/.*\)\@<![^ \/]')
                "if it is ';' then pair
                if getline('.')[col('.')-1] == ';'
                    let wait_semicolon_pair = 1
                    break
                endif
                let wait_semicolon_pair = 0
            endfor

            if wait_semicolon_pair == 1
                "place cursor back to where ')' pair
                call cursor(index,col)

                "record ); position
                let idx2 = line('.')

                "call searchpair('(','',')','bW')
                execute 'normal %'

                "find position of inst_name,skip comment
                call search('\(\/\/.*\)\@<!\w\+','b')
                "get inst_name
                let inst_name = expand('<cword>')

                "record inst_name position
                let idx1 = line('.')

                let wait_module_name = 1
            endif
        endif

        "get module_name
        if wait_module_name == 1
            "search for last none-blank character,skip comment
            call search('\(\/\/.*\)\@<![^ \/]','bW')
            "parameter exists
            if getline('.')[col('.')-1] == ')'
                if searchpair('(','',')','bW','getline(".")=~"^\\s*\/\/"') > 0
                    let index = line('.')
                    let col = col('.')
                else
                    let index = line('.')
                    let col = col('.')
                    echohl ErrorMsg | echo "() pair not-match in parameter, line: ".index." colunm: ".col | echohl None
                endif
                call search('\(\/\/.*\)\@<!\w\+','bW')
            "find position of module_name,skip comment
            else
                call search('\(\/\/.*\)\@<!\w\+','bW')
            endif
            let module_name = expand('<cword>')

            "record module_name position
            let idx3 = line('.')
            break
        endif

        let idx = idx -1

    endwhile

    "cursor back
    call cursor(orig_idx,orig_col)

    "erorr process
    if module_name == '' || inst_name == ''
        echohl ErrorMsg | echo "Cannot find module_name or inst_name from ".orig_idx.','.orig_col | echohl None
        return ['','',0,0,0]
    endif

    return [module_name,inst_name,idx1,idx2,idx3]

endfunction
"}}}2

"AutoVerilog_RsvModuleLine 删除所有Module外的行{{{2
"--------------------------------------------------
" Function: AutoVerilog_RsvModuleLine()
"
" Description:
"   Remove lines outside specific module, reserve module lines
"   e.g
"   module a();
"     uart u_uart();
"   endmodule
"   module b();
"     uart #(para=2) u_uart ();
"   endmodule
"
"   --->AutoVerilog_RsvModuleLine(lines,a)
"
" Output:
"   module a();
"     uart #(para=2) u_uart ();
"   endmodule
"---------------------------------------------------
function g:AutoVerilog_RsvModuleLine(lines,module)
    let find_module = 0
    let in_module = 0
    let multiline_module = ''
    let proc_lines = []
    for line in a:lines
        "single line
        if line =~ '^\s*module'
            if line =~ '^\s*module'.'\s\+'.'\<'.a:module.'\>'
                call add(proc_lines,line)
                let in_module = 1
            elseif line =~ '^\s*module\s*$'
                let multiline_module = matchstr(line,'^\s*module')
                let find_module = 1
            else
                call add(proc_lines,'')
            endif
            continue
        endif
        "multi line
        if find_module == 1 && in_module == 0
            if line =~ '^\s*'.'\<'.a:module.'\>'
                call add(proc_lines,multiline_module)
                call add(proc_lines,line)
                let in_module = 1
                continue
            elseif line =~ '^\s*$' || line =~ '^\s*\/\/.*$'
                call add(proc_lines,line)
                continue
            else
                call add(proc_lines,'')
            endif
        endif
        "endmodule
        if in_module == 1
            call add(proc_lines,line)
            if line =~ 'endmodule'
                let in_module = 0
                continue
            endif
        "outisde module
        else
            call add(proc_lines,'')
        endif
    endfor

    return proc_lines
endfunction
"}}}2

"AutoInst-Kill
"KillAutoInst 删除所有输入输出端口例化{{{2
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
"}}}2

"AutoInst-Draw 
"DrawIO 按格式输出例化IO口{{{2
"--------------------------------------------------
" Function: DrawIO
" Input: 
"   io_seqs : new inst io sequences for align
"   io_list : old inst io name list
"   chg_io_names : old inst io names that has been changed
"   tcmt_names : old inst io names that has tail comments
"
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
function s:DrawIO(io_seqs,io_list,chg_io_names,tcmt_names)
    let prefix = s:st_prefix.repeat(' ',4)
    let io_list = copy(a:io_list)
    let chg_io_names = copy(a:chg_io_names)
    let tcmt_names = copy(a:tcmt_names)

    "guarantee spaces width{{{3
    let max_lbracket_len = 0
    let max_rbracket_len = 0
    for seq in sort(map(keys(a:io_seqs),'str2nr(v:val)'),g:atv_sort_funcref)
        let value = a:io_seqs[seq]
        let type = value[0]

        "calculate maximum len of position to Draw
        if type != 'keep' 
            let name = value[5]
            let width = value[8]
            let connect = name.width
            "io that's changed will be keeped if config 
            if g:atv_autoinst_keep_chg == 1
                if(has_key(chg_io_names,name))
                    let connect = chg_io_names[name]
                    "when use changed io, no lspace
                    let s:lspace = ''
                endif
            endif
            "prefix.'.'.name.name2bracket.'('.lspace.connect.width2bracket.')'
            if g:atv_autoinst_style == 0
                let max_lbracket_len = max([max_lbracket_len,len(prefix)+len('.')+len(name)+4,g:atv_autoinst_name_pos])
                let max_rbracket_len = max([max_rbracket_len,max_lbracket_len+len('(')+len(s:lspace)+len(connect)+4,g:atv_autoinst_sym_pos])
            "prefix.','.'.'.name.name2bracket.'('.lspace.connect.width2bracket.')'
            else
                let max_lbracket_len = max([max_lbracket_len,len(prefix)+len(',')+len('.')+len(name)+4,g:atv_autoinst_name_pos])
                let max_rbracket_len = max([max_rbracket_len,max_lbracket_len+len('(')+len(s:lspace)+len(connect)+4,g:atv_autoinst_sym_pos])
            endif
        endif
    endfor
    "}}}3

    "draw io{{{3
    let lines = []
    let last_port_flag = 0

    "io_list can be changed in function, therefore record if it's empty first
    if io_list == []
        let io_list_empty = 1
    else
        let io_list_empty = 0
    endif

    for seq in sort(map(keys(a:io_seqs),'str2nr(v:val)'),g:atv_sort_funcref)
        let value = a:io_seqs[seq]
        let type = value[0]
        let line = value[7]
        "add single comment/ifdef line{{{4
        if type == 'keep' 
            if line =~ '^\s*\/\/'
                if g:atv_autoinst_incl_cmnt == 1
                    let line = prefix.substitute(line,'^\s*','','')
                    call add(lines,line)
                else
                    "ignore comment line when not config
                endif
            elseif line =~ '^\s*\`\(if\|elsif\|else\|endif\)'
                if g:atv_autoinst_incl_ifdef == 1
                    let line = prefix.substitute(line,'^\s*','','')
                    call add(lines,line)
                else
                    "ignore ifdef line when not config
                endif
            endif
        "}}}4
        "add io line{{{4
        else
            "Format IO sequences
            "[type,  sequence, io_dir, width1, width2, signal_name, last_port, line, width, first_port ]
            "name
            let name = value[5]

            "name2bracket
            let name2bracket = repeat(' ',max_lbracket_len-len(prefix)-len(name)-len('.'))

            "lspace

            "width
            let width = value[8]

            "io that's changed will be keeped if config 
            let connect = name.width
            if g:atv_autoinst_keep_chg == 1
                if(has_key(chg_io_names,name))
                    let connect = chg_io_names[name]
                    "when use changed io, no lspace
                    let s:lspace = ''
                endif
            endif
            
            "width2bracket
            "don't align tail if config
            if g:atv_autoinst_tail_nalign == 1
                let width2bracket = ''
            else
                let width2bracket = repeat(' ',max_rbracket_len-max_lbracket_len-len('(')-len(s:lspace)-len(connect))
            endif

            "comma
            let last_port = value[6]
            let first_port = value[9]
            if g:atv_autoinst_style == 0
                if last_port == 1
                    let comma = ' '         "space
                    let last_port_flag = 1  "special case: last port has been put in keep_io_list, there exist no last_port
                else
                    let comma = ','         "comma exists
                endif
            else
                if first_port == 1
                    let comma = ' '         "space
                else
                    let comma = ','         "comma exists
                endif
            endif

            "io_dir
            let io_dir = value[2]
            let io_dir_name_list = split(g:atv_autoinst_io_dir_name)
            if io_dir == 'input'
                let io_dir = io_dir_name_list[0]
            elseif io_dir == 'output'
                let io_dir = io_dir_name_list[1]
            elseif io_dir == 'inout'
                let io_dir = io_dir_name_list[2]
            elseif io_dir == 'interface' && len(io_dir_name_list) == 4
                let io_dir = io_dir_name_list[3]
            endif

            "Draw IO by config
            if g:atv_autoinst_style == 0
                let line = prefix.'.'.name.name2bracket.'('.s:lspace.connect.width2bracket.')'.comma
            else
                let line = prefix.comma.'.'.name.name2bracket.'('.s:lspace.connect.width2bracket.')'
            endif

            "tail comment
            let tcmt = ''

            if g:atv_autoinst_io_dir == 1
                let tcmt = tcmt.g:atv_autoinst_tcmt_delim.io_dir
            endif

            "empty list, default
            "update list, draw io by config
            if io_list_empty == 0
                "process //INST_NEW
                let io_idx = index(io_list,name) 
                "name not exist in old io_list, add //INST_NEW
                if io_idx == -1
                    if g:atv_autoinst_inst_new == 1
                        let tcmt = tcmt.g:atv_autoinst_tcmt_delim.'INST_NEW'
                        "time stamp
                        if g:atv_autoinst_inst_tstp == 1
                            let tcmt = tcmt.g:atv_autoinst_tcmt_delim.'@'.strftime(g:atv_autoinst_inst_tstp_fmt)
                        endif
                    endif
                "name already exist in old io_list,cover
                else
                    call remove(io_list,io_idx)
                endif
            endif

            "process sv_interface
            if type == 'interface'
                let ifname = value[7]
                let tcmt = tcmt.g:atv_autoinst_tcmt_delim.ifname
            endif

            "add tail comment
            if tcmt != ''
                let tcmt =  substitute(tcmt,'\V'.escape(g:atv_autoinst_tcmt_delim,'\/'),'','')        "delete first delimiter
            endif

            let line = line.' //'.tcmt

            "add user tail comment
            if has_key(tcmt_names,name)
                let user_tcmt = tcmt_names[name]
                if g:atv_autoinst_usr_cmnt == 1 && user_tcmt != '' 
                    if (user_tcmt != io_dir) 
                                \ && (user_tcmt != 'INST_NEW')
                                \ && (user_tcmt != io_dir.g:atv_autoinst_tcmt_delim.'INST_NEW')
                        let line = line.' //'.user_tcmt
                    endif
                endif
            endif

            call add(lines,line)

            "in case special case happen(last port has been put in keep_io_list, there exist no last_port)
            "same time last line is not an io type, must record last_port index here
            let self_last_port_idx = index(lines,line) 

        endif
    "}}}4
    endfor

    "special case: last port has been put in keep_io_list, there exist no last_port
    if g:atv_autoinst_style == 0
        if last_port_flag == 0
            "set last item as last_port
            let lines[self_last_port_idx] = substitute(lines[self_last_port_idx],',',' ','') 
        endif
    "no speicial case for first port
    endif

    if io_list == []
    "remain port in io_list
    else
        if g:atv_autoinst_inst_del == 1
            for name in io_list
                let line = prefix.'//INST_DEL: Port '.name.' has been deleted.'
                "time stamp
                if g:atv_autoinst_inst_tstp == 1
                    let line = line.g:atv_autoinst_tcmt_delim.'@'.strftime(g:atv_autoinst_inst_tstp_fmt)
                endif
                call add(lines,line)
            endfor
        endif
    endif
    "}}}3

    if lines == []
        echohl ErrorMsg | echo "Error io_seqs input for function DrawIO! io_seqs has no input/output definition! Possibly written in verilog-95 but atv_autoinst_95_support not open, or bracket not match in inst list " | echohl None
    endif

    return lines

endfunction
"}}}2

"}}}1

