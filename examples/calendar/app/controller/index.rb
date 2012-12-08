module ECalendar
  class Index < E

    map :/
    layout :frontend_layout

    Connections = {}

    # endpoint for EventSource requests.
    # when receiving a EventSource request, storing the socket into Connections pool.
    # this way we will can talk to the socket later, when corresponding events happening.
    # in our case a source of events are the admin controller that doing CRUD operations.
    # @note: #event_stream will automatically set Content-Type header
    def get_subscribe date
      event_stream do |s|
        (Connections[date] ||= []) << s
        # when client disconnected we are no more able to write to there socket
        # so simply removing it from pool.
        s.on_error { Connections[date].delete s }
      end
    end

  end
end
