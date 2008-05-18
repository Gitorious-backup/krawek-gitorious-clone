require File.dirname(__FILE__) + '/../spec_helper'

describe ProjectStats do
  before(:each) do
  end

  it "should get the most used languages" do
    ProjectStats.should_receive(:count).with("primary_language", anything).and_return(true)
    ProjectStats.most_used_language be_true
  end
  
  it "should get the largest project" do
    ProjectStats.should_receive(:find).with(:all, {:order => ["loc desc"] ,:include => anything, :limit => anything}).and_return(true)
    ProjectStats.largest_project be_true
  end
  
  it "should get the most forked project" do
    ProjectStats.should_receive(:find).with(:all, {:order => ["repositories desc"] ,:include => anything, :limit => anything}).and_return(true)
    ProjectStats.most_forked_project be_true
  end
  
  it "should get the most active project" do
    ProjectStats.should_receive(:find).with(:all, {:order => ["activities_last_week desc"] ,:include => anything, :limit => anything}).and_return(true)
    ProjectStats.most_active_project be_true
  end
  
  it "should get the project with the largest development team" do
    ProjectStats.should_receive(:find).with(:all, {:order => ["contributors desc"] ,:include => anything, :limit => anything}).and_return(true)
    ProjectStats.largest_development_team be_true
  end
  
  it "should get the most downloaded project" do
    ProjectStats.should_receive(:find).with(:all, {:order => ["downloads desc"] ,:include => anything, :limit => anything}).and_return(true)
    ProjectStats.most_downloaded_project be_true
  end
end
