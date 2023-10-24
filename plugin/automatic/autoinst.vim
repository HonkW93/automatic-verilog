"-----------------------------------------------------------------------------
" Vim Plugin for Verilog Code Automactic Generation 
" Author:         HonkW
" Website:        https://honk.wang
" Last Modified:  2023/10/24 17:52
" File:           autoinst.vim
" Note:           AutoInst function partly from zhangguo's vimscript
"------------------------------------------------------------------------------

"Sanity checks 启动判断{{{1
if exists("g:loaded_automatic_verilog_autoinst")
    finish
endif
let g:loaded_automatic_verilog_autoinst = 1
let s:sfile = fnamemodify(expand("<sfile>"),":t")
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
"+------------------+----------------------------------------------------------------------------------------------+
"| pos_st_auto      | auto detect start position of autoinst                                                       |
"+------------------+----------------------------------------------------------------------------------------------+
"| pos_st           | manual start position of autoinst (valid only when pos_st_auto invalid)                      |
"+------------------+----------------------------------------------------------------------------------------------+
"| pos_lbls         | position of left bracket left space (number of spaces)                                       |
"+------------------+----------------------------------------------------------------------------------------------+
"| pos_lb           | position of left bracket                                                                     |
"+------------------+----------------------------------------------------------------------------------------------+
"| pos_lbrs         | position of left bracket right space (number of spaces)                                      |
"+------------------+----------------------------------------------------------------------------------------------+
"| pos_rbls         | position of right bracket left space (number of spaces)                                      |
"+------------------+----------------------------------------------------------------------------------------------+
"| pos_rb           | position of right bracket                                                                    |
"+------------------+----------------------------------------------------------------------------------------------+
"| pos_rbrs         | position of right bracket right space (number of spaces)                                     |
"+------------------+----------------------------------------------------------------------------------------------+
"| pos_lalgn        | position - align left bracket                                                                |
"+------------------+----------------------------------------------------------------------------------------------+
"| pos_ralgn        | position - align right bracket                                                               |
"+------------------+----------------------------------------------------------------------------------------------+
"| pos_comma        | position - comma in the start of the line                                                    |
"+------------------+----------------------------------------------------------------------------------------------+
"| cmt_dir          | head comment add for directory of the instance //Instance...                                 |
"+------------------+----------------------------------------------------------------------------------------------+
"| cmt_dir_env      | head comment add for directory of the instance, but use original environment name like $HOME |
"+------------------+----------------------------------------------------------------------------------------------+
"| cmt_delim        | line comment delimiter, deafult " //"                                                        |
"+------------------+----------------------------------------------------------------------------------------------+
"| cmt_iodir        | line comment add for io direction like //input //output //inout or //interface               |
"+------------------+----------------------------------------------------------------------------------------------+
"| cmt_instnew      | line comment add for new inst //INST_NEW                                                     |
"+------------------+----------------------------------------------------------------------------------------------+
"| cmt_instnew_tstp | line comment add timestamp for new inst //INST_NEW @2023.8.1                                 |
"+------------------+----------------------------------------------------------------------------------------------+
"| cmt_instdel      | line comment add for deleted inst //INST_DEL                                                 |
"+------------------+----------------------------------------------------------------------------------------------+
"| cmt_instnew_tstp | line comment add timestamp for deleted inst //INST_DEL @2023.8.1                             |
"+------------------+----------------------------------------------------------------------------------------------+
"| cmt_usr          | line comment add user own comment                                                            |
"+------------------+----------------------------------------------------------------------------------------------+
"| incl_cmt         | include comment line of // (/*...*/ will always be ignored)                                  |
"+------------------+----------------------------------------------------------------------------------------------+
"| incl_width       | include instance signal width like a[7:0]                                                    |
"+------------------+----------------------------------------------------------------------------------------------+
"| keep_chg         | keep changed inst io by 'name' or 'full'                                                     |
"+------------------+----------------------------------------------------------------------------------------------+
"| 95_support       | support verilog-1995                                                                         |
"+------------------+----------------------------------------------------------------------------------------------+
"| itf_support      | support interface (beta version)                                                             |
"+------------------+----------------------------------------------------------------------------------------------+
"| tpl_support      | support template                                                                             |
"+------------------+----------------------------------------------------------------------------------------------+
let g:_AUTOVERILOG_AUTOINST_DEFAULTS = {
            \'pos_st_auto':         1,
            \'pos_st':              4,
            \'pos_lbls':            1,
            \'pos_lb':              32,
            \'pos_lbrs':            0,
            \'pos_rbls':            1,
            \'pos_rb':              64,
            \'pos_rbrs':            1,
            \'pos_lalgn':           1,
            \'pos_ralgn':           1,
            \'pos_comma':           0,
            \'cmt_dir':             0,
            \'cmt_dir_env':         0,
            \'cmt_delim':           ' //',
            \'cmt_iodir':           ' ',
            \'cmt_instnew':         1,
            \'cmt_instnew_tstp':    '',
            \'cmt_instdel':         1,
            \'cmt_instdel_tstp':    '',
            \'cmt_usr':             0,
            \'incl_cmt':            1,
            \'incl_ifdef':          1,    
            \'incl_width':          1,
            \'keep_chg':            'name',        
            \'95_support':          0,    
            \'itf_support':         0,    
            \'tpl_support':         0
            \}

