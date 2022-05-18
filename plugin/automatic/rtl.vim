"-----------------------------------------------------------------------------
" Vim Plugin for Verilog Code Automactic Generation 
" Author:         HonkW
" Website:        https://honk.wang
" Last Modified:  2022/05/18 00:44
" File:           rtl.vim
" Note:           RtlTree function partly from zhangguo's vimscript
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

"}}}1

"RtlTree Rtl树{{{1
"--------------------------------------------------
" Function: RtlTree
"
" Description:
"   Move from zhangguo's vimscript,add tags auto generation and auto deletion
" Output:
"   Rtl Tree
" Note:
"   Never change Rtl Generation Logic(copy from zhangguo), problem might exist
"---------------------------------------------------
command RtlTree :call RtlTree()

let t:RtlTreeVlogDefine = 0              "Open RTLTree----incllude ifdef and ifndef
let s:rtltree_init_max_display_layer = 7 "Set RTLTree Layer
let s:oTreeNode = {}
let s:tree_up_dir_line = 'rtl tree'
let s:rtl_tree_is_open = 0
let s:rtl_tree_first_open = 1

function s:GetInstFileName(inst) "{{{2
    if has_key(s:top_modules,a:inst)
        let file = s:top_modules[a:inst]
        let dir = s:top_files[file]
    else
        return ''
    endif
    return dir.'/'.file
endfunction "}}}2
function s:oTreeNode.New(parent,filename,instname,instname2) dict "{{{2
    let newTreeNode = copy(self)
    let newTreeNode.parent = a:parent
    let newTreeNode.filename = a:filename
    let newTreeNode.instname = a:instname
    let newTreeNode.instname2 = a:instname2
    let newTreeNode.unresolved = 0
    let newTreeNode.unresolved_name = ""
    let newTreeNode.layer = 1
    let newTreeNode.isFold = 1
    let newTreeNode.lnum = 2
    let newTreeNode.parent_inst_lnum = 1
    let newTreeNode.childrensolved = 0
    let newTreeNode.children = []
    let newTreeNode.macro_type = 0 " `ifdef `ifndef `elsif `else `endif
    let newTreeNode.macro_depth= 0
    return newTreeNode
endfunction "}}}2
function s:oTreeNode.GetTopNode(tree) "{{{2
    let node = a:tree
    while 1
        if(node.layer == 1)
            break
        else
            let node = node.parent
        endif
    endwhile
    return node
endfunction "}}}2
function s:oTreeNode.SearchChildNodeByLnum(tree,lnum) "{{{2
    "is the return node.lnum != a:lnum, search fail
    if(a:tree.isFold == 0)
        for node in a:tree.children
            if node.lnum == a:lnum
                return node
            else
                let tmp_node = self.SearchChildNodeByLnum(node,a:lnum)
                if tmp_node.lnum == a:lnum 
                    return tmp_node
                endif
            endif
        endfor
    endif
    "search fail
    return a:tree
endfunction "}}}2
function s:oTreeNode.SearchChildNodeByInstname2(tree,inst2) "{{{2
    for node in a:tree.children
        if node.instname2 == a:inst2
            return node
        endif
    endfor
    "search fail
    return a:tree
endfunction "}}}2
function s:oTreeNode.SearchNodeByLnum(tree,lnum) "{{{2
    return self.SearchChildNodeByLnum(self.GetTopNode(a:tree),a:lnum)
