#!/usr/bin/env ruby
require './economy'

=begin
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
s=Simulator.new do
  @nb_ff =3 #we only do ff up to 80
  @misty = { red_e: 4*10, t3: 2 } #our misty rewards
  #see `get_misty` as an helper function to build them:
  @misty = get_misty(misty_guild_twisted: :guild, misty_purple_blue: :blue)
end

# If we are feeling adventurous we can then even change internal variables:
s.instance_eval do
   # skipping large camps in dismal:
   @_dismal_stage_chest_rewards = { gold_h: 59, xp_h: 29.5, dust_h: 29.5 }
   # assume that vows only give 10 stargaze cards
   @_average_vow_rewards=({stargazers: 10})
end

#There are hooks `custom_income` and `custom_exchange` to customize income and spendings:
def s.custom_income
  #let's try to add abex rewards and hf rewards to our income
  abex_rewards={stargazers: 20, dia: 3000} #todo: add other ones
  abex_frequency=1/60.0 #1 every 2 months
  daily_abex_rewards=abex_rewards.map {|k,v| [k, v*abex_frequency]}.to_h
  hf_rewards={scrolls: 20, dia: 1000} #todo: add other ones
  hf_frequency=1/60.0 #1 every 2 months
  daily_hf_rewards=hf_rewards.map {|k,v| [k, v*hf_frequency]}.to_h
  {abex: daily_abex_rewards, hf: daily_hf_rewards}
end

def s.custom_exchange
  #we sell our daily arena tickets and dura's tears
  #nb: don't do this! One arena ticket sells for 50K gold
  #but using it gives a lot more value:
  #Arena ticket value: 6.81 [44.55 gold=2.54 dia + 5.95 dust=1.53 dia + 0.12 blue_stones=0.31 dia + 0.03 purple_stones=0.94 dia + 1.49 dia=1.49 dia]
  arena_tickets_to_sell=tally_income[:arena_tickets]
  dura_tears_to_sell=tally_income[:dura_tears]
  gold=arena_tickets_to_sell*50+dura_tears_to_sell*10
  sell_stuff={arena_tickets: -arena_tickets_to_sell, 
              dura_tears: -dura_tears_to_sell, 
              gold: +gold}

  #we also buy lct tickets every day, 300 dia for 5 tickets
  lct={dia: -300, lct_tickets: 5}

  {selling_items: sell_stuff, lct_buy_tickets: lct}
end

# This is an OO program, so we can customize some existing function
def s.exchange_shop
  #the exchange_shop currently only handle dust, dust_h, xp_h,
  #purple_stones, poe, shards, cores, silver_e, gold_e
  r=super #call the main function
  #we want to buy 1 reset scroll every day, it costs 6000K
  r[:reset_scroll]=1
  r[:gold] -= 6000
  r
end

#Now let's look at the summary!
s.summary
