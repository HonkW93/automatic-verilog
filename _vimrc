" -------------------------------------------------------------
" Decription: _vimrc for windows
" Maintainer: HonkW
" Date: 2020-05-26
" -------------------------------------------------------------
" 指定文件头内容
let g:vimrc_author='Honk'
let g:vimrc_company='NPIC'
let g:vimrc_prject='Dragon Scale DCS'
let g:vimrc_device='Actel_IGLOO2_M2GL090'
let g:vimrc_email='honkwang93@gmail.com'
let g:vimrc_website='https://honk.wang'

" 指定template的位置,可自行在template文件夹中的v文件夹下添加verilog相关模板
let g:template_path= '$VIMRUNTIME/../vimfiles/bundle/load_template/template/'

" -------------------------------------------------------------
"                        基础设置
" -------------------------------------------------------------
set nocompatible                            " 关闭vi兼容模式
source $VIMRUNTIME/vimrc_example.vim        " Vim with all enhancements
source $VIMRUNTIME/mswin.vim                " Remap a few keys for Windows behavior 部分按键按照windows模式操作，解决crtl+c、ctrl+v、ctrl+a等windows下的快捷键
behave mswin                                " Mouse behavior (the Windows way) 鼠标操作

" 避免与windows ctrl+a 冲突，替换为alt+a
:nnoremap <A-x> <C-x>
:nnoremap <A-a> <C-a>

" Use the internal diff if available.
" Otherwise use the special 'diffexpr' for Windows.
if &diffopt !~# 'internal'
  set diffexpr=MyDiff()
endif
function MyDiff()
  let opt = '-a --binary '
  if &diffopt =~ 'icase' | let opt = opt . '-i ' | endif
  if &diffopt =~ 'iwhite' | let opt = opt . '-b ' | endif
  let arg1 = v:fname_in
  if arg1 =~ ' ' | let arg1 = '"' . arg1 . '"' | endif
  let arg1 = substitute(arg1, '!', '\!', 'g')
  let arg2 = v:fname_new
  if arg2 =~ ' ' | let arg2 = '"' . arg2 . '"' | endif
  let arg2 = substitute(arg2, '!', '\!', 'g')
  let arg3 = v:fname_out
  if arg3 =~ ' ' | let arg3 = '"' . arg3 . '"' | endif
  let arg3 = substitute(arg3, '!', '\!', 'g')
  if $VIMRUNTIME =~ ' '
    if &sh =~ '\<cmd'
      if empty(&shellxquote)
        let l:shxq_sav = ''
        set shellxquote&
      endif
      let cmd = '"' . $VIMRUNTIME . '\diff"'
    else
      let cmd = substitute($VIMRUNTIME, ' ', '" ', '') . '\diff"'
    endif
  else
    let cmd = $VIMRUNTIME . '\diff'
  endif
  let cmd = substitute(cmd, '!', '\!', 'g')
  silent execute '!' . cmd . ' ' . opt . arg1 . ' ' . arg2 . ' > ' . arg3
  if exists('l:shxq_sav')
    let &shellxquote=l:shxq_sav
  endif
endfunction

" -------------------------------------------------------------
"                          界面设置
" -------------------------------------------------------------
set guifont=consolas:b:h16                      "windows设定字体风格字号
set number                                      "显示行号
set background=light                            "背景
colorscheme desert                              "设定配色方案
syntax on                                       "语法高亮
set foldclose=all                               "设置为自动关闭折叠
set nowrap                                      "关闭自动换行
highlight Pmenu    guibg=darkgrey  guifg=white  "修改自动补全窗口的配色
highlight PmenuSel guibg=darkblue guifg=white
set showcmd                                     "显示在最右下角展示最近输入的命令

" -------------------------------------------------------------
"                           其他设置
" -------------------------------------------------------------
" tab键设置
set expandtab                                   "tab自动转换空格
set softtabstop=4                               "使得按退格键时可以一次删掉 4 个空格
set tabstop=4                                   "设定tab长度为4
set shiftwidth=4                                "设定 << 和 >> 命令移动时的宽度为 4
"set autoindent                                 "设定自动缩进
set backspace=indent,eol,start                  "设定在插入状态下用退格键和delete键删除tab、回车符

" 搜索时大小写
set ignorecase                                  "搜索时忽略大小写
"set ignorecase  smartcase                       "搜索时忽略大小写，但在有一个或以上大写字母时仍保持对大小写敏感

" 备份 backup
set nowritebackup                               "写入期间不进行备份
set nobackup                                    "不保存备份
set noundofile                                  "不保存撤销文件

" 交换 swap
set directory=$VIMRUNTIME\swp                   "swp文件建立在vim目录的swp文件夹下

" 撤销保持 Persistent undo
"set hidden                                      "切换buffer(文件/tab)后仍然保留undo
"set undofile
"set undodir=$VIMRUNTIME\undo
"set undolevels=1000
"set undoreload=10000

" 帮助语言
set helplang=en                                 "设置英文帮助
"set helplang=cn                                "设置中文帮助

