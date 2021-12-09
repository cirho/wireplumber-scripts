#!/usr/bin/wpexec
-- Read these fiftyish lines to find out what this script does :)
-- Warning args order isn't deterministic!

local keys = function(t)
  local xs = {}
  for k, _ in pairs(t) do
    xs[#xs + 1] = k
  end
  return xs
end

local args = keys(...)
local volume_delta = 0.05
local cmds = {}

cmds.help = function()
  print("available commads")
  for k, _ in pairs(cmds) do
    print(k)
  end
end

cmds.up = function(mixer, id)
  local volume = mixer:call("get-volume", id)["channelVolumes"][1]["volume"]
  mixer:call("set-volume", id, math.min(volume + volume_delta, 1.0))
end

cmds.down = function(mixer, id)
  local volume = mixer:call("get-volume", id)["channelVolumes"][1]["volume"]
  mixer:call("set-volume", id, math.max(volume - volume_delta, 0.0))
end

cmds.toggle_mute = function(mixer, id)
  local route = mixer:call("get-volume", id)
  mixer:call("set-volume", id, { mute = not route.mute })
end

cmds.mute = function(mixer, id)
  mixer:call("set-volume", id, { mute = true })
end

cmds.unmute = function(mixer, id)
  mixer:call("set-volume", id, { mute = false })
end

Core.require_api("default-nodes", "mixer", function(default_nodes, mixer)
  mixer.scale = "cubic"
  local id = default_nodes:call("get-default-node", "Audio/Sink")

  local fn = cmds[args[1] or "help"] or cmds.help
  fn(mixer, id)

  Core.quit()
end)

-- vim: ft=lua
