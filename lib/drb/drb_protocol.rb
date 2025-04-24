module DRb
  module DRbProtocol
    @protocol = [DRb::DRbWebSocket] # default
  end

  module DRbProtocol
    def add_protocol(proto)
      @protocol.push(proto)
    end
    module_function :add_protocol

    def open_server(uri, config)
      @protocol.each do |proto|
        begin
          return proto.open_server(uri, config)
        rescue DRbBadScheme
        rescue DRbConnError
          raise($!)
        rescue
          raise(DRbConnError, "#{uri} - #{$!.inspect}")
        end
      end
      raise DRbBadURI, 'can\'t parse uri:' + uri
    end
    module_function :open_server

    def open(uri, config)
      @protocol.each do |proto|
        begin
          return proto.open(uri, config)
        rescue DRbBadScheme
        rescue DRbConnError => e
          raise e
        rescue => e
          raise(DRbConnError, "#{uri} - #{e.message}")
        end
      end
      raise DRbBadURI, 'can\'t parse uri:' + uri
    end
    module_function :open

    def uri_option(uri, config)
      @protocol.each do |proto|
        begin
          uri, opt = proto.uri_option(uri, config)
          return uri, opt
        rescue DRbBadScheme
        end
      end
      raise DRbBadURI, 'can\'t parse uri:' + uri
    end
    module_function :uri_option
  end
end
