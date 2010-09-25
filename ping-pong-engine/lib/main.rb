require 'rubygems'
require 'bundler'
Bundler.setup
require 'ruote'
require 'ruote/storage/fs_storage'
require 'ruote-amqp'


{ :host => 'localhost',
  :vhost => 'ruote',
  :user => 'ruote',
  :pass => 'ruote'
}.each { |k,v|
  AMQP.settings[k]=v
}


# puts AMQP.settings.inspect

# uncomment for lots of usefull information
# AMQP.logging = true

# listen to the ruote_workitems queue for return-messages
engine = Ruote::Engine.new(
  Ruote::Worker.new(
    Ruote::FsStorage.new("ruote_data")
  )
)

receiver = RuoteAMQP::Receiver.new(
  engine,
  :queue => "ruote_workitems",
  :launchitems => false
)

# generic AMQP participant
engine.register_participant :amqp, RuoteAMQP::Participant

# Puts state and count
engine.register_participant :logger do |workitem|
  $stderr.puts "State: #{workitem.fields['state']}"
  $stderr.puts "Count: #{workitem.fields['count']}"
end

# Set up the state and count
engine.register_participant :alpha do |wi|
  wi.fields['state'] = 'alpha'
  wi.fields['count'] = 0
end

# make 2 seperate MQ subscribers play ping pong with each other
pdef = Ruote.process_definition :name => 'simple' do
  # the main definition
  sequence :on_error => :shout do
    setup
    repeat do
      play
      _break :if => '${f:count} >= 6'
    end
  end

  # setup shop 
  define 'setup' do
    participant :alpha
    participant :logger
  end

  # perform a ping and a pong
  define 'play' do
    ping
    participant :logger
    pong
    participant :logger
  end

  # do ping
  define 'ping' do
    amqp :queue       => 'ping',
         :command     => '/ping/ping',
         :reply_queue => 'ruote_workitems'
  end

  # do pong
  define 'pong' do
    amqp :queue       => 'pong',
         :command     => '/pong/pong',
         :reply_queue => 'ruote_workitems'
  end

  # trap errors and log 'em
  define :shout do
    echo 'Error occured...'
  end
end

wfid = engine.launch(pdef)
engine.wait_for(wfid)

# show the errors
errs = engine.errors
if errs.size > 0
  puts "there are processes with errors :"
  errs.each do |err|
  puts "process #{err.wfid}"
  end
end
