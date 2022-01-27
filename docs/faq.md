## AutoInst？

1. 支持verilog-1995写法？

   `AutoInst`支持`verilog-1995`以及`verilog-2001`的不同写法，但使用`verilog-1995`写法时需在脚本`automatic.vim`中如下位置`配置`选择兼容`verilog-1995`，否则默认不兼容

   ```javascript
   "AutoInst 自动例化配置{{{2
   ......
   let s:ati_95_support = get(g:,'ati_95_support',1)           "Support Verilog-1995
   ......
   "}}}2
   ```

   注意，若采用`verilog-1995`写法，则`AutoInst`对`ifdef`以及注释`//`的支持存在问题，建议此时配置关闭这些选项

2. 支持的写法？

   输入输出端口的格式不支持连续多个的特殊写法，例如`input [7:0] a,b,c;`，只支持单行写法
   
3. 如何去掉注释？

   请关闭`ati_incl_cmnt`。

## AutoPara？

1. 支持的写法？

   `AutoPara`对`ifdef`以及注释`//`的支持存在问题，建议配置关闭（默认为关闭）

## AutoReg/AutoWire/AutoDef？

1. 生成错误？

   `AutoReg`：

   - 确认是否删除了`//Start of automatic reg`或`//End of automatic reg`。

     `AutoReg`自动生成的`//Start of automatic reg`以及`//End of automatic reg`行会被用于定位所有`/*autoreg*/`的内容，不能随意对其进行删除（例如只删除其中一个而保留另一个），否则再次进行自动生成时会出现错误

   - 请勿在文本中写多个标志`/*autoreg*/`，否则可能出现错误
   - 重刷特性会检查现有的`reg`，但数组格式的`reg`的检查会出现异常，例如`reg [7:0] ram_data[127:0]`

   `AutoWire`：

   - 确认是否删除了`//Start of automatic wire`或`//End of automatic wire`。

     `AutoWire`自动生成的`//Start of automatic wire`以及`//End of automatic wire`行会被用于定位所有`/*autowire*/`的内容，不能随意对其进行删除（例如只删除其中一个而保留另一个），否则再次进行自动生成时会出现错误

   - 请勿在文本中写多个标志`/*autowire*/`，否则可能出现错误

   - 由于`AutoWire`会搜索例化模块的`wire`，因此会按路径进行例化模块搜索，此时可按照使用手册`跨文件夹`相关的内容配置文件路径，保证例化模块可以被搜索到

   - 不支持例化端口的复杂写法，只支持单信号的简单写法，复杂写法举例如下：

     ```verilog
     module_name u_inst_name (
     	.test   ( {a,b[7:0],c} ),
     	.test1  ( ~d ),
     	.test2  ( &e )
     );
     ```

   `AutoDef`：

   - 确认是否删除了`//Start of automatic define`或`//End of automatic define`。

     在`Autodef`中，`AutoReg`及`AutoWire`自动生成的`//Start of automatic reg`、`//Start of automatic wire`以及`//End of automatic reg`、`//End of automatic wire`行会被用于定位所有`/*autodef*/`的内容，不能随意对其进行删除（例如只删除其中一个而保留另一个），否则再次进行自动生成时会出现错误

   - 请勿在文本中写多个标志`/*autodef*/`，否则可能出现错误
   - 由于`AutoDef`会搜索例化模块的`wire`，因此会按路径进行例化模块搜索，此时可按照使用手册`跨文件夹`相关的内容配置文件路径，保证例化模块可以被搜索到

2. 加载太慢？

   `AutoWire`及`AutoDef`运行时会获取相关的所有例化模块，其运行速度可能较慢。为有效显示其运行状态，可以打开如下配置，实现获取例化模块的`状态栏进度条显示`。

   需要注意的是，打开进度条显示后，由于进度条会刷新状态栏，若出现错误，则在状态栏的相关函数的错误信息会消失。

   ```javascript
   "Progressbar 进度条支持{{{2
   let s:atv_pb_en = 0
   "}}}2
   ```

   ![progressbar](https://cdn-1301954091.cos.ap-chengdu.myqcloud.com/blog/vimscript-automatic/progressbar.gif)


## AutoArg？

1. 生成的代码多少字符换行的宽度可调吗?

   可以，参考使用手册`位置对齐`配置`AutoArg`的`symbol max position`即可。

## RtlTree？

1. `tags`?

   `RtlTree`会自动生成`tags`文件，若一般正常操作则会自动删除此文件，但出现异常时此文件可能会留存，若不需要请自行删除

2. `top`文件位置？

   `RtlTree`以当前模块为顶层模块开始进行树图生成（默认，不可改）

3. 乱跳转？窗口切换混乱？其他异常`bug`?

   你可以[留言](https://blog.honk.wang/posts/AutoMatic#post-comment)，但不一定修复，因为这部分代码是直接移植的，改动很小，修复难度较大，除非重构（至少最近不考虑重构）。

## verilog代码写法有什么要求？

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

## 使用verilog-95的写法，脚本异常？

请打开`ati_95_support`。

## 最后一行为注释`//`时，脚本异常？

~~最后一行为注释`//`时，脚本有概率报异常（暂时不考虑修复，因为很多搜索注释到末尾未结束需要异常处理。说白了就是懒得改）。不要在最后写注释行就行。~~

此问题已在[fc25e9c](https://github.com/HonkW93/automatic-verilog/commit/fc25e9cce8abd55deae14df1ea18cc128eefd93d)修复。使用旧版代码的更新代码即可。

## 运行过程中修改相关配置？

只能通过修改源文件实现，修改脚本文件相应位置的配置后`source`即可。

## 代码段可以自定义吗，比如状态机`fsm`等自定义代码段？

（以后）可以，即将集成`load_template`脚本，之后可以在模板编写好之后自动调用。

## 其他稀奇古怪的问题怎么办？

请先看使用手册，如果还有问题，请去此页面[留言](https://blog.honk.wang/posts/AutoMatic#post-comment)。