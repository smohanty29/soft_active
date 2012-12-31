require 'spec_helper'

describe 'SoftActive module' do
  define "after include'ing" do
    it "should add the 'define_softactive' method to the model's class" do
      subject = Object.new
      subject.class.send(:include, SoftActive)
      expect(subject.class).to respond_to(scope_name)
    end
  end

  context 'after Foo.define_softactive', :db => true do
    before :all do
      ActiveRecord::Migration.create_table :foos, force: true do |t|
        t.string :name
        t.boolean :active
      end

      Foo = Class.new(ActiveRecord::Base)
      Foo.send(:include, SoftActive)
    end

    before :each do
      Foo.define_softactive

      @active = Foo.create!(:name => 'ACTIVE', :active => true)
      @inactive = Foo.create!(:name => 'INACTIVE', :active => false)
    end

    describe '#define_softactive' do

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
  end
end