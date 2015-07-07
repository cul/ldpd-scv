require 'spec_helper'

describe Ability do
  let(:user) do
    user = User.new
    allow(user).to receive(:role_symbols) { [:foo]}
    user
  end
  let(:ok_proxy) do
    ok_proxy = Cul::DownloadProxy.new
    ok_proxy.context = :fedora_content
    ok_proxy.mime_type = "image/jpeg"
    ok_proxy
  end
  let(:no_proxy) do
    ok_proxy = Cul::DownloadProxy.new
    ok_proxy.context = :fedora_content
    ok_proxy.mime_type = "image/tiff"
    ok_proxy
  end
  subject { Ability.new(user)}
  describe '#can?' do
    it do
      subject.can :download, Cul::DownloadProxy do |proxy|
        proxy.context == :fedora_content &&
          !(proxy.mime_type.eql?"image/tiff")
      end
      expect(subject.can? :download, ok_proxy).to be
      expect(subject.can? :download, no_proxy).not_to be
      expect(subject.can? :lolwut, ok_proxy).not_to be
    end
  end
  describe Role::RoleProxy do
    before do
      Role.role :foo do
        includes :bar
      end
    end
    after do
      Role.proxies.clear
    end
    it do
      expect(user.role? :bar).to be
    end
  end  
end