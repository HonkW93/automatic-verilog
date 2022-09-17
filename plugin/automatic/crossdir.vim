"-----------------------------------------------------------------------------
" Vim Plugin for Verilog Code Automactic Generation 
" Author:         HonkW
" Website:        https://honk.wang
" Last Modified:  2022/09/16 19:13
" File:           crossdir.vim
" Note:           search cross directory by tags/filelist/verilog-library
"------------------------------------------------------------------------------

"Sanity checks 启动判断{{{1
if exists("g:loaded_automatic_verilog_crossdir")
    finish
endif
let g:loaded_automatic_verilog_crossdir = 1

"{{{1 debug注释行
let s:skip_cmt_debug = 0
"}}}1

"Record update 记录脚本更新
autocmd BufWrite crossdir.vim call s:UpdateVimscriptLastModifyTime()
function s:UpdateVimscriptLastModifyTime()
    let line = getline(5)
    if line =~ '\" Last Modified'
        call setline(5,"\" Last Modified:  " . strftime("%Y/%m/%d %H:%M"))
    endif
endfunction
"}}}1

"Defaults 默认设置{{{1
let g:_ATV_CROSSDIR_DEFAULTS = {
            \'mode':            0,
            \'flist_browse':    1,
            \'flist_file':      '',
            \'tags_browse':     1,
            \'tags_file':       '',
            \}

for s:key in keys(g:_ATV_CROSSDIR_DEFAULTS)
    if !exists('g:atv_crossdir_' . s:key)
        let g:atv_crossdir_{s:key} = copy(g:_ATV_CROSSDIR_DEFAULTS[s:key])
    endif
endfor
"}}}1
            
"{{{1 AutoVerilog_GetModuleFileDirDic 主函数 获取模块名-文件名-文件夹位置关系
"--------------------------------------------------
" Function: AutoVerilog_GetModuleFileDirDic
" Input: 
"   mode 
"     0 : normal(automatic get)
"     1 : filelist 
"     2 : tags
" Description:
"   Get module-file-dir dictionary
" e.g
"   files  : file-dir dictionary(.v file)
"          e.g  ALU.v -> ./hdl/core
"   modules: module-file dictionary
"          e.g  ALU -> ALU.v
" Output:
"   [files,modules]
"---------------------------------------------------
function g:AutoVerilog_GetModuleFileDirDic()
    "normal
    if g:atv_crossdir_mode == 0
        "Get directory list by scaning line
        let [dirlist,rec,vlist,elist,flist,tlist] = s:GetVerilogLib()
        "Get file-dir dictionary from library
        let files = s:GetFileDirDicFromLib(dirlist,rec,vlist,elist)
        "Get module-file dictionary
        let modules = s:GetModuleFileDict(files)
    "by file list
    elseif g:atv_crossdir_mode == 1
        "Get file-dir dictionary from filelist
        let file = s:GetFileList()
        let files = s:GetFileDirDicFromFlist(file)
        "Get module-file dictionary
        let modules = s:GetModuleFileDict(files)
    "by tags
    elseif g:atv_crossdir_mode == 2
        "Get module-file-dir dictionary from tags
        let file = s:GetTags()
        let [files,modules] = s:GetModuleFileDirDicFromTags(file)
    else
        echohl ErrorMsg | echo "Error mode input for GetModuleFileDirDic"| echohl None
    endif

    return [files,modules]
endfunction
"}}}1

"{{{1 AutoVerilog_GetModuleFileDirDic Subfunction 子函数

