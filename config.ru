require 'drb/drb'
require 'drb/websocket'

class SampleObject
  def test
    "ACK!"
  end

  def set_callback(&callback)
    5.times do
      callback.call
      sleep 1
    end
  end
end

class SampleFactory
  def self.get
    DRbObject.new(SampleObject.new)
  end
end

DRb::WebSocket::RackApp.config.use_rack = true
DRb.start_service("ws://127.0.0.1:9292", SampleFactory)

app = DRb::WebSocket::RackApp.new(Proc.new {|env|
  case env['REQUEST_PATH']
  when '/'
    html = File.read('./index.html')
    [200, { 'content-type' => 'text/html' }, [html] ]
  when '/dist/browser.script.iife.js'
    js = File.read('./dist/browser.script.iife.js')
    [200, { 'content-type' => 'text/javascript' }, [js] ]
  when '/dist/app.wasm'
    js = File.read('./dist/app.wasm')
    [200, { 'content-type' => 'application/wasm' }, [js] ]
  else
    [404, {}, []]
  end
})

Rackup::Server.start app:app, Port: 9292
