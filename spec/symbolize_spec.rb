# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/spec_helper'

#
# Test model
class User < ActiveRecord::Base
  symbolize :other
  symbolize :language, :in => [:pt, :en]
  symbolize :sex, :in => [true, false], :scopes => true
  symbolize :status , :in => [:active, :inactive], :i18n => false, :capitalize => true, :scopes => true
  symbolize :so, :allow_blank => true, :in => {
    :linux => 'Linux',
    :mac   => 'Mac OS X',
    :win   => 'Videogame'
  }, :scopes => true
  symbolize :gui, :allow_blank => true, :in => [:cocoa, :qt, :gtk], :i18n => false
  symbolize :karma, :in => [:good, :bad, :ugly], :methods => true, :i18n => false, :allow_nil => true
  symbolize :public, :in => [true, false], :scopes => true
end

class UserSkill < ActiveRecord::Base
  symbolize :kind, :in => [:agility, :magic]
end

# Make with_scope public-usable for testing
class << ActiveRecord::Base
  public :with_scope
end

# Test records
User.create(:name => 'Anna', :other => :fo, :status => :active  , :so => :linux, :gui => :qt, :language => :pt, :sex => true, :public => true)
User.create(:name => 'Bob' , :other => :bar,:status => :inactive, :so => :mac, :gui => :gtk, :language => :en, :sex => false, :public => false)


