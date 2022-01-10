Ratios=[0.0241, 0.4479, 0.528]
#With pity, the ratios should be [0.0461, 0.4370, 0.5169]
Pity_Timer=30

def random_from_ratios(ratios)
  r=Random.rand()
  t=0
  ratios.each_with_index do |v,i|
    t += v
    return i if r <= t
  end
  return nil
end

def simulate_pity(nb, ratio, pity_timer)
  t=0; pity=0
  (1..nb).each do
    pity+=1
    if pity==pity_timer
      t+=1
      pity=0
    else
      r=Random.rand()
      if r <= ratio
        t+=1
        pity=0
      end
    end
  end
  t*1.0/nb
end

def simulate(nb, ratios: Ratios)
  pity=0
  nb_elites=0; nb_rares=0; nb_commons=0;
  (1..nb).each do
    pity+=1
    if pity==Pity_Timer
      nb_elites+=1
      pity=0
    else
      r=random_from_ratios(ratios)
      case r
      when 0
        nb_elites+=1
        pity=0
      when 1
        nb_rares+=1
      when 2
        nb_commons+=1
      end
    end
  end
  return [nb_elites, nb_rares, nb_commons].map {|i| i*1.0/nb}
end
# simulate(100000000)
# => [0.04643793, 0.43771864, 0.51584343]
# [6] pry(main)> simulate(1000000000)
# => [0.046439274, 0.437630455, 0.515930271]
#With pity, the ratios should be [0.0461, 0.4370, 0.5169]

def simulate_increasing_pity(nb)
  ratio=0.02; pity_timer=70
  increase_v=0.01; start_increase=50
  t=0; pity=0
  pities=[0,0,0,0,0,0,0]
  pities_nb=[0,0,0,0,0,0,0]
  (1..nb).each do
    pity+=1
    case pity
    when 1
      pities_nb[0]+=1
    when 11
      pities_nb[1]+=1
    when 21
      pities_nb[2]+=1
    when 31
      pities_nb[3]+=1
    when 41
      pities_nb[4]+=1
    when 51
      pities_nb[5]+=1
    when 61
      pities_nb[6]+=1
    end
    if pity==pity_timer
      t+=1
      pities[6]+=1
      pity=0
    else
      r=Random.rand()
      increase = [0, increase_v*(pity-start_increase)].max
      if r <= ratio+increase
        t+=1
        pities[(pity-1)/10]+=1
        pity=0
      end
    end
  end
  p pities, pities_nb
  return t*1.0/nb, pities.each_with_index.map {|v,i| v*1.0/pities_nb[i]}
end
