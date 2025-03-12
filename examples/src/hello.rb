require 'js'
require 'wasm_drb'

factory = DRb::DRbObject.new_with_uri 'ws://127.0.0.1:9292'
DRb.start_service("ws://127.0.0.1:9292/callback")

remote = factory.get.await

hello = remote.hello.await
hello_el = JS.global[:document].getElementById('hello')
hello_el[:innerText] = hello

increment_el = JS.global[:document].getElementById('increment')
increment_el.addEventListener('click') do
  remote.increment
end

value_el = JS.global[:document].getElementById('value')
remote.add_callback do |text|
  value_el[:innerText] = text
end

