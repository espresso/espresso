class E

  def event_stream &proc
    response[HEADER__CONTENT_TYPE] = CONTENT_TYPE__EVENT_STREAM
    response.body = ::Reel::EventStream.new(&proc)
  end

  def websocket?
    env['rack.websocket']
  end

  def chunked_stream &proc
    response.body = ::Reel::ChunkStream.new(&proc)
  end

  def stream &proc
    response.body = ::Reel::Stream.new(&proc)
  end
end
