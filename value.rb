#!/usr/bin/env ruby

module Helpers
  extend self
  @@rounding=2
  def round(p)
    p.round(@@rounding)
  end


  def add_to_hash(r,*hashes, multiplier: 1)
    hashes.each do |h|
      h.each do |k,v|
        r[k]||=0
        r[k]+=v*multiplier
      end
    end
    r
  end
  def mult_hash(h, multiplier)
    h.map do |k,v|
      [k,v*multiplier]
    end.to_h
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

module Value
  include Helpers
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

  def items_value(summons: true)
    scroll=240
    value = {
      dia: 1,
      gold: gold_conversion,
      xp: 8 / idle_hourly[:xp], #24h xp=192 dia, 1h xp=8 dia
      dust: 12.5 / idle_hourly[:dust], #24h dust=300 dia, 1h dust=12.5
      gold_h: 2, #24h gold=48 dia, 1h gold=2 dia
      gold_hg: 2,
        #Alternative: idle[:gold]*gold_conversion,
      xp_h: 8,
      dust_h: 12.5,

      poe: 0.675,
      twisted: 6.75,
      silver_e: 10080.0/30 * gold_conversion,
      gold_e: 10920.0 /20 * gold_conversion,
      red_e: 135,
      shards: 2000/20 *gold_conversion, #=5.709. Or 6.75=135/20
      cores: (7500 / 48.65 + 380) * 12.5 / 585, #=11.41. Or 13.5=135/10

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

      scrolls: scroll,
      faction_scrolls: scroll,
      friend_summons: scroll,
      stargazers: 500,
      hero_choice_chest: 6400,

      arena_tickets: 50*gold_conversion,

      challenger_coins: 1.0/15,
      guild_coins: 1.0/15,
      hero_coins: 1.0/7.5,
      lab_coins: 1.0/9.5,
    }

    if summons
      value.merge!({
        choice_god: 14000,
        random_god: 9600,
        random_atier: 31.2*60, #=1872
        wishlist_atier: 6400,
        choice_atier: 6400,
        random_fodder: 2.6*60*9 #=1404=1872*6/9, 2.6*60*156
      })
    end
    
    # "Missing: dura_tears
    value
  end

  def dia_value(items, **kw)
    o=[]; sum=0
    values=items_value(**kw)
    items.each do |k,v|
      #p "Missing: #{k}" unless values.key?(k)
      value=v*(values[k]||0)
      sum+=value
      o.push("#{round(v)} #{k}=#{round(value)} dia")
    end
    return [sum, o]
  end
  def show_dia_value(items, details: true, **kw)
    total, o=dia_value(items, **kw)
    s="#{round(total)} dia"
    s+=" [#{o.join(' + ')}]" if details
  end

  def blue_stone(n=60)
    {random_fodder: n/60.0/9.0} #convert into epic
  end
  def purple_stone(n=60)
    { random_fodder: n/60.0*0.28,
      random_atier: n/60.0*0.68,
      random_god: n/60.0*0.04}
  end
  def friend_summon(n=1)
    common_summons=n*0.528
    { random_fodder: n * 0.4479/9.0,
      wishlist_atier: n * 0.0221,
      random_god: n*0.002,
      dust: common_summons*5,
      hero_coins: common_summons*160}
  end
  def tavern_summon(n=1)
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
  def choice_summon(n=1)
    r=tavern_summon(n)
    wl=r.delete(:wishlist_atier)
    r[:choice_atier]=wl
    r
  end
  def stargaze(n=1)
    real_proba=1/40.0 #the given stargazing proba is 2% but in truth it is 1 out of 40 due to pity; so we need to adjust the other probas, except the diamond one
    diamond_proba=0.0001
    ratio=(1.0-real_proba-diamond_proba)/(1.0-0.02-diamond_proba)
    #p ratio
    { choice_god: n/40.0,
      random_atier: n * 4*ratio*0.008, #purple card
      random_fodder: n * 4*ratio*0.0225/9.0, #blue card
      #
      dia: n*30000*diamond_proba,
      mythic_gear: n * 12*ratio*0.0007,
      dura_fragments: n * 7* ratio*(15*0.0018+5*0.0056+1*0.0276),
      gold_h: n * ratio*(2*24*0.045+5*6*0.0936),
      xp_h: n * ratio*(1*24*0.045+2*6*0.0936),
      dust_h: n * ratio*(2*8*0.045+5*2*0.0936),
    }
  end

  def arena_fight(n=1)
    {
      gold: 90*0.495, dust: 10*0.495+500*0.01*0.2,
      blue_stones: 60*0.01*0.2, purple_stones: 10*0.01*0.3,
      dia: (150*0.15+300*0.12+3000*0.03)*0.01
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

if __FILE__ == $0
  puts "- Arena ticket value: #{Value.show_dia_value(Value.arena_fight(1))}"
  # Arena ticket value: 6.81 dia [44.55 gold=2.54 dia + 5.95 dust=1.53 dia + 0.12 blue_stones=0.31 dia + 0.03 purple_stones=0.94 dia + 1.49 dia=1.49 dia]

  puts "- 10 stargaze value: #{Value.show_dia_value(Value.stargaze(10), summons: false)}"
  # 10 stargaze value: 587.63 dia [0.25 choice_god=0.0 dia + 0.32 random_atier=0.0 dia + 0.1 random_fodder=0.0 dia + 30.0 dia=30.0 dia + 0.08 mythic_gear=42.0 dia + 5.78 dura_fragments=33.01 dia + 49.68 gold_h=99.36 dia + 22.03 xp_h=176.26 dia + 16.56 dust_h=207.0 dia] 
  #  With adjusted ratio of 0.99489: 10 stargaze value: 584.78 dia [0.25 choice_god=0.0 dia + 0.32 random_atier=0.0 dia + 0.1 random_fodder=0.0 dia + 30.0 dia=30.0 dia + 0.08 mythic_gear=41.79 dia + 5.75 dura_fragments=32.85 dia + 49.43 gold_h=98.85 dia + 21.92 xp_h=175.36 dia + 16.48 dust_h=205.94 dia]

  #puts "- 10 stargaze value: #{Value.show_dia_value(Value.stargaze(10))}"
  ## 10 stargaze value: 4827.07 dia [0.25 choice_god=3500.0 dia + 0.32 random_atier=599.04 dia + 0.1 random_fodder=140.4 dia + 30.0 dia=30.0 dia + 0.08 mythic_gear=42.0 dia + 5.78 dura_fragments=33.01 dia + 49.68 gold_h=99.36 dia + 22.03 xp_h=176.26 dia + 16.56 dust_h=207.0 dia]

  puts "- 10 summons value: #{Value.show_dia_value(Value.tavern_summon(10), summons: false)}"
  # 10 summons value: 96.14 dia [0.49 random_fodder=0.0 dia + 0.46 wishlist_atier=0.0 dia + 0.02 random_god=0.0 dia + 25.85 dust=6.64 dia + 827.04 hero_coins=0.0 dia + 0.1 random_atier=0.0 dia + 0.5 red_e=67.5 dia + 0.28 gold_e=8.57 dia + 0.7 silver_e=13.43 dia]
  # 10 summons value: 206.41 dia [0.49 random_fodder=0.0 dia + 0.46 wishlist_atier=0.0 dia + 0.02 random_god=0.0 dia + 25.85 dust=6.64 dia + 827.04 hero_coins=110.27 dia + 0.1 random_atier=0.0 dia + 0.5 red_e=67.5 dia + 0.28 gold_e=8.57 dia + 0.7 silver_e=13.43 dia]
  
  #puts "- 10 summons value: #{Value.show_dia_value(Value.tavern_summon(10))}"
  ## 10 summons value: 4217.73 dia [0.49 random_fodder=681.72 dia + 0.46 wishlist_atier=2950.4 dia + 0.02 random_god=192.0 dia + 25.85 dust=6.64 dia + 827.04 hero_coins=110.27 dia + 0.1 random_atier=187.2 dia + 0.5 red_e=67.5 dia + 0.28 gold_e=8.57 dia + 0.7 silver_e=13.43 dia]

  puts
  puts "*** Values: ***"
  puts Value.items_value
end
