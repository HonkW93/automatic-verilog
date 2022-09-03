"-----------------------------------------------------------------------------
" Vim Plugin for Verilog Code Automactic Generation 
" Author:         HonkW
" Website:        https://honk.wang
" Last Modified:  2022/09/03 23:30
" File:           autopara.vim
" Note:           AutoPara function self-made
"------------------------------------------------------------------------------

"Sanity checks 启动判断{{{1
if exists("g:loaded_automatic_verilog_autopara")
    finish
endif
let g:loaded_automatic_verilog_autopara = 1
"}}}1

"Defaults 默认配置{{{1
"AutoPara 自动参数配置
"+-------------+-------------------------------------------------------------------------+
"|   st_pos    |                             start position                              |
"+-------------+-------------------------------------------------------------------------+
"|  name_pos   |                          signal name position                           |
"+-------------+-------------------------------------------------------------------------+
"|   sym_pos   |                          symbol name position                           |
"+-------------+-------------------------------------------------------------------------+
"|  only_port  | add only port parameter definition,ignore parameter = value; definition |
"+-------------+-------------------------------------------------------------------------+
"|  para_new   |     add //PARA_NEW if parameter has been newly added to the module      |
"+-------------+-------------------------------------------------------------------------+
"|  para_del   |      add //PARA_DEL if parameter has been deleted from the module       |
"+-------------+-------------------------------------------------------------------------+
"|  keep_chg   |                         keep changed parameter                          |
"+-------------+-------------------------------------------------------------------------+
"|  incl_cmnt  |       include comment line of // (/*...*/ will always be ignored)       |
"+-------------+-------------------------------------------------------------------------+
"| incl_ifdef  |                    include ifdef like `ifdef `endif                     |
"+-------------+-------------------------------------------------------------------------+
"| tail_nalign |                don't do alignment in tail when autopara                 |
"+-------------+-------------------------------------------------------------------------+
let g:_ATV_AUTOPARA_DEFAULTS = {
            \'st_pos':      4,
            \'name_pos':    32,
            \'sym_pos':     64,
            \'only_port':   0,
            \'para_new':    1,
            \'para_del':    1,
            \'keep_chg':    1,        
            \'incl_cmnt':   0,
            \'incl_ifdef':  0,    
            \'tail_nalign': 0    
            \}
for s:key in keys(g:_ATV_AUTOPARA_DEFAULTS)
    if !exists('g:atv_autopara_' . s:key)
        let g:atv_autopara_{s:key} = copy(g:_ATV_AUTOPARA_DEFAULTS[s:key])
    endif
endfor
let s:st_prefix = repeat(' ',g:atv_autopara_st_pos)
"}}}1

"Keys 快捷键{{{1
amenu 9998.3.1 &Verilog.AutoPara.AutoPara(0)<TAB>One                             :call g:AutoPara(0)<CR>
amenu 9998.3.2 &Verilog.AutoPara.AutoPara(1)<TAB>All                             :call g:AutoPara(1)<CR>
amenu 9998.3.3 &Verilog.AutoPara.AutoParaValue(0)<TAB>One                        :call g:AutoParaValue(0)<CR>
amenu 9998.3.4 &Verilog.AutoPara.AutoParaValue(1)<TAB>All                        :call g:AutoParaValue(1)<CR>
amenu 9998.3.5 &Verilog.AutoPara.KillAutoPara(0)<TAB>One                         :call g:KillAutoPara(0)<CR>
amenu 9998.3.5 &Verilog.AutoPara.KillAutoPara(1)<TAB>All                         :call g:KillAutoPara(1)<CR>

if !hasmapto(':call g:AutoPara(0)<ESC>')
    map <S-F4>      :call g:AutoPara(0)<ESC>
endif
if !hasmapto(':call g:AutoParaValue(0)<ESC>')
    map <S-F5>      :call g:AutoParaValue(0)<ESC>
endif
"}}}1

