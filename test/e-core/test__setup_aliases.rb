module ECoreTest__SetupAliases
  class Before < E
    before :create do
      (@chain ||= []) << [action, :create].join(':')
    end

    before :update do
      (@chain ||= []) << [action, :update].join(':')
    end
    
    before :save do
      (@chain ||= []) << [action, :save].join(':')
    end

    def post_crud
      (@chain||[]).join("+")
    end
    alias_before :post_crud, :create, :save

    def put_crud
      (@chain||[]).join("+")
    end
    alias_before :put_crud, :update, :save
  end

  class After < E
    after :create do
      (@chain ||= []) << [action, :create].join(':')
      response.body = [(@chain||[]).join("+")]
    end

    after :update do
      (@chain ||= []) << [action, :update].join(':')
      response.body = [(@chain||[]).join("+")]
    end
    
    after :save do
      (@chain ||= []) << [action, :save].join(':')
      response.body = [(@chain||[]).join("+")]
    end

    def post_crud
    end
    alias_after :post_crud, :create, :save

    def put_crud
    end
    alias_after :put_crud, :update, :save
  end

  Spec.new Before do
    post :crud
    is('post_crud:create+post_crud:save').current_body?

    put :crud
    is('put_crud:update+put_crud:save').current_body?
  end

  Spec.new After do
    post :crud
    is('post_crud:create+post_crud:save').current_body?

    put :crud
    is('put_crud:update+put_crud:save').current_body?
  end
end
