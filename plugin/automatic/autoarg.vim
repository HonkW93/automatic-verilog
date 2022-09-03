"-----------------------------------------------------------------------------
" Vim Plugin for Verilog Code Automactic Generation 
" Author:         HonkW
" Website:        https://honk.wang
" Last Modified:  2022/09/03 23:37
" File:           autoarg.vim
" Note:           AutoArg function self-made
"------------------------------------------------------------------------------

"Sanity checks 启动判断{{{1
if exists("g:loaded_automatic_verilog_autoarg")
    finish
endif
let g:loaded_automatic_verilog_autoarg = 1
"}}}1

"Defaults 默认配置{{{1

"AutoArg Config 自动声明配置
"+--------------+-----------------------------------------+
"|    st_pos    |             start position              |
"+--------------+-----------------------------------------+
"|   sym_pos    |          symbol name position           |
"+--------------+-----------------------------------------+
"|     mode     |   mode 0,no wrap; mode 1 wrap around    |
"+--------------+-----------------------------------------+
"|   io_clsf    |      input/output/inout classified      |
"+--------------+-----------------------------------------+
"| tail_nalign  | don't do alignment in tail when autoarg |
"+--------------+-----------------------------------------+
let g:_ATV_AUTOARG_DEFAULTS = {
            \'st_pos':      4,
            \'sym_pos':     32,
            \'mode':        1,
            \'io_clsf':     1,
            \'tail_nalign': 1
            \}
for s:key in keys(g:_ATV_AUTOARG_DEFAULTS)
    if !exists('g:atv_autoarg_' . s:key)
        let g:atv_autoarg_{s:key} = copy(g:_ATV_AUTOARG_DEFAULTS[s:key])
    endif
endfor
let g:atv_autoarg_tail_nalign = g:atv_autoarg_mode ? 1 : g:atv_autoarg_tail_nalign
let s:st_prefix = repeat(' ',g:atv_autoarg_st_pos)
"}}}1

"Keys 快捷键{{{1
amenu 9998.1.1 &Verilog.AutoArg.AutoArg()<TAB>                          :call g:AutoArg()<CR>
amenu 9998.1.2 &Verilog.AutoArg.KillAutoArg()<TAB>                      :call g:KillAutoArg()<CR>

if !hasmapto(':call g:AutoArg()<ESC>')
    map <S-F2>      :call g:AutoArg()<ESC>
endif
"}}}1

"AutoArg 自动声明{{{1
"--------------------------------------------------
" Function: AutoArg
" Input: 
"   N/A
" Description:
"   auto argument for input/output/inout
" Output:
"   Formatted autoarg code
" Note:
"   list of port sequences
"            0     1        2       3       4       5            6          7
"   value = [type, sequence,io_dir, width1, width2, signal_name, last_port, line ]
"   io_seqs = {seq : value }
"   io_names = {signal_name : value }
"---------------------------------------------------
function! g:AutoArg() abort
    "AutoArg must open 95_support
    if g:atv_autoinst_95_support == 0
        echohl ErrorMsg | echo "Error because AutoArg must be used in verilog-95 but atv_autoinst_95_support not open! " | echohl None
    endif

    "Record current position
    let orig_idx = line('.')
    let orig_col = col('.')

    "AutoArg all start from top line
    call cursor(1,1)

    while 1
        "Put cursor to /*autoarg*/ line
        if search('\/\*autoarg\*\/','W') == 0
            break
        endif

        "Skip comment line //
        if getline('.') =~ '^\s*\/\/'
            continue
        endif

        "Get io sequences {sequence : value} from current buffer
        let lines = getline(1,line('$'))
        let io_seqs = g:AutoVerilog_GetIO(lines,'seq')
        let io_names = g:AutoVerilog_GetIO(lines,'name')

        "Kill all contents under /*autoarg*/
        "Current position must be at /*autoarg*/ line
        call s:KillAutoArg()

        "Draw io argument, use io_seqs
        let lines = s:DrawArg(io_seqs)

        "Delete current line );
        let line = substitute(getline(line('.')),')\s*;','','')
        call setline(line('.'),line)
        "Append io port and );
        call add(lines,');')
        call append(line('.'),lines)

        "only autoarg once
        break

    endwhile

    "cursor back
    call cursor(orig_idx,orig_col)

endfunction
"}}}1

