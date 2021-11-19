#!/usr/bin/ruby
$verbose=false
$debug=false
$max_pos=23 #maxes out at 23 chests
$rounding=2

def chests_from_amount(amount)
  eval(amount.tr('x','*'))
end

def base_amount(amount)
  amount.match(/(\d+)\s*x/)[1].to_i
end

def diamond_chests(chests)
  r={green: 0, blue: 0, purple: 0}
  {green: 'g', blue: 'b', purple: 'p'}.each do |k,v|
    chests.match(/(\d+)#{v}/) do |m|
      r[k]=m[1].to_i
    end
  end
  r
end

def detailed_diamond_chests(chests)
  result={}
  #p chests.split(/(?:,\s*|\s+)/)
  chests.split(/(?:,\s*|\s+)/).each do |pos|
    r=pos.match(/(?<pos>\d+):(?<type>[gbp])/)
    #p pos; p r
    type = case r["type"]
           when 'g'; :green
           when 'b'; :blue
           when 'p'; :purple
           end
    result[r["pos"].to_i]=type
  end
  return result
end

def merge_detailed_info(current, detailed)
end

def approx(p,q)
  (p*100.0/q).round($rounding)
end

def analyze_chest(chest_dia)
  green=chest_dia[:green]
  blue=chest_dia[:blue]
  purple=chest_dia[:purple]
  total=chest_dia[:total]
  sum=green+blue+purple
  r="#{sum}/#{total}=#{approx(sum,total)}%"
  r+=" G:B:P=#{green}:#{blue}:#{purple}=#{approx(green,sum)}%:#{approx(blue,sum)}%:#{approx(purple,sum)}%"
  r
end

def analyze(diamonds, pre: nil)
  txt=""
  txt="[#{pre}] " if pre
  diamonds.each_with_index do |chest_dia,i|
    next if !$detailed && i!=0
    i="Total" if i==0
    txt+="#{i} => #{analyze_chest(chest_dia)}\n"
  end
  txt
end

def process(data, condition=nil)
  type=amount=chests=nil
  diamonds_q={green: 0, blue: 0, purple: 0, total: 0}
  diamonds=[]
  (0..$max_pos).each do |i| #pos 0 mean all possible positions
    diamonds[i]=diamonds_q.dup
  end

  data.each_line do |line|
    line=line.chomp
    line.downcase!
    if line.empty?
      type=amount=chests=nil
      next
    end
    line.sub!(/\(.*\)$/,'') #strip comments
    line.split(/[|;]/).each do |data|
      chests_regexp=/(?<chests>(\d+\s*[gbp]?,?\s*)+)/
      detailed_chests_regexp=/(?<detailed>(\d+:[gbp],?\s*)+)/
      allchests_regexp=/(?<allchests>#{detailed_chests_regexp}|#{chests_regexp})/
      amount_regexp=/\[?\s*(?<amount>((\d+\s*x\s*\d+\s*)\+?)+)\s*\]?\s*(?:[:-]\s*|\s+)/
      amount_chests_regexp=/(?:#{amount_regexp})?#{allchests_regexp}/
      type_regexp=/((?<type>wrizz|soren)\s+)/
      final_regexp=/#{type_regexp}?#{amount_chests_regexp}/
      #u=line.match(chests_regexp)
      if (r=data.match(final_regexp))
        #require 'pry'; binding.pry
        if $debug
          p data; p r
        end
        r["type"] && type=r["type"]
        r["amount"] && amount = r["amount"]
        r["allchests"] && chests=r["allchests"]
        if condition && amount && chests
          base=base_amount(amount)
          amount=nil if not eval(condition)
        end
      else
        type=amount=chests=nil
      end
      if amount && chests
        puts "#{amount} -> #{chests}" if $verbose
        total_chests = chests_from_amount(amount)
        # p total_chests
        diamonds[0][:total]+=total_chests
        if r["detailed"]
          dia=detailed_diamond_chests(chests)
          dia.each do |k,v|
            diamonds[k][v]+=1
            diamonds[0][v]+=1
          end
          (1..total_chests).each do |i|
            diamonds[i][:total]+=1
          end
        else
          dia=diamond_chests(chests)
          # p dia
          dia.each_key do |k|
            diamonds[0][k]+=dia[k]
          end
        end
      end
      puts "---" if $debug
    end
  end
  puts analyze(diamonds, pre: condition)
end

#$debug=true
#$verbose=true
data=ARGF.read
$detailed=false
process(data)
process(data, "base <= 18")
process(data, "base > 18")
process(data, "type == 'wrizz'")
process(data, "type == 'soren'")

$detailed=true
process(data)
