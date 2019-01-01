-- Copyright (c) 2017-2018 vislee

local resty_lock = require "resty.lock"
local mysql  = require "resty.mysql"
local cjson  = require "cjson.safe"
local image  = require "image"
local opencv = require "opencv"
local util   = require "util"
local conf   = require "conf"



local _error_to_http_status = {
    OK               = ngx.HTTP_OK,
    InvalidSimplecmd = ngx.HTTP_OK,
    InvalidSsig      = ngx.HTTP_OK,
    InvalidUpdate    = ngx.HTTP_OK,
    ServiceClose     = ngx.HTTP_FORBIDDEN,
    InvalidRequest   = ngx.HTTP_BAD_REQUEST,
    InvalidFileType  = ngx.HTTP_BAD_REQUEST,
    UpstreamError    = ngx.HTTP_BAD_REQUEST,
    UnAuthorized     = ngx.HTTP_UNAUTHORIZED,
    NotFound         = ngx.HTTP_NOT_FOUND,
    InternalError    = ngx.HTTP_INTERNAL_SERVER_ERROR,
}


local function _check_int(val)
    if not tonumber(val) then
        return false, 'invalid number'
    end
    return true
end


local function _check_nil(val)
    return true
end


local function _q_check_val(val)
    if tonumber(val) and tonumber(val) >=0 and tonumber(val) <= 100 then
        return true
    end
    return false, 'invalid quality'
end


local function _r_check_val(val)
    if val == 'max' or (tonumber(val) and tonumber(val) > 0 and tonumber(val) <= 360) then
        return true
    end
    return false, 'invalid radius'
end


local function _re_check_val(val)
    if val == 'flop' or val == 'flip' or (tonumber(val) and tonumber(val) >= 0 and tonumber(val) <= 360) then
        return true
    end
    return false, 'invalid degrees'
end


local function _w_check_value(val)
    local w = tonumber(val)
    if not w or w < 0 or w > 4000 then
        return false, 'invalid width'
    end
    return true
end


local function _h_check_value(val)
    local h = tonumber(val)
    if not h or h < 0 or h > 3000 then
        return false, 'invalid height'
    end
    return true
end


local function _t_check_value(val)
    local m, e = ngx.re.match(val, '^([^-]{1,300})(-[a-z]{3,8}|-?)(-[0-9]{1,3}|-?)(-[0-9a-fA-F]{6,8}|-?)(-[a-z]{4,10}|-?)(-[0-9]{1,4}|-?)(-[0-9]{1,4}|-?)(-[0-9]{1,3}|-?)(-[0-9a-fA-F]{6,8}|-?)$')
    if not m then
        return false, 'invalid value', e
    end
    return true
end


local function _b_check_value(val)
    local m, e = ngx.re.match(val, '^([0-9]{1,3})(-[0-9]{0,3}|-??)(-[0-9a-fA-F]{6,8}|-?)$')
    if not m then
        return false, 'invalid value', e
    end
    return true
end


local function _p_check_value(val)
    local m, e = ngx.re.match(val, '^[a-z0-9A-Z=]{3,200}(-[0-9]{1,4}|-?)(-[0-9]{1,4}|-?)(-[a-z]{4,10}|-?)(-[0-9]{1,4}|-?)(-[0-9]{1,4}|-?)(-[0-9]{1,4}|-?)$')
    if not m then
        return false, 'invalid value', e
    end
    return true
end


local function _f_check_value(val)
    if not conf.file_type[val] then
        return false, 'invalid format'
    end
    return true
end


local function _v_check_value(val)
    local v = tonumber(val)
    if v and v > 0 and v < 100 then
        return true
    end

    return false, 'invalid version'
end


local function _sc_check_value(val, cmd)
    local m, e = ngx.re.match(val, "^([a-z,0-9]+)$")
    if not m then
        return false, 'invalid value', e
    end

    -- cmd: v_1,sc_a3 or sc_a3,v_1
    local m, e = ngx.re.match(cmd, "^[vsc]{1,2}_[0-9a-z]+,?[vsc]{0,2}_?[0-9a-z]*$")
    if not m then
        return false, 'mutually exclusive of cmd', e
    end
    return true
end


local function _c_check_value(val)
    local m, e = ngx.re.match(val, "^([a-z,0-9]{1,20})-?([0-9]{0,4})-?([0-9]{0,4})$")
    if not m then
        return false, 'invalid crop format', e
    end
    return true
end


local function _check_uint2(val)
    local m, e = ngx.re.match(val, "^([0-9]{1,4})-([0-9]{1,4})$")
    if not m then
        return false, 'invalid coordinates format', e
    end
    return true
end


local function _check_str(val)
    local m, e = ngx.re.match(val, "^([a-z,0-9]+)$")
    if not m then
        return false, 'invalid string', e
    end
    return true
end