"AutoPara 自动参数{{{1
"--------------------------------------------------
" Function: AutoPara
" Input: 
"   mode : mode for autoinstparam
" Description:
"   autopara for inst module
"   mode = 1, autoinstparam all parameter
"   mode = 0, autoinstparam only one parameter
" Output:
"   Formatted autoinstparam code
" Note:
"   list of parameter sequences
"    0     1         2               3                4                    5     6
"   [type, sequence, parameter_name, parameter_value, last_port_parameter, line, last_decl_parameter] 
"   para_seqs = {seq : value }
"   para_names = {parameter_name : value }
"---------------------------------------------------
function! g:AutoPara(mode)
    "Get module-file-dir dictionary
    let [files,modules] = g:AutoVerilog_GetModuleFileDirDic()

    "Record current position
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
        "Put cursor to /*autoinstparam*/ line
        if search('\/\*autoinstparam\*\/','W') == 0
            break
        endif

        "Skip comment line //
        if getline('.') =~ '^\s*\/\/'
            continue
        endif

        "Get module_name & inst_name
        let [module_name,inst_name,idx1,idx2] = s:GetParaModuleName()

        "Get keep inst parameter & update inst parameter list
        let keep_para_list = s:GetInstPara(getline(idx1,line('.')))
        let upd_para_list = s:GetInstPara(getline(line('.'),idx2))
        "Get changed parameter names
        let chg_para_names = s:GetChangedPara(getline(line('.'),idx2))

        "Get parameter sequences {sequence : value}
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
            if a:mode == 1
                continue
            elseif a:mode == 0
                return
            else
                echohl ErrorMsg | echo "Error input for AutoPara(),input mode = ".a:mode| echohl None
                return
            endif
        endif

        "Remove parameter from para_seqs that want to be keep when autoinstparam
        "   value = [type, sequence, parameter_name, parameter_value, last_port_parameter, line, last_decl_parameter] 
        "   para_seqs = {sequence : value }
        "   para_names = {parameter_name : value }
        for name in keep_para_list
            if has_key(para_names,name)
                let value = para_names[name]
                let seq = value[1]
                call remove(para_seqs,seq)
            endif
        endfor

        "Kill all contents under /*autoinstparam*/ untill inst_name
        "Current position must be at /*autoinstparam*/ line
        call s:KillAutoPara(inst_name)

        "Draw parameter, use para_seqs to cover update parameter list
        "if para_seqs has new parameter_name that's never in upd_para_list, add //PARA_NEW
        "if para_seqs has same parameter_name that's in upd_para_list, cover
        "if para_seqs doesn't have parameter_name that's in upd_para_list, add //PARA_DEL
        "if para_seqs connection has been changed, keep it
        let lines = s:DrawPara(para_seqs,upd_para_list,chg_para_names)

        "Delete current line )
        let line = substitute(getline(line('.')),')\s*','','')
        call setline(line('.'),line)
        "Append parameter and )
        call add(lines,s:st_prefix.')')
        call append(line('.'),lines)

        "mode = 0, only autopara once
        if a:mode == 0
            break
            "mode = 1, autopara all
        else
        endif

    endwhile

    "Put cursor back to original position
    call cursor(orig_idx,orig_col)
endfunction

"}}}1

"AutoParaValue 自动参数Value{{{1
"--------------------------------------------------
" Function: AutoParaValue
" Input: 
"   mode : mode for autoinstparam
" Description:
"   auto para value for inst module
"   mode = 1, autoinstparam_value all parameter
"   mode = 0, autoinstparam_value only one parameter
" Output:
"   Formatted autoinstparam code
" Note:
"   list of parameter sequences
"    0     1         2               3                4                    5     6
"   [type, sequence, parameter_name, parameter_value, last_port_parameter, line, last_decl_parameter] 
"   para_seqs = {seq : value }
"   para_names = {parameter_name : value }
"---------------------------------------------------
function! g:AutoParaValue(mode)
    "Get module-file-dir dictionary
    let [files,modules] = g:AutoVerilog_GetModuleFileDirDic()

    "Record current position
    let orig_idx = line('.')
    let orig_col = col('.')

    "AutoPara all start from top line, AutoPara once start from first /*autoinstparam_value*/ line
    if a:mode == 1
        call cursor(1,1)
    elseif a:mode == 0
        call cursor(line('.'),1)
    else
        echohl ErrorMsg | echo "Error input for AutoParaValue(),input mode = ".a:mode| echohl None
        return
    endif

    while 1
        "Put cursor to /*autoinstparam*/ line
        if search('\/\*autoinstparam_value\*\/','W') == 0
            break
        endif

        "Get module_name & inst_name
        let [module_name,inst_name,idx1,idx2] = s:GetParaModuleName()

        "Get keep inst parameter & update inst parameter list
        let keep_para_list = s:GetInstPara(getline(idx1,line('.')))
        let upd_para_list = s:GetInstPara(getline(line('.'),idx2))

        "Get parameter sequences {sequence : value}
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
            if a:mode == 1
                continue
            elseif a:mode == 0
                return
            else
                echohl ErrorMsg | echo "Error input for AutoParaValue(),input mode = ".a:mode| echohl None
                return
            endif
        endif

        "Remove parameter from para_seqs that want to be keep when autoinstparam
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

        "Kill all contents under /*autoinstparam_value*/ untill inst_name
        "Current position must be at /*autoinstparam_value*/ line
        call s:KillAutoPara(inst_name)

        "Draw parameter value, use para_seqs to cover update parameter list
        "if para_seqs has new parameter_name that's never in upd_para_list, add //PARA_NEW
        "if para_seqs has same parameter_name that's in upd_para_list, cover
        "if para_seqs doesn't have parameter_name that's in upd_para_list, add //PARA_DEL
        let lines = s:DrawParaValue(para_seqs,upd_para_list)

        "Delete current line )
        let line = substitute(getline(line('.')),')\s*','','')
        call setline(line('.'),line)
        "Append parameter and )
        call add(lines,s:st_prefix.')')
        call append(line('.'),lines)

        "mode = 0, only autopara once
        if a:mode == 0
            break
            "mode = 1, autopara all
        else
        endif

    endwhile

    "Put cursor back to original position
    call cursor(orig_idx,orig_col)
