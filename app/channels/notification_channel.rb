class NotificationChannel < ApplicationCable::Channel
  def follow
    stream_from "finish_process"
  end
end
