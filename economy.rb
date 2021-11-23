#!/usr/bin/env ruby
#TODO: towers, more events?
#Get leveling up ressources from csv file

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

  def setup_vars #assume an f2p vip 10 hero level 350 player at chap 37 with max fos by default
    @stage ||= "37-01"

    #at rc 350: the amount required to level up (xp and gold are in K)
    @level_gold ||= 18132.62
    @level_xp ||= 130100
    @level_dust ||= 24703

    @nb_ff ||=6 #ff by day
    @vip ||=10 #vip level
    @subscription ||=true if @subscription.nil?
    @player_level ||=180 #for fos, 180 is max fos for gold/xp/dust mult
    @board_level ||=8

    # Towers
    @tower_kt ||= 550 #max fos at 350 for t1_gear, 550 max fos for T2 chests
    @tower_4f ||= 280 #max fos at 280 for t2_gear
    @tower_god ||= 300 #max fos at 300 for invigor

    # Daily shopping
    @shop_items ||= %i(dust purple_stones poe shards) #+[{dust_h: 1}]
    @shop_refreshes ||= 2

    # Monthly store buys
    # [items we always buy, ..., nil, items we buy if we have coins remaining, nil, filler item]
    @buy_hero ||=[:garrison]
    @buy_guild ||= [:garrison, :dim_exchange, :t3, :t3, nil, nil, :dim_gear]
    @buy_lab ||=[:garrison, :dim_exchange, nil, :dim_emblems]
    @buy_challenger ||= []

    # Summonings
    @monthly_stargazing ||= 0 #number of stargazing done in a month
    @monthly_tavern ||= 0 #number of tavern pulls
    @monthly_hcp ||= 0 #number of hcp pulls
    # Friends and weekly mercs
    @friends_mercs ||= 5
    @friends_nb ||= 20

    #GH
    @gh_team_wrizz_gold ||=1080
    @gh_team_soren_gold ||=@gh_team_wrizz_gold
    @gh_team_wrizz_coin ||=1158
    @gh_team_soren_coin ||=@gh_team_wrizz_coin

    @gh_wrizz_chests ||= 23
    @gh_soren_chests ||= @gh_wrizz_chests
    @gh_wrizz_gold ||= get_guild_gold(@gh_wrizz_chests)
    @gh_soren_gold ||= get_guild_gold(@gh_soren_chests)
    @gh_soren_freq ||= 0.66 #round(5.0/7.0) =0.71

    #twisted realm
    @tr_twisted ||=250
    @tr_poe ||=1000

    # arena
    @arena_daily_dia ||= get_arena(5) #rank 5 in arena
    @arena_weekly_dia ||=@arena_daily_dia * 10
    @lct_coins ||=380 #top 20. Hourly coins: 400-rank

    #misty valley
    @misty ||= get_misty

    #noble society
    @noble_regal ||= regal_choice(paid: false)
    @noble_twisted ||= twisted_bounties_choice(:xp)
    @noble_coe ||= coe_choice(:dust)

    #average guild hera trial rewards
    @hero_trial_guild_rewards ||={
      dia: 200+100+200,
      guild_coins: 1000 #assume top 500
    }

    #misc
    @dura_nb_selling ||=0
  end

  def setup_constants
    @Cost={
      level: {gold: @level_gold, xp: @level_xp, dust: @level_dust},
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
    }

    @Shop_emblem_discout ||=0.7
    @Shop ||={
      xp_h: { xp_h: 24, dia: -192, proba: 0.25},
      dust_h: {dust_h: 24, dia: -300},
      dust: {dust: 500, gold: -2250},
      purple_stones: { purple_stones: 5, dia: -90, proba: 0.25 },
      poe: { poe: 250, gold: -1125 },
      shards: { shards: 20, gold: -2000, max: 3 },
      cores: { cores: 10, dia: -200, max: 3 },
      gold_e: { gold_e: 20, gold: 15600*@Shop_emblem_discout, proba: 0.25 },
      silver_e: { silver_e: 30, gold: 14400*@Shop_emblem_discout, proba: 0.75 },
    }

    @StoreHero ||={
      garrison: { cost: 66*800, garrison_stone: 66},
      dim_exchange: {cost: 40000/2, dim_points: 40/2},
    }
    @StoreGuild ||={
      garrison: { cost: 66*800, garrison_stone: 66},
      t3: 47000,
      dim_exchange: {cost: 40000/2, dim_points: 40/2},
      dim_gear: 67000,
    }
    @StoreLab ||={
      garrison: { cost: 100*800, garrison_stone: 100},
      dim_exchange: {cost: 200000/2, dim_points: 200/2},
      dim_emblems: {cost: 64000, dim_emblems: 50},
    }
    @StoreChallenger ||={}

    @Merchant_daily ||={ dia: 20, purple_stones: 2}
    @Merchant_weekly ||={ dia: 20, purple_stones: 5}
    @Merchant_monthly ||={ dia: 50, purple_stones: 10}

    @Quest_daily ||= {
      gold_hg: 2,
      blue_stones: 5, arena_tickets: 2, xp_h: 2, scrolls: 1,
      dia: 100
    }
    @Quest_weekly ||= {
      gold_h: 8+8,
      blue_stones: 60, purple_stones: 10,
      dia: 400, scrolls: 3,
      dura_tears: 3
    }

    @GH_chest_dia ||=2.7
    @GH_chest_guild ||=65

    @Oak_amount={blue_stones: 30, dia: 100, dust: 500, gold: 1500}
    @Oak_quantity=3; @Oak_proba=0.25

    @Misty_base ||={ gold: 7000, dust_h: 7*4*8, xp_h: 6*24,
           blue_stones: 10*120, purple_stones: 10*18,
           poe: 20*450}

    @Noble_regal_days ||=49
    @Noble_twisted_days ||=44
    @Noble_coe_days ||=36

    @Monthly_vows ||=2 #2 by month
    @Monthly_hero_trial ||=2
    @Hero_trial_rewards ||={
      gold: 2000, dia: 300,
      dust_h: 6*2, xp_h: 6*2, gold_h: 6*8,
      blue_stones: 60, purple_stones: 60
    }

    @Dura_nb ||=7.0
  end

  def setup 
    @ressources={}

    setup_vars
    setup_constants
    get_vip
    get_fos
    get_subscription
    get_mult
    get_numbers
    get_idle_hourly
    post_setup_hook
  end

  def post_setup_hook
  end

  def process!
    get_income
    make_exchange
    exchange_coins #long term coin exchange
    get_ressource_order
  end

  def process
    process!
  end

  def get_income
    @ressources[:idle]=idle
    @ressources[:ff]=ff
    @ressources[:board]=bounties
    @ressources[:guild]=guild
    @ressources[:oak_inn]=oak_inn
    @ressources[:tr]=tr
    @ressources[:quests]=quests
    @ressources[:merchants]=merchants
    @ressources[:friends]=friends
    @ressources[:arena]=arena
    @ressources[:lct]=lct
    @ressources[:dismal]=labyrinth
    @ressources[:misty]=misty
    @ressources[:regal]=regal
    @ressources[:tr_bounties]=twisted_bounties
    @ressources[:coe]=coe
    @ressources[:hero_trial]=hero_trial
    @ressources[:guild_hero_trial]=guild_hero_trial
    @ressources[:vow]=vow
    @ressources.merge!(custom_income)
  end
  def custom_income
    {}
  end

  def make_exchange
    @ressources[:ff_cost]=exchange_ff
    @ressources[:shop]=exchange_shop
    @ressources[:dura_fragments_sell]=sell_dura
    summonings
    @ressources.merge!(custom_exchange)
  end
  def custom_exchange
    {}
  end

  module Setup
    def get_vip
      @_vip_solo_bounty=5
      @_vip_gold_mult=0.0
      if @vip >= 1
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
      if @vip >18
        warn "Warning: vip=#{@vip} not fully implemented"
      end
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
      @_fos_t1_gear_bonus +=1 if @tower_kt >= 250
      @_fos_t1_gear_bonus +=1 if @tower_kt >= 300
      @_fos_t1_gear_bonus +=1 if @tower_kt >= 350
      @_fos_t2_gear_bonus=0
      @_fos_t2_gear_bonus +=1 if @tower_4f >= 200
      @_fos_t2_gear_bonus +=1 if @tower_4f >= 240
      @_fos_t2_gear_bonus +=1 if @tower_4f >= 280
      @_fos_invigor_bonus=0
      @_fos_invigor_bonus +=1 if @tower_god >= 100
      @_fos_invigor_bonus +=1 if @tower_god >= 200
      @_fos_invigor_bonus +=1 if @tower_god >= 300

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
      @_gold_mult=1.0+@_vip_gold_mult+@_fos_gold_mult+(@_sub_gold_mult||0)
      @_xp_mult=1.0+@_vip_xp_mult+@_fos_xp_mult+(@_sub_xp_mult||0)
      @_dust_mult=1.0+@_fos_dust_mult
      @_lab_mult=1.0+@_fos_lab_mult+(@_vip_lab_mult||0)+(@_sub_lab_mult||0)
      @_lab_gold_mult=1.0+(@_vip_lab_gold_mult||0)
      @_guild_mult=1.0+@_fos_guild_mult+(@_sub_guild_mult||0)
      @_mythic_mult=1.0+@_fos_mythic_mult
    end

    def get_numbers
      @_solo_bounties=@_vip_solo_bounty
      @_team_bounties=1+ (@_vip_extra_team_bounty||0) + (@_sub_extra_team_bounty||0)
      @_nb_arena_fight ||=2+(@_vip_extra_arena_fight||0)
      @_nb_guild_fight ||= 2+@_vip_extra_guild_fight
    end

    def get_raw_idle_hourly
      # gear_hourly=1.0/(24*4.5*1.9) #1 every 4.5 days at maxed x1.9 fos
      #TODO: we may need to mult gear_hourly by 2 to account for stage rewards
      
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
      @_raw_idle_hourly[:t1_gear]=t_gear_hourly
      @_raw_idle_hourly[:t2_gear]=t_gear_hourly

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
  include Setup

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

    def get_guild_gold(chests)
      case chests
      when 1,2,3,4; 15
      when 5,6; 30
      when 7,8; 55
      when 9,10; 80
      when 11; 110
      when 12,13,14,15; 1010
      when 16; 1110
      when 17; 1210
      when 18; 1410
      when 19; 1560
      when 20; 1710
      when 21; 1860
      when 22; 2010
      when 23; 2160
      end
    end

    def guild
      nb_chests=@_nb_guild_fight*(@gh_wrizz_chests+@gh_soren_chests*@gh_soren_freq)
      coins=@GH_chest_guild*nb_chests*@_guild_mult+@gh_team_wrizz_coin+@gh_team_soren_coin*@gh_soren_freq
      dia=@GH_chest_dia*nb_chests
      gold=@_nb_guild_fight*(@gh_wrizz_gold+@gh_soren_gold*@gh_soren_freq)+@gh_team_wrizz_gold+@gh_team_soren_gold*@gh_soren_freq

      {guild_coins: coins, dia: dia, gold: gold}
    end

    def oak_inn
      @Oak_amount.map {|k,v| [k, v*@Oak_quantity*@Oak_proba]}.to_h
    end

    def tr
      #TODO add guild tr
      {twisted: @tr_twisted*2.0/3, poe: @tr_poe*2.0/3}
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
      ressources=(@Merchant_daily.keys+@Merchant_weekly.keys+@Merchant_monthly.keys).flatten.sort.uniq
      ressources.map do |r|
        v=(@Merchant_daily[r]||0)+(@Merchant_weekly[r]||0)/7.0+(@Merchant_monthly[r]||0)/30.0
        [r,v]
      end.to_h
    end

    def friends
      {friend_summons: (@friends_nb*1.0+@friends_mercs*10.0/7)/10}
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
      #TODO: add arena tickets usage?
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

    def labyrinth
      #TODO easy/hard standard lab
      @Dismal_stage_chest_rewards ||= { gold_h: 79, xp_h: 39.5, dust_h: 39.5 }
      # skipping large camps: 59h gold+29.5h xp+dust
      @Dismal_end_rewards ||= {
        gold_h: 14*6 + 7*2, xp_h: 3.5*2, dust_h: 3.5*2,
        shards: 61, cores: 41, dia: 300,
        lab_coins: (4200+700)*@_lab_mult, guild_coins: 1000, challenger_coins: 3333
      } # i think guild coins are not affected by the multiplier here

      if @dismal_stage_flat_rewards.nil?
        dismal_flat_gold_h=55 #approximations
        dismal_flat_xp_h=6
        @dismal_stage_flat_rewards = {gold: dismal_flat_gold_h * real_afk_gold * @_lab_gold_mult, xp: dismal_flat_xp_h* real_afk_xp}
      end

      keys=(@Dismal_stage_chest_rewards.keys+@Dismal_end_rewards.keys+@dismal_stage_flat_rewards.keys).uniq
      keys.map do |t|
        total=(@Dismal_stage_chest_rewards[t]||0)+
          (@Dismal_end_rewards[t]||0)+
          (@dismal_stage_flat_rewards[t]||0)
        [t, total*2/3.0] # for double events
      end.to_h
    end

    def get_misty(misty_guild_twisted: :twisted, misty_purple_blue: :blue)
      r = { 
        dust_h: 8*12,
        purple_stones: 2*60,
        red_e: 4*10, t3: 2,
        cores: 3*100,
        hero_choice_chest: 1,
      }

      case misty_guild_twisted
      when :twisted
        r[:twisted] ||=0
        r[:twisted] += 400
      when :guild
        r[:guild_coins] ||=0
        r[:guild_coins] += 30000
      else
        raise "Incorrect choice for misty_guild_twisted: #{misty_guild_twisted}"
      end

      case misty_purple_blue
      when :purple
        r[:purple_stones] ||=0
        r[:purple_stones] += 60
      when :blue
        r[:blue_stones] ||=0
        r[:blue_stones] += 720
      else
        raise "Incorrect choice for misty_purple_blue: #{misty_purple_blue}"
      end
      r
    end

    def misty
      r=sum_hash(@Misty_base, @misty)
      r.map {|k,v| [k, v/30.0]}.to_h
    end

    def regal_choice(paid:false)
      if paid
        {dia: 5500, purple_stones: 1100, blue_stones: 3300}
      else
        {blue_stones: 3300}
      end
    end
    def regal
      @noble_regal.map {|k,v| [k,v*1.0/@Noble_regal_days]}.to_h
    end

    def twisted_bounties_choice(type, paid: false)
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
    def twisted_bounties
      @noble_twisted.map {|k,v| [k,v*1.0/@Noble_twisted_days]}.to_h
    end

    def coe_choice(type, paid: false)
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
        when :red_e; {red_e: 49}
        when :gold_e; {gold_e: 136}
        when :silver_e; {silver_e: 192}
        when :cores; {cores: 585}
        end
      end
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
        warn "Board level #{@board_level} not implemented, skipping"
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

      if @_solo_bounties==8 #lets look at the optimised strat
        single_event={ gold: 152, blue_stones: 24, dust: 810, dia: 50}
        double_event={ gold: 31, blue_stones: 39, dust: 1875, dia: 260}
        solo_quests=types.map do |type|
          v=single_event[type]*2.0/3+double_event[type]*1.0/3
          [type,v]
        end.to_h
      else
        warning "Optimized bounty strat not implemented for #{@_solo_bounties} bounties"
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
      }

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

  module Store
    def get_item_value(item, shop)
      shop_item=shop[item]
      if shop_item.is_a?(Hash)
        cost=shop_item.delete(:cost)
        shop_item.delete(:max) #TODO not implemented
        value=shop_item
      else
        cost=shop_item
        value={item => 1}
      end
      return [cost, value]
    end

    def handle_buys(buys, shop, total)
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

      primary, secondary, extra=split_array(buys)
      primary.each do |item|
        cost, value=get_item_value(item, shop)
        do_buy[item, cost, value]
        total -= cost
      end

      if secondary
        secondary.each do |item|
          cost, value=get_item_value(item, shop)
          if total > cost
            do_buy[item, cost, value]
            total -= cost
          end
        end
      end

      if extra and total > 0.0
        extra=extra.first
        cost, value=get_item_value(extra, shop)
        qty=total*1.0/cost
        do_buy[extra, cost, value, qty: qty]
      end

      return [r, o]
      r
    end

    def buy_summary(buy)
      s=""
      o=[]
      total_cost=0
      buy.each do |item, values|
        qty=values[:qty]
        cost=values[:cost]
        total_cost+=cost*qty
        o<<=" #{round(cost)} (#{(qty==1 || qty==1.0) ? '': "#{round(qty)} x "}#{item})"
      end
      s << "buy #{round(total_cost)} [#{o.join(' + ')}]" unless o.empty?
      s << "\n"
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
        warn "FF cost not implemented for #{@nb_ff} FF"
      end
      full_cost=(0...nb_ff).reduce(0) {|sum, i| sum+@FF_cost[i]}
      {dia: -full_cost}
    end

    def exchange_shop
      shop_refreshes=@shop_refreshes

      @Shop_refresh_cost= [100, 100, 200, 200]
      if @shop_refreshes > @Shop_refresh_cost.length
        warn "Extra cost of shop refreshes not implemented when shop refreshes = #{@shop_refreshes}"
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
        _total=total[coin_name]*30
        r,bought=handle_buys(instance_variable_get(:"@buy_#{i}"), instance_variable_get(:"@Store#{i.to_s.capitalize}"), _total)
        cost=r.delete(:cost)
        r[coin_name]=cost
        @__coin_summary << "#{coin_name}: #{round(_total)} => #{buy_summary(bought)}"
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
    def tally(ressources=@ressources, multiplier: 1)
      r={}
      keys=ressources.values.map {|v| v.keys}.flatten.sort.uniq
      keys.each do |type|
        sum=0
        ressources.each do |k,v|
          if v.key?(type)
            sum+=v[type] * multiplier
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

    def get_total(r=@ressources)
      s=tally(r)
      s=convert_ressources_h(s)
      unless (s.keys & %i(choice_god random_god random_fodder random_atier wishlist_atier choice_atier)).empty?
        s[:god]=(s[:choice_god]||0)+(s[:random_god]||0)
        s[:fodder]=(s[:random_fodder]||0)
        s[:atier]=(s[:random_atier]||0)+(s[:wishlist_atier]||0)+(s[:choice_atier]||0)
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

    def convert_ressources_h(r)
      dust_h=r.fetch(:dust_h,0)
      r[:total_dust]=(r[:dust]||0)+dust_h*real_afk_dust
      xp_h=r.fetch(:xp_h,0)
      r[:total_xp]=(r[:xp]||0)+xp_h*real_afk_xp
      gold_h=r.fetch(:gold_h,0)
      gold_hg=r.fetch(:gold_hg,0) #this is affected only by vip
      r[:total_gold]=(r[:gold]||0)+gold_h*real_afk_gold+gold_hg*real_afk_gold*(1+@_vip_gold_mult)
      r
    end
  end
  include Tally

  module Ordering
    def get_ressource_order
      ressources=tally.keys
      order={
        base: %i(dia gold gold_h gold_hg total_gold xp xp_h total_xp dust dust_h total_dust),
        upgrades: %i(silver_e gold_e red_e poe twisted shards cores),
        gear: %i(t2 t3 mythic_gear t1_gear t2_gear),
        coins: %i(guild_coins lab_coins hero_coins challenger_coins),
        summons: %i(purple_stones blue_stones scrolls friend_summons hcp hero_choice_chest stargazers),
        hero_summons: %i(fodder random_fodder atier choice_atier wishlist_atier random_atier god choice_god random_god),
        misc: %i(dura_fragments class_fragments dura_tears invigor arena_tickets dim_gear dim_points garrison_stone),
      }
      ressources2=order.values.flatten.sort.uniq
      missing=ressources-ressources2
      order[:extra]=missing unless missing.empty?
      @_order=order
    end

    def economy
      {income: %i(idle ff board guild oak_inn tr quests merchants friends arena lct dismal misty regal tr_bounties coe hero_trial guild_hero_trial vow),
       exchange: %i(ff_cost shop dura_fragments_sell),
       summons: %i(wishlist hcp stargazing hero_chest stones tavern stargaze),
       stores: %i(hero_store guild_store lab_store challenger_store),
      }
    end
  end
  include Ordering

  module Summary
    def make_h1(t)
      puts "=============== #{t.capitalize} ==============="
    end
    def make_h2(t)
      puts "--------------- #{t.capitalize} ---------------"
    end
    def make_h3(t)
      puts "***** #{t.capitalize} *****"
    end

    def make_summary(ressources, headings: true)
      @_order.each do |summary, keys|
        s=""
        keys.each do |type|
          sum=0
          o=[]
          ressources.each do |k,v|
            if v.key?(type)
              sum+=v[type]
              o.push("#{round(v[type])} (#{k})")
            end
          end
          s+="#{type}: #{round(sum)} [#{o.join(' + ')}]\n" unless sum==0 or sum==0.0
        end
        unless s.empty?
          make_h3(summary) if headings
          yield(summary) if block_given?
          puts s
          puts if headings
        end
      end
      puts unless headings
    end

    def do_summary(title, r, headings: true, total_value: true, total_summary: true, multiplier: 1)
      if multiplier != 1
        r=timeframe(r, multiplier)
      end

      make_h1(title)
      make_summary(r, headings: headings)

      if total_value
        puts "=> Total value: #{show_dia_value(tally(r))}"
        puts
      end
      if total_summary
        total=get_total(r)
        do_total_summary(total, headings: headings)
      end
      r
    end

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
      make_h1 "Fast Forward Value"
      puts show_dia_value(one_ff)
      puts
    end

    def previsions_summary
      total=clean_total

      make_h1 "30 days previsions summary"
      #puts "Extra rc levels: #{round((ascended+ascended_god)*5)}"
      nb_ascended=0

      @Cost.each do |k,v|
        res_buy, buy, remain=spending(v, total)

        if ["Ascended challenger celo", "Ascended 4F", "Ascended god"].include?(k.to_s)
          nb_ascended += buy
        end

        o_remain=""
        if k==:level
          o_remain+=" {#{res_buy.map { |k,v| "#{k}: #{round(1/v)} days"}.join(', ')}}"
        end

        monthly_remain=remain.select {|k,v| v !=0 and v != 0.0}.map {|k,v| [k, v*30]}.to_h
        o_remain += " [monthly remains: #{monthly_remain.map {|k,v| "#{round(v)} #{k}"}.join(" + ")}]" unless monthly_remain == {}

        puts "#{k}: #{round(1.0/buy)} days (#{round(buy*30.0)} by month)#{o_remain}"
        puts if ["level", "SI+30", "e30 to e65", "9F (with cards)", "Ascended challenger celo"].include?(k.to_s)
      end
      increase_rc_level=5 #one ascended = 5 levels
      puts "Max rc level: #{round(1.0/(increase_rc_level*nb_ascended))} days (#{round(increase_rc_level*nb_ascended*30)} by month)"
      puts
    end

    def show_summary
      ff_summary
      economy.each do |k,v|
        r=@ressources.slice(*v)
        case k
        when :income
          do_summary(k,r, total_summary: false)
        else
          do_summary(k,r, headings: false, total_value: false, total_summary: false)
          if k==:stores
            make_h2("30 days coin summary")
            puts @__coin_summary 
            puts
          end
        end
      end
      do_summary("Full monthly ressources", @ressources, total_value: false, multiplier: 30)
      previsions_summary
    end

    def summary
      show_summary
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
        make_h1 "Variables"
        make_h2 "Setup vars:"
        puts show_vars[setup_vars].join("\n")
        puts
        make_h2 "Fixed vars"
        puts show_vars[fixed_vars].join("\n")
        puts
        make_h2 "Internal vars"
        puts show_vars[internal_vars].join("\n")
        puts
      else
        make_h1 "Variables"
        puts show_vars[setup_vars].join("\n")
      end
    end
  end
  include Summary
end

if __FILE__ == $0
  s=Simulator.new do #example run
    # @monthly_stargazing=50
    @misty = get_misty(misty_guild_twisted: :guild, misty_purple_blue: :blue)
  end
  s.summary

  # s.show_variables
  # s.show_variables(verbose: true)
  #p s.items_value
end
