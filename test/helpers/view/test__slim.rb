module EViewTest__Slim
  class App < E
    map '/'

    engine :Slim

    def index
      render
    end

  end

  Spec.new App do

    get
    expect(last_response.body) == "Slim successfully registered"

  end
end
