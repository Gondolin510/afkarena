#!/usr/bin/env ruby
require './economy'

puts "==================== Detailed ressources for a chapter 37 f2p player ===================="
# Minimal settings
s=Simulator.new do
  @stage = "37-01"
  @hero_level=350

  # some non maxed values:
  @gh_wrizz_chests=22
  @tower_god = 200
  @tr= {twisted: 257, poe: 905}
  @temporal_rift_level = 150
  @arena_daily_dia = get_arena(5) #rank 5 in arena
  @lct_coins=380 #top 20.
end
s.summary(:all, options: {total: :all, conservative_ff: true})

puts "==================== Example of minimal customisation ===================="
# Minimal settings
s=Simulator.new do
  @stage = "37-01" #(default to 38-01)
  @hero_level= 350 #(default to 450)
  @player_level=180 #for fos (default), 180 is max fos for gold/xp/dust mult
  @max_ff_cost=200 #up to 6 ff by day if possible from vip (default)
  @vip=10 #vip level (default)
  @subscription=false # (default)

  # the other default settings assume max fos tower, max gh rewards, non paid regal subscriptions, ...
  # see `setup_vars` for the list of all settings
  # Some are determined automatically if not filled, for instance
  # the amount of Wrizz gold is determined from the amount of Wrizz chests:
  #    @gh_wrizz_gold ||= get_guild_gold(@gh_wrizz_chests)
end

puts "-> cost of one level up:"
puts s.level_cost_summary
puts "-> cost of ten level up:"
puts s.level_cost_summary(10)
puts "\n-> Full summary:"
s.summary

puts "==================== Example of moderate customisation ===================="
Simulator.new do
  @stage = "37-01" #(default to 38-01)
  @hero_level= 350 #(default to 500)
  @player_level=180 #for fos (default), 180 is max fos for gold/xp/dust mult
  @max_ff_cost=100
  @vip=10 #vip level (default)
  @subscription=false # (default)

  @tower_kt = 550
  @tower_4f = [280, 285, 320, 290]
  @tower_god = [200, 300]

  @monthly_stargazing= 0
  @monthly_tavern = 0
  @monthly_hcp_heroes=1 #number of hcp heroes we want to summon monthly

  @friends_mercs ||= 3 #3 weekly mercs

  @gh_wrizz_chests = 22
  @gh_soren_chests = 21
  @gh_soren_freq = 0.7 #active guild

  @tr={twisted: 300, poe: 900}
  @tr_guild = {dia: 10} #a guildie is in legend
  @cursed_realm = get_cursed_realm(30) #in cursed and in top 30%

  @arena_daily_dia = get_arena(3) #rank 3 in arena
  @lct_coins =395 #top 5. Hourly coins: 400-rank
  @lc_rewards = {gold: -6*1278} #we lose all wagers!

  @misty = get_misty(%i(t3 shards red_e poe)) #privilege t3>shards>red_e>poe
  @dura_nb_selling =2 #dura's fragments we have maxed out and are selling

  @noble_regal = get_regal(paid: true)
  @noble_twisted = get_twisted_bounties(:shards, paid: true)
  @noble_coe = get_twisted_bounties(:cores)

  @hero_trial_guild_rewards ={
    dia: 200+100+200,
    guild_coins: 2000 #assume top 200
  }

  @monthly_card=get_monthly_card(:shard) #select shards
  @deluxe_monthly_card=get_deluxe_monthly_card(red: :silver_e, purple: :twisted) #select silver emblems and twisted essence

  @shop_refreshes = 1 #only one shop refresh
  @shop_items = get_shop_items({dust_h: 1}, shards: false) #buy dust chest only once, don't buy shards

  @garrison=true #(default to false) let's garrison
  @dim_exchange=true #(default to false) and do a dim exchange

  #use our lab coins to buy all twisted essence, we don't buy dim emblems,
  #and any remaining coin is spent on red_e
  @store_lab_items = get_store_lab_items({twisted: :max}, dim_emblems: false, secondary: [{red_e: :max}])
end.summary

