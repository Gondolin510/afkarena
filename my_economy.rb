#!/usr/bin/env ruby
require './economy'

class MySimulator < Simulator
  def initialize(*args, **kw, &b)
    super do
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

      #@monthly_levelup=12
      #set_tower_progression_from_levelup(10)

      instance_eval(&b) if b
    end
  end
end

s=MySimulator.new

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

A-tier vs fodder ratio: we need 8 a-tier E and 20 fodder E to ascend an hero, ie a ratio of 8/20=04.
- In tavern, the ratio is 0.0461/(0.4370/9.0)=0.95.
- Via passive blue/stones acquisition, I get daily 213.48 blue stones and 18.60 purple stones s.blue_stone(213.48). The ratio is:
  s.blue_stone(213.48) => {:random_fodder=>0.3953333333333333}
  s.purple_stone(18.69) => {:random_fodder=>0.08722, :random_atier=>0.21182, :random_god=>0.01246}
  0.21182/0.3953333333333333+0.08722 => 0.4389566610944559
- Stargazers: 0.03183671803245229/0.00994897438514134=3.2
=end

def level_ups_summary(without_dust=10, with_dust=12)
  s=MySimulator.new
  s.level_summary "Without dust"

  s=MySimulator.new do
    @monthly_levelup = without_dust
  end
  s.level_summary "Without dust and #{without_dust} monthly level ups"

  s=MySimulator.new do
    @shop_items = get_shop_items(:dust_h)
  end
  s.level_summary "With dust"

  s=MySimulator.new do
    @shop_items = get_shop_items(:dust_h)
    @monthly_levelup = with_dust
  end
  s.level_summary "With dust and #{with_dust} monthly level ups"
end

s=MySimulator.new
if __FILE__ == $0
  if ARGV.first == "--debug"
    require "pry"
    binding.pry
  else
    s.h0 "Monthly level ups"
    level_ups_summary

    s.h0 "Income"
    s.summary(daily: true)
    s.show_variables(verbose: true)
  end
end
