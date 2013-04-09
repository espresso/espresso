module ECoreTest__Around
  class App < E
    
    around do
      begin
        invoke_action
      rescue => e
        e.message
      end
    end

    def index
      something went wrong!
    end

  end

  Spec.new App do

    get
    does(last_response.body) =~ /undefined method `wrong!'/

  end
end