describe "Symbolize" do


  it "should respond to symbolize" do
    ActiveRecord::Base.should respond_to :symbolize
  end

  describe "Instantiated" do
    before(:each) do
      @user = User.first
    end

    it "test_symbolize_string" do
      @user.status = 'inactive'
      @user.status.should eql(:inactive)
      #      @user.status_before_type_cast.should eql(:inactive)
      # @user.read_attribute(:status).should eql('inactive')
    end

    it "test_symbolize_symbol" do
      @user.status = :active
      @user.status.should eql(:active)
      @user.status_before_type_cast.should eql(:active)
      # @user.read_attribute(:status).should eql('active')
    end

    it "should acts nice with numbers" do
      @user.status = 43
      @user.status.should be_nil
      @user.status_before_type_cast.should be_nil
      @user.read_attribute(:status).should be_nil
    end

    it "should acts nice with nil" do
      @user.status = nil
      @user.status.should be_nil
      @user.status_before_type_cast.should be_nil
      @user.read_attribute(:status).should be_nil
    end

    it "should acts nice with blank" do
      @user.status = ""
      @user.status.should be_nil
      @user.status_before_type_cast.should be_nil
      @user.read_attribute(:status).should be_nil
    end

    it "test_symbols_quoted_id" do
      @user.status = :active
      @user.status.quoted_id.should eql("'active'")
    end

    it "should not validates other" do
      @user.other = nil
      @user.should be_valid
      @user.other = ""
      @user.should be_valid
    end

    it "should get the correct values" do
      User.get_status_values.should eql([["Active", :active],["Inactive", :inactive]])
      User::STATUS_VALUES.should eql({:inactive=>"Inactive", :active=>"Active"})
    end

    it "test_symbolize_humanize" do
      @user.status_text.should eql("Active")
    end

    it "should get the correct values" do
      User.get_gui_values.should =~ [["cocoa", :cocoa], ["qt", :qt], ["gtk", :gtk]]
      User::GUI_VALUES.should eql({:cocoa=>"cocoa", :qt=>"qt", :gtk=>"gtk"})
    end

    it "test_symbolize_humanize" do
      @user.gui_text.should eql("qt")
    end

    it "should get the correct values" do
      User.get_so_values.should =~ [["Linux", :linux], ["Mac OS X", :mac], ["Videogame", :win]]
      User::SO_VALUES.should eql({:linux => "Linux", :mac => "Mac OS X", :win => "Videogame"})
    end

    it "test_symbolize_humanize" do
      @user.so_text.should eql("Linux")
    end

    it "test_symbolize_humanize" do
      @user.so = :mac
      @user.so_text.should eql("Mac OS X")
    end

    it "should stringify" do
      @user.other_text.should eql("fo")
      @user.other = :foo
      @user.other_text.should eql("foo")
    end

    it "should validate status" do
      @user.status = nil
      @user.should_not be_valid
      @user.should have(1).errors
    end

    it "should not validate so" do
      @user.so = nil
      @user.should be_valid
    end

    it "test_symbols_with_weird_chars_quoted_id" do
      @user.status = :"weird'; chars"
      @user.status_before_type_cast.should eql(:"weird'; chars")
      #    assert_equal "weird'; chars", @user.read_attribute(:status)
      #   assert_equal "'weird''; chars'", @user.status.quoted_id
    end

    it "test_symbolized_finder" do
      User.find(:all, :conditions => { :status => :inactive }).map(&:name).should eql(['Bob'])
      User.find_all_by_status(:inactive).map(&:name).should eql(['Bob'])
    end

    it "test_symbolized_with_scope" do
      User.with_scope(:find => { :conditions => { :status => :inactive }}) do
        User.find(:all).map(&:name).should eql(['Bob'])
      end
    end
    
    it "should have named scopes" do
      anna = User.find_by_name!('Anna')
      bob = User.find_by_name!('Bob')
      
      User.inactive.should == [bob]
      User.linux.should == [anna]
      
      User.with_sex.should == [anna]
      User.without_sex.should == [bob]
      
      User.public.should == [anna]
      User.not_public.should == [bob]
    end

    describe "View helpers" do
      include ActionView::Helpers::FormHelper
      include ActionView::Helpers::FormOptionsHelper

      before(:each) do
        @options_status = [['Active', :active], ['Inactive', :inactive]]
        @options_gui    = [["cocoa", :cocoa], ["qt", :qt], ["gtk", :gtk]]
        @options_so     = [["Linux", :linux]  , ["Mac OS X", :mac], ["Videogame", :win]]
      end

      it "test_helper_select_sym" do
        @user.status = :inactive
        output = "<select id=\"user_status\" name=\"user[status]\">#{options_for_select(@options_status, @user.status)}</select>"
        output.should eql(select_sym("user", "status", nil))


        output = "<select id=\"user_status\" name=\"user[status]\">#{options_for_select(@options_status, @user.status)}</select>"
        output.should eql(select_sym("user", "status", nil))
      end

      def test_helper_select_sym_order
        output_so     = "<select id=\"user_so\" name=\"user[so]\">#{options_for_select(@options_so, @user.so)}</select>"
        output_office = "<select id=\"user_office\" name=\"user[office]\">#{options_for_select(@options_office, @user.office)}</select>"

        assert_equal output_so, select_sym("user", "so", nil)
        assert_equal output_office, select_sym("user", "office", nil)
      end

      def test_helper_radio_sym
        output = radio_sym("user", "status", nil)
        assert_equal("<label>Active: <input checked=\"checked\" id=\"user_status_active\" name=\"user[status]\" type=\"radio\" value=\"active\" /></label><label>Inactive: <input id=\"user_status_inactive\" name=\"user[status]\" type=\"radio\" value=\"inactive\" /></label>", output)
      end

    end

    describe "i18n" do

      it "should test i18n ones" do
        @user.language_text.should eql("Português")
      end

      it "should get the correct values" do
        User.get_language_values.should =~ [["Português", :pt], ["Inglês", :en]]
      end

      it "should get the correct values" do
        User::LANGUAGE_VALUES.should eql({:pt => "Português", :en => "Inglês"})
      end

      it "should test boolean" do
        @user.sex_text.should eql("Feminino")
      end

      it "should get the correct values" do
        User.get_sex_values.should eql([["Feminino", true],["Masculino", false]])
      end

      it "should get the correct values" do
        User::SEX_VALUES.should eql({false=>"Masculino", true=>"Feminino"})
      end

      it "should translate a multiword class" do
        @skill = UserSkill.create(:kind => :magic)
        @skill.kind_text.should eql("Mágica")
      end

    end

    describe "Methods" do

      it "should play nice with other stuff" do
        @user.karma.should be_nil
        User::KARMA_VALUES.should eql({:bad => "bad", :ugly => "ugly", :good => "good"})
      end

      it "should provide a boolean method" do
        @user.should_not be_good
        @user.karma = :ugly
        @user.should be_ugly
      end

      it "should work" do
        @user.karma = "good"
        @user.should be_good
        @user.should_not be_bad
      end

    end

  end

end
