require File.dirname(__FILE__) + '/../spec_helper'

describe UsersController do
  
  def create_user(options = {})
    post :create, :user => { :login => 'quire', :email => 'quire@example.com',
      :password => 'quire', :password_confirmation => 'quire' }.merge(options)
  end
  
  it "should allow signups" do
    proc{
      create_user
      response.should be_redirect
    }.should change(User, :count)
  end
  
  it "should require login on signup" do
    proc{
      create_user(:login => nil)
      assigns(:user).errors_on(:login).should_not == nil
      response.should render_template("users/new")
    }.should_not change(User, :count)
  end
  
  it "should require password on signup" do
    proc{
      create_user(:password => nil)
      assigns(:user).errors.on(:password).should_not be_empty
      response.should render_template("users/new")
    }.should_not change(User, :count)
  end
  
  it "should require password confirmation on signup" do
    proc {
      create_user(:password_confirmation => nil)
      assigns(:user).errors.on(:password_confirmation).should_not be_empty
      response.should render_template("users/new")
    }.should_not change(User, :count)
  end
  
  it "should require email on signup" do
    proc{
      create_user(:email => nil)
      assigns(:user).errors.on(:email).should_not be_empty
      response.should render_template("users/new")
    }.should_not change(User, :count)
  end
  
  it "should be successful with valid data" do
    proc {
      create_user
    }.should change(User, :count)
  end
  
  it "requires the user to activate himself after posting valid data" do
    create_user
    User.authenticate('quire@example.com', 'quire').should == nil
    controller.send(:logged_in?).should == false
  end
    
  it "should activate user" do
    User.authenticate('moe', 'test').should be(nil)
    get :activate, :activation_code => users(:moe).activation_code
    response.should redirect_to('/')
    flash[:notice].should_not be(nil)
    User.authenticate('moe@example.com', 'test').should == users(:moe)
  end
  
  it "flashes a message when the activation code is invalid" do
    get :activate, :activation_code => "fubar"
    response.should redirect_to('/')
    flash[:notice].should be(nil)
    flash[:error].should == "Invalid activation code"
    User.authenticate('moe@example.com', 'test').should == nil
  end
  
  it "shows the user" do
    get :show, :id => users(:johan).login
    response.should be_success
    assigns[:user].should == users(:johan)
  end
  
  it "recognizes routing with dots in it" do
    params_from(:get, "/users/j.s")[:id].should == "j.s"
  end
  
  it "recognizes activate routes" do
    p = params_from(:get, "/users/activate/abc123")
    p[:controller].should == "users"
    p[:action].should == "activate"
    p[:activation_code].should == "abc123"
  end
  
  it "counts the number of commits in the last week" do
    get :show, :id => users(:johan).login
    response.should be_success
    assigns[:commits_last_week].kind_of?(Fixnum).should == true
    (assigns[:commits_last_week] >= 0).should == true
  end
  
  it "#show sets atom feed autodiscovery" do
    user = users(:johan)
    get :show, :id => user.login
    assigns[:atom_auto_discovery_url].should == formatted_feed_user_path(user, :atom)
  end
  
  it "has an atom feed" do
    user = users(:johan)
    get :feed, :id => user.login, :format => "atom"
    response.should be_success
    assigns[:user].should == user
    assigns[:events].should == user.events.find(:all, :limit => 30, :order => "created_at desc")
  end
  
  describe "#forgot_password" do
    it "GETs the page fine for everyone" do
      get :forgot_password
      response.should be_success
      response.should render_template("forgot_password")
    end
  end
  
  describe "#reset_password" do
    it "redirects to forgot_password if nothing was found" do
      post :reset_password, :user => {:email => "xxx"}
      response.should redirect_to(forgot_password_users_path)
      flash[:error].should match(/invalid email/i)
    end
    
    it "sends a new password if email was found" do
      u = users(:johan)
      User.should_receive(:generate_random_password).and_return("secret")
      Mailer.should_receive(:deliver_forgotten_password).with(u, "secret")
      post :reset_password, :user => {:email => u.email}
      response.should redirect_to(root_path)
      flash[:notice].should == "A new password has been sent to your email"
      
      User.authenticate(u.email, "secret").should_not be_nil
    end
  end
end
