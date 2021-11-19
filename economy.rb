#!/usr/bin/env ruby
#TODO: towers, more events?

require './value'

class Simulator
  attr_accessor :income, :outcome
  include Value

  def initialize(&b)
    instance_eval(&b) if b
    setup #we assume that we are at least at Chap 33
  end

  def setup
    @afk_xp ||=13235 #the displayed value by minute, this include the vip bonus but not the fos bonus
    @afk_gold ||=844 #the displayed value by minute (include vip)
    @afk_dust ||=1167.6 #the value by day

    #at rc 557: the amount required to level up (xp and gold are in K)
    @level_gold ||= 18440
    @level_xp ||= 130410
    @level_dust ||= 25599

    @nb_ff ||=6 #ff by day
    @vip ||=9 #vip level
    @subscription ||=true if @subscription.nil?
    @player_level ||=165 #for fos
    @board_level ||=8

    @fos_t1_gear_bonus ||=3 #kings tower: 1 at 250/2 at 300/3 at 350
    @fos_t2_gear_bonus ||=3 #4f towers: 1 at 200/2 at 240/3 at 280
    @fos_invigor_bonus ||=2 #god towers: 1 at 100/2 at 200/3 at 300

    @monthly_stargazing ||= 0 #number of stargazing done in a month
    @monthly_tavern ||= 0 #number of tavern pulls
    @monthly_hcp ||= 0 #number of hcp pulls

    get_vip
    get_fos
    get_subscription
    get_mult
    get_numbers
    get_idle_hourly
  end

  def process!
    get_income
    make_exchange
    tally
    get_ressource_order
  end

  def process
    unless @_processed
      process!
      @_processed=true
    end
  end

  def get_income
    @income={}
    @income[:idle]=idle
    @income[:ff]=ff
    @income[:board]=bounties
    @income[:guild]=guild
    @income[:oak_inn]=oak_inn
    @income[:tr]=tr
    @income[:quests]=quests
    @income[:merchants]=merchants
    @income[:friends]=friends
    @income[:arena]=arena
    @income[:lct]=lct
    @income[:dismal]=labyrinth
    @income[:misty]=misty
    @income[:regal]=regal
    @income[:tr_bounties]=twisted_bounties
    @income[:coe]=coe
    @income[:hero_trial]=hero_trial
    @income[:guild_hero_trial]=guild_hero_trial
    @income[:vow]=vow
    @income.merge!(custom_income)
  end
  def custom_income
    {}
  end

  def make_exchange
    @exchange={}
    @exchange[:ff]=exchange_ff
    @exchange[:shop]=exchange_shop
    @exchange[:dura_fragment_sell]=sell_dura
    summonings
    @exchange.merge!(custom_exchange)
  end
  def custom_exchange
    {}
  end

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
    if @vip >15
      warn "Warning: vip=#{@vip} not fully implemented"
    end
    @_vip_xp_mult||=@_vip_gold_mult
  end

  def get_fos
    @_fos_base_gold=70+75+80 #stage 24-60
    @_fos_base_xp=182+372+812 #stage 25-60
    @_fos_base_dust=80+135+170 #stage 26-60

    @_fos_lab_mult=0.15*3 #stage 25-60
    @_fos_guild_mult=0.15*3 #stage 20-60
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
    @_arena_nb_fight ||=2+(@_vip_extra_arena_fight||0)
  end

  def get_idle_hourly
    t_gear_hourly=1.0/(24*15*3) #1 every 15 days at maxed x3 fos
    gear_hourly=1.0/(24*4.5*1.9) #1 every 4.5 days at maxed x1.9 fos
    #TODO: we may need to mult this by 2 to account for end level rewards

    @Idle_hourly ||={
      poe: 22.93, twisted: 1.11630, silver_e: 0.08330,
      gold_e: 0.04170, red_e: 0.01564, shards: 1.25, cores: 0.625,
      t2: gear_hourly, mythic_gear: gear_hourly,
      t3: 1.0/(24*15), #1 every 15 days
      t1_gear: t_gear_hourly,
      t2_gear: t_gear_hourly,
      invigor: 6, dura_fragment: 0.267,
    } #the last of these items to max out is poe at Chap 33

    # we use gold and xp in K
    @_real_afk_xp||=@afk_xp*(60.0/1000)/(1.0+@_vip_xp_mult)
    @_real_afk_gold||=@afk_gold*(60.0/1000)/(1.0+@_vip_gold_mult)
    @_real_afk_dust=@afk_dust/24.0

    @_idle_hourly=@Idle_hourly.dup
    @_idle_hourly[:mythic_gear] *= @_mythic_mult
    @_idle_hourly[:t2] *= @_mythic_mult
    @_idle_hourly[:t1_gear] *= @fos_t1_gear_bonus
    @_idle_hourly[:t2_gear] *= @fos_t2_gear_bonus
    @_idle_hourly[:invigor] *= (1+@fos_invigor_bonus)
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
    @_real_afk_gold
  end
  def real_afk_xp
    @_real_afk_xp
  end
  def real_afk_dust
    @_real_afk_dust
  end

  # Income functions
  # ################
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
    @Chest_dia ||=2.7
    @Chest_guild ||=65

    @team_wrizz_gold ||=1080
    @team_wrizz_coin ||=1158
    @team_soren_gold ||=@team_wrizz_gold
    @team_soren_coin ||=@team_wrizz_coin

    @wrizz_chests ||= 21
    @wrizz_gold ||= 1900
    @soren_gold ||= @wrizz_gold
    @soren_chests ||= @wrizz_chests
    @soren_freq ||= 5.0/7.0

    @_nb_guild_fight ||= 2+@_vip_extra_guild_fight

    nb_chests=@_nb_guild_fight*(@wrizz_chests+@soren_chests*@soren_freq)
    coins=@Chest_guild*nb_chests*@_guild_mult+@team_wrizz_coin+@team_soren_coin*@soren_freq
    dia=@Chest_dia*nb_chests
    gold=@_nb_guild_fight*(@wrizz_gold+@soren_gold*@soren_freq)+@team_wrizz_gold+@team_soren_gold*@soren_freq

    {guild_coins: coins, dia: dia, gold: gold}
  end

  def oak_inn
    @Oak_amount={blue_stones: 30, dia: 100, dust: 500, gold: 1500}
    @Oak_quantity=3; @Oak_proba=0.25
    @Oak_amount.map {|k,v| [k, v*@Oak_quantity*@Oak_proba]}.to_h
  end

  def tr
    @tr_twisted ||=250
    @tr_poe ||=1000
    {twisted: @tr_twisted*2.0/3, poe: @tr_poe*2.0/3}
  end

  def quests
    @Daily_quest ||= {
      dust_h: 2, gold_h: 2, gold_hg: 2,
      blue_stones: 5, arena_tickets: 2, xp_h: 2, scroll: 1,
      dia: 50+100
    }
    @Weekly_quest ||= {
      gold_h: 8+8,
      twisted: 50, poe: 500,
      blue_stones: 60, purple_stones: 10,
      silver_e: 20, gold_e: 10, red_e: 5,
      dia: 400, scroll: 3,
      dura_tears: 3
    } #this maxes out at 30-60 with the red emblem rewards
    ressources=(@Daily_quest.keys+@Weekly_quest.keys).flatten.sort.uniq
    ressources.map do |r|
      v=(@Daily_quest[r]||0)+(@Weekly_quest[r]||0)/7.0
      [r,v]
    end.to_h
  end

  def merchants
    @Daily_merchant ||={ dia: 20, purple_stones: 2}
    @Weekly_merchant ||={ dia: 20, purple_stones: 5}
    @Monthly_merchant ||={ dia: 50, purple_stones: 10}
    ressources=(@Daily_merchant.keys+@Weekly_merchant.keys+@Monthly_merchant.keys).flatten.sort.uniq
    ressources.map do |r|
      v=(@Daily_merchant[r]||0)+(@Weekly_merchant[r]||0)/7.0+(@Monthly_merchant[r]||0)/30.0
      [r,v]
    end.to_h
  end

  def friends
    @nb_mercs ||= 5
    @nb_friends ||= 20
    {friend_summons: (@nb_friends*1.0+@nb_mercs*10.0/7)/10}
  end

  def arena
    @arena_daily_dia ||=60
    @arena_weekly_dia ||=600
    #TODO: add arena tickets usage?

    arena_fight = {
      gold: 90*0.495, dust: 10*0.495+500*0.01*0.2,
      blue_stones: 60*0.01*0.2, purple_stones: 10*0.01*0.3,
      dia: (150*0.15+300*0.12+3000*0.03)*0.01
    }

    r=arena_fight.map {|k,v| [k, v*@_arena_nb_fight]}.to_h
    r[:dia] += @arena_daily_dia + @arena_weekly_dia/7.0
    r
  end

  def lct
    @lct_coins ||=380 #top 20
    {challenger_coins: @lct_coins*24}
  end

  def labyrinth
    @_dismal_stage_chest_rewards ||= { gold_h: 79, xp_h: 39.5, dust_h: 39.5 }
    # skipping large camps: 59h gold+29.5h xp+dust
    @_dismal_end_rewards ||= {
      gold_h: 14*6 + 7*2, xp_h: 3.5*2, dust_h: 3.5*2,
      shards: 61, cores: 41, dia: 300,
      lab_coins: (4200+700)*@_lab_mult, guild_coins: 1000, challenger_coins: 3333
    } # i think guild coins are not affected by the multiplier here

    if @dismal_stage_flat_rewards.nil?
      dismal_flat_gold_h=55 #approximations
      dismal_flat_xp_h=6
      @dismal_stage_flat_rewards = {gold: dismal_flat_gold_h * real_afk_gold * @_lab_gold_mult, xp: dismal_flat_xp_h* real_afk_xp}
    end

    keys=(@_dismal_stage_chest_rewards.keys+@_dismal_end_rewards.keys+@dismal_stage_flat_rewards.keys).uniq
    keys.map do |t|
      total=(@_dismal_stage_chest_rewards[t]||0)+
        (@_dismal_end_rewards[t]||0)+
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
    @misty ||= get_misty
    @Misty_base ||={ gold: 7000, dust_h: 7*4*8, xp_h: 6*24,
           blue_stones: 10*120, purple_stones: 10*18,
           poe: 20*450}

    r=@Misty_base.dup
    @misty.each do |k,v|
      r[k]||=0; r[k]+=v
    end
    r.map {|k,v| [k, v/30.0]}.to_h
  end

  def regal
    @Regal_days ||=49
    @regal_quantity ||={blue_stones: 3300}
    @regal_quantity.map {|k,v| [k,v*1.0/@Regal_days]}.to_h
  end
  def twisted_bounties
    @Twisted_days ||=44
    @twisted_quantity ||={xp_h: 956}
    @twisted_quantity.map {|k,v| [k,v*1.0/@Twisted_days]}.to_h
  end
  def coe
    @Coe_days ||=36
    @coe_quantity ||= {cores: 585}
    @coe_quantity.map {|k,v| [k,v*1.0/@Coe_days]}.to_h
  end

  def hero_trial
    @Hero_trial_monthly ||=2
    @Hero_trial_rewards ||={
      gold: 2000, dia: 300,
      dust_h: 6*2, xp_h: 6*2, gold_h: 6*8,
      blue_stones: 60, purple_stones: 60
    }

    @Hero_trial_rewards.map do |k,v|
      [k, v*@Hero_trial_monthly/30.0]
    end.to_h
  end
  def guild_hero_trial
    @guild_hero_trial_rewards ||={
      dia: 200+100+200,
      guild_coins: 1000 #assume top 500
    }

    @guild_hero_trial_rewards.map do |k,v|
      [k, v*@Hero_trial_monthly/30.0]
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
        scroll: 20
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

    @Nb_vows=2 #2 by month
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
      [k, v*@Nb_vows/30.0]
    end.to_h
  end

  def exchange_ff
    ff_cost=[0, 50, 80, 100, 100, 200, 300, 400]
    nb_ff=@nb_ff
    if nb_ff > ff_cost.length
      nb_ff=ff_cost.length
      warn "FF cost not implemented for #{@nb_ff} FF"
    end
    full_cost=(0...nb_ff).reduce(0) {|sum, i| sum+ff_cost[i]}
    {dia: -full_cost}
  end

  def exchange_shop
    return @_shop unless @_shop.nil?

    @shop_refreshes ||= 2
    @shop_items ||= %i(dust purple_stones poe shards)

    warn "Extra cost of shop refreshes not implemented when shop refreshes = #{@shop_refreshes} (nor cores/shards max cap)" if @shop_refreshes > 2
    nb_shop=1+@shop_refreshes
    @_shop={dia: -@shop_refreshes*100, gold: 0}
    xp_h_proba=0.25 #TODO: refine these probas
    purple_stones_proba=0.25
    gold_e_proba=0.25
    silver_e_proba=0.75

    if @shop_items.include?(:dust)
      @_shop[:gold] -= nb_shop*2250
      @_shop[:dust] = nb_shop*500
    end
    if @shop_items.include?(:dust_h)
      @_shop[:dia] -= nb_shop*300
      @_shop[:dust_h] = nb_shop*24
    end
    if @shop_items.include?(:xp_h)
      @_shop[:dia] -= nb_shop*192*xp_h_proba
      @_shop[:xp_h] = nb_shop*24*xp_h_proba
    end
    if @shop_items.include?(:purple_stones)
      @_shop[:dia] -= nb_shop*90*purple_stones_proba
      @_shop[:purple_stones] = nb_shop*5*purple_stones_proba
    end
    if @shop_items.include?(:poe)
      @_shop[:gold] -= nb_shop*1125
      @_shop[:poe] = nb_shop*250
    end
    if @shop_items.include?(:shards)
      @_shop[:gold] -= nb_shop*2000
      @_shop[:shards] = nb_shop*20
    end
    if @shop_items.include?(:cores)
      @_shop[:dia] -= nb_shop*200
      @_shop[:cores] = nb_shop*10
    end
    if @shop_items.include?(:silver_e)
      @_shop[:gold] -= nb_shop*14400*0.7*silver_e_proba #30% reduction
      @_shop[:silver_e] = nb_shop*30*silver_e_proba
    end
    if @shop_items.include?(:gold_e)
      @_shop[:gold] -= nb_shop*15600*0.7*gold_e_proba #30% reduction
      @_shop[:gold_e] = nb_shop*20*gold_e_proba
    end
    @_shop
  end

  def sell_dura
    @Nb_dura ||=7
    @nb_dura_selling ||=1

    total_dura=tally_income[:dura_fragment]*1.0
    {gold: @nb_dura_selling*total_dura/@Nb_dura}
  end

  def summonings
    @exchange[:stargazing]={
      dia: -500.0*@monthly_stargazing/30,
      stargazers: @monthly_stargazing/30.0
    }
    @exchange[:tavern]={
      dia: -270.0*@monthly_tavern/30,
      scroll: @monthly_tavern/30.0
    }
    @exchange[:hcp]={
      dia: -300.0*@monthly_hcp/30,
      hcp: @monthly_hcp/30.0
    }
  end

  def get_tally(ressources)
    r={}
    keys=ressources.values.map {|v| v.keys}.flatten.sort.uniq
    keys.each do |type|
      sum=0
      ressources.each do |k,v|
        if v.key?(type)
          sum+=v[type]
        end
      end
      r[type]=sum
    end
    r
  end

  def tally_income
    get_tally(@income)
  end
  def tally_exchange
    get_tally(@exchange)
  end

  def tally
    _tally_income=tally_income #memoize to not call the function each time here
    _tally_exchange=tally_exchange
    @total= (_tally_income.keys+_tally_exchange.keys).uniq.map do |key|
      [key, (_tally_income[key]||0)+(_tally_exchange[key]||0)]
    end.to_h

    handle_summons #get extra ressources from summons, this updates @total
    convert_ressources_h
    @total
  end

  def convert_ressources_h
    dust_h=@total.delete(:dust_h)||0
    @total[:dust]=(@total[:dust]||0)+dust_h*real_afk_dust
    xp_h=@total.delete(:xp_h)||0
    @total[:xp]=(@total[:xp]||0)+xp_h*real_afk_xp
    gold_h=@total.delete(:gold_h)||0
    gold_hg=@total.delete(:gold_hg)||0 #this is affected only by vip
    @total[:gold]=(@total[:gold]||0)+gold_h*real_afk_gold+gold_hg*real_afk_gold*(1+@_vip_gold_mult)
    @total
  end

  def handle_summons
    random_fodder=0; random_atier=0; random_god=0
    wishlist_atier=0; choice_atier=0; choice_god=0
    common_summons=0;

    #choice chests
    choice_atier += @total[:hero_choice_chest]||0

    #stones
    purple_summons=(@total[:purple_stones]||0)/60.0
    blue_summons=(@total[:blue_stones]||0)/60.0
    random_fodder += purple_summons*0.28 + blue_summons/9.0
    random_atier += purple_summons*0.68
    random_god += purple_summons*0.04

    #friend summons
    friends=@total[:fridend_summons]||0
    random_fodder   += friends * 0.4479/9.0
    wishlist_atier += friends * 0.0221
    random_god += friends * 0.002
    common_summons += friends * 0.528

    #wishlist summons
    wl=(@total[:scroll]||0)+(@total[:wishlist]||0)
    random_fodder   += wl * 0.4370/9.0
    wishlist_atier += wl * 0.0461
    random_god += wl * 0.002
    common_summons += wl * 0.5169

    #hcp summons
    hcp=(@total[:hcp]||0)
    random_fodder   += hcp * 0.4370/9.0
    choice_atier += hcp * 0.0461
    random_god += hcp * 0.002
    common_summons += hcp * 0.5169

    #wishlist extra ressources
    # 400 pulls = 20 red 110 gold 280 purple 4 purple cards
    total_wl=wl+hcp
    random_atier += total_wl * 1.0/100
    ressources={
      red_e: total_wl*20/400.0,
      gold_e: total_wl*110/400.0,
      silver_e: total_wl*280/400.0
    }

    #common extra ressources
    #1 common = 160 hero coins + 5 dust
    ressources[:hero_coins]=common_summons*160
    ressources[:dust]=common_summons*5

    #stargazing
    stargaze=@total[:stargazers]
    choice_god += stargaze/40.0
    random_atier += stargaze * 4*0.008 #purple card
    random_fodder += stargaze * 4*0.0225/9.0 #blue card
    stargaze_ressources={}
    stargaze_ressources[:dia]=stargaze * 30000*0.0001
    stargaze_ressources[:mythic_gear]= stargaze * 12*0.0007
    stargaze_ressources[:dura_fragment]=stargaze * 7* (15*0.0018+5*0.0056+1*0.0276)
    stargaze_ressources[:arena_tickets] = stargaze *0.0501
    stargaze_ressources[:gold_h]=stargaze * (2*24*0.045+5*6*0.0936)
    stargaze_ressources[:xp_h]=stargaze * (1*24*0.045+2*6*0.0936)
    stargaze_ressources[:dust_h]=stargaze * (2*8*0.045+5*2*0.0936)

    @summons={
      summons: ressources,
      stargaze: stargaze_ressources
    }

    tally_summons=get_tally(@summons)
    tally_summons.each do |k,v| # update total
      @total[k]||=0
      @total[k]+=v
    end

    @summons_summary={ #30 days summons summary
      fodder: random_fodder*30,
      choice_atier: choice_atier*30,
      wishlist_atier: wishlist_atier*30,
      random_atier: random_atier*30,
      choice_god: choice_god*30,
      random_god: random_god*30
    } 

    @summons
  end

  def get_ressource_order
    ressources=@total.keys #(@tally_income.keys+@tally_exchange.keys).uniq
    order={
      base: %i(dia gold gold_h gold_hg xp xp_h dust dust_h),
      upgrades: %i(silver_e gold_e red_e poe twisted shards cores),
      gear: %i(t2 t3 mythic_gear t1_gear t2_gear),
      coins: %i(guild_coins lab_coins hero_coins challenger_coins),
      summons: %i(purple_stones blue_stones scroll friend_summons hcp hero_choice_chest stargazers),
      misc: %i(dura_fragment invigor arena_tickets)
    }
    ressources2=order.values.flatten.sort.uniq
    missing=ressources-ressources2
    order[:extra]=missing unless missing.empty?
    @_order=order
  end

  def make_summary(ressources)
    @_order.each do |summary, keys|
      yield(summary) if block_given?
      keys.each do |type|
        sum=0
        o=[]
        ressources.each do |k,v|
          if v.key?(type)
            sum+=v[type]
            o.push("#{round(v[type])} (#{k})")
          end
        end
        puts "#{type}: #{round(sum)} [#{o.join(' + ')}]" unless sum==0
      end
      puts if block_given?
    end
  end

  def income_summary
    puts "=============== Income ==============="
    make_summary(@income) do |summary|
      puts "***** #{summary.capitalize} *****"
    end

    puts "*-*-* Extra summoning ressources *-*-*"
    make_summary(@summons)
    puts

    puts "Total value: #{show_dia_value(tally_income)}"
    puts
  end

  def ff_summary
    puts "=============== Fast Forward Value ==============="
    puts show_dia_value(one_ff)
    puts
  end

  def exchange_summary
    puts "=============== Spending and exchange ==============="
    make_summary(@exchange)
    puts
  end
  def total_summary
    puts "=============== Total ==============="
    @_order.each do |summary, keys|
      puts "**** #{summary.capitalize} ****"
      keys.each do |type|
        sum=@total[type]||0
        puts "#{type}: #{round(sum)}" unless sum==0
      end
      puts
    end
  end
  def summons_summary
    #{:fodder=>16.29998390022676, :choice_atier=>1.0, :wishlist_atier=>1.975714285714286, :random_atier=>6.69687619047619, :choice_god=>0, :random_god=>0.4544380952380952}
    fodders=@summons_summary[:fodder]
    atier=@summons_summary[:choice_atier]+@summons_summary[:wishlist_atier]+@summons_summary[:random_atier]
    god=@summons_summary[:choice_god]+@summons_summary[:random_god]

    puts "=============== 30 days summons summary (tavern: #{@monthly_tavern}, hcp: #{@monthly_hcp}, stargaze: #{@monthly_stargazing}) ==============="
    puts "Fodders: #{round(fodders)}"
    puts "Atiers: #{round(atier)} [choice: #{round(@summons_summary[:choice_atier])}, wl: #{round(@summons_summary[:wishlist_atier])}, random: #{round(@summons_summary[:random_atier])}]"
    puts "Gods: #{round(god)} [choice: #{round(@summons_summary[:choice_god])}, random: #{round(@summons_summary[:random_god])}]"

    #we need 8 atier + 10 fodders for ascended atier
    #we need 14 god for ascended god
    if atier/8.0 < fodders/10.0 then
      ascended=atier/8.0; extrafodder=fodders-ascended*10.0
      puts "Ascended 4F: #{round(ascended)} [remains #{round(extrafodder)} fodders]"
    else
      ascended=fodder/10.0; extraatier=atier-ascended*8.0
      puts "Ascended 4F: #{round(ascended)} [remains #{round(extraatier)} atiers]"
    end
    ascended_god=god/14.0
    puts "Ascended gods: #{round(ascended_god)}"
    #one ascended = 5 levels
    puts "Extra rc levels: #{round((ascended+ascended_god)*5)}"
    puts
  end

  def coins_summary
    buy_summary = lambda do |total, buying|
      buy=buying.values.sum
      remain=total-buy
      o="#{round(total)} => buy #{buy} [#{buying.map { |k,v| "#{v} (#{k})" }.join(' + ')}], remains: #{round(remain)}"
      [o,remain]
    end
    puts "=============== 30 days coins summary ==============="

    hero=(@total[:hero_coins]||0)*30
    @_hero_buys = {
      garrison: 66*800
    }
    puts "- Hero coins: #{buy_summary[hero,@_hero_buys][0]}"

    guild=(@total[:guild_coins]||0)*30
    @_guild_buys = {
      garrison: 66*800,
      t3: 2*47000, #T1: 33879, T2: 40875, T3: 47000
      dim_exchange: 40000/2, #across 2 months
    }
    o,remain=buy_summary[guild, @_guild_buys]
    @_dim_gear_cost=67000 #@20% reduction
    nb_dim_gear=(remain*1.0/@_dim_gear_cost)

    puts "- Guild coins: #{o} {= #{round(nb_dim_gear)} dim gears}"

    lab=(@total[:lab_coins]||0)*30
    @_lab_buys = {
      garrison: 100*800,
      dim_exchange: 200000/2, #across 2 months
      dim_emblems: 64000, #50 dim emblems
    }
    puts "- Lab coins: #{buy_summary[lab,@_lab_buys][0]}"

    challenger=(@total[:challenger_coins]||0)*30
    puts "- Challenger coins: #{round(challenger)}"
    puts
  end

  def previsions_summary
    puts "=============== Previsions ==============="

    gold=@total[:gold]||0
    xp=@total[:xp]||0
    dust=@total[:dust]||0
    level_gold_day=@level_gold *1.0/gold
    level_xp_day=@level_xp *1.0/xp
    level_dust_day=@level_dust *1.0/dust
    max_time=[level_gold_day,level_xp_day,level_dust_day].max
    puts "Level: #{round(max_time)} days [gold: #{round(level_gold_day)} days, xp: #{round(level_xp_day)} days, dust: #{round(level_dust_day)} days]"
    puts

    silver_e=@total[:silver_e]||0
    days=240.0/silver_e
    puts "SI+10: #{round(days)} days"

    gold_e=@total[:gold_e]||0
    days=240.0/gold_e
    puts "SI+20: #{round(days)} days"

    red_e=@total[:red_e]||0
    days=300.0/gold_e
    puts "SI+30: #{round(days)} days"
    puts

    shards=@total[:shards]||0
    days=3750.0/shards
    puts "e30: #{round(days)} days"

    cores=@total[:shards]||0
    days=1650.0/cores
    puts "e30 to e41: #{round(days)} days"
    days=4500.0/cores
    puts "e30 to e60: #{round(days)} days"
    days=(4500.0+1500)/cores
    puts "e30 to e65: #{round(days)} days"
    puts

    twisted=@total[:twisted]||0
    days=800.0/twisted
    puts "Tree level: #{round(days)} days"

    poe=@total[:poe]||0
    mythic_cost=(1/0.0407*300)
    days=mythic_cost/poe
    puts "Mythic furn: #{round(days)} days"
    #90 pulls = 1 mythic card
    #so 90 pulls = 1+ 90*0.0407 = 4.663 mythic furns
    mythic_cost=(90*300/(1+90*0.0407))
    days=mythic_cost/poe
    puts "Mythic furn (with cards): #{round(days)} days"
    days=167000.0/poe #9F: via 2 furn drop + 7 mythic cards
    puts "9F (with cards): #{round(days)} days"
    puts

    challenger=@total[:challenger_coins]||0
    days=250000.0/challenger
    puts "Challenger celo: #{round(days)} days, ascended: #{round(14*days)}"
    puts
  end

  def show_summary
    ff_summary
    income_summary
    exchange_summary
    total_summary
    summons_summary
    coins_summary
    previsions_summary
  end

  def summary
    process
    show_summary
  end

  def show_variables(verbose: false)
    process
    blacklist=%i(@income @exchange @total @summons @summons_summary @Vows @_order @_processed)
    vars=instance_variables-blacklist
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
      end.join(', ')
    end

    if verbose
      puts "- Setup vars: #{show_vars[setup_vars]}"
      puts
      puts "- Fixed vars: #{show_vars[fixed_vars]}"
      puts
      puts "- Internal vars: #{show_vars[internal_vars]}"
      puts
    else
      puts "- Vars: #{show_vars[setup_vars]}"
    end
  end
end


if __FILE__ == $0
  s=Simulator.new do
    # @monthly_stargazing=50
    @misty = get_misty(misty_guild_twisted: :guild, misty_purple_blue: :blue)
  end
  s.summary

  # s.show_variables
  # s.show_variables(verbose: true)
  #p s.items_value
end