for s:key in keys(g:_AUTOVERILOG_AUTOINST_DEFAULTS)
    if !exists('g:atv_ati_' . s:key)
        let g:atv_ati_{s:key} = copy(g:_AUTOVERILOG_AUTOINST_DEFAULTS[s:key])
    endif
endfor

"cfg pre process
let s:st_prefix = repeat(' ',g:atv_ati_pos_st)         "start position prefix

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
"   value = [type, sequence, iodir, width1, width2, signal_name, last_port, line, width, first_port ]
"
"   io_seqs = {seq : value }
"   io_names = {signal_name : value }
"---------------------------------------------------
function! g:AutoInst(mode)
    "Get module-file-dir dictionary
    let [files,modules] = g:ATV_GetModFileDir()

    "Record current position
    let orig_idx = line('.')
    let orig_col = col('.')

    "AutoInst all start from top line
    "AutoInst once start from first /*autoinst*/ line
    if a:mode == 1
        call cursor(1,1)
    else
        call cursor(line('.'),1)
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

        "Get module name 
        "Get inst name
        "Get idx1: line index of inst
        "Get idx2: line index of );
        "Get idx3: line index of module
        let [mname,iname,idx1,idx2,idx3] = g:ATV_GetInstModName()

        "Get io sequences {sequence : value}
        if has_key(modules,mname)
            let file = modules[mname]
            let dir = files[file]
            "read file
            let lines = readfile(dir.'/'.file)
            "reserve module lines, in case multiple module in same file
            let lines = g:ATV_GetModLine(lines,mname)
            "get comment directory by g:atv_crossdir_dirs e.g. F:/vim/test.v ->$VIM/test.v
            if g:atv_ati_cmt_dir_env == 1
                for exp_dir in keys(g:atv_crossdir_dirs)
                    if dir == exp_dir
                        let dir = g:atv_crossdir_dirs[exp_dir]
                        break
                    endif
                endfor
            endif
            if has('win32') || has('win64')
                let delim = '\'
            else
                let delim = '/'
            endif
            let cmt_dir = dir.delim.file
            let io_seqs = g:ATV_GetIO(lines,'seq')
            let io_names = g:ATV_GetIO(lines,'name')
        else
            call g:ATV_ErrEchohl("1","[".s:sfile."-".expand("<sflnum>")."]","Error Get Module. No file with module name ".mname." exist!")
            if a:mode == 1
                continue
            else 
                return
            endif
        endif

        let keep_io_names = s:GetInstIO(getline(idx1,line('.')),io_names)
        let upd_io_names = s:GetInstIO(getline(line('.'),idx2),io_names)

        "Remove io from io_seqs that want to be keep when autoinst
        "   value = [type, sequence, iodir, width1, width2, signal_name, last_port, line, width, first_port ]
        "   io_seqs = {sequence : value }
        "   io_names = {signal_name : value }
        for name in keys(keep_io_names)
            if has_key(io_names,name)
                let value = io_names[name]
                let seq = value[1]
                call remove(io_seqs,seq)
            endif
        endfor

        "Kill all contents under /*autoinst*/
        "Current position must be at /*autoinst*/ line
        call s:KillAutoInst()

        "Draw io port, use io_seqs & upd_io_names
        "if io_seqs has new signal name that's never in upd_io_names, add //INST_NEW
        "if io_seqs has same signal name that's in upd_io_names, cover
        "if io_seqs doesn't have signal name that's in upd_io_names, add //INST_DEL
        "if io_seqs connection in upd_io_names have been changed, keep it
        "if io_seqs connection in upd_io_names have comments, keep it
        let lines = s:DrawIO(io_seqs,upd_io_names)

        "Delete current line );
        let line = substitute(getline(line('.')),')\s*;','','')
        call setline(line('.'),line)
        "Append io port and );
        call add(lines,s:st_prefix.');')
        call append(line('.'),lines)

        "Add instance directory before autoinst
        if g:atv_ati_cmt_dir == 1
            let idx = idx3-1
            if getline(idx) =~ '^\s*/\/\Instance'
                if getline(idx) =~ '//Instance: '.cmt_dir
                else
                    call append(idx-1,s:st_prefix.'//Instance: '.cmt_dir)
                    let orig_dir_idx = line('.')
                    let orig_dir_col = col('.')
                    execute ':'.idx3.'d'
                    call cursor(orig_dir_idx,orig_dir_col)
                endif
            else
                call append(idx,s:st_prefix.'//Instance: '.cmt_dir)
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

    "AutoInst all start from top line
    "AutoInst once start from first /*autoinst*/ line
    if a:mode == 1
        call cursor(1,1)
    else
        call cursor(line('.'),1)
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
"ATV_GetIO 获取输入输出端口{{{2
"--------------------------------------------------
" Function: ATV_GetIO
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
"   [type, sequence, iodir, width1, width2, signal_name, last_port, line, width, first_port ]
"   [wire,1,input,'c0','c0',clk,0,'       input       clk,','']
"   [reg,5,output,31,0,port_b,0,'    output reg [31:0] port_b','[31:0]']
" Output:
"   list of port sequences(including comment lines)
"    0     1         2       3       4       5            6          7     8      9
"   [type, sequence, iodir, width1, width2, signal_name, last_port, line, width, first_port ]
"---------------------------------------------------
function g:ATV_GetIO(lines,mode)
    let idx = 0
    let seq = 0
    let wait_module = 1
    let wait_port = 1
    let func_flag = 0
    let itf_flag = 1
    let io_seqs = {}

    "get io seqs from line {{{3
    while idx < len(a:lines)
        let idx = idx + 1
        let idx = g:ATV_SkipCmtLine(2,idx,a:lines)  "skip pair comment line
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
                "           [type,  sequence, iodir, width1, width2, signal_name, last_port, line, width, first_port ]
                let value = ['keep',seq,     '',     'c0',   'c0',   'NULL',       0,         '',   '',    '']
                call extend(io_seqs, {seq : value})
                let seq = seq + 1
            "}}}4

            " `ifdef `ifndef & single comment line {{{5
            elseif line =~ '^\s*\`\(if\|elsif\|else\|endif\)' || (line =~ '^\s*\/\/' && line !~ '^\s*\/\/\s*{{{')
                "           [type,  sequence, iodir, width1, width2, signal_name, last_port, line, width, first_port ]
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
                let iodir = matchstr(line,s:VlogTypePorts)

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
                let line = substitute(line,iodir,'','')
                let line = substitute(line,'\<reg\>\|\<wire\>\|\<real\>\|\<logic\>','','')
                let line = substitute(line,'\[.\{-\}\]','','')

                "ignore list like input [7:0] a[7:0];
                if line =~ '\[.*\]'
                    let width1 = 'c0'
                    let width2 = 'c0'
                    let line = substitute(line,'\[.*\]','','')
                endif

                "get width string
                if g:atv_ati_incl_width == 0       "if config,never output width
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
                        "dict       [type,sequence,iodir, width1, width2, signal_name, last_port, line, width, first_port ]
                        let value = [type,seq,     iodir, width1, width2, name,        0,         '',   width, '']
                        call extend(io_seqs, {seq : value})
                        let seq = seq + 1
                    endif
                endfor
            "}}}4

            "sv interface {{{4
            elseif (line =~ '^\s*'    . s:not_keywords_pattern.'\.\='.'\w*'.'\s\+'.'\w\+' 
              \ || line =~ '^\s*(\s*'. s:not_keywords_pattern.'\.\='.'\w*'.'\s\+'.'\w\+' 
              \ || line =~ '^\s*,\s*'. s:not_keywords_pattern.'\.\='.'\w*'.'\s\+'.'\w\+')
              \ && g:atv_ati_itf_support == 1
                let wait_port = 0

                "skip matcth outside module(); no interface
                if itf_flag == 0
                    continue
                endif

                "delete abnormal
                if line =~ '\/\/.*$'
                    let line = substitute(line,'\/\/.*$','','')
                endif

                "type interface,use line&signal_name as ifname&name
                let type = 'interface'
                let iodir = 'interface'
                let ifname = matchstr(line,'\zs\w\+\.\=\w*\ze'.'\s\+'.'\w\+')
                let name = matchstr(line,'\w\+\.\=\w*'.'\s\+'.'\zs\w\+\ze')

                "           [type,  sequence, iodir, width1, width2, signal_name, last_port, line,     width, first_port ]
                let value = [type,  seq,      iodir, 'c0',   'c0',   name,        0,         ifname,   '',    '']
                call extend(io_seqs, {seq : value})
                let seq = seq + 1

                "for types like chip_bus a_bus,b_bus,c_bus; problem might exists
            endif
            "}}}4

            "break{{{4
            "abnormal break
            if line =~ '^\s*\<always\>' || line =~ '^\s*\<assign\>' || line =~ '^\s*\<endmodule\>'
                if wait_port == 1
                    call g:ATV_ErrEchohl("3","[".s:sfile."-".expand("<sflnum>")."]","Error GetIO. No io port but always/assign/endmodule show up!")
                endif
                break
            endif
            
            if line =~ ')\s*;\s*$' "find end of port declaration
                "verilog-1995,input/output/inout may appear outside bracket
                "verilog-2001 or above, break here
                if g:atv_ati_95_support == 0
                    break
                endif
                let itf_flag = 0   "break all interface
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
            if type =~ 'keep' && (line =~ '^\s*$') || (line =~ '^\s*\/\/.*$')
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
    else
        let io_names = {}
        for seq in keys(io_seqs)
            let value = io_seqs[seq]
            let name = value[5]
            call extend(io_names,{name : value})
        endfor
        return io_names
    endif
    "}}}3

