V1::GridsApi.route('grid_stats') do |r|

  # GET /v1/grids/:id/stats
  r.get do
    r.is do
      to = (r.params["to"] ? Time.parse(r.params["to"]) : Time.now).utc
      from = (r.params["from"] ? Time.parse(r.params["from"]) : (to - 1.hour)).utc

      @node_stats = Metrics::GridMetrics.fetch(@grid.id, from, to)
      render('grid_stats/stats')
    end

    r.on 'containers' do
      @stats = GridStat.container_count(@grid.id, DateTime.now - 1.day, DateTime.now)
      render('grid_stats/containers')
    end

    r.on 'memory_usage' do
      @stats = GridStat.memory_usage(@grid.id, DateTime.now - 1.day, DateTime.now)
      @metric = 'memory'
      render('grid_stats/usages')
    end

    r.on 'cpu_usage' do
      @stats = GridStat.cpu_usage(@grid.id, DateTime.now - 1.day, DateTime.now)
      @metric = 'cpu'
      render('grid_stats/usages')
    end

    r.on 'filesystem_usage' do
      @stats = GridStat.filesystem_usage(@grid.id, DateTime.now - 1.day, DateTime.now)
      @metric = 'filesystem'
      render('grid_stats/usages')
    end
  end
end
