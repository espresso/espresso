class String
  def remove_extension
    File.basename(self, File.extname(self))
  end
end