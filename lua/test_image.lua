#! /usr/bin/env luajit

function test()
	gh = require('image')
	math = require('math')
	-- test
	-- 圆角＋文字＋水印
	-- local logo = gh('logo.png')
	-- local lw, lh = logo:size()
	-- gh('input.jpeg'):clone():size(400, 300):roundedCorner(20):setText('hello liwq', 30, 'black'):compose(logo, 'Over', 390-lw, lh/2):save('test_graphics.png')

	-- test2
	local radius = 1 + (math.log(40) / math.log(2.1))
	local img = gh('input.png'):clone()
	local w = img:size()
	-- img:save('test_graphics.png')
	-- 锐化
	-- img:sharpen(radius, w):save('test_graphics.png')
	-- 模糊
	-- img:format('tiff')
	-- img:blur(radius, w):save('test_graphics_ttt', 80)

	--  grayscale 灰度
	-- img:type('Grayscale'):save('test_graphics.png')
	-- oil_paint 油画
	-- img:oilPaint(2):save('test_graphics.png')
	-- negate 反色
	-- img:negate():save('test_graphics.png')
	-- modulate 亮度
	-- img:modulate(120):save('test_graphics.png')
	-- contrast 自动对比度
	-- img:contrast(true):save('test_graphics.png')
	-- 增加颜色
	-- img:gammaCorrection(100, 'Opacity'):save('test_graphics.png')
	-- 老照片
	-- local threshold = 52428 * (10 - 0.8)
	-- img:solarize(0.1):save('test_graphics.png')
	-- resize
	-- img:size(600, 400, 'Lanczos', 0.5):save('test_graphics.png')
	-- scale
	-- img:scale(1000):save('test_graphics.png')
	-- img:crop(500,200, 100,300):save('test_graphics.png', 100)
	--addBorder
	-- local timg = img:size(400, 300):roundedCorner(100, 3, "rgba(255, 255, 00, 00)")
	-- timg:save('test_graphics.png', 100)
	-- pcall(gh.save, timg, 'test_graphics.jpg', 100)
	-- img:addBorder(100, 10, 0xff, 0x00, 0xff):size(400,300)
	-- 旋转
	-- timg = img:size(400):rotate(330, 0xff, 0xff, 0xff, 0xff)
	-- timg = img:size(400):negate()

	-- timg = img:unsharpMask(10, 10, 10, 10)
	-- timg:save('test_graphics.png', 100)

	img:circle(40,40,100,100,"green")
	img:save('output.png', 100)

end



local ok, msg = pcall(test)
if not ok then
	print('error: ', msg)
end

