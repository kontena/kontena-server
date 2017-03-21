json.stats @stats.each do |stat|
  json.container_id stat[:container].name
  if !stat[:stats].nil?
    json.cpu do
      json.usage stat[:stats].cpu['usage_pct']
      json.limit stat[:stats].spec['cpu']['limit']
      json.num_cores ContainerStat.calculate_num_cores(stat[:stats].spec['cpu']['mask'])
    end
    json.memory do
      json.usage stat[:stats].memory['usage']
      json.limit stat[:stats].spec['memory']['limit']
    end
    json.network do
      json.name stat[:stats].network['name']
      json.rx_bytes stat[:stats].network['rx_bytes']
      json.tx_bytes stat[:stats].network['tx_bytes']
    end
  else
    json.cpu nil
    json.memory nil
    json.network nil
  end
end