endfunction

"}}}1

"KillAutoPara Kill自动参数{{{1
"--------------------------------------------------
" Function: KillAutoPara
" Input: 
"   mode : mode for kill autopara
" Description:
"   autopara for inst module
"   mode = 1, autoinstparam all parameter
"   mode = 0, autoinstparam only one parameter
" Output:
"   Killed autopara code
"---------------------------------------------------
function! g:KillAutoPara(mode) abort

    "Record current position
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
        "Put cursor to /*autoinstparam*/ or /*autoinstparam_value*/ line
        if search('\(\/\*autoinstparam\*\/\)\|\(\/\*autoinstparam_value\*\/\)','W') == 0
            break
        endif

        "Skip comment line //
        if getline('.') =~ '^\s*\/\/'
            continue
        endif

        "Get module_name & inst_name
        let [module_name,inst_name,idx1,idx2] = s:GetParaModuleName()

        "Kill all contents under /*autoinstparam*/ untill inst_name
        "Current position must be at /*autoinstparam*/ line
        call s:KillAutoPara(inst_name)

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
"AutoPara-Get
"GetPara 获取参数列表{{{2
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
"       //comment line
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
"    0     1         2               3                4                    5     6
"   [type, sequence, parameter_name, parameter_value, last_port_parameter, line, last_decl_parameter] 
"   [port,1,'A', '16',0,'',0]
"   [port,2,'B', '4'd11',0,'',0]
"   [keep,3,'c0','c0',0,'    //comment line',0]
"   [port,4,'C', '16'h55',1,'',0]
"   [decl,5,'D', '10_0000',0,'',0]
"   [decl,6,'E', ''HEAD'',0,'',1]
"
" Output:
"   list of parameter sequences
"    0     1         2               3                4                    5     6
"   [type, sequence, parameter_name, parameter_value, last_port_parameter, line, last_decl_parameter] 
"---------------------------------------------------
function s:GetPara(lines,mode)
    let idx = 0

    "wait for parameter 
    let wait_module = 1
    let wait_hash_flag = 1
    let wait_left_braket = 1
    let wait_port_para = 1
    let wait_right_braket = 1
    let wait_decl_para = 1

    "record single comment line & ifdef
    "record port & declaration parameter
    let line_idxs = {}
    let para_seqs = {}

    "get parameter seqs from line {{{3
    while idx < len(a:lines)
        let idx = idx + 1
        let idx = g:AutoVerilog_SkipCommentLine(2,idx,a:lines)  "skip pair comment line
        if idx == -1
            echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
        endif
        let line = a:lines[idx-1]
        "delete comment line in the middle
        let line = substitute(line,'^\s*\([^s \& ^/]\)\+.*\zs\/\/.*','','')

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
        elseif wait_module == 0 && line =~ '#\s*$'
            let wait_hash_flag = 0
        elseif line =~ '^\s*(' && wait_hash_flag==0
            let wait_left_braket = 0
        endif

        "record single comment/ifdef line in port parameter 
        if wait_left_braket == 0 && wait_right_braket == 1 
            if line =~ '^\s*\`\(if\|elsif\|else\|endif\)' || (line =~ '^\s*\/\/' && line !~ '^\s*\/\/\s*{{{')
                "[type, idx, line]
                let type = 'keep'
                let value = [type,idx,line]
                call extend(line_idxs,{idx : value})
                continue
            endif
        endif
        "}}}4

        "find port parameter 
        if wait_left_braket == 0 && line =~ 'parameter'
            let wait_port_para = 0
        endif

        "record port parameter line
        if wait_port_para == 0 && wait_right_braket == 1 
            "[type, idx, line]
            let type = 'port'
            let value = [type,idx,line]
            call extend(line_idxs,{idx : value})
        endif

        "find ), skip function like $clog2(BMAN)
        if wait_port_para == 0 
            if line =~ ')' && line !~ '\$\w\+(.*)'
                let wait_right_braket = 0
                continue
            endif
        "no #() parameter, skip
        else        
            if wait_left_braket == 1 && line =~ 'parameter'
                let wait_right_braket = 0
            endif
        endif

        "record single comment/ifdef line in declaration parameter 
        if wait_right_braket == 0 && wait_decl_para == 1 
            if line =~ '^\s*\`\(if\|elsif\|else\|endif\)' || (line =~ '^\s*\/\/' && line !~ '^\s*\/\/\s*{{{')
                "[type, idx, line]
                let type = 'keep'
                let value = [type,idx,line]
                call extend(line_idxs,{idx : value})
                continue
            endif
        endif
        "}}}4
        
        "record normal parameter 
        if wait_right_braket == 0 && line =~ 'parameter'
            let wait_decl_para = 0
        endif

        "record normal parameter 
        if wait_decl_para == 0
            "[type, idx, line]
            let type = 'decl'
            let value = [type,idx,line]
            call extend(line_idxs,{idx : value})
        endif

        "find ; wait for parameter again
        if wait_decl_para == 0 && line =~ ';'
            let wait_decl_para = 1
        endif

    endwhile
    "}}}3

