module DRb
  class DRbError < RuntimeError; end
  class DRbConnError < DRbError; end
  class DRbServerNotFound < DRbError; end
  class DRbBadURI < DRbError; end
  class DRbBadScheme < DRbError; end
end

require_relative 'drb/websocket'
require_relative 'drb/drb_protocol'
require_relative 'drb/drb_conn'
require_relative 'drb/drb_object'
require_relative 'drb/drb_message'
require_relative 'drb/invoke_method'
require_relative 'drb/drb_server'
require_relative 'drb/drb'