local function _e_check_value(val)
    -- grayscale(), oilpaint(), negate(),brightness(),blur(),sharpen()
    local res = util.split(val, '%-', 2)
    if not res then
        return false
    end

    local effect = res[1]
    if effect == 'grayscale' or effect == 'oilpaint' or effect == 'negate' or effect == 'brightness' or 
       effect == 'blur' or effect == 'sharpen' or effect == 'red' or effect == 'green' or 
       effect == 'blue' or effect == 'yellow' or effect == 'gray' or effect == 'charcoal' or effect == 'spread' or 
       effect == 'contrast' or effect == 'dynamic' or effect == 'mosaic' then
        return true
    end

    return false, 'invalid effect'
end


local function _d_check_value(val)
    local res = util.split(val, '%-', 2)
    if not res then
        return false
    end

    local draw = res[1]
    if draw == 'rect' or draw == 'line' then
        return true
    end

    return false, 'invalid draw'
end


local _cmd_to_chkfunc = {
    c  = _c_check_value,
    w  = _w_check_value,
    h  = _h_check_value,
    r  = _r_check_val,
    re = _re_check_val,
    b  = _b_check_value,
    t  = _t_check_value,
    f  = _f_check_value,
    v  = _v_check_value,
    p  = _p_check_value,
    q  = _q_check_val,
    sc = _sc_check_value,
    e  = _e_check_value,
    d  = _d_check_value,
}


-- {ups={123={host='', ssig=''}, 45={host='',ssig=''}}, scmd={001='',002=''}}
local _M = {
    _VERSION = '0.10',
    -- 请求的sha1
    sha1     = 0,
    -- 指令
    cmdstr = "q_75",
    -- 文件名称
    file   = "test.png",
    -- 文件扩展名
    ext    = 'png',
    -- 通过命令的f指定了图片的格式
    c_fmt     = nil,
    c_sc      = nil,
    c_quality = 75,
    ups_host = 0,
}


setmetatable(_M, {
    __call = function(self, ...)
        return self.new(...)
    end
})


function _M.new()
    local t = {
        -- 指令集
        cmdkv_list = {},
        app_ups = {host='', ssig=nil, uri_prefix=nil},
    }

    for k,v in pairs(_M) do
        t[k] = v
        if type(v) == 'table' then
            t[k] = {}
        end
    end

    t.request_uri = ngx.var.request_uri
    t.raw_uri = '/'
    if t.request_uri then
        t.raw_uri = t.request_uri:gsub("?.*", "")
    end
    return t
end


function _M:Init()
    local ok, code, msg
    math.randomseed(ngx.now() * 1000)

    -- 解析请求
    ok, code, msg = self:_parse_request()
    if not ok then
        close()
        self:error(code, msg)
        return false
    end

    -- 解析指令
    ok, code, msg = self:_parse_cmd(nil)
    if not ok then
        close()
        self:error(code, msg)
        return false
    end

    -- 计算请求sha1
    self:_req_sha1()

    -- 用户信息初始化
    local get_info = function() {}
    local res, err, msg = self:imgxs_init(get_info)
    close()
    if not res then
        self:error(err, msg)
        return false
    end

    -- 指令输出
    self:_cmds_debug_log()

    return true
end


function _M:check_scmd()
    ngx.req.read_body()
    local body = ngx.req.get_body_data()
    if not body then
        self:error('InvalidSimplecmd', 'Invalid request body')
    end
    local res = cjson.decode(body)
    if not res or not res.scmd then
        self:error('InvalidSimplecmd', 'Invalid json')
    end

    local ok, err, msg = self:_parse_cmd(res.scmd)
    if not ok then
        self:error('InvalidSimplecmd', msg)
    else
        self:error('OK', string.format('simple cmd(%s) ok', res.scmd))
    end
end


function _M:check_ssig()
    ngx.req.read_body()
    local body = ngx.req.get_body_data()
    if not body then
        self:error('InvalidSsig', 'Invalid request body')
    end
    local header = cjson.decode(body)
    if not header or not header.ssig then
        self:error('InvalidSsig', 'Invalid json')
    end

    local hd  = {method = 'GET', uri = '/liwq/sae/test.jpg', date = ngx.http_time(ngx.time())}
    local res, err = self:get_ssig(hd, header.ssig)
    if not res then
        self:error('InvalidSsig', string.format('error: %s', err))
    else
        self:error('OK', string.format('ssig: %s', res))
    end
end


function _M.fmtRgba(s)
    local m, err = ngx.re.match(s or '', "^([0-9,a-f,A-F]{2})([0-9,a-f,A-F]{2})([0-9,a-f,A-F]{2})([0-9,a-f,A-F]{0,2})$")
    if not m then
        m = {'ff', '00', 'ff', '00'}
    end
    return string.format("rgba(0x%02s, 0x%02s, 0x%02s, 0x%02s)", m[1] or 'ff', m[2] or '00', m[3] or 'ff', m[4] or '00'), m
end