endfunction "}}}2
function s:oTreeNode.CreateRtlTree(tree) "{{{2
    if a:tree.filename == ''
        "echohl ErrorMsg | echo "file: tags not exist or need update!" | echohl None
        return
    endif
    let l:macro_depth = 0
    "for line in s:Filter(readfile(a:tree.filename))

    " start process code from current line -- line(".")
    let l:line_index = line(".")
    let l:inst_module = 0
    let l:module_name = ""
    let l:module_inst_name = ""
    let l:inst_module_pending = 0
    let l:in_pair = 0
    let l:end_pair_lnum = 1
    let l:lines = readfile(expand('%'))

    while l:line_index <= line("$")
        let l:line_index = g:AutoVerilog_SkipCommentLine(0,l:line_index,l:lines)
        if l:line_index == -1
            break
        endif
        let line = getline(l:line_index)
        let line = substitute(line, '^\s*', '', '')
        let line = substitute(line, '\/\/.*$', '', '')
        call cursor(l:line_index,1)

        "break while loop reach endmodule
        if line =~ '^\s*endmodule'
            break
        endif

        "macro
        if t:RtlTreeVlogDefine == 1
            if line =~ '^\s*`ifdef' || line =~ '^\s*`ifndef'
                let l:macro_depth = l:macro_depth + 1
            endif
            if line =~ '^\s*`ifdef' || line =~ '^\s*`ifndef' || line =~ '^\s*`elsif' || line =~ '^\s*`else' || line =~ '^\s*`endif'
                let inst = line
                for i in range(2, l:macro_depth, 1)
                    let inst= "    ".inst
                endfor
                let node = self.New(a:tree,a:tree.filename,a:tree.instname,inst)
                let node.layer = a:tree.layer + 1
                let node.parent_inst_lnum = l:line_index
                let node.childrensolved = 1
                let node.macro_type = 1
                call add(a:tree.children,node)
            endif
            if line =~ '^\s*`endif'
                let l:macro_depth = l:macro_depth - 1
            endif
        endif

        if l:in_pair == 1
            "call s:oTreeNode.TreeLog("debug:-- in_pair: " . l:in_pair. "  end_pair_lnum: " . l:end_pair_lnum . "   line_index:" . l:line_index . " >  " . line)
            let l:line_index = l:line_index + 1
            if l:line_index >= l:end_pair_lnum
                let l:in_pair = 0
            endif
            continue
        endif

        " pure pair #() {}
        if line =~ '^\s*#\?\s*\((\|{\)'
            let l:in_pair = 1
            let l:match_str = matchstr(line, '^\s*#\?\s*\((\|{\)')
            if strpart(line,0,1) =~ '\((\|{\)'
                call cursor(l:line_index-1,400) " cursor to last line last col, to search '( | {'
            endif

            call search('\((\|{\)')
            if l:match_str =~ '^\s*#\?\s*('
                let [l:end_pair_lnum,col] = searchpairpos("\(", "", "\)")
            elseif l:match_str =~ '^\s*#\?\s*{'
                let [l:end_pair_lnum,col] = searchpairpos("{" , "", "}" )
            endif
            if l:end_pair_lnum == l:line_index
                let l:in_pair = 0
            endif

            let l:line_index = l:line_index + 1
            continue
        endif

        "call s:oTreeNode.TreeLog("debug:-- " . line)
        " module instance line
        if line =~ '^\s*' . '`\?' . s:not_keywords_pattern . '\s*' . '\(' .  '$' . '\|' . '#' . '\|' . s:not_keywords_pattern . '\)'
                " get module_name
                let l:module_name = matchstr(line, '`\?' . s:not_keywords_pattern)
                let line =        substitute(line, '`\?' . s:not_keywords_pattern, '', '')

                while(1)
                    let line = substitute(line, '^\s*', '', '')
                    if line =~ '^\s*' . '`\?' . s:not_keywords_pattern || line =~ '#'
                        break
                    endif

                    let l:line_index = l:line_index + 1
                    let l:line_index = g:AutoVerilog_SkipCommentLine(0,l:line_index,l:lines)
                    if l:line_index == -1
                        break
                    endif
                    let line = getline(l:line_index)
                    let line = substitute(line, '^\s*', '', '')
                    let line = substitute(line, '\/\/.*$', '', '')
                    call cursor(l:line_index,1)
                endwhile

                if line =~ '#'
                    " have parameter assignments
                    call search('(')
                    let [lnum,col] = searchpairpos("\(", "", "\)")
                    let l:line_index = lnum
                    let line = getline(l:line_index)
                    let line = strpart(line, col, strlen(line))
                    let line = substitute(line, '\/\/.*$', '', '')
                else
                    " no parameter assignments
                endif



                " get module_inst_name
                while(1)
                    let line = substitute(line, '^\s*', '', '')
                    if line =~ '^\s*' . '`\?' . s:not_keywords_pattern
                        break
                    endif

                    let l:line_index = l:line_index + 1
                    let l:line_index = g:AutoVerilog_SkipCommentLine(0,l:line_index,l:lines)
                    if l:line_index == -1
                        break
                    endif
                    let line = getline(l:line_index)
                    let line = substitute(line, '^\s*', '', '')
                    let line = substitute(line, '\/\/.*$', '', '')
                    call cursor(l:line_index,1)
                endwhile

                if line =~ '^\s*' . '`\?' . s:not_keywords_pattern
                    " module instance name got
                    let l:module_inst_name = matchstr(line,'^\s*' . '`\?' . s:not_keywords_pattern)
                    let l:inst_module_pending = 1
                endif
        endif

        "if line =~ '\<utoinst\>'
            "let inst = s:GetInstName(line)
            "let inst2 = s:GetInstName2(line)
        if l:inst_module_pending == 1
            let inst = l:module_name
            let inst2 = l:module_inst_name
            let inst_file = s:GetInstFileName(inst)
            let node = self.New(a:tree,inst_file,inst,inst2)
            let node.layer = a:tree.layer + 1
            let node.parent_inst_lnum = l:line_index
            "call s:oTreeNode.TreeLog("debug: " . l:module_name  . '  ' . l:module_inst_name)
            if inst_file == ''
                "echohl ErrorMsg | echo "file: tags not exist or need update! inst: " . inst . " is not in tags, or file:" .inst. ".v is not exist in cur dir(" .$PWD. "/)"  | echohl None
                let node.unresolved = 1
                let node.instname = inst . " - unresolved"
            else
                if(s:rtl_tree_first_open == 1 && node.layer < s:rtltree_init_max_display_layer + 1)
                    " do not recursive CreateRtlTree
                    "call self.CreateRtlTree(node)
                endif
            endif
            call add(a:tree.children,node)
            let l:inst_module_pending = 0
        endif

        " normal pair #() {}
        if line =~ '\((\|{\)'
            let l:in_pair = 1
            let l:match_str = matchstr(line, '\((\|{\)')
            if strpart(line,0,1) =~ '\((\|{\)'
                call cursor(l:line_index-1,400) " cursor to last line last col, to search '( | {'
            endif

            call search('\((\|{\)')
            if l:match_str =~ '('
                let [l:end_pair_lnum,col] = searchpairpos("\(", "", "\)")
            elseif l:match_str =~ '{'
                let [l:end_pair_lnum,col] = searchpairpos("{" , "", "}" )
            endif
            if l:end_pair_lnum == l:line_index
                let l:in_pair = 0
            endif
        endif

    "endfor
        let l:line_index = l:line_index + 1
    endwhile
    "call s:oTreeNode.TreeLog("debug: CreateRtlTree done! -- " . a:tree.instname)
    let a:tree.childrensolved = 1
