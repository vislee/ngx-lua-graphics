-- Copyright (c) 2017 liwq
#! /usr/bin/env luajit

function test()
	gh = require('image')
	math = require('math')
	-- test
	-- 圆角＋文字＋水印
	-- local logo = gh('logo.png')
	-- local lw, lh = logo:size()
	-- gh('input.jpeg'):clone():size(400, 300):roundedCorner(20):setText('hello liwq', 30, 'black'):compose(logo, 'Over', 390-lw, lh/2):save('test_graphics.png')
	-- gh('input.jpeg'):clone():size(400, 300):roundedCorner(20):setText('hello liwq', 30, 'black', nil, nil, 50, 50):save('test_graphics.png')

	-- test2
	local radius = 1 + (math.log(2) / math.log(2.1))
	local sigma = 1 + (math.log(1) / math.log(1.8))
	-- local img = gh('dttt.gif'):clone()
	-- local w = img:size()
	-- img:save('test_graphics.png')
	-- 锐化
	-- img:sharpen(radius, w):save('test_graphics.png')
	-- 模糊
	-- img:blur(sigma, w):save('test_graphics.png')
	-- img:format('tiff')
	-- img:save('test_graphics_ttt', 100)
	-- local s = img:profile('exif')
	-- print(s)
	--  grayscale 灰度
	-- img:type('Grayscale'):save('test_graphics1.png')
	-- img:type('Grayscale'):save('test_graphics.png')
	-- oil_paint 油画
	-- img:oilPaint(8):save('test_graphics.png')
	-- negate 反色
	-- img:negate():save('test_graphics.png')
	-- modulate 亮度
	-- img:modulate(90):save('test_graphics.png')
	-- charcoal 炭笔效果
	-- img:charcoal(radius, w):save('test_graphics.png')

	-- 毛玻璃效果
	-- img:spread(8):save('test_graphics.png')
	-- img:next():save('test_graphics.png')
	-- local d = img:delay()
	-- print(d)
	-- img:delay(30):coalesce():reset():save('test_graphics.gif')
	-- contrast 自动对比度
	-- img:contrast(0):save('test_graphics.png')
	-- img:setChannelDepth('Opacity', 90):save('test_graphics.png')
	-- 增加颜色
	-- img:format('png'):gammaCorrection(60, 'Opacity'):save('test_graphics.png')
	-- local n = img:index()
	-- print(n)
	-- fuzz
	-- img:fuzz(3000):save('test_graphics.png')
	-- 噪声
	-- img:addNoise('Poisson'):save('test_graphics.png')
	-- img:redPrimary(200, 230):save('test_graphics.png')
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

	-- img:unsharpMask(10, 10, 10, 1):save('test_graphics.png')
	-- timg:save('test_graphics.png', 100)
	-- local info = img:info()
	-- print(info)

	-- local imgx = gh('dttt.gif'):clone()
	-- local i = 1
	-- while imgx:next() do
	-- 	imgx:save(i .. '_dttt.gif')
	-- 	i = i + 1
	-- end

	-- local imgx = gh('dttt.gif'):clone()
	-- -- imgx = imgx:decon()
	-- imgx:save_images('new_dttt.gif')

	-- 生成动图
	local imgx = gh('dttt_2.jpg'):size(320,380):setText('liwq',20,'black',nil,nil,30,30)
	imgx:delay(120)
	for i=1, 3 do
		local igx = gh('dttt_' .. i .. '.jpg')
		igx:size(320,380):setText('liwq',20,'black',nil,nil,30,30):delay(120)
		igx:setIter(0)
		imgx:next()
		imgx:add(igx)
	end
	imgx:save_images('new_dttt.gif')


	-- local imgx = gh('new_dttt.gif'):clone()
	-- imgx:next()
	-- imgx:setText('hello liwq', 100, 'black', nil, nil, 50, 50)
	-- imgx:save_images('new_new_dttt.gif')

end



local ok, msg = pcall(test)
if not ok then
	print('error: ', msg)
end

