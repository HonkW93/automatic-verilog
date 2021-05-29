# Changelog
All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).



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

  新增 `AutoInst`对`ifdef`以及`//`注释的支持，添加对`//`注释以及`ifedf`的可配置项

### Fixed
- Bug fixed for `AutoInst`

  修复`AutoInst()`最后`port`判断异常`Bug`

## [1.0.7] - 2021-05-18
### Added
- Add keep changed inst io name 

  新增修改后的端口不重刷功能

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

  `AutoPara` 添加支持`,`特性

### Fixed
- Bug fixed for  `AutoPara`

  修复`AutoPara`末尾丢失`,`的bug

## [1.0.3] - 2021-04-24
### Changed
- Add read `.sv` file 

  简单添加对`.sv`文件的支持，但仍然只支持`verilog`的写法

## [1.0.2] - 2021-04-19
### Added
- Add `GetReg`

  新增`GetReg`

## [1.0.1] - 2021-04-05
### Added
- Add `AutoInst` & `Autopara`

  新增 `AutoInst` 以及 `AutoPara` 初版

## [1.0.0] - 2021-03-26
### Added
- First copy from zhangguo's vimscript. See [automatic for Verilog & RtlTree - Automatic generator for Verilog HDL (upgraded) & RtlTree : vim online](https://www.vim.org/scripts/script.php?script_id=4067)

  复制原脚本，参考原结构开始进行重构