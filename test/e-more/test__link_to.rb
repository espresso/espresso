module EMoreTest__LinkTo
  class App < E
    map '/'
    format_for :foo, '.bar'

    def foo
    end
  end
  App.mount

  class App2 < E
    map 'app2'
    format '.bar'

    def foo
    end
  end
  App2.mount
  
  Spec.new self do
    app = App.new
    
    expect( app.link_to(:foo) ) =~ %r[href="/foo">/foo]
    expect( app.link_to(:foo, 'some-label') ) =~ %r[href="/foo">some-label]
    
    expect( app.link_to(:foo, target: '_blank') ) =~
      %r[href="/foo" target="_blank">/foo]
    
    expect( app.link_to(:foo, 'some-label', target: '_blank') ) =~
      %r[href="/foo" target="_blank">some-label]
    
    expect( app.link_to(:foo) { 'some-label' } ) =~
      %r[href="/foo">some-label]

    expect( app.link_to(:foo, target: '_blank') { 'some-label' } ) =~
      %r[href="/foo" target="_blank">some-label]

    expect( app.link_to('foo.bar') ) =~ %r[href="/foo.bar"]

    expect( app.link_to App2[:foo] ) =~ %r[href="/app2/foo"]
    expect( app.link_to App2['foo.bar'] ) =~ %r[href="/app2/foo.bar"]
  end
end