"KillAutoArg Kill自动声明{{{1
"--------------------------------------------------
" Function: KillAutoArg
" Input: 
"   N/A
" Description:
"   kill auto argument
" Output:
"   Killed autoarg code
"---------------------------------------------------
function! g:KillAutoArg() abort

    "AutoArg must open 95_support
    if g:atv_autoinst_95_support == 0
        echohl ErrorMsg | echo "Error because KillAutoArg must be used in verilog-95 but atv_autoinst_95_support not open! " | echohl None
    endif

    "Record current position
    let orig_idx = line('.')
    let orig_col = col('.')

    "AutoArg all start from top line
    call cursor(1,1)

    while 1
        "Put cursor to /*autoarg*/ line
        if search('\/\*autoarg\*\/','W') == 0
            break
        endif

        "Skip comment line //
        if getline('.') =~ '^\s*\/\/'
            continue
        endif

        "Kill all contents under /*autoarg*/
        "Current position must be at /*autoarg*/ line
        call s:KillAutoArg()

        "only autoarg once
        break
    endwhile

    "cursor back
    call cursor(orig_idx,orig_col)

endfunction
"}}}1

"Sub Function 辅助函数{{{1

"AutoArg-Get (Refer to GetIO)

"AutoArg-Kill
"KillAutoArg 删除所有声明{{{2
"--------------------------------------------------
" Function: KillAutoArg
" Input: 
"   Must put cursor to /*autoarg*/ position
" Description:
" e.g kill all declaration after /*autoarg*/
"    
"   module_name
"   (   
"       /*autoarg*/
"       //Input
"       port_a,port_b,
"       //Input
"       port_c,port_d
"   );
"   
"   --------------> after KillAutoArg
"
"   module_name
"   (   
"       /*autoarg*/);
"
" Output:
"   line after kill
"---------------------------------------------------
function s:KillAutoArg() 
    let orig_idx = line('.')
    let orig_col = col('.')
    let idx = line('.')
    let line = getline(idx)
    if line =~ '/\*\<autoarg\>'
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
                    echohl ErrorMsg | echo "Error running KillAutoArg! Kill abnormally till the end!"| echohl None
                    break
                "middle
                else
                    "call deletebufline('%',idx)
                    execute ':'.idx.'d'
                endif
            endwhile
        endif
    else
        echohl ErrorMsg | echo "Error running KillAutoArg! Kill line not match /*autoarg*/ !"| echohl None
    endif
    "cursor back
    call cursor(orig_idx,orig_col)
endfunction
"}}}2

