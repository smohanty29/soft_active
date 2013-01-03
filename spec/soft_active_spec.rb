require 'spec_helper'

describe 'SoftActive module' do
  puts "These tests should move to GEM's rspec"
  define "after using soft_active" do
    it "should add the 'softactive' method to the model's class" do
      subject = Object.new
      subject.class.send(:soft_active)
      expect(subject.class).to respond_to(scope_name)
    end
  end

  context 'after Foo.soft_active', :db => true do
    before :all do
      ActiveRecord::Migration.create_table :foos, force: true do |t|
        t.string :name
        t.boolean :active
      end

      Foo = Class.new(ActiveRecord::Base)
      Foo.send(:soft_active)
    end

    before :each do
      Foo.soft_active

      @active = Foo.create!(:name => 'ACTIVE', :active => true)
      @inactive = Foo.create!(:name => 'INACTIVE', :active => false)
    end

    it "should soft_active? be true" do
      Foo.soft_active?.should be(true)
    end
      
    describe '#soft_active' do
      [:only_active, :only_inactive, :with_inactive].each do |scope_name|
        it "should add the '#{scope_name}' scope to the model's class" do
          expect(Foo).to respond_to(scope_name)
        end
      end

      it "should set default_scope to :only_active" do
        expect(Foo.all).to eq([@active])
      end
    end

    describe '#only_active' do
      it "should only return active models" do
        expect(Foo.only_active).to eq([@active])
      end
    end

    describe '#only_inactive' do
      it "should only return active models" do
        expect(Foo.only_inactive).to eq([@inactive])
      end
    end

    describe '#with_inactive' do
      it "should return all items" do
        expect(Foo.with_inactive).to match_array([@active, @inactive])
      end
    end

    describe 'Set and unset active' do
      it "should set active to false" do
        test_row = @active
        test_row.unset_active
        test_row.active.should eql(false)
      end

      it "should set active to true" do
        test_row = @inactive
        test_row.set_active
        test_row.active.should eql(true)
      end
    end
  end

  describe "without using soft_active" do
    it "should say soft_active? false" do
      ActiveRecord::Migration.create_table :bars, force: true do |t|
        t.string :name
        t.boolean :active
      end

      Bar = Class.new(ActiveRecord::Base)
      Bar.soft_active?.should_not be(true)
    end
  end
end