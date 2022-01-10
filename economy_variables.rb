#!/usr/bin/env ruby
require './economy'

puts "==================== Default settings ===================="
# Here are the default variables that can be changed in `Simulator.new do ... end` and their values
s=Simulator.new do
  @stage = "38-01"
  @hero_level = 450
  @player_level =180
  @vip =10
  @max_ff_cost =200

  @tower_kt = 550
  @tower_4f = 280
  @tower_god = 300

  @monthly_stargazing = 0
  @monthly_tavern = 0
  @monthly_hcp_heroes =0
  @monthly_hcp = get_hcp_from_nb_heroes(@monthly_hcp_heroes)

  @friends_nb = 20
  @friends_mercs = 5

  @gh_wrizz_chests = 23
  @gh_soren_chests = @gh_wrizz_chests
  @gh_wrizz_gold = get_guild_gold(@gh_wrizz_chests)
  @gh_soren_gold = get_guild_gold(@gh_soren_chests)
  @gh_soren_freq = 0.66

  @tr = {twisted: 380, poe: 1290}
  @tr_guild = {dia: 100, twisted: 420/70}
  @cursed_realm = {}

  @arena_daily_dia = get_arena(5)
  @arena_weekly_dia =@arena_daily_dia * 10
  @lct_coins =380
  @lc_rewards = {gold: 6*1278}

  @misty = get_misty
  @board_level =8
  @dura_nb_selling =0

  @noble_regal = get_regal
  @noble_twisted = get_twisted_bounties
  @noble_coe = get_coe

  @hero_trial_guild_rewards ={
    dia: 200+100+200,
    guild_coins: 1000
  }

  @labyrinth_mode = :auto

  @subscription =false
  @merchant_daily ={}
  @merchant_weekly ={}
  @merchant_monthly ={}
  @monthly_card ={}
  @deluxe_monthly_card ={}

  @shop_refreshes = 2
  @shop_items = get_shop_items
  @garrison = false
  @dim_exchange = false
  @store_hero_items = get_store_hero_items
  @store_guild_items = get_store_guild_items
  @store_lab_items = get_store_lab_items
  @store_challenger_items = get_store_challenger_items

  @monthly_levelup=0
  set_tower_progression_from_levelup

  #@afk_xp=13265     # the displayed value by minute, this include the vip bonus but not the fos bonus
  #@afk_gold=844     # the displayed value by minute (include vip)
  #@afk_dust=1167.6  # the value by day, ie 48.65 by hour
  #-> determined from stage progression, but can be set up directly for more precise results
end
s.show_variables

puts "==================== Automatic generation of default settings ===================="

# The list above can be out of date with the program, here is an automatic generation:
Simulator.new.show_variables
#Simulator.new.show_variables(verbose: true) for internal variables

=begin
=============== Variables ===============
@stage: 38-01
@hero_level: 450
@player_level: 180
@nb_ff: 6
@vip: 10
@subscription: false
@tower_kt: 550
@tower_4f: 280
@tower_god: 300
@monthly_stargazing: 0
@monthly_tavern: 0
@monthly_hcp_heroes: 0
@monthly_hcp: 0.0
@friends_nb: 20
@friends_mercs: 5
@gh_wrizz_chests: 23
@gh_soren_chests: 23
@gh_wrizz_gold: 2160
@gh_soren_gold: 2160
@gh_soren_freq: 0.66
@tr: {:twisted=>380, :poe=>1290}
@tr_guild: {:dia=>100, :twisted=>6}
@cursed_realm: {}
@arena_daily_dia: 66
@arena_weekly_dia: 660
@lct_coins: 380
@lc_rewards: {:gold=>7668}
@misty: {:dust_h=>96, :twisted=>400, :blue_stones=>360, :purple_stones=>120, :red_e=>40, :t3=>2, :hero_choice_chest=>1, :cores=>300}
@board_level: 8
@dura_nb_selling: 0
@noble_regal: {:blue_stones=>3300}
@noble_twisted: {:xp_h=>956}
@noble_coe: {:dust=>7500, :dust_h=>380}
@hero_trial_guild_rewards: {:dia=>500, :guild_coins=>1000}
@labyrinth_mode: auto
@merchant_daily: {}
@merchant_weekly: {}
@merchant_monthly: {}
@monthly_card: {}
@deluxe_monthly_card: {}
@shop_refreshes: 2
@shop_items: [:dust, :purple_stones, :poe, :shards]
@garrison: false
@dim_exchange: false
@store_hero_items: [nil]
@store_guild_items: [{:t3=>:max}, nil, nil, :dim_gear]
@store_lab_items: [nil, :dim_emblems]
@store_challenger_items: [nil]
@monthly_levelup: 0
@tower_kt_progression: 0.0
@tower_4f_progression: 0.0
@tower_god_progression: 0.0
=end
