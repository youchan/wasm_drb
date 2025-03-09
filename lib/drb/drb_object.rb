module DRb
  class DRbObject
    def self._load(s)
      uri, ref = Marshal.load(s)
      self.new_with(uri, ref)
    rescue Exception => e
      puts e.message
    end

    def self.new_with(uri, ref)
      it = self.allocate
      it.instance_variable_set(:@uri, uri)
      it.instance_variable_set(:@ref, ref)
      it
    end

    def self.new_with_uri(uri)
      self.new(nil, uri)
    end

    def _dump(lv)
      Marshal.dump([@uri, @ref])
    end

    def initialize(obj, uri=nil)
      @uri = nil
      @ref = nil
      if obj.nil?
        return if uri.nil?
        @uri, option = DRbProtocol.uri_option(uri, DRb::default_config)
        @ref = DRbURIOption.new(option) unless option.nil?
      else
        @uri = uri ? uri : DRb.current_server.uri
        @ref = obj ? DRb.to_id(obj) : nil
        DRbObject.id2ref[@ref] = obj
      end
    end

    def __drburi
      @uri
    end

    def __drbref
      @ref
    end

    def self.id2ref
      @id2ref ||= {}
    end

    def inspect
      @ref && @ref.inspect
    end

    def respond_to?(msg_id, priv=false)
      case msg_id
      when :_dump
        true
      when :marshal_dump
        false
      else
        false
      end
    end

    class DRbPromise
      class WrapedResolve
        attr_reader :data

        def initialize(resolve)
          @resolve = resolve
        end

        def apply(data)
          @data = data
          @resolve.apply
        end
      end

      class Outer
        def initialize(block)
          @inner_block = block
        end

        def wraped_resolve(resolve)
          @wraped_resolve = WrapedResolve.new(resolve)
        end

        def block
          Proc.new do |resolve|
            @inner_block.call(wraped_resolve(resolve))
          end
        end

        def data
          @wraped_resolve.data
        end
      end

      def initialize(&block)
        @outer = Outer.new(block)
        @promise = JS.global[:Promise].new(&@outer.block)
      end

      def then(&block)
        inner_block = Proc.new do
          block.call @outer.data
        end
        @promise.then(&inner_block)
      end

      def await
        @promise.await
        @outer.data
      end
    end

    def method_missing(msg_id, *a, &b)
      DRbPromise.new do |resolve|
        DRbConn.open(@uri) do |conn|
          conn.send_message(self, msg_id, a, b) do |succ, result|
            if succ
              resolve.apply result
            elsif DRbUnknown === result
              resolve.apply result
            else
              bt = self.class.prepare_backtrace(@uri, result)
              result.set_backtrace(bt + caller)
              resolve.apply result
              conn.close
            end
          end
        end
      end
    end

    def self.prepare_backtrace(uri, result)
      prefix = "(#{uri}) "
      bt = []
      result.backtrace.each do |x|
        break if /`__send__'$/ =~ x
        if /^\(druby:\/\// =~ x
          bt.push(x)
        else
          bt.push(prefix + x)
        end
      end
      bt
    end

    def pretty_print(q)
      q.pp_object(self)
    end

    def pretty_print_cycle(q)
      q.object_address_group(self) {
        q.breakable
        q.text '...'
      }
    end
  end

  class DRbURIOption
    def initialize(option)
      @option = option.to_s
    end
    attr_reader :option
    def to_s; @option; end

    def ==(other)
      return false unless DRbURIOption === other
      @option == other.option
    end

    def hash
      @option.hash
    end

    alias eql? ==
  end
end
