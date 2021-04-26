"=============================================================================
" Vim Plugin for Verilog Code Automactic Generation (with RtlTree)
" 
" Language:       Verilog
" Author:         zhangguo
" Maintainer:     HonkW
" Version:        2.2.4
" Last Update:    2017/9/18
" Last Modified:  2021/03/26 00:45
" For version 7.x or above

" the new signal define store format
" will applied
"
" dict  {key : value}
" array [value0, value1]
"
" signal_dict:
"   {
"       signal_name :
"          0     1       2       3    4      5          6       7
"       [width,type,has_defined,seq,line,signal_name,io_dir,last_port]
"   }
"   width       : is the result -1 by number or define or parameter; if no define, set to ''
"   type        : is io_wire,io_reg,usrdef,inst_wire,freg,creg,wire; 
"                   if no define, set to ''
"                   if type is io, default value is io_wire, and will update to io_reg if it use in always block
"                   if type is 'keep', rev for `ifdef `ifndef ...
"   has_defined : only use for io, default value set to 0
"   seq         : normal value is 0 - n, only for io & usrdefine, keep define sequence number not change; if no use, set to -1 
"   line        : it is the define line contents, only use for usrdefine; if no use, set to ''
"   signal_name : signal net name
"   io_dir      : if signal is io net, show io_dir, input / output / inout
"
"
" signal with is same, so use link_dict
" link_dict:
"   {
"       signal_name :
"       {
"           {siga : ''},
"           {sigb : ''},
"           ...
"           {sign : ''}
"       }
"   }
"
" below is all signals
" unresolved_dict:
"   {sig : ''}
"
"=============================================================================

"记录脚本更新
autocmd BufWrite automatic.vim call UpdateVimscriptLastModifyTime()
function UpdateVimscriptLastModifyTime()
    let line = getline(9)
    if line =~ '\" Last Modified'
        call setline(9,"\" Last Modified:  " . strftime("%Y/%m/%d %H:%M"))
    endif
endfunction

"Version 启动判断{{{1
if version < 700        "如果vim版本低于7.0则无效,类似写法为 if v:version < 703,代表版本低于7.3
   finish
endif
if exists("vlog_plugin")
   finish
endif
let vlog_plugin = 1

"iabbrev <= <= #0.1     "简写 <= 自动生成 <= #0.1
"}}}1


"Variable & Config & Type 配置参数{{{1

"Variable Define 定义参数 {{{2

"Set Personal {{{3
"let s:GotoInstFile_use = 0
"let s:tree_array_idx = 0
"let s:tree_array = []
let s:verilog_indent_width = 4          "Set Verilog Indent
let s:vlog_max_col = 40                 "Set AutoArg Margin Length
let s:vlog_arg_margin = "    "
let s:autodef_max_len = 39              "Set AutoDef Margin Length
let s:autoinst_prefix_max_len = 32      "Set AutoInst Margin Length
let s:autoinst_suffix_max_len = 64 

let t:RtlTreeVlogDefine = 1              "Open RTLTree
let s:rtltree_init_max_display_layer = 2 "Set RTLTree Layer
"}}}3

"Set Default{{{3
if exists("s:verilog_indent_width")
   let s:vlog_ind = s:verilog_indent_width
   let s:indent = repeat(' ',s:vlog_ind)
else
   let s:vlog_ind = 4
   let s:indent = repeat(' ',s:vlog_ind)
endif

if exists("s:vlog_max_col") == 0
   let s:vlog_max_col = 40
endif
if exists("s:vlog_arg_margin") == 0
   let s:vlog_arg_margin = "    "
endif

if exists("s:vlog_inst_margin") == 0
   let s:vlog_inst_margin = "    "
endif

if exists("s:autodef_max_len") == 0
    let s:autodef_max_len = 39
endif

if exists("s:autoinst_prefix_max_len") == 0
    let s:autoinst_prefix_max_len = 26+4
endif

if exists("s:autoinst_suffix_max_len") == 0
    let s:autoinst_suffix_max_len = 30+12
endif

if exists("s:rtltree_init_max_display_layer") == 0
    let s:rtltree_init_max_display_layer = 2
endif

if exists("t:RtlTreeVlogDefine") == 0
    let t:RtlTreeVlogDefine = 1
endif
"}}}3

"}}}2

" Wave Define 定义波形{{{2
let s:sig_offset = 13           "Signal offset 
"let s:sig_offset = 13+4         "Signal offset (0 is clk posedge, 4 is clk negedge)
let s:clk_period = 8            "Clock period
let s:clk_num = 16              "Number of clocks generated
let s:cq_trans = 1              "Signal transition started N spaces after clock transition
let s:wave_max_wd = s:sig_offset + s:clk_num*s:clk_period       "Maximum Width
"}}}2

" Verilog Type Define 定义变量类型{{{2

"Port 端口类型
let s:VlogTypePort =                  '\<input\>\|'
let s:VlogTypePort = s:VlogTypePort . '\<output\>\|'
let s:VlogTypePort = s:VlogTypePort . '\<inout\>'

"Data 数据类型
let s:VlogTypeData =                  '\<wire\>\|'
let s:VlogTypeData = s:VlogTypeData . '\<reg\>\|'
let s:VlogTypeData = s:VlogTypeData . '\<parameter\>\|'
let s:VlogTypeData = s:VlogTypeData . '\<localparam\>\|'
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

"Keywords 关键词类型
let s:VlogTypePre  = '\('
let s:VlogTypePost = '\)'
let s:VlogTypeConn = '\|'

let s:VlogTypePorts = s:VlogTypePre . s:VlogTypePort . s:VlogTypePost
let s:VlogTypeDatas = s:VlogTypePre . s:VlogTypeData . s:VlogTypePost
let s:VlogTypeCalcs = s:VlogTypePre . s:VlogTypeCalc . s:VlogTypePost
let s:VlogTypeStrus = s:VlogTypePre . s:VlogTypeStru . s:VlogTypePost
let s:VlogTypeOthes = s:VlogTypePre . s:VlogTypeOthe . s:VlogTypePost

let s:VlogKeyWords  = s:VlogTypePre . s:VlogTypePort . s:VlogTypeConn .  s:VlogTypeData . s:VlogTypeConn. s:VlogTypeCalc . s:VlogTypeConn. s:VlogTypeStru . s:VlogTypeConn. s:VlogTypeOthe . s:VlogTypePost

"Not Keywords 非关键词类型
let s:not_keywords_pattern = s:VlogKeyWords . '\@!\(\<\w\+\>\)'

"}}}2

"}}}1


"Menu 菜单栏{{{1

"Verilog Code Block{{{2
amenu &Verilog.Code.Always@.always\ @(posedge\ or\ posedge)<TAB><;al>   :call AlBpp()<CR>i
amenu &Verilog.Code.Always@.always\ @(posedge\ or\ negedge)             :call AlBpn()<CR>
amenu &Verilog.Code.Always@.always\ @(*)                                :call AlB()<CR>
amenu &Verilog.Code.Always@.always\ @(negedge\ or\ negedge)             :call AlBnn()<CR>
amenu &Verilog.Code.Always@.always\ @(posedge)                          :call AlBp()<CR>
amenu &Verilog.Code.Always@.always\ @(negedge)                          :call AlBn()<CR>
amenu &Verilog.Code.Header.AddHeader<TAB><;header>                      :call AddHeader()<CR>
amenu &Verilog.Code.Comment.SingleLineComment<TAB><;//>                 :call AutoComment()<CR>
amenu &Verilog.Code.Comment.MultiLineComment<TAB>Visual-Mode\ <;/*>     :call AutoComment2()<CR>
amenu &Verilog.Code.Comment.CurLineAddComment<TAB><;/$>                 :call AddCurLineComment()<CR>
amenu &Verilog.Code.Template.LoadTemplate<TAB>                          :call LoadTemplate()<CR>
"}}}2

"Verilog Wave {{{2
amenu &Verilog.Wave.AddClk                                              :call AddClk()<CR>
amenu &Verilog.Wave.AddSig                                              :call AddSig()<CR>
amenu &Verilog.Wave.AddBus                                              :call AddBus()<CR>
amenu &Verilog.Wave.AddBlk                                              :call AddBlk()<CR>
amenu &Verilog.Wave.-Operation-                                         :
amenu &Verilog.Wave.Invert<TAB><C-F8>                                   :call Invert()<CR>
"}}}2

"Verilog Auto Arg/Def/Inst {{{2
amenu &Verilog.Auto.-AutoDef-                                           :
amenu &Verilog.Auto.AutoArg<TAB><S-F1>                                  :call AutoArg()<CR>
amenu &Verilog.Auto.AutoDef<TAB><S-F2>                                  :call AutoDef()<CR>
amenu &Verilog.Auto.-AutoInst-                                          :
amenu &Verilog.Auto.AutoInst<TAB><S-F3>                                 :call AutoInst(0)<CR>
amenu &Verilog.Auto.AutoInst\ -\ all<TAB><S-F4>                         :call AutoInst(1)<CR>
amenu &Verilog.Auto.AutoInstUpdate<TAB>                                 :call AutoInstUpdate(0)<CR>
amenu &Verilog.Auto.AutoInstUpdateOrder<TAB>                            :call AutoInstUpdateOrder(0)<CR>
amenu &Verilog.Auto.AutoInstPortReAlign<TAB>                            :call AutoInstPortReAlign()<CR>
amenu &Verilog.Auto.AppendPortDriectionToInst<TAB>                      :call AppendPortDriectionToInst(0)<CR>
amenu &Verilog.Auto.-KillAuto-                                          :
amenu &Verilog.Auto.KillAuto                                            :call KillAuto()<CR>
amenu &Verilog.Auto.KillAutoArg                                         :call KillAutoArg()<CR>
amenu &Verilog.Auto.KillAutoDef                                         :call KillAutoDef()<CR>
amenu &Verilog.Auto.KillAutoInst                                        :call KillAutoInst(0)<CR>
amenu &Verilog.Auto.KillAutoInst\ -\ all                                :call KillAutoInst(1)<CR>
amenu &Verilog.Auto.-Misc-                                              :
amenu &Verilog.Auto.WireDef2PortConn<TAB>                               :call WireDef2PortConn()<CR>
amenu &Verilog.Auto.Input<->Output<TAB>                                 :call Input2Output()<CR>
"}}}2

"Verilog Search {{{2
amenu &Verilog.Search.-netlist-                                         :
amenu &Verilog.Search.instance\ -\ up<TAB><C-F1>                        :call SearchInstance(1)<CR>
amenu &Verilog.Search.instance\ -\ down<TAB><C-F2>                      :call SearchInstance(0)<CR>
amenu &Verilog.Search.-structure-                                       :
amenu &Verilog.Search.module\ -\ up<TAB><C-F3>                          :call SearchModule(1)<CR>
amenu &Verilog.Search.module\ -\ down<TAB><C-F4>                        :call SearchModule(0)<CR>
amenu &Verilog.Search.-driver-                                          :
amenu &Verilog.Search.Trace\ Driver(Lite)<TAB><AS-D>                    :call SearchDriverLite(0)<CR>
amenu &Verilog.Search.-navigation-                                      :
amenu &Verilog.Search.Backward\ History<TAB><CA-B>                      :call BackwardMark()<CR>
amenu &Verilog.Search.Forward\ History<TAB><CA-F>                       :call ForwardMark()<CR>
"}}}2

"}}}1


"ToolBar 工具栏{{{1

"Main Menu 主工具栏{{{2
amenu ToolBar.-Show-                                                    :
amenu icon=$VIM/vim82/after/ShowCall.bmp ToolBar.ShowCall               :call ShowCall()<CR>
amenu icon=$VIM/vim82/after/ShowDef.bmp  ToolBar.ShowDef                :call ShowDef()<CR>

amenu ToolBar.-TimingWave-                                              :
amenu icon=$VIM/vim82/after/AddClk.bmp   ToolBar.AddClk                 :call AddClk()<CR>
amenu icon=$VIM/vim82/after/AddSig.bmp   ToolBar.AddSig                 :call AddSig()<CR>
amenu icon=$VIM/vim82/after/AddBus.bmp   ToolBar.AddBus                 :call AddBus()<CR>
amenu icon=$VIM/vim82/after/AddNeg.bmp   ToolBar.AddNeg                 :call AddNeg()<CR>
amenu icon=$VIM/vim82/after/AddBlk.bmp   ToolBar.AddBlk                 :call AddBlk()<CR>

amenu ToolBar.-Always-                                                  :
amenu icon=$VIM/vim82/after/alpp.bmp     ToolBar.alpp                   :call AlBpp()<CR>i
amenu icon=$VIM/vim82/after/alpn.bmp     ToolBar.alpn                   :call AlBpn()<CR>
amenu icon=$VIM/vim82/after/al.bmp       ToolBar.al                     :call AlB()<CR>
amenu icon=$VIM/vim82/after/alnn.bmp     ToolBar.alnn                   :call AlBnn()<CR>
"}}}2

"Tip Menu 悬浮提示语{{{2
tmenu ToolBar.ShowCall                   ShowCall
tmenu ToolBar.ShowDef                    ShowDef
tmenu ToolBar.AddClk                     AddClk
tmenu ToolBar.AddSig                     AddSig
tmenu ToolBar.AddBus                     AddBus
tmenu ToolBar.AddNeg                     AddNeg
tmenu ToolBar.AddBlk                     AddSep line
tmenu ToolBar.alpp                       always@(posedge clk or posedge rst)
tmenu ToolBar.alpn                       always@(posedge clk or negedge rst_n)
tmenu ToolBar.al                         always@(*)
tmenu ToolBar.alnn                       always@(negedge clk or negedge rst_n)
"}}}2

"}}}1


"Map Keys 快捷键{{{1

"Emacs-Verilog-mode{{{2

"添加emacs之后可使用部分emacs的功能，快捷键调用即可，与本插件的功能基本一致,优点在于可以跨目录,其余功能相差不大
"自动化功能包括AutoInst,AutoArg,AutoPara,AutoReg,AutoWire 
"识别符为/*autoinst*/ /*autoarg*/ /*autoinstparam*/ /*autoreg*/ /*autowire*/

command EmacsAuto                                                       :call EmacsAuto() 
command EmacsDir                                                        :call EmacsDir() 

function EmacsAuto() 
    let current_filename = expand("%")
    let cmd = input("", "!emacs --batch ".current_filename." -f verilog-batch-auto".repeat("\<left>",24))
    exe cmd
endfunction 

function EmacsDir() 
    let lnum = line(".")
    for idx in range(1,4)
        call append(lnum,"")
    endfor
    call setline(lnum+1,"//Config EmacsAuto,\"\.\" represents current folder while \"\.\.\" represents upper folder")
    call setline(lnum+2,"//Local Variables:")
    call setline(lnum+3,"//verilog-library-directories:(\".\" \"a\" \"../aa\")")    
    call setline(lnum+4,"//End:")
endfunction 

"}}}2

"Automatic 快捷键{{{2

