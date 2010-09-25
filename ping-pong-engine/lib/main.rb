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


puts AMQP.settings.inspect
# AMQP.logging = true

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

# generice AMQP participant
engine.register_participant :amqp, RuoteAMQP::Participant

# Puts state and count
engine.register_participant :logger do |workitem|
  $stderr.puts "State: #{workitem.fields['state']}"
  $stderr.puts "Count: #{workitem.fields['count']}"
end

# Puts a workitem
engine.register_participant :error_logger do |workitem|
  $stderr.puts "Workitem: #{workitem.fields.inspect}"
end

# Set up the state and count
engine.register_participant :alpha do |wi|
  wi.fields['state'] = 'alpha'
  wi.fields['count'] = 0
end

pdef = Ruote.process_definition :name => 'simple' do
  # the main definition
  sequence :on_error => :shout do
    setup
    repeat do
      run
      _break :if => '${f:count} >= 6'
    end
  end

  # setup shop 
  define 'setup' do
    participant :alpha
    participant :logger
  end

  # perform a ping and a pong
  define 'run' do
    ping
    participant :logger
    pong
    participant :logger
  end

  # do ping
  define 'ping' do
    amqp :queue => 'ping', :command => '/ping/ping', :reply_queue => 'ruote_workitems'
  end

  # do pong
  define 'pong' do
    amqp :queue => 'pong', :command => '/pong/pong', :reply_queue => 'ruote_workitems'
  end

  # trap errors and log 'em
  define :shout do
    echo 'Error occured...'
    participant :error_logger
  end
end

wfid = engine.launch(pdef)
engine.wait_for(wfid)
