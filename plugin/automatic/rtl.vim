"-----------------------------------------------------------------------------
" Vim Plugin for Verilog Code Automactic Generation 
" Author:         HonkW
" Website:        https://honk.wang
" Last Modified:  2022/09/17 21:46
" File:           rtl.vim
" Note:           RtlTree function refactor from zhangguo's original script
"------------------------------------------------------------------------------

"Sanity checks 启动判断{{{1
if exists("g:loaded_automatic_verilog_rtl")
    finish
endif
let g:loaded_automatic_verilog_rtl = 1
"}}}1

" Verilog Type 定义Verilog变量类型{{{1

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

"Rtl Config Rtl配置
let g:_ATV_RTL_DEFAULTS = {
            \'recursive':   0,
            \'refresh':     "r",
            \'quit':        "q",
            \'open':        "o",
            \'inst':        "i",
            \'fold':        "<CR>",
            \'ver':         "1.0"
            \}
for s:key in keys(g:_ATV_RTL_DEFAULTS)
    if !exists('g:atv_rtl_' . s:key)
        let g:atv_rtl_{s:key} = copy(g:_ATV_RTL_DEFAULTS[s:key])
    endif
endfor

command -nargs=? -complete=file RtlTree :call <SID>RtlTree(<f-args>)

"}}}1

"RtlTree Rtl树{{{1

"Rtl Tree Build
let s:oTreeNode = {}
let s:rtltree = {}
function s:oTreeNode.New() "{{{2
    let newTreeNode = copy(self)
    let newTreeNode.parent = "rtl"
    let newTreeNode.mname = "rtl"
    let newTreeNode.iname = "u_rtl"
    let newTreeNode.fname = ""
    let newTreeNode.idx = 1
    let newTreeNode.children = []
    let newTreeNode.unresolved = 0
    let newTreeNode.layer = -1
    let newTreeNode.fold = 1
    let newTreeNode.child_created = 0
    return newTreeNode
endfunction
"}}}2
function s:oTreeNode.CreateTree(level) "{{{2
    "add parent node
    call extend(s:rtltree,{self.iname : self})

    "none recursive create must have 2-level because 
    " '+' needed for children's child
    "e.g.
    "   ~ top
    "     + top_child
    if a:level == 2
        return
    endif

    "show progress
    redraw
    echo 'Building node '.(self.iname).'......'

    "create child node
    if self.CreateChildren() == []
        return
    elseif g:atv_rtl_recursive == 1
        "recursive creation
        for node in self.children
            call node.CreateTree(0)
        endfor
    else
        "none recursive creation
        for node in self.children
            call node.CreateTree(a:level+1)
        endfor
    endif
endfunction
function s:oTreeNode.CreateChildren() "{{{3
    "search file for unresolved
    if has_key(s:modules,self.mname)
        let file = s:modules[self.mname]
        let dir = s:files[file]
        let self.fname = dir.'/'.file
        let self.unresolved = 0
    else
        let self.fname = ""
        let self.unresolved = 1
    endif
    "search inst if resolved
    if self.unresolved == 0

        let module_seqs = s:GetModuleInst(readfile(self.fname),self.mname)
        if module_seqs == {}
            return []
        else
            let self.children = []
            for seq in sort(map(keys(module_seqs),'str2nr(v:val)'),g:atv_sort_funcref)
                let value = module_seqs[seq]
                let child_node = s:oTreeNode.New()
                let child_node.parent = self
                let child_node.mname = value[0]
                let child_node.iname = value[1]
                let child_node.idx = value[2]
                let child_node.layer = self.layer + 1
                call add(self.children,child_node)
            endfor
            return self.children
        endif
    else
        return []
    endif
endfunction
"}}}3
"}}}2
function s:oTreeNode.Expand() "{{{2
    let node = copy(self)
    "mark node as unfold
    let node.fold = 0
    call extend(s:rtltree,{node.iname : node})
    call append(".",node.Draw([]))
endfunction
function s:oTreeNode.Draw(lines) "{{{3
    for child in self.children
        "use tree node while child node list does'nt have fname & unresolved
        let node = s:rtltree[child.iname]
        let prefix = repeat("  ",node.layer)
        "process '~' & '+'
        if node.children == []
            let line = prefix."~ ".(node.iname)
        else
            if node.fold == 0
                let line = prefix."~ ".(node.iname)
            elseif node.fold == 1
                let line = prefix."+ ".(node.iname)
            endif
        endif
        "process unresolved
        if node.unresolved == 1
            let line = line." (".(node.mname)." - unresolved)"
        else
            let line = line." (".(node.mname).")"
        endif
        "draw line
        call add(a:lines,line)
        "node already expanded, draw it's sub-node
        if node.fold == 0
            call node.Draw(a:lines)
        endif
    endfor
    return a:lines