"GetModuleFileDirDicFromTags 从Tags获取文件名-文件夹-模块名关系{{{2
"--------------------------------------------------
" Function : GetModuleFileDirDicFromTags
" Input: 
"   file : tags file with absolute directory
" Description:
"   get file-dir dictionary from filelist
"   tags e.g.
"   ALU    ../src/aaa/bbb/ccc/ALU.v    /^module ALU($/;"    m
" Output:
"   files  : file-dir dictionary(.v file)
"   modules: module-file dictionary
"---------------------------------------------------
function s:GetModuleFileDirDicFromTags(file)
    let files = {}
    let modules = {}
    "read tags file
    let tags_dir = fnamemodify(a:file,':p:h')
    let lines = readfile(a:file)
    for line in lines
        if line =~ '^\w\+\t'
            let module = matchstr(line,'^\zs\w\+\ze\t')
            let line = substitute(line,'^\w\+\t','','')
            let file = substitute(line,'\(^\S\+\)\(.*$\)','\=submatch(1)','')
            if filereadable(tags_dir.'/'.file)
                let vfile = tags_dir.'/'.file
                let vfile = expand(vfile)
                let vfile = fnamemodify(vfile,':p')
                let dir = fnamemodify(vfile,':p:h')
                let file = fnamemodify(vfile,':p:t')
                call extend(files,{file : dir})
                call extend(modules,{module : file})
            else
                echohl ErrorMsg | echo "No file ".file." exist!"| echohl None
            endif
        endif
    endfor
    return [files,modules]
endfunction
"}}}2

"GetFileDirDicFromFlist 从File List获取文件名-文件夹关系{{{2
"--------------------------------------------------
" Function : GetFileDirDicFromFlist
" Input: 
"   file : filelist file with absolute directory
" Description:
"   get file-dir dictionary from filelist
"   flist e.g.
"       -f filelist
"       -v lib_file
"       -y lib_dir
"       +libext+lib_ext
"       +incdir+lib_dir
"       ../rtl/test.v
" Output:
"   files  : file-dir dictionary(.v file)
"          e.g  ALU.v -> ./hdl/core
"---------------------------------------------------
function s:GetFileDirDicFromFlist(file)
    let files = {}
    "get from filelist, no recursive
    let dirlist =[]
    let flist = []
    let vlist = []
    let elist = []
    let rec = 0
    "read filelist file
    let flist_dir = fnamemodify(a:file,':p:h')
    let lines = readfile(a:file)
    for line in lines
        "skip comment
        if line =~ '^\s*\/\/'
            continue
        endif
        let matchflags = '\('.   '-y'           . '\|' .
                                \'-f'           . '\|' .
                                \'+incdir+'     . '\|' .
                                \'-v'           . '\|' .
                                \'+libext+'     . '\)'
        let flag_list = split(line,matchflags.'\(\s*[^ \-+]\+\)\{1,\}\zs')
        for flag in flag_list
            if flag =~ '^\s*-f'
                let ffile = substitute(flag,'-f','','g')
                call substitute(ffile,'\zs\S\+\ze','\=add(flist,submatch(0))','g')
                for file in flist
                    if file =~ '^\s*\.'                 "dir start with ./ or ../
                        let file = flist_dir.'/'.file
                    elseif file =~ '^\s*\S\+\/'         "dir start wich $DESIGN_ROOT/.../
                        let file = file
                    else                                "dir start with test.v
                        let file = flist_dir.'/'.file
                    endif
                    let file = expand(file)
                    let file = fnamemodify(file,':p')
                    let subfiles = s:GetFileDirDicFromFlist(file)
                    call extend (files,subfiles)
                endfor
            elseif flag =~ '^\s*-y'
                let ydir = substitute(flag,'-y','','g')
                call substitute(ydir,'\zs\S\+\ze','\=add(dirlist,submatch(0))','g')
            elseif flag =~ '^\s*+incdir+'
                let incdir = substitute(flag,'+incdir+','','g')
                call substitute(incdir,'\zs\S\+\ze','\=add(dirlist,submatch(0))','g')
            elseif flag =~ '^\s*-v'
                let vfile = substitute(flag,'-v','','g')
                call substitute(vfile,'\zs\S\+\ze','\=add(vlist,submatch(0))','g')
            elseif flag =~ '^\s*+libext+'
                let ext = substitute(flag,'+libext+','','g')
                call substitute(ext,'\zs\S\+\ze','\=add(elist,submatch(0))','g')
            elseif flag != ''
                "remove space from the head&tail
                let flag = substitute(flag,'\s*$','','g')
                let file = substitute(flag,'^\s*','','g')
                if file =~ '^\s*\.'                 "dir start with ./ or ../
                    let file = flist_dir.'/'.file
                elseif file =~ '^\s*\S\+\/'         "dir start wich $DESIGN_ROOT/.../
                    let file = file
                else                                "dir start with test.v
                    let file = flist_dir.'/'.file
                endif
                let vfile = file
                let vfile = expand(vfile)
                if filereadable(vfile)
                    let vfile = fnamemodify(vfile,':p')
                    let dir = fnamemodify(vfile,':p:h')
                    let file = fnamemodify(vfile,':p:t')
                    call extend (files,{file : dir})
                else
                    echohl ErrorMsg | echo "No file ".vfile." exist!"| echohl None
                endif
            endif
        endfor
    endfor

    "filter duplicate
    if exists('*uniq')
        call uniq(dirlist)
        call uniq(vlist)
        call uniq(elist)
    endif

    "expand directories{{{3
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
    let dirlist = exp_dirlist
    "}}}3

    "expand verilog list{{{3
    let exp_vlist = []
    for file in vlist
        let file = expand(file)
        let file = fnamemodify(file,':p')
        call add(exp_vlist,file)
    endfor
    let vlist = exp_vlist
    "}}}3

    "find file from vlist
    for vfile in vlist
        if filereadable(vfile)
            let dir = fnamemodify(vfile,':p:h')
            let file = fnamemodify(vfile,':p:t')
            call extend (files,{file : dir})
        else
            echohl ErrorMsg | echo "No file ".vfile." exist!"| echohl None
        endif
    endfor

    "find file from dirlist(recursively)
    for dir in dirlist
        let files = s:GetFileDirDicFromLibRec(dir,0,files,elist)
    endfor
    return files
