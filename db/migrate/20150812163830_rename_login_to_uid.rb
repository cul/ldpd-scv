class RenameLoginToUid < ActiveRecord::Migration
  def self.up
    rename_column :users, :login, :uid
    add_column :users, :provider, :string
    add_index :users, :provider
    User.all.each do |user|
      user.provider = :saml
      user.save!
    end
  end

  def self.down
    remove_column :users, :provider, :string
    rename_column :users, :uid, :login
  end
end
