require 'spec_helper'

describe 'Nested SoftActive::Associations' do
  context 'with models setup', :db => true do
    before :all do
      ActiveRecord::Migration.create_table :users, force: true do |t|
        t.string :name
        t.boolean :active, :default => true
      end

      ActiveRecord::Migration.create_table :posts, force: true do |t|
        t.integer :user_id
        t.string :name
        t.boolean :active, :default => true
      end

      ActiveRecord::Migration.create_table :comments, force: true do |t|
        t.integer :post_id
        t.string :name
        t.boolean :active, :default => true
      end

      class User < ActiveRecord::Base
        has_many :posts, :dependent => :destroy
        soft_active :dependent_cascade => true
      end

      class Post < ActiveRecord::Base
        belongs_to :user
        has_many :comments, :dependent => :destroy
        soft_active :dependent_cascade => true
      end

      class Comment < ActiveRecord::Base
        belongs_to :post
        soft_active
      end

      # create two users, each user having two posts, each post having two comments
      (1..2).each do |n|
        user = User.create!(:name => "User #{n}")
        (1..2).each{|p| user.posts << user.posts.build(:name => "Post for user #{n} - #{p}")}
        user.save!
        user.posts.each do |p|
          (1..2).each {|c| p.comments << p.comments.build(:name => "Comment for User #{n} Post #{p.id} - #{c}")}
          p.save!
        end
        instance_variable_set("@user#{n}", user)
      end
    end

    it "should cascade deactivation recursively" do
      user = @user1
      post = user.posts.shuffle.first
      comment = user.posts.map(&:comments).flatten.shuffle.first
      user.unset_active
      user.save!
      expect {User.find(user.id)}.to raise_error(ActiveRecord::RecordNotFound)
      expect {Post.find(post.id)}.to raise_error(ActiveRecord::RecordNotFound)
      expect {Comment.find(comment.id)}.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end