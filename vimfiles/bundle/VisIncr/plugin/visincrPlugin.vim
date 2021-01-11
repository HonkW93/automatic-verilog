" visincrPlugin.vim: Visual-block incremented lists
"  Author:      Charles E. Campbell, Jr.  Ph.D.
"  Date:        Aug 16, 2011
"  Public Interface Only
"
"  (James 2:19,20 WEB) You believe that God is one. You do well!
"                      The demons also believe, and shudder.
"                      But do you want to know, vain man, that
"                      faith apart from works is dead?

" ---------------------------------------------------------------------
" Load Once: {{{1
if &cp || exists("g:loaded_visincrPlugin")
  finish
endif
let g:loaded_visincrPlugin = "v20"
let s:keepcpo              = &cpo
set cpo&vim

" ---------------------------------------------------------------------
"  Methods: {{{1
let s:I      = 0 
let s:II     = 1 
let s:IMDY   = 2 
let s:IYMD   = 3 
let s:IDMY   = 4 
let s:ID     = 5 
let s:IM     = 6 
let s:IA     = 7 
let s:IX     = 8 
let s:IIX    = 9 
let s:IB     = 10
let s:IIB    = 11
let s:IO     = 12
let s:IIO    = 13
let s:IR     = 14
let s:IIR    = 15
let s:IPOW   = 16
let s:IIPOW  = 17
let s:RI     = 18
let s:RII    = 19
let s:RIMDY  = 20
let s:RIYMD  = 21
let s:RIDMY  = 22
let s:RID    = 23
let s:RIM    = 24
let s:RIA    = 25
let s:RIX    = 26
let s:RIIX   = 27
let s:RIB    = 28
let s:RIIB   = 29
let s:RIO    = 30
let s:RIIO   = 31
let s:RIR    = 32
let s:RIIR   = 33
let s:RIPOW  = 34
let s:RIIPOW = 35

" ------------------------------------------------------------------------------
" Public Interface: {{{1
if !exists("g:visincr_longcmd")
  com! -ra -complete=expression -na=? I     call visincr#VisBlockIncr(s:I     , <f-args>)
  com! -ra -complete=expression -na=* II    call visincr#VisBlockIncr(s:II    , <f-args>)
  com! -ra -complete=expression -na=* IMDY  call visincr#VisBlockIncr(s:IMDY  , <f-args>)
  com! -ra -complete=expression -na=* IYMD  call visincr#VisBlockIncr(s:IYMD  , <f-args>)
  com! -ra -complete=expression -na=* IDMY  call visincr#VisBlockIncr(s:IDMY  , <f-args>)
  com! -ra -complete=expression -na=? ID    call visincr#VisBlockIncr(s:ID    , <f-args>)
  com! -ra -complete=expression -na=? IM    call visincr#VisBlockIncr(s:IM    , <f-args>)
  com! -ra -complete=expression -na=? IA	  call visincr#VisBlockIncr(s:IA    , <f-args>)
  com! -ra -complete=expression -na=? IX    call visincr#VisBlockIncr(s:IX    , <f-args>)
  com! -ra -complete=expression -na=* IIX   call visincr#VisBlockIncr(s:IIX   , <f-args>)
  com! -ra -complete=expression -na=? IB    call visincr#VisBlockIncr(s:IB    , <f-args>)
  com! -ra -complete=expression -na=* IIB   call visincr#VisBlockIncr(s:IIB   , <f-args>)
  com! -ra -complete=expression -na=? IO    call visincr#VisBlockIncr(s:IO    , <f-args>)
  com! -ra -complete=expression -na=* IIO   call visincr#VisBlockIncr(s:IIO   , <f-args>)
  com! -ra -complete=expression -na=? IR    call visincr#VisBlockIncr(s:IR    , <f-args>)
  com! -ra -complete=expression -na=* IIR   call visincr#VisBlockIncr(s:IIR   , <f-args>)
  com! -ra -complete=expression -na=? IPOW  call visincr#VisBlockIncr(s:IPOW  , <f-args>)
  com! -ra -complete=expression -na=* IIPOW call visincr#VisBlockIncr(s:IIPOW , <f-args>)

  com! -ra -complete=expression -na=? RI     call visincr#VisBlockIncr(s:RI     , <f-args>)
  com! -ra -complete=expression -na=* RII    call visincr#VisBlockIncr(s:RII    , <f-args>)
  com! -ra -complete=expression -na=* RIMDY  call visincr#VisBlockIncr(s:RIMDY  , <f-args>)
  com! -ra -complete=expression -na=* RIYMD  call visincr#VisBlockIncr(s:RIYMD  , <f-args>)
  com! -ra -complete=expression -na=* RIDMY  call visincr#VisBlockIncr(s:RIDMY  , <f-args>)
  com! -ra -complete=expression -na=? RID    call visincr#VisBlockIncr(s:RID    , <f-args>)
  com! -ra -complete=expression -na=? RIA    call visincr#VisBlockIncr(s:RIA    , <f-args>)
  com! -ra -complete=expression -na=? RIX    call visincr#VisBlockIncr(s:RIX    , <f-args>)
  com! -ra -complete=expression -na=? RIIX   call visincr#VisBlockIncr(s:RIIX   , <f-args>)
  com! -ra -complete=expression -na=? RIB    call visincr#VisBlockIncr(s:RIB    , <f-args>)
  com! -ra -complete=expression -na=? RIIB   call visincr#VisBlockIncr(s:RIIB   , <f-args>)
  com! -ra -complete=expression -na=? RIO    call visincr#VisOlockIncr(s:RIO    , <f-args>)
  com! -ra -complete=expression -na=? RIIO   call visincr#VisOlockIncr(s:RIIO   , <f-args>)
  com! -ra -complete=expression -na=? RIR    call visincr#VisRlockIncr(s:RIR    , <f-args>)
  com! -ra -complete=expression -na=? RIIR   call visincr#VisRlockIncr(s:RIIR   , <f-args>)
  com! -ra -complete=expression -na=? RIM    call visincr#VisBlockIncr(s:RIM    , <f-args>)
  com! -ra -complete=expression -na=? RIPOW  call visincr#VisBlockIncr(s:RIPOW  , <f-args>)
  com! -ra -complete=expression -na=* RIIPOW call visincr#VisBlockIncr(s:RIIPOW , <f-args>)