endfunction "}}}2
function s:oTreeNode.DrawRtlTree(prefix,tree) "{{{2
    "if(a:tree.unresolved)
    "    let l:instname = 'unresolved'
    "else
    "    let l:instname = a:tree.instname
    "endif
    let l:instname = a:tree.instname

    let a:tree.lnum = s:rtl_tree_init_lnum
    let s:rtl_tree_init_lnum = s:rtl_tree_init_lnum + 1

    if(s:rtl_tree_first_open == 1 && a:tree.layer < s:rtltree_init_max_display_layer)
        let a:tree.isFold = 0
    endif
    if(len(a:tree.children))
        if(a:tree.isFold)
            let sub_prefix = substitute(a:prefix,'[~+-]$','+','')
            call setline(line(".")+1,sub_prefix . a:tree.instname2 . ' (' . l:instname. ')')
            normal j
        else
            let sub_prefix = substitute(a:prefix,'[~+-]$','~','')
            call setline(line(".")+1,sub_prefix . a:tree.instname2 . ' (' . l:instname. ')')
            normal j

            let sub_prefix = substitute(a:prefix,'[~+-]$',' ','') . "|-"
            for child_tree in a:tree.children
                call self.DrawRtlTree(sub_prefix,child_tree)
            endfor
        endif
    else
        call setline(line(".")+1,a:prefix . a:tree.instname2 . ' (' . l:instname. ')')
        normal j
    endif
endfunction "}}}2
function s:oTreeNode.RenderTree() "{{{2
    let s:rtl_tree_init_lnum = 2
    call cursor(1,0)
    call setline(1,"rtl tree")
    call self.DrawRtlTree("|~",s:rtltree)
    let del_sum = line("$") - line(".")
    normal j
    if del_sum > 0
        execute "normal " . del_sum . "dd"
    endif
    call cursor(s:current_node.lnum,0)
endfunction "}}}2
function s:oTreeNode.TreeLog(log) "{{{2
    if s:rtl_tree_is_open == 0
        return
    endif
    execute bufwinnr(t:TreeLogName) . " wincmd w"
    call setline(line("$")+1,a:log)
    call cursor(line("$"),0)
    execute "normal zb"
    wincmd p
endfunction "}}}2
function s:oTreeNode.TreeLogInstFullPath() "{{{2
    let fullpath = ''
    let node = s:current_node
    while 1
        let fullpath = node.instname2 . '.' . fullpath
        if node.layer == 1
            break
        endif
        let node = node.parent
    endwhile
    let fullpath = substitute(fullpath,'\.$','','')
    call s:oTreeNode.TreeLog(fullpath)
