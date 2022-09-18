"-----------------------------------------------------------------------------
" Vim Plugin for Verilog Code Automactic Generation 
" Author:         HonkW
" Website:        https://honk.wang
" Last Modified:  2022/09/18 11:45
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

"Port 端口类型
let s:VlogTypePort =                  '\<input\>\|'
let s:VlogTypePort = s:VlogTypePort . '\<output\>\|'
let s:VlogTypePort = s:VlogTypePort . '\<inout\>'
let s:VlogTypePorts = '\(' . s:VlogTypePort . '\)'

"AutoInst Config 自动例化配置
"+--------------+-------------------------------------------------------------+
"|    st_pos    |                       start position                        |
"+--------------+-------------------------------------------------------------+
"|   name_pos   |                    signal name position                     |
"+--------------+-------------------------------------------------------------+
"|   sym_pos    |                    symbol name position                     |
"+--------------+-------------------------------------------------------------+
"|    io_dir    |       add //input or //output in the end of instance        |
"+--------------+-------------------------------------------------------------+
"| io_dir_name  |       default io_dir name, can be changed to 'I O IO'       |
"+--------------+-------------------------------------------------------------+
"|   inst_new   |  add //INST_NEW if port has been newly added to the module  |
"+--------------+-------------------------------------------------------------+
"|   inst_del   |   add //INST_DEL if port has been deleted from the module   |
"+--------------+-------------------------------------------------------------+
"|   keep_chg   |                    keep changed inst io                     |
"+--------------+-------------------------------------------------------------+
"|  incl_cmnt   | include comment line of // (/*...*/ will always be ignored) |
"+--------------+-------------------------------------------------------------+
"|  incl_ifdef  |              include ifdef like `ifdef `endif               |
"+--------------+-------------------------------------------------------------+
"|  95_support  |                    Support Verilog-1995                     |
"+--------------+-------------------------------------------------------------+
"| tail_nalign  |          don't do alignment in tail when autoinst           |
"+--------------+-------------------------------------------------------------+
"|   add_dir    |               add //Instance ...directory...                |
"+--------------+-------------------------------------------------------------+
"| add_dir_keep |     directory keep original format(ENV VAR like $HOME)      |
"+--------------+-------------------------------------------------------------+
let g:_ATV_AUTOINST_DEFAULTS = {
            \'st_pos':      4,
            \'name_pos':    32,
            \'sym_pos':     64,
            \'io_dir':      1,
            \'io_dir_name': 'input output inout',
            \'inst_new':    1,
            \'inst_del':    1,
            \'keep_chg':    1,        
            \'incl_cmnt':   1,
            \'incl_ifdef':  1,    
            \'95_support':  0,    
            \'tail_nalign': 0,    
            \'add_dir':     0,    
            \'add_dir_keep':0,
            \'incl_width':  1    
            \}
for s:key in keys(g:_ATV_AUTOINST_DEFAULTS)
    if !exists('g:atv_autoinst_' . s:key)
        let g:atv_autoinst_{s:key} = copy(g:_ATV_AUTOINST_DEFAULTS[s:key])
    endif
