# automatic-verilog

---

![logo](https://cdn.jsdelivr.net/gh/HonkW93/automatic-verilog@master/demo/logo.png)                                                                                   

An automatic verilog script based on vimscript. Modified from zhangguo's [automatic for Verilog & RtlTree](https://www.vim.org/scripts/script.php?script_id=4067). Some features refer to [Verilog-Mode](https://veripool.org/verilog-mode/)。

[![Release](https://img.shields.io/github/v/release/HonkW93/automatic-verilog?display_name=tag)](https://github.com/HonkW93/automatic-verilog/releases)[![Vim-Version](https://img.shields.io/badge/Vim-7.4.629-green.svg)](https://www.vim.org/download.php)[![License](https://img.shields.io/github/license/HonkW93/automatic-verilog)](https://github.com/HonkW93/automatic-verilog/blob/master/LICENSE)![stars](https://img.shields.io/github/stars/HonkW93/automatic-verilog)![forks](https://img.shields.io/github/forks/HonkW93/automatic-verilog)

[中文](./README.md) | [English](./README_en.md)

## 1. Install

### 1.1 Simple Install

Put all `files&folders` in `plugin` into the `plugin` folder under the root directory of `vim`.

### 1.2  vim-plug

```
Plug 'HonkW93/automatic-verilog'
```

### 1.3  Vundle

```
Plugin 'HonkW93/automatic-verilog'
```

**Note：This script may modify context, please backup your context befroe using in case overwriting**

 ## 2. Feature

### 2.1 TimeWave

- Support timewave drawing（`TimeWave`）

### 2.2 Code Snippet

- Support quick code snippet（`Snippet`）
- Support automatic generation of standard file header（`Header`）
- Support quick comment（`Comment`）

### 2.3 Automatic

- `AutoInst`
- `AutoPara`
- `AutoReg`
- `AutoWire`
- `AutoDef`
- `AutoArg`

### 2.4 Rtl  Tree

- Browse Rtl structure through `RtlTree`

## 3. Demo

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

### 3.8 RtlTree

![rtl](https://cdn.jsdelivr.net/gh/HonkW93/automatic-verilog@master/demo/rtl.gif)

## 4. Doc

[Vimcript-AutoMatic | HonkW](https://blog.honk.wang/posts/AutoMatic/)


## 5. Update

[Update](/Changelog.md)


## 6. License

[GPL V3.0](/LICENSE)