"AutoArg-Draw
"DrawArg 按格式输出例化声明{{{2
"--------------------------------------------------
" Function: DrawArg
" Input: 
"   io_seqs : new inst io sequences for align
"
" Description:
" e.g draw io argument sequences
"   [wire,1,input,'c0','c0',clk,0,'       input       clk,']
"   [reg,5,output,31,0,port_b,0,'    output reg [31:0] port_b']
"   module_name
"   (
"       clk,
"       port_b
"   );
"
" Output:
"   line that's aligned(in different ways)
"---------------------------------------------------
function s:DrawArg(io_seqs)
    let prefix = s:st_prefix

    "guarantee spaces width{{{3
    let max_comma_len = 0
    for seq in sort(map(keys(a:io_seqs),'str2nr(v:val)'),g:atv_sort_funcref)
        let value = a:io_seqs[seq]
        let type = value[0]
        if type != 'keep' 
            let name = value[5]
            "calculate maximum len of position to Draw
            "prefix.name.name2comma
            let max_comma_len = max([max_comma_len,len(prefix)+len(name)+4,g:atv_autoarg_sym_pos])
        endif
    endfor
    "}}}3

    "draw io argument{{{3

    "input/output/inout not classified{{{4
    if g:atv_autoarg_io_clsf == 0

        "get io first{{{5
        let io_lines = []
        for seq in sort(map(keys(a:io_seqs),'str2nr(v:val)'),g:atv_sort_funcref)
            let value = a:io_seqs[seq]
            let type = value[0]
            let line = value[7]
            if type != 'keep' 
                "Format IO sequences
                "   [type, sequence, io_dir, width1, width2, signal_name, last_port, line ]
                "name
                let name = value[5]

                "name2comma
                "don't align tail if config
                if g:atv_autoarg_tail_nalign == 1
                    let name2comma= ''
                else
                    let name2comma = repeat(' ',max_comma_len-len(prefix)-len(name))
                endif

                "comma
                let last_port = value[6]
                if last_port == 1
                    let comma = ' '      "space
                else
                    let comma = ','      "comma exists
                endif

                "get line
                let line = name.name2comma.comma
                call add(io_lines,line)
            endif
        endfor
        "}}}5

        "draw io{{{5
        let lines = []
        let max_len = g:atv_autoarg_sym_pos
        let cur_len = 0
        let wrap_line = prefix
        "mode 0, no wrap
        if g:atv_autoarg_mode == 0
            for line in io_lines
                call add(lines,prefix.line)
            endfor
        endif
        "mode 1, wrap around
        if g:atv_autoarg_mode == 1
            for line in io_lines
                if cur_len + len(line.' ') < max_len
                    let wrap_line = wrap_line.line.' '
                    let cur_len = cur_len + len(line.' ')
                else
                    call add(lines,wrap_line)
                    let wrap_line = prefix.line.' '
                    let cur_len = len(prefix.line.' ')
                endif
            endfor
            call add(lines,wrap_line)
        endif
        "}}}5

        let lines[-1] = substitute(lines[-1],',\s*$','','') 

    endif
    "}}}4
    
    "input/output/inout classified{{{4
    if g:atv_autoarg_io_clsf == 1
        "get inputs/outputs/inouts first{{{5
        let inputs = []
        let outputs = []
        let inouts = []
        for seq in sort(map(keys(a:io_seqs),'str2nr(v:val)'),g:atv_sort_funcref)
            let value = a:io_seqs[seq]
            let type = value[0]
            let line = value[7]
            let io_dir = value[2]
            if type != 'keep' 
                "Format IO sequences
                "   [type, sequence, io_dir, width1, width2, signal_name, last_port, line ]
                "name
                let name = value[5]

                "name2comma
                "don't align tail if config
                if g:atv_autoarg_tail_nalign == 1
                    let name2comma= ''
                else
                    let name2comma = repeat(' ',max_comma_len-len(prefix)-len(name))
                endif

                "comma
                let comma = ','      "comma exists

                "get line
                let line = name.name2comma.comma

                if io_dir == 'input'
                    call add(inputs,line)
                endif
                if io_dir == 'output'
                    call add(outputs,line)
                endif
                if io_dir == 'inout'
                    call add(inouts,line)
                endif

            endif
        endfor
        "}}}5

        "draw input{{{5
        let lines = []
        let max_len = g:atv_autoarg_sym_pos

        let cur_len = 0
        let wrap_line = prefix
        if inputs != []
            call add(lines,prefix.'//Inputs')
            "mode 0, no wrap
            if g:atv_autoarg_mode == 0
                for input in inputs
                    call add(lines,prefix.input)
                endfor
            endif
            "mode 1, wrap around
            if g:atv_autoarg_mode == 1
                for input in inputs
                    if cur_len + len(input.' ') < max_len
                        let wrap_line = wrap_line.input.' '
                        let cur_len = cur_len + len(input.' ')
                    else
                        call add(lines,wrap_line)
                        let wrap_line = prefix.input.' '
                        let cur_len = len(prefix.input.' ')
                    endif
                endfor
                call add(lines,wrap_line)
            endif
        endif
        "}}}4

        "draw output{{{5
        let cur_len = 0
        let wrap_line = prefix
        if outputs != []
            call add(lines,prefix.'//Outputs')
            "mode 0, no wrap
            if g:atv_autoarg_mode == 0
                for output in outputs
                    call add(lines,prefix.output)
                endfor
            endif
            "mode 1, wrap around
            if g:atv_autoarg_mode == 1
                for output in outputs
                    if cur_len + len(output.' ') < max_len
                        let wrap_line = wrap_line.output.' '
                        let cur_len = cur_len + len(output.' ')
                    else
                        call add(lines,wrap_line)
                        let wrap_line = prefix.output.' '
                        let cur_len = len(prefix.output.' ')
                    endif
                endfor
                call add(lines,wrap_line)
            endif
        endif
        "}}}5
        
        "draw inout{{{5
        let cur_len = 0
        let wrap_line = prefix
        if inouts != []
            call add(lines,prefix.'//Inouts')
            "mode 0, no wrap
            if g:atv_autoarg_mode == 0
                for inout in inouts
                    call add(lines,prefix.inout)
                endfor
            endif
            "mode 1, wrap around
            if g:atv_autoarg_mode == 1
                for inout in inouts
                    if cur_len + len(inout.' ') < max_len
                        let wrap_line = wrap_line.inout.' '
                        let cur_len = cur_len + len(inout.' ')
                    else
                        call add(lines,wrap_line)
                        let wrap_line = prefix.inout.' '
                        let cur_len = len(prefix.inout.' ')
                    endif
                endfor
                call add(lines,wrap_line)
            endif
        endif
        "}}}5

        let lines[-1] = substitute(lines[-1],',\s*$','','') 
    endif
    "}}}4

    "}}}3

    if lines == []
        echohl ErrorMsg | echo "Error io_seqs input for function DrawArg! io_seqs has no input/output definition! Possibly written in verilog-95 but atv_autoinst_95_support not open " | echohl None
    endif

    return lines

endfunction
"}}}2

"}}}1