"Add Always 添加always块
map ;al                                                                 :call AlBpp()<CR>i  
"Add Header 添加文件头
map ;header                                                             :call AddHeader()<CR> 
"Add Comment 添加注释
map ;//                                                                 :call AutoComment()<ESC>
map ;/*                                                                 <ESC>:call AutoComment2()<ESC>
map ;/$                                                                 :call AddCurLineComment()<ESC>

"Invert Wave 波形翻转
map <C-F8>                                                              :call Invert()<ESC>

"
map <C-J>                                                               :call ShowInst()<ESC>
"Like Verdi 类verdi进出模块功能
map <CA-A>                                                              :call ShowCall()<ESC>
map <CA-N>                                                              :call ShowDef()<ESC>

"Auto Arg/Def/Inst 自动生成
map <S-F1>                                                              :call AutoArg()<ESC>
map <S-F2>                                                              :call AutoDef()<ESC>
map <S-F3>                                                              :call AutoInst(0)<ESC>
map <S-F4>                                                              :call AutoInst(1)<ESC>
"map <F5>                                                                :call WireDef2PortConn()<ESC>
"map <F6>                                                                :call Input2Output()<ESC>

"Search 搜索
"map <F9>                                                                :call SearchUpInstLine()<ESC>
map <C-F1>                                                              :call SearchInstance(1)<ESC>
map <C-F2>                                                              :call SearchInstance(0)<ESC>
map <C-F3>                                                              :call SearchModule(1)<ESC>
map <C-F4>                                                              :call SearchModule(0)<ESC>
map <AS-D>                                                              :call SearchDriverLite(0)<ESC>
map <CA-B>                                                              :call BackwardMark()<ESC>
map <CA-F>                                                              :call ForwardMark()<ESC>

"Rtl树
command RtlTree                                                         :call RtlTree()

"生成新文件自动添加头部和模板，重新写入文件时更新写入时间
autocmd BufNewFile *.v call AutoTemplate()
autocmd BufWrite *.v call UpdateLastModifyTime()
"autocmd BufRead *.v call GotoInstRenderTree()

"}}}2

"Self-Define Function 自定义功能{{{2

"Generate Time 生成时间 {{{3
"F2 -> 2019/11/20 
:imap <F2> <C-R>=strftime("%x")<CR>
"2019/11/20 23:39:15
":imap <F2> <C-R>=strftime("%c")<CR>
"}}}3

"Inst F2例化光标选中变量 {{{3
":map <F2> ebmsd^:.s/^ *\([a-zA-Z][a-zA-Z0-9_]*\).*$/        .\1                        (\1                        ),/<cr>*^24ldw24ldw`sj
"}}}3

"Declaration 端口/变量声明 {{{3
:map ;dw ebmsd^:.s/^ *\([a-zA-Z][a-zA-Z0-9_]*\).*$/    wire \1 ;/<cr><F8>`sj:noh<cr>
:map ;dr ebmsd^:.s/^ *\([a-zA-Z][a-zA-Z0-9_]*\).*$/    reg \1 ;/<cr><F8>`sj:noh<cr>
:map ;di ebmsd^:.s/^ *\([a-zA-Z][a-zA-Z0-9_]*\).*$/    input   \1 ,/<cr><F7>`sj:noh<cr>
:map ;dow ebmsd^:.s/^ *\([a-zA-Z][a-zA-Z0-9_]*\).*$/    output wire    \1 ,/<cr><F7>`sj:noh<cr>
:map ;dor ebmsd^:.s/^ *\([a-zA-Z][a-zA-Z0-9_]*\).*$/    output reg     \1 ,/<cr><F7>`sj:noh<cr>
"}}}3

"Align 对齐 {{{3
:map <F7> 0f,bi                                                   <ESC>032ldwf,i                                                   <ESC>064ldwa        <ESC>dw^
:map <F8> 0f;bi                                                   <ESC>032ldwf;i                                                   <ESC>064ldwa        <ESC>dw^
:map <F6> :s/^ *\./        ./<cr>^f(i                                                   <ESC>f)i                                                   <ESC>^28ldw32ldwa  <ESC>hdw:noh<cr>
"调整module定义中的逗号和注释的位置（定义中不包含input、output时使用）
":map <F9> 0f,i                                                    <ESC>068ldwa        <ESC>dw<ESC>^
"}}}3

"TAB 转化为空格
:map ;t :retab<cr>

"}}}2

"}}}1


"TimingWave 时序波形{{{1

function AddClk() "{{{2
    let ret = []
    let ret0 = "//  .   .   ."
    let ret1 = "//          +"
    let ret2 = "// clk      |"
    let ret3 = "//          +"
    let format = '%' . s:clk_period/2 . 'd'
    for idx in range(1,s:clk_num)
        let ret0 = ret0 . printf(format,idx) . repeat(' ',s:clk_period/2)
        let ret1 = ret1 . repeat('-',s:clk_period/2-1)
        let ret2 = ret2 . repeat(' ',s:clk_period/2-1)
        let ret3 = ret3 . repeat(' ',s:clk_period/2-1)
        let ret1 = ret1 . '+'
        let ret2 = ret2 . '|'
        let ret3 = ret3 . '+'
        let ret1 = ret1 . repeat(' ',s:clk_period/2-1)
        let ret2 = ret2 . repeat(' ',s:clk_period/2-1)
        let ret3 = ret3 . repeat('-',s:clk_period/2-1)
        let ret1 = ret1 . '+'
        let ret2 = ret2 . '|'
        let ret3 = ret3 . '+'
    endfor
    call add(ret,ret0)
    call add(ret,ret1)
    call add(ret,ret2)
    call add(ret,ret3)
    let lnum = line(".")
    let col = col(".")
    call append(line("."),ret)
    call cursor(lnum+4,col)
endfunction "}}}2

function AddSig() "{{{2
    let ret = []
    let ret0 = "//          "
    let ret1 = "// sig      "
    let ret2 = "//          "
    let ret0 = ret0 . repeat(' ',s:clk_num*s:clk_period+1)
    let ret1 = ret1 . repeat(' ',s:clk_num*s:clk_period+1)
    let ret2 = ret2 . repeat('-',s:clk_num*s:clk_period+1)
    call add(ret,ret0)
    call add(ret,ret1)
    call add(ret,ret2)
    let lnum = line(".")
    let col = col(".")
    call append(line("."),ret)
    call cursor(lnum+3,col)
endfunction "}}}2

function AddBus() "{{{2
    let ret = []
    let ret0 = "//          "
    let ret1 = "// bus      "
    let ret2 = "//          "
    let ret0 = ret0 . repeat('-',s:clk_num*s:clk_period+1)
    let ret1 = ret1 . repeat(' ',s:clk_num*s:clk_period+1)
    let ret2 = ret2 . repeat('-',s:clk_num*s:clk_period+1)
    call add(ret,ret0)
    call add(ret,ret1)
    call add(ret,ret2)
    let lnum = line(".")
    let col = col(".")
    call append(line("."),ret)
    call cursor(lnum+3,col)
endfunction "}}}2

function AddNeg() "{{{2
    let lnum = s:GetSigNameLineNum()
    if lnum == -1
        return
    endif
    let line = getline(lnum)
    if line =~ 'neg\s*$'
        return
    endif
    call setline(lnum,line." neg")
endfunction "}}}2

function AddBlk() "{{{2
    let ret = []
    let ret0 = "//          "
    let ret0 = ret0 . repeat(' ',s:clk_num*s:clk_period+1)
    call add(ret,ret0)
    let lnum = line(".")
    let col = col(".")
    call append(line("."),ret)
    call cursor(lnum+1,col)
endfunction "}}}2

function Invert() "{{{2
"   clk_period = 8
"   clk_num = 16
"   cq_trans = 1
"
"1  .   .   .   1       2       3       4       5       6       7       8       9      10      11      12      13      14      15      16    
"2          +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +
"3 clk      |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |
"4          +   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+
"5
"6                           +-------+                                                                                                       
"7 sig                       |*      |                                                                                                       
"8          -----------------+       +-------------------------------------------------------------------------------------------------------
"1.........13..............29......37
"
    let lnum = s:GetSigNameLineNum()    "7
    if lnum == -1
        return
    endif

    let top = getline(lnum-1)   "line 6
    let mid = getline(lnum)     "line 7
    let bot = getline(lnum+1)   "line 8

    let signeg = s:SigIsNeg()                   "detect negative marker 
    let posedge = s:GetPosedge(signeg)          "detect nearest posedge     29
    let negedge = posedge + s:clk_period/2      "detect next negedge        33
    let next_posedge = posedge + s:clk_period   "detect next posedge        37 

    let last = s:SigLastClkIsHigh(lnum,posedge,negedge)     "detect line 6, col 29 is not '-'   last = 0
    let cur = s:SigCurClkIsHigh(lnum,posedge,negedge)       "detect line 6, col 33 is '-'       cur = 1
    let next = s:SigNextClkIsHigh(lnum,posedge,negedge)     "detect line 6, col 37 is '-'       next = 1
    let chg = s:BusCurClkHaveChg(lnum,posedge,negedge)      "judge if bus marker 'X' to see if already changed

    "from 0 to posedge+cq_trans-1{{{3
    let res_top = strpart(top,0,posedge+s:cq_trans-1)
    let res_mid = strpart(mid,0,posedge+s:cq_trans-1)
    let res_bot = strpart(bot,0,posedge+s:cq_trans-1)
    "}}}3

    "from posedge+cq_trans to (posedge+clk_period)(i.e.next_posedge)+cq_trans-1{{{3
    let init_top_char = ' '
    let init_mid_char = ' '
    let init_bot_char = ' '
    let top_char = ' '
    let mid_char = ' '
    let bot_char = ' '
    let is_bus = 0

    if top[negedge] =~ '-' && bot[negedge] =~ '-'           "two lines, must be bus
        let is_bus = 1
        if chg
            let init_top_char = '-'
            let init_mid_char = ' '
            let init_bot_char = '-'
        else
            let init_top_char = ' '
            let init_mid_char = 'X'
            let init_bot_char = ' '
        endif
        let top_char = '-'
        let mid_char = ' '
        let bot_char = '-'
        let res_top = res_top . init_top_char
        let res_mid = res_mid . init_mid_char
        let res_bot = res_bot . init_bot_char
        for idx in range(1,s:clk_period-1)
            let res_top = res_top . top_char
            let res_mid = res_mid . mid_char
            let res_bot = res_bot . bot_char
        endfor
    else                                                    "one line or none, signal
        if last == cur
            if cur                                          "last=1 cur=1 both high
                let init_top_char = '+'
                let init_mid_char = '|'
                let init_bot_char = '+'
                let top_char = ' '
                let bot_char = '-'
            else
                let init_top_char = '+'                     "last=0 cur=0 both low 
                let init_mid_char = '|'
                let init_bot_char = '+'
                let top_char = '-'
                let bot_char = ' '
            endif
        else
            if cur                                          "last=0 cur=1 posedge
                let init_top_char = ' '
                let init_mid_char = ' '
                let init_bot_char = '-'
                let top_char = ' '
                let bot_char = '-'
            else
                let init_top_char = '-'                     "last=1 cur=0 negedge
                let init_mid_char = ' '
                let init_bot_char = ' '
                let top_char = '-'
                let bot_char = ' '
            endif
        endif

        let res_top = res_top . init_top_char
        let res_mid = res_mid . init_mid_char
        let res_bot = res_bot . init_bot_char
        for idx in range(1,s:clk_period-1)
            let res_top = res_top . top_char
            let res_mid = res_mid . mid_char
            let res_bot = res_bot . bot_char
        endfor

        if next == cur                                      "cur=next=1 or 0
            let init_top_char = '+'
            let init_mid_char = '|'
            let init_bot_char = '+'
        else
            if cur
                let init_top_char = ' '
                let init_mid_char = ' '
                let init_bot_char = '-'
            else
                let init_top_char = '-'
                let init_mid_char = ' '
                let init_bot_char = ' '
            endif
        endif
        let res_top = res_top . init_top_char
        let res_mid = res_mid . init_mid_char
        let res_bot = res_bot . init_bot_char
    endif
    "}}}3

    "from posedge+clk_period+cq_trans to max{{{3
    let res_top = res_top .strpart(top,posedge+s:cq_trans+s:clk_period-is_bus,s:wave_max_wd-1)
    let res_mid = res_mid .strpart(mid,posedge+s:cq_trans+s:clk_period-is_bus,s:wave_max_wd-1)
    let res_bot = res_bot .strpart(bot,posedge+s:cq_trans+s:clk_period-is_bus,s:wave_max_wd-1)
    "}}}3

    call setline(lnum-1,res_top)
    call setline(lnum,res_mid)
    call setline(lnum+1,res_bot)
endfunction "}}}2

function s:My_mod(int1,int2) "{{{2
    let ret = a:int1
    while 1
        if ret >= a:int2
            let ret = ret - a:int2
        else
            break
        endif
    endwhile
    return ret
endfunction "}}}2

function s:GetSigNameLineNum() "{{{2
    let lnum = -1
    let cur_lnum = line(".")
    if getline(cur_lnum) =~ '^\/\/\s*\(sig\|bus\)'
        let lnum = cur_lnum
    elseif getline(cur_lnum-1) =~ '^\/\/\s*\(sig\|bus\)'
        let lnum = cur_lnum-1
    elseif getline(cur_lnum+1) =~ '^\/\/\s*\(sig\|bus\)'
        let lnum = cur_lnum+1
    endif
    return lnum
endfunction "}}}2

function s:GetPosedge(signeg) "{{{2
"calculate the width between col(".") and the nearest posedge
    if a:signeg == 0
        return col(".") - s:My_mod(col(".") - s:sig_offset,s:clk_period)
    else
        return col(".") - s:My_mod(col(".") - s:sig_offset + s:clk_period/2,s:clk_period)
    endif
endfunction "}}}2

function s:SigLastClkIsHigh(lnum,posedge,negedge) "{{{2
    let ret = 0
    let line = getline(a:lnum - 1)
    if line[a:posedge-1] =~ '-'
        let ret = 1
    endif
    return ret
endfunction "}}}2

function s:SigCurClkIsHigh(lnum,posedge,negedge) "{{{2
    let ret = 0
    let line = getline(a:lnum - 1)
    if line[a:negedge-1] =~ '-'
        let ret = 1
    endif
    return ret
endfunction "}}}2

function s:SigNextClkIsHigh(lnum,posedge,negedge) "{{{2
    let ret = 0
    let line = getline(a:lnum - 1)
    if line[a:negedge+s:clk_period-1] =~ '-'
        let ret = 1
    endif
    return ret
endfunction "}}}2

function s:BusCurClkHaveChg(lnum,posedge,negedge) "{{{2
    let ret = 0
    let line = getline(a:lnum)
    if line[a:posedge+s:cq_trans-1] =~ 'X'
        let ret = 1
    endif
    return ret
endfunction "}}}2

function s:SigIsNeg() "{{{2
    let ret = 0
    let lnum = s:GetSigNameLineNum()
    if getline(lnum) =~ 'neg\s*$'
        let ret = 1
    endif
    return ret
endfunction "}}}2


"}}}1


"Code 快速插入代码段{{{1

"AutoTemplate 快速新建.v文件 / 添加文件头 / 模板更新{{{2

function s:GetUserName() "{{{3

    "let a:user = system("echo $USER_DIT")
    "let a:user = substitute(a:user,'\n','','')      "去掉\n换行符
    "if a:user =~ 'USER_DIT:'
    "    let a:user = $USER
    "endif
    "return a:user
    
    let user = g:vimrc_author
    return user 
    
endfunction "}}}3

function UpdateLastModifyTime() "{{{3
    let line = getline(8)
    if line =~ '// Last Modified'
        call setline(8,"// Last Modified : " . strftime("%Y/%m/%d %H:%M"))
    endif
endfunction "}}}3

function AddHeader() "{{{3
    let line = getline(1)
    if line =~ '// +FHDR'               "已有文件头的文件不再添加
        return
    endif
    
    "记录公司信息,linux配置
    "let company = system("echo $COMPANY")
    "let company = substitute(company,'\n','','')
    "if company =~ 'COMPANY:'
    "   echohl WarningMsg | echo "unix env $COMPANY: Undefined variable. Please set_env COMPANY in ~/.cshrc" | echohl None
    "endif
    
    let author = s:GetUserName()
    let company = g:vimrc_company
    let project = g:vimrc_prject
    let device = g:vimrc_device
    let email = g:vimrc_email
    let website = g:vimrc_website

    let filename = expand("%")          "记录当前文件名
    let timelen = strlen(strftime("%x"))
    let authorlen = strlen(author)

    call append(0 , "// +FHDR----------------------------------------------------------------------------")
    call append(1 , "// Project Name  : ".project)
    call append(2 , "// Device        : ".device)
    call append(3 , "// Author        : ".author)
    call append(4 , "// Email         : ".email)
    call append(5 , "// Website       : ".website)
    call append(6 , "// Create On     : ".strftime("%Y/%m/%d %H:%M"))
    call append(7 , "// Last Modified : ".strftime("%Y/%m/%d %H:%M"))
    call append(8 , "// File Name     : ".filename)
    call append(9 , "// Description   :")
    call append(10, "//         ")
    call append(11, "// ")
    call append(12, "// Copyright (c) ".strftime("%Y ") . company . ".")
    call append(13, "// ALL RIGHTS RESERVED")
    call append(14, "// ")
    call append(15, "// ---------------------------------------------------------------------------------")
    call append(16, "// Modification History:")
    call append(17, "// Date         By              Version                 Change Description")
    call append(18, "// ---------------------------------------------------------------------------------")
    call append(19, "// ".strftime("%x").repeat(" ", 13-timelen).author.repeat(" ", 16-authorlen)."1.0                     Original")
    call append(20, "// ")
    call append(21, "// -FHDR----------------------------------------------------------------------------")
    call cursor(11,10)

endfunction "}}}3

function AutoTemplate() "{{{3
    let filename = expand("%")
    let modulename = matchstr(filename,'\w\+')
    call AddHeader()
    call append(22, "`timescale 1ns/1ps")
    call append(23, "")
    call append(24, "module " . modulename  )
    call append(25, "(")
    call append(26, "clk")
    call append(27, "rst")
    call append(28, ");")
    call append(29, "")
    call append(30, "endmodule")

    "call append(14, "`ifndef __" . substitute(toupper(filename),'\.','_','') . "__")
    "call append(15, "`define __" . substitute(toupper(filename),'\.','_','') . "__")
    "call append(16, "")
    "call append(17, "`timescale 1ns/1ps")
    "call append(18, "")
    "call append(19, "module " . modulename . '(/*autoarg*/);')
    "if modulename == 'top'
    "   call append(20, "")
    "   call append(21, "reg                                     clk;")
    "   call append(22, "reg                                     rst_n;")
    "   call append(23, "/*autodef off*/")
    "   call append(24, "initial begin")
    "   call append(25, "    clk = 1'b0;")
    "   call append(26, "    forever #10 clk = ~clk;")
    "   call append(27, "end")
    "   call append(28, "initial begin")
    "   call append(29, "    rst_n = 1'b0;")
    "   call append(30, "    #52 rst_n = 1'b1;")
    "   call append(31, "end")
    "   call append(32, "initial begin")
    "   call append(33, "    //$vcdpluson(0,top);")
    "   call append(34, "    $fsdbDumpvars(0,top);")
    "   call append(35, "end")
    "   call append(36, "initial begin")
    "   call append(37, "    #1000;")
    "   call append(38, "    $finish;")
    "   call append(39, "end")
    "   call append(40, "/*autodef on*/")
    "   call append(41, "")
    "   call append(42, "//{{")
    "   call append(43, '/*autodef*/')
    "   call append(44, "//}}")
    "   call append(45, "")
    "   call append(46, "//inst u_inst(/*autoinst*/);")
    "   call append(47, "")
    "   call append(48, "endmodule")
    "    call append(49, "")
    "    call append(50, "`endif")
    "   call search('inst')
    "else
    "   call append(20, "")
    "   call append(21, "input                                   clk;")
    "   call append(22, "input                                   rst_n;")
    "   call append(23, "")
    "   call append(24, "input                                   vld;")
    "   call append(25, "input        [7:0]                      data;")
    "   call append(26, "output                                  ack;")
    "   call append(27, "")
    "   call append(28, "//{{")
    "   call append(29, '/*autodef*/')
    "   call append(30, "//}}")
    "   call append(31, "")
    "   call append(32, "endmodule")
    "    call append(33, "")
    "    call append(34, "`endif")
    "   call search('vld')
    "endif
endfunction "}}}3

"}}}2

"Always Block 快速添加always块{{{2

function AlBpp() "{{{3
    let lnum = line(".")
    for idx in range(1,8)
        call append(lnum,"")
    endfor
    call setline(lnum+1,"    always@(posedge clk or posedge rst)begin")
    call setline(lnum+2,"        if(rst)begin")
    call setline(lnum+3,"             ")
    call setline(lnum+4,"        end")
    call setline(lnum+5,"        else begin")
    call setline(lnum+6,"             ")
    call setline(lnum+7,"        end")
    call setline(lnum+8,"    end")
    call cursor(lnum+3,13)
endfunction "}}}3

function AlBpn() "{{{3
    let lnum = line(".")
    for idx in range(1,11)
        call append(lnum,"")
    endfor
    call setline(lnum+1 ,"    always@(posedge clk or negedge rst_n)begin")
    call setline(lnum+2 ,"        if(!rst_n)begin")
    call setline(lnum+3 ,"            ")
    call setline(lnum+4 ,"        end ")
    call setline(lnum+5 ,"        else if()begin")
    call setline(lnum+6 ,"            ")
    call setline(lnum+7 ,"        end") 
    call setline(lnum+8 ,"        else begin")
    call setline(lnum+9 ,"            ")
    call setline(lnum+10,"        end")
    call setline(lnum+11,"    end")
    call cursor(lnum+3,13)
endfunction "}}}3

function AlB() "{{{3
    let lnum = line(".")
    for idx in range(1,3)
        call append(lnum,"")
    endfor
    call setline(lnum+1 ,"    always@(*)begin")
    call setline(lnum+2 ,"        ")
    call setline(lnum+3 ,"    end")
    call cursor(lnum+2,9)
endfunction "}}}3

function AlBnn() "{{{3
    let lnum = line(".")
    for idx in range(1,11)
        call append(lnum,"")
    endfor
    call setline(lnum+1 ,"    always@(negedge clk or negedge rst_n)begin")
    call setline(lnum+2 ,"        if(!rst_n) begin")
    call setline(lnum+3 ,"            ")
    call setline(lnum+4 ,"        end")
    call setline(lnum+5 ,"        else if()begin")
    call setline(lnum+6 ,"            ")
    call setline(lnum+7 ,"        end")
    call setline(lnum+8 ,"        else begin")
    call setline(lnum+9 ,"            ")
    call setline(lnum+10,"        end")
    call setline(lnum+11,"    end")
    call cursor(lnum+3,13)
endfunction "}}}3

function AlBp() "{{{3
    let lnum = line(".")
    for idx in range(1,8)
        call append(lnum,"")
    endfor
    call setline(lnum+1,"    always@(posedge clk)begin")
    call setline(lnum+2,"        if()begin")
    call setline(lnum+3,"            ")
    call setline(lnum+4,"        end")
    call setline(lnum+5,"        else begin")
    call setline(lnum+6,"            ")
    call setline(lnum+7,"        end")
    call setline(lnum+8,"    end")
    call cursor(lnum+3,13)
endfunction "}}}3

function AlBn() "{{{3
    let lnum = line(".")
    for idx in range(1,8)
        call append(lnum,"")
    endfor
    call setline(lnum+1,"    always@(negedge clk)begin")
    call setline(lnum+2,"        if()begin")
    call setline(lnum+3,"            ")
    call setline(lnum+4,"        end")
    call setline(lnum+5,"        else begin")
    call setline(lnum+6,"            ")
    call setline(lnum+7,"        end")
    call setline(lnum+8,"    end")
    call cursor(lnum+3,13)