puts "==================== Example of a beginner ===================="
Simulator.new do
  @stage = "08-01"
  @hero_level= [160, 140, 120, 120, 120] #our 5 heroes
  @player_level=90
  @nb_ff=1
  @vip=5

  @tower_kt = 150

  @friends_mercs = 1 #we only lend one weekly merc

  @gh_wrizz_chests = 13
  @gh_soren_freq = 0.5 #moderately active guild

  @tr={twisted: 150}
  @tr_guild = {} #no guildie in fabled or legend

  @arena_daily_dia = get_arena(200) #rank 200 in arena
  @lct_coins =250
  @lc_rewards = {gold: 6*1000} #betting

  @shop_items = get_shop_items(poe: false) #don't buy poe
  @shop_refreshes = 0 #don't refresh shop

  @board_level =5
  @hero_trial_guild_rewards = { dia: 200+100 } #can't pass the last quest

  # see ressources used for leveling up our roster by 5 levels
  # this also give us an estimated tower progression
  @monthly_levelup=5
  # we could be more flexible by specifying we only want to level up our
  # last two heroes
  # @monthly_levelup=[0, 0, 0, 10, 20]

  #we don't want to buy anything in the guild store
  #@store_guild_items = []
end.summary

puts "==================== Example of a whale ===================="
Simulator.new do
  @stage = "40-01"
  @hero_level = 500
  @player_level=300
  @vip =16
  @max_ff_cost =300 #up to 300 dia
  @subscription =true

  @tower_kt = 900 #multi at 600
  @tower_4f = [600, 550, 480, 750] #multi at 450
  @tower_god = [349, 370] #multi at 350
  set_tower_progression_from_levelup(10) #progression of 10 levels a month, so 20 levels in kt/4f since we are at multi, 10/20 at god since we are at singles/multi respectively

  @monthly_stargazing = 20
  @monthly_hcp_heroes = 4

  @cursed_realm = get_cursed_realm(5) #in cursed and in top 5%

  @arena_daily_dia = get_arena(1) #rank 1 in arena
  @lct_coins =400 #top 1

  @dura_nb_selling=7 #we have maxed out all artifacts

  @noble_regal = get_regal(paid: true)
  @noble_twisted = get_twisted_bounties(paid: true) #default to xp
  @noble_coe = get_coe(paid: true) #default to dust

  @monthly_card=get_monthly_card #default to dust
  @deluxe_monthly_card=get_deluxe_monthly_card #default to red_e+core

  # Buy more stuff!
  @shop_refreshes=4
  @shop_items = get_shop_items(:dust_h, {gold_e: 2}, poe: false)
  #buy up to 2 gold emblems (if possible with our amount of shop refresh), but no poe
  @store_hero_items = get_store_hero_items({twisted: :max})
  @store_lab_items = get_store_lab_items({twisted: :max}, dim_emblems: false, secondary: [{red_e: :max}])
  @store_challenger_items = get_store_challenger_items({red_e: :max}) #buy all possible red_e (if we have enough coins)
end.summary

puts "==================== Example of a new player with everything locked ===================="
Simulator.new do
  @stage = "01-01"
  @vip=0
  @hero_level= [1,1,1,1,1]
  @player_level=1
  @max_ff_cost=80 #we will have less ff than this value
end.summary

puts "==================== Example of detailed customisation ===================="

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
  See the variable list below for the full settings
=end

