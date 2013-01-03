require 'spec_helper'

describe 'SoftActive::Associations' do
  context 'With association models', :db => true do
    before :all do
      ActiveRecord::Migration.create_table :posts, force: true do |t|
        t.string :name
        t.boolean :active
      end

      ActiveRecord::Migration.create_table :comments, force: true do |t|
        t.integer :post_id
        t.string :name
        t.boolean :active
      end

      class Comment < ActiveRecord::Base
        belongs_to :post
        soft_active
      end

      class Post < ActiveRecord::Base
        has_many :comments
        soft_active :dependent_cascade => true
      end

    end

    describe "with child association" do
      it "should not deactivate child rows if w/o depedent destroy" do
        post = Post.new(:name => 'Post 1', :active => true)
        post.comments.build(:name => 'Comment 1', :active => true)
        post.save!
        comment = post.comments.first
        post.unset_active
        post.save!
        expect {Post.find(post.id)}.to raise_error(ActiveRecord::RecordNotFound)
        Comment.find_by_id(comment.id).should eql(comment)
      end

      it "should deactive child automatically with dependent association" do
        class Post < ActiveRecord::Base
          has_many :comments, :dependent => :destroy
          soft_active :dependent_cascade => true
        end
        post = Post.new(:name => 'Post 1', :active => true)
        post.comments.build(:name => 'Comment 1', :active => true)
        post.save!
        comment = post.comments.first
        post.unset_active
        post.save!
        expect {Post.find(post.id)}.to raise_error(ActiveRecord::RecordNotFound)
        expect {Comment.find(comment.id)}.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "should not deactive child with dependent association but without dependent_cascade" do
        class Post < ActiveRecord::Base
          has_many :comments, :dependent => :destroy
          soft_active
        end
        post = Post.new(:name => 'Post 1', :active => true)
        post.comments.build(:name => 'Comment 1', :active => true)
        post.save!
        comment = post.comments.first
        post.unset_active
        post.save!
        expect {Post.find(post.id)}.to raise_error(ActiveRecord::RecordNotFound)
        Comment.find_by_id(comment.id).should eql(comment)
      end

      context "with dependent destroy and dependent cascade enabled" do 
        before :each do
          class Post < ActiveRecord::Base
            has_many :comments, :dependent => :destroy
            soft_active :dependent_cascade => true
          end
          @post = Post.new(:name => 'Post 1', :active => true)
          @post.comments.build(:name => 'Comment 1', :active => true)
          @post.save!
        end

        it ".with_inactive should find deactivated rows" do
          post = @post
          post.unset_active
          post.save!
          Post.with_inactive.find(post.id).should eql(post)
        end

        it ".with_inactive and save should reactivate parent and dependent records" do
          post = @post
          comment = post.comments.first
          post.unset_active
          post.save!
          post = Post.with_inactive.find(post.id)
          post.set_active
          post.save!
          post.reload
          post.comments.first.should eql(comment)
        end
      end
    end
  end
end