#! /usr/bin/env luajit

local pub = require('util')

function test_spilit()
    str = "abc:def:higj:lmn"
    local res = pub.split(str, '%:')
    if res then
        for k, v in pairs(res) do
            print(k, v)
        end
    end
end


function test_table_to_str()
    local tab = {d = 234, a = 567, c = 456, b = 123}
    local s = pub.table_to_str(tab)
    print(s)
end



-- test_spilit()
test_table_to_str()