" 中文格式
set fileformats=dos                             "消除文件格式不正确的出现
"set encoding=utf-8                             "解决中文乱码
set termencoding=utf-8 
set fileencodings=utf-8,chinese,latin-1 
if has("win32") 
    set fileencoding=chinese 
else 
    set fileencoding=utf-8 
endif 

" -------------------------------------------------------------
"                           插件设置
" -------------------------------------------------------------
" 设置运行路径，注意新建系统变量VIM指向Gvim的安装目录
if(has('win32') || has('win64'))
    set rtp+=$VIM/vimfiles/bundle/Vundle.vim
    let path='$VIM/vimfiles/bundle'
else
    set rtp+=~/.vim/bundle/Vundle.vim
    let path='~/.vim/bundle'
endif

" 调用vundle
call vundle#begin('$VIM/vimfiles/bundle')

" 使用Vundle管理插件
Plugin 'VundleVim/Vundle.vim'
" 多插件列表
Plugin 'AutoComplPop'                                   "自动补全窗口弹出
Plugin 'preservim/nerdtree'                             "显示当前路径目录树结构
"Plugin 'dense-analysis/ale'                            "ALE-Asynchronous Lint Engine语法检查
Plugin 'vim-syntastic/syntastic'                        "syntastic语法检查
Plugin 'vim-airline/vim-airline'                        "状态栏美化
Plugin 'file:///F/Vim/vimfiles/bundle/VisIncr'          "VisIncr列操作
Plugin 'load_template'                                  "加载模板
Plugin 'stormherz/tablify'                              "自动化转换表格插件
Plugin 'DrawIt'                                         "ASCII相关图形绘制
Plugin 'nelstrom/vim-visual-star-search'                "可视模式使用*搜索


call vundle#end()

" 总是打开Location List（相当于QuickFix）窗口，如果你发现syntastic因为与其他插件冲突而经常崩溃，将下面选项置0
let g:syntastic_always_populate_loc_list = 1

" 不自动进行代码检查
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 0
let g:syntastic_mode_map = {
        \ "mode": "passive",
        \ "active_filetypes": [""],
        \ "passive_filetypes": ["verilog"] }
        
" 设置linter为iverilog
let g:syntastic_verilog_checkers = ['iverilog']"允许插件 

filetype plugin on

" -------------------------------------------------------------
"                     设置标签用于对齐
" -------------------------------------------------------------
source $VIMRUNTIME/macros/matchit.vim

let b:match_ignorecase=0
let b:match_words=
  \ '\<begin\>:\<end\>,' .
  \ '\<if\>:\<else\>,' .
  \ '\<module\>:\<endmodule\>,' .
  \ '\<class\>:\<endclass\>,' .
  \ '\<program\>:\<endprogram\>,' .
  \ '\<clocking\>:\<endclocking\>,' .
  \ '\<property\>:\<endproperty\>,' .
  \ '\<sequence\>:\<endsequence\>,' .
  \ '\<package\>:\<endpackage\>,' .
  \ '\<covergroup\>:\<endgroup\>,' .
  \ '\<primitive\>:\<endprimitive\>,' .
  \ '\<specify\>:\<endspecify\>,' .
  \ '\<generate\>:\<endgenerate\>,' .
  \ '\<interface\>:\<endinterface\>,' .
  \ '\<function\>:\<endfunction\>,' .
  \ '\<task\>:\<endtask\>,' .
  \ '\<for\>:\<endfor\>,' .
  \ '\<while\>:\<endwhile\>,' .
  \ '\<specify\>:\<endspecify\>,' .
  \ '\<generate\>:\<endgenerate\>,' .
  \ '\<case\>\|\<casex\>\|\<casez\>:\<endcase\>,' .
  \ '\<fork\>:\<join\>\|\<join_any\>\|\<join_none\>,'
  
" -------------------------------------------------------------
"                         杂项
" -------------------------------------------------------------
" creat tags
set tags=tags;
set autochdir

" 窗口管理
let Tlist_Show_One_File=1
let Tlist_Exit_OnlyWindow=1
"let g:winManagerWindowLayout='FileExplorer|TagList'
let g:winManagerWindowLayout='FileExplorer'
nmap vp :WMToggle<cr>

" 多文件编辑
let g:miniBufExplMapCTabSwitchBufs=1
let g:miniBufExplMapWindowsNavVim=1
let g:miniBufExplMapWindowNavArrows=1
let g:miniBufExplorerMoreThanOne=1
"grep
"nnoremap <silent> <F10> :Grep<CR>

" 输入;ee编辑_vimrc
:map ;ee :e $VIMHOME/_vimrc<cr>

"cnoremap <silent> sp :sp<cr>
"cnoremap <silent> vp :vsplit<cr>
":map gb :bd<cr><F4>                        "键盘键的映射，将gb快捷键映射为:bd回车键。即新建一个vim窗口。

" 删除
":map ;m :%s/

:autocmd Bufread :source $VIMHOME/_vimrc<cr>:w!<cr>

" restore your cursor position in a file over several editing sessions
au BufReadPost * if line("'\"") > 0|if line("'\"") <= line("$")|exe("norm '\"")|else|exe "norm $"|endif|endif

" 开启Rtl树
let t:RtlTreeVlogDefine = 1