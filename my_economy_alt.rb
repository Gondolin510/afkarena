#!/usr/bin/env ruby
require './economy'

s=Simulator.new do
  @hero_level=[220, 200, 200, 200, 200]
  @stage="22-02"
  @afk_xp=2820
  @afk_gold=425

  @player_level=102
  @vip=5
  @subscription=true

  @tr_twisted = 160 #gold 1
  @tr_poe = 0
  @tr_guild = {}

  @gh_team_wrizz_gold = 561
  @gh_team_soren_gold = 559
  @gh_team_wrizz_coin = 806
  @gh_wrizz_chests = 16

  @tower_kt = 245
  @tower_4f = 40

  @arena_daily_dia = get_arena(130)
  @lct_coins =282 #gold 1
  @lc_rewards = {gold: 6*941}

  @board_level =6
  @hero_trial_guild_rewards ={ dia: 200+100 }

  @garrison=false
  @shop_items = %i(dust purple_stones poe) #( shards gold_e)
  @store_lab_items = %i(dim_exchange arthur)

  #tweaks
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
