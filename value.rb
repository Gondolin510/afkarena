#!/usr/bin/env ruby

module Value
  extend self

  def gold_conversion #convert 1K gold into dia
    #2250K gold = 500 dust. 24h dust=300 dia=1167.6 dust
    (500.0/2250) / (1167.6/300)
  end

  def idle_hourly
    {gold: 27, xp: 43.5, dust: 48.65} 
    #to get correct result we need the specific player income here, this is for converting gold:xp/dust into gold_h/xp_h/dust_h
    #i am using values from chap 37, gold and xp are in K
  end

  def items_value
    value = {
      dia: 1,
      gold: gold_conversion,
      xp: 8 / idle_hourly[:xp], #24h xp=192 dia, 1h xp=8 dia
      dust: 12.5 / idle_hourly[:dust], #24h dust=300 dia, 1h dust=12.5
      gold_h: 2, #24h gold=48 dia, 1h gold=2 dia
        #Alternative: idle[:gold]*gold_conversion,
      xp_h: 8,
      dust_h: 12.5,
      poe: 0.675,
      twisted: 6.75,
      silver_e: 10080.0/30 * gold_conversion,
      gold_e: 10920.0 /20 * gold_conversion,
      red_e: 135,

      dura_fragments: 100 * gold_conversion,
      class_fragments: 9000 * 0.675 / 400,

      mythic_gear: 500,
      t1: 1000,
      t2: 2000,
      t3: 3000,
      t1_gear: 500 + 1000,
      t2_gear: 500 + 1000 + 2000,

      invigor: 0.24,
      blue_stones: 2.6,
      purple_stones: 31.2,

      scroll: 240,
      faction: 240,
      stargazers: 500,
      shards: 2000/20 *gold_conversion, #or 6.75=135/20
      cores: (7500 / 48.65 + 380) * 12.5 / 585 #or 13.5=135/10
    }

    value
  end
  #missing: :arena_tickets :challenger_coins :friend_summons :gold_hg :guild_coins :hero_choice_chest :lab_coins

  def dia_value(items)
    o=[]; sum=0
    values=items_value
    items.each do |k,v|
      # p k unless values.key?(k)
      value=v*(values[k]||0)
      sum+=value
      o.push("#{round(v)} #{k}=#{round(value)} dia")
    end
    return [sum, o]
  end
  def show_dia_value(items, details: true)
    total, o=dia_value(items)
    s="#{round(total)} dia"
    s+=" [#{o.join(' + ')}]" if details
  end

  @@rounding=2
  def round(p)
    p.round(@@rounding)
  end

  def blue_stone(n)
    {random_fodder: n/60.0/9.0} #convert into epic
  end
  def purple_stone(n)
    { random_fodder: n/60.0*0.28,
      random_atier: n/60.0*0.68,
      random_god: n/60.0*0.04}
  end
  def friend_summon(n)
    common_summons=n*0.528
    { random_fodder: n * 0.4479/9.0,
      wishlist_atier: n * 0.0221,
      random_god: n*0.002,
      dust: common_summons*5,
      hero_coins: common_summons*160}
  end
  def tavern_summon(n)
    # 400 pulls = 20 red 110 gold 280 purple 4 purple cards
    # 1 common_summon= 5 dust + 160 hero coins
    common_summons=n*0.5169
    {random_fodder: n * 0.4370/9.0,
      wishlist_atier: n * 0.0461,
      random_god: n*0.002,
      dust: common_summons*5,
      hero_coins: common_summons*160,
      #
      random_atier: n/100.0,
      red_e: n*20/400.0,
      gold_e: 110/400.0,
      silver_e: 280/400.0}
  end
  def choice_summon(n)
    r=tavern_summon(n)
    wl=r.delete(:wishlist_atier)
    r[:choice_atier]=wl
    r
  end
  def stargaze(n)
    ## TODO
    ## real_proba=1/40.0
    ## adjust_proba=real_proba-0.02 #the given stargazing proba is 2% but in truth it is 1 out of 40 due to pity; so we need to adjust the other probas, except the diamond one
    ## nb_probas=4+4+12+(15+5+1)+2+2+2
    ## epsilon=adjust_proba/nb_probas
    { choice_god: n/40.0,
      random_atier: n * 4*0.008, #purple card
      random_fodder: n * 4*0.0225/9.0, #blue card
      #
      dia: n*30000*0.0001,
      mythic_gear: n * 12*0.0007,
      dura_fragments: n * 7* (15*0.0018+5*0.0056+1*0.0276),
      gold_h: n * (2*24*0.045+5*6*0.0936),
      xp_h: n * (1*24*0.045+2*6*0.0936),
      dust_h: n * (2*8*0.045+5*2*0.0936),
    }
  end
end

module Data
  extend self
  def get_idle_data
    @__idle_data if  @__idle_data
    idle=JSON.load_file("data/idle.json5")
    @__idle_data=idle.map do |chap,idle|
      [chap.to_i,
      idle.map do |k,v|
        v=v/1000.0 if k=="gold" or k=="exp"
        k=:dura_fragments if k=="dura"
        k=:class_fragments if k=="class"
        k=:mythic_gear if k=="mythic"
        k=:t1_gear if k=="t1_g"
        k=:t2_gear if k=="t2_g"
        k=:shards if k=="shard"
        k=:cores if k=="core"
        k=:xp if k=="exp"
        [k.to_sym, v]
      end.to_h]
    end.to_h
  end

  def get_idle(stage) #the values are of the last stage, interpolate
    chap,level=stage.split('-')
    chap=chap.to_i; level=level.to_i
    prev_chap=chap-1
    prev_chap = 1 if chap==1
    prev_idle=get_idle_data[prev_chap]
    cur_idle=get_idle_data[chap]
    ratio=level/60.0 #TODO check when there are 40 levels
    idle={}
    cur_idle.each do |k,v|
      idle[k]=prev_idle[k]*(1-ratio)+cur_idle[k]*ratio
    end
    idle
  end
end

module Helpers
  extend self
  def add_to_hash(r,*hashes, multiplier: 1)
    hashes.each do |h|
      h.each do |k,v|
        r[k]||=0
        r[k]+=v*multiplier
      end
    end
    r
  end

  def sum_hash(*args, **kw)
    add_to_hash({}, *args, **kw)
  end

  def split_array(arr)
    arr=arr.dup
    result = []
    while (idx = arr.index(nil))
      result << arr.shift(idx)
      arr.shift
    end
    result << arr
  end
end

if __FILE__ == $0
  arena_fight = {
    gold: 90*0.495, dust: 10*0.495+500*0.01*0.2,
    blue_stones: 60*0.01*0.2, purple_stones: 10*0.01*0.3,
    dia: (150*0.15+300*0.12+3000*0.03)*0.01
  }
  puts "Arena ticket value: #{Value.show_dia_value(arena_fight)}"
end