"    "{{{3 Problem with `ifdef and //single comment line
    let last_port_para_idx = 0
    let last_decl_para_idx = 0

    "remove single comment line before first declaration parameter
    "find last port parameter first 
    for idx in sort(map(keys(line_idxs),'str2nr(v:val)'),g:atv_sort_funcref)
        let value = line_idxs[idx]
        let type = value[0]
        if type == 'port'
            let last_port_para_idx = idx 
        endif
    endfor
    "find last decl parameter first 
    for idx in sort(map(keys(line_idxs),'str2nr(v:val)'),g:atv_sort_funcref)
        let value = line_idxs[idx]
        let type = value[0]
        if type == 'decl'
            let last_decl_para_idx = idx 
        endif
    endfor

    "remove single comment line
    for idx in sort(map(keys(line_idxs),'str2nr(v:val)'),g:atv_sort_funcref)
        let value = line_idxs[idx]
        let type = value[0]
        let line = value[2]
        "search for idx after last port parameter
        if idx > last_port_para_idx
            if type == 'keep'
                if line =~ '^\s*\/\/'
                    call remove(line_idxs,idx)
                endif
            elseif type == 'decl'
                break
            endif
        endif
    endfor

    "---------------------------------------------------------------
    " Problem Here. Cannot be solved right now.
    " Description:
    " cannot keep ifdef ... endif for declaration parameter since it's mixed with other line ifdef 
    " e.g 
    " module test #( 
    "   parameter A = 0,
    "   parameter B = 0,
    " )
    " (
    "   `ifdef
    "   input aaaa;
    "   output bbbb;
    "   `endif
    " );
    "   `ifdef  
    "       parameter C = 0;
    "       parameter D = 0;
    "   `endif
    "
    "   `ifdef
    "       assign bbbb = aaaa;
    "   `endif
    "---------------------------------------------------------------
    "remove single comment line after last declaration parameter
    for idx in reverse(sort(map(keys(line_idxs),'str2nr(v:val)'),g:atv_sort_funcref))
        let value = line_idxs[idx]
        let type = value[0]
        let line = value[2]
        if type == 'keep'
            if line =~ '^\s*\/\/'
                call remove(line_idxs,idx)
            endif
        elseif type == 'decl' || type == 'port'
            break
        endif
    endfor

    "ifdef keeped if below is declaration parameter
    for idx in sort(map(keys(line_idxs),'str2nr(v:val)'),g:atv_sort_funcref)
        let value = line_idxs[idx]
        let type = value[0]
        let line = value[2]
        "search for idx after last port parameter
        if idx > last_port_para_idx
            if type == 'keep'
                if line =~ '^\s*\`if' 
                    if idx < last_decl_para_idx
                        "keep ifdef
                    else
                        "remove ifdef
                        call remove(line_idxs,idx)
                    endif
                endif
            elseif type == 'decl'
                break
            endif
        endif
    endfor

    let endif_exist = 0
    "endif keeped only once after declaration parameter
    for idx in sort(map(keys(line_idxs),'str2nr(v:val)'),g:atv_sort_funcref)
        let value = line_idxs[idx]
        let type = value[0]
        let line = value[2]
        "search for idx after last decl parameter
        if idx > last_decl_para_idx
            if type == 'keep'
                if endif_exist == 1
                    "remove endif
                    call remove(line_idxs,idx)
                elseif line =~ '^\s*\`endif' 
                    "keep endif
                    let endif_exist = 1
                endif
            endif
        endif
    endfor
"    "}}}3

    "generate parameter seqs{{{3
    let seq = 0
    for idx in sort(map(keys(line_idxs),'str2nr(v:val)'),g:atv_sort_funcref)
        let value = line_idxs[idx]
        "[type, idx, line]
        let type = value[0]
        let line = value[2]

        if type == 'keep'
            let seq = seq + 1
                    "   [type, sequence, parameter_name, parameter_value, last_port_parameter, line, last_decl_parameter] 
            let value = [type, seq     , 'c0',           'c0',            0,                   line, 0]
            call extend(para_seqs, {seq : value})
        elseif type == 'port'
            let port_para_list = []
            "unify to use ',' as spliter
            for port_para in split(line,',',1)
                if port_para =~ '\w\+\s*=\s*\S\+\ze\s*'
                    call add(port_para_list,matchstr(port_para,'\w\+\s*=\s*\S\+\ze\s*'))
                endif
            endfor 

            for para in port_para_list
                let seq = seq + 1
                let p_name = matchstr(para,'\w\+\ze\s*=')
                let p_value = matchstr(para,'=\s*\zs\S\+')
                        "   [type, sequence, parameter_name, parameter_value, last_port_parameter, line, last_decl_parameter] 
                let value = [type, seq     , p_name        , p_value         ,0,                   '',   0]
                call extend(para_seqs, {seq : value})
            endfor
        elseif type == 'decl'
            let decl_para_list = []
            "unify to use ',' as spliter,add spliter for last_para
            let decl_para = substitute(line,';',',','g')
            call substitute(decl_para,'\w\+\s*=\s*\S\+\ze\s*,','\=add(decl_para_list,submatch(0))','g')
            for para in decl_para_list
                let seq = seq + 1
                let p_name = matchstr(para,'\w\+\ze\s*=')
                let p_value = matchstr(para,'=\s*\zs\S\+')
                        "   [type, sequence, parameter_name, parameter_value, last_port_parameter, line, last_decl_parameter] 
                let value = [type, seq     , p_name        , p_value         ,0,                   '',   0]
                call extend(para_seqs, {seq : value})
            endfor
        endif

    endfor
    "}}}3

    "find last_port{{{3
    
    "get last_port_seq and last_decl_seq
    if len(keys(para_seqs)) > 0
        "last parameter in port 
        let last_port_seq = 0
        for seq in sort(map(keys(para_seqs),'str2nr(v:val)'),g:atv_sort_funcref)
            let value = para_seqs[seq]
            let type = value[0]
            if type == 'port'
                let last_port_seq = seq 
            endif
        endfor
        "last parameter in declaration
        let last_decl_seq = 0
        for seq in sort(map(keys(para_seqs),'str2nr(v:val)'),g:atv_sort_funcref)
            let value = para_seqs[seq]
            let type = value[0]
            if(type == 'decl')
                let last_decl_seq = seq
            endif
        endfor 
    else
        echohl ErrorMsg | echo "Error para_seqs when GetPara! para_seqs length = ".len(keys(para_seqs))| echohl None
        echohl ErrorMsg | echo "Possibly no parameter exist" | echohl None
    endif

    "add last_port_parameter 
    if last_port_seq != 0
        let value = para_seqs[last_port_seq]
        "   [type, sequence, parameter_name, parameter_value, last_port_parameter, line, last_decl_parameter] 
        let value[4] = 1
        call extend(para_seqs,{last_port_seq : value})
    endif
    "add last_decl_parameter 
    if last_decl_seq != 0
        let value = para_seqs[last_decl_seq]
        "   [type, sequence, parameter_name, parameter_value, last_port_parameter, line, last_decl_parameter] 
        let value[6] = 1
        call extend(para_seqs,{last_decl_seq : value})
    endif
    "}}}3
    
    "output by mode{{{3
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
    "}}}3

