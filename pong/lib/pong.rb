# Your starting point for daemon specific classes. This directory is
# already included in your load path, so no need to specify it.

class Pong < DaemonKit::RuotePseudoParticipant

  on_exception :dammit

  on_complete do |workitem|
    workitem['success'] = true
  end

  def pong
    workitem["state"] = "pong"
    count = Integer(workitem["count"]) rescue 0
    workitem["count"] = count + 1
  end

  def err
    raise ArgumentError, "Pong does not compute"
  end

  def dammit( exception )
    workitem["error"] = "ping: #{exception.message}"
  end

end