endfunction "}}}2
function s:setupTreeSyntaxHighlighting() "{{{2
    "treeFlags are syntax items that should be invisible, but give clues as to
    "how things should be highlighted
    syn match treeFlag #\~#
    syn match treeFlag #\[RO\]#

    "highlighting for the .. (up dir) line at the top of the tree
    execute "syn match treeUp #". s:tree_up_dir_line ."#"

    "highlighting for the ~/+ symbols for the directory nodes
    syn match treeClosable #\~\<#
    syn match treeClosable #\~\.#
    syn match treeOpenable #+\<#
    syn match treeOpenable #+\.#he=e-1

    "highlighting for the tree structural parts
    syn match treePart #|#
    syn match treePart #`#
    syn match treePartFile #[|`]-#hs=s+1 contains=treePart

    "quickhelp syntax elements
    syn match treeHelpKey #" \{1,2\}[^ ]*:#hs=s+2,he=e-1
    syn match treeHelpKey #" \{1,2\}[^ ]*,#hs=s+2,he=e-1
    syn match treeHelpTitle #" .*\~#hs=s+2,he=e-1 contains=treeFlag
    syn match treeToggleOn #".*(on)#hs=e-2,he=e-1 contains=treeHelpKey
    syn match treeToggleOff #".*(off)#hs=e-3,he=e-1 contains=treeHelpKey
    syn match treeHelpCommand #" :.\{-}\>#hs=s+3
    syn match treeHelp  #^".*# contains=treeHelpKey,treeHelpTitle,treeFlag,treeToggleOff,treeToggleOn,treeHelpCommand

    "highlighting for readonly files
    syn match treeRO #.*\[RO\]#hs=s+2 contains=treeFlag,treeBookmark,treePart,treePartFile

    "highlighting for sym links
    syn match treeLink #[^-| `].* -> # contains=treeBookmark,treeOpenable,treeClosable,treeDirSlash

    "highlighting for unresolved
    syn match treeUnresolved #unresolved#
    syn match treeNull #^\~#

    "highlighing for directory nodes and file nodes
    syn match treeDirSlash #/#
    syn match treeDir #[^-| `].*/# contains=treeLink,treeDirSlash,treeOpenable,treeClosable
    syn match treeExecFile  #[|`]-.*\*\($\| \)# contains=treeLink,treePart,treeRO,treePartFile,treeBookmark
    syn match treeFile  #|-.*# contains=treeLink,treePart,treeRO,treePartFile,treeBookmark,treeExecFile,treeUnresolved,vlogMacro
    syn match treeFile  #`-.*# contains=treeLink,treePart,treeRO,treePartFile,treeBookmark,treeExecFile
    syn match treeCWD #^/.*$#

    "highlighting for bookmarks
    syn match treeBookmark # {.*}#hs=s+1

    "highlighting for the bookmarks table
    syn match treeBookmarksLeader #^>#
    syn match treeBookmarksHeader #^>-\+Bookmarks-\+$# contains=treeBookmarksLeader
    syn match treeBookmarkName #^>.\{-} #he=e-1 contains=treeBookmarksLeader
    syn match treeBookmark #^>.*$# contains=treeBookmarksLeader,treeBookmarkName,treeBookmarksHeader

    "highlighting for verilog macro define
    syn match vlogMacro #`ifdef.*\|`ifndef.*\|`elsif.*\|`else.*\|`endif.*#

    "if g:NERDChristmasTree
    if 1
        hi def link treePart Special
        hi def link treePartFile Type
        hi def link treeFile Normal
        hi def link treeExecFile Title
        hi def link treeDirSlash Identifier
        hi def link treeClosable Type
    else
        hi def link treePart Normal
        hi def link treePartFile Normal
        hi def link treeFile Normal
        hi def link treeClosable Title
    endif

    hi def link treeBookmarksHeader statement
    hi def link treeBookmarksLeader ignore
    hi def link treeBookmarkName Identifier
    hi def link treeBookmark normal

    hi def link treeHelp String
    hi def link treeHelpKey Identifier
    hi def link treeHelpCommand Identifier
    hi def link treeHelpTitle Macro
    hi def link treeToggleOn Question
    hi def link treeToggleOff WarningMsg

    hi def link treeDir Directory
    hi def link treeUp Directory
    hi def link treeCWD Statement
    hi def link treeLink Macro
    hi def link treeOpenable Title
    hi def link treeFlag ignore
    hi def link treeRO WarningMsg
    hi def link treeBookmark Statement
    hi def link treeUnresolved WarningMsg
    hi def link treeNull Directory
    hi def link vlogMacro Macro 
