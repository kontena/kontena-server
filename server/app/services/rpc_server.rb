require_relative 'rpc/container_handler'
require_relative 'rpc/node_handler'
require_relative 'rpc/node_service_pod_handler'

class RpcServer
  include Celluloid
  include Logging

  HANDLERS = {
    'containers' => Rpc::ContainerHandler,
    'nodes' => Rpc::NodeHandler,
    'node_service_pods' => Rpc::NodeServicePodHandler,
    'node_volumes' => Rpc::NodeVolumeHandler
  }

  QUEUE_WARN_LIMIT = 500
  REPORT_EVERY = 60

  class Error < StandardError
    attr_accessor :code, :message, :backtrace

    def initialize(code, message, backtrace = nil)
      self.code = code
      self.message = message
      self.backtrace = backtrace
    end
  end

  attr_reader :handlers

  def initialize(queue)
    @queue = queue
    @handlers = {}
    @counter = 0
    @processing = false
    every(REPORT_EVERY) {
      report_queue
    }
  end

  def report_queue
    if @queue.size > QUEUE_WARN_LIMIT
      warn "#{@queue.size} messages in queue"
      info "#{@counter / REPORT_EVERY} requests per second"
    end
    @counter = 0
  end

  def process!
    @processing = true
    defer {
      while @processing && data = @queue.pop
        @counter += 1
        size = data.size
        if size == 2
          handle_notification(data[0], data[1])
        elsif size == 3
          handle_request(data[0], data[1], data[2])
        end
        Thread.pass
      end
    }
  end

  # @param [Faye::Websocket] ws_client
  # @param [String] grid_id
  # @param [Array] message msgpack-rpc request array
  # @return [Array]
  def handle_request(ws_client, grid_id, message)
    msg_id = message[1]
    handler = message[2].split('/')[1]
    method = message[2].split('/')[2]
    if actor = handling_actor(grid_id, handler)
      begin
        result = actor.send(method, *message[3])
        send_message(ws_client, [1, msg_id, nil, result])
      rescue RpcServer::Error => exc
        send_message(ws_client, [1, msg_id, {code: exc.code, message: exc.message}, nil])
        @handlers[grid_id].delete(handler)
      rescue => exc
        error "#{exc.class.name}: #{exc.message}"
        debug exc.backtrace.join("\n") if exc.backtrace
        send_message(ws_client, [1, msg_id, {code: 500, message: "#{exc.class.name}: #{exc.message}"}, nil])
        @handlers[grid_id].delete(handler)
      end
    else
      warn "handler #{handler} not implemented"
      send_message(ws_client, [1, msg_id, {code: 501, error: 'service not implemented'}, nil])
    end
  end

  # @param [String] grid_id
  # @param [Array] message msgpack-rpc notification array
  def handle_notification(grid_id, message)
    handler = message[1].split('/')[1]
    method = message[1].split('/')[2]
    if actor = handling_actor(grid_id, handler)
      begin
        debug "rpc notification: #{actor.class.name}##{method} #{message[2]}"
        actor.send(method, *message[2])
      rescue => exc
        error "#{exc.class.name}: #{exc.message}"
        error exc.backtrace.join("\n")
        @handlers[grid_id].delete(handler)
      end
    else
      warn "handler #{handler} not implemented"
    end
  end

  # @param [String] grid_id
  # @param [String] name
  def handling_actor(grid_id, name)
    return unless HANDLERS[name]

    @handlers[grid_id] ||= {}
    unless @handlers[grid_id][name]
      grid = Grid.find(grid_id)
      if grid
        @handlers[grid_id][name] = HANDLERS[name].new(grid)
      end
    end

    @handlers[grid_id][name]
  end

  # @param [Faye::Websocket] ws
  # @param [Object] message
  def send_message(ws, message)
    EM.next_tick {
      ws.send(MessagePack.dump(message.as_json).bytes)
    }
  end
end