endfunction
"}}}2

"GetFileDirDicFromLib 从Verilog Library获取文件名-文件夹关系{{{2
"--------------------------------------------------
" Function : GetFileDirDicFromLib
" Input: 
"   dirlist: directory list
"   rec: recursively
"   vlist : verilog file list
"   elist : extension list
" Description:
"   get file-dir dictionary from dirlist
" Output:
"   files  : file-dir dictionary(.v file)
"          e.g  ALU.v -> ./hdl/core
"---------------------------------------------------
function s:GetFileDirDicFromLib(dirlist,rec,vlist,elist)
    let files = {}
    "find file from vlist
    for vfile in a:vlist
        if filereadable(vfile)
            let dir = fnamemodify(vfile,':p:h')
            let file = fnamemodify(vfile,':p:t')
            call extend (files,{file : dir})
        else
            echohl ErrorMsg | echo "No file ".vfile." exist!"| echohl None
        endif
    endfor
    "find file from dirlist(recursively)
    for dir in a:dirlist
        let files = s:GetFileDirDicFromLibRec(dir,a:rec,files,a:elist)
    endfor
    return files
endfunction

"--------------------------------------------------
" Function: GetFileDirDicFromLibRec
" Input: 
"   dir : directory
"   rec : recursive
"   files : dictionary to store
"   elist : extension list
" Description:
"   rec = 1, recursively get inst-file dictionary (.v or .sv file) 
"   rec = 0, normally get inst-file dictionary (.v or .sv file)
" Output:
"   files : files-directory dictionary(.v or .sv file)
"---------------------------------------------------
function s:GetFileDirDicFromLibRec(dir,rec,files,elist)
    "let filelist = readdir(a:dir,{n -> n =~ '.v$\|.sv$'})
    if v:version >= 704
        let filedirlist = glob(a:dir.'/'.'*',0,1)
    else
        let filedirlist = split(glob(a:dir.'/'.'*',0))
    endif

    let idx = 0
    while idx <len(filedirlist)
        let file = fnamemodify(filedirlist[idx],':t')
        let filedirlist[idx] = file
        let idx = idx + 1
    endwhile

    "filter file with extesion .v/.sv/other specify extension
    let filter_str = 'v:val =~ ' . ' ''\.v$'' ' 
               \. '|| v:val =~ ' . ' ''\.sv$'' '
    for ext in a:elist
        let filter_str  = filter_str . '|| v:val =~ ' . ' ''\' . ext . '$'' ' 
    endfor
    let filelist = filter(copy(filedirlist),filter_str)

    for file in filelist
        if has_key(a:files,file)
            "echohl ErrorMsg | echo "Same file ".file." exist in both ".a:dir." and ".a:files[file]."! Only use one as directory"| echohl None
        else
            call extend (a:files,{file : a:dir})
        endif
    endfor

    if a:rec
        "for item in readdir(a:dir)
        for item in filedirlist
            if isdirectory(a:dir.'/'.item)
                call s:GetFileDirDicFromLibRec(a:dir.'/'.item,1,a:files,a:elist)
            endif
        endfor
    endif
    return a:files

