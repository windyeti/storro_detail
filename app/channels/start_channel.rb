class StartChannel < ApplicationCable::Channel
  def follow
    stream_from "start_process"
  end
end
