-- Copyright (c) 2017 liwq, SAE


local memcached  = require "resty.memcached"
local resolver = require "resty.dns.resolver"
local cjson = require "cjson.safe"
local http = require "resty.http"
local luaext = require "luaext"


local _M = {
    _VERSION = '0.10',
    OK = true,
    ERR = false,
    EXISTS = true,
    NOTEXISTS = false,
    AGAIN    = 1,
    NOTFOUND = 2,
    JUMP     = 3,
    UPSERR   = 4,
}

function _M.split(str, sep, maxsplit)
    local t = {}
    if not (str and sep) then
        return t
    end

    if maxsplit and maxsplit == 1 then
        table.insert(t, str)
        return t
    end

    local pattern = "(.-)" .. sep
    local last_end = 1
    local s, e, cap = str:find(pattern, 1)
    while s do
        table.insert(t, cap)
        if maxsplit and #t + 1 == maxsplit then
            last_end = e + 1
            break
        end
        last_end = e + 1
        s, e, cap = str:find(pattern, last_end)
    end
    cap = str:sub(last_end)
    table.insert(t, cap)
    return t
end

function _M.convert_bin_to_hex(bytes)
    local b, i, str
    local hex = ''
    for i = 1, string.len(bytes) do
        b = string.byte(bytes, i, i)
        str = string.format("%02x", b)
        hex = hex .. str
    end
    return hex
end

function _M.get_filename(path)
    -- path  = ngx.unescape_uri(path)
    local sub_paths = _M.split(path, '/')
    local filename = sub_paths[#sub_paths]
    sub_paths[#sub_paths] = nil
    local sub_names = _M.split(path, '%.')
    local ext_name = nil
    if #sub_names > 1 then
        ext_name = sub_names[#sub_names]
    end
    return table.concat(sub_paths, '/'), filename, ext_name and string.lower(ext_name) 
end


function _M.file_exist(file)
    return luaext.access(file, luaext.CONST.F_OK) 
end

function _M.mkdir(path)
    return luaext.mkdir(path, luaext.bor(luaext.CONST.S_IRWXU, luaext.CONST.S_IRGRP, luaext.CONST.S_IXGRP, luaext.CONST.S_IROTH, luaext.CONST.S_IXOTH))
end

function _M.table_to_str(t)
    local a = {}
    local s = ""
    for k in pairs(t) do
        table.insert(a, k)
    end
    table.sort(a)
    for _, k in ipairs(a) do
        s = s .. k .. '=' .. t[k] .. ', '
    end
    return s
end


function _M.resolver_query(domain)
    local r, err = resolver:new{
        nameservers = {"114.114.114.114", {"223.5.5.5", 53} },
        retrans = 5,
        timeout = 2000,
    }
    if not r then
        -- ngx.say("failed to instantiate resolver: ", err)
        return nil, err
    end

    local ans, err = r:query(domain,  {qtype = r.TYPE_A})
    if not ans then
        return nil, err
    end
    if ans.errcode then
        return nil, string.format('server return error. err: %d - %s', ans.errcode, ans.errstr)
    end

    local ip_list = {}
    for i, a in ipairs(ans) do
        table.insert(ip_list, a.address)
    end
    return ip_list
end

function _M.tmp_file(file)
    local tmpfile
    math.randomseed(ngx.now() * 1000)
    tmpfile = file .. '_' .. tostring(ngx.time()) .. '_' .. tostring(math.random(10000)) .. '.tmp'
    return tmpfile
end


function _M.download(file, ip, port, header, req_headers)
    ngx.log(ngx.DEBUG, string.format('download from (%s) uri: %s heads: %s req_headers: %s', ip, header.uri, cjson.encode(header), cjson.encode(req_headers)))
    if not req_headers or type(req_headers) ~= 'table' then
        req_headers = {}
    end

    req_headers["host"] = header.host
    req_headers["user-agent"] = header.user_agent or "SAEIMGXS/0.1.0"
    req_headers["date"] = header.date
    req_headers['authorization'] = header.auth

    local ipp   = _M.split(ip, '%:')
    local httpc = http.new()
    httpc:set_timeout(3000)
    httpc:connect(ipp[1], tonumber(ipp[2]) or port)
    local res, err = httpc:request{
        path = header.uri or '/',
        method = header.method or 'GET',
        headers = req_headers,
    }
    if not res then
        pcall(http.close, httpc)
        return _M.AGAIN, err
    end

    ngx.log(ngx.INFO, string.format('download from %s(%s) uri: %s. status: %s content-length: %d', (header.host or ''), ip, header.uri, res.status or 0, res.headers['Content-Length'] or 0))

    if res.status == 404 then
        return _M.NOTFOUND, string.format('resp status %d', res.status)
    end

    -- if res.status == 302 or res.status == 304 then
    --     return _M.JUMP, res.headers['Location'] or res.headers['location']
    -- end

    if res.status == 502 or res.status == 504 then
        pcall(http.close, httpc)
        return _M.AGAIN, string.format('resp status %d', res.status)
    end

    if res.status ~= 200 then
        return _M.UPSERR, res.reason
    end

    local reader = res.body_reader
    local tmpfile = _M.tmp_file(file)
    local fp, ferr = io.open(tmpfile, 'w+')
    if not fp then
        pcall(http.close, httpc)
        return _M.ERR, ferr
    end

    local length = 0
    repeat
        local chunk, rerr = reader(8192)
        if rerr then
            fp:close()
            pcall(http.close, httpc)
            return _M.ERR, rerr
        end

        if chunk then
            length = length + string.len(chunk)
            local wres, werr = fp:write(chunk)
            if not wres then
                fp:close()
                pcall(http.close, httpc)
                os.remove(tmpfile)
                return _M.ERR, wres
            end
        end
    until not chunk

    fp:close()
    pcall(http.close, httpc)
    local mvok, mverr = os.rename(tmpfile, file)
    if not mvok then
        os.remove(tmpfile)
        return _M.ERR, mverr
    end

    return _M.OK, res.headers['Content-Length'] or length
end


function _M.NewMC(mchost)
    local mc, err = memcached:new()
    if not mc then
        return nil, err
    end
    mc:set_timeout(2000)

    local idx, retry, ok, err = math.random(table.maxn(mchost)), 3, false, ''
    repeat
        ok, err = mc:connect(mchost[idx].ip, mchost[idx].port)
        retry   = retry - 1
        idx     = idx + 1
        if idx > table.maxn(mchost) then
            idx = 1
        end
    until ok or retry < 1
    if not ok then
        return nil, string.format('connect memcached(%s:%d) error, err: %s', mchost[idx].ip, mchost[idx].port, err)
    end

    return mc
end

return _M
