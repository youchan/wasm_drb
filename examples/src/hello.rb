require 'js'
require 'wasm_drb'

factory = DRb::DRbObject.new_with_uri 'ws://127.0.0.1:9292'
DRb.start_service("ws://127.0.0.1:9292/callback")

puts factory.hello.await

remote = factory.get.await
p remote.class

5.times do
  puts remote.test.await
end

remote.set_callback do
  puts "got callback"
end

