Role.instance_eval do
  # role extensions
  role :'ldpd.cunix.local:columbia.edu' do
    includes :download_tiff
  end
  # user permissions
  role :"ba2213:users.cul.columbia.edu" do
    includes :download_tiff
  end
  role :"dortiz0:users.cul.columbia.edu" do
    includes :download_tiff
  end
  role :"ds2057:users.cul.columbia.edu" do
    includes :download_tiff
  end
  role :"eh2124:users.cul.columbia.edu" do
    includes :download_tiff
  end
  role :"ejs2121:users.cul.columbia.edu" do
    includes :download_tiff
  end
  role :"jeg2:users.cul.columbia.edu" do
    includes :download_tiff
  end
  role :"la2272:users.cul.columbia.edu" do
    includes :download_tiff
  end
  role :"spd1:users.cul.columbia.edu" do
    includes :download_all
  end
  role :"sh3040:users.cul.columbia.edu" do
    includes :download_seminars
  end
  role :"ga2030:users.cul.columbia.edu" do
    includes :download_seminars
  end

end
