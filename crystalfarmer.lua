--
-- Addon for deleting trash items while afk farm.
local acutil = require('acutil');

crystalFarmer = {
  -- items to remove
  trash = {},
  verbose = false,
  __maxDebug = false,
  config = "../addons/crystalfarmer/settings.json",
  weight = 75
};

-- fast table dumper.
function crystalFarmer.dump(tbl)
  for k, v in pairs(tbl) do
    print(k);
  end
end

function crystalFarmer.handleNewItem(invIndex)
  local invItem = session.GetInvItem(invIndex);
  if invItem == nil then
    return;
  end;
  
  local ies = GetIES(invItem:GetObject());
  if ies == null then
    return;
  end;
  crystalFarmer.lastItem = invItem; -- for debug
  -- few debug: print(GetIES(crystalFarmer.lastItem:GetObject()).ClassName)
  
  local clazz = ies.ClassName or "UNKNOWN, SKIP";
  if (crystalFarmer.isTrash(clazz)) then
    if not crystalFarmer.needCleanup() then
      crystalFarmer.print(string.format("can delete item %s, but not required", clazz));
      return;
    end
    crystalFarmer.print(string.format("deleted item %s.", clazz));
    crystalFarmer.deleteItem(invItem);
  end;
end;
  
function crystalFarmer.isTrash(clazz)
  return crystalFarmer.trash[clazz] or false;
end;
  
function crystalFarmer.needCleanup()
  local pc = GetMyPCObject();
  if pc == null then
    return true;
  end;

  if pc.MaxWeight ~= 0 then
    return pc.NowWeight / pc.MaxWeight * 100 > crystalFarmer.weight;
  end

  return true;
end;

-- @param item InventoryItem
function crystalFarmer.deleteItem(obj)
  item.DropDelete(obj:GetIESID());
end;
  
function crystalFarmer.print(text, force)
  if crystalFarmer.verbose or force then
    CHAT_SYSTEM(string.format('[CrystalFarmer] %s', text or ''));
  end;
end;

function crystalFarmer.debug(text)
  if crystalFarmer.__maxDebug then
    crystalFarmer.print(text, true);
  end
end;
  
function crystalFarmer.setConfig(cfg)
  local classes = cfg['classes'] or {};
  for _, v in pairs(classes) do
    crystalFarmer.trash[v] = true;
  end;
  
  crystalFarmer.verbose = cfg['verbose'] or false;
  crystalFarmer.weight = cfg['weight'] or 75;
end;

function crystalFarmer.loadConfig()
  local t, err = acutil.loadJSON(crystalFarmer.config);
  if (err) then
    crystalFarmer.print(string.format("[CrystalFarmer] can't load config (%s).", crystalFarmer.config), true);
  else
    crystalFarmer.debug('loading config');
    crystalFarmer.setConfig(t);
  end;
end;

function crystalFarmer.saveConfig()
  local conf = { verbose = crystalFarmer.verbose, weight = crystalFarmer.weight, classes = {} };
  for clazz, enabled in pairs(crystalFarmer.trash) do
    if enabled then
      table.insert(conf.classes, clazz);
    end
  end
  acutil.saveJSON(crystalFarmer.config, conf);
end;

local function handleSlashCommand(args)
  local command = string.lower(table.remove(args, 1) or '');

  if command == 'weight' then
    crystalFarmer.weight = math.floor(tonumber(number) or crystalFarmer.weight);
    crystalFarmer.saveConfig();
    return;
  end;

  if command ~= 'add' and command ~= 'del' then
    ui.MsgBox('Usage:{nl}add CLASSNAME{nl}del CLASSNAME{nl}weight [percent]', '', 'Nope');
    return;
  end;

  crystalFarmer.trash[string.upper(table.remove(args, 1) or '')] = command == 'add';
  crystalFarmer.saveConfig();
end;

--------------------------
-- ADDON INITIALIZATION --
--------------------------
-- Game call this method every time after switching channel, loggin in.
function CRYSTALFARMER_ON_INIT(addon, frame)
  addon:RegisterMsg('INV_ITEM_ADD', 'CRYSTALFARMER_ON_MESSAGE');
  crystalFarmer.loadConfig();
  crystalFarmer.print("loaded!", true);
  
  acutil.slashCommand('/cf', handleSlashCommand);
end;

-- Handling incoming message
function CRYSTALFARMER_ON_MESSAGE(frame, msg, arg1, arg2)
  crystalFarmer.debug(string.format('messageLoop (%s)', msg or 'NIL'));
  if msg == 'INV_ITEM_ADD' then
    crystalFarmer.handleNewItem(arg2);
  end;
end;