endfor
let s:st_prefix = repeat(' ',g:atv_autoinst_st_pos)
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
"            0     1        2       3       4       5            6          7
"   value = [type, sequence,io_dir, width1, width2, signal_name, last_port, line ]
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

        "Get changed inst io names
        let chg_io_names = s:GetChangedInstIO(chg_lines,io_names)

        "Remove io from io_seqs that want to be keep when autoinst
        "   value = [type, sequence, io_dir, width1, width2, signal_name, last_port, line ]
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
        let lines = s:DrawIO(io_seqs,upd_io_list,chg_io_names)

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
"   [type, sequence, io_dir, width1, width2, signal_name, last_port, line ]
"   [wire,1,input,'c0','c0',clk,0,'       input       clk,']
"   [reg,5,output,31,0,port_b,0,'    output reg [31:0] port_b']
" Output:
"   list of port sequences(including comment lines)
"    0     1         2       3       4       5            6          7
"   [type, sequence, io_dir, width1, width2, signal_name, last_port, line ]
"---------------------------------------------------
function g:AutoVerilog_GetIO(lines,mode)
    let idx = 0
    let seq = 0
    let wait_module = 1
    let wait_port = 1
    let func_flag = 0
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
                "           [type,  sequence, io_dir, width1, width2, signal_name, last_port, line ]
                let value = ['keep',seq,     '',     'c0',   'c0',   'NULL',          0,         '']
                call extend(io_seqs, {seq : value})
                let seq = seq + 1
            "}}}4

            " `ifdef `ifndef & single comment line {{{4
            elseif line =~ '^\s*\`\(if\|elsif\|else\|endif\)' || (line =~ '^\s*\/\/' && line !~ '^\s*\/\/\s*{{{')
                "           [type,  sequence, io_dir, width1, width2, signal_name, last_port, line ]
                let value = ['keep',seq,     '',     'c0',   'c0',   line,        0,         line]
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

                "for types like input aa,bb,cc;
                let names = split(line,',')
                for name in names
                    let name = substitute(name,'\s*','','g')          "delete redundant space
                    let name = matchstr(name,'\w\+')
                    if name != ''
                        "dict       [type,sequence,io_dir, width1, width2, signal_name, last_port, line ]
                        let value = [type,seq,     io_dir, width1, width2, name,        0,         '']
                        call extend(io_seqs, {seq : value})
                        let seq = seq + 1
                    endif
                endfor
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
            
            "verilog-1995,input/output/inout may appear outside bracket
            if g:atv_autoinst_95_support == 1
            "verilog-2001 or above
            else
                if line =~ ')\s*;\s*$' "normal break, find end of port declaration
                    break
                endif
            endif
            "}}}4

        endif
    endwhile
    "}}}3

    "find last_port{{{3
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
    "}}}3

    "remove last useless line{{{3
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
    "}}}3

    "remove first useless line{{{3
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
            let conn = matchstr(line,'\.\s*\w\+\s*(\zs.*\ze\(\/\/.*\)\@<!)')        "connection,skip comment
            let conn = substitute(conn,'\s*$','','')                                "delete space in the end for alignment
            let conn_name = matchstr(conn,'\w\+')                                   "connection name
            if inst_name != conn_name
                call extend(cinst_names,{inst_name : conn})
            elseif has_key(io_names,inst_name)
                let value = io_names[inst_name]
                let type = value[0]
                if type != 'keep' 
                    let name = value[5]
                    if g:atv_autoinst_incl_width == 0       "if config,never output width
                        let width = ''
                    elseif value[4] == 'c0'
                        if value[3] == 'c0' 
                            let width = ''
                        else
                            let width = '['.value[3].']'
                        endif
                    elseif value[3] != 'c0'
                        let width = '['.value[3].':'.value[4].']'
                    else
                        let width = ''
                    endif
                    let conn_inst = name.width
                endif
                if conn_inst != conn
                    call extend(cinst_names,{inst_name : conn})
                endif
            endif
        endif
    endwhile
    return cinst_names
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
                if searchpair('(','',')') > 0
                    let index = line('.')
                    let col = col('.')
                else
                    let index = line('.')
                    let col = col('.')
                    echohl ErrorMsg | echo "() pair not-match in autoinst, line: ".index." colunm: ".col | echohl None
                    return
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

                call searchpair('(','',')','bW')
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
function s:DrawIO(io_seqs,io_list,chg_io_names)
    let prefix = s:st_prefix.repeat(' ',4)
    let io_list = copy(a:io_list)
    let chg_io_names = copy(a:chg_io_names)

    "guarantee spaces width{{{3
    let max_lbracket_len = 0
    let max_rbracket_len = 0
    for seq in sort(map(keys(a:io_seqs),'str2nr(v:val)'),g:atv_sort_funcref)
        let value = a:io_seqs[seq]
        let type = value[0]

        if type != 'keep' 
            let name = value[5]
            "calculate maximum len of position to Draw
            if g:atv_autoinst_incl_width == 0       "if config,never output width
                let width = ''
            elseif value[4] == 'c0'
                if value[3] == 'c0' 
                    let width = ''
                else
                    let width = '['.value[3].']'
                endif
            elseif value[3] != 'c0'
                let width = '['.value[3].':'.value[4].']'
            else
                let width = ''
            endif
            "io that's changed will be keeped if config 
            let connect = name.width
            if g:atv_autoinst_keep_chg == 1
                if(has_key(chg_io_names,name))
                    let connect = chg_io_names[name]
                endif
            endif
            "prefix.'.'.name.name2bracket.'('.connect.width2bracket.')'
            let max_lbracket_len = max([max_lbracket_len,len(prefix)+len('.')+len(name)+4,g:atv_autoinst_name_pos])
            let max_rbracket_len = max([max_rbracket_len,max_lbracket_len+len('(')+len(connect)+4,g:atv_autoinst_sym_pos])
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
            "   [type, sequence, io_dir, width1, width2, signal_name, last_port, line ]
            "name
            let name = value[5]

            "name2bracket
            let name2bracket = repeat(' ',max_lbracket_len-len(prefix)-len(name)-len('.'))
            "width
            if g:atv_autoinst_incl_width == 0       "if config,never output width
                let width = ''
            elseif value[4] == 'c0'
                if value[3] == 'c0' 
                    let width = ''
                else
                    let width = '['.value[3].']'
                endif
            elseif value[3] != 'c0'
                let width = '['.value[3].':'.value[4].']'
            else
                let width = ''
            endif

            "io that's changed will be keeped if config 
            let connect = name.width
            if g:atv_autoinst_keep_chg == 1
                if(has_key(chg_io_names,name))
                    let connect = chg_io_names[name]
                endif
            endif
            
            "width2bracket
            "don't align tail if config
            if g:atv_autoinst_tail_nalign == 1
                let width2bracket = ''
            else
                let width2bracket = repeat(' ',max_rbracket_len-max_lbracket_len-len('(')-len(connect))
            endif

            "comma
            let last_port = value[6]
            if last_port == 1
                let comma = ' '         "space
                let last_port_flag = 1  "special case: last port has been put in keep_io_list, there exist no last_port
            else
                let comma = ','      "comma exists
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
            endif

            "Draw IO by config
            "empty list, default
            if io_list_empty == 1
                if g:atv_autoinst_io_dir == 1
                    let line = prefix.'.'.name.name2bracket.'('.connect.width2bracket.')'.comma.' //'.io_dir
                else
                    let line = prefix.'.'.name.name2bracket.'('.connect.width2bracket.')'.comma
                endif
            "update list,draw io by config
            else
                if g:atv_autoinst_io_dir == 1
                    let line = prefix.'.'.name.name2bracket.'('.connect.width2bracket.')'.comma.' //'.io_dir
                else
                    let line = prefix.'.'.name.name2bracket.'('.connect.width2bracket.')'.comma
                endif
                "process //INST_NEW
                let io_idx = index(io_list,name) 
                "name not exist in old io_list, add //INST_NEW
                if io_idx == -1
                    if g:atv_autoinst_inst_new == 1
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

            "in case special case happen(last port has been put in keep_io_list, there exist no last_port)
            "same time last line is not an io type, must record last_port index here
            let self_last_port_idx = index(lines,line) 

        endif
    "}}}4
    endfor

    "special case: last port has been put in keep_io_list, there exist no last_port
    if last_port_flag == 0
        "set last item as last_port
        let lines[self_last_port_idx] = substitute(lines[self_last_port_idx],',',' ','') 
    endif

    if io_list == []
    "remain port in io_list
    else
        if g:atv_autoinst_inst_del == 1
            for name in io_list
                let line = prefix.'//INST_DEL: Port '.name.' has been deleted.'
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