endfunction
"}}}2

"{{{2 GetFileList 获取filelist
"--------------------------------------------------
" Function: GetFileList
" Input: 
"   1.browse 
"     browse filelist file
"   2.
"     global variable g:atv_crossdir_flist_file 
"   3.
"     Lines look like: 
"     verilog-library-flags:("-f filename")
"   4.
"     ./filelist.f ./file_list.f or other .f file
" Description:
" e.g
"   verilog-library-flags:("-f ./filelist.f")
" Output:
"   filelist
"   e.g. ./filelist.f
"---------------------------------------------------
let s:flist_browse_file = ''
let s:flist_selected_file = ''
function s:GetFileList()
    let file = ''

    "already browse once, don't re-browse again
    if s:flist_browse_file != ''
        let file = s:flist_browse_file
    endif

    "find filelist by browse
    if file == '' && g:atv_crossdir_flist_browse == 1 
        if has("browse")
            let file = browse(0,'Select Your Filelist','./','')
            if file !~ '.f$'
                echo 'file "'.file.'" not ended with .f, might not be a filelist, please notice'
            endif
            let s:flist_browse_file= file
        else
            echohl ErrorMsg | echo "Vim has no support for GUI browse!!! Please close g:atv_crossdir_flist_browse" | echohl None
        endif
    endif

    "find filelist by global variable
    if file == '' && g:atv_crossdir_flist_file != ''
        let file = g:atv_crossdir_flist_file
    endif

    "find filelist by verilog-lib
    let [dirlist,rec,vlist,elist,flist,tlist] = s:GetVerilogLib()
    if file == '' && flist != []
        let file = flist[0]
    endif

    "find filelist by filelist.f file_list.f or last .f file
    if file == ''
        let filelist = filter(copy(glob('./'.'*',0,1)),'v:val =~ "\\.f$"')
        for file in filelist
            if file =~ 'filelist'
                break
            elseif file =~ 'file_list'
                break
            endif
        endfor
    endif

    if file == '' 
        echohl ErrorMsg | echo "Please select at least one filelist file!!!" | echohl None
    else
        let file = expand(file)
        let file = fnamemodify(file,':p')
        "don't echo filelist again unless it's changed
        if file != s:flist_selected_file 
            echo 'file "'.file.'" selected as filelist'
            let s:flist_selected_file = file
        endif
    endif

    return file

endfunction
"}}}2

"{{{2 GetTags 获取tags
"--------------------------------------------------
" Function: GetTags
" Input: 
"   1.browse 
"     browse tag file
"   2.
"     global variable g:atv_crossdir_tags_file
"   3.
"     Lines look like: 
"     verilog-library-flags:("-t filename")
"   4.
"     tags file
" Description:
" e.g
"   verilog-library-flags:("-t filename")
" Output:
"   tags 
"   e.g. ./tags
"---------------------------------------------------
let s:tags_browse_file = ''
let s:tags_selected_file = ''
function s:GetTags()
    let file = ''

    "already browse once, don't re-browse again
    if s:tags_browse_file != ''
        let file = s:tags_browse_file
    endif

    "find tags by browse
    if file == '' && g:atv_crossdir_tags_browse == 1 
        if has("browse")
            let file = browse(0,'Select Your Tags','./','')
            if file !~ 'tag'
                echo 'file "'.file.'" not match tag, might not be a tag, please notice'
            endif
            let s:tags_browse_file = file
        else
            echohl ErrorMsg | echo "Your vim has no support for GUI browse!!! Please close g:atv_crossdir_tags_browse" | echohl None
        endif
    endif

    "find tags by global variable
    if file == '' && g:atv_crossdir_tags_file != ''
        let file = g:atv_crossdir_tags_file
    endif

    "find tags by verilog-lib
    let [dirlist,rec,vlist,elist,flist,tlist] = s:GetVerilogLib()
    if file == '' && tlist !=[]
        let file = tlist[0]
    endif

    "find tags by ./tags 
    if file == ''
        let taglist = filter(copy(glob('./'.'*',0,1)),'v:val =~ "tag"')
        if taglist != []
            let file = taglist[0]
        endif
    endif

    if file == '' 
        echohl ErrorMsg | echo "Please select at least one tags file!!!" | echohl None
    else
        let file = expand(file)
        let file = fnamemodify(file,':p')
        "don't echo tags again unless it's changed
        if file != s:tags_selected_file 
            echo 'file "'.file.'" selected as tags'
            let s:tags_selected_file = file
        endif
        "automatic set tag file for user
        execute "set tags=".file
    endif

    return file

