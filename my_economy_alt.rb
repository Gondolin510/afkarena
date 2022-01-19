#!/usr/bin/env ruby
require './economy'

s=Simulator.new do
  #@hero_level=[221, 200, 200, 200, 200]
  #@monthly_levelup=[10]+[0]*4
  @hero_level=260

  @stage="28-48"
  #@afk_xp=2820
  #@afk_gold=425

  @player_level=128
  @vip=7
  @max_ff_cost=100
  #@subscription=true

  @tr = {twisted: 200, poe: 613} #gold 2
  @tr_guild = {}

  @gh_wrizz_gold = 714*2
  @gh_soren_gold = 720*2
  @gh_wrizz_chests = 18

  @tower_kt = 325
  @tower_4f = [90,99,102,103]

  @arena_daily_dia = get_arena(90)
  @lct_coins =288 #plat 4
  @lc_rewards = {gold: 6*1050}

  #@board_level =6
  @hero_trial_guild_rewards ={ dia: 200+100 }

  #@dim_exchange=true
  @shop_items = get_shop_items(:timegazers, shards: false)
  #@store_lab_items = get_store_lab_items(:arthur)

  #tweaks (I don't know when poe goes from 100 to 250 in shop, so it is not automatic for now)
  @Shop={ poe: { poe: 100, gold: -500 } }
end

if __FILE__ == $0
  if ARGV.first == "--debug"
    require "pry"
    binding.pry
  else
    s.summary
    s.show_variables(verbose: true)
  end
end
