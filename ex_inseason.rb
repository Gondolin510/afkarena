#!/usr/bin/env ruby
require './economy'

Simulator.new do
  @stage = "40-28"
  @hero_level = 596
  @player_level=300
  @vip =16
  @nb_ff =7 #up to 300 dia
  @subscription =true

  @tower_kt = 900
  @tower_4f = [700, 700, 700, 700]
  @tower_god = [450, 500]
  set_tower_progression_from_levelup(10) #simulate a progression of 10 levels a month, so 20 levels in towers since we are at multis

  @monthly_stargazing = 20
  @monthly_hcp_heroes = 4

  @cursed_realm = get_cursed_realm(10) #in cursed and in top 10%

  @arena_daily_dia = get_arena(2) #rank 1 in arena
  @lct_coins =309 #top 1

  @dura_nb_selling=7 #we have maxed out all artifacts

  @noble_regal = get_regal(paid: true)
  @noble_twisted = get_twisted_bounties(paid: true) #default to xp
  @noble_coe = get_coe(paid: true) #default to dust

  @monthly_card=get_monthly_card #default to dust
  @deluxe_monthly_card=get_deluxe_monthly_card #default to red_e+core

  @store_hero_items = get_store_hero_items({twisted: :max})
  @store_lab_items = get_store_lab_items({twisted: :max}, dim_emblems: true)
end.summary
