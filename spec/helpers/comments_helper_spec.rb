require File.dirname(__FILE__) + '/../spec_helper'

describe CommentsHelper do
  it "should render reference to previous comment" do
    comment = comments(:reference1)
    render_comment_body(comment.body, 4).include?("href").should == true
  end
  
  it "should not render reference to current/post comments" do
    comment = comments(:reference1)
    render_comment_body(comment.body, 1).include?("href").should == false
  end
end
