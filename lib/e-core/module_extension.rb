module EspressoFrameworkModuleExtension
  def mount *roots, &setup
    EApp.new.mount self, *roots, &setup
  end

  def run *args
    mount.run *args
  end
end