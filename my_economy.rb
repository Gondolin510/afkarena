#!/usr/bin/env ruby
require './economy'

s=Simulator.new do
  @hero_level=359
  @stage="37-16"
  @afk_xp=13235
  @afk_gold=844

  @player_level=165
  @vip=9
  @subscription=true

  #dia 5 at floor 360
  @tr_twisted ||=257
  @tr_poe ||=905

  @gh_team_wrizz_gold = 948
  @gh_team_soren_gold = 978
  @gh_team_wrizz_coin = 1058

  @gh_wrizz_chests = 21
  @gh_wrizz_gold = 1897
  @gh_soren_gold = 1957

  @noble_coe = get_coe(:cores)
  @dura_nb_selling =1

  @tower_god = 200

  @misty = get_misty(guild_twisted: :guild)
end
s.summary
# p s.real_afk_gold, s.real_afk_xp
# require 'pry'; binding.pry
s.show_variables(verbose: true)
