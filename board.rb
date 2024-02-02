#! /usr/bin/env ruby

require 'pry'

# when printing, only show 3 decimals
class Float
  def pretty_print(pp)
    pp.pp(self.round(3))
  end
end

def pretty_print(object)
  Pry::ColorPrinter.pp(object)
  #PP.pp(object)
end

class Board
  class <<self
    attr_accessor :nb, :nb_simulate, :strats
  end
  @nb=10
  @nb_simulate=10000
  @strats=%i(simple gold advanced advanced3 optimal)

  module Helpers
    def random_from_ratios(ratios)
      total=ratios.sum
      r=(Random.rand()*total).floor
      t=0
      ratios.each_with_index do |v,i|
        t += v
        return i if r < t
      end
      return ratios.length-1 #should only happen if Random.rand()=1.0, ie never
    end
  end
  extend Helpers

  attr_accessor :nb, :max_nb, :double, :items, :items_Ratio, :values, :refresh_Cost, :multiplier, :diamond_Conversion, :nb_simulate

  def initialize(nb=Board.nb, double: false, nb_simulate: Board.nb_simulate)
    @nb=nb
    @max_nb=10
    @double=double

    # Board level 8
    @base_items=[:gold, :dust, :stones, :dia]
    @items=@base_items+[:juice,:shard]
    @items_Ratio=[3,3,1,1]
    @levels=[:legend,:mythic,:ascended]
    @levels_Ratio=[45,8,2]

    @item_level_ratios={}
    @base_items.each_with_index do |item, r1|
      @levels.each_with_index do |level, r2|
        r=@items_Ratio[r1]*@levels_Ratio[r2]
        case level
        when :mythic, :ascended
          item = :juice if item == :gold
          item = :shard if item == :stones
        end
        @item_level_ratios[[item, level]]=r
      end
    end
    [:gold, :stones].each do |item|
      [:mythic, :ascended].each do |level|
        @item_level_ratios[[item, level]]=0
      end
    end
    [:juice, :shard].each do |item|
      [:legend].each do |level|
        @item_level_ratios[[item, level]]=0
      end
    end

    @values={
      gold: [173, 246, 321],
      dust: [150, 500, 800],
      stones: [15, 25, 40],
      dia: [60, 100, 150],
      juice: [0, 5, 10],
      shard: [0, 5, 10],
    }
    @refresh_Cost=50

    @diamond_Conversion={
      #gold: 0.08481764 or 0.05,
      #gold: 1000/17540.0, #=0.057126
      gold: 1000/51867.0,
      #dust: 0.2568,
      dust: 0.1735,
      stones: 0.3889,
      dia: 1.0,
      shard: 6.75,
      juice: 6.75,
    }

    @nb_simulate=nb_simulate #default simulation iterations
  end

  def get_value(item,level)
    r=@values[item][@levels.rindex(level)]
    return r*2 if @double
    r
  end

  def diamond_value(item, level)
    diamond_v(get_value(item,level), item)
  end

  def diamond_v(qty, item)
    qty*@diamond_Conversion[item]
  end

  # average quest value
  def get_avg_value
    return @avg_value if @avg_value
    t=0.0
    #items_total=@items_Ratio.sum
    #levels_total=@levels_Ratio.sum
    #@items.each_with_index do |item, index|
    #  @levels.each_with_index do |level, index2|
    #    t += diamond_value(item, level)*@levels_Ratio[index2]/levels_total*@items_Ratio[index]/items_total
    #  end
    #end
    item_level_total=@item_level_ratios.values.sum
    @item_level_ratios.keys.each do |item, level|
      t += diamond_value(item, level)*@item_level_ratios[[item,level]]/item_level_total
    end
    @avg_value=t
  end

  # output an average quest proba
  def get_avg_quest
    return @avg_quest if @avg_quest
    #items_total=@items_Ratio.sum
    #levels_total=@levels_Ratio.sum
    avg={}
    #@items.each_with_index do |item, index|
    #  @levels.each_with_index do |level, index2|
    #    avg[[item,level]]=@items_Ratio[index]*@levels_Ratio[index2]*1.0/(items_total*levels_total)
    #  end
    #end
    item_level_total=@item_level_ratios.values.sum
    @item_level_ratios.keys.each do |item, level|
      avg[[item,level]] = @item_level_ratios[[item,level]]*1.0/item_level_total
    end
    @avg_quest=avg
  end

  # sample a new quest
  def new_quest
    #item=@items[Board.random_from_ratios(@items_Ratio)]
    #level=@levels[Board.random_from_ratios(@levels_Ratio)]
    i=Board.random_from_ratios(@item_level_ratios.values)
    item, level=@item_level_ratios.keys[i]
    return [item, level]
  end

  def new_quests(m)
    (1..m).map {|i| new_quest}
  end

  def refresh(quests, &b) # simple refresh strat
    if b
      u=b.call(quests) #should return quests to refresh and their index
    else
      avg_value=get_avg_value
      u=to_refresh(quests, avg_value)
      u=[] unless do_refresh?(u, avg_value)
    end
    if !u or u.empty? #we are done
      return quests, 0
    else
      new_quests=u.map {|_i| new_quest}
      refreshed, tries=refresh(new_quests, &b)
      refreshed.each_with_index do |q,i|
        #require 'pry'; binding.pry
        quests[u[i][1]]=q
      end
      return quests, 1+tries
    end
  end

  def to_refresh(quests, avg_value) # the quests to refresh (potentially)
    quests.each_with_index.select do |v,_i|
      diamond_value(*v) < avg_value
    end
  end

  def refresh_diamond_value(refresh)
    refresh.reduce(0) do |sum,v| #the dia value of the refreshable quests
      sum+diamond_value(*v[0])
    end
  end
  def do_refresh?(refresh, avg_value)
    binding.pry if avg_value==0.0
    avg_value*refresh.length - refresh_diamond_value(refresh) > @refresh_Cost #we should refresh
  end

  def init
    r={}
    @items.each do |item| #initialisation
      @levels.each do |level|
        r[[item,level]]=0
      end
    end
    r
  end

  def tally(quests) #tally each quest type (can be a float since we work with average quests)
    r=init
    quests.each do |q|
      r[q]+=1
    end
    r
  end

  def value_tally(avg_tally) #the diamond value of a tally
    avg_tally.reduce(0) do |sum, v| #v: [quest, coeff]
      sum + diamond_value(*v[0])*v[1]
    end
  end

  def refresh_dynamic(quests, avg_value, memo, tries: 0) #same as above except we memoize the results for a smaller number of quests
    # return the tally of the iterated refreshed board, the number of tries we did
    u=to_refresh(quests, avg_value)
    if u.length < quests.length #we can reuse our previous results
      new_avg_value=avg_value
      loop do
        break if u.length==0
        new_avg_value=memo[u.length][:average_value]
        u2=to_refresh(quests, new_avg_value)
        break if u2.length == u.length
        u=u2
      end
      if do_refresh?(u, new_avg_value)
        r=memo[u.length][:result].dup
        u_index=u.map {|q,i| i}
        quests.each_with_index do |q,i|
          #check if the quest is not in u
          r[q]+=1 unless u_index.include?(i)
        end
        return r, tries+1+memo[u.length][:average_tries]
      else #we are done
        return tally(quests), tries
      end
    else #we potentially refresh everything
      if do_refresh?(u, avg_value)
        u.map do |_v,i| #refresh quest slots
          quests[i]=new_quest
        end
        refresh_dynamic(quests, avg_value, memo, tries: tries+1)
      else #we are done
        return tally(quests), tries
      end
    end
  end

  def info_from_simulation(total, total_dia_std, tries, nb_simulate)
    r={}
    case tries
    when Array
      tries_distribution=tries
      total_tries=tries_distribution.each_with_index.reduce(0) {|sum, v| sum+(v[0]||0)*v[1]}
    else
      total_tries=tries
    end
    avg_tries=total_tries*1.0/nb_simulate
    avg={}; total.each do |k,v|
      avg[k]=v*1.0/nb_simulate
    end
    nb=avg.values.sum.round #nb quests we had
    r[:nb]=nb
    #cur_average_value=(value_tally(avg)-avg_tries*@refresh_Cost)/nb
    avg_quest={}; avg.each do |k,v|
      avg_quest[k]=v/nb
    end
    r[:result]=avg #average total number of quest type we add
    r[:average_tries]=avg_tries
    r[:average_tries_by_quest]=avg_tries/nb
    if tries_distribution
      tries_proba=[]
      tries_distribution.each_with_index do |v,i|
        tries_proba[i]=(v||0)*1.0/nb_simulate
      end
      r[:tries_distribution]=tries_proba
    end
    #r[:average_value]=cur_average_value
    r[:average_quest]=avg_quest #average quest, ie r[:result]/nb quests
    update_avg_quest_values(r)
    avg=r[:full_values][:total_with_refresh]
    # p total_dia_std/nb_simulate, avg**2
    std=Math.sqrt((total_dia_std/nb_simulate-avg**2*1.0)) rescue 0
    r[:std]=std
    r
  end

  def update_avg_quest_values(result)
    nb=result[:nb] || 1
    avg=result[:average_quest]
    avg_tries_q=result[:average_tries_by_quest]||0
    # result[:average_quest_v]={}
    # result[:average_quest].each do |k,v|
    #   result[:average_quest_v][k]=v*diamond_value(*k)
    # end
    avg_tries=avg_tries_q*nb
    full_value=value_tally(avg)
    real_value=full_value-avg_tries_q*@refresh_Cost
    #result[:full_value]=full_value
    values={}; total=0
    @items.each do |item|
      values[item]=0
      @levels.each do |level|
        values[item]+=avg[[item,level]]*get_value(item,level)
      end
      values[:"#{item}_v"]=diamond_v(values[item],item)
      total+=values[:"#{item}_v"]
    end
    values[:total_v]=total
    result[:values_by_quest]=values
    values_t={}
    result[:values_by_quest].each do |k,v|
      values_t[k]=v*nb
    end
    values_t[:dia_with_refresh]=values_t[:dia]-avg_tries*@refresh_Cost
    values_t[:total_with_refresh]=values_t[:total_v]-avg_tries*@refresh_Cost
    result[:full_values]=values_t
    result[:average_value]=real_value
    result
  end

  def avg_quest_info(nb=@nb)
    r={}
    r[:average_quest]=get_avg_quest
    r[:nb]=nb
    r[:quest_value]={}
    @items.each do |item|
      @levels.each do |level|
        r[:quest_value][[item,level]]=diamond_value(item,level)
      end
    end
    update_avg_quest_values(r)
    r
  end

  def simulate(nb=@nb, nb_simulate: @nb_simulate, verbose: true, &b)
    #avg_quest_info(nb)
    total=init; tries_distribution=[];
    total_dia_std=0
    (1..nb_simulate).each do |sim_nb|
      # $sim_nb=sim_nb
      quests,tries=refresh(new_quests(nb), &b)
      result=tally(quests)
      value=value_tally(result)-tries*@refresh_Cost
      # p value if value < 0 #the value can be negative!
      total_dia_std+=value**2
      result.each { |k,v| total[k]+=v }
      tries_distribution[tries] ||= 0
      tries_distribution[tries] += 1
    end
    result=info_from_simulation(total, total_dia_std, tries_distribution, nb_simulate)
    if verbose
      puts "# Average quest value for #{nb} quests using #{nb_simulate} simulations (double=#{@double})"
      pretty_print(result)
      puts
    end
    result
  end

  def simulate_dynamic(number=@max_nb, nb_simulates: [@nb_simulate,@nb_simulate,@nb_simulate], verbose: true)
    memo={}; result={}
    memo[0]=avg_quest_info(number) #standard quest without refreshing
    cur_average_value=memo[0][:average_value]
    #pretty_print(memo[0])
    (1..number).each do |nb|
      memo[nb]={}
      nb_simulates.each do |nb_simulate|
        total=init; tries_distribution=[];
        total_dia_std=0
        (1..nb_simulate).each do |sim_nb|
          result,tries=refresh_dynamic(new_quests(nb), cur_average_value, memo)
          result.each { |k,v| total[k]+=v }
          tries_distribution[tries] ||= 0
          tries_distribution[tries] += 1
          value=value_tally(result)-tries*@refresh_Cost
          total_dia_std+=value**2
        end
        result=info_from_simulation(total, total_dia_std, tries_distribution, nb_simulate)
        cur_average_value=result[:average_value]
        puts cur_average_value if verbose==:full
      end
      memo[nb]=result
      if verbose
        puts "# Average quest value for #{nb} quests using #{nb_simulates} simulations"
        pretty_print(memo[nb])
        puts
      end
    end
    return memo
  end

  module Strategies
    def show_average_quest(nb=@nb)
      puts "## Average quest without refresh (nb=#{nb})"
      r=avg_quest_info(nb)
      pretty_print(r)
      puts
    end

    ## Exemples of simulations
    ## refresh all quests that are below the ev; if the ev gained is greater than the refresh cost
    def simulate_simple(nb=@nb, **kw)
      puts
      puts "## Simulation with simple refresh strategy ##"
      simulate(nb, **kw) #40.619; double: 88.341
    end

    ## refresh gold quests if they are above the threshold
    def simulate_gold(nb=@nb, gold_threshold: nil, **kw)
      if gold_threshold.nil?
        gold_threshold=3
        gold_threshold=1 if @double
      end
      puts
      puts "## Simulation with gold refresh strategy (gold_threshold=#{gold_threshold}) ##"
      simulate(nb, **kw) do |quests|
        u=quests.each_with_index.select do |v,_i|
          v[0]==:gold
        end
        next false unless u.length >= gold_threshold
        u
      end
    end

    ## refresh all gold+stone quests
    def simulate_goldstones(nb=@nb, **kw)
      puts
      puts "## Simulation with gold and stones refresh strategy ##"
      simulate(nb, **kw) do |quests|
        u=quests.each_with_index.select do |v,_i|
          v[0]==:gold or v[0]==:stones
        end
        u
      end
    end

    def simulate_advanced(nb=@nb, threshold: nil, **kw)
      if threshold.nil? #default value
        threshold = @double ? 3 : 6
      end
      puts
      puts "## Simulation with advanced refresh strategy (threshold=#{threshold}) ##"
      simulate(nb, **kw) do |quests|
        eggdust=quests.count do |v|
          (v[0] == :dust or v[0] == :stones) && v[1] == :legend
        end
        gold=quests.count do |v|
          v[0] == :gold
        end
        total=eggdust+gold
        total=gold if total < threshold #do not refresh dustL eggL
        if @double
          gold_threshold=case total
                         when 5,6,7,8,9,10; 0
                         else; 1
                         end
        else
          next false if total <=1
          gold_threshold=case total
                         when 10; 0
                         when 9; 1
                         else; 2
                         end
        end
        next false if gold < gold_threshold
        quests.each_with_index.select do |v,_i|
          if @double && total == gold && total==1
            # if v[0] == :gold && v[1] != :legend
            #   $special ||=0
            #   $special +=1
            #   # puts "Special case: #{$special}/#{$sim_nb}"
            # end
            v[0] == :gold && v[1] == :legend
          else
            total != gold && (v[0] == :dust && v[1] == :legend or v[0] == :stones && v[1] == :legend) or v[0] == :gold
          end
        end #the quests to refresh
      end
    end

    def simulate_advanced2(nb=@nb, **kw)
      puts
      puts "## Simulation with advanced2 refresh strategy ##"
      simulate(nb, **kw) do |quests|
        eggdust=quests.count do |v|
          (v[0] == :dust or v[0] == :stones) && v[1] == :legend
        end
        gold=quests.count do |v|
          v[0] == :gold
        end
        goldL=quests.count do |v|
          v[0] == :gold && v[1] == :legend
        end
        dorefresh=false
        if @double
          dorefresh=true if goldL >= 1 or gold >=2 or gold >=1 && eggdust >=3 or eggdust >=5
        else
          dorefresh=true if goldL >= 2 or gold >=3 or gold >=2 && eggdust >=6 or eggdust >=10
        end
        next false unless dorefresh
        u=quests.each_with_index.select do |v,_i|
          (@double ? (gold+eggdust) >=3 : (gold+eggdust) >=6) && (v[0] == :dust && v[1] == :legend or v[0] == :stones && v[1] == :legend) or v[0] == :gold
        end
        u #the quests to refresh
      end
    end

    def simulate_advanced3(nb=@nb, **kw)
      puts
      puts "## Simulation with advanced3 refresh strategy ##"
      simulate(nb, **kw) do |quests|
        eggdust=quests.count do |v|
          (v[0] == :dust or v[0] == :stones) && v[1] == :legend
        end
        gold=quests.count do |v|
          v[0] == :gold
        end
        goldL=quests.count do |v|
          v[0] == :gold && v[1] == :legend
        end
        if @double
          threshold1=2; threshold2=0
        else
          threshold1=6; threshold2=1
        end
        total=eggdust+gold
        if total > threshold1 #we refresh medium quests
          quests.each_with_index.select do |v,_i|
            (v[0] == :dust && v[1] == :legend or v[0] == :stones && v[1] == :legend) or v[0] == :gold
          end #the quests to refresh
        elsif gold > threshold2 #we only refresh gold
          quests.each_with_index.select do |v,_i|
            v[0] == :gold
          end #the quests to refresh
        else
          next false #no refesh
        end
      end
    end

    def simulate_pure_dia(nb=@nb, **kw)
      puts
      puts "## Simulation with pure diamonds refresh strategy ##"
      simulate(nb, **kw) do |quests|
        u=quests.each_with_index.select do |v,_i|
            (v[0] != :dia)
        end #the quests to refresh
        next false unless u.length > 0
        u
      end
    end

    def simulate_optimal(nb=@nb, magic: nil, **kw)
      if magic.nil?
        magic=[44.00601, 42.62974, 41.21228, 39.85913, 38.65864, 37.80118, 37.03364, 36.33974, 35.80604, 35.7104].reverse
        magic=[111.87832, 108.88099, 105.49544, 101.62087, 97.28789, 92.36578, 87.08076, 81.40006, 75.58795, 71.4208].reverse if @double
      end

      puts
      puts "## Simulation with optimal refresh strategy ##"
      simulate(nb, **kw) do |quests|
        nbr=quests.length; u=quests; avg_value=0
        loop do
          avg_value=magic[nbr-1]
          u=to_refresh(quests, avg_value)
          break if u.length == nbr or u.length==0
          nbr=u.length
        end
        next false unless do_refresh?(u, avg_value)
        u
      end
    end
  end
  include Strategies

  module Compare
    # from the values of a standard (resp double) board, show average values long term
    def mix_values(r1, r2)
      r={}
      %i(values_by_quest full_values).each do |t|
        r[t]={}
        r1[t].each do |k,v|
          r[t][k]=v*2/3+r2[t][k]*1/3
        end
      end
      r[:average_value]=r1[:average_value]*2/3+r2[:average_value]*1/3
      r
    end

    def final_result_no_strat(nb=@nb, verbose: true)
      b1=self.clone
      b1.double=false
      b2=self.clone
      b2.double=true
      r1=b1.avg_quest_info
      r2=b2.avg_quest_info
      r=mix_values(r1,r2)
      if verbose==:full
        puts "## Full values across simple board (no refresh, nb=#{nb})"
        pretty_print(r1)
        puts
        puts "## Full values across double board (no refresh, nb=#{nb})"
        pretty_print(r2)
        puts
      end
      if verbose
        puts "## Full values across simple and double boards (no refresh, nb=#{nb})"
        pretty_print(r)
        puts
      end
      return r,r1,r2
    end

    def final_result(nb=@nb, strat: :optimal, **kw)
      b1=self.clone
      b1.double=false
      b2=self.clone
      b2.double=true
      r1=b1.send(:"simulate_#{strat}", nb, verbose: false, **kw)
      r2=b2.send(:"simulate_#{strat}", nb, verbose: false, **kw)
      r=mix_values(r1,r2)
      return r,r1,r2
    end

    def compare_strats(nb=@nb, strats: Board.strats, **kw)

      total_value=get_avg_value*nb
      total_value_double=get_avg_value*nb*2

      strats.each do |s|
        r,r1,r2=final_result(nb, strat: s, **kw)
        if kw[:verbose]
          puts "## Final result across simple and double boards"
          pretty_print(r)
          puts
        end
        new_total1=r1[:full_values][:total_with_refresh]
        new_total2=r2[:full_values][:total_with_refresh]
        diff1=new_total1-total_value
        diff2=new_total2-total_value_double
        puts "Advantage of strategy #{s} with #{nb} quests: #{(diff1*2/3+diff2*1/3).round(3)} (simple: #{diff1.round(3)}, double: #{diff2.round(3)})"
      end
    end
  end
  include Compare