endfunction
"}}}2

"GetInstIO 获取例化端口{{{2
"--------------------------------------------------
" Function: GetInstIO
" Input: 
"   lines : lines to get inst IO port
"   io_names : old io-name dictionary
" Description:
"   Get inst io port info from lines
"   e.g_1
"   module_name #(
"       .A_PARAMETER (A_PARAMETER)
"       .B_PARAMETER (B_PARAMETER)
"   )
"   inst_name
"   (
"       .clk(clk),      //test
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
"    .port_b(conn_b)
"   );
"
" Output:
"   inst_names : dictionary of port sequences(according to input lines)
"   [port, connection,  changed, comment,  line]
"
"   e.g_1
"   'clk' : ['clk','clk',0,'test','.clk(clk),      //test']
"   'rst' : ['rst','rst',0,'','.rst(rst),']
"
"   e.g_2
"   'port_a' : ['port_a','port_a',0,'','.port_a(port_a),']
"   'port_b_valid' : ['port_b_valid','port_b_valid',0,'','.port_b_valid(port_b_valid),']
"   'port_b' : ['port_b','conn_b',1,'','.port_b(conn_b)']
"
"---------------------------------------------------
function s:GetInstIO(lines,io_names)
    let idx = 0
    let inst_names = {}
    let io_names = copy(a:io_names)
    while idx < len(a:lines)
        let idx = idx + 1
        let idx = g:ATV_SkipCmtLine(2,idx,a:lines)  "skip pair comment line
        let line = a:lines[idx-1]
        "record user // comment
        let cmt = matchstr(line,'\/\/\zs[^/]*\ze$')             "skip //...//...
        let line = substitute(line,'\/\/.*$','','')             "delete // comment
        while line =~ '\.\s*\w\+\s*(.\{-\})'
            "record port
            let port = matchstr(line,'\.\s*\zs\w\+\ze\s*(.\{-\})')
            "record connection
            let conn = matchstr(line,'\.\s*\w\+\s*(\zs.\{-\}\ze\(\/\/.*\)\@<!)')    "connection,skip comment
            let conn = substitute(conn,'^\s*','','')                                "delete space from the start for alignment
            let conn = substitute(conn,'\s*$','','')                                "delete space in the end for alignment
            let changed = 0
            if g:atv_ati_keep_chg == 'name'
                let conn = matchstr(conn,'\w\+')    "connection name
                if port != conn
                    let changed = 1
                endif
            elseif g:atv_ati_keep_chg == 'full' 
                if has_key(io_names,port)
                    let value = io_names[port]
                    let type = value[0]
                    if type != 'keep'
                        let name = value[5]
                        let width = value[8]
                        let dft_conn = name.width
                        if dft_conn != conn
                            let changed = 1
                        endif
                    endif
                endif
            else
                let changed = 0
            endif
            "           [port, connection,  changed, comment,  line]
            let value = [port, conn,        changed, cmt,      line]
            call extend(inst_names,{port : value})
            let line = substitute(line,'\.\s*\w\+\s*(.\{-\})','','')
        endwhile
    endwhile
    return inst_names
