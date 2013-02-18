class E
  # Allows to start sending data to the client even though later parts of
  # the response body have not yet been generated.
  #
  # The close parameter specifies whether Stream#close should be called
  # after the block has been executed. This is only relevant for evented
  # servers like Thin or Rainbows.
  def stream keep_open = false, &proc
    if app.streaming_backend == :Celluloid
      response.body = Reel::Stream.new(&proc)
    else
      # kindly borrowed from Sinatra
      scheduler = env['async.callback'] ? EventMachine : EspressoStream
      current   = (@__e__params||{}).dup
      response.body = EspressoStream.new(scheduler, keep_open) {|out| with_params(current) { yield(out) }}
    end
  end

  def websocket?
    # on websocket requests, Reel web-server storing the socket into ENV['rack.websocket']
    # TODO: implement rack.hijack
    env[RACK__WEBSOCKET]
  end

  private
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
class EspressoStream # kindly borrowed from Sinatra
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
