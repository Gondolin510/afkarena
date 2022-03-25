#!/usr/bin/env ruby

module Helpers
  extend self
  @@rounding=2
  def round(p, prec: @@rounding)
    r=p.round(prec)
    r == r.to_i ? r.to_i : r rescue r #coerce to int if possible
  end
  def percent(r)
    "#{(r*100).round}%"
  end

  def non_zero(r)
    r.abs >= 1e-10
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

  def show_items(items, separator: ' + ', empty: '0')
    return empty if items.respond_to?(:empty?) && items.empty?
    case items
    when Hash
      items.map do |k,v| 
        "#{rounded_v(v,k)} #{k}"
      end.join(separator)
    else
      [*items].map {|i| round(i)}.join(separator)
    end
  end
end

module Value
  include Helpers
  extend self

  def gold_conversion #convert 1K gold into dia
    #2250K gold = 500 dust. 24h dust=300 dia=1167.6 dust
    (500.0/2250) / (1167.6/300)
  end

  def raw_idle_hourly
    {gold: 27, xp: 43.5, dust: 48.65} 
    #to get correct result we need the specific player income here, this is for converting gold:xp/dust into gold_h/xp_h/dust_h
    #i am using values from chap 37, gold and xp are in K
  end

  def items_value(summons: true, values: {}) #values if for user supplied values
    scroll=270
    value = {
      dia: 1,
      gold: gold_conversion,
        #Alternative: gold: 2 / raw_idle_hourly[:gold]
      xp: 8 / raw_idle_hourly[:xp], #24h xp=192 dia, 1h xp=8 dia
      dust: 12.5 / raw_idle_hourly[:dust], #24h dust=300 dia, 1h dust=12.5
        #Alternative: dust caps out at 1167.6 dust by day, ie 48.65 by hour
      # dust: 300/1167.6,
      gold_h: 2, #24h gold=48 dia, 1h gold=2 dia
      gold_hg: 2, #Alternative: raw_idle_hourly[:gold]*gold_conversion,
      xp_h: 8,
      dust_h: 12.5,

      poe: 0.675,
      twisted: 6.75,
      silver_e: 10080.0/30 * gold_conversion,
      gold_e: 10920.0 /20 * gold_conversion,
      red_e: 135,
      dim_emblems: 135,
      faction_emblems: 135,
      shards: 2000/20 *gold_conversion, #=5.709. Or 6.75=135/20
      cores: (7500 / 48.65 + 380) * 12.5 / 585, #=11.41. Or 13.5=135/10

      dura_fragments: 100 * gold_conversion, #=5.709
      class_fragments: 9000 * 0.675 / 400, #=15.1875

      mythic_gear: 500,
      reset_scrolls: 250,
      dim_gear: 500,
      t1: 1000,
      t2: 2000,
      t1t2_chest: 2000,
      t3: 3000,
      t1t2t3_chest: 3000,
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

      arena_tickets: 50*gold_conversion, #=2.854
      dura_tears: 10*gold_conversion, #=0.57
      reset_scroll: 6000*gold_conversion, #=342.58

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

    value.merge(values)
  end

  def dia_value(items, debug: false, **kw)
    sum=0
    values=items_value(**kw)
    items.each do |k,v|
      p "Missing value for #{k}" unless values.key?(k) if debug
      value=v*(values[k]||0)
      sum+=value
    end
    return sum
  end

  def rounded_v(v, k=nil)
    value="#{round(v)}"
    value+="K" if k==:gold or k==:xp
    value
  end

  def detailed_dia_value(items, debug: false, skip_null: false, **kw)
    o=[]; sum=0
    values=items_value(**kw)
    items.each do |k,v|
      p "Missing value for #{k}" unless values.key?(k) if debug
      value=v*(values[k]||0)
      sum+=value
      o.push("#{rounded_v(v, k)} #{k}=#{round(value)} dia") unless skip_null and (value == 0.0 or value == 0)
    end
    return [sum, o]
  end
  def show_dia_value(items, details: true, **kw)
    total, o=detailed_dia_value(items, **kw)
    s="#{round(total)} dia"
    s+=" [#{o.join(' + ')}]" if details
  end

  def dia_value_h(items, **kw)
    r={}
    values=items_value(**kw)
    items.each do |k,v|
      value=v*(values[k]||0)
      r[k]=value
    end
    r
  end
  def sort_dia_value(items, pretty: true, **kw)
    r=dia_value_h(items,**kw).sort {|a,b| a[1] <=> b[1]}.reverse
    if pretty
      r.each do |k,v|
        puts "- #{items[k]} #{k}: #{round(v)} dia"
      end
    end
    r
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
    { random_fodder: n * 0.4370/9.0,
      wishlist_atier: n * 0.0461, #1 out of 21.69
      random_god: n*0.002,
      dust: common_summons*5,
      hero_coins: common_summons*160,
      #
      faction_purple_card: n/100.0, #purple card with faction choice
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
  def faction_summon(n=1)
    r=tavern_summon(n)
    wl=r.delete(:wishlist_atier)
    r[:faction_atier]=wl
    fodder=r.delete(:random_fodder)
    r[:faction_fodder]=fodder
    r
  end
  def stargaze(n=1)
    real_proba=1/40.0 #the given stargazing proba is 2% but in truth it is 1 out of 40 due to pity; so we need to adjust the other probas, except the diamond one
    diamond_proba=0.0001
    ratio=(1.0-real_proba-diamond_proba)/(1.0-0.02-diamond_proba)
    #p ratio
    { choice_god: n/40.0,
      purple_card: n * 4*ratio*0.008, #purple card
      blue_card: n * 4*ratio*0.0225/9.0, #blue card
      #
      dia: n*30000*diamond_proba,
      mythic_gear: n * 12*ratio*0.0007,
      dura_fragments: n * 7* ratio*(15*0.0018+5*0.0056+1*0.0276),
      gold_h: n * ratio*(2*24*0.045+5*6*0.0936),
      xp_h: n * ratio*(1*24*0.045+2*6*0.0936),
      dust_h: n * ratio*(2*8*0.045+5*2*0.0936),
      arena_tickets: n * ratio*(2*0.0501)
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
    idle=get_idle_data
    max_chap=idle.keys.max
    chap,level=stage.split('-')
    chap=chap.to_i; level=level.to_i
    if chap>max_chap
      warn "[Warning]: no idle data for Chapter #{chap}, falling back to data from Chapter #{max_chap}"
      chap=max_chap
    end
    prev_chap=chap-1
    prev_chap = 1 if chap==1
    prev_idle=get_idle_data[prev_chap]
    cur_idle=get_idle_data[chap]
    nb_stages=60
    nb_stages=40 if chap<20
    ratio=level*1.0/nb_stages
    idle={}
    cur_idle.each do |k,v|
      idle[k]=prev_idle[k]*(1-ratio)+cur_idle[k]*ratio
    end
    idle
  end

  def get_hero_level_stats
    @__level_stats if @__level_stats
    @__level_stats={}
    r=File.readlines("data/level_stats.csv")
    levels=r[0].split(',').length-1
    gold=r[2].split(',').map {|v| v.to_i} #the first element is the label
    xp=r[3].split(',').map {|v| v.to_i}
    dust=r[4].split(',').map {|v| v.to_i}
    (1..levels).each do |i|
      #below 240 this is the cost for one hero
      _gold=gold[i]/1000.0 #we work in k
      _xp=xp[i]/1000.0
      _dust=dust[i]
      #above 240 this is the cost for one crystal upgrade (for gold and xp), so we need to mult by 10 to get the full cost
      if i>=240
        _gold*=10
        _xp*=10
      end
      @__level_stats[i]={gold: _gold, xp: _xp, dust: _dust}
    end
    @__level_stats
  end
end

if __FILE__ == $0
  puts "- Arena ticket value: #{Value.show_dia_value(Value.arena_fight(1))}"
  # Arena ticket value: 6.81 dia [44.55 gold=2.54 dia + 5.95 dust=1.53 dia + 0.12 blue_stones=0.31 dia + 0.03 purple_stones=0.94 dia + 1.49 dia=1.49 dia]

  puts "- 10 stargaze value: #{Value.show_dia_value(Value.stargaze(10), summons: false)}"
  # 10 stargaze value: 587.63 dia [0.25 choice_god=0.0 dia + 0.32 random_atier=0.0 dia + 0.1 random_fodder=0.0 dia + 30.0 dia=30.0 dia + 0.08 mythic_gear=42.0 dia + 5.78 dura_fragments=33.01 dia + 49.68 gold_h=99.36 dia + 22.03 xp_h=176.26 dia + 16.56 dust_h=207.0 dia] 
  #  With adjusted ratio of 0.99489: 10 stargaze value: 584.78 dia [0.25 choice_god=0.0 dia + 0.32 random_atier=0.0 dia + 0.1 random_fodder=0.0 dia + 30.0 dia=30.0 dia + 0.08 mythic_gear=41.79 dia + 5.75 dura_fragments=32.85 dia + 49.43 gold_h=98.85 dia + 21.92 xp_h=175.36 dia + 16.48 dust_h=205.94 dia]
  # Summary: 10 stargaze has real cost of 5000-584.78=4415
  # A celo costs 4*4415=17660

  #puts "- 10 stargaze value: #{Value.show_dia_value(Value.stargaze(10))}"
  ## 10 stargaze value: 4827.07 dia [0.25 choice_god=3500.0 dia + 0.32 random_atier=599.04 dia + 0.1 random_fodder=140.4 dia + 30.0 dia=30.0 dia + 0.08 mythic_gear=42.0 dia + 5.78 dura_fragments=33.01 dia + 49.68 gold_h=99.36 dia + 22.03 xp_h=176.26 dia + 16.56 dust_h=207.0 dia]
  # Summary: with 4f summons, 10 stargaze has real cost of 5000-4827+3500=3673
  # A celo costs 4*3673=14692

  puts "- 10 summons value: #{Value.show_dia_value(Value.tavern_summon(10), summons: false)}"
  # 10 summons value: 96.14 dia [0.49 random_fodder=0.0 dia + 0.46 wishlist_atier=0.0 dia + 0.02 random_god=0.0 dia + 25.85 dust=6.64 dia + 827.04 hero_coins=0.0 dia + 0.1 random_atier=0.0 dia + 0.5 red_e=67.5 dia + 0.28 gold_e=8.57 dia + 0.7 silver_e=13.43 dia]
  # 10 summons value: 206.41 dia [0.49 random_fodder=0.0 dia + 0.46 wishlist_atier=0.0 dia + 0.02 random_god=0.0 dia + 25.85 dust=6.64 dia + 827.04 hero_coins=110.27 dia + 0.1 random_atier=0.0 dia + 0.5 red_e=67.5 dia + 0.28 gold_e=8.57 dia + 0.7 silver_e=13.43 dia] {with hero coins included}
  # Summary: 10 4f summons cost 2700-206.41=2493 dia
  # So a 4f hero costs 2.169*2493=5407 dia
  
  #puts "- 10 summons value: #{Value.show_dia_value(Value.tavern_summon(10))}"
  ## 10 summons value: 4217.73 dia [0.49 random_fodder=681.72 dia + 0.46 wishlist_atier=2950.4 dia + 0.02 random_god=192.0 dia + 25.85 dust=6.64 dia + 827.04 hero_coins=110.27 dia + 0.1 random_atier=187.2 dia + 0.5 red_e=67.5 dia + 0.28 gold_e=8.57 dia + 0.7 silver_e=13.43 dia]
  # Summary: with fodder summons, 10 4f summons cost
  # 2700-4217.73+2950.4=1432, so a 4f hero cost 2.169*1432=3106

  puts
  puts "*** Values: ***"
  puts Value.items_value
  # puts "*** Level stats: ***"
  # puts Data.get_hero_level_stats
end

=begin
load "value.rb"
Value.sort_dia_value({red_e: 2, gold_e: 6, silver_e: 10, poe: 400, blue_stones: 120, shards: 40, twisted: 40, faction_scrolls: 1, xp_h: 32, dust_h: 32, gold: 2000})
- dust_h: 400 dia
- blue_stones: 312 dia
- faction_scrolls: 270 dia
- twisted: 270 dia
- poe: 270 dia
- red_e: 270 dia
- xp_h: 256 dia
- shards: 228.39 dia
- silver_e: 191.85 dia
- gold_e: 187.05 dia
- gold: 114.19 dia
Value.sort_dia_value({cores: 75, stargazers: 3, scrolls: 5, red_e: 8, gold_e: 24, silver_e: 40, poe: 1500, blue_stones: 480, shards: 150, twisted: 150, faction_scrolls: 3, xp_h: 120, dust_h: 120, gold: 7500})
- dust_h: 1500 dia
- stargazers: 1500 dia
- scrolls: 1350 dia
- blue_stones: 1248 dia
- red_e: 1080 dia
- poe: 1012.5 dia
- twisted: 1012.5 dia
- xp_h: 960 dia
- shards: 856.46 dia
- cores: 856.03 dia
- faction_scrolls: 810 dia
- silver_e: 767.39 dia
- gold_e: 748.2 dia
- gold: 428.23 dia
=end
