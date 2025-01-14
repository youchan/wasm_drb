module DRb
  class DRbServer
    def initialize(uri, option)
      @protocol = DRbProtocol.open_server(uri, option)
      run
    end

    def uri
      @protocol.uri
    end

    def run
      @protocol.accept do |client|
        run
        begin
          succ = false
          invoke_method = InvokeMethod.new(self, client)
          succ, result = invoke_method.perform
          print_error(result) unless succ
          client.send_reply(succ, result)
        rescue Exception => e
          print_error(e)
        ensure
          client.close unless succ
          break unless succ
        end
      end
    end

    def print_error(e)
      puts e.message
      p e.backtrace
    end
  end
end

