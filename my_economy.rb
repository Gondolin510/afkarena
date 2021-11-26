#!/usr/bin/env ruby
require './economy'

s=Simulator.new do
  @hero_level=362
  @stage="37-16"
  @afk_xp=13932
  @afk_gold=888

  @player_level=170
  @vip=10
  @subscription=true

  #dia 5 at floor 360
  @tr= {twisted: 257, poe: 905}

  @gh_team_wrizz_gold = 948
  @gh_team_soren_gold = 978
  @gh_team_wrizz_coin = 1058

  @gh_wrizz_chests = 21
  @gh_wrizz_gold = 1897
  @gh_soren_gold = 1957

  @noble_coe = get_coe(:cores)
  @dura_nb_selling =1

  @tower_kt = 561
  @tower_4f = [296, 291, 361, 393] #lb, maulers, wilders, gb
  @tower_god = [143, 231] #celo, hypo
  @monthly_levelup=10
  #set_tower_progression(10)

  @garrison=true
  @dim_exchange=true

  @misty = get_misty(guild_twisted: :guild)

  @shop_items = get_shop_items(:dust_h)
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
