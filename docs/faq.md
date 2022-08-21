## AutoInst？

1. 支持的写法？

   ~~输入输出端口的格式暂时不支持连续多个的特殊写法，例如`input [7:0] a,b,c;`，只支持单行写法~~ 最新V1.5支持连续多个写法。

2. 支持verilog-1995写法？

   `AutoInst`支持`verilog-1995`以及`verilog-2001`的不同写法，但使用`verilog-1995`写法时需在`.vimrc(or _vimrc)`全局配置如下，否则默认不兼容

   ```javascript
   let g:atv_autoinst_95_support = 1
   ```

   另外，若采用`verilog-1995`写法，则`AutoInst`对`ifdef`以及注释`//`的支持存在问题（所有注释行会被添加到`AutoInst`中），建议此时配置关闭这些选项

3. 如何去掉注释？

   在`.vimrc(or _vimrc)`全局配置如下，关闭`include comment`选项。

   ```javascript
   let g:atv_autoinst_incl_cmnt = 0
   ```

## AutoPara？

1. 支持的写法？

   `AutoPara`对`ifdef`以及注释`//`的支持存在问题，建议配置关闭（默认为关闭）

## AutoReg/AutoWire/AutoDef？

1. 生成错误？

   `AutoReg`：

   - 确认是否删除了`//Start of automatic reg`或`//End of automatic reg`。

     `AutoReg`自动生成的`//Start of automatic reg`以及`//End of automatic reg`行会被用于定位所有`/*autoreg*/`的内容，不能随意对其进行删除（例如只删除其中一个而保留另一个），否则再次进行自动生成时会出现错误

   - 重刷特性会检查现有的`reg`，但数组格式的`reg`的检查会出现异常，例如`reg [7:0] ram_data[127:0]`

   `AutoWire`&`AutoDef`：

   - 确认是否删除了`//Start of automatic wire`或`//End of automatic wire`。

   - 确认是否删除了`//Start of automatic define`或`//End of automatic define`。

     `AutoWire`自动生成的`//Start of automatic wire`以及`//End of automatic wire`行会被用于定位所有`/*autowire*/`的内容，不能随意对其进行删除（例如只删除其中一个而保留另一个），否则再次进行自动生成时会出现错误

     在`Autodef`中，`AutoReg`及`AutoWire`自动生成的`//Start of automatic reg`、`//Start of automatic wire`以及`//End of automatic reg`、`//End of automatic wire`行会被用于定位所有`/*autodef*/`的内容，不能随意对其进行删除（例如只删除其中一个而保留另一个），否则再次进行自动生成时会出现错误

   - 由于`AutoDef`&`AutoWire`会搜索例化模块的`wire`，因此会按路径进行例化模块搜索，此时可按照使用手册`跨文件夹`相关的内容配置文件路径，保证例化模块可以被搜索到

   - 暂时不支持例化端口的复杂写法，只支持单信号的简单写法，复杂写法举例如下：

     ```verilog
     module_name u_inst_name (
     	.test   ( {a,b[7:0],c} ),
     	.test1  ( ~d ),
     	.test2  ( &e )
     );
     ```

2. 加载太慢？

   `AutoWire`及`AutoDef`运行时会获取相关的所有例化模块，其运行速度可能较慢

## RtlTree？

1. 顶层文件位置？

   `RtlTree`以当前模块为顶层模块开始进行树图生成，如果想置顶文件位置，可以自行加上文件名（如果在当前文件夹，可用`tab`在命令行自动补全）

   ```javascript
   RtlTree top.v
   ```

2. 乱跳转？窗口切换混乱？其他异常`bug`?

   可以[留言](https://blog.honk.wang/posts/AutoMatic#post-comment)，我会尽量修复
   

## 代码对齐？

1. `AutoArg`生成的代码多少字符换行的宽度可调吗?

   可以，参考`使用手册`的`位置对齐`配置`AutoArg`的`symbol max position`即可

2. `AutoInst`&`AutoPara`&`AutoDef`等生成的代码对齐位置可调吗?

   可以，同样参考`使用手册`的`位置对齐`配置`AutoArg`的`symbol max position`即可

## 代码写法？

`AutoInst`只支持获取单行声明的写法，不支持获取端口跨行声明的写法；`AutoPara`支持连续的跨行声明，但不支持不连续的跨行声明

- `inst`跨行，不支持：

  ```verilog
  input [1:0]
  a,
  ```

- `parameter`跨行，支持：

  ```verilog
  parameter BMAN=3, 
  AMAN=45 ,WIDTH = 16, 
  ```

- `parameter`声明跨行，不支持：

  ```verilog
  parameter BMAN
  =3, 
  ```

## verilog-95的写法异常？

使用`verilog-1995`写法时需在`.vimrc(or _vimrc)`全局配置如下，否则默认不兼容

```javascript
let g:atv_autoinst_95_support = 1
```

## 使用中修改相关配置？

在`.vimrc(or _vimrc)`配置后`source`即可。

## 代码段自定义？

自动调用`always`块等模板简单实现了一下，希望纯自定义代码段的请参考[vim-scripts/load_template](https://github.com/vim-scripts/load_template)，本插件不专注与实现代码段的功能。

## 其他稀奇古怪#%……&*￥的问题？

请先看`使用手册`，如果还有问题，请去此页面[留言](https://blog.honk.wang/posts/AutoMatic#post-comment)。

