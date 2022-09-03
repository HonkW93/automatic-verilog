"-----------------------------------------------------------------------------
" Vim Plugin for Verilog Code Automactic Generation 
" Author:         HonkW
" Website:        https://honk.wang
" Last Modified:  2022/09/04 00:06
" File:           automatic.vim
" Note:           1. Auto function based on zhangguo's vimscript, heavily modified
"                 2. Rtl Tree based on zhangguo's vimscript, slightly modified
"                    https://www.vim.org/scripts/script.php?script_id=4067 
"------------------------------------------------------------------------------
" Modification History:
" Date          By              Version                 Change Description
"------------------------------------------------------------------------------
" 2021/3/26     HonkW           1.0.0                   First copy from zhangguo's vimscript
" 2021/4/5      HonkW           1.0.1                   Finish AutoInst & Autopara
" 2021/5/28     HonkW           1.1.0                   Optimize AutoInst & AutoPara
" 2021/6/12     HonkW           1.1.2                   Prototype of AutoReg
" 2021/8/1      HonkW           1.1.6                   Add modified verision of RtlTree
" 2021/9/14     HonkW           1.2.4                   Prototype of AutoDef
" 2021/11/20    HonkW           1.2.5                   Prototype of AutoArg
" 2022/2/15     HonkW           1.2.6                   Prototype of filelist & tags support
" 2022/05/18    HonkW           1.5                     Divide Auto Function into several .vim file
" 2022/09/04    HonkW           1.5.x                   Add AutoAll and KillAutoAll
" For vim version 7.x or above
"-----------------------------------------------------------------------------

"Sanity checks 启动判断{{{1
if exists("g:loaded_automatic_verilog_plugin")
    finish
endif
let g:loaded_automatic_verilog_plugin = 1

if v:version < 703        "如果vim版本低于7.3则无效,写法为 if v:version < 704,代表版本低于7.4
    echohl ErrorMsg | echo "automatic-verilog: this plugin requires vim >= 7.3. "| echohl None
    finish
endif

"Record update 记录脚本更新
autocmd BufWrite *.vim call s:UpdateVimscriptLastModifyTime()
function s:UpdateVimscriptLastModifyTime()
    let line = getline(5)
    if line =~ '\" Last Modified'
        call setline(5,"\" Last Modified:  " . strftime("%Y/%m/%d %H:%M"))
    endif
endfunction
"}}}1

"{{{1 Personal Keys
let g:atv_personal_keys = get(g:,'atv_personal_keys',0)
if g:atv_personal_keys == 1
    imap <F2> <C-R>=strftime("%Y/%m/%d")<CR>
endif
"}}}1

"{{{1 AutoAll KillAutoAll

if !hasmapto(':call g:ToggleAutoVerilogAll()<ESC>')
    map <S-F1>      :call g:ToggleAutoVerilogAll()<ESC>
endif

function g:ToggleAutoVerilogAll()
    if exists("s:kill")
        if s:kill == 1
            call s:AutoVerilogAll()
        else
            call s:KillAutoVerilogAll()
        endif
    else
        let s:kill = 1
        call s:AutoVerilogAll()
    endif
endfunction

function! s:AutoVerilogAll()
    call g:AutoInst(1)
    call g:AutoPara(1)
    call g:AutoParaValue(1)
    call g:AutoArg()
    call g:AutoDef()
    call g:AutoReg()
    call g:AutoWire()
endfunction

function! s:KillAutoVerilogAll()
    call g:KillAutoInst(1)
    call g:KillAutoPara(1)
    call g:KillAutoParaValue(1)
    call g:KillAutoArg()
    call g:KillAutoDef()
    call g:KillAutoReg()
    call g:KillAutoWire()
endfunction

"}}}1

runtime! plugin/automatic/*.vim

