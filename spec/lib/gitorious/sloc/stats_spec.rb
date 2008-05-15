require File.dirname(__FILE__) + '/../../../spec_helper'

describe Gitorious::Sloc::Stats do
  before(:each) do
    @stats = Gitorious::Sloc::Stats.new(repositories(:johans).full_repository_path)
  end
  
  it "should collect sloc stats" do
    filename = "a_file"
    filenames = [filename]
    branch = "a_branch"
    
    @stats.should_receive(:filenames).at_least(1).and_return(filenames)
    
    context = mock("context")
    Ohcount::GitFileContext.should_receive(:new).with(@stats.git_dir, filename, filenames, branch).and_return(context)
    Ohcount::Detector.should_receive(:detect).with(context)
    
    @stats.parse!(branch).blank?.should be_true
  end
  
end