function _M:error(code, msg, ext)
    local debug = require 'debug'
    local bck   = debug.getinfo(2, 'l')
    -- ngx.log(ngx.INFO, debug.traceback())

    code = code or 'InvalidRequest'
    ngx.log(ngx.ERR, string.format('errorline[%d] request error. code: %s msg: %s', bck.currentline, code, msg))

    ngx.status = _error_to_http_status[code] or ngx.HTTP_BAD_REQUEST
    ngx.header["Content-Type"] = "application/json"

    local errmsg = {
        Message = msg or "",
        Code = code,
        Resource = self.raw_uri,
    }

    if ext then
        errmsg['code'] = ext
    end

    ngx.say(cjson.encode(errmsg))
    ngx.eof()
    ngx.exit(ngx.status)
end


function _M:get_ssig(header, ssigstr, req_headers)
    local ssig = ssigstr or self.app_ups.ssig

    if not ssig then
        return nil, 'Missing ssigstr'
    end
    ssig = ssig:gsub(' %. ', ' .. ')

    local f, err = loadstring('return ' .. ssig, "=user script")
    if not f then
        ngx.log(ngx.ERR, string.format('===user ssig script(%s) error, err: %s', ssig, err))
        return nil, err
    end

    local SCS_SSIG = function(ak, sk)
        local str = header.method .. '\n\n\n' .. header.date .. '\n' .. header.uri
        return 'SINA ' .. ak .. ':' .. string.sub(ngx.encode_base64(ngx.hmac_sha1(sk, str)), 6, 15)
    end

    local Sub_Str = function(str, start, length)
        local j = -1
        if length then
            j = start + length
            if length < 0 then
                j = j - 1
            end
        end
        return string.sub(str, start+1, j)
    end

    if not req_headers then
        req_headers = {}
    end

    setfenv(f,  { scs             = SCS_SSIG,
                  base64          = ngx.encode_base64,
                  hmac_sha1       = ngx.hmac_sha1,
                  md5             = ngx.md5,
                  http_time       = ngx.http_time,
                  escape_uri      = ngx.escape_uri,
                  unescape_uri    = ngx.unescape_uri,
                  substr          = Sub_Str,

                  METHOD          = header.method,
                  CONTENT_MD5     = header.content_MD5,
                  CONTENT_TYPE    = header.content_type,
                  DATE            = header.date,
                  DATE_STAMP      = header.datestamp,
                  RESOURCE        = header.uri,
                  REQHEADERS      = req_headers,
                }
            )
    local ok, res = pcall(f)
    if not ok then
        ngx.log(ngx.ERR, string.format('get ssig[%s] error. err: %s', ssig, res))
        return nil, res
    end
    ngx.log(ngx.DEBUG, string.format('===get ssig res: %s', res))
    return res
end


function _M:_req_sha1()
    local cmd = ""
    local ver = 0
    for _, cmdkv in ipairs(self.cmdkv_list) do
        self.c_sc  = cmdkv['sc']
        self.c_fmt = cmdkv['f'] or self.c_fmt
        self.c_quality = tonumber(cmdkv['q']) or self.c_quality
        ver = cmdkv['v']
        cmdkv['v'] = nil
        cmd = cmd .. util.table_to_str(cmdkv)
        cmdkv['v'] = ver
    end
    self.sha1 = util.convert_bin_to_hex(ngx.sha1_bin(self.appname .. cmd .. self.ups_host .. self.file .. (ver or '')))
    _, _, self.ext  = util.get_filename(self.file)
end


function _M:_parse_request()
    local regex = '^/(?<cmd>[^/]+)/(?<upshost>[^/]+)/(?<file>.+)$'
    local raw_uri = ngx.unescape_uri(self.raw_uri)
    local m, err = ngx.re.match(raw_uri, regex)
    if m then
        self.cmdstr   = m['cmd']
        self.ups_host = m['upshost']
        self.file     = string.gsub(ngx.escape_uri(m['file']), "%%2F", "/")
    else
        ngx.log(ngx.ERR, string.format('match uri(%s) error. err: %s', raw_uri, err))
        return nil, 'InvalidRequest', 'url format(/cmd/upshost/file) error'
    end
    return self
end


function _M:_parse_sub_cmd(idx, sub_cmd)
    sub_cmd = ngx.unescape_uri(sub_cmd)
    local lines = util.split(sub_cmd, ',')

    if #lines == 0 then
        return false, 'InvalidRequest', "Missing SubCmd"
    end
    local cmdkv = {}
    for _, v in ipairs(lines) do
        local m, err = ngx.re.match(v, "^([a-z]{1,2})_(.+)$")
        if m and #m == 2 and _cmd_to_chkfunc[m[1]] then
            local res, err, detail = _cmd_to_chkfunc[m[1]](m[2], self.cmdstr)
            if not res then
                ngx.log(ngx.ERR, "check cmd value error. err: ", err, '. error detail:', detail)
                return false, 'InvalidRequest', string.format('Group[%d] SubCmd(%s_%s) %s', idx, m[1], m[2], err)
            end
            cmdkv[m[1]] = m[2]
        else
            ngx.log(ngx.ERR, string.format("sub_cmd(%s) format error. err: %s", v, err))
            return false, 'InvalidRequest', string.format("Group[%d] SubCmd(%s) Invalid Key", idx, v)
        end
    end
    self.cmdkv_list[idx] = cmdkv

    return self
