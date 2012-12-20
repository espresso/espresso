#### Note: Streaming in Espresso is working only with [Reel](https://github.com/celluloid/reel) web server of version 0.3 and up

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
    event_stream do |stream|
      stream.data 'some string' # will set #wall's HTML to 'some string'
    end
  end
end
```

Other stream helpers:

  - event
  - retry
  - id


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
  event_stream do |stream|
    stream.event 'time'
    stream.data  Time.now.to_s # will set #time's HTML to current time
  end
end
```

Writing to stream directly:

```ruby
def some_action
  event_stream do |stream|
    stream << "event: time\n"
    stream << "data:  #{Time.now}\n\n"
  end
end
```

Using it without `event_stream` helper:


```ruby
def some_action
  response.body = Reel::EventStream.new do |stream|
    # write to stream directly or via stream helpers
  end
end
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## WebSockets

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

You should not worry about data size/encoding, everything is done under-the-hood by Espresso.

Here is an example that will release the response instantly and then send body by chunks:

```ruby
def some_heavy_action
  chunked_stream do |socket|
    ExtractDataFromDB_OrSomePresumablySlowAPI.each do |data|
      socket << data.to_s
    end
    socket.finish # close it, otherwise the browser will waiting for data forever
  end
end
```

Please make sure to do `socket.finish` after all your data sent.
