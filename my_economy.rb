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
      @dim_exchange=false

      #@misty = get_misty(chest2: :guild_coins) #take guild coins

      #@monthly_levelup=12
      #set_tower_progression_from_levelup(10)

      instance_eval(&b) if b
    end
  end
end

s=MySimulator.new

=begin
A-tier vs fodder ratio: we need 8 a-tier E and 20 fodder E to ascend an hero, ie a ratio of 8/20=0.4
- In tavern, the ratio is 0.0461/(0.4370/9.0)=0.95.
- Via passive blue/stones acquisition, I get daily 213.48 blue stones and 18.60 purple stones s.blue_stone(213.48). The ratio is:
  s.blue_stone(213.48) => {:random_fodder=>0.3953333333333333}
  s.purple_stone(18.69) => {:random_fodder=>0.08722, :random_atier=>0.21182, :random_god=>0.01246}
  0.21182/(0.3953333333333333+0.08722) => 0.4389566610944559
- Stargazers: 0.03183671803245229/0.00994897438514134=3.2
=end

def level_ups_summary(without_dust=:auto, with_dust=:auto)
  s=MySimulator.new
  s.level_summary "Without dust"
  without_dust = s.possible_levelups if without_dust == :auto

  s=MySimulator.new do
    @monthly_levelup = without_dust
  end
  s.level_summary "Without dust and #{without_dust} monthly level ups for tower"

  s=MySimulator.new do
    @shop_items = get_shop_items(:dust_h)
  end
  s.level_summary "With dust"
  with_dust = s.possible_levelups if with_dust == :auto

  s=MySimulator.new do
    @shop_items = get_shop_items(:dust_h)
    @monthly_levelup = with_dust
  end
  s.level_summary "With dust and #{with_dust} monthly level ups for tower"
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