end


function _M:_parse_cmd(cmd)
    self.cmdkv_list = {}
    local cmds = util.split(cmd or self.cmdstr, '%|')
    for i, v in ipairs(cmds) do
        local ok, code, msg = self:_parse_sub_cmd(i, v)
        if not ok then
            return false, code, msg
        end
    end

    return self
end


function _M:_cmds_debug_log()
    local s = cjson.encode(self.cmdkv_list)
    ngx.log(ngx.DEBUG, "[request cmd:] ", s)
    ngx.log(ngx.DEBUG, "[request upshost:] ", self.ups_host)
    ngx.log(ngx.DEBUG, "[request sha1:] ", self.sha1)
end


-- todo
function _M:imgxs_init(func)
    if self.c_sc then
        local ok, err, msg = self:_parse_cmd("w_100,h_100")
        if not ok then
            return nil, err, msg
        end
    end

    if self.ups_host then
        local res = util.split(self.ups_host, ',')
        if #res > 0 then
            -- Select the upstream host
            self.app_ups.host = res[1]
        else
            ngx.log(ngx.ERR, string.format('%s no upshost', key))
            return nil, 'InvalidRequest', 'Missing ups'
        end
    end

    return true
end


function _M:img_process(img, cmdkv)
    local c_pf = cmdkv['pf']
    -- c_100-100
    local c_c  = cmdkv['c']
    -- q_85
    local c_q  = cmdkv['q']
    -- c_100
    local c_w  = cmdkv['w']
    -- h_100
    local c_h  = cmdkv['h']
    -- r_360
    local c_r  = cmdkv['r']
    -- bo_10-3-ff00ffaa  bo_10-ff00ffaa
    local c_b  = cmdkv['b']
    -- f_png
    local c_f  = cmdkv['f']
    -- e_brightness--20
    local c_e  = cmdkv['e']
    local c_d  = cmdkv['d']
    -- v_001
    local c_v  = cmdkv['v']
    -- re_30
    local c_re = cmdkv['re']
    -- t_text-size-color-x-y
    local c_t  = cmdkv['t']
    -- p_sae.png-w-h-x-y
    local c_p  = cmdkv['p']


    if c_f then
        img = img:format(c_f)
    end

    if not c_pf then
        img:removeProfile()
    end

    -- 剪裁
    if c_c then
        local cropGravity = function(gravity, w, h)
            if not (w and h) or gravity == '' then
                return 0, 0, 0, 0
            end

            local call_opencv = function(gravity, img)
                if w > 4000 or h > 3000 then
                    return {x=0, y=0, w=w, h=h}, {{x=0, y=0, w=w, h=h}}
                end

                local byt = img:toPixels('byte', 'RGB')
                local cv = opencv()
                cv:cvImgxs(w, h, byt, 8, 3)
                local bigger = 1
                if gravity == "faces" then
                    bigger = nil
                end
                local res, ress = cv:cvObjectDetect((conf.haar[gravity] or conf.haar["none"]), bigger)
                cv:release()
                return res, ress
            end
            if gravity and (gravity == "face" or gravity == "faces" or gravity == "facealt" or gravity == "facetree"
                        or  gravity == "eyepair" or gravity == "lefteye" or gravity == "righteye"
                        or  gravity == "mouth"   or gravity == "nose") then
                local ok, res, ress = pcall(call_opencv, gravity, img)
                if not ok then
                    ngx.log(ngx.INFO, string.format('call_opencv return error. gravity: %s err: %s', gravity, res))
                    return 0, 0, w, h
                end
                ngx.log(ngx.INFO, "res:  ", cjson.encode(res))
                ngx.log(ngx.INFO, "ress: ", cjson.encode(ress))

                if gravity == "faces" then
                    return res.x, res.y, res.w, res.h
                elseif #ress > 0 then
                    return ress[1].x+ress[1].w*0.5, ress[1].y+ress[1].h*0.5, ress[1].w, ress[1].h
                end
                return 0, 0, w, h
            end

            local gx, gy = w*3/6, h*3/6
            if gravity and gravity == "centergreed" then
                local greed = w
                if greed > h then
                    greed = h
                end
                return gx, gy, greed, greed
            end

            if not gravity then
                gravity = string.lower(conf.gravity['none'])
            end
            if 'forget' == gravity then
                return 0, 0, w, h
            end


            if string.find(gravity, 'north') then
                gy = h/6
            end
            if string.find(gravity, 'south') then
                gy =  h*5/6
            end
            if string.find(gravity, 'west') then
                gx = w/6
            end
            if string.find(gravity, 'east') then
                gx = w*5/6
            end
            return gx, gy, w/3, h/3
        end

        local res = util.split(c_c, '%-')
        local w, h = img:size()
        local g, x, y = tostring(res[1]), tonumber(res[2]) or 0, tonumber(res[3]) or 0
        if #res == 2 and tonumber(res[1]) then
            x, y = tonumber(res[1]) or 0, tonumber(res[2]) or 0
            g = ""
        end
        if g and g ~= "" then
            local tx, ty, tw, th = cropGravity(g, w, h)
            w, h = tw, th
            x = tx + x
            y = ty + y
        end
        if c_w or c_h then
            w, h = img:keepScale(tonumber(c_w), tonumber(c_h))
        end
        if g and g~= "" then
            x = x - w/2
            y = y - h/2
            if x < 0 then
                x = 0
            end
            if y < 0 then
                y = 0
            end
        end
        img = img:crop(w, h, x, y)

    -- 大小
    elseif (c_w or c_h) and not c_c then
        local w, h = img:keepScale(tonumber(c_w), tonumber(c_h))
        img = img:size(tonumber(w), tonumber(h))
    end

    -- 圆角剪裁 ＋ 边框
    if c_r then
        c_r = c_r == 'max' and 360 or c_r
        local res = util.split(c_b, '%-')
        local rgba = self.fmtRgba((res[3] or res[2]))

        img = img:roundedCorner(tonumber(c_r), tonumber(res[1]), rgba)
    end

    -- 非圆角剪裁 ＋ 边框
    if c_b and not c_r then
        local res = util.split(c_b, '%-')

        local _, m = self.fmtRgba((res[3] or res[2]))
        local w = res[1]
        local h = #res==3 and res[2] or w
        img = img:addBorder(tonumber(w), tonumber(h), tonumber(m[1], 16), tonumber(m[2], 16), tonumber(m[3], 16))
    end

    -- 旋转 re_degrees
    if c_re then
        if c_re == 'flip' then
            img = img:flip()
        elseif c_re == 'flop' then
            img = img:flop()
        else
            img = img:rotate(tonumber(c_re), 0xff, 0xff, 0xff, 0xff)
        end
    end

    if c_d then
        local res = util.split(c_d, '%-')
        local draw = res[1]
        local w, h = img:size()

        -- d_rectangle-x1-y1-x2-y2-color-radius
        if draw == 'rect' then
            local x1 = tonumber(res[2]) or 0
            local y1 = tonumber(res[3]) or 0
            local x2 = tonumber(res[4]) or w/10
            local y2 = tonumber(res[5]) or h/10
            local rgba    = self.fmtRgba(res[6])
            local radius  = tonumber(res[7]) or 0
            img = img:rectangle(x1, y1, x2, y2, rgba, radius)
        elseif draw == 'line' then
            -- d_line-sx-sy-ex-ey-color
            local sx = tonumber(res[2]) or 0
            local sy = tonumber(res[3]) or 0
            local ex = tonumber(res[4]) or w/10
            local ey = tonumber(res[5]) or h/10
            local rgba    = self.fmtRgba(res[6])
            img = img:line(sx, sy, ex, ey, rgba)
        end
    end

    if c_e then
        local res = util.split(c_e, '%-')
        local effect = res[1]
        local prm    = tonumber(res[2]) or res[2]

        if effect == 'grayscale' then
            img = img:type('Grayscale')
        elseif effect == 'oilpaint' then
            if not prm or prm < 1 or prm > 8 then
                prm = 3
            end
            img = img:oilPaint(prm)
        elseif effect == 'negate' then
            img = img:negate()
        elseif effect == 'brightness' then
            if not prm or prm < 0 or prm > 1000 then
                prm = 120
            end
            img = img:modulate(prm)
        elseif effect == 'blur' then
            local w = img:size()
            if not prm or prm < 1 or prm > 2000 then
                prm = 50
            end
            local radius = 1 + (math.log(prm) / math.log(1.8))
            img = img:blur(radius, w)
        elseif effect == 'sharpen' then
            local w = img:size()
            if not prm or prm < 1 or prm > 2000 then
                prm = 50
            end
            local radius = 1 + (math.log(prm) / math.log(2.1))
            img = img:sharpen(radius, w)
        elseif effect == 'contrast' then
            img = img:contrast(1)

        elseif effect == 'red' then
            if not prm or prm < 1 or prm > 100 then
                prm = 2
            end
            img = img:gammaCorrection(prm, 'Red')
        elseif effect == 'green' then
            if not prm or prm < 1 or prm > 100 then
                prm = 2
            end
            img = img:gammaCorrection(prm, 'Green')
        elseif effect == 'blue' then
            if not prm or prm < 1 or prm > 100 then
                prm = 2
            end
            img = img:gammaCorrection(prm, 'Blue')
        elseif effect == 'yellow' then
            if not prm or prm < 1 or prm > 100 then
                prm = 2
            end
            img = img:gammaCorrection(prm, 'Yellow')
        elseif effect == 'gray' then
            if not prm or prm < 1 or prm > 100 then
                prm = 2
            end
            img = img:gammaCorrection(prm, 'Gray')
        elseif effect == 'spread' then
            if not prm or prm < 1 or prm > 100 then
                prm = 2
            end
            img = img:spread(prm)
        elseif effect == 'charcoal' then
            if not prm or prm < 1 or prm > 100 then
                prm = 2
            end
            local w = img:size()
            local sigma = 1 + (math.log(prm) / math.log(2.1))
            img = img:charcoal(sigma, w)
        elseif effect == 'dynamic' then
            local delay = tonumber(res[3]) or 100
            local pic = ngx.decode_base64(prm)
            if pic then
                local cap, err = ngx.re.match(pic, '^(?<prefix>.+)\\[(?<series>[0-9\\,]*)\\](?<suffix>\\.?.*)$')
                if cap then
                    local w, h = img:size()
                    local itm = util.split(cap['series'] or '', '%,', 8)
                    for i, v in ipairs(itm) do
                        local picfile  = cap['prefix'] .. v .. cap['suffix']
                        local savefile = conf.cache_path .. '/' .. self.appnamecrc32 .. '/dynamic-' .. prm:sub(1,20) .. v
                        if picfile:byte(1, 1) ~= 47 then
                            picfile = '/' .. picfile
                        end
                        if self.app_ups.uri_prefix and (not string.match(picfile, self.app_ups.uri_prefix .. '/.*')) then
                            picfile = self.app_ups.uri_prefix .. picfile
                        end
                        ngx.log(ngx.DEBUG, 'dynamic pic: ', picfile)
                        local ok = self:imgxs_download(picfile, savefile, true)
                        if ok then
                            local ok, picImg = pcall(image, savefile)
                            if ok then
                                if i == 1 then
                                    img:delay(delay)
                                    img:iterations(0)
                                end
                                img:next()
                                img:add(picImg:size(w,h):delay(delay):iterations(0))
                            else
                                ngx.log(ngx.ERR, string.format('load dynamic pic file(%s) error. err: %s', savefile, picImg))
                            end
                        end
                        os.remove(savefile)
                    end
                else 
                    ngx.log(ngx.WARN, 'err: ', err)
                end
            end
            img:resetIterator()
        elseif effect == 'mosaic' then
            -- e_mosaic--w-h-x-y
            img:resetIterator()
            local w, h = img:size()
            local ew   = tonumber(res[3]) or 0
            local eh   = tonumber(res[4]) or 0
            if ew == 0 and eh == 0 then
                ew = w/5
            end

            local x    = tonumber(res[5]) or 0
            local y    = tonumber(res[6]) or 0
            local tmpimg = img:clone()

            local pic  = ngx.decode_base64(prm or '')
            if pic and string.len(pic) > 0 then
                if pic:byte(1, 1) ~= 47 then
                    pic = '/' .. pic
                end
                if self.app_ups.uri_prefix and (not string.match(pic, self.app_ups.uri_prefix .. '/.*')) then
                    pic = self.app_ups.uri_prefix .. pic
                end

                local savefile = conf.cache_path .. '/' .. self.appnamecrc32 .. '/mosaic-' .. string.sub(res[2], 1, 20)
                local ok = self:imgxs_download(pic, savefile, true)
                if ok then
                    local ok, picImg = pcall(image, savefile)
                    if ok then
                        tmpimg = picImg
                    end
                    os.remove(savefile)
                end
            end
            tmpimg:size(tmpimg:keepScale(ew, eh)):page(0,0,x,y)
            tmpimg:next()
            img = tmpimg:add(img)
            img:mosaic()
        end
    end

    -- 水印 文字 t_text-font-size-color-gravity-x-y-angle-backcolor
    if c_t then
        local res   = util.split(c_t, '%-')
        local font  = conf.font[string.lower(res[2] or 'none')]
        local size  = tonumber(res[3]) or 10
        local color = self.fmtRgba(res[4])
        local gravity = conf.gravity[string.lower(res[5] or 'none')]
        local x, y    = tonumber(res[6]) or 0, tonumber(res[7]) or 0
        local angle   = tonumber(res[8]) or 0
        local underColor = nil
        if res[9] then
            underColor = self.fmtRgba(res[9])
        end

        if not font or font == '' then
            font = conf.font['none']
        end
        if not gravity or gravity == '' then
            gravity = conf.gravity['none']
        end
        if (gravity == 'Forget' or string.find(string.lower(gravity), 'north')) and y == 0 then
            y = size * 0.8
        end
        -- ngx.log(ngx.INFO, string.format('=t========%s=%d:%d', gravity, x, y))
        img:resetIterator()
        -- repeat
            img:setText(res[1], size, color, font, gravity, x, y, angle, underColor)
        -- until (self.c_fmt ~= 'gif' and self.c_fmt ~= 'GIF') or not img:next()
    end

    -- 水印 图片 p_sae.png-w-h-gravity-x-y-re
    if c_p then
        local deGravity = function(gravity, w, h, pw, ph)
            if not (w and h and pw and ph) or gravity == '' then
                return 0, 0
            end
            if not gravity then
                gravity = string.lower(conf.gravity['none'])
            end
            if 'forget' == gravity then
                return 0, 0
            end

            local gx, gy = w/2-pw/2, h/2-ph/2
            if string.find(gravity, 'north') then
                gy = 0
            end
            if string.find(gravity, 'south') then
                gy =  h - ph;
            end
            if string.find(gravity, 'west') then
                gx = 0
            end
            if string.find(gravity, 'east') then
                gx = w - pw
            end
            return gx, gy
        end


        local res = util.split(c_p, '%-')
        local logo     = ngx.decode_base64(res[1])
        if not logo then
            return img
        end
        local logofile = conf.cache_path .. '/' .. self.appnamecrc32 .. '/logo-' .. string.sub(res[1], 1, 20)
        local logopath = '/' .. logo
        if logo:byte(1,1) == 47 then
            logopath = logo
        end
        if self.app_ups.uri_prefix and (not string.match(logopath, self.app_ups.uri_prefix .. '/.*')) then
            logopath = self.app_ups.uri_prefix .. logopath
        end
        ngx.log(ngx.DEBUG, 'logo: ', logo)
        local ok = self:imgxs_download(logopath, logofile)
        if ok then
            local ok, logoImg = pcall(image, logofile)
            if not ok then
                ngx.log(ngx.ERR, string.format('load logo file error. err: %s', logoImg))
            else
                os.remove(logofile)
                local olw, olh = logoImg:size()
                local nlw, nlh = tonumber(res[2]) or 0, tonumber(res[3]) or 0
                if nlw == 0 and nlh == 0 then
                    nlw, nlh = olw, olh
                else
                    nlw, nlh = logoImg:keepScale(nlw, nlh)
                end

                logoImg:size(nlw, nlh)
                local iw, ih  = img:size()
                local gx, gy  = deGravity(res[4], iw, ih, nlw, nlh)

                local x, y    = tonumber(res[5]) or 0, tonumber(res[6]) or 0
                if x < 0 or x > iw then
                    x = 1
                end
                if y < 0 or y > ih then
                    y = 1
                end

                if #res == 7 and tonumber(res[7]) then
                    logoImg:rotate(tonumber(res[7]), 0xff, 0xff, 0xff, 0xff)
                end
                -- ngx.log(ngx.INFO, string.format('=p========%d:%d=%d:%d', gx, gy, gx+x, gy+y))
                img:resetIterator()
                -- repeat
                    img:compose(logoImg, 'Over', gx+x, gy+y)
                -- until (self.c_fmt ~= 'gif' and self.c_fmt ~= 'GIF') or not img:next()
            end
        end
    end

    return img
