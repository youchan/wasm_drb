module DRb
  class DRbConn
    POOL_SIZE = 16
    @pool = {}

    def self.open(remote_uri)
      conn = @pool[remote_uri]
      unless conn&.alive?
        conn = self.new(remote_uri)
        @pool[remote_uri] = conn
      end

      yield(conn)
    end

    def initialize(remote_uri)
      @uri = remote_uri
      @protocol = DRbProtocol.open(remote_uri, DRb::default_config)
    end
    attr_reader :uri

    def send_message(ref, msg_id, arg, b, &callback)
      @protocol.send_request(ref, msg_id, arg, b) do |stream|
        callback.call(@protocol.recv_reply(stream))
      end
    end

    def close
      @protocol.close
      @protocol = nil
    end

    def alive?
      return false unless @protocol
      @protocol.alive?
    end
  end
end
