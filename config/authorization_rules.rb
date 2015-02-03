authorization do
  role :"staff:cul.columbia.edu" do
    has_permission_on :download do
      to :fedora_content
      if_attribute :mime_type => is_not {"image/tiff"}
      #if_attribute :mime_type => is_not {"audio/x-wav"}
      #if_attribute :mime_type => is_not {nil}
      #if_attribute :content_models => does_not_contain {"info:fedora/ldpd:RestrictedResource"}
    end
  end
  role :download_seminars do
    has_permission_on :download do
      to :fedora_content
      if_attribute :publisher => is {["info:fedora/project:usem"]}
    end
    has_permission_on :download do
      to :fedora_content
      if_attribute :context => is {'seminars'}
    end
  end
  role :download_all do
    has_permission_on :download do
      to :fedora_content
    end
  end
  role :download_wav do
    has_permission_on :download do
      to :fedora_content
      if_attribute :mime_type => is {"audio/x-wav"}
    end
  end
  role :download_tiff do
    has_permission_on :download do
      to :fedora_content
      if_attribute :mime_type => is {"image/tiff"}
    end
  end
  # role extensions
  role :"ldpd.cunix.local:columbia.edu" do
    includes :download_tiff
  end
  # user permissions
  role :"ba2213:users.cul.columbia.edu" do
    includes :download_all
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
