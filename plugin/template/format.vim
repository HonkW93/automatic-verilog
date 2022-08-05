
"Functions for Foramat Adjust {{{1
if g:atv_personal_keys == 0
    finish
endif

nnoremap <S-F1> :call FormatAdjust()<CR>

"input/output port adjust{{{2
function PortAdjust(line,cmts)
    let line = a:line   "line without comments
    let cmts = a:cmts   "comments

    "extract {{{3
    let prefix = repeat(' ',4)
    let port = matchstr(line,'\v<input>|<output>')      "input/output
    let type = matchstr(line,'\v<wire>|<reg>')          "wire/reg
    "[31:0]
    let width = matchstr(line,'\[.*\]')                 
    let width = substitute(width,'\s*','','g')          "delete redundant space
    "name
    if line =~ '\v(\w+)(\s*$)'  "last line
        let name = matchstr(line,'\v(\w+)(\s*$)@=')
    else                        "other line
        let name = matchstr(line,'\v(\w+)(\s*,)@=') 
    endif
    "}}}3

    "insert space {{{3
    "port2type
    if port == 'input'
        let port2type = repeat(' ',2)
    elseif port == 'output'
        let port2type = repeat(' ',1)
    endif
    "type2width
    if type == 'reg'
        let type2width = repeat(' ',2)
    elseif type == 'wire'
        let type2width = repeat(' ',1)
    else
        let type2width = repeat(' ',5)      "align to 5 blanks
        "let type2width = ''                "align to input if no wire/reg
    endif
    "width2name
    let width2name_len = s:pos_name - len(prefix.port.port2type.type.type2width.width)
    let width2name = repeat(' ',width2name_len)
    "name2comma
    let name2cma_len = s:pos_symbol - len(prefix.port.port2type.type.type2width.width.width2name.name)
    let name2cma = repeat(' ',name2cma_len)
    "comma
    let cma = matchstr(line,',')
    if cma != ','
        let cma = ' '
    endif
    "comma2comments
    let cma2cmts = repeat(' ',4)
    "}}}3
    
    "pairup {{{3
    let line = prefix.port.port2type.type.type2width.width.width2name.name.name2cma.cma.cma2cmts.cmts
    return line
    "}}}3

endfunction
"}}}2

"reg/wire adjust{{{2
function WireRegAdjust(line,cmts)
    let line = a:line   "line without comments
    let cmts = a:cmts   "comments

    "extract & insert space {{{3
    let prefix = repeat(' ',4)
    let type = matchstr(line,'\v<wire>|<reg>')          "wire/reg
    let width = matchstr(line,'\[.*\]')                 "[31:0]
    let width = substitute(width,'\s*','','g')          "delete redundant space
    "type2width
    if type == 'reg'
        let type2width = repeat(' ',2)
    elseif type == 'wire'
        let type2width = repeat(' ',1)
    endif
    "width2name
    let width2name_len = s:pos_name - len(prefix.type.type2width.width)
    let width2name = repeat(' ',width2name_len)
    "comma2comments
    let cma2cmts = repeat(' ',4) 
    "}}}3

    "results {{{3
    let results = []
    let names = split(line,',\zs') 
    let name = ''
    for name in names
        "match word + ,
        if name =~ '\v\w+\s*,'
            let name = matchstr(name,'\v(\w+\s*)(,)@=')
            "name2comma
            let name2cma_len = s:pos_symbol - len(prefix.type.type2width.width.width2name.name)
            let name2cma = repeat(' ',name2cma_len)
            let results = add(results,prefix.type.type2width.width.width2name.name.name2cma.';'.cma2cmts.cmts)
            "match word + ;
        elseif name =~ '\v\w+\s*;' 
            let name = matchstr(name,'\v(\w+\s*)(;)@=')
            "name2comma
            let name2cma_len = s:pos_symbol - len(prefix.type.type2width.width.width2name.name)
            let name2cma = repeat(' ',name2cma_len)
            let results = add(results,prefix.type.type2width.width.width2name.name.name2cma.';'.cma2cmts.cmts)
        endif
    endfor

    return results
    "}}}3
    
endfunction
"}}}2