endfunction "}}}2
function s:bindMappings() "{{{2
    nnoremap <buffer><expr> <cr>    matchstr(getline('.'), '\%' . col('.') . 'c.') == '~'
                                    \ ? ":call <SID>active(1)<cr>" :
                                    \ matchstr(getline('.'), '\%' . col('.') . 'c.') == '-'
                                    \ ? ":call <SID>active(1)<cr>" :
                                    \ matchstr(getline('.'), '\%' . col('.') . 'c.') == '+'
                                    \ ? ":call <SID>active(1)<cr>" : ":call <SID>active(0)<cr>"
    nnoremap <buffer> <leftrelease> :call <SID>active(0)<cr>
    nnoremap <buffer> <2-leftmouse> :call <SID>active(1)<cr>
endfunction "}}}2
function s:testleft() "{{{2
    call s:oTreeNode.TreeLog("leftrelease")
endfunction "}}}2
function s:active(mode) "{{{2
    "mode 0 - go to module instance line, 1 - go to module define file
    let lnum = line(".")
    if lnum == 1
        return
    endif
    let last_node = s:current_node
    let t:RtlBufName = s:GetInstFileName(s:current_node.instname)

    let s:current_node = s:oTreeNode.SearchNodeByLnum(s:rtltree,lnum)
    "call s:oTreeNode.TreeLog("------------active--------------" . s:current_node.instname)

    "wincmd p
    if bufwinnr(t:RtlBufName) == -1
        silent! execute 'belowright ' . 'vertical '. ' new'
        silent! execute "edit " . t:RtlBufName
    endif
    execute bufwinnr(t:RtlBufName) . " wincmd w"

    "let s:GotoInstFile_use = 1

        " mouse left-click or module is undefined
        if a:mode == 0 || s:current_node.unresolved == 1 || s:current_node.macro_type == 1
            "call s:oTreeNode.TreeLog("tag - 0 : -- " . s:current_node.parent.instname)
            "echo "tag s:current_node.parent.instname " . s:current_node.parent.instname
            execute "tag! " . s:current_node.parent.instname
            call cursor(s:current_node.parent_inst_lnum,1)
            execute "normal zt"

        " module have defined & mouse double-click
        else
            "call s:oTreeNode.TreeLog("active - 1")
            let inst = s:current_node.instname
            "call s:oTreeNode.TreeLog("tag - 1 : -- " . inst)
            "echo "tag inst " . inst
            execute "tag! " . inst
            execute "normal zt"
        endif

        "call s:oTreeNode.TreeLog("unresolved = " . s:current_node.unresolved)
        "call s:oTreeNode.TreeLog("childrensolved = " . s:current_node.childrensolved)
        "call s:oTreeNode.TreeLog("current_node= " . s:current_node.instname)

    " module have defined
    if s:current_node.unresolved == 0
        if s:current_node.childrensolved == 0 && a:mode == 1
            call s:oTreeNode.CreateRtlTree(s:current_node)
            "echo "tag s:current_node.instname " . s:current_node.instname
            execute "tag! " . s:current_node.instname
            execute "normal zt"
        endif
        execute bufwinnr(t:NERDTreeBufName) . " wincmd w"
        let l:lnum = line(".")
        let l:col = col(".")

        " to get old top line number
        execute "normal H"
        let l:old_top_lnum = line(".")

        let line = getline(l:lnum)

        if a:mode == 1
            let s:current_node.isFold = !s:current_node.isFold
        elseif ((line[l:col-1] =~ '+') && (a:mode == 0))
            let s:current_node.isFold = 0
        elseif ((line[l:col-1] =~ '\~') && (a:mode == 0))
            let s:current_node.isFold = 1
        endif

        call s:oTreeNode.RenderTree()
        execute bufwinnr(t:NERDTreeBufName) . " wincmd w"

        call cursor(l:old_top_lnum, 1)
        execute "normal zt"
        call cursor(l:lnum, l:col)


        "if a:mode == 1
        "    let t:RtlBufName = s:GetInstFileName(s:current_node.instname)
        "    execute bufwinnr(t:RtlBufName) . " wincmd w"
        "endif
    endif

    if a:mode == 0 || s:current_node.unresolved == 1 || s:current_node.macro_type == 1
        let s:current_node = s:current_node.parent
        execute bufwinnr(t:NERDTreeBufName) . " wincmd w"
    endif

    "if last_node.instname == s:current_node.instname
        "call s:oTreeNode.TreeLogInstFullPath()
    "endif