endfunction
"}}}2

"ATV_GetInstModName 获取例化名和模块名{{{2
"--------------------------------------------------
" Function: ATV_GetInstModName
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
"   module name and inst name
"   idx1: line index of inst name
"   idx2: line index of );
"   idx3: line index of module name
"---------------------------------------------------
function g:ATV_GetInstModName()
    "record original idx & col to cursor back to orginal place
    let orig_idx = line('.')
    let orig_col = col('.')

    "get module name & inst name by search function
    let idx = line('.')
    let mname= ''
    let iname = ''
    let wait_semicolon = 0
    let wait_mname = 0

    while 1
        "skip function must have lines input
        let idx = g:ATV_SkipCmtLine(1,idx,getline(1,line('$')))
        "afer skip, still use current buffer
        let line = getline(idx)

        "abnormal break
        if wait_semicolon == 1
            if idx == 0 || getline(idx) =~ '^\s*module' || getline(idx) =~ ');' || getline(idx) =~ '(.*)\s*;'
                call g:ATV_ErrEchohl("5","[".s:sfile."-".expand("<sflnum>")."]","Error GetInstModName. line = ".idx)
                let [mname,iname,idx1,idx2,idx3] = ['','',0,0,0]
                break
            endif
        endif

        "get inst name
        if line =~ '('
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
                    call g:ATV_ErrEchohl("6","[".s:sfile."-".expand("<sflnum>")."]","Error GetInstModName. () inst pair not-match, line = ".index." colunm = ".col)
                    let [mname,iname,idx1,idx2,idx3] = ['','',0,0,0]
                    return [mname,iname,idx1,idx2,idx3]
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
                    let wait_semicolon = 1
                    break
                endif
                let wait_semicolon = 0
            endfor

            if wait_semicolon == 1
                "place cursor back to where ')' pair
                call cursor(index,col)

                "record ); position
                let idx2 = line('.')

                "call searchpair('(','',')','bW')
                execute 'normal %'

                "find position of inst name,skip comment
                call search('\(\/\/.*\)\@<!\w\+','b')
                "get inst name
                let iname = expand('<cword>')

                "record inst name position
                let idx1 = line('.')

                let wait_mname = 1
            endif
        endif

        "get module name
        if wait_mname == 1
            "search for last none-blank character,skip comment
            call search('\(\/\/.*\)\@<![^ \/]','bW')
            "parameter exists
            if getline('.')[col('.')-1] == ')'
                if searchpair('(','',')','bW','getline(".")=~"^\\s*\/\/"') <= 0
                    call g:ATV_ErrEchohl("7","[".s:sfile."-".expand("<sflnum>")."]","Error GetInstModName. () parameter pair not-match, line = ".index." colunm = ".col)
                    let [mname,iname,idx1,idx2,idx3] = ['','',0,0,0]
                    return [mname,iname,idx1,idx2,idx3]
                endif
                call search('\(\/\/.*\)\@<!\w\+','bW')
            "find position of module name,skip comment
            else
                call search('\(\/\/.*\)\@<!\w\+','bW')
            endif
            let mname = expand('<cword>')

            "record start position
            if g:atv_ati_pos_st_auto == 1
                let s:st_prefix = matchstr(getline('.'),'^\zs\s*\ze'.mname)
            endif

            "record module name position
            let idx3 = line('.')
            break
        endif

        let idx = idx -1

    endwhile

    "cursor back
    call cursor(orig_idx,orig_col)

    return [mname,iname,idx1,idx2,idx3]

