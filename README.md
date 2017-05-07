### 在线图片处理服务

#### 安装

+ 安装graphicsmagick
+ 安装openresty
+ 安装lua-resty-http
+ 编译安装luaext动态库
gcc -fPIC -shared luaext.c -o luaext.so -I/usr/local/Cellar/openresty/1.11.2.3/luajit/include/luajit-2.1/ -L/usr/local/Cellar/openresty/1.11.2.3/luajit/lib/ -lluajit-5.1


#### 指令

指令是对图片做的动作。
不允许有重复的指令，指令之间用英文逗号隔开。例如：w_300,h_300,r_30,p_png,t_hello+world-30-FF4500-southeast


+ v

 - 格式：v_%d
 - 说明：版本

+ f

 - 格式：f_format
 - 说明：图片格式，format目前可以是：png jpeg jpg

+ q

 - 格式：q_quality
 - 说明：图片压缩质量，仅对jpeg jpg格式有作用。quality取值0-100，默认为85.

+ w

 - 格式：w_width
 - 说明：图片宽度，width取值为数字。

+ h

 - 格式：h_highly
 - 说明：图片高度，highly取值为数字。

+ r

 - 格式：r_radius
 - 说明：圆角剪裁。radius为角度，取值为0-360

+ re

 - 格式： re_degrees
 - 说明：图片旋转。degrees为旋转的度，取值为0-360。

+ b

 - 格式：b_borderWidth-borderHighly-borderColor
 - 说明：边框。borderWidth为边框宽度。borderHighly为边框高度，如果为圆角剪裁边框则该值无用。borderColor边框颜色，格式为：颜色代码（如：FF4500）。

+ t

 - 格式：t_text-font-size-color-gravity-x-y-angle
 - 说明：文字水印。text文字内容。font为文字格式，size文字大小，取值为数字。color文字颜色，格式为颜色代码。gravity文字位置，取值和说明见下图，x和y是文字位置横纵坐标，angle文字角度。


```

northwest   |   north    |   northeast
------------+------------+------------
west        |   center   |        east 
------------+------------+------------
southwest   |   south    |   southeast

```


+ p

 - 格式：p_picture-w-h-x-y-re
 - 说明：图片水印。picture为水印图片。w水印图片的宽度，0为默认宽度。h水印图片的高度，0为默认高度。x和y是水印图片位置，re为旋转度数。


