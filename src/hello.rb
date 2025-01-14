require 'js'
require_relative 'wasm_drb'

factory = DRb::DRbObject.new_with_uri 'ws://127.0.0.1:9292'
DRb.start_service("ws://127.0.0.1:9292/callback")

=begin
factory.get.then do |remote|
  puts "############## then"
  p remote.class
  5.times do
    remote.test.then do |v|
      puts v
    end
    sleep 1
  end

  remote.set_callback do
    puts "got callback"
  end
end
=end

Fiber.new do
  remote = factory.get.await
  puts remote.test
end.transfer
