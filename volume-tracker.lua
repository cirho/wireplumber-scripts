#!/usr/bin/wpexec
-- Live update of sinks' volume level, muteness in i3bar friendly format.

node_om = ObjectManager({
  Interest({ type = "node", Constraint({ "media.class", "=", "Audio/Sink", type = "pw-global" }) }),
})

metadata_om = ObjectManager({
  Interest({ type = "metadata", Constraint({ "metadata.name", "=", "default" }) }),
})

local default_sink = nil
local sink2volume = {}
local name2icon = {}
name2icon["alsa_output.pci-0000_00_1f.3.analog-stereo"] = ""
name2icon["alsa_output.usb-Sony_Interactive_Entertainment_Wireless_Controller-00.analog-stereo"] = ""

local span = function(content, color, underline)
  local s = "<span "
  if color then
    s = s .. 'foreground="#Cd3f45" '
  end
  if underline then
    s = s .. 'underline="single" '
  end
  return s .. ">" .. content .. "</span>"
end

local update_prompt = function()
  local prompt = ""
  for sink, vol in pairs(sink2volume) do
    local icon = name2icon[sink]
    prompt = prompt .. icon .. " " .. span(vol.mute and "Mute" or vol.level, vol.mute, sink == default_sink) .. " "
  end
  print(prompt)
end

local node_volume = function(node)
  for p in node:iterate_params("Props") do
    local output = p:parse().properties
    if output["channelVolumes"] == nil then
      return { level = "?", mute = false }
    end
    local vol = output.channelVolumes[1] ^ (1 / 3)
    return {
      level = math.floor(100 * vol + 0.5),
      mute = output.mute,
    }
  end

  error("something went wrong :(")
end

metadata_om:connect("object-added", function(_, metadata)
  local process = function(key, value)
    if key ~= "default.audio.sink" then
      return
    end
    default_sink = value:match('"name": "(.*)"')
    update_prompt()
  end

  for _, k, _, v in metadata:iterate(Id.ANY) do
    process(k, v)
  end
  metadata:connect("changed", function(_, _, k, _, v)
    process(k, v)
  end)
end)

node_om:connect("object-added", function(_, node)
  local name = node.properties["node.name"]
  sink2volume[name] = node_volume(node)
  update_prompt()

  node:connect("params-changed", function(_, params)
    if params == "Props" then
      sink2volume[name] = node_volume(node)
      update_prompt()
    end
  end)
end)

node_om:connect("object-removed", function(_, node)
  local name = node.properties["node.name"]
  sink2volume[name] = nil
  update_prompt()
end)

metadata_om:activate()
node_om:activate()
