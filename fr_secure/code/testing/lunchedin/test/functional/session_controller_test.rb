#---
# Excerpted from "Security on Rails",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material, 
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose. 
# Visit http://www.pragmaticprogrammer.com/titles/fr_secure for more book information.
#---
require File.dirname(__FILE__) + '/../test_helper'

class SessionControllerTest < ActionController::TestCase
  tests SessionController

  
  test "should not validate login using sql injection" do
    @request.env['HTTPS'] = 'on'
    post :check_login, :user => { 
      :username => "bob' OR 'a' = 'a", 
      :password => "fakepass' OR 'a' = 'a"
    }
    assert_redirected_to login_path 
    assert_nil @request.session[:user_id] 
  end
  
  
  
  def test_login_success
    @request.env['HTTPS'] = 'on'
    post :check_login, :user => { :username => 'bob', :password => 'hello' }
    assert_response :redirect
    assert_not_nil @request.session[:user_id]
    assert_equal users(:bob).id, @request.session[:user_id]
  end
  
  
  
  def test_logout_success
    @request.session[:user_id] = users(:bob).id
    post :logout
    assert_response :success
    assert_nil @request.session[:user_id]
  end
  
  
end
