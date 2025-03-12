require_relative '../wasm_drb/websocket'
require_relative 'drb_message'

module DRb
  module WebSocket
    class SocketPool
      attr_reader :uri, :ws

      def initialize(uri, ws)
        @uri = uri
        @ws = ws
        @handlers = {}

        ws.onmessage do |event|
          message_data = event.data.to_s
          sender_id = message_data.slice(0, 36)
          message = message_data.slice(36, message_data.length - 36)
          @handlers.delete(sender_id).call(message)
        end
      end

      def self.open(uri)
        @sockets ||= {}
        @sockets[uri] ||= new_connection(uri)
      end

      def self.new_connection(uri)
        ws = WasmDRb::WebSocket.new(uri)

        ws.onclose do
          @sockets[uri] = new_connection(uri)
        end

        self.new(uri, ws)
      end

      def send(data, &block)
        sender_id = JS.global[:crypto].randomUUID().to_s
        @handlers[sender_id] = block
        byte_data = sender_id.bytes + data.bytes

        if @ws.connecting?
          listener = @ws.onopen do
            @ws.send(WasmDRb::ArrayBuffer.new(byte_data))
            @ws.remove_event_listener('open', &listener)
          end
        else
          @ws.send(WasmDRb::ArrayBuffer.new(byte_data))
        end
      end

      def [](uri)
        @sockets[uri].ws
      end
    end

    class StrStream
      def initialize(str='')
        @buf = str
      end
      attr_reader :buf

      def read(n)
        begin
          return @buf[0,n]
        ensure
          @buf = @buf[n, @buf.size - n]
        end
      end

      def write(s)
        @buf += s
      end
    end

    def self.uri_option(uri, config)
      return uri, nil
    end

    def self.open(uri, config)
      unless uri =~ /^ws:\/\/(.*?):(\d+)(\/(.*))?$/
        raise(DRbBadScheme, uri) unless uri =~ /^ws:/
        raise(DRbBadURI, 'can\'t parse uri:' + uri)
      end
      ClientSide.new(uri, config)
    end

    def self.open_server(uri, config)
      unless uri =~ /^ws:\/\/(.*?):(\d+)(\/(.*))?$/
        raise(DRbBadScheme, uri) unless uri =~ /^ws:/
        raise(DRbBadURI, 'can\'t parse uri:' + uri)
      end

      Server.new(uri, config)
    end

    class Server
      attr_reader :uri

      def initialize(uri, config)
        uuid = JS.global[:crypto].randomUUID()
        @uri = "#{uri}/#{uuid}"
        @config = config
        reconnect
      end

      def close
        @ws.close
      end

      def reconnect
        @ws.close if @ws

        @ws = WasmDRb::WebSocket.new(@uri)

        @ws.onclose do
          reconnect
        end

        @ws.onmessage do |event|
          message_data = event.data.to_s
          sender_id = message_data.slice(0, 36)
          message = message_data.slice(36, message_data.length - 36)
          stream = StrStream.new(message)
          server_side = ServerSide.new(stream, @config, uri)
          @accepter.call server_side

          send_data = WasmDRb::ArrayBuffer.new(sender_id.bytes + server_side.reply.bytes)
          @ws.send(send_data)
        end
      end

      def accept(&block)
        @accepter = block
      end
    end

    class ServerSide
      attr_reader :uri, :reply

      def initialize(stream, config, uri)
        @uri = uri
        @config = config
        @msg = DRbMessage.new(@config)
        @req_stream = stream
      end

      def close
      end

      def alive?; false; end

      def recv_request
        begin
          @msg.recv_request(@req_stream)
        rescue
          close
          raise $!
        end
      end

      def send_reply(succ, result)
        begin
          stream = StrStream.new
          @msg.send_reply(stream, succ, result)
          @reply = stream.buf
        rescue
          close
          raise $!
        end
      end
    end

    class ClientSide
      def initialize(uri, config)
        @uri = uri
        @pool = SocketPool.open(uri)
        @res = nil
        @config = config
        @msg = DRbMessage.new(@config)
      end

      def alive?
        !!@pool.ws && @pool.ws.open?
      end

      def close
      end

      def send_request(ref, msg_id, *arg, b, &block)
        stream = StrStream.new
        @msg.send_request(stream, ref, msg_id, *arg, b)
        send(@uri, stream.buf, &block)
      end

      def recv_reply(reply_stream)
        @msg.recv_reply(reply_stream)
      end

      def send(uri, data, &block)
        @pool.send(data) do |message|
          reply_stream = StrStream.new
          reply_stream.write(message.to_s)

          if @config[:load_limit] < reply_stream.buf.size
            raise TypeError, 'too large packet'
          end

          block.call reply_stream
        end
      end
    end
  end
end