endfunction 
"}}}3
"}}}2
function s:oTreeNode.Shrink() "{{{2
    let node = copy(self)
    "mark node as unfold
    let node.fold = 1
    call extend(s:rtltree,{node.iname : node})
    let orig_idx = line(".")
    let orig_col = col(".")
    let prefix = matchstr(getline("."),'^\s*')
    call cursor(line(".")+1,col("."))
    while 1
        if(getline(".") =~ '^'.prefix.'\s\+')
            execute 'normal dd'
        else
            break
        endif
    endwhile
    call cursor(orig_idx,orig_col)
endfunction
"}}}2

"Rtl Main
let s:RtlTreeBufName = "RtlTree"."("."top".")"
let s:RtlTreeWinWidth = 31
let s:RtlCurBufName = expand("%")
function s:RtlTree(...) "{{{2
    if a:0 == 0
        let file = expand("%")
    else
        let file = a:1
    endif
    if bufexists(s:RtlTreeBufName)
        call s:CloseRtl()
        "give another file, reopen
        if a:0 != 0
            call s:OpenRtl(file)
        endif
    else
        call s:OpenRtl(file)
    endif
endfunction
function s:CloseRtl() abort "{{{3
    execute bufwinnr(s:RtlTreeBufName) . "wincmd w"
    close
    execute bufwinnr(s:RtlCurBufName) . "wincmd w"
    execute "bwipeout ".s:RtlTreeBufName
endfunction
"}}}3
function s:OpenRtl(file) abort "{{{3
    let [s:files,s:modules] = g:AutoVerilog_GetModuleFileDirDic()
    "Get top file
    let s:rtl_top_file = fnamemodify(a:file,':p')
    let lines = readfile(s:rtl_top_file)
    let s:rtl_top_module = s:GetModule(lines)
    if s:rtl_top_module == ""
        echohl ErrorMsg | echo "top file have no module definition, error generate RtlTree" | echohl None
        return
    endif
    "Create RtlTree
    let node = s:oTreeNode.New()
    let node.parent = "rtl"
    let node.mname = s:rtl_top_module
    let node.iname = "u_".s:rtl_top_module
    let node.fname = s:rtl_top_file
    let node.children = []
    let node.layer = 0
    let node.child_created = 1
    call node.CreateTree(0)
    "forbid mouse behavior change when using this plugin, possible problem here
    let s:save_mouse = &mouse
    "Create Window for RtlTree
    let s:RtlCurBufName = bufname("%")
    let s:RtlTreeBufName = "RtlTree"."(".s:rtl_top_module.")"
    silent! exe 'aboveleft ' . 'vertical ' . s:RtlTreeWinWidth . ' new '.s:RtlTreeBufName
    execute bufwinnr(s:RtlTreeBufName) . "wincmd w"
    call s:SetRtlBufOpt()
    call s:SetRtlBufAu()
    call s:SetRtlBufHl()
    call s:SetRtlBufKey()
    call setline(1,'" Press ? for help')
    call setline(2,"")
    call append(2,"RtlTree")
    call append(3,"~ ".("u_".s:rtl_top_module)." (".(s:rtl_top_module).")")
    call cursor(4,1)
    call node.Expand()
endfunction
function s:SetRtlBufOpt()
    setlocal cursorline
    setlocal nowrap
    setlocal nomodified
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal nospell
    setlocal nonumber
endfunction
function s:SetRtlBufAu()
    if exists("#QuitPre")
        execute "autocmd QuitPre <buffer> bwipeout ".s:RtlTreeBufName
    endif
    execute "autocmd BufEnter,WinEnter <buffer> stopinsert"
    "mouse support
    execute "autocmd BufEnter,WinEnter ".s:RtlTreeBufName." set mouse=n"
    execute "autocmd BufLeave,BufDelete <buffer> set mouse=".s:save_mouse
endfunction
function s:SetRtlBufHl()
    hi def link RtlTree Directory
    execute "syn match RtlTree #". "RtlTree" ."#"
    execute "syn match RtlTree #". '\~' ."#"
    execute "syn match RtlTree #". '+' ."#"
    hi def link RtlTreeTop Special
    execute "syn match RtlTreeTop #". s:rtl_top_module ."#"
    execute "syn match RtlTreeTop #". "u_". s:rtl_top_module ."#"
    hi def link RtlTreeUnresolved WarningMsg
    execute "syn match RtlTreeUnresolved #unresolved#"
    hi def link RtlTreeHelp PreProc
    execute 'syn match RtlTreeHelp #".*#'
