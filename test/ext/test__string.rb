module ExtTest__String
  Spec.new self do
    it :remove_extension do
      variations = [
        ["test.json", 'test'],
        ["action/test.xml", 'test']
      ]

      variations.each do |args|
        is?(args[0].remove_extension) == args[1]
      end
    end
  end
end