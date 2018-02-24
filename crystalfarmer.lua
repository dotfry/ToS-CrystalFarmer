--
-- Addon for deleting trash items while afk farm.
-- debug: dofile("../addons/crystalfarmer/crystalfarmer.lua");

crystalFarmer = {
  -- items to remove
  trash = {},
  verbose = false,
  weight = 75
};
  
function crystalFarmer.handleNewItem(invIndex)
  local invItem = session.GetInvItem(invIndex);
  if invItem == nil then
    return;
  end;
  
  local ies = GetIES(invItem:GetObject());
  if ies == null then
    return;
  end;
  crystalFarmer.lastItem = item; -- for debug
  
  local clazz = ies.ClassName or "NIL_OBJECT";
  if (crystalFarmer.isTrash(clazz)) then
    if not crystalFarmer.needCleanup() then
      crystalFarmer.verbose("can delete item " .. clazz .. ", but not required");
      return;
    end
    crystalFarmer.verbose("deleted item " .. clazz .. ".");
    crystalFarmer.deleteItem(invItem);
  end;
end;
  
function crystalFarmer.isTrash(clazz)
  return crystalFarmer.trash[clazz] or false;
end;
  
function crystalFarmer.needCleanup()
  local pc = GetMyPCObject();
  if (pc == null) then
    return true;
  end;

  if pc.MaxWeight ~= 0 then
    return pc.NowWeight / pc.MaxWeight * 100 > crystalFarmer.weight;
  end

  return true;
end;

-- @param item InventoryItem
function crystalFarmer.deleteItem(item)
  item.DropDelete(item:GetIESID());
end;
  
function crystalFarmer.verbose(text)
  if crystalFarmer.verbose == true then
    CHAT_SYSTEM("[CrystalFarmer] " .. text);
  end;
end;
  
function crystalFarmer.setConfig(cfg)
  local classes = cfg["classes"] or {};
  for _, v in pairs(classes) do
    crystalFarmer.trash[v] = true;
  end;
  
  crystalFarmer.verbose = cfg['verbose'] or false;
  crystalFarmer.weight = cfg['weight'] or 75;
end;

function crystalFarmer.loadConfig()
  local acutil, file = require('acutil'), "../addons/crystalfarmer/settings.json";
  local t, err = acutil.loadJSON(file);
  if (err) then
    CHAT_SYSTEM(string.format("[CrystalFarmer] can't load config (%s).", file));
  else
    crystalFarmer.setConfig(t);
  end;
end

-- Game call this method every time after switching channel, loggin in.
function CRYSTALFARMER_ON_INIT(addon, frame)
  crystalFarmer.loadConfig();
  addon:RegisterMsg('INV_ITEM_ADD', 'CRYSTALFARMER_ON_MESSAGE');
end;

-- Handling incoming message
function CRYSTALFARMER_ON_MESSAGE(frame, msg, arg1, arg2)
  if msg == 'INV_ITEM_ADD' then
    crystalFarmer.handleNewItem(arg2);
  end;
end;
