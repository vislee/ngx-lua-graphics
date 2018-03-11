#! /usr/bin/env luajit

local gh = require "image"
local cv = require "opencv"


----[[
local m = gh("input.jpg")
local w, h = m:size()
print(w, h)
local b = m:toPixels('byte', 'RGB')
print(b)
local c = cv()
c:cvImgxs(w, h, b, 8, 3)

local t1, t2 = c:cvObjectDetect("haarcascade_frontalface_alt.xml")
print(t1.x,t1.y,t1.w,t1.h)
c:save("./output2.jpg")

c:release()

local tmp = m:clone()
tmp:crop(t1.x,t1.y, t1.w, t1.h)

for _,itm in ipairs(t2) do
    m:circle(itm.x, itm.y, itm.x+itm.w, itm.y+itm.h, "green", 300)
end
m:save("./output.jpg")
tmp:save("./output3.jpg")
--]]

--[[
local c = cv()
local res = c:load("input.png")
if res == nil then
    print("error error")
    return
end

local m = gh()
m:fromBlob(c:imageData())
m:save("output.jpg")

-- c:release()
--]]