endfunction
function s:SetRtlBufKey()
    "nnoremap <buffer> <silent> r :call <SID>CreateRtl()<CR>
    execute "nnoremap <buffer> <silent> ".g:atv_rtl_refresh." :call <SID>CreateRtl()<CR>"
    "nnoremap <buffer> <silent> q :call <SID>CloseRtl()<CR>
    execute "nnoremap <buffer> <silent> ".g:atv_rtl_quit." :call <SID>CloseRtl()<CR>"
    "nnoremap <buffer> <silent> o :call <SID>OpenRtlModule()<CR>
    execute "nnoremap <buffer> <silent> ".g:atv_rtl_open." :call <SID>OpenRtlModule()<CR>"
    "nnoremap <buffer> <silent> i :call <SID>OpenRtlInst()<CR>
    execute "nnoremap <buffer> <silent> ".g:atv_rtl_inst." :call <SID>OpenRtlInst()<CR>"
    "nnoremap <buffer> <silent> <CR> :call <SID>FoldRtl()<CR>
    execute "nnoremap <buffer> <silent> ".g:atv_rtl_fold." :call <SID>FoldRtl()<CR>"
    nnoremap <buffer> <silent> <leftrelease> :call <SID>OpenRtlInst()<CR>
    nnoremap <buffer> <silent> <2-leftmouse> :call <SID>FoldRtl()<CR>:call <SID>OpenRtlModule()<CR>
    nnoremap <buffer> <silent> ? :call <SID>RtlHelp()<CR>
endfunction
"}}}3
function s:FoldRtl() abort "{{{3
    let line = getline(".")
    let iname = matchstr(line,'\w\+')
    if has_key(s:rtltree,iname)
        let node = s:rtltree[iname]
    else
        return
    endif
    "expand
    if line =~ '^\s*+\s'
        "none recursive, rtl needed create while fold
        if g:atv_rtl_recursive==0 && node.child_created== 0
            call node.CreateTree(0)
            let node.child_created = 1
        endif
        "+ -> ~
        let line = substitute(line,'\(^\s*\)+\s','\1\~ ','')
        call setline(".",line)
        call node.Expand()
    "shrink
    elseif line =~ '^\s*\~\s' && len(node.children)>0
        "~ -> +
        let line = substitute(line,'\(^\s*\)\~\s','\1+ ','')
        call setline(".",line)
        call node.Shrink()
    endif
endfunction
"}}}3
function s:OpenRtlInst() abort "{{{3
    let line = getline(".")
    let iname = matchstr(line,'\w\+')
    if has_key(s:rtltree,iname)
        let node = s:rtltree[iname]
    else
        return
    endif
    "top node
    if type(node.parent) == 1
        echohl WarningMsg | echo "Top module ".(node.mname)." doesn't have instance!" | echohl None
    "not top node
    else
        let curbufexist = 0
        "check if current buffer exist
        if exists("*getbufinfo") 
            for buf in getbufinfo()
                if buf.name =~ fnamemodify(s:RtlCurBufName,':t') && buf.loaded == 1
                    let curbufexist = 1
                endif
            endfor
        else
            for nr in  filter(range(1,bufnr('$')),'buflisted(v:val)')
                let bufname = bufname(nr)
                let bufloaded = bufloaded(nr)
                if bufname =~ fnamemodify(s:RtlCurBufName,':t') && bufloaded == 1
                    let curbufexist = 1
                endif
            endfor
        endif
        "current buffer exist, jump to window
        if curbufexist == 1
            silent! exe bufwinnr(s:RtlCurBufName)." wincmd w"
            "unsaved changes exist open new window
            if &modified == 1
                silent! exe 'leftabove '.'new '
            endif
        "no current buffer, open new window
        else
            silent! exe 'rightbelow '.'vertical '. (&columns - s:RtlTreeWinWidth) . ' new '
        endif
        "edit parent file,cursor to inst position
        execute "edit ".(node.parent.fname)
        call cursor(node.idx,1)
        call search('\w\+')
        execute "normal zz"
        let s:RtlCurBufName = bufname("%")
        execute bufwinnr(s:RtlTreeBufName)."wincmd w"
    endif
