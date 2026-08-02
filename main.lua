-- This mod turns off wild encounters before you can buy repels to emulate
-- what the any% speedrun does. It also guarantees you will catch a Paras
-- in Mt. Moon and then a Doduo on Route 16. Lapras in Silph is the last
-- required HM user but it is free.
--
-- After you catch the HM user the encounter rate will go down to 0 in
-- Mt. Moon. No pesky manips required.
--
-- This mod also makes the pokeball a guaranteed catch, 100% catch rate.
-- This is intended with the sole purpose of solo run play and can be
-- turned off. Waste 9 balls on a Paras if you want. It's your life.
--
-- Note: Since the badge boost glitch doesn't work natively, the manips
-- 99% don't work so this is the best you can get in that regard.

local GUARANTEE_BY_MAP = {
  MT_MOON_1F = { species = "PARAS", level = 8 },
  ROUTE_16   = { species = "DODUO", level = 18 },
}

local ZERO_MAPS = {
  ROUTE_1 = true, ROUTE_22 = true, VIRIDIAN_FOREST = true, ROUTE_3 = true,
  MT_MOON_B1F = true, MT_MOON_B2F = true, ROUTE_6 = true,
}

local MASTER_BALL_DEF = {
  randMax = 0, autoCatch = true, tossAnim = "ULTRATOSS_ANIM", flicker = true,
}

local function ownedKey(species) return "owned_" .. species end

return function(mod)
  mod.options:define({
    { key = "hm_chance", label = "100% HM CHANCE", type = "toggle", default = true },
    { key = "no_early_encounters", label = "NO EARLY ENCOUNTERS", type = "toggle", default = true },
    { key = "pokeball_100", label = "100% POKEBALL", type = "toggle", default = true },
  })

  mod.events:on("pokemon.caught", function(ev)
    for _, g in pairs(GUARANTEE_BY_MAP) do
      if ev.species == g.species then
        mod.save:set(ownedKey(g.species), true)
      end
    end
  end)

  mod.hooks:wrap("encounter.roll", function(next, encDef, ctx)
    if ctx.terrain == "grass" or ctx.terrain == "indoor" then
      local g = GUARANTEE_BY_MAP[ctx.mapId]
      if g and mod.options:get("hm_chance") then
        if mod.save:get(ownedKey(g.species), false) then return nil end
        local rolled = next(encDef, ctx)
        if rolled then return { species = g.species, level = g.level } end
        return nil
      end
      if ZERO_MAPS[ctx.mapId] and mod.options:get("no_early_encounters") then
        return nil
      end
    end
    return next(encDef, ctx)
  end)

  local Catching = require("src.battle.Catching")
  local origAttempt = Catching.attempt
  Catching.attempt = function(ball, targetMon, targetDef, rng, rateOverride, opts)
    if ball == "POKE_BALL" and mod.options:get("pokeball_100") then
      opts = opts or {}
      opts.ballDef = MASTER_BALL_DEF
    end
    return origAttempt(ball, targetMon, targetDef, rng, rateOverride, opts)
  end
end
