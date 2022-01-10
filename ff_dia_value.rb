#!/usr/bin/ruby
# Gives the FF value breakpoints, ie at which stage we have more than
# 50/80/100/200/300 dia value for ff
# To run with `ruby -W0 ff_dia_value.rb` to quell the warnings
require './economy'

def get_ff_value(stage, vip: 1, level: 1, towers: 1, show: false)
  s=Simulator.new do
    @DiaValues={dust: 300/1167.6} #don't use a dynamic rate
    @stage = stage
    @hero_level= 350
    @player_level=level
    @vip=vip
    @tower_kt=@tower_4f=@tower_god=towers
    @nb_ff=0
  end
  s.ff_summary if show
  s.ff_value
end

stages=[]
(1..19).each do |i|
  (1..40).each do |j|
    stages << "#{"%02d" % i}-#{j}"
  end
end
(20..40).each do |i|
  (1..60).each do |j|
    stages << "#{"%02d" % i}-#{j}"
  end
end

breakpoints=[50, 80, 100, 200, 300]
i=0; b=breakpoints[i]
stages.each do |s|
  value=get_ff_value(s)
  if value >= b
    puts "Breakpoint for FF dia value #{b}: #{s}"
    i+=1; b=breakpoints[i]
  end
  break if i >= breakpoints.length
end

# result=breakpoints.map do |b|
#   stages.find {|s| get_ff_value(s) >= b }
# end
# puts result

