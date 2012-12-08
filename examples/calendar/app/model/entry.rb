module ECalendar
  class EntryModel

    include DataMapper::Resource

    property :id, Serial
    property :occur_at, DateTime, :unique_index => :datetimename, :required => true
    property :name, String, :unique_index => :datetimename, :required => true, :length => 1..50

    def date
      self.occur_at.strftime '%a, %b %-d %Y, %l:%M %p'
    end

  end
end
