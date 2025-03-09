require 'js'
require_relative 'array_buffer'

module WasmDRb
  class WebSocket
    def initialize(uri)
      @js_ws = JS.global[:WebSocket].new(uri)
      @js_ws[:binaryType] = 'arraybuffer'

      @listeners = {}
    end

    def onmessage(&block)
      listener = Proc.new {|event| yield MessageEvent.new(event) if self.open? }
      @listeners[block] = [:message, listener]
      add_event_listener('message', &listener)
    end

    def onopen(&block)
      listener = Proc.new {|_event| yield }
      @listeners[block] = [:open, listener]
      add_event_listener('open', &listener)
      listener
    end

    def onclose(&block)
      listener = Proc.new {|_event| yield }
      @listeners[block] = [:close, listener]
      add_event_listener('close', &listener)
    end

    def off handler
      remove_event_listener(*@listeners[handler])
    end

    def connecting?
      @js_ws[:readyState] == 0
    end

    def open?
      @js_ws[:readyState] == 1
    end

    def closing?
      @js_ws[:readyState] == 2
    end

    def closed?
      @js_ws[:readyState] == 3
    end

    # alias_native
    def close
      @js_ws.close
    end

    def send mesg
      @js_ws.call(:send, mesg.buffer)
    end

    def add_event_listener(type, &listener)
      @js_ws.addEventListener(type, &listener)
    end

    def remove_event_listener(type, &listener)
      @js_ws.removeEventListener(type, &listener)
    end

    class MessageEvent
      def initialize(js_event)
        @js_event = js_event
      end

      def data
        ArrayBuffer.new(@js_event[:data])
      end
    end

  end
end
