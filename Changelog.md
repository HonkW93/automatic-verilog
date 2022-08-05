# Changelog
All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.5.1] - 2022-08-05

### Changed

- `autoinst` changed config and fixed several bugs

  修改部分配置并修复部分遗留问题

### Added

- Add `RtlTree` newer version

  优化版`RtlTree()`

### Fixed

- Bug fixed

  修复大量遗留问题

## [1.5] - 2022-05-15

### Changed

- `automatic.vim` changed into several different files

  拆分原文件为多个独立分拣，功能解耦合

### Fixed

- Bug fixed

  修复部分遗留问题

## [1.2.6] - 2022-02-15

### Fixed

- A few bugs fixed

  一些小`bug`修复，具体参考`commit`的内容

### Added

- Add `filelist`&`tags` for cross directory

  新增跨文件夹支持`filelist`及`tags`载入，包括多种可配置模式


## [1.2.5.1] - 2021-12-2

### Changed

- Backward compatibility

  优化 `sort()`获取方式，兼容部分`vim74`版本

  > 依据来源：
  >
  > `:h sort()`
  >
  > `:h v:version()`
  >
  > [sorting - Sort numbers in vimscript - Stack Overflow](https://stackoverflow.com/questions/27226987/sort-numbers-in-vimscript)
  >
  > [regex - Vim - Sort each line of numbers in a file? - Stack Overflow](https://stackoverflow.com/questions/25870715/vim-sort-each-line-of-numbers-in-a-file)
  >
  > *Edit:* This relies on the 'n' flag of the `sort()` function, which was added in 7.4.341 to allow sorting numbers rather than always treating them as strings.

## [1.2.5] - 2021-11-19

### Added

- Add `AutoArg`

  新增`AutoArg()`，包括4种可配置模式

### Fixed

- Optimize `GetDirList`

  优化 `GetDirList()`地址获取方式，使用绝对地址`full path`，不再使用相对地址

- Bug fixed for `GetFileDirDic`

  修复`GetFileDirDic()`获取除`.v`以及`.sv`之外以`v`结尾的目标文件的的异常匹配

  > 依据来源：
  >
  > `:h string`
  >
  > Single quoted strings are useful for patterns, so that backslashes do not need
  > to be doubled.	These two commands are equivalent:
  > 	` if a =~ "\\s*"`
  > 	`if a =~ '\s*'`

### Changed

- Optimize `key maping`

  允许自定义`Auto`函数的快捷键

  > 依据来源：
  >
  > `:h hasmapto()`

- Optimize  `remove_io` for `AutoReg`,`AutoWire` and `AutoDef`

  添加`remove_io`配置项

- Optimize  `atd_move` for `AutoDef`

  添加`atd_move`配置项

  

## [1.2.4] - 2021-09-15

### Added

- Add `AutoDef`

  新增初版`AutoDef()`，待测试
  
  

## [1.2.3] - 2021-09-14

### Added

- Add `AutoWire`

  新增初版`AutoWire()`，待测试

### Changed

- Optimize `Draw`

  优化所有`Draw`函数，包括`DrawIO`，`DrawPara`，`DrawParaValue`，`DrawReg`，`DrawWire`，使其对齐逻辑统一

- Optimize `GetReg`& `GetWire`

  优化 `GetReg()`及 `GetWire()`函数，均统一使用`GetAllSig()`函数作为获取接口，为以后`Merge()`函数作铺垫
  
- Optimize `GetDeclReg`& `GetDeclWire`

  优化已自动例化的寄存器或线网的获取方式。只识别`//Start of ...`以及`//End of ...`
  
  


## [1.2.2] - 2021-09-04

### Fixed

- Bug fixed for `GetInstModuleName`

  修复搜索特殊情况下匹配模块名异常的问题，例子如下：

  ```verilog
  module test #(.PARA_A(PARA_A)) u_test(
  ......
  );
  ```

### Changed

- Optimize `GetiWire`

  `GetiWire`函数巨幅优化，包括：

  1. 将删除`parameter`的模块外移，简化代码
  2. 由外部获取多个参数值，避免重复计算
  3. 简化内部获取信号流程（使用`has_key`替代原循环的方式）

### Added

- Add `Progressbar`

  由于`GetiWire`获取速度较慢及为后续函数考虑，新增`progressbar`进度条相关函数用于显示当前获取进度。进度条相关函数基于插件`progressbar`，作者`Andreas Politz`，[progressbar](http://www.vim.org/scripts/script.php?script_id=2006)



## [1.2.1] - 2021-08-31

### Fixed

- Bug fixed for `GetReg,GetaWire`

  `GetReg(),GetaWire(),`自动跳过`defparam`，避免异常

- Bug fixed for`GetIO`

  `GetIO()`修复注释类型`// ......  /*autoinst*/`产生的异常

- Bug fixed for`GetiWire`

  1. `GetiWire()`修复无法获取`IP`的输入输出端口导致`iwire`获取失败的异常

  2. `GetiWire()`修复括号嵌套导致的获取失败异常，（例如`.ADDR_CFG_LAST ( 32*(ROOT_CHN_NUM) )`的异常匹配）

- Bug fixed for`AutoPara`

  `AutoPara()`修复`#`和`(`不在同一行的特殊写法导致的异常问题

### Changed

- Optimize `Auto`

  优化各个`Auto()`函数写法，只使用单个的`try`及`endtry`

### Added

- Add `GetAllSig`

  新增`GetAllSig()`函数，获取单文件内所有信号并去冗余（未完成），为`AutoDef`编写做准备。




## [1.2.0] - 2021-08-27

### Fixed

- Bug fixed for `GetaWire`

  修复完善部分`GetaWire()`函数的正则匹配机制

- Bug fixed for`GetReg`

  1. 修复完善部分`GetReg()`部分子函数的正则匹配机制，避免错误匹配
  2. 子函数在匹配前自动跳过注释`//`，避免错误匹配

- Bug fixed for `GetIO`

  修复`GetIO()`在部分括号`(`匹配时因带注释(`//`)导致的获取模块名或例化名异常的问题

### Changed

- Force new buffer for `RtlTree`

  意外关闭原`buffer`后允许`RtlTree`强制重新打开，避免窗口异常`bug`。



## [1.1.9] - 2021-08-24

### Fixed

- Bug fixed for `GetiWire`

  修复完善部分`GetiWire()`函数的正则匹配机制，避免错误匹配多重括号，同时保证单行多例化的情况，例子如下：

  ```verilog
  module test u_test ( .a(wire_a) .b(wire_b[(3+2*4):0]))
  ```

- Bug fixed for `GetIO`

  修复`GetIO()`无法获取`IO`带`none`字眼的`bug`

### Changed

- Force jump for `RtlTree`

  原`buffer`修改后未保存时允许`RtlTree`进行强制跳转，避免窗口异常`bug`。



## [1.1.8] - 2021-08-21

### Fixed

- Bug fixed for `GetiWire`,`GetaWire`&`GetReg`

  修复完善部分`Get()`函数的正则匹配机制，避免错误匹配（例如`for(i=0;i<10;i=1+1)`,`wire a=1`等异常匹配）

- Bug fixed for `GetiWire`

  修复`GetiWire()`异常匹配`.a()`的问题

- Bug fixed for `GetiWire`

  修复`GetiWire()`在无法获取例化文件的情况下无法正常完成的问题

- Bug fixed for `GetaWire`

  修复`GetaWire()`多行无法获取的问题，例子如下

  ```verilog
  assign a = b | c | d |
      	   e | f | g;
  ```

- Bug fixed for `GetiSig`

  注释未完成的`GetSig()`，避免其异常问题

- Bug fixed for `GetIO`

  修复`GetIO()`在模块名或例化名后带注释(`//`)导致的获取模块名或例化名异常的问题

- Bug fixed for `GetReg`

  修复获取连续`reg`的异常问题（例如`reg a=1,b=3'd7;`）

### Changed

- Change keyboard click method for `RtlTree`

  更改`RtlTree`的键盘操作方式，点击`+`,`-`,`~`为展开至例化模块，普通点击为跳转至例化位置。



## [1.1.7] - 2021-08-13

### Added

- Add `GetaWire`，`GetiWire`

  新增`GetaWire()`以及`GetiWire()`函数，为`autowire`以及`autodef`做准备

### Fixed

- Bug fixed for `GetRightWidth`

  修复`GetRightWidth()`函数的部分遗留`bug`，完善其正则匹配机制



## [1.1.6] - 2021-08-02

### Added

- Add `RtlTree`

  新增`RtlTree()`，在原脚本（zhangguo）基础上进行如下改动
  
  1. 新增`tags`内部集成，不再需要外部`ctag_gen`脚本即自动生成
  2. 修复原脚本`:q`退出时无法再次进入的异常`Bug`
  3. 实现跨文件夹`RtlTree`功能



## [1.1.5] - 2021-08-01

### Changed

- Change configuration method for `AutoInst`, `AutoPara`, `AutoReg` & `AddHeader`

  更改现有函数的配置方式，可通过`.vimrc`外部配置



## [1.1.4] - 2021-07-21

### Added

- Add comment for `AutoInst`

  `AutoInst()`可配置添加注释例化模块所在位置`//Instance...<DIR>...`




## [1.1.3] - 2021-06-21

### Fixed

- Bug fixed for whole vim-scripts

  修复无法`source` 配置的`Bug`

- Bug fixed for `AutoReg`

  修复`AutoReg()`对重复多次相同写法（例如'a[3:0]+b[4:0]'）解析错误而产生的异常`Bug`



## [1.1.2] - 2021-06-12

### Added

- Add `AutoReg`

  新增 `AutoReg`初版

- Add`AUTOINST_TAIL_NOT_ALITN`, `AUTOPARA_TAIL_NOT_ALITN`, `AUTOREG_TAIL_NOT_ALITN`

  新增 `TAIL_NOT_ALIGN`特性，各种声明尾部可不进行统一对齐  


### Fixed

- Bug fixed for `AutoInst`

  添加`AutoInst()`对`verilog-1995`的支持，修复`AutoInst()`最后的因`)`而异常停止的`Bug`

### Changed

- Optimize `GetIO`, `GetPara`, `DrawIO`, `DrawPara`, `DrawVaraValue`

  优化写法，`GetIO()`, `GetPara()`, `DrawIO()`, `DrawPara()`, `DrawParaValue()`等函数添加注释及折叠，方便后续定位故障
  




## [1.1.1] - 2021-06-04

### Fixed

- Bug fixed for `AutoPara`

  修复`AutoPara()`最后的`port parameter`异常覆盖的`Bug`



## [1.1.0] - 2021-05-28
### Changed
- Optimize `AutoInst`& `AutoPara`

  优化`AutoInst` 以及 `AutoPara`部分内容

  - `AutoInst`

  1. 修复`AutoInst()`最后`port`被移入不变列表后无法获取最后一个`port`的`Bug`
  2. 修复`AutoInst()`获取端口列表外的`//`注释或`ifdef`的问题

  - `AutoPara`

  1. `AutoPara()`的最后一个参数的判断统一移动至`GetPara()`函数内
  2. `AutoPara()`传参格式变动，修改部分注释
  4. 对照`AutoPara`已知的问题，修改`AutoParaValue`

  - `Other`

  1. 针对末尾行尾注释`//`行时报错的问题，添加更明显的报错提醒




## [1.0.8] - 2021-05-19
### Added
- Add `ifdef` for `AutoInst`, add config for `ifdef` and single comment line`//`

  新增 `AutoInst()`对`ifdef`以及`//`注释的支持，添加对`//`注释以及`ifedf`的可配置项

### Fixed
- Bug fixed for `AutoInst`

  修复`AutoInst()`最后`port`判断异常`Bug`



## [1.0.7] - 2021-05-18
### Added
- Add keep changed inst io name for  `AutoInst`

   `AutoInst()`新增修改后的端口不重刷功能



## [1.0.6] - 2021-05-15
### Added
- Add new `AutoPara` & modified original `AutoPara` to `AutoParaValue`, use `/*autoinstparam*/` & `/*autoinstparam_value*/` as flag

  `AutoPara()`函数拆分为`AutoPara()`以及`AutoParaValue`, 分别使用`/*autoinstparam*/`以及`/*autoinstparam_value*/`作为检测条件

### Fixed

- Bug fixed for `AutoPara`

  修复`AutoPara()`最后的`parameter`判断异常`Bug`



## [1.0.5] - 2021-05-08
### Changed
- Compatible with `vim 7.4`

  兼容旧版`vim v7.4`

  1. 不再使用`readdir()`函数，改为使用`glob()`、`filter()`以及`fnamemodify()`；

  2. `filter()`写法由`lambda`改为普通`string`的写法；

  3. `GetIO`函数的`signal_name`不再使用空符号`''`，统一使用`NULL`。避免`dictionary`出现`key`为空；

  4. `call deletebufline('%',idx)`改为`execute ':'.idx.'d'`，由于`execute`会移动光标位置，添加光标位置跳回

  5. ~~`sort(...,'N')`改为`sort(...,'n')`~~ `sort(...,'N')`改为`sort(Str2Num(...),'n')`，添加单独的转换函数

  6. 修复`AutoPara`在`ONLY_PORT=0`时无法获取（没有端口参数，只有声明参数的情况）参数列表的`Bug`

     > 依据来源：
     >
     > [vimscript - How to find a executable file inside a folder? - Vi and Vim Stack Exchange](https://vi.stackexchange.com/questions/20260/how-to-find-a-executable-file-inside-a-folder)
     >
     > [vimrc - Get directory name from CWD (dirname without preceding path)? - Vi and Vim Stack Exchange](https://vi.stackexchange.com/questions/15046/get-directory-name-from-cwd-dirname-without-preceding-path)



## [1.0.4] - 2021-04-30

### Added

- Add `,` feature for `AutoPara`

  `AutoPara()` 添加支持`,`特性

### Fixed
- Bug fixed for  `AutoPara`

  修复`AutoPara()`末尾丢失`,`的bug



## [1.0.3] - 2021-04-24

### Changed
- Add read `.sv` file 

  简单添加对`.sv`文件的支持，但仍然只支持`verilog`的写法



## [1.0.2] - 2021-04-19

### Added
- Add `GetReg`

  新增`GetReg()`



## [1.0.1] - 2021-04-05

### Added
- Add `AutoInst` & `Autopara`

  新增 `AutoInst()` 以及 `AutoPara()` 初版



## [1.0.0] - 2021-03-26

### Added
- First copy from zhangguo's vimscript. See [automatic for Verilog & RtlTree - Automatic generator for Verilog HDL (upgraded) & RtlTree : vim online](https://www.vim.org/scripts/script.php?script_id=4067)

  复制原脚本，参考原结构开始进行重构