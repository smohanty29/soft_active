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

    it "should cascade deactivation recursively" do
      user = @user1
      xuser_count = User.count - 1
      xpost_count = Post.count - user.posts.count
      xcomment_count = Comment.count - user.posts.map(&:comments).flatten.count

      post = user.posts.shuffle.first
      comment = user.posts.map(&:comments).flatten.shuffle.first
      user.unset_active
      user.save!
      expect {User.find(user.id)}.to raise_error(ActiveRecord::RecordNotFound)
      expect {Post.find(post.id)}.to raise_error(ActiveRecord::RecordNotFound)
      expect {Comment.find(comment.id)}.to raise_error(ActiveRecord::RecordNotFound)
      User.count.should eql(xuser_count)
      Post.count.should eql(xpost_count)
      Comment.count.should eql(xcomment_count)
    end

    it "should cascade reactivation recursively" do
      user1 = @user1
      xuser = user1
      xposts = user1.posts
      xcomments = user1.posts.map(&:comments).flatten

      user2 = @user2
      fuser = [user1, user2].shuffle.first
      fpost = Post.scoped.shuffle.first
      fcomment = Comment.scoped.shuffle.first
      # we unset both users
      user1.unset_active
      user1.save!
      user2.unset_active
      user2.save!
      # should fail for any find
      expect {User.find(fuser.id)}.to raise_error(ActiveRecord::RecordNotFound)
      expect {Post.find(fpost.id)}.to raise_error(ActiveRecord::RecordNotFound)
      expect {Comment.find(fcomment.id)}.to raise_error(ActiveRecord::RecordNotFound)
      # reactivate 1
      user = User.with_inactive.find(user1.id)
      user.set_active
      user.save!
      # test
      user = User.find(user1.id)
      user.posts.map(&:id).should eql(xposts.map(&:id))
      user.posts.map(&:comments).flatten.map(&:id).should eql(xcomments.map(&:id))
      User.count.should eql(1)
      Post.count.should eql(xposts.count)
      Comment.count.should eql(xcomments.count)
    end

    it "should cascade reactivation recursively all rows regardless of how deactivated" do
      user1 = @user1
      xuser = user1
      xposts = user1.posts
      xcomments = user1.posts.map(&:comments).flatten
      users_count = User.count
      comments_count = Comment.count
      posts_count = Post.count

      # deactive a random post and children
      post = xposts.shuffle.first
      ycomments = post.comments.all
      post.unset_active
      post.save!
      Comment.scoped.should have_exactly(comments_count - ycomments.count).items

      # now reactivate the parent row
      user = user1
      user.set_active
      user.save!
      User.count.should eql(users_count)
      Post.count.should eql(posts_count)
      Comment.count.should eql(comments_count)
    end
  end
end