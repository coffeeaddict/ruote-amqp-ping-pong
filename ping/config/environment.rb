# Be sure to restart your daemon when you modify this file

# Uncomment below to force your daemon into production mode
#ENV['DAEMON_ENV'] ||= 'production'

# Boot up
require File.join(File.dirname(__FILE__), 'boot')

# Auto-require default libraries and those for the current Rails environment.
Bundler.require :default, DaemonKit.env

DaemonKit::Initializer.run do |config|

  # The name of the daemon as reported by process monitoring tools
  config.daemon_name = 'ping'

  # Force the daemon to be killed after X seconds from asking it to
  # config.force_kill_wait = 30

  # Log backraces when a thread/daemon dies (Recommended)
  # config.backtraces = true

  # Configure the safety net (see DaemonKit::Safety)
  # config.safety_net.handler = :hoptoad
  # config.safety_net.hoptoad.api_key = ''
end
