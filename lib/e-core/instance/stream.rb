class E

  def stream keep_open = false, &proc
    streamer EStream::Generic, keep_open, &proc
  end

  def chunked_stream keep_open = true, &proc
    transfer_encoding 'chunked'
    streamer EStream::Chunked, keep_open, &proc
  end
  alias chunk_stream chunked_stream

  def evented_stream keep_open = true, &proc
    content_type EConstants::CONTENT_TYPE__EVENT_STREAM
    streamer EStream::Evented, keep_open, &proc
  end
  alias event_stream evented_stream

  def websocket?
    # on websocket requests, Reel web-server storing the socket into ENV['rack.websocket']
    # TODO: implement rack.hijack API
    env[EConstants::RACK__WEBSOCKET]
  end

  private
  # Allows to start sending data to the client even though later parts of
  # the response body have not yet been generated.
  #
  # The close parameter specifies whether Stream#close should be called
  # after the block has been executed. This is only relevant for evented
  # servers like Thin or Rainbows.
  def streamer streamer, keep_open = false, &proc
    if app.streaming_backend == :Celluloid
      response.body = Reel::Stream.new(&proc)
    else
      scheduler = env['async.callback'] ? EventMachine : EStream::Generic
      current   = (@__e__params||{}).dup
      response.body = streamer.new(scheduler, keep_open) {|out| with_params(current) { yield(out) }}
    end
  end

  def with_params(temp_params)
    original, @__e__params = @__e__params, temp_params
    yield
  ensure
    @__e__params = original if original
  end
end

# Class of the response body in case you use #stream.
#
# Three things really matter: The front and back block (back being the
# block generating content, front the one sending it to the client) and
# the scheduler, integrating with whatever concurrency feature the Rack
# handler is using.
#
# Scheduler has to respond to defer and schedule.
class EStream 
  class Generic # kindly borrowed from Sinatra
    def self.schedule(*) yield end
    def self.defer(*)    yield end

    def initialize(scheduler = self.class, keep_open = false, &back)
      @back, @scheduler, @keep_open = back.to_proc, scheduler, keep_open
      @callbacks, @closed = [], false
    end

    def close
      return if @closed
      @closed = true
      @scheduler.schedule { @callbacks.each { |c| c.call }}
    end

    def each(&front)
      @front = front
      @scheduler.defer do
        begin
          @back.call(self)
        rescue Exception => e
          @scheduler.schedule { raise e }
        end
        close unless @keep_open
      end
    end

    def <<(data)
      @scheduler.schedule { @front.call(data.to_s) }
      self
    end

    def callback(&block)
      return yield if @closed
      @callbacks << block
    end

    alias errback callback

    def closed?
      @closed
    end
  end

  class Chunked < Generic
    def << data
      data = data.to_s.chomp + "\n" # ensure data ends in a new line
      size = data.bytesize.to_s(16)
      super size + "\r\n" + data + "\r\n"
    end

    def close
      @scheduler.schedule { @front.call("0\r\n\r\n") } unless closed?
      super
    end
  end

  class Evented < Generic

    # EventSource-related helpers
    #
    # @example
    #   evented_stream do |socket|
    #     socket.event 'some event'
    #     socket.retry 10
    #   end
    #
    %w[event id retry].each do |meth|
      define_method meth do |data|
        # unlike on #data, these messages expects a single \n at the end.
        write meth + ": " + data.to_s.gsub(/\n|\r/, '') + "\n"
      end
    end

    # sending data
    #
    # @example
    #   event_stream :keep_open do |out|
    #     out.data 'chunk one'
    #     out.data 'chunk two'
    #     out.data 'etc.'
    #   end
    #
    def data data
      # - any single message should not contain \n except at the end.
      # - EventSource expects \n\n at the end of each single message.
      write "data: %s\n\n" % data.gsub(/\n|\r/, '')
    end
    alias :<< :data

    def write data
      @scheduler.schedule { @front.call(data.to_s) }
    end

  end

end
