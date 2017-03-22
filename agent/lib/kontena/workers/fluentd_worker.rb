require 'fluent-logger'

module Kontena::Workers
  class FluentdWorker
    include Celluloid
    include Celluloid::Notifications
    include Kontena::Logging
    include Kontena::Observer

    attr_reader :fluentd, :node_name, :queue

    ##
    # @param [Queue] queue
    # @param [Boolean] autostart
    def initialize(autostart = true)
      @fluentd = nil
      @queue = []
      @forwarding = false
      info 'initialized'
      subscribe('container:log', :on_log_event)

      observe(node: Actor[:node_info_worker]) do
        configure(@node)
      end
    end

    # @param [Node] node
    def configure(node)
      node_name = node.name
      driver = node.grid.dig('logs', 'forwarder')
      if driver == 'fluentd'
        fluentd_address = node.grid.dig('logs', 'opts', 'fluentd-address')
        info "starting fluentd log streaming to #{fluentd_address}"
        host, port = fluentd_address.split(':')
        @fluentd = Fluent::Logger::FluentLogger
          .new("#{node_name}.#{node.grid['name']}",
              :host => host,
              :port => port || 24224)
        @forwarding = true
      elsif @forwarding
        info "stopping fluentd log streaming"
        @fluentd.close if @fluentd
        @forwarding = false
        @fluentd = nil
      end
    end

    def on_log_event(topic, log)
      if @forwarding && @fluentd
        tag = [log[:stack], log[:service], log[:instance]].join('.')
        record = {
          log: log[:data], # the actual log event
          source: log[:type] # stdout/stderr
        }
        @fluentd.post(tag, record)
      end
    end
  end
end