else
  com! -ra -complete=expression -na=? VI_I     call visincr#VisBlockIncr(s:I     , <f-args>)
  com! -ra -complete=expression -na=* VI_II    call visincr#VisBlockIncr(s:II    , <f-args>)
  com! -ra -complete=expression -na=* VI_IMDY  call visincr#VisBlockIncr(s:IMDY  , <f-args>)
  com! -ra -complete=expression -na=* VI_IYMD  call visincr#VisBlockIncr(s:IYMD  , <f-args>)
  com! -ra -complete=expression -na=* VI_IDMY  call visincr#VisBlockIncr(s:IDMY  , <f-args>)
  com! -ra -complete=expression -na=? VI_ID    call visincr#VisBlockIncr(s:ID    , <f-args>)
  com! -ra -complete=expression -na=? VI_IM    call visincr#VisBlockIncr(s:IM    , <f-args>)
  com! -ra -complete=expression -na=? VI_IA	  call visincr#VisBlockIncr(s:IA    , <f-args>)
  com! -ra -complete=expression -na=? VI_IX    call visincr#VisBlockIncr(s:IX    , <f-args>)
  com! -ra -complete=expression -na=* VI_IIX   call visincr#VisBlockIncr(s:IIX   , <f-args>)
  com! -ra -complete=expression -na=? VI_IB    call visincr#VisBlockIncr(s:IB    , <f-args>)
  com! -ra -complete=expression -na=* VI_IIB   call visincr#VisBlockIncr(s:IIB   , <f-args>)
  com! -ra -complete=expression -na=? VI_IO    call visincr#VisBlockIncr(s:IO    , <f-args>)
  com! -ra -complete=expression -na=* VI_IIO   call visincr#VisBlockIncr(s:IIO   , <f-args>)
  com! -ra -complete=expression -na=? VI_IR    call visincr#VisBlockIncr(s:IR    , <f-args>)
  com! -ra -complete=expression -na=* VI_IIR   call visincr#VisBlockIncr(s:IIR   , <f-args>)
  com! -ra -complete=expression -na=? VI_IPOW  call visincr#VisBlockIncr(s:IPOW  , <f-args>)
  com! -ra -complete=expression -na=* VI_IIPOW call visincr#VisBlockIncr(s:IIPOW , <f-args>)

  com! -ra -complete=expression -na=? VI_RI     call visincr#VisBlockIncr(s:RI     , <f-args>)
  com! -ra -complete=expression -na=* VI_RII    call visincr#VisBlockIncr(s:RII    , <f-args>)
  com! -ra -complete=expression -na=* VI_RIMDY  call visincr#VisBlockIncr(s:RIMDY  , <f-args>)
  com! -ra -complete=expression -na=* VI_RIYMD  call visincr#VisBlockIncr(s:RIYMD  , <f-args>)
  com! -ra -complete=expression -na=* VI_RIDMY  call visincr#VisBlockIncr(s:RIDMY  , <f-args>)
  com! -ra -complete=expression -na=? VI_RID    call visincr#VisBlockIncr(s:RID    , <f-args>)
  com! -ra -complete=expression -na=? VI_RIA    call visincr#VisBlockIncr(s:RIA    , <f-args>)
  com! -ra -complete=expression -na=? VI_RIX    call visincr#VisBlockIncr(s:RIX    , <f-args>)
  com! -ra -complete=expression -na=? VI_RIIX   call visincr#VisBlockIncr(s:RIIX   , <f-args>)
  com! -ra -complete=expression -na=? VI_RIB    call visincr#VisBlockIncr(s:RIB    , <f-args>)
  com! -ra -complete=expression -na=? VI_RIIB   call visincr#VisBlockIncr(s:RIIB   , <f-args>)
  com! -ra -complete=expression -na=? VI_RIO    call visincr#VisOlockIncr(s:RIO    , <f-args>)
  com! -ra -complete=expression -na=? VI_RIIO   call visincr#VisOlockIncr(s:RIIO   , <f-args>)
  com! -ra -complete=expression -na=? VI_RIR    call visincr#VisRlockIncr(s:RIR    , <f-args>)
  com! -ra -complete=expression -na=? VI_RIIR   call visincr#VisRlockIncr(s:RIIR   , <f-args>)
  com! -ra -complete=expression -na=? VI_RIM    call visincr#VisBlockIncr(s:RIM    , <f-args>)
  com! -ra -complete=expression -na=? VI_RIPOW  call visincr#VisBlockIncr(s:RIPOW  , <f-args>)
  com! -ra -complete=expression -na=* VI_RIIPOW call visincr#VisBlockIncr(s:RIIPOW , <f-args>)
endif

" ---------------------------------------------------------------------
"  Restoration And Modelines: {{{1
"  vim: ts=4 fdm=marker
let &cpo= s:keepcpo
unlet s:keepcpo
