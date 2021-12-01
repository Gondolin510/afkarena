#!/usr/bin/ruby

require './economy'

def get_ff_value(stage, vip: 1, level: 1, towers: 1, show: false)
  s=Simulator.new do
    @DiaValues={dust: 300/1167.6}
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

=begin
s=Simulator.new do
  @stage = "18-06"
  @hero_level= 350
  @player_level=1
  @vip=1
  @tower_kt=@tower_4f=@tower_god=1
  @nb_ff=0
end
=end

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
#breakpoints=[50]
result=breakpoints.map do |b|
  stages.find {|s| get_ff_value(s) >= b }
end

puts result

