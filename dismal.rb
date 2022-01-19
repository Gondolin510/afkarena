#!/usr/bin/ruby
$verbose=false

$rounding=2

def approx(p,q)
  (p*1.0/q).round($rounding)
end

def process(data, condition=nil)
  result={"2h gold": 0, "6h gold": 0, "2h xp": 0, "2h dust": 0,
          floor1: {shards: 0, cores: 0},
          floor2: {shards: 0, cores: 0},
          floor3: {shards: 0, cores: 0}}
  nb_cores=0; nb_shards=0
  nb_30=0; nb_50=0
  total=0

  dismaltype="regular"
  data.each_line do |line|
    line=line.chomp
    line.downcase!
    if line.empty?
      dismaltype="regular" #fallback
      next
    end
    reg_dismaltype=/(?<dismaltype>double|regular)\s+dismal/
    reg_amount=/\((?<amount>\d+)\)/
    reg_hours=/(?<hours>\d+)h/
    reg_type=/(?<type>dust|xp|gold)/
    reg_chests=/#{reg_amount}\s+#{reg_hours}\s+#{reg_type}/
    reg_floor=/floor\s+(?<floor>\d+)/
    reg_quantity=/\((?<quantity>\d+)\)\s+/
    reg_shardtype=/(?<shardtype>shards?|cores?)/
    reg_endlevel=/#{reg_floor}\s*-?\s*#{reg_quantity}#{reg_shardtype}/

    if (r=line.match(reg_dismaltype))
      dismaltype=r["dismaltype"]
      total+=1
      puts "Dismal type: #{dismaltype}" if $verbose
      p dismaltype
    elsif (r=line.match(reg_chests))
      amount=r["amount"].to_i
      hours=r["hours"]
      type=r["type"]
      key=:"#{hours}h #{type}"
      real_amount= dismaltype=="double" ? amount/2 : amount
      result[key]+=real_amount
      puts "- #{amount} x #{hours}h #{type}" if $verbose
      # p real_amount
      #require 'pry'; binding.pry
    elsif (r=line.match(reg_endlevel))
      floor=r["floor"]
      quantity=r["quantity"].to_i
      shardtype=r["shardtype"]
      shardkey=case shardtype
               when "cores","core"; :cores
               when "shards","shard"; :shards
               end
      nb_cores +=1 if shardkey == :cores
      nb_shards +=1 if shardkey == :shards
      real_quantity= dismaltype=="double" ? quantity/2 : quantity
      nb_30 +=1 if real_quantity == 30
      nb_50 +=1 if real_quantity == 50
      result[:"floor#{floor}"][shardkey]+=real_quantity
      puts "- Floor #{floor}: #{quantity} #{shardtype}" if $verbose
      # p real_quantity
    end
  end

  p result
  puts
  puts "Average (regular) run:"
  puts "2h gold: #{approx(result[:"2h gold"],total)}h"
  puts "2h xp: #{approx(result[:"2h xp"],total)}h"
  puts "2h dust: #{approx(result[:"2h dust"],total)}h"
  puts "6h gold: #{approx(result[:"6h gold"],total)}h"
  puts "gold:xp:dust ratio = #{approx(result[:"2h gold"],result[:"2h gold"]+result[:"2h xp"]+result[:"2h dust"])}:#{approx(result[:"2h xp"],result[:"2h gold"]+result[:"2h xp"]+result[:"2h dust"])}:#{approx(result[:"2h dust"],result[:"2h gold"]+result[:"2h xp"]+result[:"2h dust"])}"
  puts
  (1..3).each do |i|
    puts "Floor #{i}: #{approx(result[:"floor#{i}"][:shards],total)} shards and #{approx(result[:"floor#{i}"][:cores],total)} cores"
  end
  puts "Shards:Cores ratio = #{approx(nb_shards, nb_cores+nb_shards)}:#{approx(nb_cores, nb_cores+nb_shards)} [Shards: #{nb_shards}, Cores: #{nb_cores}]"
  puts "30:50 ratio = #{approx(nb_30, nb_30+nb_50)}:#{approx(nb_50, nb_30+nb_50)} [30x: #{nb_30}, 50x: #{nb_50}]"
end

$verbose=true
data=ARGF.read
process(data)