endfunction
"}}}3
function s:OpenRtlModule() abort "{{{3
    let line = getline(".")
    let iname = matchstr(line,'\w\+')
    if has_key(s:rtltree,iname)
        let node = s:rtltree[iname]
    else
        return
    endif
    if node.unresolved == 1
        echohl WarningMsg | echo "inst ".iname.' unresolved' | echohl None
    else
        let curbufexist = 0
        "check if current buffer exist
        if exists("*getbufinfo") 
            for buf in getbufinfo()
                if buf.name =~ fnamemodify(s:RtlCurBufName,':t') && buf.loaded == 1
                    let curbufexist = 1
                endif
            endfor
        else
            for nr in  filter(range(1,bufnr('$')),'buflisted(v:val)')
                let bufname = bufname(nr)
                let bufloaded = bufloaded(nr)
                if bufname =~ fnamemodify(s:RtlCurBufName,':t') && bufloaded == 1
                    let curbufexist = 1
                endif
            endfor
        endif
        "current buffer exist, jump to window
        if curbufexist == 1
            silent! exe bufwinnr(s:RtlCurBufName)." wincmd w"
            "unsaved changes exist open new window
            if &modified == 1
                silent! exe 'leftabove '.'new '
            endif
        "no current buffer, open new window
        else
            silent! exe 'rightbelow '.'vertical '. (&columns - s:RtlTreeWinWidth) . ' new '
        endif
        "edit parent file,cursor to inst position
        execute "edit ".(node.fname)
        call search('^\s*module')
        call search(node.mname)
        execute "normal zz"
        let s:RtlCurBufName = bufname("%")
        execute bufwinnr(s:RtlTreeBufName)."wincmd w"
    endif
endfunction
"}}}3
function s:CreateRtl() abort "{{{3
    let node = s:oTreeNode.New()
    let node.parent = "rtl"
    let node.mname = s:rtl_top_module
    let node.iname = "u_".s:rtl_top_module
    let node.fname = s:rtl_top_file
    let node.children = []
    let node.layer = 0
    let node.child_created = 1
    "recursively refresh
    let save_recursive = g:atv_rtl_recursive 
    let g:atv_rtl_recursive = 1
    call node.CreateTree(0)
    let g:atv_rtl_recursive = save_recursive
endfunction
"}}}3
"}}}2

"Rtl Help
function s:RtlHelp() "{{{2
    let orig_idx = line(".")
    let orig_col = col(".")
    if getline(1) =~ '^"\sRtlTree'
        execute 'g/"/d'
        call append(0,'" Press ? for help')
    else
        execute '1d'
        let help  = '" '.'RtlTree'. '('. g:atv_rtl_ver.')'. 'quickhelp~'."\n"
        let help .= '" '.repeat('=',s:RtlTreeWinWidth)."\n"
        let help .= '" '. g:atv_rtl_refresh . ': refresh rtl tree'."\n"
        let help .= '" '. g:atv_rtl_quit    . ': close rtl tree'."\n"
        let help .= '" '. g:atv_rtl_open    . ': open module position'."\n"
        let help .= '" '. g:atv_rtl_inst    . ': open inst position'."\n"
        let help .= '" '. g:atv_rtl_fold    . ': fold rtl tree'."\n"
        let help .= '" '. '?'               . ': toggle help'."\n"
        call cursor(1,1)
        0put =help
    endif
    call cursor(orig_idx,orig_col)
endfunction
"}}}2

"}}}1

"Sub Function 辅助函数{{{1

"RemoveCommentLine 删除所有注释{{{2
function s:RemoveCommentLine(lines)
    let in_cmt = 0
    let proc_lines = []
    for line in a:lines
        "process //
        let line = substitute(line,'\/\/.*$','','g')
        "process /*...*/
        if line =~ '\/\*'
            if line =~ '\*\/'
                let line = substitute(line,'\/\*.\{-\}\*\/','','g')
                call add(proc_lines,line)
                continue
            else
                let line = substitute(line,'\/\*.*$','','')
                call add(proc_lines,line)
                let in_cmt = 1
                continue
            endif
        endif
        if in_cmt == 1
            if line =~ '\*\/'
                let line = substitute(line,'^.*\*\/','','')
                call add(proc_lines,line)
                let in_cmt = 0
                continue
            else
                let line = ''
                call add(proc_lines,line)
                continue
            endif
        endif
        "normal
        call add(proc_lines,line)
    endfor
    return proc_lines
endfunction
"}}}2

