Name
=================

ngx-lua-graphics  -  graphics server driver for OpenResty.


Table of Contents
=================
* [Name](#name)
* [Status](#status)
* [Install](#install)
* [Description](#description)
* [Command](#command)
* [Author](#author)
* [Copyright and License](#copyright-and-license)

Status
======

This library is still under early development and is still experimental.


Install
=========

+ install the graphicsmagick
  yum install GraphicsMagick-devel.x86_64

+ install the opencv

+ install the openresty

+ install the lua-resty-http

+ install the luaext
  gcc -fPIC -shared luaext.c -o luaext.so -I ./openresty/1.11.2.3/luajit/include/luajit-2.1/ -L ./openresty/1.11.2.3/luajit/lib/ -lluajit-5.1

[Back to TOC](#table-of-contents)

Description
===========

图片处理服务。

通过指令可以对uri的图片做剪裁、旋转、水印等处理

例如： 对test.jpg这张图片转换为png格式，宽高为400，圆角，图片中央添加文字hello liwq，字体大小为40。图片中间添加logo图片水印
http://127.0.0.1:8080/imgxs/f_png,r_max,t_hello+liwq--40---200-200,w_400,h_400,p_logo---200-200/sinacloud.com/test.jpg

[Back to TOC](#table-of-contents)

Command
=========

指令是对图片做的动作。可以由多组指令共同处理，每组之间用管道符(|)分割。
一组之内不允许有重复的指令，组内指令用英文逗号隔开。
例如：w_300,h_300,r_30,p_png,t_hello+world--30-FF4500-southeast|t_hello+liwq--50--center

[Back to TOC](#table-of-contents)

+ 版本(v)

  - 格式：v_version
  - 取值：version 取值0-100
  - 说明：用于刷新缓存，多组指令只有最后一组指令中的版本生效。


+ 图片格式(f)

  - 格式：f_format
  - 取值：format 取值 png，jpeg，jpg，webp，tiff，tif，gif
  - 说明：转换为指定的图片格式。合成gif格式的图片还需要特效指令的支持。如果客户端支持建议使用webp格式。


+ 图片质量(q)

  - 格式：q_quality
  - 取值：quality取值0-100，默认为75。
  - 说明：图片压缩质量，仅对jpeg、jpg、webp、tiff、tif格式有作用。如果没有特殊需求，建议使用默认quality。


+ 图片宽度(w)

  - 格式：w_width
  - 取值：width 取值0-4000。
  - 说明：如果指定了宽度没指定高度，则按照宽度等比例缩放图片。

+ 图片高度(h)

  - 格式：h_highly
  - 取值：highly取值0-3000。
  - 说明：如果指定了高度没指定宽度，则按照高度等比例缩放图片。如果同时指定了宽度和高度，则不保证原图比例。


+ 剪裁（c）

  - 格式：c_gravity-x-y
  - 取值：gravity 为图片剪裁的位置，x、y为相对于gravity的横纵坐标。gravity 取值除了位置说明中的northwest等值，还可以指定用来剪裁单个人脸的’face’和多个人脸的’faces’。
  - 说明：


+ 圆角（r）

  - 格式：r_radius
  - 取值：radius取值0-360或max。
  - 说明：圆角剪裁，不支持jpg、jpeg、gif格式


+ 旋转（re）

  - 格式：re_degrees
  - 取值：degrees取值0-360，flip:垂直翻转，flop:水平翻转。
  - 说明：图片旋转。

+ 特效（e）

  - 格式：e_effect-parameter
  - 取值：effect取值:
        grayscale: 黑白。 (参数: 无)
        negate: 反色。 (参数: 无)
        contrast: 自动对比度。 (参数: 无)
        oilpaint: 油画。 (参数: parameter取值1-8，默认3.)
        brightness: 亮度。 (参数: parameter取值0-1000，默认120.)
        blur: 模糊。 (参数: parameter取值0-2000，默认50.)
        sharpen: 锐化。 (参数: parameter取值1-2000，默认50.)
        spread: 毛玻璃。 (参数: parameter取值1-100，默认2.)
        charcoal: 炭笔。 (参数: parameter取值1-100，默认2.)
  - 说明：

+ 边框（b）

  - 格式：b_width-highly-color
  - 取值：width边框宽度，highly边框高度。color边框颜色，颜色为颜色的代码（如：FF4500）
  - 说明：边框。


+ 文字水印（t）

  - 格式：t_text-font-size-color-gravity-x-y-angle
  - 取值：text为水印文字。 font为字体样式。size为字体大小。color为字体颜色，格式为颜色代码（如：FF4500）。gravity 为文字位置。x、y为相对于gravity的横纵坐标。angle为文字角度。
  - 说明：添加文字水印。


+ 图片水印（p）

  - 格式：p_picture-w-h-gravity-x-y-re
  - 取值：picture为水印图片，w为水印图片的宽度，h为水印图片的高度，gravity 为水印图片位置，x、y为水印图片添加到原图相对于gravity的横纵坐标，re为水印图片旋转的角度。
  - 说明：添加图片水印。picture为水印图片的base64编码。

[Back to TOC](#table-of-contents)

图片位置说明
===========

  ```

  northwest   |   north    |   northeast
  ------------+------------+------------
  west        |   center   |        east 
  ------------+------------+------------
  southwest   |   south    |   southeast

  ```

[Back to TOC](#table-of-contents)


Author
=======

wenqiang li(vislee)

[Back to TOC](#table-of-contents)


Copyright and License
=====================

This module is licensed under the GPL license.

Copyright (C) 2017-2018, by vislee.
Copyright (C) 2017-2018, by SAE.

All rights reserved.

[Back to TOC](#table-of-contents)
