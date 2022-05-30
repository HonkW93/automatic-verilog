# automatic-verilog

---

![logo](https://cdn.jsdelivr.net/gh/HonkW93/automatic-verilog@master/demo/logo.png)                                                                                   

一款基于vimscript的自动化verilog脚本。由[automatic for Verilog & RtlTree](https://www.vim.org/scripts/script.php?script_id=4067)修改而来，原作者zhangguo。部分功能参考[Verilog-Mode](https://veripool.org/verilog-mode/)。

[![Release](https://img.shields.io/github/v/release/HonkW93/automatic-verilog?display_name=tag)](https://github.com/HonkW93/automatic-verilog/releases)[![Vim-Version](https://img.shields.io/badge/Vim-7.4.629-green.svg)](https://www.vim.org/download.php)[![License](https://img.shields.io/github/license/HonkW93/automatic-verilog)](https://github.com/HonkW93/automatic-verilog/blob/master/LICENSE)![stars](https://img.shields.io/github/stars/HonkW93/automatic-verilog)![forks](https://img.shields.io/github/forks/HonkW93/automatic-verilog)



## 1. 安装

### 1.1 简洁安装

将`plugin`文件夹中`全部文件及文件夹`放入`vim`根目录下的`plugin`文件夹即可。

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

### 2.1 时序图

- 支持时序图绘制（`TimeWave`）

### 2.2 代码段

- 支持快速插入代码段（`Snippet`）
- 支持自动生成标准文件头（`Header`）
- 支持快速注释（`Comment`）

### 2.3 自动化

- 自动例化（`AutoInst`）
- 自动参数（`AutoPara`）
- 自动寄存器（`AutoReg`）
- 自动线网（`AutoWire`）
- 自动定义（`AutoDef`） 
- 自动声明（`AutoArg`）

### 2.4 Rtl 树

- 通过`RtlTree`浏览`Rtl`结构

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