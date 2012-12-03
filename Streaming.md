### Important Note:

Streaming in Espresso working only with [Reel](https://github.com/celluloid/reel) web server.

## Server-Sent Events

As easy as:

```
<script type="text/javascript">
var evs = new EventSource('/subscribe');
evs.onmessage = function(e) { 
  $('#wall').html( e.data );
}
</script>
```

```ruby
class App < E
  map :/
  
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


```
<script type="text/javascript">
var evs = new EventSource('/subscribe');
evs.addEventListener('time', function(e) { 
  $('#time').html( e.data );
}, false);
</script>
```

```ruby
def subscribe
  event_stream do |stream|
    stream.event 'time'
    stream.data  Time.now.to_s # will set #time's HTML to current time
  end
end
```

Writing to socket directly:

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
    # write to stream directly or via data, event etc. stream helpers
  end
end
```


