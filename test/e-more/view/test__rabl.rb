module EMoreTest__View__Rabl
  class RablTest < E
    map :rabl_test
    view_prefix base_url

    engine :Rabl

    def index
      render
    end

  end

  Spec.new RablTest do

    get
    expect(last_response.body) == '{"content":"Rabl successfully registered"}'

  end
end