end

if __FILE__ == $0
  Board.nb=10
  Board.nb=8
  #Board.nb_simulate=1000000
  Board.nb_simulate=100000

  board=Board.new
  board.final_result_no_strat(verbose: :full) #the values we get without refresh strat
  
  board.nb_simulate=1000000
  r=board.simulate_dynamic(10, nb_simulates: [100000,100000,Board.nb_simulate])
  magic = r.values.map do |rnb| rnb[:average_value] end
  puts magic
  board.double=true
  r=board.simulate_dynamic(10, nb_simulates: [100000,100000,Board.nb_simulate])
  magic = r.values.map do |rnb| rnb[:average_value] end
  puts magic

  board.compare_strats(strats: [:simple,:optimal], verbose: true)

  #Board.new.compare_strats(verbose: true)
  #Board.new.compare_strats(strats: [:advanced, :advanced2, :advanced3], verbose: true)
  #Board.new.compare_strats(strats: [:pure_dia], verbose: true)
  #Board.new.compare_strats(strats: [:advanced], verbose: true)
  #Board.new(8, double: true, nb_simulate: 1000000).simulate_advanced3
  #board.compare_strats(strats: [:simple,:goldstones,:optimal], verbose: true)

  # (8..10).each do |nb|
  #   board=Board.new(nb)
  #   board.show_average_quest
  #   board.simulate_simple
  #   board.simulate_gold
  #   board.simulate_advanced
  #   board.simulate_optimal
  #   board.simulate_dynamic(10, nb_simulates: [100000,100000,nb_simulate])
  #   board.final_result_no_strat(verbose: :full)
  #   board.compare_strats(strats: [:optimal], verbose: true)
  # end
end
