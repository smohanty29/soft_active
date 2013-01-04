require 'spec_helper'

describe 'ActiveRecord relations' do
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
      User.reset_column_information

      class Post < ActiveRecord::Base
        belongs_to :user
        has_many :comments, :dependent => :destroy
        soft_active :dependent_cascade => true
      end
      Post.reset_column_information

      class Comment < ActiveRecord::Base
        belongs_to :post
        soft_active
      end
      Comment.reset_column_information
    end

    before :each do
      [User, Post, Comment].each {|tbl| tbl.destroy_all }
      # create two users, each user having two posts, each post having two comments
      (1..2).each do |n|
        user = User.create!(:name => "User #{n}")
        (1..2).each{|p| user.posts << user.posts.build(:name => "Post for user #{n} - #{p}")}
        user.save!
        user.reload
        user.posts.each do |post|
          (1..2).each {|c| post.comments << post.comments.build(:name => "Comment for User #{n} Post #{post.id} - #{c}")}
          post.save!
          post.reload
        end
        instance_variable_set("@user#{n}", user)
      end
    end

    it "should include deactivated rows with_inactive" do
      user = @user1
      posts = user.posts.all
      comments = user.posts.map(&:comments).flatten

      post = posts.shuffle.first
      post.unset_active
      post.save!
      expect {Post.find(post.id)}.to raise_error(ActiveRecord::RecordNotFound)
      user.posts.with_inactive.should have_exactly(posts.count).items
    end

  end
end