#---
# Excerpted from "Security on Rails",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material, 
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose. 
# Visit http://www.pragmaticprogrammer.com/titles/fr_secure for more book information.
#---
require File.dirname(__FILE__) + '/../test_helper'

class UsersControllerTest < ActionController::TestCase
  tests UsersController
  
  
  def test_create_user_success
    post :create, :user => {
      :type => "DbUser",
      :first_name => 'Juan', 
      :last_name => 'Valdez', 
      :email => 'juan@gmail.com',
      :username => 'juaninamillion', 
      :zip_code => '75024',
      :password => 'hello34', 
      :password_confirmation => 'hello34'
    }
    user = User.find_by_username('juaninamillion')
    assert_not_nil user, assigns(:user).errors.inspect
    assert_response :redirect
    assert_redirected_to user_path(assigns(:user))
  end
  
  
  
  def test_create_user_success_in_ldap
    LDAPUser.ldap_server do |ldap|
      username = "juaninamillion"
      password = "hello34"
      lattrs = LDAPUser.build_ldap_user_hash("test","user", 
        "test@railssecurity.org", username, password, "75093")
      dn = "uid=#{username},#{LDAP_CONF[RAILS_ENV]["basedn"]}"
      ldap.open {|l| l.add(:dn => dn, :attributes => lattrs)}
      post :create, :user => {
        :type => "LDAPUser",
        :username => username,
        :password => password
      }
      user = User.find_by_username('juaninamillion')
      assert_not_nil user, assigns(:user).errors.inspect
      assert_response :redirect
      assert_redirected_to user_path(assigns(:user))
      ldap.open {|l| l.delete(:dn => dn)}
    end
  end
  
  
  def test_create
    post :create, :user => { 
      :type => "DbUser",
      :username => 'bsmith', 
      :password => 'hello11',
      :password_confirmation => 'hello11',
      :email => 'bob@yahoo.com',
      :zip_code => '75024',
      :first_name => 'Bob',
      :last_name => 'Smith',
      :role_id => 1 
    }
    user = User.find_by_username('bsmith')
    assert_not_nil user, assigns(:user).errors.inspect
    assert_equal 2, user.role_id 
    assert_response :redirect
    assert_redirected_to user_path(user)
    assert_equal @request.session[:user_id], user.id
  end

  def test_new
    get :new
    assert assigns(:user)
  end
end
