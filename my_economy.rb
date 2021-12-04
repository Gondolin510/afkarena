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

  @garrison=true
  @dim_exchange=true

  #@misty = get_misty(chest2: :guild_coins) #take guild coins

  @shop_items = get_shop_items(:dust_h)
  @monthly_levelup=12
  #set_tower_progression_from_levelup(10)

=begin
With set_tower_progression_from_levelup(10) and @monthly_levelup=0
  - Not buying dust:
  level: 2.9 days (10.35 by month) {gold: 2.11 days, xp: 1.81 days, dust: 2.9 days} [monthly remains: 88005.18 gold + 1030671.08 xp]
  - Buying dust:
  level: 2.19 days (13.7 by month) {gold: 2.11 days, xp: 1.81 days, dust: 2.19 days} [monthly remains: 11821.59 gold + 479300.28 xp]
With @monthly_levelup=10
  - Not buying dust:
  level: Infinity days (0 by month) {gold: 9.42 days, xp: 5.47 days, dust: -43.48 days} [monthly remains: 72329.45 gold + 901825.95 xp + -21622.92 dust]
  - Buying dust:
  level: 11.27 days (2.66 by month) {gold: 9.42 days, xp: 5.47 days, dust: 11.27 days} [monthly remains: 11822 gold + 463909.59 xp]
=end
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