s=Simulator.new do
  # User variables
  # ##############

  @stage="37-01"

  #Enter the afk timer value for xp and gold:
  #(by default we use stage progression to get approximations of these values)
  @afk_xp =14508 #the displayed value by minute, this include the vip bonus but not the fos bonus
  @afk_gold =900 #the displayed value by minute (include vip)
  @afk_dust =1167.6 #the value by day, ie 48.65 by hour
  #This is used to set up real_afk_xp, real_afk_gold, real_afk_dust which are the hourly base values not affected by vip, with gold and xp in K.

  @nb_ff =3 #we only do ff up to 80 dia
  @misty = { red_e: 4*10, t3: 2 } #our misty rewards
  #alternative: see `get_misty` as an helper function to build them
  @misty = get_misty(chest2: :guild_coins) #take guild coins

  @noble_regal = get_regal(paid: true) #we pay the regal pass
  @noble_coe = get_coe(:cores) #we select cores rather than dust in champion of esperia regals, by default paid is false, ie we use the f2p version
  
  @monthly_stargazing=20 #lets stargaze!
  @monthly_tavern= 0
  @monthly_hcp_heroes= 1 #we want to do enough hcp summons to get one hero

  # Skip large camps in dismal
  # @_dismal_stage_chest_rewards = { gold_h: 59, xp_h: 29.5, dust_h: 29.5 }
  # Better:
  @labyrinth_mode = :dismal_skip_large

  # Game variables
  # ##############

  # The game variables are supposed to be constant and automatically
  # determined from progression. But in case of a game update we may want
  # to change things.

  # As an example, the shop use 250 poe for 1125 gold when poe unlock.
  # But when they first unlock it is actually 100 poe for 500 gold.
  # But I don't know when it changes, so in the program I use the 250 poe
  # quantity.
  # Let's tweak this here:
  @Shop={ poe: { poe: 100, gold: -500 } }

  # For misty we assume we get all stages silver+gold unlock
  # To change this:
  @Misty_base={ poe: 19*450} #only got 19 gold chests!
  
  # If we are feeling adventurous we can even change internal variables:

  # assume that vows only give 10 stargaze cards
  @_average_vow_rewards=({stargazers: 10})

  # Usually the internal variables are determined automatically, but we use the user supplied internal variables in priority.
  # For the exceptions (the @_fos_* variables), we can still change them in post_setup_hook:
  def post_setup_hook
     #the program determines fos values from stage progression, but we can change it:
     @_fos_mythic_mult=0.3*2 #we forgot to activate the last mythic fos even though we are at chapter 37
  end

  # Hooks
  # #####

  #There is an hook `custom_ressources` to customize income and spendings:
  def custom_ressources
    # add a current event
    event_duration=7
    event_frequency=0.2 #once every 5 months
    event_rewards={dia: 200, dust_h: 10}
    event_pass={dia: 800, stargazers: 10}
    daily_event_rewards=mult_hash(sum_hash(event_rewards, event_pass), event_duration/30.0*event_frequency)

    #let's try to add abex rewards and hf rewards to our income
    abex_rewards={stargazers: 20, dia: 3000} #todo: add other ones
    abex_frequency=1/60.0 #1 every 2 months
    daily_abex_rewards=mult_hash(abex_rewards, abex_frequency)

    hf_rewards={scrolls: 20, dia: 1000} #todo: add other ones
    hf_frequency=1/90.0 #1 every 3 months
    daily_hf_rewards=mult_hash(hf_rewards, hf_frequency)

    #we sell our daily arena tickets and dura's tears
    #  nb: don't do this! One arena ticket sells for 50K gold, but using it gives a lot more value:
    #  Arena ticket value: 6.81 [44.55 gold=2.54 dia + 5.95 dust=1.53 dia + 0.12 blue_stones=0.31 dia + 0.03 purple_stones=0.94 dia + 1.49 dia=1.49 dia]
    arena_tickets_to_sell=tally[:arena_tickets]
    dura_tears_to_sell=tally[:dura_tears]
    gold=arena_tickets_to_sell*50+dura_tears_to_sell*10
    sell_stuff={arena_tickets: -arena_tickets_to_sell, 
                dura_tears: -dura_tears_to_sell, 
                gold: +gold}

    #we also buy lct tickets every day, 300 dia for 5 tickets
    lct={dia: -300, lct_tickets: 5}

    {event: daily_event_rewards, abex: daily_abex_rewards, hf: daily_hf_rewards, selling_items: sell_stuff, lct_buy_tickets: lct}
  end

  ### More customisations

  # This is an OO program, so we can customize some existing functions

  # 1) the `friends` income ressource do not handle garrison for now
  #    it is easy to fix it
  def friends
    r=super #call the original function
    @nb_garrison ||= 5 #5 garrison monthly
    r[:friend_summons]+=@nb_garrison*10.0/30 #1 garrison = 10 friends point monthly
    r
  end

  # 2) we can add some items we want to buy in the shop:
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
  @Shop={reset_scroll: {reset_scrolls: 1, gold: -6000}} #it's already in the program, but let's pretend it was not
  @shop_items = get_shop_items({reset_scroll: 1}) #we only buy one scroll daily
end

#Now let's look at the summary!
s.summary
#s.show_variables
