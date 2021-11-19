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

      dura_fragment: 100 * gold_conversion,
      class_fragment: 9000 * 0.675 / 400,

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

end

if __FILE__ == $0
  arena_fight = {
    gold: 90*0.495, dust: 10*0.495+500*0.01*0.2,
    blue_stones: 60*0.01*0.2, purple_stones: 10*0.01*0.3,
    dia: (150*0.15+300*0.12+3000*0.03)*0.01
  }
  puts "Arena ticket value: #{Value.show_dia_value(arena_fight)}"
end
