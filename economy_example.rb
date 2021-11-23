#!/usr/bin/env ruby
require './economy'

puts "==================== Example of minimal customisation ===================="
# Minimal settings (with their default values)
Simulator.new do
  @stage = "37-01"

  @hero_level= 350
  @player_level=180 #for fos, 180 is max fos for gold/xp/dust mult
  @nb_ff=6 #ff by day
  @vip=10 #vip level
  @subscription=false

  #the other default settings assume max fos tower, max gh rewards,
  #non paid regal subscriptions, ...

  #see `setup_vars` for the list of all settings
  #Some are determined automatically if not filled, for instance
  #the amount of Wrizz gold is determined from the amount of Wrizz chests:
  #    @gh_wrizz_gold ||= get_guild_gold(@gh_wrizz_chests)
end.summary

=begin
Detailed customizations
  Conventions:
  - @lowercase variables can be changed at setup (except a few of them that
  are internat to the program, see blacklist)
  See `setup` for the main ones, or call `show_variables` for a complete list
  - @Uppercase variables are 'constants' that depends on the game itself
  (so they may need to change after an update)
  - @_underscore variables are internal variables
  Call `show_variables(verbose: true)` to see all these variables.
=end

# Exemple:
puts "==================== Example of detailed customisation ===================="
s=Simulator.new do
  #Enter the afk timer value for xp and gold:
  #(by default we use stage progression to get approximations of these values)
  @afk_xp ||=14508 #the displayed value by minute, this include the vip bonus but not the fos bonus
  @afk_gold ||=900 #the displayed value by minute (include vip)
  @afk_dust ||=1167.6 #the value by day, ie 48.65 by hour
  #This is used to set up real_afk_xp, real_afk_gold, real_afk_dust which are the hourly base values not affected by vip, with gold and xp in K.

  @nb_ff =3 #we only do ff up to 80 dia
  @misty = { red_e: 4*10, t3: 2 } #our misty rewards
  #alternative: see `get_misty` as an helper function to build them
  @misty = get_misty(misty_guild_twisted: :guild, misty_purple_blue: :blue)
  @noble_regal = regal_choice(paid: true) #we pay the regal pass
  @noble_coe = coe_choice(:cores) #we select cores rather than dust in champiion of esperia regals, by default paid is false, ie we use the f2p version
  #see the variable list below for the full settings
  #
  @monthly_stargazing=20 #lets stargaze!
  @monthly_tavern= 0
  @monthly_hcp= 30 #and hcp

  
  # If we are feeling adventurous we can even change internal variables in post_setup_hook
  def post_setup_hook
     # skipping large camps in dismal:
     @_dismal_stage_chest_rewards = { gold_h: 59, xp_h: 29.5, dust_h: 29.5 }
     # assume that vows only give 10 stargaze cards
     @_average_vow_rewards=({stargazers: 10})
     #the program determines fos values from stage progression, but we can change it:
     @_fos_mythic_mult=0.3*2 #we forgot to activate the last mythic fos even though we are at chapter 37
  end

  #There are hooks `custom_income` and `custom_exchange` to customize income and spendings:
  def custom_income
    #let's try to add abex rewards and hf rewards to our income
    abex_rewards={stargazers: 20, dia: 3000} #todo: add other ones
    abex_frequency=1/60.0 #1 every 2 months
    daily_abex_rewards=mult_hash(abex_rewards, abex_frequency)
    hf_rewards={scrolls: 20, dia: 1000} #todo: add other ones
    hf_frequency=1/90.0 #1 every 3 months
    daily_hf_rewards=mult_hash(hf_rewards, hf_frequency)
    {abex: daily_abex_rewards, hf: daily_hf_rewards}
  end
  
  def custom_exchange
    #we sell our daily arena tickets and dura's tears
    #nb: don't do this! One arena ticket sells for 50K gold, but using it gives a lot more value:
    #Arena ticket value: 6.81 [44.55 gold=2.54 dia + 5.95 dust=1.53 dia + 0.12 blue_stones=0.31 dia + 0.03 purple_stones=0.94 dia + 1.49 dia=1.49 dia]
    arena_tickets_to_sell=tally[:arena_tickets]
    dura_tears_to_sell=tally[:dura_tears]
    gold=arena_tickets_to_sell*50+dura_tears_to_sell*10
    sell_stuff={arena_tickets: -arena_tickets_to_sell, 
                dura_tears: -dura_tears_to_sell, 
                gold: +gold}
  
    #we also buy lct tickets every day, 300 dia for 5 tickets
    lct={dia: -300, lct_tickets: 5}
  
    {selling_items: sell_stuff, lct_buy_tickets: lct}
  end
  
  # This is an OO program, so we can customize some existing functions

  # 1) the `friends` income ressource do not handle garrison for now
  #    it is easy to fix it
  def friends
    r=super #call the original function
    @nb_garrison ||= 5 #5 garrison monthly
    r[:friend_summons]+=@nb_garrison*10.0/30 #1 garrison = 10 friends point monthly
    r
  end

  # 2) the `exchange_shop` function currently only handle dust, dust_h, xp_h, purple_stones, poe, shards, cores, silver_e, gold_e
  #  we want to add some functionality:
  #
  #    def exchange_shop
  #      r=super #call the main function
  #      #we want to buy 1 reset scroll every day, it costs 6000K
  #      r[:reset_scrolls]=1
  #      r[:gold] -= 6000
  #      r
  #    end
  #
  # But we can actually use the built in functionality here:
  @Shop={reset_scroll: {reset_scrolls: 1, gold: -6000}}
  @shop_items = %i(dust purple_stones poe shards) +[{reset_scroll: 1}] #we only buy one scroll daily, by default we assume we buy the full number of store refreshes