endfunction
"}}}2

"ATV_GetModLine 删除所有Module外的行{{{2
"--------------------------------------------------
" Function: ATV_GetModLine()
"
" Output:
"   lines : lines to reserve module line
"   mname : module name to be reserved
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
"   --->ATV_GetModLine(lines,a)
"
" Output:
"   module a();
"     uart #(para=2) u_uart ();
"   endmodule
"---------------------------------------------------
function g:ATV_GetModLine(lines,mname)
    let find_module = 0
    let in_module = 0
    let module = ''
    let proc_lines = []
    for line in a:lines
        "single line
        if line =~ '^\s*module'
            if line =~ '^\s*module'.'\s\+'.'\<'.a:mname.'\>'
                call add(proc_lines,line)
                let in_module = 1
            elseif line =~ '^\s*module\s*$'
                let module = matchstr(line,'^\s*module')
                let find_module = 1
            else
                call add(proc_lines,'')
            endif
            continue
        endif
        "multi line
        if find_module == 1 && in_module == 0
            if line =~ '^\s*'.'\<'.a:mname.'\>'
                call add(proc_lines,module)
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
                    call g:ATV_ErrEchohl("2","[".s:sfile."-".expand("<sflnum>")."]","KillAutoInst end abnormally !")
                    break
                "middle
                else
                    "call deletebufline('%',idx)
                    execute ':'.idx.'d'
                endif
            endwhile
        endif
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
"   upd_io_names : old io name dictionary needed update
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
"       .signal_name   (signal_name[width1:width2]      ), //iodir
"---------------------------------------------------
function s:DrawIO(io_seqs,upd_io_names)
    let prefix = s:st_prefix.repeat(' ',4)
    let upd_io_names = copy(a:upd_io_names)

    "guarantee spaces width{{{3
    let max_lb = 0
    let max_rb = 0
    let lbrs = repeat(' ',g:atv_ati_pos_lbrs)
    for seq in sort(map(keys(a:io_seqs),'str2nr(v:val)'),g:atv_sort_funcref)
        let value = a:io_seqs[seq]
        let type = value[0]
        "calculate maximum len of position to Draw
        if type != 'keep' 
            let name = value[5]
            let width = value[8]
            let conn = name.width
            "io that's changed will be keeped if config 
            if g:atv_ati_keep_chg != ''
                if has_key(upd_io_names,name)
                    let upd_value = upd_io_names[name]
                    let changed = upd_value[2]
                    if changed == 1
                        let conn = upd_value[1]
                    endif
                endif
            endif
            "prefix.'.'.name.lbls.'('.lbrs.conn.rbls.')'
            if g:atv_ati_pos_comma == 0
                let max_lb = max([max_lb,len(prefix)+len('.')+len(name)+4,g:atv_ati_pos_lb])
                let max_rb = max([max_rb,max_lb+len('(')+len(lbrs)+len(conn)+4,g:atv_ati_pos_rb])
            "prefix.','.'.'.name.lbls.'('.lbrs.conn.rbls.')'
            else
                let max_lb = max([max_lb,len(prefix)+len(',')+len('.')+len(name)+4,g:atv_ati_pos_lb])
                let max_rb = max([max_rb,max_lb+len('(')+len(lbrs)+len(conn)+4,g:atv_ati_pos_rb])
            endif
        endif
    endfor
    "}}}3

    "draw io{{{3
    let lines = []
    let last_idx = 0
    let last_port_flag = 0

    "upd_io_names can be changed in function, therefore record if it's empty first
    if upd_io_names == {}
        let upd_io_empty = 1
    else
        let upd_io_empty = 0
    endif

    for seq in sort(map(keys(a:io_seqs),'str2nr(v:val)'),g:atv_sort_funcref)
        let value = a:io_seqs[seq]
        let type = value[0]
        let line = value[7]
        "add single comment/ifdef line{{{4
        if type == 'keep' 
            if line =~ '^\s*\/\/'
                if g:atv_ati_incl_cmt == 1
                    let line = prefix.substitute(line,'^\s*','','')
                    call add(lines,line)
                else
                    "ignore comment line when not config
                endif
            elseif line =~ '^\s*\`\(if\|elsif\|else\|endif\)'
                if g:atv_ati_incl_ifdef == 1
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
            "[type,  sequence, iodir, width1, width2, signal_name, last_port, line, width, first_port ]
            "name
            let name = value[5]

            "lbls align/not align
            if g:atv_ati_pos_lalgn == 1
                let lbls = repeat(' ',max_lb-len(prefix)-len(name)-len('.'))
            else
                let lbls = repeat(' ',g:atv_ati_pos_lbls)
            endif

            "lbrs
            let lbrs = repeat(' ',g:atv_ati_pos_lbrs)

            "width
            let width = value[8]
            let conn = name.width
            "io that's changed will be keeped if config 
            if g:atv_ati_keep_chg != ''
                if has_key(upd_io_names,name)
                    let upd_value = upd_io_names[name]
                    let changed = upd_value[2]
                    if changed == 1
                        let conn = upd_value[1]
                    endif
                endif
            endif
            
            "rbls align/not align
            if g:atv_ati_pos_ralgn == 1
                if g:atv_ati_pos_lalgn == 1
                    let max_lb = max_lb
                else
                    let max_lb = len(prefix)+len('.')+len(name)+len(lbls)
                endif
                let rbls = repeat(' ',max_rb-max_lb-len('(')-len(lbrs)-len(conn))
            else
                let rbls = repeat(' ',g:atv_ati_pos_rbls)
            endif

            "comma
            let last_port = value[6]
            let first_port = value[9]
            if g:atv_ati_pos_comma == 0
                if last_port == 1
                    let comma = ' '         "space
                    let last_port_flag = 1  "special case: last port has been moved out of upd_io_names, there exist no last_port
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

            "rbrs
            let rbrs = repeat(' ',g:atv_ati_pos_rbrs)

            "Draw IO by config
            if g:atv_ati_pos_comma == 0
                let line = prefix.'.'.name.lbls.'('.lbrs.conn.rbls.')'.comma.rbrs
            else
                let line = prefix.comma.'.'.name.lbls.'('.lbrs.conn.rbls.')'.rbrs
            endif

            "tail comment (iodir+instnew+ifname)
            let tcmt = ''

            "record user tail comment (in case inst new delete upd_io_names)
            let usr_io_names = copy(upd_io_names)

            "iodir
            let iodir = value[2]
            if g:atv_ati_cmt_iodir != ''
                "map input -> I output -> O inout -> IO interface -> IF
                let iodir_dlist = ['input','output','inout','interface']    "default
                let iodir_list = split(g:atv_ati_cmt_iodir)
                let idx = 0
                while idx < len(iodir_list)
                    if iodir == iodir_dlist[idx]
                        let iodir = iodir_list[idx]
                    endif
                    let idx = idx + 1
                endwhile
                let tcmt = tcmt.g:atv_ati_cmt_delim.iodir
            endif

            "inst new
            if upd_io_empty == 0       "draw when upd_io_names not empty
                if g:atv_ati_cmt_instnew == 1
                    "name not exist in old upd_io_names, add //INST_NEW
                    if has_key(upd_io_names,name) != 1
                        let tcmt = tcmt.g:atv_ati_cmt_delim.'INST_NEW'
                        "time stamp
                        if g:atv_ati_cmt_instnew_tstp == ''
                            let tstp = ''
                        else
                            let tstp = g:atv_ati_cmt_delim.'@'.strftime(g:atv_ati_cmt_instnew_tstp)
                        endif
                        let tcmt = tcmt.tstp
                    "name already exist in old upd_io_names,cover
                    else
                        call remove(upd_io_names,name)
                    endif
                endif
            endif

            "sv interface
            if type == 'interface'
                let ifname = value[7]
                let tcmt = tcmt.g:atv_ati_cmt_delim.ifname
            endif

            "add tail comment
            if tcmt != ''
                let tcmt = substitute(tcmt,'\V'.escape(g:atv_ati_cmt_delim,'\/'),'','')        "delete first delimiter
                let line = line.'//'.tcmt
            endif

            "add user tail comment
            if g:atv_ati_cmt_usr == 1 
                if has_key(usr_io_names,name)
                    let upd_value = usr_io_names[name]
                    let utcmt = upd_value[3]
                    if utcmt != '' 
                        "in case multiple adding user comment
                        if strpart(utcmt,0,len(tcmt)) != tcmt
                            let line = line.'//'.utcmt
                        endif
                    endif
                endif
            endif

            call add(lines,line)

            "in case special case happen(last port has been moved out of upd_io_names, there exist no last_port)
            "same time last line is not an io type, must record last_port index here
            let last_idx = index(lines,line) 

        endif
    "}}}4
    endfor

    "special case: last port has been put in keep_io_list, there exist no last_port
    if g:atv_ati_pos_comma == 0
        if last_port_flag == 0 && last_idx != 0
            "set last item as last_port
            let lines[last_idx] = substitute(lines[last_idx],',',' ','') 
        endif
    "no speicial case for first port
    endif

    "inst delete
    if g:atv_ati_cmt_instdel == 1
        if upd_io_names == {}
            "remain port in upd_io_names
        else
            for name in keys(upd_io_names)
                let upd_value = upd_io_names[name]
                let conn = upd_value[1]
                let line = prefix.'//INST_DEL: Port '.'.'.name.'('.conn.')'.' has been deleted'
                "time stamp
                if g:atv_ati_cmt_instdel_tstp != ''
                    let line = line.g:atv_ati_cmt_delim.'@'.strftime(g:atv_ati_cmt_instdel_tstp)
                endif
                call add(lines,line)
            endfor
        endif
    endif
    "}}}3

    if lines == []
        call g:ATV_ErrEchohl("4","[".s:sfile."-".expand("<sflnum>")."]","Error DrawIO. No io input. Possibly g:atv_ati_95_support not open, or bracket () not match")
    endif

    return lines

endfunction
"}}}2

"}}}1

