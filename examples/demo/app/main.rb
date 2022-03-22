require 'smaug.rb'

def tick args
  @world ||= GameWorld.new
  @world.tick args
end