"parameter/localparam adjust{{{2
function ParaAdjust(line,cmts)
    let line = a:line   "line without comments
    let cmts = a:cmts   "comments
    "extract & insert space {{{3
    let prefix = repeat(' ',4)
    let type = matchstr(line,'\v<parameter>|<localparam>')  "parameter/localparam
    "type2name
    let type2name_len = s:pos_name - len(prefix.type)
    let type2name = repeat(' ',type2name_len)
    "comma2comments
    let cma2cmts = repeat(' ',4)
    "}}}3

    "results {{{3
    let results = []
    let formulas = split(line,',\zs') 
    let formula = ''

    for formula in formulas
        "match name
        let name = matchstr(formula,'\v(\w+)(\s*\=)@=')
        "match name = xxx ,
        if formula =~ '\v\w+\s*,'
            let value = matchstr(formula,'\v(\=\s*)@<=(\S.*\S)(\s*,)@=')    "match = ... ,
            let value = substitute(value,'\s*','','g')                      "delete all space
            "value2comma
            let value2cma_len = s:pos_symbol - len(prefix.type.type2name.name.' = '.value)
            let value2cma = repeat(' ',value2cma_len)
        "match name = xxx ;
        elseif formula =~ '\v\w+\s*;' 
            let value = matchstr(formula,'\v(\=\s*)@<=(\S.*\S)(\s*;)@=')    "match = ... ;
            let value = substitute(value,'\s*','','g')                      "delete all space
            "value2comma
            let value2cma_len = s:pos_symbol - len(prefix.type.type2name.name.' = '.value)
            let value2cma = repeat(' ',value2cma_len)
        endif
        "get results
        let results = add(results,prefix.type.type2name.name.' = '.value.value2cma.';'.cma2cmts.cmts)
    endfor
    return results
    "}}}3
    
endfunction
"}}}2

"}}}1

"Function for Re-align parameter/localparam {{{1
function AlignPara()
    let idx = 0
    while idx < line('$')
        let idx += 1
        let line = getline(idx)
        let line = substitute(substitute(line,'\/\*.*\*\/','',''),'\/\/.*','','')           "delete comments

        "record position {{{2
        let idx_start = idx             "record start
        let max_len = 0
        if line =~ '\v^\s*(<parameter>|<localparam>)'                                       "first line match parameter
            while 1
                if line =~ '\v^\s*(<parameter>|<localparam>)'                               "next line match parameter
                    let name = matchstr(line,'\v(\w+)(\s*\=)@=')
                    if len(name) > max_len
                        let max_len = len(name)
                    endif
                else
                    let idx -= 1
                    break
                endif
                let idx += 1                                                           
                let line = getline(idx)                                                     "next line
                let line = substitute(substitute(line,'\/\*.*\*\/','',''),'\/\/.*','','')   "delete comments
            endwhile
        endif
        let idx_end = idx               "record end
        "}}}2

        "process parameter|localparam align {{{2
        if idx_start != idx_end
            for i in range(idx_start,idx_end)
                let line = getline(i)
                let cmts = matchstr(line,'\/\*.*\*\/') . matchstr(line,'\/\/.*')            "comments
                let line = substitute(substitute(line,'\/\*.*\*\/','',''),'\/\/.*','','')   "delete comments
                "extract & insert space
                let prefix = repeat(' ',4)
                let type = matchstr(line,'\v<parameter>|<localparam>')                      "parameter/localparam
                "type2name
                let type2name_len = s:pos_name - len(prefix.type)
                let type2name = repeat(' ',type2name_len)
                "comma2comments
                let cma2cmts = repeat(' ',4)
                "match name & value
                let name = matchstr(line,'\v(\w+)(\s*\=)@=')
                let value = matchstr(line,'\v(\=\s*)@<=(\S.*\S)(\s*;)@=')       "match = ... ;
                let value = substitute(value,'\s*','','g')                      "delete all space
                "name2equal
                let name2eql_len = max_len - len(name)
                let name2eql = repeat(' ',name2eql_len)
                "value2comma
                let value2cma_len = s:pos_symbol - len(prefix.type.type2name.name.name2eql.' = '.value)
                let value2cma = repeat(' ',value2cma_len)
                "get results
                let line = prefix.type.type2name.name.name2eql.' = '.value.value2cma.';'.cma2cmts.cmts
                call setline(i,line)
            endfor
        endif
        "}}}2
        
    endwhile
endfunction
"}}}1

