class Ability
  include CanCan::Ability 

  def initialize(user)
    @user = user || User.new # guest user, what about SSL/IP?
    if @user.role? :"staff:cul.columbia.edu"
      can :download, Cul::Scv::DownloadProxy do |proxy|
        proxy.context.to_sym == :catalog &&
        !(proxy.mime_type.eql?("image/tiff"))
      end
    end
    if @user.role? :download_tiff
      can :download, Cul::Scv::DownloadProxy do |proxy|
        proxy.context.to_sym == :catalog &&
        proxy.mime_type.eql?("image/tiff")
      end
    end
    if @user.role? :download_wav
      can :download, Cul::Scv::DownloadProxy do |proxy|
        proxy.context.to_sym == :catalog &&
        proxy.mime_type.eql?("audio/x-wav")
      end
    end
    if @user.role? :download_seminars
      can :download, Cul::Scv::DownloadProxy do |proxy|
        proxy.publisher.include?("info:fedora/project:usem") ||
        proxy.context.to_sym == :seminars
      end
    end
    if @user.role? :download_all
      can :download, Cul::Scv::DownloadProxy
    end
  end

end
