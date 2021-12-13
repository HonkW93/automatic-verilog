# automatic-verilog

---

```verilog
 ______     __  __     ______   ______     __    __     ______     ______   __     ______    
/\  __ \   /\ \/\ \   /\__  _\ /\  __ \   /\ "-./  \   /\  __ \   /\__  _\ /\ \   /\  ___\   
\ \  __ \  \ \ \_\ \  \/_/\ \/ \ \ \/\ \  \ \ \-./\ \  \ \  __ \  \/_/\ \/ \ \ \  \ \ \____  
 \ \_\ \_\  \ \_____\    \ \_\  \ \_____\  \ \_\ \ \_\  \ \_\ \_\    \ \_\  \ \_\  \ \_____\ 
  \/_/\/_/   \/_____/     \/_/   \/_____/   \/_/  \/_/   \/_/\/_/     \/_/   \/_/   \/_____/ 
                                                                                             
 __   __   ______     ______     __     __         ______     ______                         
/\ \ / /  /\  ___\   /\  == \   /\ \   /\ \       /\  __ \   /\  ___\                        
\ \ \'/   \ \  __\   \ \  __<   \ \ \  \ \ \____  \ \ \/\ \  \ \ \__ \                       
 \ \__|    \ \_____\  \ \_\ \_\  \ \_\  \ \_____\  \ \_____\  \ \_____\                      
  \/_/      \/_____/   \/_/ /_/   \/_/   \/_____/   \/_____/   \/_____/                      
                                                                                             
```