end

#Now let's look at the summary!
s.summary
#s.show_variables

puts "==================== Default settings ===================="
#Here are the default variables that can be changed in `Simulator.new do ... end` and their values
Simulator.new.show_variables
#Simulator.new.show_variables(verbose: true) for internal variables

=begin
=============== Variables ===============
@stage: 37-01
@hero_level: 350
@player_level: 180
@nb_ff: 6
@vip: 10
@subscription: false
@tower_kt: 550
@tower_4f: 280
@tower_god: 300
@shop_items: [:dust, :purple_stones, :poe, :shards]
@shop_refreshes: 2
@buy_hero: [:garrison]
@buy_guild: [:garrison, :dim_exchange, :t3, :t3, nil, nil, :dim_gear]
@buy_lab: [:garrison, :dim_exchange, nil, :dim_emblems]
@buy_challenger: []
@monthly_stargazing: 0
@monthly_tavern: 0
@monthly_hcp: 0
@friends_mercs: 5
@friends_nb: 20
@gh_team_wrizz_gold: 1080
@gh_team_soren_gold: 1080
@gh_team_wrizz_coin: 1158
@gh_team_soren_coin: 1158
@gh_wrizz_chests: 23
@gh_soren_chests: 23
@gh_wrizz_gold: 2160
@gh_soren_gold: 2160
@gh_soren_freq: 0.66
@tr_twisted: 250
@tr_poe: 1000
@tr_guild: {:dia=>100, :twisted=>6}
@arena_daily_dia: 66
@arena_weekly_dia: 660
@lct_coins: 380
@misty: {:dust_h=>96, :purple_stones=>120, :red_e=>40, :t3=>2, :cores=>300, :hero_choice_chest=>1, :twisted=>400, :blue_stones=>720}
@noble_regal: {:blue_stones=>3300}
@noble_twisted: {:xp_h=>956}
@noble_coe: {:dust=>7500, :dust_h=>380}
@hero_trial_guild_rewards: {:dia=>500, :guild_coins=>1000}
@board_level: 8
@dura_nb_selling: 0
@labyrinth_mode: dismal
@lab_flat_rewards: {:gold=>1758.6359999999997, :xp=>2473.3799999999997}
=end
