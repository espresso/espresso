module ECoreTest__File

  class App < E

    def inline
      send_file __FILE__
    end

    def attach
      attachment __FILE__
    end

  end

  Spec.new App do
    Testing :inline do

      get :inline
      does(/module ECoreTest__File/).match_body?

    end

    Testing :attachment do
      get :attach
      is(last_response.headers['Content-Disposition']) ==
                   'attachment; filename="%s"' % File.basename(__FILE__)
    end

  end
end
