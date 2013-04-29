
#### Note: Streaming in Espresso is working only with Thin, Rainbows! and [Reel(0.3 and up)](https://github.com/celluloid/reel) web-servers.

By default Espresso will use `EventMachine` as streaming backend.

If you are using Reel web server, you should instruct `Espresso` to use `Celluloid` as backend.

This is done via `streaming_backend` method at app level:

```ruby
app = E.new do
  streaming_backend :Celluloid
  # ...
end
```

## Server-Sent Events

As easy as:

<pre lang="html">
&lt;script type=&quot;text/javascript&quot;&gt;
var evs = new EventSource('/subscribe');
evs.onmessage = function(e) {
  $('#wall').html( e.data );
}
&lt;/script&gt;
</pre>

```ruby
class App < E
  map '/'
  
  def subscribe
    evented_stream :keep_open do |stream|
      stream << "some string" # sending data
    end
  end
end
```

<pre lang="html">
&lt;script type=&quot;text/javascript&quot;&gt;
var evs = new EventSource('/subscribe');
evs.addEventListener('time', function(e) {
  $('#time').html( e.data );
}, false);
&lt;/script&gt;
</pre>

```ruby
def subscribe
  evented_stream :keep_open do |stream|
    stream.event "time" # sending "time" event
    stream << Time.now  # sending time data
  end
end
```

Other `EventSource` related methods - `id`, `retry`:

```ruby
def subscribe
  evented_stream :keep_open do |stream|
    stream.id "foo"     # sending "foo" ID
    stream.retry 10000  # instructing browser to reconnect every 10 seconds
  end
end
```

**[Real-world Example #1](https://github.com/espresso/espresso-examples/tree/master/eventsource-chat)**

**[Real-world Example #2](https://github.com/espresso/espresso-examples/tree/master/calendar/app)**

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**

## WebSockets

For now, WebSockets works out-of-the-box with Reel web-server only.

As easy as:

<pre lang="html">
&lt;script type=&quot;text/javascript&quot;&gt;
ws = new WebSocket('ws://host:port/subscribe');
ws.onmessage = function(e) {
  $('#wall').html( e.data );
}
&lt;/script&gt;

&lt;input type=&quot;text&quot; id=&quot;message&quot;&gt;
&lt;input type=&quot;button&quot; onClick=&quot;ws.send( $('#message').val() );&quot; value=&quot;send message&quot;&gt;
</pre>

```ruby
def subscribe
  if socket = websocket?
    socket << 'Welcome to the wall'
    socket.on_message do |msg|
      # will set #wall's HTML to current time + received message
      socket << "#{Time.now}: #{msg}"
    end
    socket.on_error { socket.close unless socket.closed? }
    socket.read_interval 1 # reading from socket every 1 second
  end
end
```

**[Real-world Example](https://github.com/espresso/espresso-examples/tree/master/websocket-chat)**

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**

## Chunked Responses

**From W3.org:**

<blockquote>
The chunked encoding modifies the body of a message in order to transfer it as a series of chunks,
each with its own size indicator, followed by an OPTIONAL trailer containing entity-header fields.
This allows dynamically produced content to be transferred along with the information necessary
for the recipient to verify that it has received the full message.
</blockquote>

So, this is useful when your body is not yet ready in full and you want to start sending it by chunks.

Here is an example that will release the response instantly and then send body by chunks:

```ruby
def some_heavy_action
  chunked_stream do |socket|
    ExtractDataFromDBOrSomePresumablySlowAPI.each do |data|
      socket << data
    end
    socket.close # close it, otherwise the browser will wait for data forever
  end
end
```

**[Real-world Example](https://github.com/espresso/espresso-examples/blob/master/chunked-stream.rb)**
