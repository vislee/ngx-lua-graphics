-- Copyright (c) 2017-2018 vislee, SAE

local imgxs = require 'imgxs_process'

function main()
    if ngx.req.is_internal() then
        ngx.log(ngx.INFO, 'internal request')
        imgxs.error({}, 'InvalidRequest', 'The unknown error')
    end

    if ngx.req.get_method() ~= 'GET' then
        imgxs.error({}, 'InvalidRequest', 'Method Not Allowed')
    end

    local p, code, msg = imgxs()
    if not p then
        imgxs.error({}, err, msg)
    end
    p:Init()
    p:Process()
    p:Clean()
end


-- main()
local ok, err = pcall(main)
if not ok then
    ngx.log(ngx.ERR, 'The unknown error. ', err)
    imgxs.error({}, 'InvalidRequest', 'The unknown error')
end
