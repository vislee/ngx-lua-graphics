-- Copyright (c) 2017-2018 vislee

conf = {
    file_type = {
        jpeg = 'image/jpeg',
        png  = 'image/png',
        jpg  = 'image/jpeg',
        webp  = 'image/webp',

        accept = function(self)
            local a = ''
            for _, v in pairs(self) do
                if type(v) == 'string' then
                    a = string.format('%s,%s', a, v)
                end
            end
            return a:sub(2)
        end
    },
    gravity  = {
        none      = 'Forget',
        northwest = 'NorthWest',
        north     = 'North',
        northeast = 'NorthEast',
        west      = 'West',
        center    = 'Center',
        east      = 'East',
        southwest = 'SouthWest',
        south     = 'South',
        southeast = 'SouthEast',
    },
    font = {
        none    = '/usr/local/restylua/imgxs/fonts/msfs.ttf',     -- 微软仿宋
        msfs    = '/usr/local/restylua/imgxs/fonts/msfs.ttf',     -- 微软仿宋
    },
    haar = {
        none  = '/usr/local/restylua/imgxs/opencv/haarcascade_frontalface_alt.xml',
        face  = '/usr/local/restylua/imgxs/opencv/haarcascade_frontalface_alt2.xml',
    },
    cache_path = "/temp/cache",
    exec_path = "/imgx/cache/",
    ups_hide_header = {
        false,
        ['date'] = true,
        ['connection'] = true,
        ['accept-encoding'] = true,
        ['accept'] = true,
        ['cache-control'] = true,
    },
}

conf['ups_hide_header']['accept'] = conf.file_type:accept()
return conf