一款基于vimscript的自动化verilog脚本。由[automatic for Verilog & RtlTree](https://www.vim.org/scripts/script.php?script_id=4067)修改而来，原作者zhangguo。

[![Release-Version](https://img.shields.io/badge/Release-1.2.5-blue.svg)](https://github.com/HonkW93/automatic-verilog/releases)-[![Vim-Version](https://img.shields.io/badge/Vim-7.4.629-green.svg)](https://www.vim.org/download.php)

## 1. 安装

### 1.1 简洁安装

将`automatic.vim`放入`vim`根目录下的`plugin`文件夹即可。

### 1.2  vim-plug

```
Plug 'HonkW93/automatic-verilog'
```

### 1.3  Vundle

```
Plugin 'HonkW93/automatic-verilog'
```

**提示：此脚本可能会修改文本数据，请在使用前备份数据，防止数据覆盖等情况发生。**

 ## 2. 特性

### 2.1 自动化

- 自动例化（`AutoInst`）

  - [x] 支持跨文件夹搜索.v文件进行例化，支持文件夹递归（参考`emacs verilog-mode`）

  - [x] 支持端口重刷（参考`emacs verilog-mode`）

  - [x] 支持行尾自动添加端口类型`input/output/inout` （参考`vim automatic-verilog`）

  - [x] 支持新增端口自动添加`//INST_NEW`（参考`vim automatic-verilog`）

  - [x] 支持删除端口自动添加`//INST_DEL`（参考`vim automatic-verilog`）

  - [x] 支持例化文件名与模块名不同的模块

  - [x] 支持配置为修改端口自动不重刷

  - [x] 支持`` `ifdef``及`` `endif``

  - [ ] 支持载入`filelist`

  - [ ] 支持载入`tags`
- 自动参数（`AutoPara`）
  - [x] 支持跨文件夹搜索.v文件进行例化，支持文件夹递归（参考`emacs verilog-mode`）

  - [x] 支持参数重刷（参考`emacs verilog-mode`）

  - [x] 支持新增端口自动添加`//PARA_NEW`（参考`vim automatic-verilog`）

  - [x] 支持删除端口自动添加`//PARA_DEL`（参考`vim automatic-verilog`）

  - [x] 支持`parameter`连续多个的写法，例如`parameter A = 1, B = 5, C = 6`

  - [x] 支持配置为`.A(A)`或者`.A(5)`的写法

  - [x] 支持配置为修改过的参数自动不重刷

  - [x] 支持`` `ifdef``及`` `endif``
- 自动寄存器（`AutoReg`）

  - [x] 支持端口`output reg`覆盖定义（参考`emacs verilog-mode`）

  - [x] 支持`always`语句阻塞/非阻塞赋值`reg`获取（参考`vim automatic-verilog`）
    - [x] 支持左端`{}`写法，但不支持此写法获取位宽

    - [x] 支持左端`[WIDTH1:WIDTH2]`写法

    - [ ] 支持右端`16'd1`或 `2'b01`或 `4'hf`或<code>`WIDTH'hf</code>写法（可解析，但暂不支持<code>merge</code>）

    - [ ] 支持右端`[WIDTH-1:0]`或 `[2*3-1:0]`或`[WIDTH1:WIDTH2]`写法（可解析，但暂不支持<code>merge</code>）

    - [ ] 支持右端`signal_a`或 `~signal_a`或`！signal_a`写法（可解析，但暂不支持<code>merge</code>）

    - [ ] 支持右端`signal_a & signal_b | signal_c[2:0]`写法（可解析，但暂不支持<code>merge</code>）

    - [ ] 支持右端`en ? signal_b : signal_c[2:0]`写法（可解析，但暂不支持<code>merge</code>）

    - [ ] 支持右端`{}`写法（可解析，但暂不支持<code>merge</code>）

    - [ ] 进行中...
- 自动线网（`AutoWire`）

  - [x] 支持例化`inst_wire`自动获取

  - [x] 支持`assign`语句`wire`自动获取

  - [ ] 支持获取特性与自动reg相同

  - [ ] 进行中...
- 自动定义（`AutoDef`） 

  - [x] 支持`AutoWire`

  - [x] 支持`AutoReg`

  - [ ] 支持多信号`merge`

  - [ ] 进行中...
- 自动声明（`AutoArg`）
  - [x] 支持`io`分类（参考`vim automatic-verilog`）
  - [ ] 支持`` `ifdef``及`` `endif``
- 对齐（`Align`）
  - [x] 所有自动化对齐格式宽度可调
- 自动接口（`AutoInterface`）

  - [ ] 梳理`sv`中`interface`的自动例化
  - [ ] 梳理中...
- 其他（`Other`）

  - [ ] 梳理`emacs verilog-mode`中其他`auto`函数...
- [ ] 梳理中...

### 2.2 Rtl 树

- 通过`RtlTree`浏览`Rtl`结构

  - [x] 支持跨文件夹

  - [x] 支持使用内部集成`tag`

  - [ ] 支持使用外部加载`tag`

## 3. 演示

### 3.1 AutoInst

![autoinst](https://cdn.jsdelivr.net/gh/HonkW93/automatic-verilog@master/demo/autoinst.gif)

### 3.2 AutoPara

![autopara](https://cdn.jsdelivr.net/gh/HonkW93/automatic-verilog@master/demo/autopara.gif)

### 3.3 AutoParaValue

![autoparavalue](https://cdn.jsdelivr.net/gh/HonkW93/automatic-verilog@master/demo/autoparavalue.gif)

### 3.4 AutoReg

![autoreg](https://cdn.jsdelivr.net/gh/HonkW93/automatic-verilog@master/demo/autoreg.gif)

### 3.5 AutoWire

![autowire](https://cdn.jsdelivr.net/gh/HonkW93/automatic-verilog@master/demo/autowire.gif)

### 3.6 AutoDef

![autodef](https://cdn.jsdelivr.net/gh/HonkW93/automatic-verilog@master/demo/autodef.gif)

### 3.7 AutoArg

![autoarg](https://cdn.jsdelivr.net/gh/HonkW93/automatic-verilog@master/demo/autoarg.gif)

## 4. 文档

[Vimcript-AutoMatic | HonkW](https://blog.honk.wang/posts/AutoMatic/)


## 5. 更新

[Update](/Changelog.md)


## 6. 开源协议

[GPL V3.0](/LICENSE)