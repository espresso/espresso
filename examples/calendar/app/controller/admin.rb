module ECalendar
  class Admin < E
    map    :admin
    layout :admin_layout

    # protecting Admin controller via basic auth.
    # we could also do like this:
    #   [user, pass] == ['admin', 'superSecretPassword']
    # but keeping passwords in plain text is a terrible bad idea!
    # so simply using IRB to create the MD5 hash of the password
    # and copying it here to be compared with pass provided by user,
    # which is MD5 hashed as received.
    auth do |user, pass|
      [user, Digest::MD5.hexdigest(pass)] ==
        ['admin', '62c428533830d84fd8bc77bf402512fc']
    end

    # `crudify` will automatically create all needed CRUD actions
    # and will map them to corresponding methods of EntryModel.
    # so when we issue a GET request it will fetch a entry by given ID and return it to us.
    # when a POST request issued it will create a new entry based on provided data.
    # on PUT requests it will fetch entry by given ID and update it with given data.
    # by default, `crudify` will use :index action to listen for requests.
    # but we index action for user interface, so telling `crudify` to use another action
    # by passing it as second argument.
    # in our case it will use /crud URL to serve CRUD requests and will create following actions:
    #   - get_crud
    #   - post_crud
    #   - put_crud
    #   - delete_crud
    #   etc.
    crudify EntryModel, :crud

    # we have to update the frontend UI when some entry created / updated / deleted.
    # here we setup `post_crud`, `put_crud` and `delete_crud` actions(automatically created by `crudify`)
    # to execute a hook that will run after a successful db operation.
    # the hook will update connections sticked to the date of CRUDed row.
    setup :post_crud, :put_crud, :delete_crud do
      after do
        if response.status == 200 && date = params[:occur_at]
          date = DateTime.parse(date).strftime('%Y-%m-%d')
          # executing Index#entries(date) and sending output to connected clients
          output = fetch(Index, :entries, date)
          (Index::Connections[date]||[]).each { |s| s.data output }
        end
      end
    end

  end
end
