Spec.new :AdminSpec do

  def of_same_time_as? a, b
    format = '%Y-%m-%dT%H:%M:%S'
    a.strftime(format) == b.strftime(format)
  end

  Should 'require authorization' do
    get
    check(last_response.status) == 401
  end

  auth 'admin', 'ap'
  Ensure 'authorization passed' do
    get
    check(last_response.status) == 200
  end

  map ECalendar::Admin.base_url + '/crud'

  Should 'fail with no title error' do
    post
    expect(last_response.status) == 500
    does(last_response.body) =~ /name.*blank/i
  end

  Should 'fail with no date error' do
    post :name => rand.to_s
    expect(last_response.status) == 500
    does(last_response.body) =~ /occur_at.*blank/i
  end

  Should 'create new item' do
    name, occur_at = rand.to_s, DateTime.now
    
    post :name => name, :occur_at => occur_at.to_s
    item_id = last_response.body.to_i
    expect(item_id) > 0

    item = ECalendar::EntryModel.first :id => item_id
    expect { item.name } == name
    is { item.occur_at }.of_same_time_as? occur_at

    Should 'fail with duplicate key error' do
      post :name => name, :occur_at => occur_at.to_s
      does(last_response.body) =~ /Duplicate.*key/i
    end

    Should 'update item' do
      name, occur_at = rand.to_s, DateTime.now - 100

      put item_id, :name => name, :occur_at => occur_at.to_s
      updated_item_id = last_response.body.to_i
      expect(updated_item_id) == item_id

      item = ECalendar::EntryModel.first :id => item_id
      expect { item.name } == name
      is { item.occur_at }.of_same_time_as? occur_at
    end

    Should 'delete item' do
      delete item_id
      expect(last_response.status) == 200
      item = ECalendar::EntryModel.first :id => item_id
      is(item).nil?
    end

  end

end
