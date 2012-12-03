class E

  def event_stream &proc
    response[HEADER__CONTENT_TYPE] = CONTENT_TYPE__EVENT_STREAM
    response.body = Reel::EventStream.new &proc
  end
  
end
