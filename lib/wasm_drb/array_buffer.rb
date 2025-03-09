require 'js'

module WasmDRb
  class ArrayBuffer
    def initialize(data)
      @js_array = JS.global[:Uint8Array].new(data)
    end

    def self.from_array(arr)
      @js_array = JS.global[:Uint8Array].new(arr.length)
      arr.each_with_index do |i, v|
        @js_array[i] = v
      end
    end

    def buffer
      @js_array[:buffer]
    end

    def length
      @js_array[:length]
    end

    def to_s
      @js_array.to_a.map do |d|
        d.to_i.chr
      end.join
    end
  end
end