endfunction "}}}2
function s:OpenRtlTree() "{{{2
    let s:rtltree = s:oTreeNode.New("","toa.v","toa","toa")
    let s:rtltree.parent = s:rtltree
    let l:line_index = 1
    let l:store_lnum = line(".")
    let l:store_col  = col(".")
    let l:lines = readfile(expand('%'))

    while l:line_index <= line("$")
        let l:line_index = g:AutoVerilog_SkipCommentLine(0,l:line_index,l:lines)
        if l:line_index == -1
            break
        endif
        let line = getline(l:line_index)
        "if line =~ '^\s*module\s*\w.*(\/\*autoarg\*\/'
        if line =~ '^\s*module\s\+\w'
            "let top_module = matchstr(line,'module\s*\w\+')
            let top_module = matchstr(line,'module\s\+\w\+')
            let top_module = matchstr(top_module,'\w\+$')
            let s:rtltree.filename = s:GetInstFileName(top_module)
            let s:rtltree.instname = top_module
            let s:rtltree.instname2 = top_module
            let s:rtltree.parent_inst_lnum = l:line_index
            break
        endif
        let l:line_index = l:line_index + 1
    endwhile

    call cursor(l:line_index,1)
    call s:oTreeNode.CreateRtlTree(s:rtltree)

    "create the rtl tree window
    "let splitSize = 28

    "let t:NERDTreeBufName = localtime() . "_RtlTree_"
    "silent! execute 'aboveleft ' . 'vertical ' . splitSize . ' new'
    "silent! execute "edit " . t:NERDTreeBufName

    set tags=tags;
    set noautochdir   "automatic change directory based on the opened file

    let splitSize = 28
    let t:NERDTreeBufName = localtime() . "._RtlTree_"
    silent! execute 'aboveleft ' . 'vertical ' . splitSize . ' new'
    silent! execute "edit " . t:NERDTreeBufName

    "autocmd QuitPre t:NERDTreeBufName echo 'leave!!!!!!'.t:NERDTreeBufName
    "reset rtl_tree_is_open when :q
    autocmd QuitPre *._RtlTree_ let s:rtl_tree_is_open = 0
    autocmd QuitPre *._RtlTree_ call delete('tags')
        
    setlocal winfixwidth

    "throwaway buffer options
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal nowrap
    setlocal foldcolumn=0
    setlocal nobuflisted
    setlocal nospell
    setlocal nomodified

    iabc <buffer>

    setlocal cursorline

    call s:bindMappings()
    " syntax highlighting
    call s:setupTreeSyntaxHighlighting()

    let s:current_node = s:rtltree
    call s:oTreeNode.RenderTree()

    call cursor(l:store_lnum, l:store_col)

endfunction "}}}2
function s:CloseRtlTree() "{{{2
    execute bufwinnr(t:NERDTreeBufName) . " wincmd w"
    close
    let t:RtlBufName = s:GetInstFileName(s:current_node.instname)
    execute bufwinnr(t:RtlBufName) . " wincmd w"
endfunction "}}}2
function s:OpenRtlTreeLog() "{{{2
    let t:TreeLogName = localtime() . "_TreeLog_"
    silent! execute 'botright 5 new'
    silent! execute "edit " . t:TreeLogName

    "throwaway buffer options
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal nowrap
    setlocal foldcolumn=0
    setlocal nobuflisted
    setlocal nospell
    setlocal nomodified

    iabc <buffer>

    wincmd p
endfunction "}}}2
function s:CloseRtlTreeLog() "{{{2
    execute bufwinnr(t:TreeLogName) . " wincmd w"
    close
    let t:RtlBufName = s:GetInstFileName(s:current_node.instname)
    execute bufwinnr(t:RtlBufName) . " wincmd w"
endfunction "}}}2
"s:GenRtlTags 写Rtl标签{{{2
"--------------------------------------------------
" Function: GenRtlTags
" Input: 
"   .v file
"
" Description:
"   input .v file and generate tag file for linked jump
"
" Output:
"   generate tags for tag jump
"---------------------------------------------------
function s:GenRtlTags(files,modules)
    let files = a:files
    let modules = a:modules
    "Write tags by module line
    let tags = []
    call add(tags,'!_TAG_PROGRAM_AUTHOR	HonkW	/contact@honk.wang/')
    for file in sort(keys(files))
        let dir = files[file]
        let file = dir.'/'.file
        if filereadable(file) == 1
            let lines = readfile(file)
            let module_line = ''
            for line in lines
                if line =~ '^\s*module\s*\w\+.*$'
                    let module_line = line
                    let module = matchstr(line,'^\s*module\s*\zs\w\+\ze.*$')
                    break
                endif
            endfor
            if module_line == ''
                echohl WarningMsg | echo "Error finding module for ".file | echohl None
            else
                "write tag
                let tag = module . "\t" . file . "\t" . '/^' . module_line . '$'
                "reaplace // with \/\/
                let tag = substitute(tag,'\/\/','\\\/\\\/','g')                   
                call add(tags,tag)
            endif
        endif
    endfor
    return tags