endfunction
"}}}2

"GetInstPara 获取例化参数{{{2
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
        let idx = g:AutoVerilog_SkipCommentLine(2,idx,a:lines)  "skip pair comment line
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
"}}}2

"GetChangedPara 获取修改过的参数{{{2
"--------------------------------------------------
" Function: GetChangedPara
" Input: 
"   lines : lines to get parameter
" Description:
"   Get changed parameter info from lines
"   e.g
"   module_name #(
"       .A_PARAMETER (5'd20)
"       .B_PARAMETER (B_PARAMETER)
"   )
"   inst_name
"   (
"       ....
"   );
"
" Output:
"   dict of changed parameter (according to input lines)
"   e.g_1
"   cpara_names = {
"                   'A_PARAMETER':'5'd20'
"                 }
"---------------------------------------------------
function s:GetChangedPara(lines)
    let idx = 0
    let cpara_names = {}
    while idx < len(a:lines)
        let idx = idx + 1
        let idx = g:AutoVerilog_SkipCommentLine(2,idx,a:lines)  "skip pair comment line
        if idx == -1
            echohl ErrorMsg | echo "Error when SkipCommentLine! return -1"| echohl None
        endif
        let line = a:lines[idx-1]
        if line =~ '\.\s*\w\+\s*(.*)'
            let para_name = matchstr(line,'\.\s*\zs\w\+\ze\s*(.*)')
            let conn = matchstr(line,'\.\s*\w\+\s*(\s*\zs.\{-\}\ze\s*)')    "connection
            let conn_name = matchstr(conn,'\w\+')                           "connection name
            if para_name != conn_name
                call extend(cpara_names,{para_name : conn})
            endif
        endif
    endwhile
    return cpara_names
endfunction
"}}}2