endfunction
"}}}2

"GetModuleFileDict 获取模块名和文件名关系{{{2
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
        let module_flag = 0
        let find_module = 0
        for line in lines
            if line =~ '^\s*module\s*\w\+'
                let module = matchstr(line,'^\s*module\s*\zs\w\+')
                let find_module = 1
            elseif line =~ '^\s*module\s*$'
                let module_flag = 1
                continue
            elseif module_flag == 1
                if line =~ '^\s*$' || line =~ '^\s*\/\/'
                    continue
                elseif line =~ '^\s*\w\+'
                    let module = matchstr(line,'^\s*\zs\w\+') 
                    let find_module = 1
                else
                    let find_module = 0
                endif
            endif
            if find_module == 1
                let find_module = 0
                if module == ''
                    call extend(modules,{'NULL' : file})
                else
                    call extend(modules,{module : file})
                endif
            endif
        endfor
    endfor
    return modules
endfunction
"}}}2

"{{{2 GetVerilogLib 获取verilog文件搜索位置
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
    let g:atv_crossdir_dirs = {} "g:atv_crossdir_dirs -> {F:/vim -> $VIM}
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

    "expand directories{{{3
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

    "record expand dir dictionary as g:atv_crossdir_dirs
    for idx in range(len(dirlist))
        call extend(g:atv_crossdir_dirs,{exp_dirlist[idx]:dirlist[idx]})
    endfor

    let dirlist = exp_dirlist
    "}}}3

    "expand verilog list{{{3
    let exp_vlist = []
    for file in vlist
        let file = expand(file)
        let file = fnamemodify(file,':p')
        call add(exp_vlist,file)
    endfor
    let vlist = exp_vlist
    "}}}3
    
    "expand filelist{{{3
    let exp_flist = []
    for file in flist
        let file = expand(file)
        let file = fnamemodify(file,':p')
        call add(exp_flist,file)
    endfor
    let flist = exp_flist
    "}}}3

    "expand taglist{{{3
    let exp_tlist = []
    for file in tlist
        let file = expand(file)
        let file = fnamemodify(file,':p')
        call add(exp_tlist,file)
    endfor
    let tlist = exp_tlist
    "}}}3
    
    return [dirlist,str2nr(rec),vlist,elist,flist,tlist]

endfunction
"}}}2

"}}}1

"AutoVerilog_SkipCommentLine 跳过注释行{{{1
"--------------------------------------------------
" Function: AutoVerilog_SkipCommentLine
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
function g:AutoVerilog_SkipCommentLine(mode,idx,lines)
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

    if s:skip_cmt_debug == 1
        echohl ErrorMsg | echo "Possibly last line is a comment line"| echohl None
        return -1
    else
        return idx
    endif

endfunction
"}}}1

"AutoVerilog_Sort 排序兼容vim7.4{{{1

"SortNaturalOrder sort函数Funcref（用于sort函数排序）{{{2
" Comparator function for natural ordering of numbers
function g:AutoVerilog_SortNaturalOrder(firstNr, secondNr)
  if a:firstNr < a:secondNr
    return -1
  elseif a:firstNr > a:secondNr
    return 1
  else 
    return 0
  endif
endfunction

if v:version > 704
    let g:atv_sort_funcref = 'n'
elseif v:version == 704
    if has("patch341") 
        let g:atv_sort_funcref = 'n'
    else
        let g:atv_sort_funcref = 'g:AutoVerilog_SortNaturalOrder'
    endif
elseif v:version == 703
    let g:atv_sort_funcref = 'g:AutoVerilog_SortNaturalOrder'
endif

"}}}2

"}}}1