endfunction "}}}3

"}}}2

"AutoComment 快速添加注释"{{{2

function AutoComment() "{{{3
    let lnum = line(".")
    let line = getline(lnum)

    if line =~ '^\/\/ by .* \d\d\d\d-\d\d-\d\d'
        let tmp_line = substitute(line,'^\/\/ by .* \d\d\d\d-\d\d-\d\d | ','','')
    else
        let tmp_line = '// by ' . s:GetUserName() . ' ' . strftime("%Y-%m-%d") . ' | ' . line
    endif
    call setline(lnum,tmp_line)
endfunction "}}}3

function AutoComment2() "{{{3
    let col = col(".")
    let lnum = line(".")

    if line("'<") == lnum || line("'>") == lnum
        if getline(line("'<")) =~ '^/\*'
            '<
            execute "normal dd"
            '>
            execute "normal dd"
            if lnum != line("'<")
                let lnum = line("'>")-1
            endif
        else
            call append(line("'<")-1,'/*----------------  by '.s:GetUserName().' '.strftime("%Y-%m-%d").'  ---------------------')
            call append(line("'>")  ,'------------------  by '.s:GetUserName().' '.strftime("%Y-%m-%d").'  -------------------*/')
            let lnum = line(".")
        endif
    endif

    call cursor(lnum,col)

    "echo "< = " . line("'<") . " > = " . line("'>") . " cur = " . line(".")
endfunction "}}}3

function AddCurLineComment() "{{{3
    let lnum = line(".")
    let line = getline(lnum)

    let tmp_line = line . ' // ' . s:GetUserName() . ' ' . strftime("%Y-%m-%d") . ' |'
    call setline(lnum,tmp_line)
    normal $
endfunction "}}}3

"}}}2

"}}}1


"Automatic definition 自动例化/生成{{{1

function ShowInst() "{{{2
    if(s:rtl_tree_is_open == 0)
        return
    endif
    " first lnum is 1, and first col is 1
    let lnum = line(".")
    let curcol = col(".")
    let line = getline(lnum)
    if line =~ '\<autoinst\>' && line !~ '--oneline\>'
        call s:ShowInstWrapper(0,lnum,'')
        return
    endif
    "if curcol char is not a word char
    if line[curcol-1] !~ '\w'
        call s:ShowInstWrapper(0,lnum,'')
        return
    else
        if s:SearchComment(lnum,curcol)
            call s:ShowInstWrapper(0,lnum,'')
            return
        endif

        let word = expand("<cword>")

        "mask key words
        "if word =~ '\(\<input\>\|\<output\>\|\<inout\>\|\<wire\>\|\<reg\>\|\<function\>\|\<endfunction\>\|\<task\>\|\<endtask\>\|\<module\>\|\<endmodule\>\)'
        if word =~ s:VlogKeyWords
            call s:ShowInstWrapper(0,lnum,'')
            return
        endif

        let ret = match(line,'\.\s*'. word)
        if ret != -1
            let ret = matchend(line,'\.\s*'. word)
            "curcol is in '.word'
            if ret >= curcol
                call s:ShowInstWrapper(1,lnum,word)
            else
                call s:ShowInstWrapper(2,lnum,word)
            endif
        else
            call s:ShowInstWrapper(2,lnum,word)
        endif
    endif
endfunction "}}}2

"function GotoInstRenderTree() "{{{2
"    if(s:rtl_tree_is_open)
"        "if(s:GotoInstFile_use==0 && s:tree_array_idx>=0)
"        "    let s:current_node = s:tree_array[s:tree_array_idx-1]
"        "    call remove(s:tree_array,s:tree_array_idx-1)
"        "    let s:tree_array_idx = s:tree_array_idx - 1
"        "endif
"        execute bufwinnr(t:NERDTreeBufName) . " wincmd w"
"        call s:oTreeNode.RenderTree()
"
"        call s:oTreeNode.TreeLogInstFullPath()
"
"        "wincmd p
"        let t:RtlBufName = s:GetInstFileName(s:current_node.instname)
"        execute bufwinnr(t:RtlBufName) . " wincmd w"
"    endif
"    "let s:GotoInstFile_use = 0
"endfunction "}}}2

function ShowCall() "{{{2
    if(s:rtl_tree_is_open == 0)
        return
    endif
    let t:RtlBufName = s:GetInstFileName(s:current_node.instname)
    execute bufwinnr(t:RtlBufName) . " wincmd w"

    if(s:rtl_tree_is_open)
        "up a layer
        let node = s:current_node
        "if node.layer == 1
        "    return
        "endif

        execute "tag " . s:current_node.parent.instname
        call cursor(s:current_node.parent_inst_lnum,1)
        execute "normal zt"

        execute bufwinnr(t:NERDTreeBufName) . " wincmd w"
        call cursor(s:current_node.lnum, 1)
        let s:current_node = s:current_node.parent

        let t:RtlBufName = s:GetInstFileName(s:current_node.instname)
        execute bufwinnr(t:RtlBufName) . " wincmd w"

    endif
endfunction "}}}2

function ShowDef() "{{{2
    if(s:rtl_tree_is_open == 0)
        return
    endif
    let t:RtlBufName = s:GetInstFileName(s:current_node.instname)
    execute bufwinnr(t:RtlBufName) . " wincmd w"

    " first lnum is 1, and first col is 1
    let lnum = line(".")
    let curcol = col(".")
    let line = getline(lnum)

    "match() get idx of line
    if s:SearchComment(lnum,curcol)
        echohl ErrorMsg | echo "========ShowDef() fail cause comment=========" | echohl None
        return
    endif

    if s:current_node.unresolved == 0 && s:current_node.childrensolved == 0
        call cursor(1,1)
        call s:oTreeNode.CreateRtlTree(s:current_node)
    endif

    for node in reverse(copy(s:current_node.children))
        if node.parent_inst_lnum <= lnum
            let s:current_node = s:oTreeNode.SearchNodeByLnum(s:rtltree,node.lnum)
            break
        endif
    endfor

    execute "tag " . s:current_node.instname
    execute "normal zt"

    execute bufwinnr(t:NERDTreeBufName) . " wincmd w"
    " module have defined
    if s:current_node.unresolved == 0
        let l:lnum = line(".")
        let l:col = col(".")

        " to get old top line number
        execute "normal H"
        let l:old_top_lnum = line(".")

        let s:current_node.isFold = 0

        call s:oTreeNode.RenderTree()
        execute bufwinnr(t:NERDTreeBufName) . " wincmd w"

        call cursor(l:old_top_lnum, 1)
        execute "normal zt"
        call cursor(l:lnum, l:col)
    endif

    call cursor(s:current_node.lnum, 1)

    let t:RtlBufName = s:GetInstFileName(s:current_node.instname)
    execute bufwinnr(t:RtlBufName) . " wincmd w"

    if line =~ '^\s*\.\w'
        let l:port = s:GetPortName(line)
        call search('^\s*'. s:VlogTypePorts . '\s*' . s:VlogTypeDatas . '*' . '\s*' . '\(\[.*:.*\]\)*' . '\s*' . l:port)
        call search('\<' . l:port . '\>')
    endif

endfunction "}}}2

function s:SearchComment(lnum,curcol) "{{{2
    " 1 found, 0 no found
    "echo "SearchComment ing...."

    "search comment //
    let ret = match(getline(a:lnum),'\/\/')
    if ret != -1
        if ret < a:curcol-1
            return 1
        endif
    endif

    "search comment /* ... */
    for idx in range(a:lnum,1,-1)
        let line = getline(idx)
        "echo line

        "get all start and end ret
        let se_rets = []
        let times = 1
        while 1
            let ret = match(line,'\(\/\*\|\*\/\)',0,times)
            if ret == -1
                break
            else
                if line[ret] == '/'
                    call extend(se_rets,[{'s':ret}])
                else
                    call extend(se_rets,[{'e':ret}])
                endif

                "echo "pos: " . ret . " char = " . line[ret]
                let times = times + 1
            endif
        endwhile
        if len(se_rets) == 0
            continue
        endif

        "have found '/*' or '*/'
        "start match
        let s_ret = -1
        let e_ret = -1
        let s_key = 's'
        let e_key = 's'

        if idx != a:lnum
            "no cur line, only care the last se_ret
            let se_ret = se_rets[len(se_rets)-1]
            for ret in keys(se_ret)
                let e_key = ret
            endfor
            if e_key == 's'
                "echo "====   /* ... curcol"
                return 1
            endif
        else
            "cur line
            "get near two ret beside a:curcol, result is s_ret < a:curcol < e_ret
            let break_list_loop = 0
            for se_ret in se_rets
                for ret in keys(se_ret)
                    "echo ret . ":" . se_ret[ret]
                    if se_ret[ret] < a:curcol-1
                        let s_ret = se_ret[ret]
                        let s_key = ret
                    else
                        let e_ret = se_ret[ret]
                        let e_key = ret
                        let break_list_loop = 1
                    endif
                endfor
                if break_list_loop == 1
                    break
                endif
            endfor
            "echo "result s_ret:e_ret = " . s_ret . ":" . e_ret
            "echo "result s_key:e_key= " . s_key . ":" . e_key
            if s_ret == -1 && e_ret == -1
                echohl ErrorMsg | echo "Fatal error!" | echohl None
            elseif s_ret == -1 && e_ret != -1
                if e_key == 'e'
                    "echo "====  curcol ... */"
                    return 1
                endif
            elseif s_ret != -1 && e_ret == -1
                if s_key == 's'
                    "echo "====   /* ... curcol"
                    return 1
                endif
            elseif s_ret != -1 && e_ret != -1
                "only two result  /* ... curcol ... */ and  */ ... curcol ... /*
                if s_key == 's'
                    "echo "====   /* ... curcol ... */"
                    return 1
                endif
            endif
        endif
        "comment char '/*' or '*/' is not valid for cursol
        "break search comment /* ... */ for
        break
    endfor
    "no found valid '/*' or '*/'
    return 0
endfunction "}}}2

function s:ShowInstWrapper(mode,lnum,word) "{{{2
    "mode: 0-ShowAllInst, 1-ShowSpecInst, 2-ShowWireCon
    "echohl ErrorMsg | echo "========ShowInstWrapper()=========" | echohl None
    call s:oTreeNode.TreeLog("========ShowInstWrapper()=========")
    let in_inst = 0
    let inst = ''
    let max_lnum_wd = s:CalNumLen(line("$"))

    let line_index = 1
    while line_index <= line("$")
        let line_index = s:SkipCommentLine(0,line_index)
        if line_index == -1
            break
        endif
        let cur_lnum_wd = s:CalNumLen(line_index)
        let prefix = s:CalMargin(max_lnum_wd,cur_lnum_wd) . line_index . ": "
        let line = getline(line_index)
        if line =~ '^\s*module\s*\w.*(\/\*autoarg\*\/'
            "echo prefix . line
            call s:oTreeNode.TreeLog(prefix . line)
        "mode 2, match input|output|inout
        "elseif a:mode == 2 && line =~ '^\s*\(\<input\>\|\<output\>\|\<inout\>\)\s*\(\<wire\>\|\<reg\>\)*\s*\(\[.*:.*\]\)*\s*' . '\<' . a:word . '\>'
        elseif a:mode == 2 && line =~ '^\s*' . s:VlogTypePorts . '\s*'. s:VlogTypeDatas . '*' . '\s*\(\[.*:.*\]\)*' . '\s*' . '\<' . a:word . '\>'
            "echohl WarningMsg | echo prefix . line | echohl None
            call s:oTreeNode.TreeLog(prefix . line)
        elseif line =~ '\<autoinst\>'
            let in_inst = 1
            let inst = s:GetInstName(line)
            "echo prefix . line
            call s:oTreeNode.TreeLog(prefix . line)
        elseif line_index == a:lnum
            if in_inst
                "echohl WarningMsg | echo prefix . line . '//' . s:GetInstPortDir(inst,s:GetPortName(line)) . ' <- cursor line' | echohl None
                call s:oTreeNode.TreeLog(prefix . line . '//' . s:GetInstPortDir(inst,s:GetPortName(line)) . ' <- cursor line')
            else    
                "echohl WarningMsg | echo prefix . line . ' <- cursor line' | echohl None
                call s:oTreeNode.TreeLog(prefix . line . ' <- cursor line')
            endif
        "mode 1, match '.word'
        elseif a:mode == 1 && line =~ '^\s*\.\<' . a:word . '\>'
            "echohl WarningMsg | echo prefix . line . '//' . s:GetInstPortDir(inst,s:GetPortName(line)) | echohl None
            call s:oTreeNode.TreeLog(prefix . line . '//' . s:GetInstPortDir(inst,s:GetPortName(line)))
        "mode 2, match '(word'
        elseif a:mode == 2 && line =~ '(.*\s*\<' . a:word . '\>'
            "echohl WarningMsg | echo prefix . line . '//' . s:GetInstPortDir(inst,s:GetPortName(line)) | echohl None
            call s:oTreeNode.TreeLog(prefix . line . '//' . s:GetInstPortDir(inst,s:GetPortName(line)))
        elseif line =~ '^\s*)\s*;'
            let in_inst = 0
            let inst = ''
            "echo prefix . line
            call s:oTreeNode.TreeLog(prefix . line)
        elseif line =~ '^\s*\<endmodule\>'
            "echo prefix . line
            call s:oTreeNode.TreeLog(prefix . line)
            break
        endif
        let line_index = line_index + 1
   endwhile
endfunction "}}}2

function s:GetInstLineNum(lnum) "{{{2
    let line_index = a:lnum
    while line_index >= 1
        let line_index = s:SkipCommentLine(1,line_index)
        if line_index == -1
            break
        endif
        let line = getline(line_index)
        "if line =~ '\<autoinst\>'
        if line =~ '\<autoinst\>' || line =~ '^\s*' . '`\?' . s:not_keywords_pattern . '\s*' . '\w\+'
            return line_index
        endif
        let line_index = line_index - 1
    endwhile
endfunction "}}}2

function s:GetInstName(line) "{{{2
"get rtl.module_name
    let start = match(a:line,'\w')
    let end = match(a:line,'\w\s')
    return strpart(a:line, start, end-start+1)
endfunction "}}}2

function s:GetInstNameAdvance(lnum) "{{{2
"get rtl.module_name
" advance search backwards from autoinst keywords line
" stop condition: reach ); or autoinst; or module define line
    let line_index = a:lnum

    let wait_autoinst_pair = 0
    let wait_inst_name = 0
    let wait_module_name = 0

    let check_autoinst_pair = 0
    let module_name = ''
    let inst_name = ''
    let result = 1

    while line_index >= 1
        let line_index = s:SkipCommentLine(1,line_index)
        let line = getline(line_index)
        let line = substitute(line,'//.*','','')        "is it '\/\/.*' ??? but repeat work of SkipCommentLine
        let line = substitute(line,'\s*$','','')

        if wait_autoinst_pair == 1 || wait_inst_name == 1 || wait_module_name == 1
            if line =~ '\<autoinst\>' || line =~ ');' || line =~ '^\s*module'
                break
            endif
        endif

        "search up to /*autoinst
        if line =~ '/\*\s*\<autoinst\>'
            let result = match(line, '(\s*/\*\s*\<autoinst\>')
            "( /*autoinst
            if result != -1
                let check_autoinst_pair = 1
                let line = substitute(line, '\s*(\s*/\*\s*\<autoinst\>.*$', '', '')
            "/*autoinst
            else
                let wait_autoinst_pair = 1
                let line = substitute(line, '\s*/\*\s*\<autoinst\>.*$', '', '')
            endif
        endif
        "echo line
        "echo line_index .': wait_pair:' . wait_autoinst_pair . '  check_pari: ' . check_autoinst_pair . "  wait_inst: " . wait_inst_name . "  wait_module:" . wait_module_name . " module_name: " . module_name  . "  inst_name: " . inst_name

        if wait_autoinst_pair == 1
            if line =~ '[^(]\s*$' && line != '^\s*$'
                echohl ErrorMsg | echo "() pair not-match in autoinst, line: ".line_index  | echohl None
                return ['', '']
            endif
            let result = match(line, '(\s*$')
            if result != -1
                let wait_autoinst_pair = 0
                let check_autoinst_pair = 1
                let line = substitute(line, '\s*(\s*$', '', '')
            endif
        endif
        "echo line . " check_pair: " . check_autoinst_pair . "  result: " . result
        "echo 'wait_pair:' . wait_autoinst_pair . '  check_pari: ' . check_autoinst_pair . "  wait_inst: " . wait_inst_name . "  wait_module:" . wait_module_name
        
        if check_autoinst_pair == 1
            let check_autoinst_pair = 0
            " start check autoinst () pair
            call cursor(l:line_index,result+1) " cursor to autoinst line '('
            "call search('(','b')
            let [tmp1,tmp2] = searchpairpos("\(", "", "\)")
            if tmp1 == 0 && tmp2 == 0
                echohl ErrorMsg | echo "() pair not-match in autoinst, line: ".line_index  | echohl None
                return ['', '']
            endif
            let [tmp1,tmp2] = searchpairpos("\(", "", "\)", 'b')
            let wait_inst_name = 1
        endif

        "echo line
        "echo 'wait_pair:' . wait_autoinst_pair . '  check_pari: ' . check_autoinst_pair . "  wait_inst: " . wait_inst_name . "  wait_module:" . wait_module_name
        if wait_inst_name == 1
            let result = match(line, '\w\+$')
            if result != -1
                let wait_inst_name = 0
                let wait_module_name = 1
                let inst_name = matchstr(line,'\w\+$')
                let line = substitute(line, '\s*\w\+$', '', '')
            endif
        endif

        "echo line
        "echo 'wait_pair:' . wait_autoinst_pair . '  check_pari: ' . check_autoinst_pair . "  wait_inst: " . wait_inst_name . "  wait_module:" . wait_module_name
        if wait_module_name == 1
            while 1
                "echo 'debug---+ ' . line
                let result = match(line, '\w\+$')
                if result != -1
                    let wait_module_name = 0
                    let module_name = matchstr(line,'\w\+$')
                    break
                " skip parameter instance is to be done.
                elseif line =~ ')\s*$'
                    let result = match(line, ')\s*$')
                    call cursor(l:line_index,result+1) " cursor to autoinst line ')'
                    let [tmp1,tmp2] = searchpairpos("\(", "", "\)", 'b')
                    if tmp1 == 0 && tmp2 == 0
                        echohl ErrorMsg | echo "() parameter pair not-match in autoinst, line: ".line_index  | echohl None
                        return ['', '']
                    endif
                    let line_index = tmp1
                    let line = getline(tmp1)
                    "echo '------ parameter para line: ' . line
                    let line = strpart(line, 0, tmp2)
                    let line = substitute(line, '\s*#\?\s*(', '', '')
                    continue
                else
                    break
                endif
            endwhile
        endif

        if module_name != ''
            break
        endif

        let line_index = line_index - 1
    endwhile

    "if module_name == '' || inst_name == ''
    "    echohl ErrorMsg | echo "autoinst may be error, line: ".line_index  | echohl None
    "endif

    "echo "module: " . module_name . ",  instance: " . inst_name
    return [module_name, inst_name]
endfunction "}}}2

function s:GetInstName2(line) "{{{2
"get rtl.module.instance_name
    let name = matchstr(a:line,'\w\+\s*(\s*\/')
    return substitute(name, '\s*(\s*\/', '','')
endfunction "}}}2

function s:GetPortName(line) "{{{2
    "let start = match(a:line,'\w')
    let start = match(a:line,'\w\+\s*(')
    let end = match(a:line,'\w\s*(')
    return strpart(a:line, start, end-start+1)
endfunction "}}}2

function s:GetInstPortDir(inst,port) "{{{2
    let inst_file = s:GetInstFileName(a:inst)
    if inst_file != ''
        let lines = s:Filter(readfile(inst_file))
        for line in lines
            "if line =~ '^\s*\(\<input\>\|\<output\>\|\<inout\>\)\s*\(\<wire\>\|\<reg\>\)*\s*\(\[.*:.*\]\)*\s*' . '\<' . a:port . '\>'
            if line =~ '^\s*' . s:VlogTypePorts . '\s*' . s:VlogTypeDatas . '*' . '\s*' . '\(\[.*:.*\]\)*' . '\s*' . '\<' . a:port . '\>'
                let line = substitute(line,'^\s*','','')
                return substitute(line,'ut\s\+.*$','ut','')
            endif
        endfor
    endif
    return ''
endfunction "}}}2

function s:GetInstFileName(inst) "{{{2
    let inst_file = ''
    let file_readable = 0
    if filereadable('tags')
        let lines = readfile('tags')
        for line in lines
            if line =~ '^' . '\<' . a:inst . '\>'
                let line = substitute(line, '^\w\+\t', "", "")
                let inst_file = substitute(line, '\.v.*$', '.v', "")
                if filereadable(inst_file)
                    let file_readable = 1
                endif
                break
            endif
        endfor
    endif
    if file_readable == 0
        let inst_file = findfile(a:inst . ".v", "./")
        if filereadable(inst_file)
            call system("ctags -a " . inst_file)
            call system("sed -i '/[prn]$/d' tags")
            let file_readable = 1
        endif
    endif
    if file_readable
        return inst_file
    else
        return ''
    endif
endfunction "}}}2

"---------------------------------------------------------------
"        Skip Comment Line 
"---------------------------------------------------------------
function s:SkipCommentLine(mode,line_idx) "{{{2
"---------------------------------------------------------------
"input: 
"   mode: 0 - code search dir is up to down(idx to end), 
"         1 - code search dir is down to up(idx to 1)
"   line_idx: start line index
"
"output:
"   return nearest no comment line index
"must run before comment line
"---------------------------------------------------------------
    let in_comment_pair = 0

    if a:mode == 0
        for idx in range(a:line_idx,line("$"),1)
            let line = getline(idx)
            "/* symbol at top of the line
            if line =~ '^\s*/\*' && line !~ '\*/'
                let in_comment_pair = 1
                continue
            "*/ symbol at end of the line
            elseif line !~ '/\*' && line =~ '\*/\s*$'
                let in_comment_pair = 0
                continue
            "in comment pair /* ... */
            elseif in_comment_pair == 1
                continue
            "no think about comment pair /* ... */ in single line, it may be autocmd

            "signal line comment must use //
            "comment line //
            elseif line =~ '^\s*\/\/'
                continue
            else
                return idx
            endif
        endfor
    else
        for idx in range(a:line_idx,1,-1)
            let line = getline(idx)
            "*/ symbol at end of the line
            if line !~ '/\*' && line =~ '\*/\s*$'
                let in_comment_pair = 1
                continue
            "/* symbol at top of the line
            elseif line =~ '^\s*/\*' && line !~ '\*/'
                let in_comment_pair = 0
                continue
            "in comment pair /* ... */
            elseif in_comment_pair == 1
                continue
            "comment line //
            elseif line =~ '^\s*\/\/'
                continue
            else
                return idx
            endif
        endfor
    endif
    return -1
endfunction "}}}2

function s:SkipPairCommentLine_array(mode,lines,line_idx) "{{{2
    "mode: 0 - code search dir is up to down, 1 - is down to up
    "return no comment line index
    "must run before comment line
    let in_comment_pair = 0

    if a:mode == 0
        for idx in range(a:line_idx,len(a:lines),1)
            let line = a:lines[idx-1]
            "/* symbol at top of the line
            if line =~ '^\s*/\*' && line !~ '\*/'
                let in_comment_pair = 1
                continue
            "*/ symbol at end of the line
            elseif line !~ '/\*' && line =~ '\*/\s*$'
                let in_comment_pair = 0
                continue
            "in comment pair /* ... */
            elseif in_comment_pair == 1
                continue
            "no think about comment pair /* ... */ in signal line, it may be autocmd
            "signal line comment must use //
            else
                return idx
            endif
        endfor
    else
        for idx in range(a:line_idx,1,-1)
            let line = a:lines[idx-1]
            "*/ symbol at end of the line
            if line !~ '/\*' && line =~ '\*/\s*$'
                let in_comment_pair = 1
                continue
            "/* symbol at top of the line
            elseif line =~ '^\s*/\*' && line !~ '\*/'
                let in_comment_pair = 0
                continue
            "in comment pair /* ... */
            elseif in_comment_pair == 1
                continue
            else
                return idx
            endif
        endfor
    endif
    return -1
endfunction "}}}2

"---------------------------------------------------------------
"        Update Current Buffer
"---------------------------------------------------------------
function s:UpdateBuf(new_lines,goto_lnum) "{{{2
   if len(a:new_lines) < line("$")
      for line_index in range(1, line("$"), 1)
         if line_index > len(a:new_lines)
            "orgial code
            "call setline(line_index, "")
            "modify by zhangg @2012.03.17
            "del null line
            call cursor(line_index,0)
            let del_sum = line("$") - len(a:new_lines)
            execute "normal " . del_sum . "dd"
            break
         else
            call setline(line_index, a:new_lines[line_index-1])
         endif
      endfor
   else
      for line_index in range(1, len(a:new_lines), 1)
         call setline(line_index, a:new_lines[line_index-1])
      endfor
   endif
   if a:goto_lnum != -1
       call cursor(a:goto_lnum,0)
   endif
   execute "normal zz"
endfunction "}}}2

"---------------------------------------------------------------
"        Get Instance Name and its Path from Comments
"---------------------------------------------------------------
function s:GetInsts() "{{{2
    let insts = {}
    let inst_file_not_exist = 0

    let line_index = 1
    "for line in s:Filter(getline(1, line("$")))
    while line_index <= line("$")
        let line_index = s:SkipCommentLine(0,line_index)
        let line = getline(line_index)
        if line =~ '\<autoinst\>'
            "let inst = s:GetInstName(line)
            let [inst, tmp] = s:GetInstNameAdvance(line_index)
            let inst_file = s:GetInstFileName(inst)
            if inst_file == ''
                echohl ErrorMsg | echo "file: tags not exist or need update! inst: " . inst . " is not in tags, or file:" .inst. ".v is not exist in cur dir(" .$PWD. "/)"  | echohl None
                let inst_file_not_exist = 1
            else
                call extend(insts, {inst : inst_file})
            endif
        endif
        let line_index = line_index + 1
   "endfor
   endwhile
   if inst_file_not_exist
       let insts = {}
   endif
   return insts
endfunction "}}}2

function s:GetInst() "{{{2
    let insts = {}
    let line = getline(".")
    let line_index = line(".")
        if line =~ '\<autoinst\>'
            "let inst = s:GetInstName(line)
            let [inst, tmp] = s:GetInstNameAdvance(line_index)
            let inst_file = s:GetInstFileName(inst)
            if inst_file == ''
                echohl ErrorMsg | echo "file: tags not exist or need update! inst: " . inst . " is not in tags, or file:" .inst. ".v is not exist in cur dir(" .$PWD. "/)"  | echohl None
            else
                call extend(insts, {inst : inst_file})
            endif
        endif
   return insts
endfunction "}}}2

"---------------------------------------------------------------
"       Remove Comments and Functions from Current Buffer
"---------------------------------------------------------------
function s:Filter(lines) "{{{2
   let aft_filter = []
   let line_index = 1
   while line_index <= len(a:lines)
      let line = a:lines[line_index-1]
      let line = substitute(line, '//.*$', "", "")
      "match /*, the symbol should location at top of the line
      if line =~ '^.*/\*' && line !~ '\*/.*$'
         let line = substitute(line, '/\*.*$', "", "")
         call add(aft_filter, line)
         let line_index = line_index + 1
         let line = a:lines[line_index-1]
         "match */, the symbol should location at end of the line
         while line !~ '\*/.*$'
            let line_index = line_index + 1
            let line = a:lines[line_index-1]
         endwhile
      elseif line =~ '^\s*\<function\>'
         let line_index = line_index + 1
         let line = a:lines[line_index-1]
         while line !~ '^\s*\<endfunction\>'
            let line_index = line_index + 1
            let line = a:lines[line_index-1]
         endwhile
      "match endmodule, and break Filter
      elseif line =~ '^\s*\<endmodule\>'
         call add(aft_filter, line)
         break
      else
         "match /* and */, the symbol /* should location at top of the line
         if line !~ '^.*/\*'
            let line = substitute(line, '^.*\*/', "", "")
         endif
         let line = substitute(line, '^\s*\<endfunction\>', "", "")
         let line_index = line_index + 1
         if line != ""
            call add(aft_filter, line)
         endif
      endif
   endwhile
   return aft_filter
endfunction "}}}2

"---------------------------------------------------------------
"       Get Sequence IO
"---------------------------------------------------------------
function s:Seq2String(seq_num) "{{{2
    if a:seq_num < 10
        let seq = '0000' . a:seq_num
    elseif a:seq_num < 100
        let seq = '000' . a:seq_num
    elseif a:seq_num < 1000
        let seq = '00' . a:seq_num
    elseif a:seq_num < 10000
        let seq = '0' . a:seq_num
    else
        let seq = a:seq_num
    endif
    return seq
endfunction "}}}2

function s:GetSeqIO(lines, io_seq_dict) "{{{2
" use for AutoInst, AutoDef
" io_seq_dict type dict
" key is seq 
    let line_index = 1
    let io_seq = 0
    let tmp_dict = {}
    let max_len = []
    let io_wire = {}
    let sig = ''
    let have_port = 0
    let have_module = 0
    while line_index <= len(a:lines)
        "1 step,skip comment
        let line_index = s:SkipPairCommentLine_array(0,a:lines,line_index)
        if line_index == -1
            break
        endif
        "2 step get define
        let line = a:lines[line_index-1]
        if line !~ '^\s*\/\/'
            let line = substitute(line,'//.*$','','')
        endif
        let line = substitute(line,'^\s*,','','')
        if line =~ '^\s*module'
            let have_module = 1
        endif
        if have_module == 0
            let line_index = line_index + 1
            continue
        endif

        if line =~ ');' && len(tmp_dict) > 0 && have_port == 0
            let io_seq = 0
            let tmp_dict = {}
        endif

        " `ifdef `ifndef
        " single comment line
        " null line
        if  (line =~ '^\s*\`\(if\|else\|endif\)') || (line =~ '^\s*\/\/' && line !~ '^\s*\/\/\s*{{{') || (line =~ '^\s*$')
            " cur line is null & last tmp_dict is null line, skip it
            if io_seq > 0
                let seq = s:Seq2String(io_seq-1)
                if has_key(tmp_dict,seq)
                    let value = tmp_dict[seq]
                    if value[1] =~ 'keep' && value[4] =~ '^\s*$' && line =~ '^\s*$'
                        let line_index = line_index + 1
                        continue
                    endif
                endif
            endif

            let seq = s:Seq2String(io_seq)
                "        0     1      2           3   4    5           6      7
                "       [width,type,  has_defined,seq,line,signal_name,io_dir,last_port]
            let value = ['c0', 'keep',0          ,seq,line,''         ,''    ,0]
            call extend(tmp_dict, {seq : value})
            let io_seq = io_seq + 1

        " io_wire or io_reg
        elseif line =~ '^\s*' . s:VlogTypePorts
            let io_seq = s:ExtendIoFromLine2(tmp_dict,line,io_seq)
            let have_port = 1
        elseif line =~ '^\s*\<always\>' || line =~ '^\s*\<assign\>' || line =~ '^\s*\<endmodule\>' || line =~ '\<autodef\>'
            break
        endif

        let line_index = line_index + 1
    endwhile

    " set last port flag
    let io_seq = len(tmp_dict)
    while 1
        let io_seq = io_seq - 1
        let seq = s:Seq2String(io_seq)
        if has_key(tmp_dict, seq)
"          0     1       2       3    4      5          6       7
"       [width,type,has_defined,seq,line,signal_name,io_dir,last_port]
            let value = tmp_dict[seq]
            if (value[1] !~ 'keep')
                let value[7] = 1
                call remove(tmp_dict, seq)
                call extend(tmp_dict, {seq : value})
                break
            endif
        endif
    endwhile

    " remove last null lines
    let io_seq = len(tmp_dict)
    while 1
        let io_seq = io_seq - 1
        let seq = s:Seq2String(io_seq)
        if has_key(tmp_dict, seq)
"          0     1       2       3    4      5          6       7
"       [width,type,has_defined,seq,line,signal_name,io_dir,last_port]
            let value = tmp_dict[seq]
            if (value[1] !~ 'keep') || (value[4] !~ '^\s*$')
                break
            else
                call remove(tmp_dict, seq)
            endif
        endif
    endwhile

    " remove first null lines
    let io_seq = 0
    while 1
        let seq = s:Seq2String(io_seq)
        let io_seq = io_seq + 1
        if has_key(tmp_dict, seq)
"          0     1       2       3    4      5          6       7
"       [width,type,has_defined,seq,line,signal_name,io_dir,last_port]
            let value = tmp_dict[seq]
            if (value[1] !~ 'keep') || (value[4] !~ '^\s*$')
                break
            else
                call remove(tmp_dict, seq)
            endif
        endif
    endwhile

    " cp tmp_dict to a:io_seq_dict
    for key in sort(keys(tmp_dict))
        call extend(a:io_seq_dict, {key : tmp_dict[key]})
    endfor
endfunction "}}}2

function s:ExtendIoFromLine(dict,in_line,init_seq) "{{{2
    "line must be input or output define line
    let io_dir = matchstr(a:in_line,'\w\+')
    "let line = substitute(a:in_line,'^\s*\(\<input\>\|\<output\>\|\<inout\>\)\s*','','')
    let line = substitute(a:in_line,'^\s*' . s:VlogTypePorts . '\s*','','')
    "use c0 replace 0

    let signal_name = ''
    let width = 'c0'
    let type = 'io_wire'
    let has_defined = 0
    let seq = ''
    let line0 = ''

    if line =~ '^\<wire\>'
        let has_defined = 1
        let line = substitute(line,'^\<wire\>\s*','','')
    endif
    if line =~ '^\<reg\>'
        let has_defined = 1
        let type = 'io_reg'
        let line = substitute(line,'^\<reg\>\s*','','')
    endif

    if line =~ '^\['
        let width = matchstr(line,'^\[.*:')
        let line = substitute(line,'^\[.*:.*\]\s*','','')
        let width = substitute(width,'^\[\s*','','')
        let width = substitute(width,'\s*:$','','')
    endif

    let signal_name = matchstr(line,'\w\+')
    let seq = s:Seq2String(a:init_seq)
    let value = []
    call add(value,width)       " 0
    call add(value,type)        " 1
    call add(value,has_defined) " 2
    call add(value,seq)         " 3
    call add(value,line0)       " 4
    call add(value,'')          " 5
    call add(value,io_dir)      " 6
    call add(value,0)           " 7

    call extend(a:dict, {signal_name : value})
    return a:init_seq + 1
endfunction "}}}2

function s:ExtendIoFromLine2(dict,in_line,init_seq) "{{{2
    "line must be input or output define line
    let io_dir = matchstr(a:in_line,'\w\+')
    "let line = substitute(a:in_line,'^\s*\(\<input\>\|\<output\>\|\<inout\>\)\s*','','')
    let line = substitute(a:in_line,'^\s*' . s:VlogTypePorts . '\s*','','')
    "use c0 replace 0

    let signal_name = ''
    let width = 'c0'
    let type = 'io_wire'
    let has_defined = 0
    let seq = ''
    let line0 = ''

    if line =~ '^\<wire\>'
        let has_defined = 1
        let line = substitute(line,'^\<wire\>\s*','','')
    endif
    if line =~ '^\<reg\>'
        let has_defined = 1
        let type = 'io_reg'
        let line = substitute(line,'^\<reg\>\s*','','')
    endif

    if line =~ '\<signed\>\s*\|\<unsigned\>\s*'
        let line = substitute(line,'\<signed\>\s*\|\<unsigned\>\s*','','')
    endif

    let width1 = ''
    if line =~ '^\['
        let width1 = matchstr(line,'^\[\zs.*\ze:')
        let width1 = substitute(width1,'^\s*','','')
        let width1 = substitute(width1,'\s*$','','')
        let width2 = matchstr(line,'^\[.*:\zs.*\ze\]')
        let width2 = substitute(width2,'^\s*','','')
        let width2 = substitute(width2,'\s*$','','')
        let width = abs(str2nr(width2)-str2nr(width1))
        let line = substitute(line,'^\[.*:.*\]\s*','','')
    endif

    let signal_name = matchstr(line,'\w\+')
    let seq = s:Seq2String(a:init_seq)
    "            0     1    2          3   4      5         6      7
    "           [width,type,has_defined,seq,line, signal_name,io_dir,last_port]
    let value = [width,type,has_defined,seq,line0,signal_name,io_dir,0]
    call extend(a:dict, {seq : value})
    return a:init_seq + 1
endfunction "}}}2

"---------------------------------------------------------------
"       
"---------------------------------------------------------------
function s:ConvertSeqIO(io_seq_dict,io_dict) "{{{2
    for seq in sort(keys(a:io_seq_dict))
        let value = a:io_seq_dict[seq]
        if value[1] !~ 'keep'
            call extend(a:io_dict, {value[5] : value})
        endif
    endfor
endfunction "}}}2

function s:ConvertIO(io_dict,io_seq_dict) "{{{2
    for tmp in sort(keys(a:io_dict))
        let value = a:io_dict[tmp]
        if value[1] !~ 'keep'
            call extend(a:io_seq_dict, {value[3] : value})
        endif
    endfor
endfunction "}}}2

function s:ExtendUsrdefFromLine(dict,in_line,init_seq) "{{{2
    "line must be input or output define line
    "only care signal_name, width, init_seq, line
    "type and has_defined is no cared
    let line0 = a:in_line
    "let line = substitute(a:in_line,'^\s*\(\<wire\>\|\<reg\>\)\s\+','','')
    let line = substitute(a:in_line,'^\s*' . s:VlogTypeDatas . '\s\+','','')

    let signal_name = ''
    let width = 'c0'
    let type = 'usrdef'
    let has_defined = ''
    let seq = ''

    if line =~ '^\['
        let width = matchstr(line,'^\[.*:')
        let line = substitute(line,'^\[.*:.*\]\s\+','','')
        let width = substitute(width,'^\[\s*','','')
        let width = substitute(width,'\s*:$','','')
    endif

    let signal_name = matchstr(line,'\w\+')
    if has_key(a:dict,signal_name)
        return a:init_seq
    endif
    let seq = s:Seq2String(a:init_seq)
    let value = []
    call add(value,width)       " 0
    call add(value,type)        " 1
    call add(value,has_defined) " 2
    call add(value,seq)         " 3
    call add(value,line0)       " 4
    call add(value,'')          " 5
    call add(value,'')          " 6

    call extend(a:dict, {signal_name : value})
    return a:init_seq + 1
endfunction "}}}2

function s:ExtendFromSide(dict,side,type) "{{{2
    let signal_name = ''
    let width = ''
    let has_defined = ''
    let init_seq = ''
    let line0 = ''

    if len(a:side) == 1
        "only use in left side is such as x[.*], only store it's type
        let signal_name = a:side[0]
        if has_key(a:dict,signal_name)
            let value = a:dict[signal_name]
            if value[1] == 'io_wire'
                if a:type == 'freg' || a:type == 'creg'
                    let value[1] = 'io_reg'
                    let a:dict[signal_name] = value
                endif
            endif
        else
            let value = []
            call add(value,width)       " 0
            call add(value,a:type)      " 1
            call add(value,has_defined) " 2
            call add(value,init_seq)    " 3
            call add(value,line0)       " 4
            call add(value,'')          " 5
            call add(value,'')          " 6

            call extend(a:dict, {signal_name : value})
        endif
    elseif len(a:side) == 2
        "store it's width info
        if a:side[1] =~ '[a-zA-Z]'
            let width = a:side[1].'-1'
        else
            let width = str2nr(a:side[1])-1
            if width == 0
                let width = 'c0'
            endif
        endif
        let signal_name = a:side[0]
        if has_key(a:dict,signal_name)
            let value = a:dict[signal_name]
            if value[0] == ''
                let value[0] = width
            endif
            if value[1] == 'io_wire'
                if a:type == 'freg' || a:type == 'creg'
                    let value[1] = 'io_reg'
                endif
            endif
            let a:dict[signal_name] = value
        else
            let value = []
            call add(value,width)       " 0
            call add(value,a:type)      " 1
            call add(value,has_defined) " 2
            call add(value,init_seq)    " 3
            call add(value,line0)       " 4
            call add(value,'')          " 5
            call add(value,'')          " 6

            call extend(a:dict, {signal_name : value})
        endif
    elseif len(a:side) == 3
        if a:side[2] == 'link'
            "only store it's type
            let signal_name = a:side[0]

            if has_key(a:dict,signal_name)
                let value = a:dict[signal_name]
                if value[1] == 'io_wire'
                    if a:type == 'freg' || a:type == 'creg'
                        let value[1] = 'io_reg'
                        let a:dict[signal_name] = value
                    endif
                endif
            else
                let value = []
                call add(value,width)       " 0
                call add(value,a:type)      " 1
                call add(value,has_defined) " 2
                call add(value,init_seq)    " 3
                call add(value,line0)       " 4
                call add(value,'')          " 5
                call add(value,'')          " 6

                call extend(a:dict, {signal_name : value})
            endif
        endif
    endif
endfunction "}}}2

function s:ExtendInstWireFromLine(dict,in_line,inst_io) "{{{2
    let line = a:in_line
    let inst_port = matchstr(line,'\w\+')
    let line = substitute(line,'\w\+','','')
    " if inst_wire is `define or constant value M'hN,  return
    if line =~ "\'" || line =~ '\`'
        return
    endif
    let inst_wire = matchstr(line,'\w\+')

    let port_value = a:inst_io[inst_port]
    let port_width = port_value[0]

    "if port_width is parameter
    if port_width !~ 'c0' && port_width =~ '[a-zA-Z]' && port_width !~ '\`'
        let port_width = ''
        "return
    endif

    if has_key(a:dict,inst_wire)
        let sig_value = a:dict[inst_wire]
        if sig_value[0] == ''
            let sig_value[0] = port_width
            let a:dict[inst_wire] = sig_value

        endif
    else
        let signal_name = inst_wire
        let width = port_width
        let type = 'inst_wire'
        let has_defined = 0
        let seq = ''
        let line0 = ''

        let value = []
        call add(value,width)       " 0
        call add(value,type)        " 1
        call add(value,has_defined) " 2
        call add(value,seq)         " 3
        call add(value,line0)       " 4
        call add(value,'')          " 5
        call add(value,'')          " 6

        call extend(a:dict, {signal_name : value})
    endif
endfunction "}}}2

function s:GetSpecAutoParaLine(state) "{{{2
    for line in getline(1, line("$"))
        if line =~ '/\*\<autopara\>\s*' . '\<' . a:state . '\>'
            return line
        end
    endfor
    return ''
endfunction "}}}2

function s:GetAutoParas(autoparaline) "{{{2
    "it is autopara define line
    let paras_list = []
    let line = matchstr(a:autoparaline,'(.*)')
    let line = substitute(line,'(','','')
    let line = substitute(line,')','','')
    let paras = split(line,',')
    let default_value = 0
    let use_value = ''
    for para in paras
        "get para value
        let cur_value = matchstr(para,'=.*$')
        let cur_value = substitute(cur_value,'=\s*','','')
        let use_value = cur_value
        "use default_value
        if cur_value == ''
            let use_value = default_value
            "update default_value
            if default_value =~ '\<[a-zA-Z]\+\>'
                let add_value = matchstr(default_value,'\<\d\+\>')
                let add_value = str2nr(add_value) + 1
                let default_value = substitute(default_value,'\<\d\+\>','','')
                let default_value = default_value . add_value
            else
                let default_value = default_value + 1
            endif
        "is define or other parameter value
        elseif cur_value =~ '\<[a-zA-Z]\+\>'
            let default_value = cur_value . '+1'
        "is number
        else
            let default_value = str2nr(cur_value) + 1
        endif

        let para = substitute(para,'^\s*','','')
        let para = substitute(para,'\s*=.*$','','')
        let para = substitute(para,'\s*$','','')
        call extend(paras_list,[{para : use_value}])
    endfor
    return paras_list
endfunction "}}}2

function s:GetAllParas() "{{{2
    let allparas = {}
    let line_index = 1
    while line_index <= line("$")
        "1 step, skip autopara
        let line = getline(line_index)
        if line == "// Define parameter here"
            let line_index = line_index + 1
            let line = getline(line_index)
            while line !~ "// End of automatic parameter" && line_index < line("$")
                let line_index = line_index + 1
                let line = getline(line_index)
            endwhile
            let line_index = line_index + 1
        endif
        "2 step,skip comment
        let line_index = s:SkipCommentLine(0,line_index)
        if line_index == -1
            break
        endif
        "3 step match parameter
        let line = getline(line_index)
        if line =~ '^\s*\(\<parameter\>\|\<localparam\>\)\s*'
            let line = substitute(line,'^\s*\(\<parameter\>\|\<localparam\>\)\s*','','')
            call extend(allparas, {matchstr(line,'\w\+') : ''})
        elseif line =~ '/\*\<autopara\>'
            let paras = s:GetAutoParas(line)
            for para in paras
                for key in keys(para)
                    call extend(allparas, {key : ''})
                endfor
            endfor
        elseif line =~ '^\s*\<endmodule\>'
            break
        endif
        let line_index = line_index + 1
    endwhile
    return allparas
endfunction "}}}2

function s:GetAllDefs() "{{{2
    let alldefs = {}
    let line_index = 1
    while line_index <= line("$")
        "1 step,skip comment
        let line_index = s:SkipCommentLine(0,line_index)
        if line_index == -1
            break
        endif
        "2 step match define
        let line = getline(line_index)
        if line =~ '^\s*`\(\<define\>\|\<ifdef\>\|\<ifndef\>\)\s*'
            let line = substitute(line,'^\s*`\(\<define\>\|\<ifdef\>\|\<ifndef\>\)\s*','','')
            call extend(alldefs, {matchstr(line,'\w\+') : ''})
        elseif line =~ '^\s*\<endmodule\>'
            break
        endif
        let line_index = line_index + 1
    endwhile
    return alldefs
endfunction "}}}2

function s:GetAllSignals(alldefs,allparas) "{{{2
    let allsignals = {}

    let line_index = 1
    while line_index <= line("$")
        let line = getline(line_index)
        "0 step, skip autodef off - on
        if line == "/*autodef off*/"
            let line_index = line_index + 1
            let line = getline(line_index)
            while line != "/*autodef on*/" && line_index < line("$")
                let line_index = line_index + 1
                let line = getline(line_index)
            endwhile
            let line_index = line_index + 1
        "1 step, skip autodef and autopara
        elseif line == "// Define io wire here"
            let line_index = line_index + 1
            let line = getline(line_index)
            while line !~ "// End of automatic define" && line_index < line("$")
                let line_index = line_index + 1
                let line = getline(line_index)
            endwhile
            let line_index = line_index + 1
        elseif line == "// Define parameter here"
            let line_index = line_index + 1
            let line = getline(line_index)
            while line !~ "// End of automatic parameter" && line_index < line("$")
                let line_index = line_index + 1
                let line = getline(line_index)
            endwhile
            let line_index = line_index + 1
        endif
        "2 step, skip comment
        let line_index = s:SkipCommentLine(0,line_index)
        if line_index == -1
            break
        endif

        "3 step, prepare line
        let line = getline(line_index)
        " autocmd
        if line =~ '/\*\s*\(\<autoarg\>\|\<autopara\>\|\<autodef\>\|\<autoinst\>\|\<autofsm\>\)'
            let line_index = line_index + 1
            continue
        endif
        "del comment /* ... */, this line is for comment
        let line = substitute(line, '/\*.*\*/', "", "")
        "del comment at end of the line
        let line = substitute(line, '//.*$', "", "")

        "4 step, match start
        " `define `if(n)def `else `elseif `elsif `endif
        if line =~ '^\s*\`\(\<define\>\|\<ifdef\>\|\<ifndef\>\|\<else\>\|\<elseif\>\|\<elsif\>\|\<endif\>\)'
        elseif line =~ '^\s*\`timescale'
        elseif line =~ '^\s*\<endmodule\>'
            break
        else
            while 1
                let signal = matchstr(line,"[`\.']\\?\\w\\+")
                if signal == ''
                    break
                endif
                let line = substitute(line,"[`\.']\\?\\w\\+",'','')
                "it is use define or number
                if signal =~ '`' || signal =~ '\.' || signal =~ "'[hbd]" || signal =~ '\<\d\+\>'
                    continue
                endif
                "key words
                "if signal !~ '\(\<if\>\|\<else\>\|\<begin\>\|\<end\>\|\<case\>\|\<endcase\>\|\<default\>\|\<posedge\>\|\<or\>\|\<negedge\>\|\<always\>\|\<assign\>\|\<input\>\|\<output\>\|\<inout\>\|\<wire\>\|\<reg\>\|\<parameter\>\|\<localparam\>\)'
                if signal !~ s:VlogKeyWords
                    if has_key(a:allparas, signal)
                    elseif has_key(a:alldefs, signal)
                    elseif has_key(allsignals, signal) == 0
                        call extend(allsignals,{signal : ''})
                    endif
                endif
            endwhile
        endif
        let line_index = line_index + 1
    endwhile
    return allsignals
endfunction "}}}2

function s:GetAssignSide(side) "{{{2
    "left side is signal name
    "right side return signal width
    
    let result_side = []
    "get left side
    let left = a:side[0]
    if left =~ '\[.*\]'
        call add(result_side,matchstr(left,'\w\+'))
        return result_side
    endif
    let left = matchstr(left,'\w\+\s*$')
    "let left = substitute(left,'^\s*','','')
    let left = substitute(left,'\s*$','','')

    if left !~ '\W'
        "get right side
        let right = a:side[1]
        "let right = substitute(right,'#`\?\w\+\s','','')
        " for delay like #0.1
        let right = substitute(right,'#`\?\w\+\(\.\w\+\)\?\s','','')
        let right = substitute(right,'^\s*','','')
        let right = substitute(right,'\s*$','','')


        "match M'bN or match M'hN or match M'dN
        "M may be `define or parameter or number
        if right =~ '^\(`\?\w\+\|\d\+\)' . "'" . '[bhd].*'
            let right = matchstr(right,'^\(`\?\w\+\|\d\+\)')
            call add(result_side,left)
            call add(result_side,right)
        "match signal[N], N is integer number
        elseif right =~ '^\~\?\w\+\[\s*\d\+\s*\]\s*;$'
            call add(result_side,left)
            call add(result_side,1)
        "match signal[M:N], M and N is integer number
        elseif right =~ '^\~\?\w\+\[\s*\d\+\s*:\s*\d\+\s*\]\s*;$'
            let high = matchstr(right,'\d\+')
            let right = substitute(right,'\d\+','','')
            let low = matchstr(right,'\d\+')
            if str2nr(high) >= str2nr(low)
                call add(result_side,left)
                call add(result_side,1 + str2nr(high) - str2nr(low))
            endif
        "match signal or ~signal
        elseif right =~ '^\~\?\w\+\s*;$'
            let right = matchstr(right, '\w\+')
            call add(result_side,left)
            let tmp = {}
            "type is unknow ''
            call extend(tmp, {right : ''})
            call add(result_side, tmp)
            call add(result_side,'link')
        "match signal0 & signal1
        elseif right =~ '^\~\?\w\+\(\s\+[\&\|\^]\s\+\~\?\w\+\)\+\s*;$'
            call add(result_side,left)
            let tmp = {}
            "type is unknow ''
            while 1
                let s0 = matchstr(right,'\w\+')
                if s0 == ''
                    break
                else
                    let right = substitute(right,'\w\+','','')
                    call extend(tmp, {s0 : ''})
                endif
            endwhile
            call add(result_side, tmp)
            call add(result_side,'link')
        "match signal0 == signal1
        elseif right =~ '^(\?\s*\w\+\s*==\s*\w\+\s*)\?\s*;$'
            call add(result_side,left)
            call add(result_side,1)
        "match sel ? signal0 : signal1
        elseif right =~ '^\~\?\w\+\s*?\s*\w\+\s*:\s*\w\+\s*;$'
            let right = substitute(right,'\w\+','','')
            let s0 = matchstr(right,'\w\+')
            let right = substitute(right,'\w\+','','')
            let s1 = matchstr(right,'\w\+')
            if s0 =~ '[a-zA-Z]' && s1 =~ '[a-zA-Z]'
                call add(result_side,left)
                let tmp = {}
                call extend(tmp,{s0 : ''})
                call extend(tmp,{s1 : ''})
                call add(result_side, tmp)
                call add(result_side,'link')
            else
                call add(result_side,left)
                call add(result_side, {})
                call add(result_side,'link')
            endif
        "return null link for get it's type
        else
            call add(result_side,left)
            call add(result_side, {})
            call add(result_side,'link')
        endif
    endif
    return result_side
endfunction "}}}2

function s:UpdateLinkDict(link_dict,allparas,key,in_dict) "{{{2
" link_dict:
"   {
"       signal_name :
"       {
"           {siga : ''},
"           {sigb : ''},
"           ...
"           {sign : ''}
"       }
"   }
    let tmp_dict = {}
    if has_key(a:link_dict,a:key)
        let tmp_dict = a:link_dict[a:key]
    endif

    for tmp in keys(a:in_dict)
        if has_key(a:allparas,tmp)
            continue
        endif
        if has_key(tmp_dict,tmp) == 0
            call extend(tmp_dict, {tmp : ''})
        endif
    endfor
    "update link_dict
    let a:link_dict[a:key] =  tmp_dict
endfunction "}}}2

function s:GroupLinkDict(link_dict) "{{{2
    let new_link_dict = copy(a:link_dict)

    "speed
    let removed = {}
    let tmp_link_dict0 = copy(a:link_dict)
    let tmp_link_dict2 = copy(a:link_dict)
    for key in keys(tmp_link_dict0)
        if has_key(removed,key)
            continue
        endif
        let tmp_link_dict1 = copy(tmp_link_dict2)
        call remove(tmp_link_dict1,key)
        for tmp_key in keys(tmp_link_dict1)
            let tmp_dict = tmp_link_dict1[tmp_key]
            let break_for = 0
            for tmp in keys(tmp_dict)
                if key == tmp
                    let break_for = 1
                    call s:MvLinkDict(new_link_dict,key,tmp_key)
                    call remove(tmp_link_dict2,tmp_key)
                    call extend(removed,{tmp_key : ''})
                endif
                if break_for
                    break
                endif
            endfor
            "continue search tmp_key
        endfor
    endfor

    "slow
    let removed = {}
    let tmp_link_dict0 = copy(new_link_dict)
    let tmp_link_dict2 = copy(new_link_dict)
    for key in keys(tmp_link_dict0)
        if has_key(removed,key)
            continue
        endif
        let tmp_link_dict1 = copy(tmp_link_dict2)
        call remove(tmp_link_dict1,key)
        let tmp_dict2 = tmp_link_dict0[key]
        for tmp_key in keys(tmp_link_dict1)
            let tmp_dict = tmp_link_dict1[tmp_key]
            let break_for = 0
            for tmp in keys(tmp_dict)
                for tmp_key2 in keys(tmp_dict2)
                    if tmp_key2 == tmp
                        let break_for = 1
                        call s:MvLinkDict(new_link_dict,key,tmp_key)
                        call remove(tmp_link_dict2,tmp_key)
                        call extend(removed,{tmp_key : ''})
                        break
                    endif
                endfor
                if break_for
                    break
                endif
            endfor
            "continue search tmp_key
        endfor
    endfor
    return new_link_dict
endfunction "}}}2

function s:MvLinkDict(link_dict,key0,key1) "{{{2
    "function: let key0 = key0 . key1, remove(key1)

    let dict0 = a:link_dict[a:key0]
    let dict1 = a:link_dict[a:key1]

    call extend(dict0,{a:key1 : ''})
    for key in keys(dict1)
        if key == a:key0
            continue
        endif
        if has_key(dict0,key) == 0
            call extend(dict0,{key : ''})
        endif
    endfor
    let a:link_dict[a:key0] = dict0

    "remove key1
    call remove(a:link_dict,a:key1)
endfunction "}}}2

function s:UpdateDefine(unresolved,link_dict,signals) "{{{2
    if len(a:signals) && len(a:link_dict)
        for key in keys(a:link_dict)
            let hit = 0
            let hit_key = ''
            "speed
            for tmp_key in keys(a:signals)
                if key == tmp_key
                    let value = a:signals[tmp_key]
                    if value[0] != ''
                        let hit_key = tmp_key
                        let hit = 1
                        break
                    endif
                endif
            endfor
            "slow
            if hit == 0
                let tmp_dict = a:link_dict[key]
                for tmp in keys(tmp_dict)
                    for tmp_key in keys(a:signals)
                        if tmp == tmp_key
                            let value = a:signals[tmp_key]
                            if value[0] != ''
                                let hit_key = tmp_key
                                let hit = 1
                                break
                            endif
                        endif
                    endfor
                    if hit
                        break
                    endif
                endfor
            endif

            if hit
                let value = a:signals[hit_key]
                let width = value[0]
                "echo "width: " .width

                let value = a:signals[key]
                if value[0] == ''
                    let value[0] = width
                    let a:signals[key] = value
                endif

                let tmp_dict = a:link_dict[key]
                for tmp in keys(tmp_dict)
                    if has_key(a:signals,tmp)
                        let value = a:signals[tmp]
                        if value[0] == ''
                            let value[0] = width
                            let a:signals[tmp] = value
                        endif
                    endif
                endfor
            endif
        endfor
    endif
    "remove unresolved
    if len(a:signals) && len(a:unresolved)
        for sig in keys(a:signals)
            let value = a:signals[sig]
            "echo "all:  sig:" . sig . " width: " . value[0] . "  " value[1] . "  " . value[2] . "  " . value[3] . "  " . value[4]
            if value[1] == 'io_wire' || value[1] == 'io_reg' || value[1] == 'usrdef' || value[1] == 'inst_wire'
                call remove(a:unresolved,sig)
            elseif value[1] == 'freg' || value[1] == 'creg' || value[1] == 'wire'
                "echo "will remove:  sig:" . sig . " width: " . value[0] . "  " value[1] . "  " . value[2] . "  " . value[3] . "  " . value[4]
                if value[0] != ''
                    call remove(a:unresolved,sig)
                    "echo "remove " .sig
                endif
            endif
        endfor
    endif
endfunction "}}}2

function s:DivSignals(signals,io_wire,usr_def,ff_reg,comb_reg,wire,inst_wire) "{{{2
    let max_len = s:autodef_max_len
    for sig in keys(a:signals)
        let value = a:signals[sig]
        let width = value[0]
        let type = value[1]
        let has_defined = value[2]
        let seq = value[3]
        let line = value[4]

        if type == 'io_wire' || type == 'io_reg'
            if has_defined == 0
                let value[5] = sig
                call extend(a:io_wire,{seq : value})
            endif
        elseif type == 'usrdef'
            call extend(a:usr_def,{seq : value})
        elseif type == 'freg'
            if width != ''
                call extend(a:ff_reg,{sig : value})
            endif
        elseif type == 'creg'
            if width != ''
                call extend(a:comb_reg,{sig : value})
            endif
        elseif type == 'wire'
            if width != ''
                call extend(a:wire,{sig : value})
            endif
        elseif type == 'inst_wire'
            if width != ''
                call extend(a:inst_wire,{sig : value})
            endif
        endif
        "cal max_len
        if type != 'usr_def'
            if width != ''
                "first char is 'reg  ' or 'wire ' len = 5
                let tmp_len = 5
                if width != 'c0'
                    "   '[' . width . ':0]' , so will plus 4
                    let tmp_len = tmp_len + len(width) + 4
                endif
                if tmp_len > max_len
                    let max_len = tmp_len
                endif
            endif
        endif
    endfor
    return max_len
endfunction "}}}2

function s:ConvertSignals(signals,io_wire) "{{{2
    let max_len = []
    let prefix_max_len = s:autoinst_prefix_max_len
    let suffix_max_len = s:autoinst_suffix_max_len
    for sig in keys(a:signals)
        let value = a:signals[sig]
        let width = value[0]
        let type = value[1]
        let has_defined = value[2]
        let seq = value[3]
        let line = value[4]

        if type == 'io_wire' || type == 'io_reg' || type == 'keep'
            let value[5] = sig
            call extend(a:io_wire,{seq : value})

            let port_len = len(sig)
            let wire_len = len(sig)

            if width != 'c0'
                let wire_len = wire_len + len(width) + 4
            endif

            if port_len > prefix_max_len
                let prefix_max_len = port_len
            endif
            if wire_len > suffix_max_len
                let suffix_max_len = wire_len
            endif
        endif
    endfor
    call add(max_len,prefix_max_len)
    call add(max_len,suffix_max_len)
    return max_len
endfunction "}}}2

function s:GetPortMaxLen(signals) "{{{2
    let max_len = []
    let prefix_max_len = s:autoinst_prefix_max_len
    let suffix_max_len = s:autoinst_suffix_max_len
    for seq in keys(a:signals)
        let value = a:signals[seq]
        if value[1] =~ 'keep'
            continue
        endif
        let width = value[0]
        let type = value[1]
        let has_defined = value[2]
        let seq = value[3]
        let line = value[4]
        let sig = value[5]

        if type == 'io_wire' || type == 'io_reg' || type == 'keep'
            let port_len = len(sig)
            let wire_len = len(sig)

            if width != 'c0'
                let wire_len = wire_len + len(width) + 4
            endif

            if port_len > prefix_max_len
                let prefix_max_len = port_len
            endif
            if wire_len > suffix_max_len
                let suffix_max_len = wire_len
            endif
        endif
    endfor
    call add(max_len,prefix_max_len)
    call add(max_len,suffix_max_len)
    return max_len
endfunction "}}}2

function s:CalMargin(max_len, cur_len) "{{{2
   let margin = ""
   if a:max_len >= a:cur_len
       for i in range(1, a:max_len-a:cur_len+1, 1)
          let margin = margin." "
       endfor
   endif
   return margin
endfunction "}}}2

function s:CalNumLen(num) "{{{2
    let len = 1
    for i in range(1,5)
        if a:num >= pow(10,i)
            let len = len + 1
        else
            break
        endif
    endfor
    return len
endfunction "}}}2

"---------------------------------------------------------------
"        Automatic Argument Generation
"---------------------------------------------------------------
function KillAutoArg() "{{{2
   let aft_kill = []
   let line_index = 1
   let goto_lnum = -1
   let line = ""
   while line_index <= line("$") 
      let line = getline(line_index)
      "if line =~ '^\s*\<module\>\s\+\w\+\s*(/\*\<\(autoarg\|AUTOARG\)\>\*/'  " -- BUG.2017.09.16
      if line =~ '/\*\s*\<\(autoarg\|AUTOARG\)\>'
         let goto_lnum = line_index
         if line =~ ');$'
             call add(aft_kill, line)
         else
             call add(aft_kill, line.");")
             let line_index = line_index + 1
             let line = getline(line_index)
             while line !~ ');$'
                let line_index = line_index + 1
                let line = getline(line_index)
             endwhile
         endif
      else
         call add(aft_kill, line)
      endif
      let line_index = line_index + 1
   endwhile
   call s:UpdateBuf(aft_kill,goto_lnum)
endfunction "}}}2

function AutoArg() "{{{2
    let inputs = []
    let outputs = []
    let inouts = []
    let aft_arg = []
    let arg_col = 0
    call KillAutoArg()
    let lines = s:Filter(getline(1, line("$")))
    for line in lines
        if line =~ '^\s*\<input\>'
            "let line = substitute(line, '^\s*\<input\>\s*\(\<wire\>\|\<reg\>\)*\s*\(\[.*:.*\]\)*\s*', "", "")
            let line = substitute(line, '^\s*\<input\>\s*' . s:VlogTypeDatas . '*' . '\s*\(\[.*:.*\]\)*\s*', "", "")
            let line = substitute(line, '\s*;.*$', "", "")
            call add(inputs, line)
        elseif line =~ '^\s*\<output\>'
            "let line = substitute(line, '^\s*\<output\>\s*\(\<wire\>\|\<reg\>\)*\s*\(\[.*:.*\]\)*\s*', "", "")
            let line = substitute(line, '^\s*\<output\>\s*' . s:VlogTypeDatas . '*' . '\s*\(\[.*:.*\]\)*\s*', "", "")
            let line = substitute(line, '\s*;.*$', "", "")
            call add(outputs, line)
        elseif line =~ '^\s*\<inout\>'
            "let line = substitute(line, '^\s*\<inout\>\s*\(\<wire\>\|\<reg\>\)*\s*\(\[.*:.*\]\)*\s*', "", "")
            let line = substitute(line, '^\s*\<inout\>\s*' . s:VlogTypeDatas . '*' . '\s*\(\[.*:.*\]\)*\s*', "", "")
            let line = substitute(line, '\s*;.*$', "", "")
            call add(inouts, line)
        endif
    endfor
    for line in getline(1, line("$"))
        if line =~ '/\*\s*\<\(autoarg\|AUTOARG\)\>.*'
            let line = substitute(line, ').*', "", "")
            call add(aft_arg, line)
            "inputs
            if len(inputs) > 0
                call add(aft_arg, s:vlog_arg_margin."//Inputs")
                let arg_col = len(s:vlog_arg_margin)
                let signal_line = s:vlog_arg_margin
                for signal_index in range(len(inputs)-1)
                    if arg_col > s:vlog_max_col
                        call add(aft_arg, signal_line)
                        let signal_line = s:vlog_arg_margin. inputs[signal_index] . ", "
                        let arg_col = len(s:vlog_arg_margin) + strlen(inputs[signal_index]) + 2
                    else
                        let signal_line = signal_line . inputs[signal_index] . ", "
                        let arg_col = arg_col + strlen(inputs[signal_index]) + 2
                    endif
                endfor
                if arg_col > s:vlog_max_col
                    call add(aft_arg, signal_line)
                    let signal_line = s:vlog_arg_margin. inputs[len(inputs)-1]
                else
                    let signal_line = signal_line . inputs[len(inputs)-1]
                endif
                if len(outputs) > 0 || len(inouts) > 0
                    let signal_line = signal_line . ", "
                endif
                call add(aft_arg, signal_line)
            endif
            "outputs
            if len(outputs) > 0
                if len(inputs) > 0
                    call add(aft_arg, "")
                endif
                call add(aft_arg, s:vlog_arg_margin."//Outputs")
                let arg_col = len(s:vlog_arg_margin)
                let signal_line = s:vlog_arg_margin
                for signal_index in range(len(outputs)-1)
                    if arg_col > s:vlog_max_col
                        call add(aft_arg, signal_line)
                        let signal_line = s:vlog_arg_margin . outputs[signal_index] . ", "
                        let arg_col = len(s:vlog_arg_margin) + strlen(outputs[signal_index]) + 2
                    else
                        let signal_line = signal_line . outputs[signal_index] . ", "
                        let arg_col = arg_col + strlen(outputs[signal_index]) + 2
                    endif
                endfor
                if arg_col > s:vlog_max_col
                    call add(aft_arg, signal_line)
                    let signal_line = s:vlog_arg_margin. outputs[len(outputs)-1]
                else
                    let signal_line = signal_line . outputs[len(outputs)-1]
                endif
                if len(inouts) > 0
                    let signal_line = signal_line . ", "
                endif
                call add(aft_arg, signal_line)
            endif
            "inouts
            if len(inouts) > 0
                if len(inputs) > 0 || len(outputs) > 0
                    call add(aft_arg, "")
                endif
                call add(aft_arg, s:vlog_arg_margin."//Inouts")
                let arg_col = len(s:vlog_arg_margin)
                let signal_line = s:vlog_arg_margin
                for signal_index in range(len(inouts)-1)
                    if arg_col > s:vlog_max_col
                        call add(aft_arg, signal_line)
                        let signal_line = s:vlog_arg_margin . inouts[signal_index] . ", "
                        let arg_col = len(s:vlog_arg_margin) + strlen(inouts[signal_index]) + 2
                    else
                        let signal_line = signal_line . inouts[signal_index] . ", "
                        let arg_col = arg_col + strlen(inouts[signal_index]) + 2
                    endif
                endfor
                if arg_col > s:vlog_max_col
                    call add(aft_arg, signal_line)
                    let signal_line = s:vlog_arg_margin. inouts[len(inouts)-1]
                else
                    let signal_line = signal_line . inouts[len(inouts)-1]
                endif
                call add(aft_arg, signal_line)
            endif

            let signal_line = ");"
            call add(aft_arg, signal_line)
        else
            call add(aft_arg, line)
        endif
    endfor
    call s:UpdateBuf(aft_arg,-1)
endfunction "}}}2

"---------------------------------------------------------------
"        Automatic Instance Generation
"---------------------------------------------------------------
function KillAutoInst(kill_all) "{{{2
   let line_index = 1
   let goto_lnum = -1
   let goto_lnum_valid = 1
   let aft_kill = []
   if a:kill_all
        let lnum = 1
   else
        let lnum = line(".")
   endif
   let goto_lnum = lnum
   let kill = 1
   let multi_line_insted = 1
   while line_index <= line("$")
      let line = getline(line_index)
      if line_index < lnum
         call add(aft_kill, line)
      "elseif line =~ '/\*\<autoinst\>\*/\s*$'
      "elseif kill == 1 && line =~ '/\*\<autoinst\>\*/\s*\()\s*;\s*\)\?$'
      elseif kill == 1 && line =~ '/\*\<autoinst\>'
         let kill = a:kill_all
         if goto_lnum_valid
             let goto_lnum_valid = 0
             let goto_lnum = line_index
         endif

         if line =~ ');\s*$'
             let multi_line_insted = 0
         endif

         let line = substitute(line, '\*/.*$', "\*/);", "")
         call add(aft_kill, line)

         if multi_line_insted
             let line_index = line_index + 1
             let line = getline(line_index)
             while line !~ ')\s*;$'
                if(line =~ 'endmodule' || line_index == line("$"))
                    call add(aft_kill, "")
                    call add(aft_kill, line)
                    break
                endif
                let line_index = line_index + 1
                let line = getline(line_index)
             endwhile
         endif
      else
         call add(aft_kill, line)
      endif
      let line_index = line_index + 1
   endwhile
   call s:UpdateBuf(aft_kill,goto_lnum)
endfunction "}}}2

function AutoInst(kill_all) "{{{2
    let aft_inst = []
    let max_len = []
    if a:kill_all
        let insts = s:GetInsts()
        let lnum = 1
    else
        let insts = s:GetInst()
        let lnum = line(".")
    endif
    if insts == {}
        echo "No Instance found!"
        return
    endif
    call KillAutoInst(a:kill_all)
    let line_index = 1
    let kill = 1
    let oneline_mode = 0
    for line in getline(1, line("$"))
        if line_index < lnum
            call add(aft_inst, line)
        "elseif kill == 1 && line =~ '(/\*\<autoinst\>\s*\*/)\s*;.*$'
        "elseif kill == 1 && line =~ '(/\*\<autoinst\>'  "2017.09.16
        elseif kill == 1 && line =~ '/\*\<autoinst\>'
            let kill = a:kill_all
            "let tmp = split(line)
            "let inst_name = tmp[0]
            let [inst_name, tmp] = s:GetInstNameAdvance(line_index)
            if has_key(insts, inst_name)
                let inst_file = insts[inst_name]
            else
                echo "Has not found the instance: ".inst_name."'s file!"
                return
            endif
            if line =~ '--oneline'
                let oneline_mode = 1
            endif
            
            let inst_io_seq = {}
            "let io_wire = {}
            let lines = readfile(inst_file)
            call s:GetSeqIO(lines, inst_io_seq)
            let max_len = s:GetPortMaxLen(inst_io_seq)

            if oneline_mode
                "oneline mode
                let line = substitute(line, ');\s*', "", "")

                for seq in sort(keys(inst_io_seq))
                    let value = inst_io_seq[seq]
                    let width = value[0]
                    let type = value[1]
                    let sig = value[5]

                    if type =~ 'keep'
                        continue
                    endif

                    let line = line . ' .' . sig . '(' . sig
                    if width != 'c0'
                        let line = line . "[" . width . ":0]"
                    endif
                    let line = line . '),'
                endfor
                let line = substitute(line, '),$', "));", "")
                call add(aft_inst, line)

            else
                "multi line mode
                let line = substitute(line, ');\s*', "", "")
                call add(aft_inst, line)

                let prefix_max_len = max_len[0]
                let suffix_max_len = max_len[1]

                for seq in sort(keys(inst_io_seq))
"          0     1       2       3    4      5          6       7
"       [width,type,has_defined,seq,line,signal_name,io_dir,last_port]
                    let value = inst_io_seq[seq]
                    let width = value[0]
                    let type = value[1]
                    let sig = value[5]
                    let io_dir = value[6]
                    let io_dir = substitute(io_dir, '\(input\|inout\)', '\1 ', '')

                    if type =~ 'keep'
                        if value[4] =~ '^\s*\/\/'
                            call add(aft_inst, "    " . value[4])
                        else
                            call add(aft_inst, value[4])
                        endif
                        continue
                    endif

                    let prefix_margin = s:CalMargin(prefix_max_len, len(sig))
                    let tmp_line = '    .' . sig . prefix_margin .'(' . sig
                    if width != 'c0'
                        let suffix_margin = s:CalMargin(suffix_max_len, len(sig)+len(width)+4)
                        let tmp_line = tmp_line . "[" . width . ":0]"
                    else
                        let suffix_margin = s:CalMargin(suffix_max_len, len(sig))
                    endif
                    if value[7] == 1
                        let tmp_line = tmp_line . suffix_margin . ')  // ' . io_dir
                    else
                        let tmp_line = tmp_line . suffix_margin . '), // ' . io_dir
                    endif
                    call add(aft_inst, tmp_line)
                endfor

                let line = ");"
                call add(aft_inst, line)
            endif
        else
            call add(aft_inst, line)
        endif
        let line_index = line_index + 1
    endfor
    call s:UpdateBuf(aft_inst,-1)
endfunction "}}}2

function AutoInstUpdate(kill_all) "{{{2
    "======================================================================================
    "Function:
    "    Update module instance, detect the Newst append and have deleted module ports
    "    It is very useful for RTL code module instance update.
    "
    "Note:
    "   not support oneline mode
    "   not support rtl code /* ... */ style comment
    "======================================================================================
    let aft_inst = []
    let max_len = []
    if a:kill_all
        let insts = s:GetInsts()
        let lnum = 1
    else
        let insts = s:GetInst()
        let lnum = line(".")
    endif
    if insts == {}
        echo "No Instance found!"
        return
    endif
    let line_index = 1
    let kill = 1
    let instance_updating = 0
    let goto_lnum = lnum


    while line_index <= line("$")
        let line_index_preskip = line_index
        "1 step,skip comment
        let line_index = s:SkipCommentLine(0,line_index)
        if line_index == -1
            let line_index = line("$")
        endif
        " print skip comment line
        if line_index_preskip < line_index
            for line in getline(line_index_preskip, line_index-1)
                call add(aft_inst, line)
            endfor
        endif

        "2 step get define
        let line = getline(line_index)

        if line_index < lnum
            call add(aft_inst, line)
        "elseif kill == 1 && line =~ '(/\*\<autoinst\>'  "2017.09.16
        elseif kill == 1 && line =~ '/\*\<autoinst\>'
            let kill = a:kill_all
            let instance_updating = 1


            let tmp = split(line)
            "let inst_name = tmp[0]
            let [inst_name, tmp] = s:GetInstNameAdvance(line_index)
            if has_key(insts, inst_name)
                let inst_file = insts[inst_name]
            else
                echo "Has not found the instance: ".inst_name."'s file!"
                return
            endif

            let inst_io_seq = {}
            let inst_io = {}
            let lines = readfile(inst_file)
            call s:GetSeqIO(lines, inst_io_seq)
            let max_len = s:GetPortMaxLen(inst_io_seq)
            call s:ConvertSeqIO(inst_io_seq,inst_io)

            let old_inst_io = {}


            call add(aft_inst, line)

            let prefix_max_len = max_len[0]
            let suffix_max_len = max_len[1]
        elseif instance_updating == 1
            if line =~ ')\s*;'
                let instance_updating = 0

                for key in keys(old_inst_io)
                    if has_key(inst_io,key)
                        call remove(inst_io, key)
                    endif
                endfor

                let old_inst_io = {}
                let inst_io_seq = {}
                call s:ConvertIO(inst_io,inst_io_seq)

                for seq in sort(keys(inst_io_seq))
"          0     1       2       3    4      5          6       7
"       [width,type,has_defined,seq,line,signal_name,io_dir,last_port]
                    let value = inst_io_seq[seq]
                    let width = value[0]
                    let type = value[1]
                    let sig = value[5]
                    let io_dir = value[6]
                    let io_dir = substitute(io_dir, '\(input\|inout\)', '\1 ', '')

                    let prefix_margin = s:CalMargin(prefix_max_len, len(sig))
                    let tmp_line = '    .' . sig . prefix_margin .'(' . sig
                    if width != 'c0'
                        let suffix_margin = s:CalMargin(suffix_max_len, len(sig)+len(width)+4)
                        let tmp_line = tmp_line . "[" . width . ":0]"
                    else
                        let suffix_margin = s:CalMargin(suffix_max_len, len(sig))
                    endif
                    let tmp_line = tmp_line . suffix_margin . '), // ' . io_dir . ' // INST_NEW'
                    call add(aft_inst, tmp_line)
                endfor

            elseif (line !~ '^\s*\`\(if\|else\|endif\)') && (line !~ '^\s*\/\/') && (line !~ '^\s*$')
                let l:port = s:GetPortName(line)
                if has_key(inst_io, l:port)
                    let value = inst_io[l:port]
                    "let line = line . ' // ' . value[6]

                    call extend(old_inst_io, {value[5] : value})
                elseif l:port != ''
                    let line = line . ' // INST_DEL: port ' . l:port . ' have deleted'
                endif
            endif

            call add(aft_inst, line)
        else
            call add(aft_inst, line)
        endif
        let line_index = line_index + 1
    endwhile
    call s:UpdateBuf(aft_inst,goto_lnum)
    echo 'command completed! press any key to continue...'
endfunction "}}}2

function AutoInstUpdateOrder(kill_all) "{{{2
    "======================================================================================
    "Function:
    "    Update module instance, instance port order same with module port.
    "    It is very useful for RTL code module instance update.
    "
    "Note:
    "   not support oneline mode
    "   not support rtl code /* ... */ style comment
    "======================================================================================
    let aft_inst = []
    let max_len = []
    if a:kill_all
        let insts = s:GetInsts()
        let lnum = 1
    else
        let insts = s:GetInst()
        let lnum = line(".")
    endif
    if insts == {}
        echo "No Instance found!"
        return
    endif
    let line_index = 1
    let kill = 1
    let instance_updating = 0
    let old_inst_seq = 0
    let goto_lnum = lnum


    while line_index <= line("$")
        let line_index_preskip = line_index
        "1 step,skip comment
        let line_index = s:SkipCommentLine(0,line_index)
        if line_index == -1
            let line_index = line("$")
        endif
        " print skip comment line
        if line_index_preskip < line_index && instance_updating == 0
            for line in getline(line_index_preskip, line_index-1)
                call add(aft_inst, line)
            endfor
        endif

        "2 step get define
        let line = getline(line_index)

        if line_index < lnum
            call add(aft_inst, line)
        "elseif kill == 1 && line =~ '(/\*\<autoinst\>'  "2017.09.16
        elseif kill == 1 && line =~ '/\*\<autoinst\>'
            let kill = a:kill_all
            let instance_updating = 1


            let tmp = split(line)
            "let inst_name = tmp[0]
            let [inst_name, tmp] = s:GetInstNameAdvance(line_index)
            if has_key(insts, inst_name)
                let inst_file = insts[inst_name]
            else
                echo "Has not found the instance: ".inst_name."'s file!"
                return
            endif

            let inst_io_seq = {}
            let inst_io = {}
            let lines = readfile(inst_file)
            call s:GetSeqIO(lines, inst_io_seq)
            let max_len = s:GetPortMaxLen(inst_io_seq)
            call s:ConvertSeqIO(inst_io_seq,inst_io)

            let old_inst_io = {}


            call add(aft_inst, line)

            let prefix_max_len = max_len[0]
            let suffix_max_len = max_len[1]
        elseif instance_updating == 1
            if line =~ ')\s*;'
                let instance_updating = 0

                for seq in sort(keys(inst_io_seq))
"          0     1       2       3    4      5          6       7
"       [width,type,has_defined,seq,line,signal_name,io_dir,last_port]
                    let value = inst_io_seq[seq]
                    let width = value[0]
                    let type = value[1]
                    let sig = value[5]
                    let io_dir = value[6]
                    let io_dir = substitute(io_dir, '\(input\|inout\)', '\1 ', '')

                    if type =~ 'keep'
                        if value[4] =~ '^\s*\/\/'
                            call add(aft_inst, "    " . value[4])
                        else
                            call add(aft_inst, value[4])
                        endif
                        continue
                    endif

                    let prefix_margin = s:CalMargin(prefix_max_len, len(sig))
                    let tmp_line = '    .' . sig . prefix_margin .'(' . sig
                    if width != 'c0'
                        let suffix_margin = s:CalMargin(suffix_max_len, len(sig)+len(width)+4)
                        let tmp_line = tmp_line . "[" . width . ":0]"
                    else
                        let suffix_margin = s:CalMargin(suffix_max_len, len(sig))
                    endif
                    if value[7] == 1
                        let tmp_line = tmp_line . suffix_margin . ')  // ' . io_dir
                    else
                        let tmp_line = tmp_line . suffix_margin . '), // ' . io_dir
                    endif

                    " detect INST_NEW
                    if has_key(old_inst_io, sig)
                        let value = old_inst_io[sig]
                        let tmp_line = value[4]

                        call remove(old_inst_io, sig)
                    else
                        let tmp_line = tmp_line . ' // INST_NEW'
                    endif

                    call add(aft_inst, tmp_line)
                endfor

                " print INST_DEL
                let inst_io_seq = {}
                call s:ConvertIO(old_inst_io,inst_io_seq)
                for seq in sort(keys(inst_io_seq))
                    let value = inst_io_seq[seq]
                    let tmp_line = value[4] . ' // INST_DEL: port ' . value[5] . ' have deleted'
                    call add(aft_inst, tmp_line)
                endfor

                let line = ");"
                call add(aft_inst, line)

            elseif (line !~ '^\s*\`\(if\|else\|endif\)') && (line !~ '^\s*\/\/') && (line !~ '^\s*$')
                let l:port = s:GetPortName(line)
                if l:port != ''
                    let seq = s:Seq2String(old_inst_seq)

                    let value = []
                    call add(value,'c0')        " 0
                    call add(value,'io_wire')   " 1
                    call add(value,0)           " 2
                    call add(value,seq)         " 3
                    call add(value,line)        " 4
                    call add(value,l:port)      " 5
                    call add(value,'input')     " 6
                    call add(value,0)           " 7

                    call extend(old_inst_io, {l:port : value})

                    let old_inst_seq = old_inst_seq + 1
                endif

            endif

        else
            call add(aft_inst, line)
        endif
        let line_index = line_index + 1
    endwhile
    call s:UpdateBuf(aft_inst,goto_lnum)
    echo 'command completed! press any key to continue...'
endfunction "}}}2

function AutoInstPortReAlign() "{{{2
    "======================================================================================
    "Function:
    "    Auto Inst Port signal auto Re-Align format, only Re-Align port connection
    "    No check inst validation, does not modify lines that have be commented.
    "
    "Note:
    "    not support oneline mode
    "======================================================================================
    let aft_inst = []
    let max_len = []

    let line_index = 1
    let lnum = line(".")
    let kill = 1
    let instance_updating = 0
    let goto_lnum = lnum


    while line_index <= line("$")
        let line_index_preskip = line_index
        "1 step,skip comment
        let line_index = s:SkipCommentLine(0,line_index)
        if line_index == -1
            let line_index = line("$")
        endif
        " print skip comment line
        if line_index_preskip < line_index
            for line in getline(line_index_preskip, line_index-1)
                call add(aft_inst, line)
            endfor
        endif

        "2 step get line
        let line = getline(line_index)

        if line_index < lnum
            call add(aft_inst, line)
        "elseif kill == 1 && line =~ '(/\*\<autoinst\>'  "2017.09.16
        elseif kill == 1 && line =~ '/\*\<autoinst\>'
            let kill = 0
            let instance_updating = 1

            call add(aft_inst, line)

        elseif instance_updating == 1
            if line =~ ')\s*;'
                let instance_updating = 0

            elseif (line !~ '^\s*\`\(if\|else\|endif\)') && (line !~ '^\s*\/\/') && (line !~ '^\s*$')

                let prefix_max_len = s:autoinst_prefix_max_len
                let suffix_max_len = s:autoinst_suffix_max_len

                " del space char util \w
                let line = substitute(line, '^\s*\(,\?\)\s*\(\.\)\s*', '\1\2', '')

                " port name ,.\w\+
                let port_name = matchstr(line, ',\?\.\w\+')
                let line = substitute(line, ',\?\.\w\+\s*(\s*', '', '')

                " del space char util )
                let line = substitute(line, '\s*)', ')', '')

                " inst_wire_name
                let inst_wire_name = matchstr(line,'.*)')
                let inst_wire_name = substitute(inst_wire_name,')', '', '')
                let line = substitute(line, '.*)', ')', '')

                " Do Re-Align
                let prefix_margin = s:CalMargin(prefix_max_len, len(port_name)-1)
                let tmp_line = '    ' . port_name . prefix_margin .'(' . inst_wire_name
                let suffix_margin = s:CalMargin(suffix_max_len, len(inst_wire_name))
                let tmp_line = tmp_line . suffix_margin

                let line = tmp_line . line
            endif

            call add(aft_inst, line)
        else
            call add(aft_inst, line)
        endif
        let line_index = line_index + 1
    endwhile
    call s:UpdateBuf(aft_inst,goto_lnum)
    echo 'command completed! press any key to continue...'
endfunction "}}}2

function AppendPortDriectionToInst(kill_all) "{{{2
    "======================================================================================
    "Function:
    "    Append port direction info(comment) to have instanced module port instanced line
    "
    "Note:
    "    not support oneline mode
    "======================================================================================
    let aft_inst = []
    let max_len = []
    if a:kill_all
        let insts = s:GetInsts()
        let lnum = 1
    else
        let insts = s:GetInst()
        let lnum = line(".")
    endif
    if insts == {}
        echo "No Instance found!"
        return
    endif
    let line_index = 1
    let kill = 1
    let instance_updating = 0
    let goto_lnum = lnum


    while line_index <= line("$")
        let line_index_preskip = line_index
        "1 step,skip comment
        let line_index = s:SkipCommentLine(0,line_index)
        if line_index == -1
            let line_index = line("$")
        endif
        " print skip comment line
        if line_index_preskip < line_index
            for line in getline(line_index_preskip, line_index-1)
                call add(aft_inst, line)
            endfor
        endif

        "2 step get define
        let line = getline(line_index)

        if line_index < lnum
            call add(aft_inst, line)
        "elseif kill == 1 && line =~ '(/\*\<autoinst\>'  "2017.09.16
        elseif kill == 1 && line =~ '/\*\<autoinst\>'
            let kill = a:kill_all
            let instance_updating = 1


            let tmp = split(line)
            "let inst_name = tmp[0]
            let [inst_name, tmp] = s:GetInstNameAdvance(line_index)
            if has_key(insts, inst_name)
                let inst_file = insts[inst_name]
            else
                echo "Has not found the instance: ".inst_name."'s file!"
                return
            endif

            let inst_io_seq = {}
            let inst_io = {}
            let lines = readfile(inst_file)
            call s:GetSeqIO(lines, inst_io_seq)
            let max_len = s:GetPortMaxLen(inst_io_seq)
            call s:ConvertSeqIO(inst_io_seq,inst_io)

            call add(aft_inst, line)

            let prefix_max_len = max_len[0]
            let suffix_max_len = max_len[1]
        elseif instance_updating == 1
            if line =~ ')\s*;'
                let instance_updating = 0

            elseif (line !~ '^\s*\`\(if\|else\|endif\)') && (line !~ '^\s*\/\/') && (line !~ '^\s*$')
                let l:port = s:GetPortName(line)
                if has_key(inst_io, l:port)
                    let value = inst_io[l:port]
                    let io_dir = value[6]
                    let io_dir = substitute(io_dir, '\(input\|inout\)', '\1 ', '')
                    let line = substitute(line,')\s*\(,\?\)', ')\1 ','')
                    " update port direction
                    if (match(line, ')\s*,\?\s*//\s*'.s:VlogTypePorts) != -1)
                        let line = substitute(line,'\()\(\s\|,\)\?\)\s*//\s*' . s:VlogTypePorts . '\s*', '\1 // ' . io_dir,'')
                    else
                    " append port direction
                        let line = substitute(line,'\()\(\s\|,\)\?\)', '\1 // ' . io_dir,'')
                    endif

                endif
            endif

            call add(aft_inst, line)
        else
            call add(aft_inst, line)
        endif
        let line_index = line_index + 1
    endwhile
    call s:UpdateBuf(aft_inst,goto_lnum)
    echo 'command completed! press any key to continue...'
endfunction "}}}2

"---------------------------------------------------------------
"        Automatic Parameter Generation
"---------------------------------------------------------------
function KillAutoPara() "{{{2
   let line_index = 1
   let goto_lnum = -1
   let goto_lnum_valid = 1
   let aft_kill = []
   while line_index <= line("$")
      let line = getline(line_index)
      if line == "// Define parameter here"
         if goto_lnum_valid
             let goto_lnum_valid = 0
             let goto_lnum = line_index
         endif
         let line_index = line_index + 1
         let line = getline(line_index)
         while line !~ "// End of automatic parameter" && line_index < line("$")
            let line_index = line_index + 1
            let line = getline(line_index)
         endwhile
         let line_index = line_index + 1
      elseif line =~ '^\s*\<endmodule\>'
         call add(aft_kill, line)
         break
      else
         call add(aft_kill, line)
         let line_index = line_index + 1
      endif
   endwhile
   call s:UpdateBuf(aft_kill,goto_lnum)
endfunction "}}}2

function AutoPara() "{{{2
    let aft_para = []
    call KillAutoPara()
    for line in getline(1, line("$"))
        if line =~ '/\*\<autopara\>'
            call add(aft_para, line)
            call add(aft_para, "// Define parameter here")
            let paras = s:GetAutoParas(line)

            "cal max len
            let maxlen = 0
            let maxpara = 0
            for para in paras
                for key in keys(para)
                    if maxlen < len(key)
                        let maxlen = len(key)
                    endif
                    if maxpara < str2nr(para[key])
                        let maxpara = str2nr(para[key])
                    endif
                endfor
            endfor
            let para_wid = 1
            while ((pow(2,para_wid)-1) < maxpara)
                let para_wid = para_wid + 1
            endwhile

            for para in paras
                for key in keys(para)
                    let margin = s:CalMargin(maxlen, len(key))
                    let line = "parameter " . key . margin . '= ' . para_wid . "'d" . para[key] . ';'
                    call add(aft_para, line)
                endfor
            endfor
            call add(aft_para, "// End of automatic parameter")
      elseif line =~ '^\s*\<endmodule\>'
         call add(aft_para, line)
         break
      else
         call add(aft_para, line)
      endif
   endfor
   call s:UpdateBuf(aft_para,-1)
endfunction "}}}2

"---------------------------------------------------------------
"        Automatic Fsm Generation
"---------------------------------------------------------------
function KillAutoFsm() "{{{2
   let line_index = 1
   let goto_lnum = -1
   let goto_lnum_valid = 1
   let aft_kill = []
   while line_index <= line("$")
      let line = getline(line_index)
      if line == "// Define fsm here"
         if goto_lnum_valid
             let goto_lnum_valid = 0
             let goto_lnum = line_index
         endif
         let line_index = line_index + 1
         let line = getline(line_index)
         while line !~ "// End of automatic fsm" && line_index < line("$")
            let line_index = line_index + 1
            let line = getline(line_index)
         endwhile
         let line_index = line_index + 1
      elseif line =~ '^\s*\<endmodule\>'
         call add(aft_kill, line)
         break
      else
         call add(aft_kill, line)
         let line_index = line_index + 1
      endif
   endwhile
   call s:UpdateBuf(aft_kill,goto_lnum)
endfunction "}}}2

function AutoFsm() "{{{2
    let aft_fsm = []
    call KillAutoFsm()
    for line in getline(1, line("$"))
        if line =~ '/\*\<autofsm\>'
            call add(aft_fsm, line)
            call add(aft_fsm, "// Define fsm here")
            let line = substitute(line,'^.*\<autofsm\>\s*','','')
            let line = substitute(line,'\s*\*/.*$','','')
            let paras = split(line,'\s\+')
            let state = paras[0]
            let inst_state = paras[1]
            let autoparaline = s:GetSpecAutoParaLine(state)
            let paras = s:GetAutoParas(autoparaline)

            let first_st = ''
            for key in keys(paras[0])
                let first_st = key
            endfor
            call add(aft_fsm, "always @(posedge clk or negedge rst_n) begin")
            call add(aft_fsm, s:indent . "if(!rst_n) begin")
            call add(aft_fsm, s:indent . s:indent . inst_state . ' <= #1 ' . first_st . ';')
            call add(aft_fsm, s:indent . "end else begin")
            call add(aft_fsm, s:indent . s:indent . inst_state . ' <= #1 ' . 'next_' . inst_state . ';')
            call add(aft_fsm, s:indent . "end")
            call add(aft_fsm, "end")

            call add(aft_fsm, "always @(*) begin")
            call add(aft_fsm, s:indent . 'next_' . inst_state . ' = ' . inst_state . ';')
            call add(aft_fsm, s:indent . 'case(' . inst_state . ')')

            for para in paras
                for key in keys(para)
                    call add(aft_fsm, s:indent . s:indent . key . ': begin')
                    call add(aft_fsm, s:indent . s:indent . 'end')
                endfor
            endfor
            call add(aft_fsm, s:indent . s:indent . 'default' . ': begin')
            call add(aft_fsm, s:indent . s:indent . 'end')

            call add(aft_fsm, s:indent . 'endcase')
            call add(aft_fsm, "end")

            call add(aft_fsm, "// End of automatic fsm")
      elseif line =~ '^\s*\<endmodule\>'
         call add(aft_fsm, line)
         break
      else
         call add(aft_fsm, line)
      endif
   endfor
   call s:UpdateBuf(aft_fsm,-1)
endfunction "}}}2

"---------------------------------------------------------------
"        Automatic Definition Generation
"---------------------------------------------------------------
function KillAutoDef() "{{{2
   let aft_kill = []
   let line_index = 1
   let goto_lnum = -1
   while line_index <= line("$")
      let line = getline(line_index)
      if line =~ '^\s*/\*\<\(autodef\|AUTODEF\)\>'
         let goto_lnum = line_index
         call add(aft_kill, line)
      elseif line == "// Define io wire here"
         "let goto_lnum = line_index - 1
         let line_index = line_index + 1
         let line = getline(line_index)
         while line != "// End of automatic define"
            let line_index = line_index + 1
            let line = getline(line_index)
         endwhile
      else
         call add(aft_kill, line)
      endif
      let line_index = line_index + 1
   endwhile
   call s:UpdateBuf(aft_kill,goto_lnum)
endfunction "}}}2

function AutoDef() "{{{2
    let link_dict = {}
    let signals = {}
    let aft_def = []
    let max_len = 0
    call KillAutoDef()
    "let insts = GetInsts()
    "let inst_express = GetInstExpress(keys(insts))
    "let lines = Filter(getline(1, line("$")))
    let alldefs = s:GetAllDefs()
    let allparas = s:GetAllParas()
    let unresolved = s:GetAllSignals(alldefs,allparas)
    let line_index = 1
    let io_seq = 0
    let usr_seq = 0
    while line_index <= line("$")
        "0 step, skip autodef off - on
        let line = getline(line_index)
        if line == "/*autodef off*/"
            let line_index = line_index + 1
            let line = getline(line_index)
            while line != "/*autodef on*/" && line_index < line("$")
                let line_index = line_index + 1
                let line = getline(line_index)
            endwhile
            let line_index = line_index + 1
        endif

        "1 step,skip comment
        let line_index = s:SkipCommentLine(0,line_index)
        if line_index == -1
            break
        endif
        "2 step get define
        let line = getline(line_index)
        let line = substitute(line,'//.*$','','')
        let line = substitute(line,'^\s*,','','')

        " io_wire or io_reg
        "if line =~ '^\s*\(\<input\>\|\<output\>\|\<inout\>\)'
        if line =~ '^\s*' . s:VlogTypePorts
            let io_seq = s:ExtendIoFromLine(signals,line,io_seq)
        " usrdefine
        "elseif line =~ '^\s*\(\<wire\>\|\<reg\>\)'
        elseif line =~ '^\s*' . s:VlogTypeDatas
            let usr_seq = s:ExtendUsrdefFromLine(signals,line,usr_seq)
        " ff_reg
        elseif line =~ '^\s*\<always\>\s*@\s*(\s*\<\(posedge\|negedge\)\>'
            let line_index = line_index + 1
            let line = getline(line_index)
            "Break meet another always block, assign statement or instance
            while line !~ '^\s*\<always\>' && line !~ '^\s*\<assign\>' && line !~ '^\s*\<endmodule\>' && line !~ '/\*\<autoinst\>\*/'
                "1 step,skip comment
                let line_index = s:SkipCommentLine(0,line_index)
                if line_index == -1
                    break
                endif
                "2 step get define
                let line = getline(line_index)
                if line =~ '^\s*\<always\>' || line =~ '^\s*\<assign\>' || line =~ '^\s*\<endmodule\>' || line =~ '/\*\<autoinst\>\*/'
                    break
                endif

                if line =~ '.*<=.*'
                    " Remove this condition
                    " if(!rst) a <= #1 b;
                    " else if(c_valid)  a<= #1 c;
                    " else a <= #1 d;
                    "
                    " 2'h0: a <= #1 b; // case
                    let line = substitute(line, '\<if\>\s*(.*)\s\+', "", "")
                    let line = substitute(line, '\<else\>\s\+', "", "")
                    "let line = substitute(line, '^\s*\S\+\s*:', "", "")
                    
                    let ll = matchstr(line,'\w\+\s*\(\[.*\]\)\?\s*<=')
                    let ll = substitute(ll,'<=', "", "")
                    let rr = matchstr(line,'<=.*$')
                    let rr = substitute(rr,'<=', "", "")

                    "let side = s:GetAssignSide(split(line,'<='))
                    let side = s:GetAssignSide([ll,rr])

                    call s:ExtendFromSide(signals,side,'freg')
                    if len(side) == 3
                        if side[2] == 'link'
                            call s:UpdateLinkDict(link_dict,allparas,side[0],side[1])
                        endif
                    endif
                endif
                let line_index = line_index + 1
                let line = getline(line_index)
            endwhile
            continue
        " comb_reg
        elseif line =~ '^\s*\<always\>'
            let line_index = line_index + 1
            let line = getline(line_index)
            "Break meet another always block, assign statement or instance
            while line !~ '^\s*\<always\>' && line !~ '^\s*\<assign\>' && line !~ '^\s*\<endmodule\>' && line !~ '/\*\<autoinst\>\*/'
                "1 step,skip comment
                let line_index = s:SkipCommentLine(0,line_index)
                if line_index == -1
                    break
                endif
                "2 step get define
                let line = getline(line_index)
                if line =~ '^\s*\<always\>' || line =~ '^\s*\<assign\>' || line =~ '^\s*\<endmodule\>' || line =~ '/\*\<autoinst\>\*/'
                    break
                endif

                if line =~ '.*=.*;'
                    " Remove this condition
                    " if(!rst) a <= #1 b;
                    " else if(c_valid)  a<= #1 c;
                    " else a <= #1 d;
                    "
                    " 2'h0: a <= #1 b; // case
                    let line = substitute(line, '\<if\>\s*(.*)\s\+', "", "")
                    let line = substitute(line, '\<else\>\s\+', "", "")
                    "let line = substitute(line, '^\s*\S\+\s*:', "", "")
                    
                    "let ll = matchstr(line,'\s*\w\+\s*=')
                    "let rr = substitute(line,'^.*=','','')
                    "let ll = substitute(ll,'=','','')

                    let ll = matchstr(line,'\w\+\s*\(\[.*\]\)\?\s*=')
                    let ll = substitute(ll,'=', "", "")
                    let rr = matchstr(line,'=.*$')
                    let rr = substitute(rr,'=', "", "")

                    let side = s:GetAssignSide([ll,rr])

                    call s:ExtendFromSide(signals,side,'creg')
                    if len(side) == 3
                        if side[2] == 'link'
                            call s:UpdateLinkDict(link_dict,allparas,side[0],side[1])
                        endif
                    endif
                endif
                let line_index = line_index + 1
                let line = getline(line_index)
            endwhile
            continue
        " Get Wires
        elseif line =~ '^\s*\<assign\>'
            let line = substitute(line, '^\s*\<assign\>\(\s*#`\?\w\+\)\?', "", "")
            "let ll = matchstr(line,'^\s*\w\+\s*=')
            "let rr = substitute(line,'^\s*\w\+\s*=','','')
            "let ll = substitute(ll,'=','','')

            let ll = matchstr(line,'\w\+\s*\(\[.*\]\)\?\s*=')
            let ll = substitute(ll,'=', "", "")
            let rr = matchstr(line,'=.*$')
            let rr = substitute(rr,'=', "", "")

            let side = s:GetAssignSide([ll,rr])

            call s:ExtendFromSide(signals,side,'wire')
            if len(side) == 3
                if side[2] == 'link'
                    call s:UpdateLinkDict(link_dict,allparas,side[0],side[1])
                endif
            endif
        " Get inst_wire
        elseif line =~ '/\*\<autoinst\>\*/'
            let inst = s:GetInstName(line)
            let inst_file = s:GetInstFileName(inst)
            if inst_file == ''
                echohl ErrorMsg | echo "file: tags not exist or need update! inst: " . inst . " is not in tags, or file:" .inst. ".v is not exist in cur dir(" .$PWD. "/)"  | echohl None
                return
            endif
            let inst_lines = readfile(inst_file)
            let inst_io_seq = {}
            let inst_io = {}
            "call s:GetIO(inst_lines,inst_io)
            call s:GetSeqIO(inst_lines,inst_io_seq)
            echo inst_io_seq
            call s:ConvertSeqIO(inst_io_seq,inst_io)

            let line_index = line_index + 1
            let line = getline(line_index)
            "Break meet ');' end of one inst
            while line !~ ');$' && line_index < line("$")
                "1 step,skip comment
                let line_index = s:SkipCommentLine(0,line_index)
                if line_index == -1
                    break
                endif
                "2 step get define
                let line = getline(line_index)
                if line =~ ');'
                    break
                endif

                if line =~ '^\s*\.\w\+\s\+(\s*\w\+.*)'
                    call s:ExtendInstWireFromLine(signals,line,inst_io)
                endif
                let line_index = line_index + 1
                let line = getline(line_index)
            endwhile


        elseif line =~ '^\s*\<endmodule\>'
            break
        endif
        let line_index = line_index + 1
    endwhile

    let link_dict = s:GroupLinkDict(link_dict)

    "remove paras from signals
    for key0 in sort(keys(signals))
        for key1 in sort(keys(allparas))
            if key0 == key1
                call remove(signals, key0)
                break
            endif
        endfor
    endfor

    call s:UpdateDefine(unresolved,link_dict,signals)

    let io_wire = {}
    let usr_def = {}
    let ff_reg = {}
    let comb_reg = {}
    let wire = {}
    let inst_wire = {}
    let max_len = s:DivSignals(signals,io_wire,usr_def,ff_reg,comb_reg,wire,inst_wire)

    "update current buffer
    for line in getline(1, line("$"))
        if line =~ '^\s*/\*\<\(autodef\|AUTODEF\)\>\*/'
            call add(aft_def, line)
            call add(aft_def, "// Define io wire here")
            for io in sort(keys(io_wire))
                let value = io_wire[io]
                if value[1] == 'io_wire'
                    let line = 'wire '
                else
                    let line = 'reg  '
                endif
                let line = line . s:CalMargin(12,len(line))
                if value[0] != "c0"
                    let line = line . '[' . value[0] . ':0]'
                endif
                let margin = s:CalMargin(max_len, len(line))
                call add(aft_def, line.margin.value[5].";")
            endfor

            call add(aft_def, "// Define flip-flop registers here")
            for regs in sort(keys(ff_reg))
                let value = ff_reg[regs]
                let line = 'reg  '
                let line = line . s:CalMargin(12,len(line))
                if value[0] != "c0"
                    let line = line . '[' . value[0] . ':0]'
                endif
                let margin = s:CalMargin(max_len, len(line))
                call add(aft_def, line.margin.regs.";")
            endfor

            call add(aft_def, "// Define combination registers here")
            for regs in sort(keys(comb_reg))
                let value = comb_reg[regs]
                let line = 'reg  '
                let line = line . s:CalMargin(12,len(line))
                if value[0] != "c0"
                    let line = line . '[' . value[0] . ':0]'
                endif
                let margin = s:CalMargin(max_len, len(line))
                call add(aft_def, line.margin.regs.";")
            endfor

            call add(aft_def, "// Define wires here")
            for wires in sort(keys(wire))
                let value = wire[wires]
                let line = 'wire '
                let line = line . s:CalMargin(12,len(line))
                if value[0] != "c0"
                    let line = line . '[' . value[0] . ':0]'
                endif
                let margin = s:CalMargin(max_len, len(line))
                call add(aft_def, line.margin.wires.";")
            endfor

            call add(aft_def, "// Define inst wires here")
            for wires in sort(keys(inst_wire))
                let value = inst_wire[wires]
                let line = 'wire '
                let line = line . s:CalMargin(12,len(line))
                if value[0] != "c0"
                    let line = line . '[' . value[0] . ':0]'
                endif
                let margin = s:CalMargin(max_len, len(line))
                call add(aft_def, line.margin.wires.";")
            endfor

            call add(aft_def, "// Unresolved define signals here")
            for regs in sort(keys(unresolved))
                call add(aft_def, "unresolved ".regs.";")
            endfor
            call add(aft_def, "// End of automatic define")
        "elseif line !~ '^\s*\<\(wire\|reg\|genvar\|integer\)\>'
        elseif line !~ '^\s*' . s:VlogTypeDatas
            call add(aft_def, line)
        else
            call add(aft_def, line)
        endif
    endfor
    call s:UpdateBuf(aft_def,-1)
    call search("// Unresolved define signals here")
endfunction "}}}2

function KillAuto() "{{{2
   call KillAutoArg()
   call KillAutoDef()
   call KillAutoInst(1)
endfunction
"}}}2

"}}}1


"Search instance / module / driver 搜索{{{1

"SearchInstance{{{2
function SearchInstance(backward)
    call s:PushMark()
    if (a:backward == 1)            "向上/向下搜索
        execute "normal 0"
        call search('^\s*'.'\(\|.*)\s\+\|'.s:not_keywords_pattern.'\s\+\)'.s:not_keywords_pattern.'\(\s*$\|\s*\/\/.*$\|\s*(\)','be')
       "call search('^\s*'.'\(\|.*)\s\+\|'.s:not_keywords_pattern.'\s\+\)'.s:not_keywords_pattern.'\(\s*$\|\s*(\)','be')
    else
        execute "normal $"
        call search('^\s*'.'\(\|.*)\s\+\|'.s:not_keywords_pattern.'\s\+\)'.s:not_keywords_pattern.'\(\s*$\|\s*\/\/.*$\|\s*(\)','e')
    endif
endfunction
"}}}2

"SearchModule{{{2
function SearchModule(backward)
    call s:PushMark()
    if (a:backward)
        execute "normal 0"
        call search('^\s*module','be')
    else
        execute "normal $"
        call search('^\s*module','e')
    endif
endfunction
"}}}2

"SearchDriverLite{{{2
function SearchDriverLite(backward)
    call s:PushMark()
    "               input ... <cword>             or   <cword> =/<= ...
    call search('\('.'\<input\>'.'.*'.'\<'.expand("<cword>").'\>'.'\)' .'\|'. '\('.'\<'.expand("<cword>").'\>'.'\([.*]\)\?'.'\s*<\?=\s'.'\)','')
endfunction
"}}}2

"Marker{{{2

let b:markchar = 'a'
function s:MarkCharAdd()
    if (b:markchar == 'z')
        let b:markchar = 'a'
    else
        let l:markchar2nr = char2nr(b:markchar) + 1
        let b:markchar = nr2char(l:markchar2nr)
    endif
endfunction
function s:MarkCharDec()
    if (b:markchar == 'a')
        let b:markchar = 'z'
    else
        let l:markchar2nr = char2nr(b:markchar) - 1
        let b:markchar = nr2char(l:markchar2nr)
    endif
endfunction
function s:PushMark()
    if exists("b:markchar") == 0
        let b:markchar = 'a'
    endif
    execute "normal m" . b:markchar
    call s:MarkCharAdd()
    execute "normal :delmarks " . b:markchar
endfunction
function ForwardMark()
    if exists("b:markchar") == 0
        let b:markchar = 'a'
    endif
    call s:MarkCharAdd()
    execute "normal g`" . b:markchar
endfunction
function BackwardMark()
    if exists("b:markchar") == 0
        let b:markchar = 'a'
    endif
    call s:MarkCharDec()
    execute "normal g`" . b:markchar
endfunction

"}}}2

"Search Up Inst Line{{{2
function SearchUpInstLine()
    "it relay the '(' ')' pair match for search the inst module line
    let loss_pair = 0
    let lnum = line(".")
    while 1
        if (lnum <= 1)
            break
        else
            let line = getline(lnum)
            if (match(line,'[(|)]') != -1)
                "echo "line: " . line
                if (match(line,'(.*)') != -1)
                    "echo "paris"
                elseif (match(line,')') != -1)
                    let loss_pair = 1
                    "echo "loss_pair"
                elseif (match(line,'(') != -1)
                    if (loss_pair == 1)
                        let loss_pair = 0
                        "echo "get_pair"
                    else
                        "echo "break"
                        break
                    endif
                endif
            endif
        endif
        let lnum = lnum - 1
    endwhile
    call cursor(lnum,0)
endfunction
"}}}2

"}}}1


"RtlTree definition Rtl树{{{1

let s:oTreeNode = {}
let s:tree_up_dir_line = 'rtl tree'
let s:rtl_tree_is_open = 0
let s:rtl_tree_first_open = 1

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
    while l:line_index <= line("$")
        let l:line_index = s:SkipCommentLine(0,l:line_index)
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
                    let l:line_index = s:SkipCommentLine(0,l:line_index)
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
                    let l:line_index = s:SkipCommentLine(0,l:line_index)
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
    call s:oTreeNode.TreeLog("debug: CreateRtlTree done! -- " . a:tree.instname)
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
    nnoremap <buffer> <cr> :call <SID>active(1)<cr>
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
    call s:oTreeNode.TreeLog("------------active--------------" . s:current_node.instname)

    "wincmd p
    execute bufwinnr(t:RtlBufName) . " wincmd w"

    "let s:GotoInstFile_use = 1

        " mouse left-click or module is undefined
        if a:mode == 0 || s:current_node.unresolved == 1 || s:current_node.macro_type == 1
            call s:oTreeNode.TreeLog("tag - 0 : -- " . s:current_node.parent.instname)
            "echo "tag " . s:current_node.parent.instname
            execute "tag " . s:current_node.parent.instname
            call cursor(s:current_node.parent_inst_lnum,1)
            execute "normal zt"

        " module have defined & mouse double-click
        else
            "call s:oTreeNode.TreeLog("active - 1")
            let inst = s:current_node.instname
            "call s:oTreeNode.TreeLog("tag - 1 : -- " . inst)
            "echo "tag " . inst
            execute "tag " . inst
            execute "normal zt"
        endif

        "call s:oTreeNode.TreeLog("unresolved = " . s:current_node.unresolved)
        "call s:oTreeNode.TreeLog("childrensolved = " . s:current_node.childrensolved)
        "call s:oTreeNode.TreeLog("current_node= " . s:current_node.instname)

    " module have defined
    if s:current_node.unresolved == 0
        if s:current_node.childrensolved == 0 && a:mode == 1
            call s:oTreeNode.CreateRtlTree(s:current_node)
            execute "tag " . s:current_node.instname
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
    while l:line_index <= line("$")
        let l:line_index = s:SkipCommentLine(0,l:line_index)
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
    let splitSize = 28

    let t:NERDTreeBufName = localtime() . "_RtlTree_"
    silent! execute 'aboveleft ' . 'vertical ' . splitSize . ' new'
    silent! execute "edit " . t:NERDTreeBufName

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

function RtlTree()
    if s:rtl_tree_is_open == 0
        let s:rtl_tree_is_open = 1
        call s:OpenRtlTreeLog()
        call s:OpenRtlTree()
        let s:rtl_tree_first_open = 0
    else
        let s:rtl_tree_is_open = 0
        call s:CloseRtlTree()
        call s:CloseRtlTreeLog()
        let s:rtl_tree_first_open = 1
    endif
endfunction


" vim: set sw=4 sts=4 et fdm=marker:

"}}}1


"WireDef2PortConn definition 转换wire为例化"{{{1

function WireDef2PortConn() "{{{2
    let lnum = line(".")
    let line = getline(lnum)
    if line =~ '^\s*\/\/' || line =~ '^\s*$'
        return 0
    endif

    let type = matchstr(line,s:VlogTypePorts)
    let line = substitute(line,'^\s*' . s:VlogTypePorts . '\s*','','')
    let line = substitute(line,'^\s*' . s:VlogTypeDatas . '\s*','','')

    let width = matchstr(line,'\[.*:.*\]')
    let line = substitute(line,'\[.*:.*\]','','')
    let sig = matchstr(line,'\w\+')

    if line =~ '('
        if type =~ '\w\+'
            let tmp_line = type . s:CalMargin(7,len(type)) . 'wire ' . width
        else
            let tmp_line = 'wire ' . s:CalMargin(7,0) . width
        endif
        let margin = s:CalMargin(s:autodef_max_len, len(tmp_line))
        let tmp_line = tmp_line . margin . sig . ";"
    else
        let prefix_margin = s:CalMargin(s:autoinst_prefix_max_len, len(sig))
        let suffix_margin = s:CalMargin(s:autoinst_suffix_max_len, len(sig)+len(width))
        let tmp_line = '    .' . sig . prefix_margin .'(' . sig . width . suffix_margin . '), // ' . type
    endif
    call setline(lnum,tmp_line)
endfunction "}}}2

"}}}1


"Input2Output definition 转换input/output"{{{1

function Input2Output() "{{{2
    let lnum = line(".")
    let line = getline(lnum)
    if line =~ '^\s*\/\/' || line =~ '^\s*$'
        return 0
    endif

    if line =~ '\<input\>\s\?'
        let line = substitute(line,'\<input\>\s\?','output','')
    elseif line =~ '\<output\>'
        let line = substitute(line,'\<output\>','input ','')
    endif

    call setline(lnum,line)
endfunction "}}}2

"}}}1