end

function _M:imgxs(file, cachefile)
    ngx.log(ngx.DEBUG, 'load file: ', file)
    local ok, img = pcall(image, file)
    if not ok then
        ngx.log(ngx.ERR, string.format('load imgx error. file: [%s] err: [%s]', file, img))
        return false, 'NotFound'
    end
    local width, height = img:size()
    self.fmt = img:format():lower()
    if not conf.file_type[self.fmt] or width < 1 or height < 1 then
        return false, 'InvalidFileType'
    end

    for _, cmdkv in ipairs(self.cmdkv_list) do
        img = self:img_process(img, cmdkv)
    end

    ngx.log(ngx.INFO, string.format('save cache file: %s, quality: %d', cachefile, self.c_quality))
    if self.c_fmt == 'gif' or self.c_fmt == 'GIF' then
        img:saveImages(cachefile)
    else
        img:save(cachefile, self.c_quality)
    end
    return true
end


function _M:imgxs_download(path, savefile, norepeat)
    ngx.log(ngx.DEBUG, savefile)
    local basePath = util.get_filename(savefile)
    local ip_list = {}

    if not util.file_exist(basePath) then
        util.mkdir(basePath)
    end

    local downloadsha1 = ngx.sha1_bin(path)
    local lock, err = resty_lock:new("download_locks")
    if not lock then
        ngx.log(ngx.ERR, 'lock new error. err: ', err)
        return false, 'InternalError'
    end
    local elapsed, err = lock:lock(downloadsha1)
    if not elapsed then
        ngx.log(ngx.ERR, 'lock error. err: ', err)
        return false, 'InternalError'
    end

    if util.file_exist(savefile) then
        lock:unlock()
        return true
    end

    local res, err = ngx.re.match(self.app_ups.host, '^([0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}[:,0-9]{0,6})$')
    if res then
        ip_list = util.split(res[1], ',')
    else
        local resolver_cache = ngx.shared.resolver_cache
        local ipstr = resolver_cache:get(self.app_ups.host)
        if not ipstr then
            ip_list, err = util.resolver_query(self.app_ups.host)
            if not ip_list then
                lock:unlock()
                ngx.log(ngx.WARN, string.format('resolver(%s) results error. err: %s', self.app_ups.host, err))
                return false, 'UpstreamError', 'resolver host error'
            end
            ipstr   = cjson.encode(ip_list)
            resolver_cache:set(self.app_ups.host, ipstr, 300)
        else
            ip_list = cjson.decode(ipstr)
            ngx.log(ngx.DEBUG, string.format('resolver_cache(%s) hit: %s', self.app_ups.host, ipstr))
        end
    end

    if not ip_list or #ip_list == 0 then
        lock:unlock()
        ngx.log(ngx.WARN, string.format('resolver(%s) results null', self.app_ups.host))
        return false, 'UpstreamError', 'resolver host null'
    end

    local code, msg = util.AGAIN, ''
    local rtimes = 3
    local now_time = ngx.time() + 300
    local hd  = {method = 'GET', host = self.app_ups.host, uri = path, date = ngx.http_time(now_time), datestamp = now_time}

    local reqHeaders = {accept="image/*"}
    if conf.ups_hide_header and not conf.ups_hide_header[1] then
        reqHeaders = ngx.req.get_headers()
        for k in pairs(reqHeaders) do
            local hide = conf.ups_hide_header[string.lower(k)]
            if hide then
                if type(hide) == 'boolean' then
                    reqHeaders[k] = nil
                else
                    reqHeaders[k] = hide
                end
            end
        end
    end

    hd.auth = self:get_ssig(hd, nil, reqHeaders)
    repeat
        local idx = math.random(#ip_list)
        local ip  = ip_list[idx]
        code, msg = util.download(savefile, ip, 80, hd, reqHeaders)
        if util.JUMP == code and not norepeat then
            hd.uri  = msg
            hd.auth = self:get_ssig(hd, nil, reqHeaders)
            code, msg = util.download(savefile, ip, 80, hd, reqHeaders)
        elseif util.NOTFOUND == code and not norepeat then
            local notfound = util.get_filename(path)
            notfound = notfound .. '/notfound.jpg'
            hd.uri = notfound
            hd.auth = self:get_ssig(hd, nil, reqHeaders)
            code, msg = util.download(savefile, ip, 80, hd, reqHeaders)
        end
        rtimes = rtimes - 1
    until code ~= util.AGAIN or rtimes < 1
    lock:unlock()


    if code == util.OK then
        self.download_length = self.download_length + (tonumber(msg) or 0)
        return true
    end

    if code == util.UPSERR then
        return false, 'UpstreamError', msg
    elseif code == util.NOTFOUND then
        return false, 'NotFound'
    end

    ngx.log(ngx.WARN, string.format('imgx download code %s msg: %s', code, msg))
    return false, 'InternalError'
end


function _M:Process()
    local etag = ngx.req.get_headers()["If-None-Match"] or ngx.req.get_headers()["if-none-match"]
    if etag and etag == tostring(self.sha1) then
        ngx.exit(ngx.HTTP_NOT_MODIFIED)
    end

    local execFile = '/' .. self.sha1
    if self.ext then
        execFile = execFile .. '.' .. self.ext
    end
    if self.c_fmt and (not self.ext or self.c_fmt ~= self.ext) then
        execFile = execFile .. '.' .. self.c_fmt
    end

    local cachepathfile = (conf['cache_path'] or '.') .. execFile
    local exist = util.file_exist(cachepathfile)
    if not exist then
        local upsimg  = util.convert_bin_to_hex(ngx.sha1_bin(self.file))
        local upsfile = conf['cache_path'] .. '/upsimg_' .. upsimg
        local path    = '/' .. self.file
        local ok, dcode, dmsg = self:imgxs_download(path, upsfile)
        if not ok then
            ngx.log(ngx.ERR, string.format('download imgx error. errmsg: %s', dmsg))
            self:error(dcode, dmsg)
            return false
        end
        local ok, err = self:imgxs(upsfile, cachepathfile)
        os.remove(upsfile)
        if not ok then
            self:error(err)
            return false
        end
    end

    if exist then
        ngx.log(ngx.DEBUG, 'file cache hit')
    end
    ngx.header["ETag"] = tostring(self.sha1)
    ngx.header['Content-Type'] = conf.file_type[self.c_fmt or self.ext or 'png']
    ngx.exec(conf.exec_path .. execFile)
    return true
end


function _M:Clean()
    ngx.log(ngx.INFO, "clean: " .. self.cmdstr)
end

return _M