"GetParaModuleName 获取参数位置和模块名{{{2
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
    let wait_semicolon_pair = 0

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
                echohl ErrorMsg | echo "Abnormal break when GetParaModuleName, idx = ".idx| echohl None
                let [module_name,inst_name,idx1,idx2,idx3] = ['','',0,0,0]
                break
            endif
        endif

        "find position of '#('
        if line =~ '#'
            let col = match(line,'#')
            call cursor(idx,col+1)
            "search for none-blank character,skip comment
            call search('\(\/\/.*\)\@<![^ \/]')

            "if it is '(' then pair
            if getline('.')[col('.')-1] == '('
                let wait_semicolon_pair = 1
            endif

            if wait_semicolon_pair == 1
                "search for pair ()
                if searchpair('(','',')','','getline(".")=~"^\\s*\/\/"') > 0
                    let index = line('.')
                    let col = col('.')
                else
                    let index = line('.')
                    let col = col('.')
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
                call searchpair('(','',')','bW','getline(".")=~"^\\s*\/\/"')
                call search('\w\+','b')

                "get module_name
                let module_name = expand('<cword>')

                "record module_name position
                let idx1 = line('.')

                break

            endif
        endif

        let idx = idx -1

    endwhile

    "cursor back
    call cursor(orig_idx,orig_col)

    "erorr process
    if wait_semicolon_pair == 0
        echohl ErrorMsg | echo "No parameter definition '#(' find here!"| echohl None
        return ['','',0,0]
    endif

    if module_name == '' || inst_name == ''
        echohl ErrorMsg | echo "Cannot find module_name or inst_name from ".orig_idx.','.orig_col | echohl None
        return ['','',0,0]
    endif

    return [module_name,inst_name,idx1,idx2]

endfunction
"}}}2

