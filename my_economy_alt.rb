#!/usr/bin/env ruby
require './economy'

s=Simulator.new do
  @hero_level=[221, 200, 200, 200, 200]
  @monthly_levelup=[10]+[0]*4

  @stage="22-02"
  @afk_xp=2820
  @afk_gold=425

  @player_level=102
  @vip=5
  @max_ff_cost=80
  @subscription=true

  @tr = {twisted: 160} #gold 1
  @tr_guild = {}

  @gh_wrizz_gold = 561*2
  @gh_soren_gold = 559*2
  @gh_wrizz_chests = 16

  @tower_kt = 245
  @tower_4f = 40

  @arena_daily_dia = get_arena(130)
  @lct_coins =282 #gold 1
  @lc_rewards = {gold: 6*941}

  @board_level =6
  @hero_trial_guild_rewards ={ dia: 200+100 }

  @dim_exchange=true
  @shop_items = get_shop_items(shards: false)
  @store_lab_items = get_store_lab_items(:arthur)

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
