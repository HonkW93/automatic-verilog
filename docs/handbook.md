# 使用手册

使用手册包含操作步骤和一些特性。使用前请按照快速上手的安装步骤保证脚本正确安装。

## 时序图-TimeWave

---

> 绘制简单的时序图

![TimeWaveDemo](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/timewave-demo.gif)

### 操作步骤

> 关于`Leader`请参考[Leaders / Learn Vimscript the Hard Way (stevelosh.com)](https://learnvimscriptthehardway.stevelosh.com/chapters/06.html)或[Vim快捷键和前缀键Leader-Vim入门教程(29) | vim教程网 (vimjc.com)](https://vimjc.com/vim-leader.html)
>
> `vim`默认`Leader`为`\`。所以默认不配置，绘制时钟`clk`的快捷键即为`\clk`。作者习惯的`Leader`为`;`。所以作者绘制时钟`clk`的快捷键是`;clk`

1. 绘制时序图

   <details>
   
   <summary>绘制信号</summary>

   - 绘制时钟`clk`：使用快捷键生成时钟信号。默认快捷键为`<Leader>clk`。
   - 绘制单线`sig`：使用快捷键生成单线信号。默认快捷键为`<Leader>sig`。
   - 绘制总线`bus`：使用快捷键生成总线信号。默认快捷键为`<Leader>bus`。
   - 绘制间隔`blk`：使用快捷键生成空间隔行。默认快捷键为`<Leader>blk`。
   - 绘制翻转`neg`：使用快捷键生成翻转标记。默认快捷键为`<Leader>neg`。
   - 翻转信号`inv`：按时钟沿翻转当前的`sig`/`bus`信号。默认快捷键为`<Leader>inv`。翻转，即是根据现在信号`sig`的状态创造一个新的`0/1`状态（可以理解为上升沿触发，或者下降沿触发）。总线`bus`的翻转同理。

   </details>

2. 属性配置

   <details>
   
   <summary>可配属性</summary>

   - `g:atv_timewave_sig_offset`：信号的偏移量，默认为`13`。
   - `g:atv_timewave_clk_period`：时钟周期宽度，默认为`8`。
   - `g:atv_timewave_clk_num`：时钟个数，默认为`16`。
   - `g：atv_timewave_cq_trans`：信号第一个上升沿（或下降沿，根据末端是否有`neg`标志决定）距离时钟的距离，即信号**延迟**，默认为`1`。

   可通过在`.vimrc(or _vimrc)`中配置相关`global`参数实现配置（以`clk_num`为例）

   ```javascript
   let g:atv_timewave_clk_num = 32
   ```

   ![TimeWaveConfig](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/timewave_config.png)

   </details>

3. 快捷键

   <details>
   <summary>快捷键</summary>
   
   默认快捷键如下：
   
- `<Leader>clk`：绘制时钟`clk`
   - `<Leader>sig`：绘制单线`sig`
   - `<Leader>bus`：绘制总线`bus`
   - `<Leader>blk`：绘制间隔`blk`
   - `<Leader>neg`：绘制翻转`neg`
   - `<Leaderinv`：翻转信号`inv`
   
如果希望自行设定快捷键，可配置快捷键如下：
   
- `<Plug>Atv_Timewave_AddClk;`：绘制时钟`clk`
   - `<Plug>Atv_Timewave_AddSig;`：绘制单线`sig`
   - `<Plug>Atv_Timewave_AddBus;`：绘制总线`bus`
   - `<Plug>Atv_Timewave_AddBlk;`：绘制间隔`blk`
- `<Plug>Atv_Timewave_AddNeg;`：绘制翻转`neg`
   - `<Plug>Atv_Timewave_Invert;`：翻转信号`inv`
   
   可通过在`.vimrc(or _vimrc)`中配置相关`Plug`快捷键实现配置（以绘制时钟`clk`为例，配置快捷键为`;clock`）
   
   ```javascript
   map ;clock <Plug>Atv_Timewave_AddClk;
   ```
   
   </details>

## 代码段-Snippet

---

> ⚠️注意：旧版代码中代码段功能的配置项与新版不同（不兼容），请升版至新版后根据下述配置项重新进行配置。
>

### 快速生成文件头

![HeaderDemo](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/header_demo.gif)

1. 文件头内容

   <details>
   
   <summary>文件头</summary>
   
   文件头可配置内容如下：

   - 文件头标记`+FHDR`以及`-FHDR`，用于标记文件头起始，请勿删除
   - 文件名`Project Name`，配置参数为`g:atv_snippet_project`。假设不需要此选项请配置为`''`，如不配置则自动采用默认配置。可通过在`.vimrc(or _vimrc)`中配置相关`global`参数实现配置（以`project`为例，假设项目名为`FPGA_Design`）。

     ```javascript
     let g:atv_snippet_project = 'FPGA_Design'
     ```

   - 公司名`Company Name`，配置参数为`g:atv_snippet_company`。假设不需要此选项请配置为`''`，如不配置则自动采用默认配置。配置方法同上。
   - 器件名`Device Name`，配置参数为`g:atv_snippet_device`。假设不需要此选项请配置为`''`，如不配置则自动采用默认配置。配置方法同上。
   - 作者名`Author Name`，配置参数为`g:atv_snippet_author`。假设不需要此选项请配置为`''`，如不配置则自动采用默认配置。配置方法同上。
   - 电邮名`Email Name`，配置参数为`g:atv_snippet_email`。假设不需要此选项请配置为`''`，如不配置则自动采用默认配置。配置方法同上。
   - 网站名`Website Name`，配置参数为`g:atv_snippet_website`。假设不需要此选项请配置为`''`，如不配置则自动采用默认配置。配置方法同上。
   - 生成时间`Created On`，根据当前时间自动生成，必生成项。
   - 修改时间`Last Modified`，根据每一次更改自动更新，必生成项，且在修改文件时自动更新
   - 文件名`File Name`，根据当前文件名自动生成。必生成项。
   - 公司名`Company Name`，配置参数为`g:atv_snippet_company`。假设不需要此选项请配置为`''`，如不配置则自动采用默认配置。此项会生成公司版权声明。配置方法同上。
   - 修改历史`History`，自动生成初版的历史声明。

   </details>

2. 快捷键

   <details>
   
   <summary>快捷键</summary>
   
   默认快捷键为`<Leader>hd`。如果希望自行设定快捷键，可配置快捷键如下：

   - `<Plug>Atv_Snippet_AddHeader;`

   可通过在`.vimrc(or _vimrc)`中配置相关`Plug`快捷键实现配置（配置快捷键为`;header`）

   ```javascript
   map ;header <Plug>Atv_Snippet_AddHeader;
   ```

   </details>

### 快速注释

![CommentDemo](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/cmt_demo.gif)

1. 快速注释分为三种

   <details>

   <summary>快速注释</summary>

   - 当行修改为注释
     使用快捷键快速注释或取消注释当前行。
   - 选中行改为注释
     使用快捷键快速注释或取消注释`visual`模式下的选中行。
   - 行末尾添加注释
     使用快捷键快速在尾部添加注释。
     

   </details>

2. 快捷键
   <details>
   
   <summary>快捷键</summary>
   
   - 当行修改为注释

     默认快捷键为`<Leader>//`。如果希望自行设定快捷键，可配置快捷键如下：

     - `<Plug>Atv_Snippet_AutoComment;`

     可通过在`.vimrc(or _vimrc)`中配置相关`Plug`快捷键实现配置（配置快捷键为`;cmt`）

     ```javascript
     nmap ;cmt <Plug>Atv_Snippet_AutoComment;
     ```

   - 选中行改为注释

     默认快捷键为`<Leader>//`（与上一项相同，因为模式不同）。如果希望自行设定快捷键，可配置快捷键如下：

     - `<Plug>Atv_Snippet_AutoComment2;`

     可通过在`.vimrc(or _vimrc)`中配置相关`Plug`快捷键实现配置（配置快捷键为`;cmt`）

     ```javascript
     vmap ;cmt <Plug>Atv_Snippet_AutoComment2;
     ```

   - 行末尾添加注释

     默认快捷键为`<Leader>/e`。如果希望自行设定快捷键，可配置快捷键如下：

     - `<Plug>Atv_Snippet_AddCurLineComment;`

     配置方法同当行修改为注释。
   </details>

3. 添加项

   快速注释会添加作者名，采用的配置参数为`g:atv_snippet_author`。配置方法见快速生成文件头部分的说明。

### 快速always

![AlwaysDemo](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/always_demo.gif)

   <details>

   <summary>快速always</summary>

操作方法类似自动生成文件头，使用快捷键快速生成`always`块。默认快捷键为`<Leader>al`。同时对于`Gvim`可以使用菜单栏生成的方式。快速生成的`always`块分为以下几种类型：

- `AlBpp`：`always block posedge clock posedge reset`

- `AlBpn`：`always block posedge clock negedge reset`

- `AlB`：`always block *`

- `AlBnn`：`always block negedge clock negedge reset`

- `AlBn`：`always block negedge clock`

- `AlBp`：`always block posedge clock`

1. 快捷键

   默认快捷键只能生成`AlBpp`对应的代码段。如果希望自行设定快捷键，可配置快捷键如下：

   - `<Plug>Atv_Snippet_AlBpp;`：生成`always block posedge clock posedge reset`
   - `<Plug>Atv_Snippet_AlBpn;`：生成`always block posedge clock negedge reset`
   - `<Plug>Atv_Snippet_AlB;`：生成`always block *`
   - `<Plug>Atv_Snippet_AlBnn;`：生成`always block negedge clock negedge reset`
   - `<Plug>Atv_Snippet_AlBn;`：生成`always block negedge clock`
   - `<Plug>Atv_Snippet_AlBp;`：生成`always block posedge clock`

   可通过在`.vimrc(or _vimrc)`中配置相关`Plug`快捷键实现配置（以生成`always block *`为例，配置快捷键为`A*`）生成块中的的文字可配置，可配置项如下：

   ```javascript
   map A* <Plug>Atv_Snippet_AlB;
   ```


2. 自定义文字

   可配置模板文字以及模板生成后的鼠标位置：

   - 配置模板位置（默认位置为脚本`plugin`文件夹下的`template`文件夹）

     - `atv_snippet_albpp_file`：默认`template`文件夹内`albpp.v`文件
     - `atv_snippet_albpn_file`：默认`template`文件夹内`albpn.v`文件
     - `atv_snippet_albnn_file`：默认`template`文件夹内`albnn.v`文件
     - `atv_snippet_albn_file`：默认`template`文件夹内`albn.v`文件
     - `atv_snippet_albp_file`：默认`template`文件夹内`albp.v`文件
     - `atv_snippet_alb_file`：默认`template`文件夹内`alb.v`文件

     例如配置`AlBpp`的模板在如下路径：

     ```javascript
     let g:atv_snippet_albpp_file = '~/Desktop/template/albpp.v'
     ```

     `albpp.v`内容设置如下：
     
     ```systemverilog
     always@(posedge clk or posedge rst)begin
     	if(rst==1'b1)begin
            
     	end
        	else begin
            
        	end
     end
     ```

   则可通过快捷键自动调用上述设置的模板。其他模板调用的使用方法相同。

   - 鼠标位置

     `atv_snippet_albpp_pos`：可配置`albpp.v`文件加载后鼠标所在位置。

     ```javascript
     //配置鼠标跳转至模板第4行，第13列
     let g:atv_snippet_albpp_pos = '4,13'
     ```
   ```
     
   其他模板配置鼠标所在位置的方法类似。
     
   ```




</details>

### 加载模板

如有其它需要自主加载的模板，可使用[vim-scripts/load_template](https://github.com/vim-scripts/load_template)插件。

### 新建载入模板

新建`.v`文件时自动载入预设模板（`AutoTemplate`）。

如需要此功能请在`.vimrc(or _vimrc)`中打开如下配置（默认关闭）。

```javascript
let g:atv_snippet_att_en = 0
```

预设模板可配置模板文字：`atv_snippet_att_file`：默认`template`文件夹内`auto_template.v`文件。

- 例如配置`AutoTemplate`的模板在如下路径：

  ```javascript
  let g:atv_snippet_att_file = '~/Desktop/template/template.v'
  ```

  `template.v`内容设置如下：

  ```systemverilog
  $header
  `timescale 1ns/1ps
  module $module_name
  (
  );
  endmodule
  ```

注意`template`有两个可选配置的特殊参数：

- `$header`，在首行识别到此标识后会自动生成文件头。
- `$module_name`，自动替换为当前文件名。

模板内容均可以自定义。

![AutoTemplate](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/autotemplate.gif)

## 自动例化-AutoInst

---

> 自动生成例化模块连接。

![AutoInst](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/autoinst.gif)

### 操作步骤

1. 写标志`/*autoinst*/`

   <details>
   
   <summary>写标志</summary>

   将要例化的模块写为如下格式：`module_name inst_name(/*autoinst*/);`

   > ⚠️注意
   >
   > - 格式末尾必须要有分号`;`
   > - 注意格式可不在同一行，只要`(/*autoinst*/)`包含在括号内，括号外为`module_name inst_name`即可；支持端口处带`parameter`的写法。

   **e.g.**

   ```verilog
   fetch fetch_inst ( /*autoinst*/ );
   ```

   

   ```verilog
   mem     u_mem(
       /*autoinst*/);
   ```

   

   ```verilog
   writeback 
   #(
       // Parameters
       .BMAN			(BMAN),
   )writeback_inst
   (
       .write_data			(write_data[31:0]),
       /*autoinst*/
   );
   ```
   
   </details>


2. 自动例化
   
   <details>
   
   <summary>自动例化</summary>

   - 使用菜单栏点击`AutoInst(0)`或在命令行输入`:call g:AutoInst(0)`确认，进行`/*autoinst*/`**当前模块**自动例化，注意例化时光标必须置于`/*autoinst*/`所在行之前的位置（即在当前行或上一行，若在当前行则必须在`/*autoinst*/`所在列之前）；

   - 使用菜单栏点击`AutoInst(1)`或在命令行输入`:call g:AutoInst(1)`确认，进行`/*autoinst*/`**所有模块**自动例化；
   - 上述操作也可以使用快捷键完成。
   
   </details>

3. 快捷键

   <details>
   <summary>快捷键</summary>
   
   
- 默认键盘快捷键为`<S-F3>`（`Shift+F3`），为避免脚本更新导致的快捷键变更，或想使用自定义快捷键，可通过在`.vimrc(or _vimrc)`中配置相关`mapping`实现覆盖配置。（假设配置为`;ati`）
  
```javascript
   map ;ati      :call g:AutoInst(0)<ESC>
```

   </details>

4. 配置参数 
   
   <details>
   
   <summary>配置参数</summary>
   
   通过配置脚本参数，可以
   
   1. 配置例化位置
   2. 添加一些`AutoInst`相关的标志：<code>//INST_NEW</code>、<code>//INST_DEL</code>、<code>io_dir</code>、注释<code>//</code>以及宏定义<code>`ifedf</code>
   
   > - 例化时默认的对齐位置，请参考[位置对齐-Align](#位置对齐-Align)
   > - 例化时默认自动在尾部添加`io_dir`，即端口类型`input/output/inout`（`g:atv_autoinst_io_dir`）
   > - 例化时默认若有端口更新，自动在该端口尾部添加`//INST_NEW`（`g:atv_autoinst_inst_new`）
   > - 例化时默认若有端口被删除，自动在所有端口例化之后添加`//INST_DEL`（`g:atv_autoinst_inst_del`）
   > - 例化时修改过端口连线的则保留，否则自动刷新（`g:atv_autoinst_keep_chg`）
   > - 例化时默认添加`//`类型注释（`g:atv_autoinst_incl_cmnt`）
   > - 例化时默认添加<code>`ifdef</code>类型的宏定义，包括<code>ifdef/elsif/else/endif</code>（<code>g:atv_autoinst_incl_ifdef</code>）
   > - 例化时支持`verilog-95`的写法（`g:atv_autoinst_95_support`）
   > - 例化时默认不添加例化模块文件所在位置<code>dir</code>，打开此配置会在例化模块之前一行添加`//Instance`+`dir`以显示例化模块所在的文件夹地址（`g:atv_autoinst_add_dir`）
   > - 例化时若添加了例化模块文件所在位置<code>dir</code>，使用原有的环境变量（如果有，例如`$HOME`）表述而不展开为详细目录（`g:atv_autoinst_add_dir_keep`）
   > - 例化时默认添加多`bit`信号的位宽，如不想添加，可关闭位宽添加（`g:atv_autoinst_incl_width`）
   
   可通过在`.vimrc(or _vimrc)`中配置相关`global`参数实现配置
   
   ```javascript
   let g:atv_autoinst_st_pos = 8
   let g:atv_autoinst_name_pos = 64 
   let g:atv_autoinst_sym_pos = 128
   let g:atv_autoinst_io_dir = 1
   let g:atv_autoinst_io_dir_name = 'I O IO' 
   let g:atv_autoinst_inst_new = 0
   let g:atv_autoinst_inst_del = 0
   let g:atv_autoinst_keep_chg = 1
   let g:atv_autoinst_incl_cmnt = 0
   let g:atv_autoinst_incl_ifdef = 0
   let g:atv_autoinst_95_support = 1
   let g:atv_autoinst_tail_nalign = 1
   let g:atv_autoinst_add_dir = 1
   let g:atv_autoinst_add_dir_keep = 1
   let g:atv_autoinst_incl_width = 0
   ```
   
   ![ati_mark_demo](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/ati_mark_demo.gif)

   </details>
   
5. 重刷

   <details>
   
   <summary>重刷</summary>

   - 自动保留`/*autoinst*/`上方的例化端口，只对其余端口进行自动例化。

   ![name&reinst](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/name&reinst.gif)

   - 如果配置`g:atv_autoinst_keep_chg=1`（默认为1），若端口连线更改，则不进行重刷，只进行端口对齐操作。

   ![reinst_with_conn_change](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/reinst_with_conn_change.gif)
   
   </details>



## 自动参数-AutoPara

---

> 自动生成例化参数连接。
>
> 操作逻辑基本同`AutoInst`一致，分为两种。
>
> 1. `AutoParaValue`，例化`parameter`的`值`，标志为`/*autoinstparam_value*/`。
> 2. `AutoPara`，例化`parameter`，标志为`/*autoinstparam*/`。

![autopara_normal](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/autopara_normal.gif)

![autopara_value](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/autopara_value.gif)

### 操作步骤

1. 写标志`/*autoinstparam*/`或`/*autoinstparam_value*/`

   整体操作与`AutoInst`一致，参考[AutoInst](#自动例化-AutoInst)

2. 自动例化参数

   整体操作与`AutoInst`一致，参考[AutoInst](#自动例化-AutoInst)

3. 快捷键

   <details>
   
   <summary>快捷键</summary>
   
   - `AutoPara`默认键盘快捷键为`<S-F4>`（`Shift+F4`）

   - `AutoParaValue`默认键盘快捷键为`<S-F5>`（`Shift+F5`）

   - 为避免脚本更新导致的快捷键变更，或想使用自定义快捷键，可通过在`.vimrc(or _vimrc)`中配置相关`mapping`实现覆盖配置。（假设配置为`;atp`和`;atpv`）
   
     ```javascript
     map ;atp      :call g:AutoPara(0)<ESC>
     map ;atpv     :call g:AutoParaValue(0)<ESC>
     ```
   
   </details>

4. 配置参数

   <details>
   
   <summary>配置参数</summary>
   
   通过配置脚本参数，可以

   1. 配置例化位置
   2. 添加一些`AutoPara`相关的标志：`//PARA_NEW` `//PARA_DEL`，注释`//`以及宏定义<code>ifedf</code>等
   
> - 例化时默认的对齐位置，请参考[位置对齐-Align](http://localhost:3000/#/handbook?id=位置对齐-align)
   > - 例化时配置使用`端口`参数例化或使用`所有`参数进行例化。（`g:atv_autopara_only_port`）
> - 例化时默认若有参数更新，自动在该端口尾部添加`//PARA_NEW`（`g:atv_autopara_para_new`）
   > - 例化时默认若有参数被删除，自动在所有端口例化之后添加`//PARA_DEL`（`g:atv_autopara_para_del`）
   > - 例化时修改过参数连线的则保留，否则自动刷新（`g:atv_autopara_keep_chg`）
   > - 例化时默认添加`//`类型注释（`g:atv_autopara_incl_cmnt`）
   > - 例化时默认添加``ifdef`类型的宏定义，包括`ifdef/elsif/else/endif`（`g:atv_autopara_incl_ifdef`）
   >   - 当前添加注释`//`以及宏定义<code>ifedf</code>在`AutoPara`中只支持使用`端口`参数例化，使用`所有`参数进行例化的会添加无用的注释`//`以及宏定义<code>ifedf</code>，请使用者注意。
   >   - 另外，注释`//`以及宏定义<code>ifedf</code>只针对`AutoPara`，不论如何配置，`AutoParaValue`均不添加注释`//`以及宏定义<code>ifedf</code>

   可通过在`.vimrc(or _vimrc)`中配置相关`global`参数实现配置

   ```javascript
   let g:atv_autopara_st_pos = 4
let g:atv_autopara_name_pos = 64 
   let g:atv_autopara_sym_pos = 128
let g:atv_autopara_only_port = 1
   let g:atv_autopara_para_new = 0
   let g:atv_autopara_para_del = 0
   let g:atv_autopara_keep_chg = 1
let g:atv_autopara_incl_cmnt = 1
   let g:atv_autopara_incl_ifdef = 1
let g:atv_autopara_tail_nalign = 1
   ```

   例化`端口`参数（`ONLY_PORT=1`）的例子：

   ```verilog
   module writeback
   #(
       parameter BMAN=3, 
       parameter AMAN=45   ,
    parameter WIDTH = 16    , 
       parameter TIME_INTERVAL = 4'd11
)
   ```

   例化`所有`参数（`ONLY_PORT=0`）的例子：

   ```verilog
   module writeback
   #(
       parameter BMAN=3, 
       parameter AMAN=45   ,
       parameter WIDTH = 16    , 
       parameter TIME_INTERVAL = 4'd11
   )
   (
       ......
   );
       parameter CNT0 = 16'h55, CNT1 = 16'h55;
       parameter CNT2 = 256     ;
       parameter CNT3 = 16'h55  ;
   ```

   </details>

5. 重刷

   整体与`AutoInst`一致，参考[AutoInst](#自动例化-AutoInst)

6. 连续声明

   支持特殊的`parameter`连续多个的写法，例如`parameter A = 1, B = 5, C = 6`。



## 自动寄存器-AutoReg

---

> 自动定义寄存器列表。

![autoreg](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/autoreg.gif)

### 操作步骤

1. 写标志`/*autoreg*/`

   <details>
   
   <summary>写标志</summary>
   
   在一个空白行内写入：`/*autoreg*/`

   > ⚠️注意
   >
   > 同一行内：
   >
   > - `/*autoreg*/`前端可以存在空格
   > - `/*autoreg*/`后端可以存在任意字符，操作时会忽略

   

   **e.g.**

   ```verilog
   /*autoreg*/
   ```

   ```verilog
   //multiple spaces
               /*autoreg*/ any_character
   ```
   
   </details>

2. 自动生成`reg`
   
   <details>
   
   <summary>自动生成</summary>

   - 使用菜单栏点击`AutoReg()`或在命令行输入`:call g:AutoReg()`确认，在当前文本`/*autoreg*/`下方自动生成`reg`，例化时光标位置随意，只要保证当前文本含有包含`/*autoreg*/`的行即可；

   - 上述操作也可以使用快捷键完成。
   
   </details>


3. 快捷键

   <details>
   
   <summary>快捷键</summary>

   默认键盘快捷键为`<S-F6>`（`Shift+F6`），为避免脚本更新导致的快捷键变更，或想使用自定义快捷键，可通过在`.vimrc(or _vimrc)`中配置相关`mapping`实现覆盖配置。（假设配置为`;atr`）

   ```javascript
   map ;atr      :call g:AutoReg()<ESC>
   ```
   
   </details>


4. 配置参数

   与`AutoDef`统一，参考[AutoDef](#自动定义-AutoDef)


5. 重刷

   <details>
   
   <summary>重刷</summary>

   - 自动保留`/*autoreg*/`范围外的`reg`。即，在`//Start of automatic reg`以及`//End of automatic reg`行之外）不重刷，只对其余端口进行自动生成`reg`。

   - **不支持**修改后的`reg`不重刷的功能。

   ![rereg](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/rereg.gif)

   </details>

## 自动线网-AutoWire

---

> 自动定义线网列表。

![autowire](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/autowire.gif)

### 操作步骤

1. 写标志`/*autowire*/`

   与`AutoReg`一致，参考[AutoReg](#自动寄存器-AutoReg)

2. 自动生成`wire`

   <details>
   
   <summary>自动生成</summary>

   - 使用菜单栏点击`AutoWire()`或在命令行输入`:call g:AutoWire()`确认，在当前文本`/*autowire*/`下方自动生成`wire`，例化时光标位置随意，只要保证当前文本含有包含`/*autowire*/`的行即可；

   - 上述操作也可以使用快捷键完成。
   
   </details>

3. 快捷键

    <details>

    <summary>快捷键</summary>

    默认键盘快捷键为`<S-F7>`（`Shift+F7`），为避免脚本更新导致的快捷键变更，或想使用自定义快捷键，可通过在`.vimrc(or _vimrc)`中配置相关`mapping`实现覆盖配置。（假设配置为`;atw`）
   
     ```javascript
     map ;atw      :call g:AutoWire()<ESC>
     ```

    </details>

4. 配置参数

   与`AutoDef`统一，参考[AutoDef](#自动定义-AutoDef)


## 自动定义-AutoDef

---

> 自动定义所有信号列表
>
> 可参考[AutoReg](#自动寄存器-AutoReg)与[AutoWire](#自动线网-AutoWire)，`AutoDef`功能上等于`AutoReg`+`AutoWire`。

![autodef](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/autodef.gif)

### 操作步骤

1. 写标志为`/*autodef*/`。默认键盘快捷键为`<S-F8>`（`Shift+F8`）。为避免脚本更新导致的快捷键变更，或想使用自定义快捷键，可通过在`.vimrc(or _vimrc)`中配置相关`mapping`实现覆盖配置。（假设配置为`;atd`）

   ```javascript
   map ;atd      :call g:AutoDef()<ESC>
   ```
   
   其余步骤及注意事项参考[AutoReg](#自动寄存器-AutoReg)与[AutoWire](#自动线网-AutoWire)。

2. 配置参数

   <details>
   
   <summary>配置参数</summary>

   可通过在`.vimrc(or _vimrc)`中配置相关`global`参数实现配置。

   ```javascript
   let g:atv_autodef_st_pos = 4
   let g:atv_autodef_name_pos = 64 
   let g:atv_autodef_sym_pos = 128
   let g:atv_autodef_reg_new = 1
   let g:atv_autodef_reg_del = 1
   let g:atv_autodef_wire_new = 1
   let g:atv_autodef_wire_del = 1
   let g:atv_autodef_unresolved_flag = 1
   let g:atv_autodef_reg_rmv_io = 1
   let g:atv_autodef_wire_rmv_io = 1
   let g:atv_autodef_mv = 1
   let g:atv_autodef_tail_nalign = 1
   ```

   - 生成时默认的对齐位置，请参考[位置对齐-Align](#位置对齐-Align)

   - 生成时配置使用`端口`参数例化或使用`所有`参数进行例化。（`g:atv_autopara_only_port`）

   - 生成时默认若有信号更新，自动在该端口尾部添加`//REG_NEW ` or `//WIRE_NEW`（`g:atv_autodef_reg_new` or `g:atv_autodef_wire_new`）

   - 生成时默认若有信号被删除，自动在所有端口例化之后添加`//REG_DEL` or `//WIRE_DEL`（`g:atv_autodef_reg_del` or `g:atv_autodef_wire_del`）

   - 生成时默认解析变量失败不添加标志位（`g:atv_autodef_unresolved_flag`）

     - 如果解析出当前变量为`reg`型，但解析其位宽等信息失败时，可在尾部添加标志位，即`//unresolved`，代表解析变量失败。
     - 如果解析出当前变量为`wire`型，但解析其位宽等信息失败，解析信号例化模块失败，获取例化模块相关信号失败等情况时，可在尾部添加标志位，即`//unresolved`，代表解析变量失败。

   - 生成时默认去除`input/output/inout`信号

     - 如果解析为`reg`型变量自动过滤已经在`input/output/inout`端口处声明过的变量（即在端口处声明的变量默认不会自动声明`reg`）。但如果是`verilog-1995`的写法可能存在依旧需要声明的情况，这时可在脚本`automatic.vim`中`配置`选择不自动过滤。（`g:atv_autodef_reg_rmv_io`）
     - 如果解析为`wire`型变量自动过滤已经在`input/output/inout`端口处声明过的变量（即在端口处声明的变量默认不会自动声明`wire`）。但如果是`verilog-1995`的写法可能存在依旧需要声明的情况，这时可在脚本`automatic.vim`中`配置`选择不自动过滤。（`g:atv_autodef_wire_rmv_io`）

   - 生成时默认不移动变量（`g:atv_autodef_mv`）

     可以配置将`/*autodef*/`范围外的所有已经声明的变量（`reg`或者`wire`）移动到`/*autodef*/`自动定义的变量之后。

   ![atd_move](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/atd_move.gif)

   </details>


3. 单行例化

   `AutoWire`支持单行例化`wire`的检索，举例：

   ```verilog
   module_name u_inst_name ( .test( a ), .test1( b ), .test2( c ));
   ```

## 自动声明-AutoArg

---

> 自动声明端口

![autoarg](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/autoarg.gif)

### 操作步骤

1. 打开`95-support`

   <details>

   <summary>95-support</summary>
   
    `AutoArg`为`verilog-1995`写法，必须打开相关配置，可通过在`.vimrc(or _vimrc)`中配置相关`global`参数实现配置

    ```javascript
    let g:atv_autoinst_95_support = 1
    ```

   </details>

2. 写标志`/*autoarg*/`

   <details>

   <summary>写标志</summary>
   
   将要自动声明的端口写为如下格式：`module module_name (/*autoarg*/);`

   > ⚠️注意
   >
   > - 格式末尾必须要有分号`;`
   > - 注意格式可不在同一行，只要`(/*autoarg*/)`包含在括号内即可。

   **e.g.**

   ```verilog
   module fetch  ( /*autoarg*/ );
   ```

   ```verilog
   module mem (
           /*autoarg*/);
   ```

   ```verilog
   module writeback
   (  /*autoarg*/
       clk,rst,
       write_data
   );
   ```

   </details>

3. 自动声明

   <details>

   <summary>自动声明</summary>
   
   - 使用菜单栏点击`AutoArg()`或在命令行输入`:call g:AutoArg()`确认，进行`/*autoarg*/`当前模块自动声明，注意例化时光标必须置于`/*autoarg*/`所在行之前的位置（即在当前行或上一行，若在当前行则必须在`/*autoarg*/`所在列之前）；

   - 上述操作也可以使用快捷键完成。

   </details>

4. 快捷键

   <details>

   <summary>快捷键</summary>
   
   - 默认键盘快捷键为`<S-F2>`（`Shift+F2`），为避免脚本更新导致的快捷键变更，或想使用自定义快捷键，可通过在`.vimrc(or _vimrc)`中配置相关`mapping`实现覆盖配置。（假设配置为`;ata`）

     ```javascript
     map ;ata      :call g:AutoArg()<ESC>
     ```

   </details>

5. 配置参数
   
   <details>

   <summary>配置参数</summary>
   
   可通过在`.vimrc(or _vimrc)`中配置相关`global`参数实现配置。

   ```javascript
   let g:atv_autoarg_st_pos = 8
   let g:atv_autoarg_sym_pos =  64 
   let g:atv_autoarg_mode =  0 
   let g:atv_autoarg_io_clsf =  0 
   let g:atv_autoarg_tail_nalign =  0 
   ```

   - 生成时默认的对齐位置，请参考
   
   - 生成时默认自动换行，默认多个端口一行，到最大宽度后自动进行换行，最大宽度设置参考[位置对齐-Align](#位置对齐-Align)。（`g:atv_autoarg_mode`）
   
     - 自动换行（`g:atv_autoarg_mode=1`）
   
       ![autoarg](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/autoarg.gif)
   
     - 不自动换行：（`g:atv_autoarg_mode=0`）
   
       ![nowrap](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/nowrap.gif)
   
   - 生成时默认端口按`input/output/inout`自动进行分类。（`g:atv_autoarg_io_clsf`）
   
     ![io_clasf](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/io_clasf.gif)

   </details>

## 跨文件夹-CrossDir

---

> 使用`AutoInst`、`AutoPara`、`AutoParaValue`、`AutoWire`、`AutoDef`、`RtlTree`等功能时，可能例化的模块不在当前文件夹下，而在上一层或下一层文件夹的某个位置，此时需要进行配置

跨文件夹可以通过三种方式进行设置：`verilog-library`(默认，仿`verilog-mode`)、`filelist`、`tags`。

跨文件夹的方式可通过在`.vimrc(or _vimrc)`中配置相关`global`参数实现配置（`0:normal 1:filelist 2:tags`，假设配置为`tags`）

```javascript
let g:atv_crossdir_mode = 2    "0:normal 1:filelist 2:tags
```

1. `verilog-library`设置（默认）

   <details>

   <summary>verilog-library</summary>
   
   在代码中添加如下格式的内容`声明`文件夹即可保证代码文件被搜索到：
   
   ```verilog
   //Local Variables:
   //verilog-library-directories:("." "./aaa/bbb/ccc")
   //verilog-library-directories-recursive:0
//End:
   ```

   - `verilog-library-directories`为要选择的文件夹，文件夹之间以空格隔开；

   - `verilog-library-directories-recursive`为是否进行文件夹递归搜索，即搜索所有选择文件夹及其子文件夹；
   
     > 假设需要选择当前文件夹以及其下所有子文件夹作为例化搜索的对象，则配置为：
     >
     > `//verilog-library-directories:(".")`
     > `//verilog-library-directories-recursive:1`
     >
     > ⚠️注意
     >
     > 如果使用递归搜索，请勿采用重叠的文件夹，否则递归会报错；例如上述例子中，`"."` 当前文件夹递归搜索包含`"./aaa/bbb/ccc"`子文件夹，若此时使用递归搜索则重复调用时会报错。
     >
     > 
     >
     > 如果不配置跨文件夹的选项，默认会以打开`vim`的位置作为搜索顶层往下**递归**搜索相关`.v`或`.sv`文件。
  >
     > 注意不要在`桌面`或者`盘符根目录`等位置打开文件并使用脚本，否则搜索可能会卡死。（暂时不考虑修复为自动切换地址到文件位置，因为与`RtlTree`部分功能冲突）

     ![CrossDir](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/cross_dir.gif)

   同时，参考[Verilog-Mode:verilog-library-extensions](https://veripool.org/verilog-mode/help/#verilog-library-extensions)可以设置其他选项：

   `verilog-mode`的设置选项：

   ```
       -f filename     Reads absolute verilog-library-flags from the filename.
       -F filename     Reads relative verilog-library-flags from the filename.
       +incdir+dir     Adds the directory to verilog-library-directories.
       -Idir           Adds the directory to verilog-library-directories.
       -y dir          Adds the directory to verilog-library-directories.
    +libext+.v      Adds the extensions to verilog-library-extensions.
       -v filename     Adds the filename to verilog-library-files.
       filename        Adds the filename to verilog-library-files.
                       This is not recommended, -v is a better choice.
   ```

   本插件的实际使用的设置选项：

   > -f filename     																						 	 在指定位置读`filelist`，采用相对或绝对路径均可。
   > ~~-F filename     Reads relative verilog-library-flags from the filename.~~		 取消，均使用`-f`
   >
> -t filename     																						 	 新增，在指定位置读`tags`，采用相对或绝对路径均可。
   >
> +incdir+dir     Adds the directory to verilog-library-directories.					添加搜索文件夹
   >
   > -Idir           Adds the directory to verilog-library-directories.                         添加搜索文件夹
   >
   > -y dir          Adds the directory to verilog-library-directories.                        添加搜索文件夹
   >
   > +libext+.v      Adds the extensions to verilog-library-extensions.                 添加扩展名(例如`'.vo'`)
   >
   > -v filename     Adds the filename to verilog-library-files.                              添加指定文件(例如`'test.v'`)
   >
   > filename        Adds the filename to verilog-library-files.                               添加指定文件(推荐直接使用 -v )

   举例，使用`-y`、`+incdir+`设置搜索路径，使用`-f`设置搜索文件，使用`+libext+`设置扩展名

   ```verilog
   // Local Variables:
   // verilog-library-flags:("-y dir -y otherdir")
   // verilog-library-flags:("+incdir+dir")
   // verilog-library-flags:("-v test.v")
   // verilog-library-flags:("+libext+.vo")
   // End:
   ```

   </details>



2. `filelist`设置

   <details>

   <summary>filelist</summary>
   
   使用`filelist`进行跨文件夹请先配置`g:atv_crossdir_mode = 1`。配置方式见本章节开头内容。

   默认在第一次进行跨文件夹操作时（例如`AutoInst`或`AutoDef`时）载入`filelist`，载入方式分为四种：

   1. 浏览（`browse`）

      如果`g:atv_crossdir_flist_browse = 1`（默认），那么采取浏览选择的方式载入`filelist`。

      如果配置`g:atv_crossdir_flist_browse = 0`，那么采取如下三种方式载入`filelist`。

   2. 配置`global`参数`g:atv_crossdir_flist_file`（`config`）

      可通过在`.vimrc(or _vimrc)`中配置相关`global`参数实现配置（假设配置为`./filelist.f`）

      ```javascript
      let g:atv_crossdir_flist_file = '../filelist/ctags_filelist.f'
      ```

   3. 通过`verilog-library`设置（`library`）

      在代码中添加如下格式的内容`声明filelist`位置保证其被搜索到：

      ```verilog
      // Local Variables:
      // verilog-library-flags:("-f ./filelist.f")
      // End:
      ```

   4. 自动选取当前文件夹下的.f文件（`auto`）

   以上四种方式由上至下保持先后顺序，找到一个即载入，不会通过另外的方式继续搜索`filelist`。

   `filelist`载入后跨文件夹会通过`filelist`文件定义的位置自动进行跨文件夹的相关搜索。

   </details>

3. `tags`设置

   <details>

   <summary>tags</summary>
   
   使用`tags`进行跨文件夹请先配置`g:atv_crossdir_mode = 2`。配置方式见本章节开头内容。
   
   默认在第一次进行跨文件夹操作时（例如`AutoInst`或`AutoDef`时）载入`tags`，载入方式分为四种：
   
   1. 浏览（`browse`）
   
      如果`g:atv_crossdir_tags_browse = 1`（默认），那么采取浏览选择的方式载入`tags`。
   
      如果配置`g:atv_crossdir_tags_browse = 0`，那么采取如下三种方式载入`tags`。
   
   2. 配置`global`参数`g:atv_crossdir_tags_file`（`config`）
   
      可通过在`.vimrc(or _vimrc)`中配置相关`global`参数实现配置（假设配置为`./tags`）
   
      ```javascript
      let g:atv_crossdir_tags_file = '../filelist/tags'
      ```
   
   3. 通过`verilog-library`设置（`library`）
   
      在代码中添加如下格式的内容`声明tags`位置保证其被搜索到：
   
      ```verilog
      // Local Variables:
      // verilog-library-flags:("-t ./tags")
      // End:
      ```
   
   4. 自动选取当前文件夹下的`tags`文件（`auto`）
   
   以上四种方式由上至下保持先后顺序，找到一个即载入，不会通过另外的方式继续搜索`tags`。
   
   `tags`载入后跨文件夹会通过`tags`文件定义的位置自动进行跨文件夹的相关搜索。

   </details>

## 位置对齐-Align

---

> 配置自动生成代码的对齐位置

1. 对齐位置

   <details>

   <summary>对齐位置</summary>
   
   可通过在`.vimrc(or _vimrc)`中配置相关`global`参数选择使用自动函数时的对齐位置（下列为`AutoInst`相关配置，其他函数`AutoArg`、`AutoPara`、`AutoReg`、`AutoWire`、`AutoDef`、`AutoArg`配置同理）

   ```javascript
   "AutoInst
   let g:atv_autoinst_st_pos = 8
   let g:atv_autoinst_name_pos = 64 
   let g:atv_autoinst_sym_pos = 128
   
   "AutoPara
   let g:atv_autopara_st_pos = 4
   let g:atv_autopara_name_pos = 64 
   let g:atv_autopara_sym_pos = 128
   
   "AutoReg&AutoWire&AutoDef
   let g:atv_autodef_st_pos = 4
   let g:atv_autodef_name_pos = 64 
   let g:atv_autodef_sym_pos = 128
   
   "AutoArg
   let g:atv_autoarg_st_pos = 8
   let g:atv_autoarg_sym_pos =  64 
   ```

   `st_pos`：起始位置`start position`

   `name_pos`：信号名对齐位置`name position`

   `sym_pos`：第二个括号对齐位置`symbol position`

   如果信号长度过长（长于设定的对齐位置），则会按照`最长信号长度+4`为新的对齐位置进行对齐。

   ![autopara](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/pos.png)

   </details>

2. 行尾对齐

   <details>

   <summary>行尾对齐</summary>
   

   可在脚本`automatic.vim`中如下位置`配置`相关参数选择进行行尾对齐/不对齐（默认0，进行行尾对齐）

   ```javascript
   "AutoInst 行尾不对齐
   let g:atv_autoinst_tail_nalign = 1
   "AutoPara 行尾不对齐
   let g:atv_autopara_tail_nalign = 1
   "AutoReg&AutoWire&AutoDef 行尾不对齐
   let g:atv_autodef_tail_nalign = 1
   "AutoArg 行尾不对齐,仅在不自动换行，即g:atv_autoarg_mode=0时有效
   let g:atv_autoarg_tail_nalign =  0 
   ```

   - `AutoInst`行尾对齐
   
   ![image-20210612222934861](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/image-20210612222934861.png)
   
   - - `AutoInst`行尾不对齐
   
   ![image-20210612222827132](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/image-20210612222827132.png)
   
   - `AutoPara`的行尾对齐
   
   ![image-20210612223220307](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/image-20210612223220307.png)
   
   - `AutoPara`的行尾不对齐
   
   ![image-20210612223427942](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/image-20210612223427942.png)

   - `AutoReg`、`AutoWire`、`AutoDef`及`AutoArg`的行尾对齐与`AutoInst`以及`AutoPara`类似
   
   </details>


## 树状拓扑-RtlTree

---

> 通过`Rtl`树观察代码结构

⚠️注意：此功能可能存在`BUG`，请及时反馈

![callout_rtl](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/callout_rtl.gif)

### 操作步骤

1. 打开`Rtl`

   命令行输入`RtlTree`（或直接使用缩略的`Rtl`）确认即可

   ```javascript
   :RtlTree
   ```

   `RtlTree`默认以当前模块为顶层模块开始进行树图生成，如果想自定义顶层文件，可以自行加上文件名（如果在当前文件夹，可用`tab`在命令行自动补全）

   ```javascript
   RtlTree top.v
   ```

   ```
   RtlTree ../src/top.v
   ```

   ⚠️需要注意的是，当前版本的`跨文件夹`如果使用`verilog-library`设置（默认），则必须从当前打开的文件进行树图展开，否则无法找到跨文件夹的文件。如果使用`filelist`和`tag`则不受此影响。

2. 跳转

   - 鼠标操作

     单击跳转至例化位置

     双击跳转至模块内部（如果文件存在），同时展开其子模块（如果子模块文件存在）

     `+`代表可以展开，`~`代表无法展开，`unresolved`代表子模块对应文件不存在（即跨文件夹未搜索到）

     ![mouse](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/mouse.gif)

   - 键盘操作

     在`~`，`+`位置按`<CR>`，也就是`<Enter>`，进行子模块展开/收缩

     按`o`，打开对应模块

     按`i`，打开对应模块例化位置

     按`q`，关闭`RtlTree`

     按`r`，更新`RtlTree`（适用于在过程中新增/删除文件，新增/删除模块的时候。注意更新之后需要手动收缩/展开一次相应模块的位置才能展现效果）

     按`?`，打开或关闭帮助信息

     ![fastkey](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/fastkey.gif)

     键盘相关操作可以配置为其他按键：

     - 打开对应模块：`g:atv_rtl_open`
     - 打开对应模块例化位置：`g:atv_rtl_inst`
     - 关闭`RtlTree`：`g:atv_rtl_quit`
     - 更新`RtlTree`：`g:atv_rtl_refresh`

     例如配置通过`d`键打开对应模块：

     ```javascript
     let g:atv_rtl_open = "d"
     ```

### 递归搜索

默认建立`Rtl`树时不会搜索整个代码结构，只会搜索当前模块下的例化模块结构。如果希望递归搜索所有代码结构，请打开如下配置：

```javascript
let g:atv_rtl_recursive = 1
```

另外，更新`RtlTree`时，总会自动进行递归调用。

