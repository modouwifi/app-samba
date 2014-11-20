package.path        = "./?.lua;/usr/local/share/lua/5.1/?.lua;"
                      .. "/usr/local/share/lua/5.1/?/init.lua;"
                      .. "/usr/local/lib/lua/5.1/?.lua;"
                      .. "/usr/local/lib/lua/5.1/?/init.lua;"
                      .. "/system/share/lua/5.1/?.lua;"
                      .. "/data/share/lua/5.1/?.lua";
package.cpath       = "./?.so;/usr/local/lib/lua/5.1/?.so;"
                      .. "/usr/local/lib/lua/5.1/loadall.so;"
                      .. "/system/lib/lua/5.1/?.so;/data/lib/lua/5.1/?.so";

local json      = require "dkjson";
local util      = require "lutil";

require "os";
require "io";
require "string";
require "table"

function smb_flushjson(path)
  local res;
  local datajson = path .. "/../conf/data.json"
  local viewjson = path .. "/../conf/views.json"
  local mobileviewjson = path .. "/../conf/mobile_views.json"
  local matchfile = path .. "/../conf/match.conf"
  local tmpfile = path .. "/../conf/tmp.conf"
  local matchslice;
  local node, nodetmp, mode, passwd, viewitems;
  local strdata, strview;
  local data, view;
  local nodemodeindex, nodeuserindex, nodepasswdindex;
  local indexcount = 1;
  local cmdnote = 'mount | grep "/media/" | cut -d " " -f3'

  local fddata = io.open(datajson)
  if fddata then
    strdata = fddata:read("*all");
    fddata:close()
    data = json.decode(strdata)
  end

  local fdview = io.open(viewjson)
  if fdview then
    strview = fdview:read("*all")
    fdview:close()
    view = json.decode(strview)
  end

  for line in io.lines(matchfile) do
    matchslice = string.split(line, "_")
    nodetmp = string.split(matchslice[1], "/")
    for realnode in io.lines(tmpfile) do
      if realnode == matchslice[1] then
        node = nodetmp[2];
        mode = matchslice[2];
        passwd = matchslice[3];
        nodemodeindex = node .. "_share_mode"
        nodeuserindex = node .. "_share_username"
        nodepasswdindex = node .. "_share_passwd"
        -- for data.json
        data[nodepasswdindex] = {
          id = nodepasswdindex,
          name = "密码",
          value = passwd,
          group_id = "main_info_display",
          ["type"] = {
            class = "STRING",
            min = 2,
            max = 30,
          }
        }
        if mode == "0" or mode == "2" then
          data[nodeuserindex] = {
            id = nodeuserindex,
            name = "用户名",
            value = "matrix",
            group_id = "main_info_display",
            ["type"] = {
              class = "STRING",
              min = 2,
              max = 30,
            }
          }
          data[nodemodeindex] = {
            id = nodemodeindex,
            name = "加密共享",
            value = true,
            group_id = "main_info_display",
            ["type"] = {
              class = "BOOL",
            }
          }
        else
          data[nodeuserindex] = {
            id = nodeuserindex,
            name = "用户名",
            value = "guest",
            group_id = "main_info_display",
            ["type"] = {
              class = "STRING",
              min = 2,
              max = 30,
            }
          }
          data[nodemodeindex] = {
              id = nodemodeindex,
              name = "加密共享",
              value = false,
              group_id = "main_info_display",
              ["type"] = {
                class = "BOOL",
              }
            }
        end
        -- for view.json
        viewitems = view["main_page_samba"]["menu"]["2"]["items"]
        viewitems[tostring(indexcount)] = {
            index = indexcount,
            text  = node,
            ["type"]  = "VIEW",
            viewid =  "page_account_setting"..tostring(indexcount)
        }
        view["page_account_setting" .. tostring(indexcount)] = {
            id = "page_account_setting"..tostring(indexcount),
            name = node .. "配置",
            ["type"] = "sub",
            data = {
              nodepasswdindex = {
                id = nodepasswdindex,
                access = "RW",
              },
              nodeuserindex = {
                id = nodeuserindex,
                access = "RW",
              },
              nodemodeindex = {
                id = nodemodeindex,
                access = "RW",
              }
            }
        }
      end
    end
    indexcount = indexcount + 1;
  end
  strdata = json.encode(data)
  os.execute("/bin/echo \'" .. strdata .. "\' > " .. datajson);
  strview = json.encode(view)
  os.execute("/bin/echo \'" .. strview .. "\' > " .. mobileviewjson);
end

--main
local path;
path = arg[1];
smb_flushjson(path)