"Function for Align always block {{{1
function AlignAlways()
    let idx = 0
    let tab = 0
    let sts = ''
    let busy = ''
    let else_sts = ''
    while idx < line('$')
        let idx = idx + 1
        let line = getline(idx)
        let cmts = matchstr(line,'\/\*.*\*\/') . matchstr(line,'\/\/.*')            "comments
        let line = substitute(substitute(line,'\/\*.*\*\/','',''),'\/\/.*','','')   "delete comments

        "start by always block
        if line =~ '^\s*always\s*@'
            let tab = 1
            call setline(idx,repeat(' ',4*tab).substitute(line,'^\s*','',''))
            let sts = 'if'
            let busy = 1
        endif

        "ajust only when meeting always block
        if busy == 1

            "if / case / IDLE:begin
            if line =~ '^\s*if' || (line =~ '^\s*case' || line =~':\s*begin')
                if sts == 'if'          "if follow if, tab + 1
                    let tab += 1
                    call setline(idx,repeat(' ',4*tab).substitute(line,'^\s*','',''))
                elseif sts=='end'       "if follow end, tab keep
                    call setline(idx,repeat(' ',4*tab).substitute(line,'^\s*','',''))
                endif
                let sts = 'if'

            "else , tab keep
            elseif line =~ '^\s*else'
                call setline(idx,repeat(' ',4*tab).substitute(line,'^\s*','',''))
                let sts = 'if'
                if line !~ 'begin'
                    let else_sts = 'end'
                endif

            "begin , tab keep 
            elseif line =~ '^\s*begin'
                call setline(idx,repeat(' ',4*tab).substitute(line,'^\s*','',''))
                let sts = 'if'
                let else_sts = 'end_finish'

            "end
            elseif line =~ '^\s*end'
                if else_sts == 'end' || sts == 'end' "end follow end , tab - 1
                    let tab -= 1
                    call setline(idx,repeat(' ',4*tab).substitute(line,'^\s*','',''))

                    let else_sts = 'end_finish'
                    if tab == 1
                        let busy = 0
                    end
                elseif sts == 'if'                   "end follow if , tab keep
                    call setline(idx,repeat(' ',4*tab).substitute(line,'^\s*','',''))
                endif
                let sts = 'end'

            "normal
            elseif tab > 1
                if sts == 'if'          "follow if, tab + 1
                    call setline(idx,repeat(' ',4*(tab+1)).substitute(line,'^\s*','',''))
                elseif sts == 'end'     "follow end tab keep
                    call setline(idx,repeat(' ',4*tab).substitute(line,'^\s*','',''))
                endif
            endif

        endif

    endwhile
endfunction
"}}}1

"Main Function: Format Adjust for verilog {{{1
function FormatAdjust()
    "pre-define position to place
    let s:pos_name = 32
    let s:pos_symbol = 64

    "align always block{{{2
    call AlignAlways()
    "}}}2

    "align input/output, reg/wire, localparam/parameter, delete redundant space {{{2
    let idx = 0
    while idx < line('$')
        let idx = idx + 1
        let line = getline(idx)
        let cmts = matchstr(line,'\/\*.*\*\/') . matchstr(line,'\/\/.*')            "comments
        let line = substitute(substitute(line,'\/\*.*\*\/','',''),'\/\/.*','','')   "delete comments


        "input/output port adjust {{{3
        if line =~ '\v^\s*(<input>|<output>)'
            "adjust current line
            let line = PortAdjust(line,cmts)
            call setline(idx,line)
        endif
        "}}}3

        "reg/wire adjust {{{3
        if line =~ '\v^\s*(<reg>|<wire>)'
            let results = WireRegAdjust(line,cmts)
            "adjust from current line
            call setline(idx,results[0])
            call append(idx,results[1:])
            "update index
            let idx = idx + len(results)-1 
        endif 
        "}}}3

        "localparam/parameter adjust {{{3
        if line =~ '\v^\s*(<parameter>|<localparam>)'
            let results = ParaAdjust(line,cmts)
            "adjust from current line
            call setline(idx,results[0])
            call append(idx,results[1:])
            "update index
            let idx = idx + len(results)-1
        endif
        "}}}3

        "redundant space deletion {{{3

        "delete redundant line
        if cmts == '' && line =~ '^\s*$'
            call setline(idx,'')
        endif

        "delete redundant space in the end
        let line = getline(idx)
        if line =~ '\v\s+$'
            let line = substitute(line,'\v\s+$','','')
            call setline(idx,line)
        endif
        "}}}3

    endwhile
    "}}}2

    "realign localparam/parameter{{{2
    call AlignPara()
    "}}}2

endfunction

"}}}1
