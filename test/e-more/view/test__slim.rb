module EMoreTest__View__Slim
  class SlimTest < E
    map :slim_test
    view_prefix base_url

    engine :Slim

    def index
      render
    end

  end

  Spec.new SlimTest do

    get
    expect(last_response.body) == "Slim successfully registered"

  end
end
