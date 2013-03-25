class << E

  E__CRUD__AUTH_TEST_PAYLOAD_KEY = "E__CRUD__AUTH_TEST_PAYLOAD_#{rand(2**64)}".freeze

  # automatically creates POST/PUT/DELETE actions
  # and map them to corresponding methods of given resource,
  # so sending a POST request to the controller
  # resulting in creating new object of given resource.
  # PUT/PATCH requests will update objects by given id.
  # DELETE requests will delete objects by given id.
  #
  # @params [Class] resource
  # @params [Array] path_or_opts
  # @option path_or_opts [String || Array] :exclude
  #   sometimes forms sending extra params. exclude them using :exclude option
  # @option path_or_opts [Integer] :pkey
  #   item's primary key(default :id) to be returned when item created /updated.
  #   if no pkey given and item does not respond to :id, the item itself returned.
  # @option path_or_opts [Integer] :halt_on_errors
  #   if created/updated item contain errors,
  #   halt processing unconditionally, even if proc given.
  #   if this option is false(default) and a proc given,
  #   it will pass item object and extracted errors to proc rather than halt.
  # @option path_or_opts [Integer] :halt_with
  #   when resource are not created/updated because of errors,
  #   Espresso will halt operation with 500 error status code.
  #   use :halt_with option to set a custom error status code.
  # @option path_or_opts [String] :join_with
  #   if resource thrown some errors, Espresso will join them using a coma.
  #   use :join_with option to set a custom glue.
  #
  def crudify resource, *path_or_opts, &proc
    opts = path_or_opts.last.is_a?(Hash) ? path_or_opts.pop : {}
    if opts[:exclude]
      opts[:exclude] = [ opts[:exclude] ] unless opts[:exclude].is_a?(Array)
    else
      opts[:exclude] = []
    end
    path = path_or_opts.first
    action = '%s_' << (path || :index).to_s
    orm = :ar if resource.respond_to?(:arel_table)
    orm = :dm if resource.respond_to?(:storage_name)
    orm_map = {
      ar: {
          get: :find,
          put: :update_attributes,
        patch: :update_attributes
      },
    }[orm] || {}
    resource_method = {
         get: opts.fetch(:get,    orm_map[:get] || :get),
         put: opts.fetch(:put,    orm_map[:put] || :update),
        post: opts.fetch(:post,   :create),
       patch: opts.fetch(:patch,  orm_map[:patch] || :update),
      delete: opts.fetch(:delete, :destroy),
    }
    
    proc_accept_object, proc_accept_errors = nil
    if proc
      proc_accept_object = proc.arity > 0
      proc_accept_errors = proc.arity > 1
    end

    pkey      = opts[:pkey]      || :id
    join_with = opts[:join_with] || ', '
    halt_with = opts[:halt_with] || 500

    presenter = lambda do |controller_instance, obj, err|

      # extracting errors, if any
      errors = nil
      if err || (obj.respond_to?(:errors) && (err = obj.errors) &&
        err.respond_to?(:size) && err.size > 0)

        if err.respond_to?(:join)
          errors = err
        else
          if err.respond_to?(:each_pair) # seems error is a Hash
            # some objects may respond to `each_pair` but not respond to `inject`,
            # so using trivial looping to extract error messages.
            errors = []
            err.each_pair do |k,v|
              # usually DataMapper returns errors in the following format:
              # { :property => ['error 1', 'error 2'] }
              # flatten is here just in case we get nested arrays.
              error = v.is_a?(Array) ? v.flatten.join(join_with) : v.to_s
              errors << '%s: %s' % [k, error]
            end
          elsif err.respond_to?(:to_a) # not Array nor Hash, but convertible to Array
            # converting error to Array and joining
            errors = err.to_a
          elsif err.is_a?(String)
            errors = [err]
          else
            errors = [err.inspect]
          end
        end
      end
      errors && errors = controller_instance.escape_html(errors.join(join_with))
      
      if proc
        if errors && opts[:halt_on_errors]
          controller_instance.halt halt_with, errors
        end
        proc_args = []
        proc_args = [obj] if proc_accept_object
        proc_args = [obj, errors] if proc_accept_errors
        controller_instance.instance_exec(*proc_args, &proc)
      else
        if errors
          # no proc given, so halting when some errors occurring
          controller_instance.halt halt_with, errors
        else
          # no proc given and no errors detected,
          # so extracting and returning object's pkey.
          # if no pkey given and object does not respond to :id nor to :[],
          # returning object as is.
          if obj.respond_to?(:[]) && obj.respond_to?(:has_key?)
            obj.has_key?(pkey) ? obj[pkey] : obj
          elsif obj.respond_to?(pkey)
            obj.send(pkey)
          else
            obj
          end
        end
      end
    end
    
    fetch_object = lambda do |controller_instance, id|
      obj, err = nil
      begin
        id = id.to_i if id =~ /\A\d+\Z/
        obj = resource.send(resource_method[:get], id) ||
          controller_instance.halt(404, 'object with ID %s not found' % controller_instance.escape_html(id))
      rescue => e
        err = e.message
      end
      [obj, err]
    end

    create_object = lambda do |controller_instance|
      obj, err = nil
      begin
        data = controller_instance.params.reject { |k,v| opts[:exclude].include?(k) }
        unless data.has_key?(E__CRUD__AUTH_TEST_PAYLOAD_KEY)
          obj = resource.send(resource_method[:post], data)
        end
      rescue => e
        err = e.message
      end
      [obj, err]
    end

    update_object = lambda do |controller_instance, request_method, id|
      obj, err = nil
      begin
        obj, err = fetch_object.call(controller_instance, id)
        unless err
          data = controller_instance.params.reject { |k,v| opts[:exclude].include?(k) }
          obj.send(resource_method[request_method], data)
        end
      rescue => e
        err = e.message
      end
      [obj, err]
    end

    # fetching object by given id
    # and calling #destroy(or whatever in options for delete) on it
    #
    # @return [String] empty string
    delete_object = lambda do |id|
      err = nil
      begin
        obj, err = fetch_object.call(self, id)
        unless err
          meth = resource_method[:delete]
          if obj.respond_to?(meth)
             obj.send(meth)
          else
            err = '%s does not respond to %s' % [obj.inspect, escape_html(meth)]
          end
        end
      rescue => e
        err = e.message
      end
      [nil, err]
    end

    options = lambda do |controller_instance|
      EspressoConstants::HTTP__REQUEST_METHODS.reject do |rm|
        next if rm == 'OPTIONS'
        args  = rm == 'POST' ? 
          [{E__CRUD__AUTH_TEST_PAYLOAD_KEY => 'true'}] : 
          [E__CRUD__AUTH_TEST_PAYLOAD_KEY]
        s,h,b = controller_instance.invoke(action % rm.downcase, *args) do |env|
          env.update ENV__REQUEST_METHOD => rm
        end
        s == STATUS__PROTECTED
      end.join(', ')
    end

    self.class_exec do

      define_method action % :get do |id|
        presenter.call self, *fetch_object.call(self, id)
      end

      define_method action % :head do |id|
        presenter.call self, *fetch_object.call(self, id)
      end

      define_method action % :post do
        presenter.call self, *create_object.call(self)
      end

      [:put, :patch].each do |request_method|
        define_method action % request_method do |id|
          presenter.call self, *update_object.call(self, request_method, id)
        end
      end

      define_method action % :delete do |id|
        presenter.call self, *delete_object.call(id)
      end

      define_method action % :options do
        options.call self
      end
    end

  end
  alias crud crudify

end
