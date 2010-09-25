# Sample pseudo participant
#
# See http://gist.github.com/144861 for a test engine
class Ping < DaemonKit::RuotePseudoParticipant

  on_exception :dammit

  on_complete do |workitem|
    workitem['success'] = true
  end

  def ping
    workitem["state"] = "ping"
    count = Integer(workitem["count"]) rescue 0
    workitem["count"] = count + 1
  end

  def err
    raise ArgumentError, "Ping does not compute"
  end

  def dammit( exception )
    workitem["error"] = "pong: #{exception.message}"
  end

end