"RemoveOutsideModuleLine 删除所有Module外的行{{{2
"--------------------------------------------------
" Function: RemoveOutsideModuleLine()
"
" Description:
"   Remove lines outside specific module
"   e.g
"   module a();
"     uart u_uart();
"   endmodule
"   module b();
"     uart #(para=2) u_uart ();
"   endmodule
"
"   --->RemoveOutsideModuleLine(lines,a)
"
" Output:
"   module a();
"     uart #(para=2) u_uart ();
"   endmodule
"---------------------------------------------------
function s:RemoveOutsideModuleLine(lines,module)
    let find_module = 0
    let in_module = 0
    let multiline_module = ''
    let proc_lines = []
    for line in a:lines
        "single line
        if line =~ '^\s*module'
            if line =~ '^\s*module'.'\s\+'.a:module
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
            if line =~ '^\s*'.a:module 
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

"GetModuleInst 获取子模块的Module-Inst关系{{{2
"--------------------------------------------------
" Function: GetModuleInst
"
" Description:
"   Get Module-Inst Dict from lines
"   e.g
"     uart u_uart();
"     uart #(para=2) u_uart ();
"   seq -> use seq as key
"   sequences are the number when module appear in line
" Output:
"   Module-Inst dictionary
"   e.g module inst sequences
"   [module_name, inst_name, line_index]
"   [uart,        u_uart,    3]
"---------------------------------------------------
function s:GetModuleInst(lines,mname)
    let lines = s:RemoveCommentLine(a:lines)
    let lines = s:RemoveOutsideModuleLine(a:lines,a:mname)
    let module_lines = []
    let in_module = 0
    let module_seqs ={}
    let seq = 0
    let idx = 0
    let idx_flag = 0
    "module inst ();
    let module_inst_pattern = '^\s*'.'\('.s:not_keywords_pattern.'\)'.'\s\+'.'\('.s:not_keywords_pattern.'\)'.'\s*'.'(.*)'.'\s*;\s*$'
    "module #() inst ();
    let module_para_inst_pattern = '^\s*'.'\('.s:not_keywords_pattern.'\)'.'\s*#\s*'.'(.*)'.'\s*'.'\('.s:not_keywords_pattern.'\)'.'\s*'.'(.*)'.'\s*;\s*$'
    for line in lines
        let idx = idx + 1
        "one-line
        if line =~ '^\s*'.s:not_keywords_pattern
            call add(module_lines,line)
            "record line index
            if idx_flag ==0 
                let inst_idx = idx
            endif
            let idx_flag = 1
            if line =~';\s*$'
                "module inst ();
                if join(module_lines) =~ module_inst_pattern
                    let value = []
                    call substitute(join(module_lines),module_inst_pattern,'\=extend(value,[submatch(1),submatch(4)])','')
                    let seq = seq + 1
                    call add(value,inst_idx)
                    call extend(module_seqs,{seq : value})
                "module #() inst ();
                elseif join(module_lines) =~ module_para_inst_pattern
                    let value = []
                    call substitute(join(module_lines),module_para_inst_pattern,'\=extend(value,[submatch(1),submatch(4)])','')
                    let seq = seq + 1
                    call add(value,inst_idx)
                    call extend(module_seqs,{seq : value})
                endif
                let in_module = 0
                let module_lines = []
                let idx_flag = 0
            else
                let in_module = 1
            endif
            continue
        endif

        "multi-line
        if in_module == 1
            if line =~';\s*$'
                call add(module_lines,line)
                "module inst ();
                if join(module_lines) =~ module_inst_pattern
                    let value = []
                    call substitute(join(module_lines),module_inst_pattern,'\=extend(value,[submatch(1),submatch(4)])','')
                    let seq = seq + 1
                    call add(value,inst_idx)
                    call extend(module_seqs,{seq : value})
                "module #() inst ();
                elseif join(module_lines) =~ module_para_inst_pattern
                    let value = []
                    call substitute(join(module_lines),module_para_inst_pattern,'\=extend(value,[submatch(1),submatch(4)])','')
                    let seq = seq + 1
                    call add(value,inst_idx)
                    call extend(module_seqs,{seq : value})
                endif
                let in_module = 0
                let module_lines = []
                let idx_flag = 0
            else
                call add(module_lines,line)
            endif
            continue
        endif
    endfor
    return module_seqs
endfunction
"}}}2

"GetModule 获取当前module名{{{2
"--------------------------------------------------
" Function: GetModule
"
" Description:
"   Get Module Name
" Output:
"   module name
" Note:
"   only use for top_module generation, ignore multi-line
"---------------------------------------------------
function s:GetModule(lines)
    let lines = s:RemoveCommentLine(a:lines)
    for line in lines
        if line =~ '^\s*module\s\+\w\+'
            let module = matchstr(line,'^\s*module\s\+\zs\w\+\ze') 
            return module
        endif
    endfor
endfunction
"}}}2

"}}}1
