# frozen_string_literal: true

require_relative "wasm_drb/version"

module WasmDRb
end

module DRb
  class DRbError < RuntimeError; end
  class DRbConnError < DRbError; end
  class DRbServerNotFound < DRbError; end
  class DRbBadURI < DRbError; end
  class DRbBadScheme < DRbError; end
end

require_relative 'wasm_drb/websocket'
require_relative 'wasm_drb/invoke_method'
require_relative 'wasm_drb/array_buffer'

require_relative 'drb/drb_websocket'
require_relative 'drb/drb_protocol'
require_relative 'drb/drb_conn'
require_relative 'drb/drb_object'
require_relative 'drb/drb_message'
require_relative 'drb/drb_server'
require_relative 'drb/drb'
