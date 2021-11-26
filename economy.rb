#!/usr/bin/env ruby
#TODO: more events?, board level<7 + team quests

require './value'
require 'json'

class Simulator
  attr_accessor :ressources
  include Value
  include Data
  include Helpers

  def initialize(process: true, &b)
    instance_eval(&b) if b
    setup
    self.process if process
  end

  module UserSetup
    def setup_vars #assume an f2p vip 10 hero level 450 player at chap 38 with max fos by default and in fabled

      # Main settings
      # #############

      # Core settings
      @stage ||= "38-01" #warning: for stage comparison we want @stage="02-04" rather than @stage="2-04" for earlier chapters

      @hero_level ||= 450
      # If the rc is not yet 240, we can be more precise:
      # @hero_level = [240, 220, 200, 201, 205]
      @player_level ||=180 #for fos, 180 is max fos for gold/xp/dust mult
      @vip ||=10 #vip level
      @nb_ff ||=6

      ### Towers
      @tower_kt ||= 550 #max fos at 350 for t1_gear, 550 max fos for T2 chests
      @tower_4f ||= 280 #max fos at 280 for t2_gear
      @tower_god ||= 300 #max fos at 300 for invigor
      #we can also specify our individual tower progression:
      # @tower_4f=[320, 340, 347, 350]
      # @tower_god=[220, 350]

      ### Summonings
      @monthly_stargazing ||= 0 #number of stargazing done in a month (open at 16-01)
      @monthly_tavern ||= 0 #number of tavern pulls (open at 01-12)
      @monthly_hcp_heroes ||=0 #number of hcp heroes we want to summon monthly
      @monthly_hcp ||= get_hcp_from_nb_heroes(@monthly_hcp_heroes) #number of hcp pulls

      ### Friends and weekly mercs
      @friends_nb ||= 20
      @friends_mercs ||= 5 #[only used when mercs unlock]

      ### GH [only used when guild unlocks]
      @gh_wrizz_chests ||= 23
      @gh_soren_chests ||= @gh_wrizz_chests
      #if not specified, we determine the gold amount from the chest amount:
      @gh_wrizz_gold ||= get_guild_gold(@gh_wrizz_chests)
      @gh_soren_gold ||= get_guild_gold(@gh_soren_chests)
      @gh_soren_freq ||= 0.66 #or round(5.0/7.0) =0.71
      # we can get the gold from the guild mail (the guild coins and gold
      # we get in the mail is half what we get for our best run)
      # see also `guild_chest_from_gold` and `guild_chest_from_coins` to conversely get the number of guild chests from our gold or amount of guild coin

      ### twisted realm [only used when tr unlocks]
      @tr ||= {twisted: 380, poe: 1290} #use fabled rewards
      @tr_guild ||= {dia: 100, twisted: 420/70} #a guildie is in fabled

      ### cursed realm
      @cursed_realm ||= {} #not in cursed
      # @cursed_realm = get_cursed_realm(30) #in cursed and in top 30%

      ### arena [only used when arena/lc/lct unlocks]
      @arena_daily_dia ||= get_arena(5) #rank 5 in arena
      @arena_weekly_dia ||=@arena_daily_dia * 10
      @lct_coins ||=380 #top 20. Hourly coins: 400-rank
      @lc_rewards ||= {gold: 6*1278} #we win all wagers (6*941 for earlier accounts)

      ### misty valley [only used when misty unlocks]
      @misty ||= get_misty
      # can specify the required chest using: `chest5: poe` for instance
      # can also specify an ordering: get_misty(%i(cores red_e poe)) to ask for cores in priority if available, then red_e, then poe

      ### misc
      @board_level ||=8 #[only used when board unlocks]
      @dura_nb_selling ||=0 #dura's fragments we have maxed out and are selling

      ### Noble societies [only when they unlock]
      #by default paid is false

      @noble_regal ||= get_regal #opens after 10 days of account creation
      # Paid version: @noble_regal = get_regal(paid: true)

      @noble_twisted ||= get_twisted_bounties #default to xp
      # Example for the paid version and shard selection:
      #    @noble_twisted = get_twisted_bounties(:shards, paid: true)

      @noble_coe ||= get_coe #default to dust
      # Example for the paid version and cores selection:
      #    @noble_coe = get_twisted_bounties(:cores, paid: true)

      ### Hero trials [only used when hero trials unlock]
      @hero_trial_guild_rewards ||={ #average guild hero trial rewards
        dia: 200+100+200,
        guild_coins: 1000 #assume top 500
      }

      ### Labyrinth
      @labyrinth_mode = :auto #automatically select the hardest instance
      # modes: :skip, :easy, :hard, :dismal, :dismal_skip_large
      # see @lab_flat_rewards for the flat rewards, we use an approximation if this is not set

      # Spending money
      # ##############

      @subscription ||=false if @subscription.nil?

      ### Merchants
      #Paid version, f2p versions are in Merchant_daily, Merchant_weekly, Merchant_monthly
      @merchant_daily ||={} #we are f2p by default
      @merchant_weekly ||={}
      @merchant_monthly ||={}

      ### Cards

      @monthly_card ||={} #f2p
      # Exemples:
      #    @monthly_card={dia: 110, dust_h: 4*2*6}
      # Or use the helper function:
      #    @monthly_card=get_monthly_card #default to dust
      #    @monthly_card=get_monthly_card(:shard) #select shards

      @deluxe_monthly_card ||={} #f2p
      # Exemples with the helper function:
      #    @deluxe_monthly_card=get_deluxe_monthly_card #default to red_e+core
      #    @deluxe_monthly_card=get_deluxe_monthly_card(red: silver_e, purple: twisted) #select silver emblems and twisted essence

      # Stores
      # ======

      ### Daily shopping
      @shop_refreshes ||= 2

      # Set the items we want to buy:
      #   @shop_items = [item1, {item2: qty2}, item3, {item4: qty4}]
      # if qty is not set, assume we buy each time the shop is refreshed
      # (the program automatically handles probability and maximal number of buyings, eg for shards the daily max)

      # We can use an helper function:
      @shop_items ||= get_shop_items #get items depending on stage progression
      # - By default this function adds dust, purple_stones, poe and shards when they unlock. 
      # - Options: `poe: false` we say to not buy poe, idem for shards, ...
      # - Arguments are added to the list of items:
      #     @shop_items = get_shop_items(:dust_h, {gold_e: 2})
      #   -> Buy as many dust_h box as shop refreshes, but only max 2 gold emblems

      ### Monthly store buys
      #    @store_foo_items=[primary_item1, {primary_item2: qty2}, primary_item3, nil, {secondary_item4: qty4}, secondary_item5, nil, filler_item]
      # - we buy the primary items, even if we don't have enough coins (mainly
      #used for garrison/dim exchange). 
      # - we buy the secondary items if we have enough coins.
      # - if there are still coins remaining, use them all with `filler_item`.
      # - If not specified the qty is 1. With `qty=:max` we buy up to the maximal number of items in the shop. Example: in the hero store we can only buy up to 4 purple stones, so {purple_stones: :max} maxes out at 4.
      # Example: 
      #     @store_guild_items=[{garrison: 10}, nil, {t3: :max}, nil, :dim_gear]
      # -> set up 10 garrison stone using guild coins, buy max (ie 2) t3 and use dim_gear as a filler

      # Helper functions:
      #   @store_foo_items=get_store_foo_items(primary_item1, {primary_item2: qty2}, secondary: [{secondary_item3: qty3}, secondary_item4], filler: filler_item)
      # - These handle dim exchange and garrison automatically if they are active: they are added as primary items
      #  By default we use 50 lab points+10 guild points for dim exchange,
      #  and 100 lab points + 66 guild points + 34 hero points for garrison.
      # - Thes can be changed with the options `garrison: qty`, `dim_exchange: qty`.
      # Example: @store_lab_items = get_store_lab_items({red_e: 2}, {twisted: :max}, dim_exchange: 40)
      # -> buy 2 red emblems and the max number of twisted essence, and do a dim exchange with 40 points
      @garrison = false if @garrison.nil? #used by get_store_*_items, by default we only use hero+guild+lab for exchange
      @dim_exchange = false if @dim_exchange.nil? #used by get_store_*_items, by default we only use guild+lab for exchange

      @store_hero_items ||= get_store_hero_items

      @store_guild_items ||= get_store_guild_items
      #  By default, get_store_guild_items adds t3 as a primary (if they are unlocked), and dim_emblems as fillers (if they are unlocked). This can be tweaked via the options `t3: false`, `dim_gear: false`
      #  Example: @store_guild_items = get_store_guild_items({t1: :2}, :t2, filler: :random_mythic_gear)
      #  -> buy max (ie 2) t3 as primary, and 2 t1 + 1 t2 , and then spend all the rest on random mythic gears

      @store_lab_items ||= get_store_lab_items
      # By default adds dim_emblems as secondary (if they are unlocked), use `dim_emblems: false` to remove them.

      @store_challenger_items ||= get_store_challenger_items
      # By default do nothing, since we don't use challengers tokens for garrison/dim exchange!

      # Tower progression and level up
      # ##############################
      @monthly_levelup||=0
      # If the rc is less than 240, @monthly_levelup=10 means to add 10
      # levels on each hero. We can be more precise:
      #    @monthly_levelup = [10, 0, 5, 0, 0]
      # to add 10 levels to the first hero, and 5 to the third;

      # Examples:
      #  @tower_kt_progression=10 #we expect to climb 10 floors
      #  @tower_4f_progression=5 #we expect to climb 5 floors in all 4f towers
      #  @tower_4f_progression=[5, 0, 10, 2] #we expect to climb 5/0/10/2 floors respectively
      #  @tower_god_progression=2 #we expect to climb 2 floors in all celo/hypo towers
      #  @tower_god_progression=[1,3] #climb 1/3 floors respectively

      # Helper:
      set_tower_progression_from_levelup
      #this setup @tower_{kt,4f,god}_progression, the average number of floor we do monthly from our monthly level up number @monthly_levelup (which we can estimate using this simulator)

      # Other variables
      # ###############

      #@afk_xp=13265     # the displayed value by minute, this include the vip bonus but not the fos bonus
      #@afk_gold=844     # the displayed value by minute (include vip)
      #@afk_dust=1167.6  # the value by day, ie 48.65 by hour
      #-> determined from stage progression, but can be set up directly for more precise results
    end

    # Redefine these functions to add custom source of income and exchange
    # see the examples in economy_example.rb
    def custom_income
      {}
    end
    def custom_exchange
      {}
    end
  end
  include UserSetup

  module Setup
    def setup_constants
      @Cost={
        "SI+10": {silver_e: 240},
        "SI+20": {gold_e: 240},
        "SI+30": {red_e: 300},
        "e30": {shards: 3750},
        "e30 to e41": {cores: 1650},
        "e30 to e60": {cores: 4500},
        "e30 to e65": {cores: 4500+1500},
        "tree level": {twisted: 800},
        "mythic furn": {poe: 300/0.0407},
        #90 pulls = 1 mythic card, so 90 pulls = 1+ 90*0.0407 = 4.663 mythic furns
        "mythic furn (with cards)": {poe: 90*300/(1+90*0.0407)},
        "9F (with cards)": {poe: 167000},
        "Challenger celo": {challenger_coins: 250000},
        "Ascended challenger celo": {challenger_coins: 250000*14},

        "Ascended 4F": { atier: 8, fodder: 10},
        "Ascended god": { god: 14},
        "RC slot": { invigor: 5000},
      }.merge(@Cost||{})

      @Shop = {
        # there are 2 extra slots, for 24h gold, 24h xp, tokens, 500 dust,
        # purple stones. The first 4 are equiprobable and the last roughly
        # half as frequent, so we get a proba of 2/9 resp 1/9 by slot, so
        # 4/9 resp 2/9 by shop refresh
        xp_h: { xp_h: 24, dia: -192, proba: 4.0/9},
        dust_h: {dust_h: 24, dia: -300},
        dust: {dust: 500, gold: -2250},
        purple_stones: { purple_stones: 5, dia: -90, proba: 2.0/9 },
        poe: { poe: 250, gold: -1125 },
        shards: { shards: 20, gold: -2000, max: 3 },
        cores: { cores: 10, dia: -200, max: 3 },
        gold_e: { gold_e: 20, gold: -15600*@_shop_discount, proba: 0.25 },
        silver_e: { silver_e: 30, gold: -14400*@_shop_discount, proba: 0.75 },
        mythic_gear: {mythic_gear: 1, dia: -3168},  #3564 dia at earlier chapters
        reset_scroll: {reset_scrolls: 1, gold: -6000},
        fodder: {random_fodder: 1, dia: -2268},#9 blue cards
      }.merge(@Shop||{})
      # note: at chap 22, we have 500 dust, 30/20 gold/siver_e, shards and core, but only 100 poe

      @StoreHero ={
        fodder: {cost: 4800, choice_fodder: 1.0/9},
        purple_stone: { cost: 18000, purple_stones: 60, max: 4},
        blue_stone: { cost: 2400, blue_stones: 60, max: 1+2+3+4},
        twisted: { cost: 10000, twisted: 100, max: 1+2+3+10},

        garrison: { cost: 800, garrison_stone: 1, max: 66},
        dim_exchange: {cost: 4000, dim_points: 1, max: 40},
      }.merge(@StoreHero||{})

      @StoreGuild ||={
        t1: 33879, #shortcut for t1: {cost: 33879, t1: 1}
        t2: 40875,
        t3: {cost: 47000, t3: 1, max: 2},
        random_mythic_gear: 31350,
        mythic_gear: 84260*@_shop_discount, #there is also the mythic variety chest (max 1) for 63000 coins at later chapters
        dim_gear: 67000, #shortcut for dim_gear: {cost: 67000, dim_gear:1},

        garrison: { cost: 800, garrison_stone: 1, max: 66},
        dim_exchange: {cost: 4000, dim_points: 1, max: 40},
      }.merge(@StoreGuild||{})

      @StoreLab={
        #blue_stone: { cost: 2400, blue_stones: 60, max: 8},
        blue_stone: { cost: 4800, blue_stones: 120, max: 4},
        # ealier we have 8x60 blue stones, 4 of them are replaced by red_e+twisted afterwards
        fodder: {cost: 4800, choice_fodder: 1.0/9},
        atier: {cost: 45000, choice_atier: 1},
        dust: {cost: 9000, dust: 1500, max: 2},
        twisted: {cost: 40000, twisted: 400, max: 2+1},
        wukong: 45000, arthur: 60000, #we get dim_e after Arthur, twisted after wukong
        dim_emblems: {cost: 64000, dim_emblems: 50},
        red_e: {cost: 37125, red_e: 25, max: 2},

        garrison: { cost: 800, garrison_stone: 1, max: 100},
        dim_exchange: {cost: 4000, dim_points: 1, max: 200},
      }.merge(@StoreLab||{})

      @StoreChallenger={
        god: { cost: 250000, choice_god: 1},
        #they are replaced by shards after 5*
        shard: { cost: 10000, shards: 30},
        atier: {cost: 150000, choice_atier: 1},
        flora: 150000,
        merlin: 250000, ldv: 250000,
        red_e: {cost: 165000, red_e: 25, max: 3},

        garrison: { cost: 2666, garrison_stone: 1, max: 50},
        dim_exchange: {cost: 13333, dim_points: 1, max: 15},
      }.merge(@StoreChallenger||{})

      @Merchant_daily={ dia: 20, purple_stones: 2}.merge(@Merchant_daily||{})
      @Merchant_weekly={ dia: 20, purple_stones: 5}.merge(@Merchant_weekly||{})
      @Merchant_monthly={ dia: 50, purple_stones: 10}.merge(@Merchant_monthly||{})

      @Quest_daily={ #quest without fos
        gold_hg: 2,
        blue_stones: 5, arena_tickets: 2, xp_h: 2, scrolls: 1,
        dia: 100
      }.merge(@Quest_daily||{})
      @Quest_weekly= {
        gold_h: 8+8,
        blue_stones: 60, purple_stones: 10,
        dia: 400, scrolls: 3,
        dura_tears: 3
      }.merge(@Quest_weekly||{})

      @Dismal_rewards ||= { dia: 300, lab_coins: (4200+700), guild_coins: 1000, challenger_coins: 3333 }
      @Lab_hard_rewards ||= { dia: 300, lab_coins: 3867+1000, guild_coins: 1000, challenger_coins: 3333 }
      @Lab_easy_rewards ||= { dia: 300, lab_coins: 3867 }
      @Dismal_stage_chest_rewards ||= { gold_h: 79, xp_h: 39.5, dust_h: 39.5 }
      @Dismal_stage_chest_skip_rewards ||= { gold_h: 59, xp_h: 29.5, dust_h: 29.5 } # skipping large camps: 59h gold+29.5h xp+dust
      @Dismal_end_rewards ||= {
        gold_h: 14*6 + 7*2, xp_h: 3.5*2, dust_h: 3.5*2,
        shards: 61, cores: 41
      } 
      #We have less end rewards in standard lab, apart from the 6h gold
      #chest we only have 2 items rather than 3, so multiply the rewards by 2/3
      @Lab_end_rewards ||= { gold_h: 14*6 + 7*2*2.0/3, xp_h: 3.5*2*2.0/3, dust_h: 3.5*2*2.0/3 }
      #approximations to recover the flat rewards
      #@_lab_flat_gold_h ||=55 #new approx: 65.71
      @_lab_flat_gold_h ||=65 #new approx: 65.71
      @_lab_flat_xp_h ||=6 #new approx: 5.785 or 5.88

      @GH_chest_dia ||=2.7
      @GH_chest_guild ||=65

      @Oak_amount={blue_stones: 30, dia: 100, dust: 500, gold: 1500}
      @Oak_quantity=3; @Oak_proba=0.25

      @Misty_base={ gold: 7000, dust_h: 7*4*8, xp_h: 6*24,
             blue_stones: 10*120, purple_stones: 10*18,
             poe: 20*450}.merge(@Misty_base || {})

      @Noble_regal_days ||=49
      @Noble_twisted_days ||=44
      @Noble_coe_days ||=36

      @Monthly_vows ||=2 #2 by month
      @Monthly_hero_trial ||=2
      @Hero_trial_rewards={
        gold: 2000, dia: 300,
        dust_h: 6*2, xp_h: 6*2, gold_h: 6*8,
        blue_stones: 60, purple_stones: 60
      }.merge(@Hero_trial_rewards||{})

      @Dura_nb ||=7.0
    end

    def setup 
      @ressources={}

      setup_vars
      get_progression
      setup_constants
      setup_internals
      get_idle_hourly
      post_setup_hook
    end

    def setup_internals
      get_vip
      get_fos
      get_subscription
      get_mult
      get_numbers
    end

    def post_setup_hook
    end
  end
  include Setup

  module GuildHelpers
    def get_guild_chests(dmg)
      nb=0
      nb=1 if dmg >= 5000
      nb=2 if dmg >= 10000
      nb=3 if dmg >= 20000
      nb=4 if dmg >= 40000
      nb=5 if dmg >= 70000
      nb=6 if dmg >= 120000 # 120k
      nb=7 if dmg >= 220000
      nb=8 if dmg >= 450000
      nb=9 if dmg >= 820000
      nb=10 if dmg >= 1550000 # 1.55M
      nb=11 if dmg >= 3000000
      nb=12 if dmg >= 5500000
      nb=13 if dmg >= 10000000 # 10M
      nb=14 if dmg >= 20000000
      nb=15 if dmg >= 45000000
      nb=16 if dmg >= 99999999 # 100M
      nb=17 if dmg >= 30000000
      nb=18 if dmg >= 999999999 # 1B
      nb=19 if dmg >= 199999999 # 2B
      nb=20 if dmg >= 499999999 # 5B 
      nb=21 if dmg >= 999999999 # 10B
      nb=22 if dmg >= 1999999999 # 20B
      nb=23 if dmg >= 9999999999 # 100B
      nb
    end
    def get_guild_gold(chests)
      case chests
      when 1; 2     # 5k
      when 2; 4     # 10k
      when 3; 7.5   # 20k
      when 4; 15    # 40k
      when 5; 20    # 70k
      when 6; 30    # 120k
      when 7; 38    # 220k
      when 8; 55    # 450k
      when 9; 65    # 820k
      when 10; 80   # 1.55M
      when 11; 110  # 3M
      when 12; 160  # 5.5M
      when 13; 246  # 10M
      when 14; 435  # 20M
      when 15; 953  # 45M
      when 16; 1044 # 100M
      when 17; 1150 # 300M
      when 18; 1410 # 1B
      when 19; 1560 # 2B
      when 20; 1710 # 5B
      when 21; 1865 # 10B
      when 22; 2010 # 20B
      when 23; 2160 # 100B
      end
    end

    def guild_chest_from_gold(gold)
      return 23 if gold>=2160
      (1..Float::INFINITY).each do |i|
        g=get_guild_gold(i)
        return i-1 if g>gold
      end
    end
  end
  include GuildHelpers
  extend GuildHelpers

  module UserSetupHelpers
    def get_hcp_from_nb_heroes(heroes=@monthly_hcp_heroes)
      heroes*round(10/0.461)
    end
    #call this function when @_guild_mult is built
    #either in post_setup_hook, or by calling setup_internals first
    def guild_chest_from_coins(coins)
      (coins/(65.0*@_guild_mult)).round
    end

    def get_regal(paid:false)
      if paid
        {dia: 5500, purple_stones: 1100, blue_stones: 3300}
      else
        {blue_stones: 3300}
      end
    end

    def get_twisted_bounties(type=:xp, paid: false)
      get_progression
      return {} unless @_unlock_tr
      if paid
        case type
        when :gold; {dia: 5500, gold_h: 11472}
        when :xp; {dia: 5500, xp_h: 3444}
        when :twisted; {dia: 5500, twisted: 3700}
        when :poe; {dia: 5500, poe: 37000}
        when :shards; {dia: 5500, shards: 1170}
        end
      else
        case type
        when :gold; {gold_h: 3824}
        when :xp; {xp_h: 956}
        when :twisted; {twisted: 990}
        when :poe; {poe: 9900}
        when :shards; {shards: 1170}
        end
      end
    end

    def get_coe(type=:dust, paid: false)
      get_progression
      return {} unless @_unlock_coe
      if paid
        case type
        when :dust; {dia: 5500, dust: 50000, dust_h: 1900}
        when :red_e; {dia: 5500, red_e: 210}
        when :gold_e; {dia: 5500, gold_e: 484}
        when :silver_e; {dia: 5500, silver_e: 735}
        when :cores; {dia: 5500, cores: 1960}
        end
      else
        case type
        when :dust; {dust: 7500, dust_h: 380}
          #this is 6.42 + 15.83 = 21.82 days of dust, ie 6549 dia
        when :red_e; {red_e: 49}
        when :gold_e; {gold_e: 136}
        when :silver_e; {silver_e: 192}
        when :cores; {cores: 585}
        end
      end
    end

    #by default we take the last one, so no need for ordering
    #use order=%i(cores shards red_e poe) to priviliege cores then shards then red_e then poe
    def get_misty(order=%i(), chest1: nil, chest2: nil, chest3: nil, chest4: nil, chest5: nil, chest6: nil, chest7: nil, chest8: nil, chest9: nil, chest10: nil, chest11: nil, chest12: nil, chest13: nil, chest14: nil, chest15: nil)
      @Misty_chests={
        chest1: [{gold_h: 24*12}, {xp_h: 8*12}, {dust_h: 8*12}],
        chest2: [ {dia: 1000}, {guild_coins: 30000}, {twisted: 400} ],
        chest3: [ {purple_stones: 60}, {blue_stones: 720} ],
        chest4: [ {scrolls: 5}, {poe: 1000}, {purple_stones: 60} ],
        chest5: [ {poe: 1000}, {silver_e: 40}, {gold_e: 20}, {red_e: 10} ],
        chest6: [ {t1: 1}, {t2: 1}, {t3: 1} ],
        chest7: [ {shards: 200}, {silver_e: 40}, {gold_e: 20}, {poe: 1000}, {red_e: 10} ],
        chest8: [ {scrolls: 5}, {poe: 1000}, {purple_stones: 60} ],
        chest9: [ {hero_choice_chest: 1} ],
        chest10: [ {silver_e: 40}, {gold_e: 20}, {poe: 1000}, {red_e: 10}, {cores: 100} ],
        chest11: [ {shards: 200}, {silver_e: 40}, {gold_e: 20}, {red_e: 10} ],
        chest12: [ {poe: 2000}, {twisted: 200}, {cores: 100} ],
        chest13: [ {shards: 200}, {silver_e: 40}, {gold_e: 20}, {red_e: 10} ],
        chest14: [ {poe: 2000}, {twisted: 200}, {cores: 100} ],
        chest15: [ {poe: 1000}, {t1: 1}, {t2: 1}, {t3: 1} ]
      }.merge(@Misty_chests || {})
      r={}
      misty_chests=@Misty_chests.map do |k,v|
        rewards=v
        if rewards.is_a?(Array) #convert it to a hash
          rewards=rewards.map {|v| [v.keys.first, v]}.to_h
        end
        [k, rewards]
      end.to_h
      find_chest=lambda do |chest|
        rewards=chest.keys
        best=order.find {|i| rewards.include?(i)} || rewards.last
        return best
      end
      get_chest=lambda do |nb, required|
        chest=misty_chests[nb]
        rewards = required || find_chest[chest]
        value=chest[rewards]
        if value.nil?
          warn "[Warning] Required reward `#{required}` not found in chest #{nb}" 
          value={}
        end
        return value
      end

      if @stage >= "17-01"
        add_to_hash(r,get_chest[:chest1, chest1])
        add_to_hash(r,get_chest[:chest2, chest2])
        add_to_hash(r,get_chest[:chest3, chest3])
        add_to_hash(r,get_chest[:chest4, chest4])
      end
      add_to_hash(r,get_chest[:chest5, chest5]) if @stage >= "21-01"
      add_to_hash(r,get_chest[:chest6, chest6]) if @stage >= "23-01"
      add_to_hash(r,get_chest[:chest7, chest7]) if @stage >= "25-01"
      add_to_hash(r,get_chest[:chest8, chest8]) if @stage >= "27-01"
      add_to_hash(r,get_chest[:chest9, chest9]) if @stage >= "29-01"
      add_to_hash(r,get_chest[:chest10, chest10]) if @stage >= "31-01"
      add_to_hash(r,get_chest[:chest11, chest11]) if @stage >= "32-01"
      add_to_hash(r,get_chest[:chest12, chest12]) if @stage >= "33-01"
      add_to_hash(r,get_chest[:chest13, chest13]) if @stage >= "34-01"
      add_to_hash(r,get_chest[:chest14, chest14]) if @stage >= "35-01"
      add_to_hash(r,get_chest[:chest15, chest15]) if @stage >= "36-01"
      r
    end

    def get_cursed_realm(rank=nil)
      return {} if rank==nil #not in twisted
      r={twisted: 100, shards: 100}
      r={twisted: 120, shards: 120} if rank <= 95
      r={twisted: 140, shards: 140} if rank <= 90
      r={twisted: 160, shards: 160} if rank <= 85
      r={twisted: 180, shards: 180} if rank <= 80
      r={twisted: 200, shards: 200} if rank <= 75
      r={twisted: 220, shards: 220} if rank <= 70
      r={twisted: 240, shards: 240} if rank <= 65
      r={twisted: 260, shards: 260} if rank <= 60
      r={twisted: 280, shards: 280} if rank <= 55
      r={twisted: 300, shards: 300, cores: 10} if rank <= 50
      r={twisted: 320, shards: 320, cores: 20} if rank <= 47
      r={twisted: 340, shards: 340, cores: 30} if rank <= 44
      r={twisted: 360, shards: 360, cores: 40} if rank <= 41
      r={twisted: 380, shards: 380, cores: 50} if rank <= 38
      r={twisted: 400, shards: 400, cores: 60} if rank <= 35
      r={twisted: 420, shards: 400, cores: 70} if rank <= 32
      r={twisted: 440, shards: 400, cores: 80} if rank <= 29
      r={twisted: 460, shards: 400, cores: 90} if rank <= 26
      r={twisted: 480, shards: 400, cores: 100} if rank <= 23
      r={twisted: 500, shards: 400, cores: 110} if rank <= 21
      r={twisted: 530, shards: 400, cores: 120} if rank <= 19
      r={twisted: 560, shards: 400, cores: 130} if rank <= 16
      r={twisted: 590, shards: 400, cores: 140} if rank <= 14
      r={twisted: 620, shards: 400, cores: 150} if rank <= 12
      r={twisted: 650, shards: 400, cores: 160, stargazers: 3} if rank <= 10
      r={twisted: 680, shards: 400, cores: 170, stargazers: 4} if rank <= 8
      r={twisted: 710, shards: 400, cores: 180, stargazers: 5} if rank <= 6
      r={twisted: 740, shards: 400, cores: 200, stargazers: 6} if rank <= 5
      r={twisted: 770, shards: 400, cores: 220, stargazers: 7} if rank <= 4
      r={twisted: 800, shards: 400, cores: 240, stargazers: 8} if rank <= 3
      r={twisted: 850, shards: 400, cores: 260, stargazers: 9} if rank <= 2
      r={twisted: 1000, shards: 400, cores: 300, stargazers: 10} if rank <= 1
      return r
    end

    def get_monthly_card(type=:dust)
      purple=case type
      when :shard; {shards: 15}
      when :silver_e; {silver_e: 3}
      when :gold_e; {gold_e: 2}
      when :gold; {gold_h: 8*6}
      when :xp; {xp_h: 2*6}
      when :dust; {dust_h: 2*6}
      end
      nb=3 #level 1
      nb=4 if @vip >= 12 #level 2
      sum_hash({dia: 300/30+100}, mult_hash(purple, nb))
    end
    def get_deluxe_monthly_card(red: :red_e, purple: :core)
      red=case red
      when :silver_e; {silver_e: 8}
      when :gold_e; {gold_e: 5}
      when :red_e; {red_e: 2}
      end
      nb_red=1 #level 1
      nb_red=2 if @vip >= 14 #level 3

      purple=case purple
      when :poe; {poe: 240}
      when :twisted; {twisted: 24}
      when :core; {cores: 12}
      when :blue_stone; level <=2 ? {blue_stones: 30} : {blue_stones: 60}
      end
      nb_purple=1 #level 1
      nb_purple=2 if @vip >= 12 #level 2

      sum_hash({dia: 980.0/30+600}, mult_hash(purple, nb_purple), mult_hash(red, nb_red))
    end

    def get_shop_items(*extra, dust: true, stones: true, poe: :unlocked, shards: :unlocked)
      get_progression
      return [] unless @_unlock_shop
      poe=@_unlock_afk_poe if poe == :unlocked
      shards=@_unlock_afk_shard if shards == :unlocked
      r=[]
      r << :dust if dust
      r << :purple_stones if stones
      r << :poe if poe
      r << :shards if shards
      r += extra
      r
    end

    def get_store_hero_items(*extra, garrison: (@garrison ? 34 : 0), dim_exchange: 0, secondary: [], filler: nil)
      get_progression
      return [] unless @_unlock_store_hero
      r=[]
      r << {garrison: garrison} if garrison >0
      r << {dim_exchange: dim_exchange} if dim_exchange>0
      r += extra
      r << nil #for secondary items
      r += secondary
      r+=[nil, filler] if filler
      r
    end
    def get_store_guild_items(*extra, garrison: (@garrison ? 66 : 0), dim_exchange: (@dim_exchange ? 10/2 : 0), secondary: [], t3: :unlocked, dim_gear: :unlocked, filler: nil)
      get_progression
      return [] unless @_unlock_store_guild
      t3=@_unlock_t3 if t3 == :unlocked
      dim_gear=@_unlock_guild_store_mythic if dim_gear == :unlocked
      r=[]
      r << {garrison: garrison} if garrison >0
      r << {dim_exchange: dim_exchange} if dim_exchange>0
      r += extra
      r << {t3: :max} if t3
      r << nil #secondary items
      r += secondary
      if filler
        r+=[nil, filler]
      else
        r += [nil, :dim_gear] if dim_gear
      end
      r
    end
    def get_store_lab_items(*extra, garrison: (@garrison ? 100 : 0), dim_exchange: (@dim_exchange ? 50/2 : 0), secondary: [], dim_emblems: :unlocked, filler: nil)
      get_progression
      return [] unless @_unlock_store_lab
      dim_emblems=@_unlock_afk_red_e if dim_emblems == :unlocked
      r=[]
      r << {garrison: garrison} if garrison >0
      r << {dim_exchange: dim_exchange} if dim_exchange>0
      r += extra
      r << nil
      r += secondary
      r << :dim_emblems if dim_emblems
      r+=[nil, filler] if filler
      r
    end
    def get_store_challenger_items(*extra, garrison: 0, dim_exchange: 0, secondary: [], filler: nil)
      get_progression
      return [] unless @_unlock_store_challenger
      r=[]
      r << {garrison: garrison} if garrison >0
      r << {dim_exchange: dim_exchange} if dim_exchange>0
      r += extra
      r << nil #secondary items
      r += secondary
      r+=[nil, filler] if filler
      r
    end
  end
  include UserSetupHelpers

  module Process
    def process!
      get_income
      make_exchange
      summonings #summons, could be seen as an exchange but sufficiently different to be treated separatly
      exchange_coins #long term coin exchange, ditto
      handle_towers #tower progression
      monthly_levelup(@monthly_levelup) #levelup
      get_ressource_order
    end

    def process
      process!
    end

    def get_income
      @ressources[:idle]=idle
      @ressources[:ff]=ff
      @ressources[:board]=bounties if @_unlock_board
      @ressources[:guild]=guild if @_unlock_guild
      @ressources[:oak_inn]=oak_inn if @_unlock_oak_inn
      @ressources[:tr]=tr if @_unlock_tr
      @ressources[:cursed]=cursed_realm if @cursed_realm and not @cursed_realm.empty?
      @ressources[:quests]=quests
      @ressources[:merchants]=merchants
      @ressources[:friends]=friends
      @ressources[:arena]=arena if @_unlock_arena
      @ressources[:lct]=lct if @_unlock_lct
      @ressources[:lc]=lc if @_unlock_lc
      @ressources[:lab]=labyrinth
      @ressources[:misty]=misty if @_unlock_misty
      @ressources[:regal]=regal
      @ressources[:tr_bounties]=twisted_bounties
      @ressources[:coe]=coe
      @ressources[:hero_trial]=hero_trial if @_unlock_trials
      @ressources[:guild_hero_trial]=guild_hero_trial if @_unlock_trials
      @ressources[:vow]=vow
      @ressources[:monthly_card]=@monthly_card
      @ressources[:deluxe_monthly_card]=@deluxe_monthly_card
      @ressources.merge!(custom_income)
    end

    def make_exchange
      @ressources[:ff_cost]=exchange_ff
      @ressources[:shop]=exchange_shop
      @ressources[:dura_fragments_sell]=sell_dura
      @ressources.merge!(custom_exchange)
    end

    def handle_towers
      @ressources.merge!(towers_ressources)
    end
  end
  include Process

  module LevelUp
    def one_level_up_cost(*levels, hack: false)
      r=get_hero_level_stats
      max=r.keys.max
      gold=xp=dust=0
      levels.each do |level|
        if level>max
          warn "[Warning]: no cost data for hero level #{level}, using the one from level #{max}"
          level=max
        end
        g=r[level][:gold]
        x=r[level][:xp]
        d=r[level][:dust]
        #at 240 we level up the whole crystal
        #so we simulate a by hero cost of /5
        if hack and level >= 240
          g=g/5.0;
          x=x/5.0;
          d=d/5.0;
        end
        gold+=g; xp+=x; dust+=d
      end
      return [gold, xp, dust]
    end
    def one_level_up_cost_h(*levels,**kw)
      gold, xp, dust = one_level_up_cost(*levels,**kw)
      {gold: gold, xp: xp, dust: dust}
    end

    def level_up_rc(levels)
      return level_up_rc([levels]*5) if levels.is_a?(Integer)
      return one_level_up_cost(*levels, hack: true)
    end
    def level_up_rc_h(levels)
      gold, xp, dust = level_up_rc(levels)
      {gold: gold, xp: xp, dust: dust}
    end

    def current_level_cost
      gold, xp, dust = level_up_rc(@hero_level)
      @_current_level_gold ||= gold
      @_current_level_xp ||= xp
      @_current_level_dust ||= dust
      {gold: @_current_level_gold, xp: @_current_level_xp, dust: @_current_level_dust}
    end

    def level_up_cost(nb_levels, levels=@hero_level)
      return level_up_cost(nb_levels, [levels]*5) if levels.is_a?(Integer)
      return level_up_cost([nb_levels]*levels.length, levels) if nb_levels.is_a?(Integer)
      r={}
      levels.each_with_index do |level,i|
        (0...nb_levels[i]).each do |n|
          add_to_hash(r, one_level_up_cost_h(level+n, hack: true))
        end
      end
      r
    end

    def monthly_levelup(nb_levels)
      @ressources[:levelup]=mult_hash(level_up_cost(nb_levels), -1/30.0)
    end

    def ressources_cost
      r={level: current_level_cost}
      r.merge(@Cost)
    end
  end
  include LevelUp

  module SetupHelpers
    def get_progression #variables depending on progression
      stage= @stage || "01-01" #in case we call this from the setup function
      vip=@vip || 0

      @_shop_discount =1
      @_shop_discount =0.7 if stage >= "33-01" #is that correct?
      #todo adjust depending on stage progression

      @_unlock_ff=true if stage > "03-36" #not used
      @_unlock_guild=true if stage >"02-20"
      @_unlock_arena=true if stage >"02-28"
      @_unlock_board=true if stage >"03-12"
      @_unlock_lc=true if stage >"05-40"
      @_unlock_trials=true if stage >"06-40"
      @_unlock_coe=true if stage >"08-20"
      @_unlock_lct=true if stage >"09-20"
      @_unlock_tr=true if stage >"12-40" #and twisted bounties
      @_unlock_oak_inn=true if stage >"04-40" #we unlock our own oak inn at 17-40, but can access friends ones at 04-40
      @_unlock_misty=true if stage >"16-40"
      @_unlock_mercs=true if stage > "06-40"

      #not used except for t3
      @_unlock_shop=true if stage > "02-08"
      @_unlock_shop_mythic=true if stage > "10-22"
      @_unlock_guild_store_legendary=true if stage > "10-22"
      @_unlock_guild_store_mythic=true if stage > "12-02"
      @_unlock_t1=true if stage > "21-01" #also for shop
      @_unlock_t2=true if stage > "26-01"
      @_unlock_t3=true if stage > "30-01"

      @_unlock_store_hero=true if stage > "01-12"
      @_unlock_store_guild=true if stage > "02-40"
      @_unlock_store_lab=true if stage > "02-20"
      @_unlock_store_challenger=true if stage > "09-20"

      @_unlock_tower_kt=true if stage > "02-12"
      @_unlock_tower_4f=true if stage > "14-40"
      @_unlock_tower_god=true if stage > "29-60"

      #for information, not used
      @_unlock_ranhorn=true if stage > "01-12"
      @_unlock_tavern=true if stage > "01-12"
      @_unlock_temple=true if stage > "01-12"
      @_unlock_rickety=true if stage > "01-12"
      @_unlock_dark_forest=true if stage > "02-04"
      @_unlock_labyrinth=true if stage > "02-04"
      @_unlock_labyrinth_hard=true if stage > "09-24"
      @_unlock_labyrinth_dismal=true if stage > "26-60"
      @_unlock_library=true if stage > "02-16"
      @_unlock_prog_rewards=true if stage > "02-28"
      @_unlock_wishlist=true if stage > "04-04"
      @_unlock_wall_legends=true if stage > "04-36"
      @_unlock_artifacts=true if stage > "06-04"
      @_unlock_artifacts_enhancements=true if stage > "13-40"
      @_unlock_guild_grounds=true if stage > "06-04"
      @_unlock_elder_tree=true if stage > "08-40"
      @_unlock_twisted=true if stage > "08-40"
      @_unlock_fos=true if stage > "11-40"
      @_unlock_board_autofill=true if stage > "12-40" or vip>=6
      @_unlock_stargazer=true if stage > "15-40"
      @_unlock_abex=true if stage > "15-40"
      @_unlock_own_oak_inn=true if stage > "17-40"

      @_unlock_afk_legendary=true if stage > "11-18"
      @_unlock_afk_mythic=true if stage > "16-11"
      @_unlock_afk_mythic=true if stage > "16-11"
      @_unlock_afk_silver_e=true if stage > "16-40"
      @_unlock_afk_gold_e=true if stage > "17-40"
      @_unlock_afk_red_e=true if stage > "18-40"
      @_unlock_afk_twisted=true if stage >= "14-40" #somewhere before
      @_unlock_afk_poe=true if stage > "17-40" #somewhere before 18-40, lets assume this is the same as oak inn opening
      @_unlock_afk_shard=true if stage > "21-60" #chap 22
      @_unlock_afk_core=true if stage > "23-60" #chap 24

      @_unlock_gh_skip=true if vip>=6
      @_unlock_arena_skip=true if vip>=6
      @_unlock_speed2=true if stage > "02-16" or vip>=2
      @_unlock_speed4=true if stage > "21-60" or vip>=11
    end

    def get_vip
      @_vip_solo_bounty=5
      @_vip_gold_mult=0.0
      @_vip_max_ff=1 #not used, just for info
      if @vip >= 1
        @_vip_max_ff=2
        @_vip_gold_mult=0.05
        @_vip_extra_arena_fight=1
      end
      if @vip >= 2
        @_vip_gold_mult=0.1
        @_vip_solo_bounty=6
      end
      if @vip >= 3
        @_vip_gold_mult=0.2
        @_vip_extra_arena_fight=2
        @_vip_max_ff=3
      end
      if @vip >= 4
        @_vip_gold_mult=0.25
      end
      if @vip >= 5
        @_vip_gold_mult=0.3
        @_vip_solo_bounty=7
        @_vip_extra_arena_fight=3
      end
      if @vip >= 6
        @_vip_gold_mult=0.5
        @_vip_extra_guild_fight=1
        @_vip_extra_team_bounty=1
        @_vip_max_ff=5
      end
      if @vip >= 7
        @_vip_gold_mult=0.55
        @_vip_extra_arena_fight=4
      end
      if @vip >= 8
        @_vip_gold_mult=0.6
        @_vip_solo_bounty=8
      end
      if @vip >= 9
        @_vip_gold_mult=0.9
        @_vip_extra_arena_fight=5
        @_vip_max_ff=7
      end
      if @vip >=  10
        @_vip_gold_mult=1.0
        @_vip_lab_gold_mult=0.2
      end
      if @vip >=  11
        @_vip_gold_mult=1.1
        @_vip_lab_gold_mult=0.5
        @_vip_extra_arena_fight=6
        @_vip_solo_bounty=9
      end
      if @vip >=  12
        @_vip_gold_mult=1.5
        @_vip_lab_gold_mult=1.0
        @_vip_max_ff=8
      end
      if @vip >=  13
        @_vip_gold_mult=1.6
        @_vip_lab_mult=0.5
        @_vip_extra_arena_fight=7
      end
      if @vip >=  14
        @_vip_gold_mult=1.7
        @_vip_lab_mult=1.0
        @_vip_solo_bounty=10
      end
      if @vip >=  15
        @_vip_gold_mult=2.0
        @_vip_max_ff=12
      end
      if @vip >=  16
        @_vip_gold_mult=2.3
      end
      if @vip >=  17
        @_vip_gold_mult=2.6
      end
      if @vip >=  18
        @_vip_gold_mult=3.0
      end

      warn "[Warning] The number of ff #{@nb_ff} is greater than the max #{@_vip_max_ff} possible from your vip #{@vip}" if @nb_ff > @_vip_max_ff
      warn "[Warning] #{@nb_ff} fast forward requested, but fast forwards not yet unlocked" if @nb_ff>0 and !@_unlock_ff

      @_vip_xp_mult||=@_vip_gold_mult
    end

    def get_fos
      #stage fos maxes out at chap 33
      @_fos_base_gold=0
      @_fos_base_gold += 70 if @stage > "12-40"
      @_fos_base_gold += 75 if @stage > "18-40"
      @_fos_base_gold += 80 if @stage > "24-60"
      @_fos_base_xp=0
      @_fos_base_xp+=182 if @stage > "14-40"
      @_fos_base_xp+=372 if @stage > "20-60"
      @_fos_base_xp+=812 if @stage > "25-60"
      @_fos_base_dust=0
      @_fos_base_dust+=80 if @stage > "16-40"
      @_fos_base_dust+=135 if @stage > "22-60"
      @_fos_base_dust+=170 if @stage > "26-60"

      @_fos_lab_mult=0
      @_fos_lab_mult += 0.15 if @stage > "15-40"
      @_fos_lab_mult += 0.15 if @stage > "21-60"
      @_fos_lab_mult += 0.15 if @stage > "25-60"
      @_fos_guild_mult=0 
      @_fos_guild_mult += 0.15 if @stage > "14-40"
      @_fos_guild_mult += 0.15 if @stage > "17-40"
      @_fos_guild_mult += 0.15 if @stage > "20-60"
      @_fos_mythic_mult=0
      @_fos_mythic_mult += 0.3 if @stage > "16-40"
      @_fos_mythic_mult += 0.3 if @stage > "24-60"
      @_fos_mythic_mult += 0.3 if @stage > "32-60"
      @_fos_mythic_mult=0.3*3 #stage 32-60

      @_fos_gold_mult=0.0
      @_fos_xp_mult=0.0
      @_fos_dust_mult=0.0
      @_fos_gold_mult += 0.8 if @player_level >= 90
      @_fos_gold_mult += 0.8 if @player_level >= 105
      @_fos_gold_mult += 0.8 if @player_level >= 130
      @_fos_gold_mult += 0.8 if @player_level >= 160
      @_fos_xp_mult += 0.5 if @player_level >= 95
      @_fos_xp_mult += 0.5 if @player_level >= 110
      @_fos_xp_mult += 0.5 if @player_level >= 140
      @_fos_xp_mult += 0.5 if @player_level >= 170
      @_fos_dust_mult += 0.4 if @player_level >= 100
      @_fos_dust_mult += 0.4 if @player_level >= 120
      @_fos_dust_mult += 0.4 if @player_level >= 150
      @_fos_dust_mult += 0.4 if @player_level >= 180

      @_fos_t1_gear_bonus=0
      @_fos_t1_gear_bonus +=1 if [*@tower_kt].min >= 250
      @_fos_t1_gear_bonus +=1 if [*@tower_kt].min >= 300
      @_fos_t1_gear_bonus +=1 if [*@tower_kt].min >= 350
      @_fos_t2_gear_bonus=0
      @_fos_t2_gear_bonus +=1 if [*@tower_4f].min >= 200
      @_fos_t2_gear_bonus +=1 if [*@tower_4f].min >= 240
      @_fos_t2_gear_bonus +=1 if [*@tower_4f].min >= 280
      @_fos_invigor_bonus=0
      @_fos_invigor_bonus +=1 if [*@tower_god].min >= 100
      @_fos_invigor_bonus +=1 if [*@tower_god].min >= 200
      @_fos_invigor_bonus +=1 if [*@tower_god].min >= 300

      @_fos_daily_quest = {}
      @_fos_daily_quest[:dia]=50 if @stage > "16-40"
      @_fos_daily_quest[:dust_h]=2 if @stage > "20-60"
      @_fos_daily_quest[:gold_h]=2 if @stage > "23-60"
      @_fos_weekly_quest = {}
      @_fos_weekly_quest[:twisted]=50 if @stage > "22-60"
      @_fos_weekly_quest[:poe]=500 if @stage > "23-60"
      @_fos_weekly_quest[:silver_e]=20 if @stage > "28-60"
      @_fos_weekly_quest[:gold_e]=10 if @stage > "29-60"
      @_fos_weekly_quest[:red_e]=5 if @stage > "30-60"

      #non used fos:
      #gear has a chance to be factioned: +25% at 4F Towers 40/80/120/160
      #T2 stone chest: +25% at KT 400/450/500/550
      #daily common tokens +40 at 13-40/19-40/25-60
    end

    def get_subscription
      if @subscription
        @_sub_gold_mult=@_sub_xp_mult=@_sub_guild_mult=@_sub_lab_mult=0.1
        @_sub_extra_team_bounty=1
      end
    end

    def get_mult
      @_gold_mult||=1.0+@_vip_gold_mult+@_fos_gold_mult+(@_sub_gold_mult||0)
      @_xp_mult||=1.0+@_vip_xp_mult+@_fos_xp_mult+(@_sub_xp_mult||0)
      @_dust_mult||=1.0+@_fos_dust_mult
      @_lab_mult||=1.0+@_fos_lab_mult+(@_vip_lab_mult||0)+(@_sub_lab_mult||0)
      @_lab_gold_mult||=1.0+(@_vip_lab_gold_mult||0)
      @_guild_mult||=1.0+@_fos_guild_mult+(@_sub_guild_mult||0)
      @_mythic_mult||=1.0+@_fos_mythic_mult
    end

    def get_numbers
      @_solo_bounties||=@_vip_solo_bounty
      @_team_bounties||=1+ (@_vip_extra_team_bounty||0) + (@_sub_extra_team_bounty||0)
      @_nb_arena_fight ||=2+(@_vip_extra_arena_fight||0)
      @_nb_guild_fight ||= 2+(@_vip_extra_guild_fight||0)
    end

    def get_raw_idle_hourly
      # gear_hourly=1.0/(24*4.5*1.9) #1 every 4.5 days at maxed x1.9 fos
      #todo: we may need to mult gear_hourly by 2 to account for stage rewards
      
      # @_Idle_hourly ||={
      #   poe: 22.93, twisted: 1.11630, silver_e: 0.08330,
      #   gold_e: 0.04170, red_e: 0.01564, shards: 1.25, cores: 0.625,
      #   t2: gear_hourly, mythic_gear: gear_hourly,
      #   t3: 1.0/(24*14), #1 every 14 days
      #   t1_gear: t_gear_hourly,
      #   t2_gear: t_gear_hourly,
      #   invigor: 6, dura_fragments: 0.267,
      # } #the last of these items to max out is poe at Chap 33

      @_raw_idle_hourly ||= get_idle(@stage)
      t_gear_hourly=1.0/(24*15*3) #1 every 15 days at maxed x3 fos
      @_raw_idle_hourly[:t1_gear]= @_unlock_tower_kt ? t_gear_hourly : 0
      @_raw_idle_hourly[:t2_gear]= @_unlock_tower_4f ? t_gear_hourly : 0

      # we use gold and xp in K
      unless @afk_xp.nil?
        @_raw_idle_hourly[:xp]=@afk_xp*(60.0/1000)/(1.0+@_vip_xp_mult)
      end
      unless @afk_gold.nil?
        @_raw_idle_hourly[:gold]=@afk_gold*(60.0/1000)/(1.0+@_vip_gold_mult)
      end
      unless @afk_dusk.nil?
        @_raw_idle_hourly[:dust]=@afk_dust/24.0
      end
      @_raw_idle_hourly
    end

    def get_idle_hourly
      get_raw_idle_hourly

      @_idle_hourly=@_raw_idle_hourly.dup
      @_idle_hourly[:mythic_gear] *= @_mythic_mult
      @_idle_hourly[:t2] *= @_mythic_mult
      @_idle_hourly[:t1_gear] *= @_fos_t1_gear_bonus
      @_idle_hourly[:t2_gear] *= @_fos_t2_gear_bonus
      @_idle_hourly[:invigor] *= (1+@_fos_invigor_bonus)
      @_idle_hourly.merge!({
        gold: real_afk_gold*@_gold_mult + @_fos_base_gold/24.0, 
        xp: real_afk_xp*@_xp_mult + @_fos_base_xp/24.0,
        dust: real_afk_dust*@_dust_mult + @_fos_base_dust/24.0
      })
    end

    def raw_idle_hourly
      @_raw_idle_hourly
    end
    def idle_hourly
      @_idle_hourly
    end
    def real_afk_gold
      @_raw_idle_hourly[:gold]
    end
    def real_afk_gold=(v)
      @_raw_idle_hourly[:gold]=v
    end
    def real_afk_xp
      @_raw_idle_hourly[:xp]
    end
    def real_afk_xp=(v)
      @_raw_idle_hourly[:xp]=v
    end
    def real_afk_dust
      @_raw_idle_hourly[:dust]
    end
    def real_afk_dust=(v)
      @_raw_idle_hourly[:dust]=v
    end

  end
  include SetupHelpers

  module Income # Income functions ################
    def idle
      @_idle_hourly.map {|k,v| [k, v*24.0]}.to_h
    end
    def one_ff
      @_idle_hourly.map {|k,v| [k, v*2.0]}.to_h
    end
    def ff
      one_ff.map {|k,v| [k, v*@nb_ff]}.to_h
    end

    def guild
      #mail = half of our top rewards, hence the +0.5
      nb_chests=(@gh_wrizz_chests+@gh_soren_chests*@gh_soren_freq)
      nb_chests_total=@_nb_guild_fight*nb_chests
      dia=@GH_chest_dia*nb_chests_total
      coins=(@_nb_guild_fight+0.5)*nb_chests*@GH_chest_guild*@_guild_mult
      gold=(@_nb_guild_fight+0.5)*(@gh_wrizz_gold+@gh_soren_gold*@gh_soren_freq)

      {guild_coins: coins, dia: dia, gold: gold}
    end

    def oak_inn
      @Oak_amount.map {|k,v| [k, v*@Oak_quantity*@Oak_proba]}.to_h
    end

    def tr
      r=@tr.dup
      add_to_hash(r, @tr_guild)
      mult_hash(r, 2.0/3) #to account for double events
    end

    def cursed_realm
      mult_hash(@cursed_realm, 1.0/7) #open every week
    end

    def quests
      # @Daily_quest ||= {
      #   dust_h: 2, gold_h: 2, gold_hg: 2,
      #   blue_stones: 5, arena_tickets: 2, xp_h: 2, scrolls: 1,
      #   dia: 50+100
      # }
      # @Weekly_quest ||= {
      #   gold_h: 8+8,
      #   twisted: 50, poe: 500,
      #   blue_stones: 60, purple_stones: 10,
      #   silver_e: 20, gold_e: 10, red_e: 5,
      #   dia: 400, scrolls: 3,
      #   dura_tears: 3
      # } #this maxes out at 30-60 with the red emblem rewards

      daily_quest=sum_hash(@Quest_daily, @_fos_daily_quest)
      weekly_quest=sum_hash(@Quest_weekly, @_fos_weekly_quest)
      ressources=(daily_quest.keys+weekly_quest.keys).flatten.sort.uniq
      ressources.map do |r|
        v=(daily_quest[r]||0)+(weekly_quest[r]||0)/7.0
        [r,v]
      end.to_h
    end

    def merchants
      daily=sum_hash(@Merchant_daily, @merchant_daily)
      weekly=sum_hash(@Merchant_weekly, @merchant_weekly)
      monthly=sum_hash(@Merchant_monthly, @merchant_monthly)
      ressources=(daily.keys+weekly.keys+monthly.keys).sort.uniq
      ressources.map do |r|
        v=(daily[r]||0)+(weekly[r]||0)/7.0+(monthly[r]||0)/30.0
        [r,v]
      end.to_h
    end

    def friends
      summons=@friends_nb
      summons+=@friends_mercs*10.0/7 if @_unlock_mercs
      {friend_summons: summons/10.0}
    end

    def get_arena(position)
      case position
      when 1; 80
      when 2; 75
      when 3; 70
      when 4; 68
      when 5; 66
      when 6; 64
      when 7; 62
      when 8; 60
      when 9; 58
      when 10; 56
      when 11; 54
      when 12; 52
      when 13; 50
      when 14; 48
      when 15; 45
      when 16; 42
      when 17; 40
      when 18; 38
      else 36
      end
    end

    def arena
      #todo: add arena tickets usage to the number of arena fights? via tally[:arena_tickets]
      arena_fight = {
        gold: 90*0.495, dust: 10*0.495+500*0.01*0.2,
        blue_stones: 60*0.01*0.2, purple_stones: 10*0.01*0.3,
        dia: (150*0.15+300*0.12+3000*0.03)*0.01
      }

      r=arena_fight.map {|k,v| [k, v*@_nb_arena_fight]}.to_h
      r[:dia] += @arena_daily_dia + @arena_weekly_dia/7.0
      r
    end

    def lct
      {challenger_coins: @lct_coins*24}
    end

    def lc #open every two weeks
      mult_hash(@lc_rewards, 1.0/15)
    end

    def labyrinth(mode: @labyrinth_mode)
      if mode==:auto or mode==nil
        mode = :skip #not open
        mode = :easy if @_unlock_dark_forest
        mode = :hard if @_unlock_labyrinth_hard
        mode = :dismal if @_unlock_labyrinth_dismal
        #or dismal_skip_large
      end
      if @lab_flat_rewards.nil?
        lab_flat_rewards = {gold: @_lab_flat_gold_h * real_afk_gold * @_lab_gold_mult, xp: @_lab_flat_xp_h* real_afk_xp}
        lab_flat_rewards[:gold] *= @_lab_gold_mult
      else
        lab_flat_rewards=@lab_flat_rewards
        #do we also use the lab_gold_mult? It depends if the user supplied
        #the value without vip or not, by default assume these are the full
        #value, vip included
      end
      rewards=case mode
        when :skip; return {} #skip the lab
        when :dismal
          [@Dismal_rewards, @Dismal_stage_chest_rewards, @Dismal_end_rewards, lab_flat_rewards]
        when :dismal_skip_large
          [@Dismal_rewards, @Dismal_stage_chest_skip_rewards, @Dismal_end_rewards, lab_flat_rewards]
        when :hard
          [@Lab_hard_rewards, @Lab_end_rewards, lab_flat_rewards]
        when :easy
          [@Lab_easy_rewards, @Lab_end_rewards, lab_flat_rewards]
        end
      total=sum_hash(*rewards, multiplier: 2.0/3) #for double events
      total[:lab_coins]*=@_lab_mult
      total
    end

    def misty
      r=sum_hash(@Misty_base, @misty)
      r.map {|k,v| [k, v/30.0]}.to_h
    end

    def regal
      @noble_regal.map {|k,v| [k,v*1.0/@Noble_regal_days]}.to_h
    end

    def twisted_bounties
      @noble_twisted.map {|k,v| [k,v*1.0/@Noble_twisted_days]}.to_h
    end

    def coe
      #Choices:
      @noble_coe.map {|k,v| [k,v*1.0/@Noble_coe_days]}.to_h
    end

    def hero_trial
      @Hero_trial_rewards.map do |k,v|
        [k, v*@Monthly_hero_trial/30.0]
      end.to_h
    end
    def guild_hero_trial
      @hero_trial_guild_rewards.map do |k,v|
        [k, v*@Monthly_hero_trial/30.0]
      end.to_h
    end

    def bounties
      if @board_level < 8
        #todo: find the probas in the game files
        warn "[Warning] Board level #{@board_level} not implemented, skipping"
        return {}
      end
      types=%i(dust gold dia blue_stones)

      solo_bounty={dust: [150, 500, 800],
                   gold: [170, 245, 320],
                   dia: [60,100,150],
                   blue_stones: [15,25,40]}
      team_bounty={dust: [160, 500, 800],
                   gold: [249, 249, 249],
                   dia: [120,200,300],
                   blue_stones: [30,50,80]}
      type_proba={dust: 3.0/8, gold: 3.0/8, blue_stones: 1.0/8, dia: 1.0/8}
      tier_proba=[0.9, 0.08, 0.02]

      solo_quest=types.map do |type|
        values=solo_bounty[type]
        sum=values.each_with_index.reduce(0) {|sum, cur| sum+cur[0]*tier_proba[cur[1]]}
        v=type_proba[type]*sum
        [type,v]
      end.to_h

      team_quest=types.map do |type|
        values=team_bounty[type]
        sum=values.each_with_index.reduce(0) {|sum, cur| sum+cur[0]*tier_proba[cur[1]]}
        v=type_proba[type]*sum
        [type,v]
      end.to_h

      team_quests=team_quest.map do |k,v|
        [k, v*@_team_bounties]
      end.to_h

      case @_solo_bounties #lets look at the optimised strat
        #cf board.rb to compute the values
      when 8,9,10;
        single_event= case @_solo_bounties
        when 8; { gold: 152, blue_stones: 24, dust: 810, dia: 50}
        when 9; { gold: 152, blue_stones: 26, dust: 929, dia: 68}
        when 10; { gold: 152, blue_stones: 28, dust: 1049, dia: 89}
        end
        double_event= case @_solo_bounties
        when 8; { gold: 31, blue_stones: 39, dust: 1875, dia: 260}
        when 9; { gold: 31, blue_stones: 43, dust: 2114, dia: 324}
        when 10; { gold: 152, blue_stones: 47, dust: 2354, dia: 391}
        end
        solo_quests=types.map do |type|
          v=single_event[type]*2.0/3+double_event[type]*1.0/3
          [type,v]
        end.to_h
      else
        warn "[Warning] Optimized bounty strat not implemented for #{@_solo_bounties} bounties"
        solo_quests=solo_quest.map do |k,v|
          [k, v*@_solo_bounties*4.0/3] #for double events
        end.to_h
      end

      types.map do |type|
        v=solo_quests[type]+team_quests[type]
        [type,v]
      end.to_h
    end

    def vow
      @Vows={
        demonic: {
          purple_chests: 4,
          shards: 100, cores: 50,
          silver_e: 20, gold_e: 20, red_e: 10,
          poe: 1000,
          scrolls: 20
        },
        gold_rush: {
          shards: 120, cores: 50,
          silver_e: 30, gold_e: 20, red_e: 10,
          poe: 3000,
          stargazers: 10
        },
        frontier: {
          purple_chests: 5,
          shards: 100, cores: 50,
          silver_e: 20, gold_e: 20, red_e: 10,
          poe: 2000,
          stargazers: 10
        },
        setting_sun: {
          purple_chests: 2,
          shards: 100, cores: 50,
          silver_e: 40, gold_e: 20, red_e: 10,
          stargazers: 10
        },
      }.merge(@Vows||{})

      keys=@Vows.values.map {|i| i.keys}.flatten.uniq
      if @_average_vow_rewards.nil?
        @_average_vow_rewards={}
        keys.each do |k|
          @_average_vow_rewards[k]= (@Vows.values.map {|i| i[k]||0}).sum / (@Vows.keys.length*1.0)
        end

        #purple chest: 2x8h dust or 2x8h xp or 8x8h gold
        purple_chests=@_average_vow_rewards.delete(:purple_chests)
        @_average_vow_rewards[:dust_h]=purple_chests*16.0

        # p @_average_vow_rewards
      end

      @_average_vow_rewards.map do |k,v|
        [k, v*@Monthly_vows/30.0]
      end.to_h
    end
  end
  include Income

  module Towers
    #return the average floor reward
    def tower_kt_floor(level=@tower_kt)
      # >560: 5650 gold + 160 dia +150 dust + 30 purple every *10
      #       5650 gold + 80 dia +150 dust + 30 blue every else
      #           (except 160 dia every *5)
      gold=1; dia=20; dust=10; blue=5; purple=10
      ( gold=12; dia=30 ) if level>40
      ( gold=17; dust=15 ) if level>50
      ( gold=30; blue=10 ) if level>60
      ( gold=49; dust=20 ) if level>75
      ( gold=55; dia=40 ) if level>80
      ( gold=72; purple=20; dust=25 ) if level>100
      ( gold=200; dia=50; blue=15 ) if level>120
      ( gold=248; dust=30 ) if level>125
      ( gold=461; dust=35 ) if level>150
      ( gold=512; dia=60 ) if level>160
      ( gold=578; dust=40 ) if level>175
      ( gold=591; blue=20 ) if level>180
      ( gold=667; dia=70; dust=45; purple=30 ) if level>200 #purple max out at 210
      ( gold=760; dust=50 ) if level>225
      ( gold=826; dia=80; dust=50; blue=25 ) if level>240 #dia max out at 241
      ( gold=875; dust=55 ) if level>250
      ( gold=3475; dust=60; blue=30 ) if level>275 #blue max out at 276
      ( gold=4180; dust=65 ) if level>300
      ( gold=4560; dust=70 ) if level>325
      ( gold=4900; dust=75 ) if level>350
      ( gold=5050; dust=80 ) if level>375
      ( gold=5200; dust=85 ) if level>400
      ( gold=5500; dust=95 ) if level>450
      ( gold=5580; dust=100 ) if level>475
      ( gold=5500; dust=150 ) if level>500 #dust max out at 501
      ( gold=5650 ) if level>560 #gold max out at 561
      return {gold: gold, dia: 1.2*dia, dust: dust, purple_stones: purple/10.0, blue_stones: blue*9/10.0}
    end
    def tower_kt_quest(level=@tower_kt)
      # quest: 400 dia every x20, 
      #        250-500: 1000 shards every 50
      #        550+: 500 cores every x50
      # Rem: stages quest: 400 shards for {22-35}-30, 200 cores afterwards
      dia=100
      dia=200 if level>=60
      dia=300 if level>=110
      dia=400 if level>=160
      kt_quest={dia: dia/10}
      kt_quest={dia: dia/10, shards: 1000/50} if level >= 250
      kt_quest={dia: dia/10, cores: 500/50} if level>=550
      kt_quest
    end
    def tower_kt_avg(level=@tower_kt)
      return sum_hash(tower_kt_floor(level), tower_kt_quest(level))
    end
    def tower_kt_ressources(level=@tower_kt)
      tower_kt_avg(level)
    end

    def tower_4f_floor(level=@tower_4f)
      # for 4f towers, between 240 and 360:
      # between 150-240: *5 4000 dust+5 stargaze, *0 90 purple stones or 15 gold_e
      # above 240: *5 4000 dust+5 stargaze or red_e, *0 90 purple stones or 15 gold_e
      #   funnily 361-370 is a copy of 351-360 but after they alternate
      #   again
      # above 450?: *5 4000 dust+5 stargaze, *0 10 red_e or 10 faction emblems
      #   funny: 5 sg+5000K gold at 470...
      # see https://afk-arena.fandom.com/wiki/Towers_of_Esperia_Rewards

      gold=200
      gold=240 if level>=40
      gold=300 if level>=80
      gold=400 if level>=90
      gold=500 if level>=110
      gold=600 if level>=120
      # before 150 the rewards change too much
      t4f_floor={gold: 4*gold/10}
      t4f_floor={dust: 4000/10, stargazers: 5.0/10, purple_stones: 90.0/20, gold_e: 15.0/20, gold: 4*gold/10} if level>=150
      t4f_floor={dust: 4000/20, stargazers: 5.0/20, red_e: 10.0/20, purple_stones: 90.0/20, gold_e: 15.0/20, gold: 4*gold/10} if level>=240
      t4f_floor={dust: 4000/10, stargazers: 5.0/10, red_e: 10.0/20, faction_emblems: 10.0/20, gold: 4*gold/10} if level>=360
      t4f_floor
    end
    def tower_4f_quest(level=@tower_4f)
      # quests: above 220: 40 red_e for every 20 floors x4, above 460: 600 poe
      t4f_quest={}
      t4f_quest={red_e: 40/20} if level>=220
      t4f_quest={poe: 600/20} if level >=460
      t4f_quest
    end
    #return the avg ressources from climbing one level in *all* the 4f towers
    def tower_4f_avg(level=@tower_4f)
      if level.is_a?(Enumerable)
        min=level.min
        sum_hash(*level.map {|lvl| tower_4f_floor(lvl)}, tower_4f_quest(min))
      else #integer
        return tower_4f_avg([level]*4)
      end
    end

    def tower_god_floor(level=@tower_god)
      #every *5: 4000 dust + 5 stargazer
      #every *10: 10 faction_emblem or 15 gold_e
      #  this becom 10 faction_emblem or 10 red_e at??
      god_floor= { dust: 4000/10, stargazers: 5.0/10, faction_emblems: 10.0/20, gold_e: 15.0/20, gold: 4*600/10 } #start at level 1
      god_floor= { dust: 4000/10, stargazers: 5.0/10, faction_emblems: 10.0/20, red_e: 10.0/20, gold: 4*600/10 } if level >=200
      return god_floor
    end
    def tower_god_quest(level=@tower_god)
      # celhypo quests: 400 cores every x20
      return {cores: 400/20}
    end
    def tower_god_avg(level=@tower_god)
      if level.is_a?(Enumerable)
        min=level.min
        sum_hash(*level.map {|lvl| tower_god_floor(lvl)}, tower_god_quest(min))
      else #integer
        return tower_god_avg([level]*2)
      end
    end

    #return tower progression from the rate of level up
    #heuristic: one level=one floor at single, two floors at multis
    def set_tower_progression_from_levelup(level_up=@monthly_levelup)
      #Multis: 700 KT, 450 4F, 350 celestial
      level_up=[*level_up]
      avg_level_up=level_up.sum*1.0/level_up.length
      factor_4f=factor_kt=factor_god=1
      factor_kt=2 if [*@tower_kt].min >= 600
      factor_kt=0 unless @_unlock_tower_kt
      factor_4f=2 if [*@tower_4f].min >= 450
      factor_4f=0 unless @_unlock_tower_4f
      factor_god=2 if [*@tower_god].min >= 350
      factor_god=0 unless @_unlock_tower_god
      @tower_kt_progression ||= avg_level_up*factor_kt
      @tower_4f_progression ||= avg_level_up*factor_4f
      @tower_god_progression ||= avg_level_up*factor_god
    end

    def towers_ressources
      return {} unless @_unlock_tower_kt
      @_tower_kt_avg ||= @_unlock_tower_kt ? tower_kt_avg(@tower_kt) : {}
      @_tower_4f_avg ||= @_unlock_tower_4f ? tower_4f_avg(@tower_4f) : {}
      @_tower_god_avg ||= @_unlock_tower_god ? tower_god_avg(@tower_god) : {}
      return {
        towers_kt: mult_hash(@_tower_kt_avg, @tower_kt_progression/30.0),
        towers_4f: mult_hash(@_tower_4f_avg, @tower_4f_progression/30.0),
        towers_god: mult_hash(@_tower_god_avg, @tower_god_progression/30.0),
      }
    end
  end
  include Towers

  module Store
    #returns item, cost, the item value, and the actual buyable quantity
    def get_item_value(item, shop)
      qty=1
      if item.is_a?(Hash)
        item, qty=item.to_a.first
      end

      shop_item=shop[item].dup
      if shop_item.is_a?(Hash)
        cost=shop_item.delete(:cost)
        max=shop_item.delete(:max)
        if qty==:max
          max ? qty=max : qty=1
        end
        value=shop_item
      else
        unless shop_item
          warn "[Warning!] Shop item `#{item}` not found"
          return[item, 0, {}, 1]
        end
        cost=shop_item
        value={item => 1}
        qty=1 if qty==:max
      end
      return [item, cost, value, qty]
    end

    def buy_in_store(shop, *secondary, primary: [], filler: nil, total: nil)
      r={ cost: 0 }
      o={}

      do_buy = lambda do |item, cost, value, qty: 1|
        s={cost: -cost}
        add_to_hash(r, s.merge(value), multiplier: qty)
        o[item]||={}
        o[item][:cost]=cost
        o[item][:qty]||=0
        o[item][:qty]+=qty
      end

      if total==nil
        primary=secondary
        secondary=[]
        total=0
      end

      primary.each do |item|
        item, cost, value, qty=get_item_value(item, shop)
        do_buy[item, cost, value, qty: qty]
        total -= qty*cost
      end

      secondary.each do |item|
        item, cost, value, qty=get_item_value(item, shop)
        qty=[(total/cost).floor(), qty].min
        qty=[qty, 0].max
        if qty>0
          do_buy[item, cost, value, qty: qty]
          total -= qty*cost
        end
      end

      if filler and total > 0.0
        item, cost, value, _qty =get_item_value(filler, shop)
        qty=total*1.0/cost
        qty=[qty, 0].max
        do_buy[item, cost, value, qty: qty] if qty>0
      end

      # ressources exchanged, list of items bought
      return [r, o]
    end

    def handle_buys(buys, shop, total)
      primary, secondary, extra=split_array(buys)
      filler = extra && extra.first
      buy_in_store(shop, *secondary, primary: primary, filler: filler, total: total)
    end

    def buy_summary(buy)
      s=""
      o=[]
      total_cost=0
      buy.each do |item, values|
        qty=values[:qty]
        cost=values[:cost]
        total_cost+=cost*qty
        o<<=" #{round(qty*cost)} (#{(qty==1 || qty==1.0) ? '': "#{round(qty)} x "}#{item})"
      end
      s << "buy #{round(total_cost)} [#{o.join(' + ')}]" unless o.empty?
      s
    end

    def spending(cost, ressources=tally)
      #in one unit of time, how much ressource can we buy?
      #@return the amount we can buy which each needed ressources, the
      #minimal amount (=effective amount unless we have stocks), the
      #remaining ressources by unit of time.
      res_buy=cost.map do |k,v|
        res=ressources[k]||0
        [k, res*1.0/v]
      end.to_h
      min_buy=res_buy.values.min #so time=1/min_buy
      min_buy=[min_buy, 0].max
      remain=cost.map do |k,v|
        [k, (ressources[k]||0)-v*min_buy]
      end.to_h
      return [res_buy, min_buy, remain]
    end
  end
  include Store

  module Exchange
    def exchange_ff
      @FF_cost=[0, 50, 80, 100, 100, 200, 300, 400]
      nb_ff=@nb_ff
      if nb_ff > @FF_cost.length
        nb_ff=@FF_cost.length
        warn "[Warning] FF cost not implemented for #{@nb_ff} FF"
      end
      full_cost=(0...nb_ff).reduce(0) {|sum, i| sum+@FF_cost[i]}
      {dia: -full_cost}
    end

    def exchange_shop
      shop_refreshes=@shop_refreshes

      @Shop_refresh_cost= [100, 100, 200, 200]
      if @shop_refreshes > @Shop_refresh_cost.length
        warn "[Warning] Extra cost of shop refreshes not implemented when shop refreshes = #{@shop_refreshes}"
        shop_refreshes=@Shop_refresh_cost.length
      end
      refresh_cost=(0...shop_refreshes).reduce(0) {|sum, i| sum+@Shop_refresh_cost[i]}

      nb_shop=1+shop_refreshes
      shop={dia: -refresh_cost, gold: 0}

      @shop_items.each do |item|
        if item.is_a?(Hash) # {item: qty}
          item, qty=item.to_a.first
        else
          qty=nb_shop
        end
        value=@Shop[item]
        proba=value.delete(:proba) || 1
        max=value.delete(:max) || 1000
        appearances=nb_shop*proba
        buy=[qty, max, appearances].min
        add_to_hash(shop, value, multiplier: buy)
      end

      shop
    end

    def exchange_coins
      @__coin_summary=""
      total=tally

      %i(hero lab guild challenger).each do |i|
        @ressources[:"#{i}_store"] ||={}
        coin_name=:"#{i}_coins"
        _total=(total[coin_name]||0)*30
        r,bought=handle_buys(instance_variable_get(:"@store_#{i}_items"), instance_variable_get(:"@Store#{i.to_s.capitalize}"), _total)
        cost=r.delete(:cost)
        r[coin_name]=cost
        b=buy_summary(bought)
        @__coin_summary << "#{coin_name}: #{round(_total)}"
        @__coin_summary << " => #{b}" unless b.empty?
        @__coin_summary << "\n"
        add_to_hash(@ressources[:"#{i}_store"], r.map {|k,v| [k, v/30.0]}.to_h)
      end
    end

    def sell_dura
      total_dura=tally[:dura_fragments]
      dura_sold=(@dura_nb_selling/@Dura_nb)*total_dura
      {dura_fragments: -dura_sold, gold: dura_sold * 50}
    end

    def summonings
      @ressources[:stargazing]={
        dia: -500.0*@monthly_stargazing/30,
        stargazers: @monthly_stargazing/30.0
      }
      @ressources[:wishlist]={
        dia: -270.0*@monthly_tavern/30,
        scrolls: @monthly_tavern/30.0
      }
      @ressources[:hcp]={
        dia: -300.0*@monthly_hcp/30,
        hcp: @monthly_hcp/30.0
      }
      @ressources.merge!(handle_summons(tally)) #get extra ressources from summons
    end

    def handle_summons(total)
      hero_chest = total[:hero_choice_chest]||0
      purple_summons=purple_stone(total[:purple_stones]||0)
      blue_summons=blue_stone(total[:blue_stones]||0)
      friend_summons=friend_summon(total[:friend_summons]||0)
      wl_summons=tavern_summon((total[:scrolls]||0)+(total[:wishlist]||0))
      hcp_summons=choice_summon(total[:hcp]||0)
      stargaze_summons=stargaze(total[:stargazers]||0)

      r={}
      r[:hero_chest]={choice_atier: hero_chest}
      r[:stones]=tally({purple: purple_summons, blue: blue_summons})
      r[:tavern]=tally({friends: friend_summons, wl: wl_summons, hcp: hcp_summons})
      r[:stargaze]=stargaze_summons
      r
    end
  end
  include Exchange

  module Tally
    def tally(ressources=@ressources, multiplier: 1, mode: 0)
      r={}
      keys=ressources.values.map {|v| v.keys}.flatten.sort.uniq
      keys.each do |type|
        sum=0
        ressources.each do |k,v|
          if v.key?(type)
            value=v[type]
            value=0 if mode*value<0 #keep only pos entries when mode=1, only neg entries when mode=-1
            sum+=value * multiplier
          end
        end
        r[type]=sum
      end
      r
    end

    def timeframe(r=@ressources,multiplier) #mutliply the ressources according to the time frame
      r.map do |k,v|
        [k, v.map do |k2, v2|
          [k2, v2*multiplier]
        end.to_h]
      end.to_h
    end

    def get_total(r=@ressources, **kw)
      s=tally(r, **kw)
      s=convert_ressources_h(s)
      unless (s.keys & %i(god choice_god random_god fodder choice_fodder random_fodder atier random_atier wishlist_atier choice_atier)).empty?
        s[:god]||=0
        s[:god]+=(s[:choice_god]||0)+(s[:random_god]||0)
        s[:fodder]||=0
        s[:fodder]+=(s[:choice_fodder]||0)+(s[:random_fodder]||0)
        s[:atier]||=0
        s[:atier]+=(s[:random_atier]||0)+(s[:wishlist_atier]||0)+(s[:choice_atier]||0)
      end
      s
    end
    def clean_total
      total=get_total
      total[:gold]=total.delete(:total_gold)
      total[:xp]=total.delete(:total_xp)
      total[:dust]=total.delete(:total_dust)
      total
    end

    def total_gold(r)
      gold_h=r.fetch(:gold_h,0)
      gold_hg=r.fetch(:gold_hg,0) #this is affected only by vip
      return r.fetch(:gold,0)+gold_h*real_afk_gold+gold_hg*real_afk_gold*(1+@_vip_gold_mult)
    end
    def total_xp(r)
      xp_h=r.fetch(:xp_h,0)
      xp_hg=r.fetch(:xp_hg,0) #this is affected only by vip
      return r.fetch(:xp,0)+xp_h*real_afk_xp+xp_hg*real_afk_xp*(1+@_vip_xp_mult)
    end
    def total_dust(r)
      dust_h=r.fetch(:dust_h,0)
      dust_hg=r.fetch(:dust_hg,0) #this is affected only by vip wich don't change dust
      return r.fetch(:dust,0)+dust_h*real_afk_dust+dust_hg*real_afk_dust*1
    end
    def convert_ressources_h(r)
      r[:total_gold]=total_gold(r)
      r[:total_xp]=total_xp(r)
      r[:total_dust]=total_dust(r)
      r
    end
  end
  include Tally

  module Ordering
    def get_ressource_order
      ressources=tally.keys
      order={
        base: %i(dia gold gold_h gold_hg total_gold xp xp_h xp_hg total_xp dust dust_h dust_hg total_dust),
        upgrades: %i(silver_e gold_e red_e faction_emblems poe twisted shards cores),
        gear: %i(t2 t3 mythic_gear t1_gear t2_gear),
        coins: %i(guild_coins lab_coins hero_coins challenger_coins),
        summons: %i(purple_stones blue_stones scrolls friend_summons hcp hero_choice_chest stargazers),
        hero_summons: %i(fodder random_fodder atier choice_atier wishlist_atier random_atier god choice_god random_god),
        dimensional: %i(garrison_stone dim_points dim_gear dim_emblems),
        misc: %i(dura_fragments class_fragments dura_tears invigor arena_tickets),
      }
      ressources2=order.values.flatten.sort.uniq
      missing=ressources-ressources2
      order[:extra]=missing unless missing.empty?
      @_order=order
    end

    def economy
      {income: %i(idle ff board guild oak_inn tr quests merchants friends arena lct lc lab misty regal tr_bounties coe hero_trial guild_hero_trial vow monthly_card deluxe_monthly_card),
       exchange: %i(ff_cost shop dura_fragments_sell),
       summons: %i(wishlist hcp stargazing hero_chest stones tavern stargaze),
       stores: %i(hero_store guild_store lab_store challenger_store),
       towers: %i(towers_kt towers_4f towers_god),
       levelup: %i(levelup),
      }
    end
  end
  include Ordering

  module Summary
    def make_h1(t)
      "=============== #{t.capitalize} ===============\n"
    end
    def h1(t)
      puts make_h1(t)
    end
    def make_h2(t)
      "--------------- #{t.capitalize} ---------------\n"
    end
    def h2(t)
      puts make_h2(t)
    end
    def make_h3(t)
      "***** #{t.capitalize} *****\n"
    end
    def h3(t)
      puts make_h3(t)
    end

    def make_summary(ressources, headings: true, total: false, plusminus: false, percent: false)
      if total
        total=get_total(ressources)
        pos_total=get_total(ressources, mode: 1)
      end
      summary=""
      @_order.each do |header, keys|
        s=""
        keys.each do |type|
          #next if %i(total_gold total_xp total_dust).include?(type)
          sum=pos_sum=neg_sum=0
          o=[]
          ressources.each do |k,v|
            if v.key?(type)
              value=v[type]
              sum+=value
              pos_sum+=value if value>0
              neg_sum+=value if value<0
            end
          end #we need to tally the sums first
          ressources.each do |k,v|
            if v.key?(type)
              value=v[type]
              per=0
              oo=""
              if value>0
                per=value/pos_sum
                oo << (o.empty? ? "" : " + ")
                oo<<"#{round(value)}"
              elsif value<0
                per=value/neg_sum
                oo << (o.empty? ? "" : " - ")
                oo<<"#{round(value.abs)}"
              end
              unless value == 0 or value == 0.0
                oo << (percent ? " (#{k} #{percent(per)})" : " (#{k})" )
                o.push(oo)
              end
            end
          end
          if total
            if type==:choice_god and total[:god]
              s+="-> God: #{round(total[:god])}\n"
            end
            if type==:choice_atier and total[:atier]
              s+="-> Atier: #{round(total[:atier])}\n"
            end
            #fodder == random_fodder
          end

          unless o.empty?
            s << "#{type}: #{round(sum)}"
            plusminuscondition=(plusminus and pos_sum !=0 and pos_sum != 0.0 and neg_sum !=0 and neg_sum != 0)
            if plusminuscondition
              s+="=#{round(pos_sum)}-#{round(-neg_sum)}"
            end
            s << " [#{o.join}]"

            if percent and type==:gold and total and total[:total_gold]
              s += " {#{round(pos_sum)}K gold=#{percent(pos_sum*1.0/pos_total[:total_gold])}}"
            elsif %i(gold_h gold_hg).include?(type)
              converted=total_gold(type => sum)
              if total and total[:total_gold] and percent
                s += " {#{round(converted)}K gold=#{percent(converted*1.0/pos_total[:total_gold])}}"
              else
                s += " {#{round(converted)}K gold}"
              end
            end

            if percent and type==:xp and total and total[:total_xp]
              s += " {#{round(pos_sum)}K xp=#{percent(pos_sum*1.0/pos_total[:total_xp])}}"
            elsif %i(xp_h xp_hg).include?(type)
              converted=total_xp(type => sum)
              if total and total[:total_xp] and percent
                s += " {#{round(converted)}K xp=#{percent(converted*1.0/pos_total[:total_xp])}}"
              else
                s += " {#{round(converted)}K xp}"
              end
            end

            if percent and type==:dust and total and total[:total_dust]
              s += " {#{round(pos_sum)}K dust=#{percent(pos_sum*1.0/pos_total[:total_dust])}}"
            elsif %i(dust_h dust_hg).include?(type)
              converted=total_dust(type => sum)
              if total and total[:total_dust] and percent
                s += " {#{round(converted)}K dust=#{percent(converted*1.0/pos_total[:total_dust])}}"
              else
                s += " {#{round(converted)}K dust}"
              end
            end

            s << "\n"
          end

          if total
            s<< "\n" if type==:dia
            if type==:gold_hg and total[:total_gold]
              s+="-> Total gold: #{round(total[:total_gold])}K\n\n"
            end
            if type==:xp_hg and total[:total_xp]
              s+="-> Total xp: #{round(total[:total_xp])}K\n\n"
            end
            if type==:dust_hg and total[:total_dust]
              s+="-> Total dust: #{round(total[:total_dust])}\n"
            end
          end

        end

        unless s.empty?
          s=make_h3(header)+s if headings
          yield(s,header) if block_given?
          s+="\n" if headings
          summary+=s
        end
      end
      summary += "\n" unless headings or summary.empty?
      summary
    end

    def do_summary(title, r, total_value: false, multiplier: 1, **kw)
      if multiplier != 1
        r=timeframe(r, multiplier)
      end

      summary=make_summary(r, **kw)
      unless summary.empty?
        summary=make_h1(title)+summary

        if total_value
          summary+="=> Total value: #{show_dia_value(tally(r), skip_null: true)}\n\n"
        end
        puts summary
      end
      r
    end

    #not used anymore
    def do_total_summary(total, headings: true, title: "Total")
      make_h2(title)
      @_order.each do |summary, keys|
        s=""
        keys.each do |type|
          next unless %i(total_gold total_xp total_dust god fodder atier).include?(type)
          sum=total[type]||0
          s+="#{type}: #{round(sum)}\n" unless sum==0 or sum == 0.0
        end
        unless s.empty?
          make_h3(summary) if headings
          yield(summary) if block_given?
          puts s
          puts if headings
        end
      end
      puts unless headings
      total
    end

    def ff_summary
      h1 "Fast Forward Value"
      puts show_dia_value(one_ff, skip_null: true)
      puts
    end

    def level_cost_summary(n=1, daily: false)
      cost=level_up_cost(n)
      gold=cost[:gold]
      xp=cost[:xp]
      dust=cost[:dust]
      gold_h=gold/real_afk_gold
      xp_h=xp/real_afk_xp
      dust_h=dust/real_afk_dust
      gold_v=dia_value({gold: gold})
      goldh_v=dia_value({gold_h: gold_h})
      xp_v=dia_value({xp: xp})
      dust_v=dia_value({dust: dust})
      total=gold_v+xp_v+dust_v
      totalbis=goldh_v+xp_v+dust_v
      o="Level cost: #{round(total)} dia / #{round(totalbis)} dia [#{round(gold)} gold=#{round(gold_v)} dia / #{round(gold_h)} gold_h=#{round(goldh_v)} dia + #{round(xp)} xp=#{round(xp_h)} xp_h=#{round(xp_v)} dia + #{round(dust)} dust=#{round(dust_h)} dust_h=#{round(dust_v)} dia"
      o << " {#{round(gold_h/24.0)} x 24h gold + #{round(xp_h/24.0)} x 24h xp + #{round(dust_h/24.0)} x 24h dust}" if daily
      o
    end

    def cost_summary(cost, total)
      res_buy, buy, remain=spending(cost, total)
      o_remain=""

      if res_buy.keys.length>1
        o_remain+=" {#{res_buy.map { |k,v| "#{k}: #{round(1/v)} days"}.join(', ')}}"
      end

      monthly_remain=remain.select {|k,v| v !=0 and v != 0.0}.map {|k,v| [k, v*30]}.to_h
      o_remain += " [monthly remains: #{monthly_remain.map {|k,v| "#{round(v)} #{k}"}.join(" + ")}]" unless monthly_remain == {}

      return "#{round(1.0/buy)} days (#{round(buy*30.0)} by month)#{o_remain}"
    end

    def previsions_summary
      total=clean_total

      h1 "30 days previsions summary"
      #puts "Extra rc levels: #{round((ascended+ascended_god)*5)}"
      nb_ascended=0

      ressources_cost.each do |k,v|

        o=cost_summary(v, total)
        puts "#{k}: #{o}"

        if ["Ascended challenger celo", "Ascended 4F", "Ascended god"].include?(k.to_s)
          _res_buy, buy, _remain=spending(v, total)
          nb_ascended += buy
        end
        puts "-> #{level_cost_summary}" if k.to_s=="level"

        puts if ["level", "SI+30", "e30 to e65", "9F (with cards)", "Ascended challenger celo"].include?(k.to_s)
      end
      increase_rc_level=5 #one ascended = 5 levels
      puts "Max rc level+1: #{round(1.0/(increase_rc_level*nb_ascended))} days (#{round(increase_rc_level*nb_ascended*30)} by month)"
      puts
    end

    def show_summary(daily: false, monthly: true)
      ff_summary
      economy.each do |k,v|
        r=@ressources.slice(*v)
        next if r.empty?
        title=k
        case k
        when :summons
          title="Summons (#{round(@monthly_stargazing)} sg + #{round(@monthly_hcp)} hcp + #{round(@monthly_tavern)} wl)"
        when :levelup
          title="Level up (#{[*@monthly_levelup].map {|i| round(i)}.join(', ')})"
        when :towers
          title="Towers (#{round(@tower_kt_progression)} kt, #{round(@tower_4f_progression)} 4f, #{round(@tower_god_progression)} god)"
        end
        case k
        when :income
          do_summary(title,r, total: true, total_value: true)
        else
          do_summary(title,r, headings: false)
          if k==:stores
            h2("30 days coin summary")
            puts @__coin_summary 
            puts
          end
        end
      end
      do_summary("Full daily ressources", @ressources, total: true, plusminus: true, percent: true) if monthly
      do_summary("Full monthly ressources", @ressources, total: true, multiplier: 30, plusminus: true, percent: true) if monthly
      previsions_summary
    end

    def summary(*a, **kw)
      show_summary(*a, **kw)
    end

    def show_variables(verbose: false)
      blacklist=%i(@ressources @Vows @_order)
      vars=instance_variables-blacklist
      vars=vars.reject {|i| i.to_s.start_with?("@__")}
      internal_vars=vars.select do |i|
        i.to_s.start_with?("@_")
      end
      fixed_vars=vars.select do |i|
        ('A'..'Z').include?(i.to_s[1])
      end
      setup_vars=vars-internal_vars-fixed_vars

      show_vars=lambda do |keys|
        keys.map do |key|
          "#{key}: #{instance_variable_get(key)}"
        end
      end

      if verbose
        h1 "Variables"
        h2 "Setup vars:"
        puts show_vars[setup_vars].join("\n")
        puts
        h2 "Fixed vars"
        puts show_vars[fixed_vars].join("\n")
        puts
        h2 "Internal vars"
        puts show_vars[internal_vars].join("\n")
        puts
      else
        h1 "Variables"
        puts show_vars[setup_vars].join("\n")
      end
    end
  end
  include Summary

  module Utilities
    def level_cost(n, level: 1, stage: "37-01")
      s=self.new do
        @hero_level=level
        @stage=stage
      end
      puts s.level_cost_summary(n, daily: true)
    end
  end
  extend Utilities
end

if __FILE__ == $0
  if ARGV.first == "--debug"
    require "pry"
    binding.pry
    #Simulator.level_cost(500, stage: "38-01")
  else
    #Simulator.new.one_level_up_cost(900)
    s=Simulator.new do #example run
      # @monthly_stargazing=50
    end
    s.summary
    # s.show_variables
    # s.show_variables(verbose: true)
    #p s.items_value
  end
end
