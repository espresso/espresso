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
    testing :inline do

      get :inline
      is_body? /module ECoreTest__File/

    end

    testing :attachment do
      get :attach
      is(last_response.headers['Content-Disposition']) ==
                   'attachment; filename="%s"' % File.basename(__FILE__)
    end

  end
end
