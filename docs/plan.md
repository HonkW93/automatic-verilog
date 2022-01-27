## 自动化功能

### 自动例化-AutoInst

- [x] 支持`/*autoinst*/`下方端口重刷（参考`emacs verilog-mode`）
- [x] 支持修改端口后不重刷
- [x] 支持行尾自动添加端口类型`input/output/inout` （参考原脚本）
- [x] 支持新增端口自动添加`//INST_NEW`（参考原脚本）
- [x] 支持删除端口自动添加`//INST_DEL`（参考原脚本）
- [x] 支持例化文件名与模块名不同的模块
- [x] 支持例化注释，`` `ifdef``及`` `endif``
- [x] 支持`verilog-1995`写法
- [x] 支持添加例化模块全局地址`//Instance ...directory...`
- [ ] 支持自定义配置添加的内容（`input/output -> I/O`）
- [ ] ...

### 自动参数-AutoPara

- [x] 支持`/*autoinstparam*/`下方端口重刷（参考`emacs verilog-mode`）
- [x] 支持修改端口后不重刷
- [x] 支持配置为`.A(A)`或者`.A(5)`的写法(`/*autoinstparam*/`及`/*autoinstparam_value*/`，参考`emacs verilog-mode`）
- [x] 支持新增端口自动添加`//PARA_NEW`（参考原脚本）
- [x] 支持删除端口自动添加`//PARA_DEL`（参考原脚本）
- [x] 支持例化注释，`` `ifdef``及`` `endif``
- [x] 支持`parameter`连续多个的写法，例如`parameter A = 1, B = 5, C = 6`
- [ ] ...

### 自动寄存器-AutoReg&自动线网-AutoWire&自动定义-AutoDef

- [x] 支持端口`io`覆盖定义（参考`emacs verilog-mode`）
- [x] 支持`always`语句阻塞/非阻塞赋值`reg`获取，支持`assign`语句`wire`自动获取（参考原脚本）
  - [x] 支持左端`{}`写法，但不支持此写法获取位宽
  - [x] 支持左端`[WIDTH1:WIDTH2]`写法
  - [ ] 支持右端<code>merge</code>![](data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyB3aWR0aD0iOTAiIGhlaWdodD0iMjAiIHZlcnNpb249IjEuMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pZFlNaWQiPgogIDxsaW5lYXJHcmFkaWVudCBpZD0iYSIgeDI9IjAiIHkyPSIxMDAlIj4KICAgIDxzdG9wIG9mZnNldD0iMCIgc3RvcC1jb2xvcj0iI2JiYiIgc3RvcC1vcGFjaXR5PSIuMSIvPgogICAgPHN0b3Agb2Zmc2V0PSIxIiBzdG9wLW9wYWNpdHk9Ii4xIi8+CiAgPC9saW5lYXJHcmFkaWVudD4KCiAgPHJlY3Qgcng9IjQiIHg9IjAiIHdpZHRoPSI5MCIgaGVpZ2h0PSIyMCIgZmlsbD0iIzQyOGJjYSIvPgogIDxyZWN0IHJ4PSI0IiB4PSIwIiB3aWR0aD0iOTAiIGhlaWdodD0iMjAiIGZpbGw9IiM1NTUiIC8+CiAgPHJlY3Qgcng9IjQiIHg9IjAiIHdpZHRoPSI5LjAiIGhlaWdodD0iMjAiIGZpbGw9IiNkOTUzNGYiIC8+CiAgCiAgPHJlY3Qgcng9IjQiIHdpZHRoPSI5MCIgaGVpZ2h0PSIyMCIgZmlsbD0idXJsKCNhKSIgLz4KCiAgCgogIDxnIGZpbGw9IiNmZmYiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGZvbnQtZmFtaWx5PSJEZWphVnUgU2FucyxWZXJkYW5hLEdlbmV2YSxzYW5zLXNlcmlmIiBmb250LXNpemU9IjExIj4KICAgIDx0ZXh0IHg9IjQ1LjAiIHk9IjE1IiBmaWxsPSIjMDEwMTAxIiBmaWxsLW9wYWNpdHk9Ii4zIj4KICAgICAgMTAlCiAgICA8L3RleHQ+CiAgICA8dGV4dCB4PSI0NS4wIiB5PSIxNCI+CiAgICAgIDEwJQogICAgPC90ZXh0PgogIDwvZz4KPC9zdmc+)
- [x] 支持例化`inst_wire`自动获取
- [x] `AutoDef`支持移动已有`reg`和`wire`声明
- [ ] ...

### 自动声明-AutoArg

- [x] 支持`io`分类（参考原脚本）
- [ ] 支持`` `ifdef``及`` `endif``

### 位置对齐-Align

- [x] 所有自动化对齐格式宽度可调

### 跨文件夹-CrossDir

- [x] 支持跨文件夹搜索.v文件进行例化，支持文件夹递归（参考`emacs verilog-mode`）
- [ ] 支持载入`filelist`跨文件夹（参考`emacs verilog-mode`，新增`browse`模式添加）![](data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyB3aWR0aD0iOTAiIGhlaWdodD0iMjAiIHZlcnNpb249IjEuMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pZFlNaWQiPgogIDxsaW5lYXJHcmFkaWVudCBpZD0iYSIgeDI9IjAiIHkyPSIxMDAlIj4KICAgIDxzdG9wIG9mZnNldD0iMCIgc3RvcC1jb2xvcj0iI2JiYiIgc3RvcC1vcGFjaXR5PSIuMSIvPgogICAgPHN0b3Agb2Zmc2V0PSIxIiBzdG9wLW9wYWNpdHk9Ii4xIi8+CiAgPC9saW5lYXJHcmFkaWVudD4KCiAgPHJlY3Qgcng9IjQiIHg9IjAiIHdpZHRoPSI5MCIgaGVpZ2h0PSIyMCIgZmlsbD0iIzQyOGJjYSIvPgogIDxyZWN0IHJ4PSI0IiB4PSIwIiB3aWR0aD0iOTAiIGhlaWdodD0iMjAiIGZpbGw9IiM1NTUiIC8+CiAgPHJlY3Qgcng9IjQiIHg9IjAiIHdpZHRoPSIyNy4wIiBoZWlnaHQ9IjIwIiBmaWxsPSIjZjBhZDRlIiAvPgogIAogIDxyZWN0IHJ4PSI0IiB3aWR0aD0iOTAiIGhlaWdodD0iMjAiIGZpbGw9InVybCgjYSkiIC8+CgogIAoKICA8ZyBmaWxsPSIjZmZmIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LWZhbWlseT0iRGVqYVZ1IFNhbnMsVmVyZGFuYSxHZW5ldmEsc2Fucy1zZXJpZiIgZm9udC1zaXplPSIxMSI+CiAgICA8dGV4dCB4PSI0NS4wIiB5PSIxNSIgZmlsbD0iIzAxMDEwMSIgZmlsbC1vcGFjaXR5PSIuMyI+CiAgICAgIDMwJQogICAgPC90ZXh0PgogICAgPHRleHQgeD0iNDUuMCIgeT0iMTQiPgogICAgICAzMCUKICAgIDwvdGV4dD4KICA8L2c+Cjwvc3ZnPg==)
- [ ] 支持载入`tags`跨文件夹![](data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyB3aWR0aD0iOTAiIGhlaWdodD0iMjAiIHZlcnNpb249IjEuMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pZFlNaWQiPgogIDxsaW5lYXJHcmFkaWVudCBpZD0iYSIgeDI9IjAiIHkyPSIxMDAlIj4KICAgIDxzdG9wIG9mZnNldD0iMCIgc3RvcC1jb2xvcj0iI2JiYiIgc3RvcC1vcGFjaXR5PSIuMSIvPgogICAgPHN0b3Agb2Zmc2V0PSIxIiBzdG9wLW9wYWNpdHk9Ii4xIi8+CiAgPC9saW5lYXJHcmFkaWVudD4KCiAgPHJlY3Qgcng9IjQiIHg9IjAiIHdpZHRoPSI5MCIgaGVpZ2h0PSIyMCIgZmlsbD0iIzQyOGJjYSIvPgogIDxyZWN0IHJ4PSI0IiB4PSIwIiB3aWR0aD0iOTAiIGhlaWdodD0iMjAiIGZpbGw9IiM1NTUiIC8+CiAgPHJlY3Qgcng9IjQiIHg9IjAiIHdpZHRoPSIxOC4wIiBoZWlnaHQ9IjIwIiBmaWxsPSIjZDk1MzRmIiAvPgogIAogIDxyZWN0IHJ4PSI0IiB3aWR0aD0iOTAiIGhlaWdodD0iMjAiIGZpbGw9InVybCgjYSkiIC8+CgogIAoKICA8ZyBmaWxsPSIjZmZmIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LWZhbWlseT0iRGVqYVZ1IFNhbnMsVmVyZGFuYSxHZW5ldmEsc2Fucy1zZXJpZiIgZm9udC1zaXplPSIxMSI+CiAgICA8dGV4dCB4PSI0NS4wIiB5PSIxNSIgZmlsbD0iIzAxMDEwMSIgZmlsbC1vcGFjaXR5PSIuMyI+CiAgICAgIDIwJQogICAgPC90ZXh0PgogICAgPHRleHQgeD0iNDUuMCIgeT0iMTQiPgogICAgICAyMCUKICAgIDwvdGV4dD4KICA8L2c+Cjwvc3ZnPg==)

### 树状拓扑-RtlTree

- [x] 支持使用内部集成`tag`
- [ ] 支持使用外部加载`tag`
- [ ] 结构优化
- [ ] ...

## 优化

- [x] 脚本文件按功能分离
- [x] 配置方式优化（参考[vim-syntastic](https://github.com/vim-syntastic/syntastic)）
- [ ] 减少全局函数使用（参考`help`，使用`command`/`hasmapto`/`<Plugin>`/`<SID>`等方法映射函数，尽量避免全局函数）
- [x] 代码生成插件`snippet.vim`独立后集成[load_template](https://github.com/vim-scripts/load_template)
- [ ] `vim`文档添加`vim-doc`
- [ ] `docsify`文档添加英文支持
- [x] 基于[Learn Vimscript the Hard Way](https://learnvimscriptthehardway.stevelosh.com/)的部分优化
- [ ] ...

## 修复

- [ ] `AutoInst`修复`` `ifdef``及`` `endif``的末尾判断问题
- [ ] `AutoDef`纯数字的位宽引用问题
- [ ] `System Verilog`部分优化项
- [ ] ...

  