"AutoPara-Kill
"KillAutoPara 删除所有参数例化"{{{2
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
"   e.g. 2
"   module_name #(/*autoinstparam*/)inst_name();
"   --------------> after KillAutoPara
"
"   module_name #(/*autoinstparam*/)
"   inst_name();
"
" Output:
"   line after kill
"   kill untill inst_name
"---------------------------------------------------
function s:KillAutoPara(inst_name) 
    let prefix = s:st_prefix
    let orig_idx = line('.')
    let orig_col = col('.')
    let idx = line('.')
    let line = getline(idx)
    if line =~ '/\*\<autoinstparam\>' || line =~ '/\*\<autoinstparam_value\>' 
        let oneline = 0

        "if current line end with ')', one line
        "e.g. star #( /*autoinstparam*/ ) 
        "e.g. star #( /*autoinstparam*/ .ATEST(ATEST)) 
        if line =~ '\(\/\*autoinstparam\*\/\)'.'.*)\s*$' || 
        \          '\(\/\*autoinstparam_value\*\/\)'.'.*)\s*$'
            "delete contents after autoinstparam*/
            let line = substitute(line,'\*\/.*$','*/)','')
            call setline(idx,line)
            "still needed to get rid of ')' before inst_name
            let oneline = 0
        "if current line has inst_name, one line , append inst to another line
        "e.g. star #( /*autoinstparam*/ .ATEST(ATEST)) u_star 
        "e.g. star #( /*autoinstparam*/ .ATEST(ATEST)) u_star (/*autoinst*/);
        elseif line =~ '\(\/\*autoinstparam\*\/\)'.'.*)\s*'.a:inst_name || 
        \              '\(\/\*autoinstparam_value\*\/\)'.'.*)\s*'.a:inst_name
            let redundant = matchstr(line,a:inst_name.'.*$')
            let line = substitute(line,escape(redundant,'/*'),'','')
            "delete line after autoinstparam*/ "e.g. star #( /*autoinstparam*/ .ATEST(ATEST)) -->star #( /*autoinstparam*/) 
            let line = substitute(line,'\*\/.*$','*/)','')
            call setline(idx,line)
            call append(idx,prefix.redundant)
            let oneline = 1
        "e.g. star #( /*autoinstparam*/ 
        ") 
        else
            "delete contents after autoinstparam*/
            let line = substitute(line,'\*\/.*$','*/)','')
            call setline(idx,line)
            "still needed to get rid of ')' before inst_name
            let oneline = 0
        endif

        "multi-line
        if oneline == 0
            let idx = idx + 1
            while 1
                let line = getline(idx)
                "end of inst
                if line =~ a:inst_name
                    let redundant = matchstr(line,'^\s*\zs.*\ze'.a:inst_name)
                    let line = substitute(line,escape(redundant,'/*'),'','')
                    call setline(idx,line)
                    break
                "abnormal end
                elseif line =~ 'endmodule' || idx == line('$')
                    echohl ErrorMsg | echo "Error running KillAutoPara! Kill abnormally till the end!"| echohl None
                    break
                "middle
                else
                    "delete all contents in the middle
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
"}}}2

"AutoPara-Draw
"DrawPara 按格式输出例化parameter-parameter{{{2
"--------------------------------------------------
" Function: DrawPara
" Input: 
"   para_seqs : new inst para sequences for align
"   para_list : old inst para name list
"   chg_para_names : old parameter names that has been changed
"
" Description:
" e.g draw parameter sequences as format of para-para
"    0     1         2               3                4                    5     6
"   [type, sequence, parameter_name, parameter_value, last_port_parameter, line, last_decl_parameter] 
"   [port,1,'A', '16',0,'',0]
"   [port,2,'B', '4'd11',0,'',0]
"   [keep,3,'c0','c0',0,'    //comment line',0]
"   [port,4,'C', '16'h55',1,'',0]
"   [decl,5,'D', '10_0000',0,'',0]
"   [decl,6,'E', ''HEAD'',0,'',1]
"
"   module_name #(
"       /*autoinstparam*/
"       .A      (A              ),
"       .B      (B              ),
"       //comment line
"       .C      (C              ),
"       .D      (D              ),
"       .E      (E              ),
"   )
"   inst_name
"   (
"       ...
"   );
"
" Output:
"   line that's aligned
"   e.g
"       .parameter_name   (parameter_name       ),
"       .parameter_name   (parameter_name       )  //last_parameter
"---------------------------------------------------
function s:DrawPara(para_seqs,para_list,chg_para_names)
    let prefix = s:st_prefix.repeat(' ',4)

    let para_list  = copy(a:para_list)
    let chg_para_names = copy(a:chg_para_names)

    "guarantee spaces width{{{3
    let max_lbracket_len = 0
    let max_rbracket_len = 0
    for seq in sort(map(keys(a:para_seqs),'str2nr(v:val)'),g:atv_sort_funcref)
        let value = a:para_seqs[seq]
        let p_name = value[2]
        let p_value = p_name
        "para that's changed will be keeped if config 
        if g:atv_autopara_keep_chg == 1
            if(has_key(chg_para_names,p_name))
                let p_value = chg_para_names[p_name]
            endif
        endif
        "prefix.'.'.p_name.name2bracket.'('.p_value.value2bracket.')'
        let max_lbracket_len = max([max_lbracket_len,len(prefix)+len('.')+len(p_name)+4,g:atv_autopara_name_pos])
        let max_rbracket_len = max([max_rbracket_len,max_lbracket_len+len('(')+len(p_value)+4,g:atv_autopara_sym_pos])
    endfor
    "}}}3

    "draw para{{{3
    let lines = []
    let last_para_flag = 0

    "para_list can be changed in function, therefore record if it's empty first
    if para_list == []
        let para_list_empty = 1
    else
        let para_list_empty = 0
    endif

    for seq in sort(map(keys(a:para_seqs),'str2nr(v:val)'),g:atv_sort_funcref)
        let value = a:para_seqs[seq]
        let type = value[0]
        let line = value[5]
        "add single comment/ifdef line {{{4
        if type == 'keep' 
            if line =~ '^\s*\/\/'
                if g:atv_autopara_incl_cmnt == 1
                    let line = prefix.substitute(line,'^\s*','','')
                    call add(lines,line)
                else
                    "ignore comment line when not config
                endif
            elseif line =~ '^\s*\`\(if\|elsif\|else\|endif\)'
                if g:atv_autopara_incl_ifdef == 1
                    let line = prefix.substitute(line,'^\s*','','')
                    call add(lines,line)
                else
                    "ignore ifdef line when not config
                endif
            endif
        "}}}4
        "add parameter line{{{4
        else
            "Format parameter sequences
            "    0     1         2               3                4                    5     6
            "   [type, sequence, parameter_name, parameter_value, last_port_parameter, line, last_decl_parameter] 

            "p_name
            let p_name = value[2]
            "p_value
            let p_value = p_name

            "para that's changed will be keeped if config 
            if g:atv_autopara_keep_chg == 1
                if(has_key(chg_para_names,p_name))
                    let p_value = chg_para_names[p_name]
                endif
            endif

            "name2bracket
            let name2bracket = repeat(' ',max_lbracket_len-len(prefix)-len(p_name)-len('.'))

            "value2bracket
            "don't align tail if config
            if g:atv_autopara_tail_nalign == 1
                let value2bracket = ''
            else
                let value2bracket = repeat(' ',max_rbracket_len-max_lbracket_len-len('(')-len(p_value))
            endif

            "comma
            if g:atv_autopara_only_port == 0   "use all parameter
                let last_para = value[6]
            else                "use only port parameter
                let last_para = value[4]
            endif
            if last_para == 1
                let comma = ' '         "space
                let last_para_flag = 1  "special case: last parameter has been put in keep_io_list, there exist no last_para
            else
                let comma = ','      "comma exists
            endif

            "type
            let type = value[0]

            "Draw para by config
            "Only draw port or draw all
            if (g:atv_autopara_only_port == 1 && type == 'port') || (g:atv_autopara_only_port == 0)
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
                        if g:atv_autopara_para_new == 1
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

                "in case special case happen(last parameter has been put in keep_io_list, there exist no last_para)
                "same time last line is not a parameter type, must record last_para index here
                let self_last_para_idx = index(lines,line) 

            endif
        endif
    "}}}4
    endfor

    "special case: last parameter has been put in keep_para_list, there exist no last_para
    if last_para_flag == 0
        "set last item as last_para
        let lines[self_last_para_idx] = substitute(lines[self_last_para_idx],',',' ','') 
    endif

    if para_list == []
    "remain port in para_list
    else
        if g:atv_autopara_para_del == 1
            for p_name in para_list
                let line = prefix.'//PARA_DEL: Parameter '.p_name.' has been deleted.'
                call add(lines,line)
            endfor
        endif
    endif
    "}}}3

    if lines == []
        echohl ErrorMsg | echo "Error para_seqs input for function DrawPara! para_seqs has no parameter definition!" | echohl None
    endif

    return lines

endfunction
"}}}2

"DrawParaValue 按格式输出例化parameter-value{{{2
"--------------------------------------------------
" Function: DrawParaValue
" Input: 
"   para_seqs : new inst para sequences for align
"   para_list : old inst para name list
"
" Description:
" e.g draw parameter sequences as format of para-value
"    0     1         2               3                4                    5     6
"   [type, sequence, parameter_name, parameter_value, last_port_parameter, line, last_decl_parameter] 
"   [port,1,'A', '16',0,'',0]
"   [port,2,'B', '4'd11',0,'',0]
"   [keep,3,'c0','c0',0,'    //comment line',0]
"   [port,4,'C', '16'h55',1,'',0]
"   [decl,5,'D', '10_0000',0,'',0]
"   [decl,6,'E', ''HEAD'',0,'',1]
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
function s:DrawParaValue(para_seqs,para_list)
    let prefix = s:st_prefix.repeat(' ',4)
    let para_list = copy(a:para_list)

    "guarantee spaces width{{{3
    let max_lbracket_len = 0
    let max_rbracket_len = 0
    for seq in sort(map(keys(a:para_seqs),'str2nr(v:val)'),g:atv_sort_funcref)
        let value = a:para_seqs[seq]
        let p_name = value[2]
        let p_value = value[3]
        "prefix.'.'.p_name.name2bracket.'('.p_value.value2bracket.')'
        let max_lbracket_len = max([max_lbracket_len,len(prefix)+len('.')+len(p_name)+4,g:atv_autopara_name_pos])
        let max_rbracket_len = max([max_rbracket_len,max_lbracket_len+len('(')+len(p_value)+4,g:atv_autopara_sym_pos])
    endfor
    "}}}3

    "draw para{{{3
    let lines = []
    let last_para_flag = 0

    "para_list can be changed in function, therefore record if it's empty first
    if para_list == []
        let para_list_empty = 1
    else
        let para_list_empty = 0
    endif

    for seq in sort(map(keys(a:para_seqs),'str2nr(v:val)'),g:atv_sort_funcref)
        let value = a:para_seqs[seq]
        let type = value[0]
        "ignore single comment/ifdef line{{{4
        if type == 'keep' 
        "}}}4
        "add parameter line{{{4
        else
            "Format parameter sequences
            "    0     1         2               3                4               5
            "   [type, sequence, parameter_name, parameter_value, last_parameter, line] 

            "p_name
            let p_name = value[2]
            "p_value
            let p_value = value[3]

            "name2bracket
            let name2bracket = repeat(' ',max_lbracket_len-len(prefix)-len(p_name)-len('.'))

            "value2bracket
            "don't align tail if config
            if g:atv_autopara_tail_nalign == 1
                let value2bracket = ''
            else
                let value2bracket = repeat(' ',max_rbracket_len-max_lbracket_len-len('(')-len(p_value))
            endif

            "comma
            if g:atv_autopara_only_port == 0    "use all parameter
                let last_para = value[6]
            else                                "use only port parameter
                let last_para = value[4]
            endif

            if last_para == 1
                let comma = ' '         "space
                let last_para_flag = 1  "special case: last parameter has been put in keep_io_list, there exist no last_para
            else
                let comma = ','      "comma exists
            endif

            "type
            let type = value[0]

            "Draw para by config
            "Only draw port or draw all
            if (g:atv_autopara_only_port == 1 && type == 'port') || (g:atv_autopara_only_port == 0)
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
                        if g:atv_autopara_para_new == 1
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

                "in case special case happen(last parameter has been put in keep_io_list, there exist no last_para)
                "same time last line is not a parameter type, must record last_para index here
                let self_last_para_idx = index(lines,line) 

            endif
        endif
    "}}}4
    endfor

    "special case: last parameter has been put in keep_para_list, there exist no last_para
    if last_para_flag == 0
        "set last item as last_para
        let lines[self_last_para_idx] = substitute(lines[self_last_para_idx],',',' ','') 
    endif

    if para_list == []
    "remain port in para_list
    else
        if g:atv_autopara_para_del == 1
            for p_name in para_list
                let line = prefix.'//PARA_DEL: Parameter '.p_name.' has been deleted.'
                call add(lines,line)
            endfor
        endif
    endif
    "}}}3

    if lines == []
        echohl ErrorMsg | echo "Error para_seqs input for function DrawPara! para_seqs has no parameter definition!" | echohl None
    endif

    return lines

endfunction
"}}}2

"}}}1