endfunction
"}}}2

function RtlTree() "{{{2

    if s:rtl_tree_is_open == 0
        let s:rtl_tree_is_open = 1
        "Get tags from top module and search down
        try
            "Get directory list by scaning line
            let [dirlist,rec,vlist,elist,flist,tlist] = s:GetVerilogLib()
            "Get file-dir dictionary & module-file dictionary ahead of all process
            let [s:top_files,s:top_modules] = g:AutoVerilog_GetModuleFileDirDic()
        endtry

        let tags = s:GenRtlTags(s:top_files,s:top_modules)
        call writefile(tags,'tags')
        "echo 'Tags Write Finish!'

        "call s:OpenRtlTreeLog()
        call s:OpenRtlTree()
        let s:rtl_tree_first_open = 0
    else
        let s:rtl_tree_is_open = 0
        call s:CloseRtlTree()
        call delete('tags')
        "call s:CloseRtlTreeLog()
        let s:rtl_tree_first_open = 1
    endif


endfunction "}}}2

"}}}1

"{{{1 GetVerilogLib 获取verilog文件搜索位置
"--------------------------------------------------
" Function: GetVerilogLib
" Input: 
"   Lines look like: 
"   verilog-library-directories:()
"   verilog-library-directories-recursive:0
"   verilog-library-flags:()
" Description:
" e.g
"   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
"   | Style                                                                  | Function                     |
"   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
"   | verilog-library-directories:("test" ".")                               | add the directory test & .   |
"   +------------------------------------------------------------------------+------------------------------+
"   | verilog-library-directories-recursive:1                                | directory search recursive   |
"   +------------------------------------------------------------------------+------------------------------+
"   | verilog-library-files:("/some/path/technology.v" "/some/path/tech2.v") | add the two files            |
"   +------------------------------------------------------------------------+------------------------------+
"   | verilog-library-flags:("-y dir -y dir2")                               | add the directory dir & dir2 |
"   +------------------------------------------------------------------------+------------------------------+
"   | verilog-library-flags:("+incdir+dir3")                                 | add the directory dir3       |
"   +------------------------------------------------------------------------+------------------------------+
"   | verilog-library-flags:("-Idir4")                                       | add the directory dir4       |
"   +------------------------------------------------------------------------+------------------------------+
"   | verilog-library-flags:("+libext+.v .sv")                               | add the extension .v         |
"   +------------------------------------------------------------------------+------------------------------+
"   | verilog-library-flags:("-v filename")                                  | add file of filename         |
"   +------------------------------------------------------------------------+------------------------------+
"   |                                                                        |                              |
"   +------------------------------------------------------------------------+------------------------------+
"   | verilog-library-flags:("-f filename")                                  | add filelist of filename     |
"   +------------------------------------------------------------------------+------------------------------+
"   | verilog-library-flags:("-t filename")                                  | add tag of filename          |
"   +------------------------------------------------------------------------+------------------------------+
"
" Output:
"   Parameter for verilog library
" e.g.
"   1.name:dir 
"     dirlist and recursive flag
"       dirlist = ['test','.','dir','dir2','dir3','dir4']
"       rec = 1
"   2.name:file
"     vlist
"       vlist = ['/some/path/technology.v','/some/path/tech2.v']
"   3.name:ext
"     extension for file
"       elist = ['.v','.sv']
"   4.name:flist
"     filelist to get verilog file
"       flist = ['../filelist/ctags_filelist.f']
"   5.name:tlist
"     taglist to get verilog file
"       tlist = ['../filelist/tags']
"---------------------------------------------------
function s:GetVerilogLib()
    "dir
    let dirlist = [] 
    let rec = 1
    let s:ati_add_dirs = {} "s:ati_add_dirs -> {F:/vim -> $VIM}
    "verilog file
    let vlist = [] 
    "extension
    let elist = []
    "filelist
    let flist = []
    "tag list
    let tlist = []
    "divide quotation
    let quote_list = []

    "Get library
    let lines = getline(1,line('$'))
    for line in lines
        "verilog-library-directories
        if line =~ 'verilog-library-directories:(.*)'
            let dir = matchstr(line,'verilog-library-directories:(\zs.*\ze)')
            call substitute(dir,'"\zs\S*\ze"','\=add(dirlist,submatch(0))','g')
        endif

        "verilog-library-directories-recursive
        if line =~ 'verilog-library-directories-recursive:'
            let rec = matchstr(line,'verilog-library-directories-recursive:\s*\zs\d\ze\s*$')
            if rec != '0' && rec != '1'
                echohl ErrorMsg | echo "Error input for verilog-library-directories-recursive = ".rec| echohl None
            endif
        endif

        "verilog-library-files
        if line =~ 'verilog-library-files:(.*)'
            "//verilog-library-files:("./test.v" "./aaa/test1.v")
            let file = matchstr(line,'verilog-library-files:(\zs.*\ze)')
            let quote_list = []
            call substitute(file,'"\zs.\{-}\ze"','\=add(quote_list,submatch(0))','g')
            for lib in quote_list
                call substitute(lib,'\zs\S\+\ze','\=add(vlist,submatch(0))','g')
            endfor
        endif
        
        "verilog-library-flags
        if line =~ 'verilog-library-flags:(.*)'
            let quote = matchstr(line,'verilog-library-flags:("\zs.*\ze")')
            let matchflags = '\('.   '-y'           . '\|' .
                                    \'+incdir+'     . '\|' .
                                    \'-I'           . '\|' .
                                    \'-v'           . '\|' .
                                    \'+libext+'     . '\|' .
                                    \'-f'           . '\|' .
                                    \'-t'           . '\)'
            let flag_list = split(quote,matchflags.'\(\s*[^ \-+]\+\)\{1,\}\zs')
            for flag in flag_list
                if flag =~ '^\s*-y'
                    let ydir = substitute(flag,'-y','','g')
                    call substitute(ydir,'\zs\S\+\ze','\=add(dirlist,submatch(0))','g')
                elseif flag =~ '^\s*+incdir+'
                    let incdir = substitute(flag,'+incdir+','','g')
                    call substitute(incdir,'\zs\S\+\ze','\=add(dirlist,submatch(0))','g')
                elseif flag =~ '^\s*-I'
                    let idir = substitute(flag,'-I','','g')
                    call substitute(idir,'\zs\S\+\ze','\=add(dirlist,submatch(0))','g')
                elseif flag =~ '^\s*-v'
                    let vfile = substitute(flag,'-v','','g')
                    call substitute(vfile,'\zs\S\+\ze','\=add(vlist,submatch(0))','g')
                elseif flag =~ '^\s*+libext+'
                    let ext = substitute(flag,'+libext+','','g')
                    call substitute(ext,'\zs\S\+\ze','\=add(elist,submatch(0))','g')
                elseif flag =~ '^\s*-f'
                    let file = substitute(flag,'-f','','g')
                    call substitute(file,'\zs\S\+\ze','\=add(flist,submatch(0))','g')
                elseif flag =~ '^\s*-t'
                    let file = substitute(flag,'-t','','g')
                    call substitute(file,'\zs\S\+\ze','\=add(tlist,submatch(0))','g')
                endif
            endfor
        endif
    endfor

    "filter duplicate
    if exists('*uniq')
        call uniq(dirlist)
        call uniq(vlist)
        call uniq(elist)
        call uniq(flist)
        call uniq(tlist)
    endif

    "expand directories{{{2
    "default
    let dir = '.'       
    if dirlist == [] 
        let dirlist = [dir]
    endif

    let exp_dirlist = []
    for dir in dirlist
        "expand directories in SYSTEM VARIABLE (e.g. $VIM -> F:/Vim)
        let dir = expand(dir)
        "expand directories to full path(e.g. ./ -> /usr/share/vim/vim74 )
        let dir = substitute(fnamemodify(dir,':p'),'\/$','','')
        call add(exp_dirlist,dir)
    endfor
    "record expand dir dictionary as ati_add_dirs
    for idx in range(len(dirlist))
        call extend(s:ati_add_dirs,{exp_dirlist[idx]:dirlist[idx]})
    endfor
    let dirlist = exp_dirlist
    "}}}2

    "expand verilog list{{{2
    let exp_vlist = []
    for file in vlist
        let file = expand(file)
        let file = fnamemodify(file,':p')
        call add(exp_vlist,file)
    endfor
    let vlist = exp_vlist
    "}}}2
    
    "expand filelist{{{2
    let exp_flist = []
    for file in flist
        let file = expand(file)
        let file = fnamemodify(file,':p')
        call add(exp_flist,file)
    endfor
    let flist = exp_flist
    "}}}2

    "expand taglist{{{2
    let exp_tlist = []
    for file in tlist
        let file = expand(file)
        let file = fnamemodify(file,':p')
        call add(exp_tlist,file)
    endfor
    let tlist = exp_tlist
    "}}}2
    
    return [dirlist,str2nr(rec),vlist,elist,flist,tlist]

endfunction
"}}}1

