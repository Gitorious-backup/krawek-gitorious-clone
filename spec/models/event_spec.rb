#--
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe Event do
  before(:each) do
    @event = new_event
    @user = users(:johan)
    @repository = repositories(:johans)
    @project = @repository.project
  end

  def new_event(opts={})
    c = Event.new({
      :target => repositories(:johans),
      :body => "blabla"
    }.merge(opts))
    c.user = opts[:user] || users(:johan)
    c.project = opts[:project] || @project
    c
  end

  it "should have valid associations" do
    @event.should have_valid_associations
  end

  describe "processing events" do
    before do
      @revs = ["old", "new", "refs/heads/master"]
      @repo_path = "/repo/path"
      @repository = repositories(:johans)
      @project = @repository.project
      @git = mock("Git")
      Event.stub!(:git).and_return(@git)
      Grit::Git.stub!(:new).and_return(@git)

      Repository.stub!(:find_by_path).and_return(@repository)
    end

    it "should return false if the given repository is nil" do
      Repository.should_receive(:find_by_path).with(@repo_path).and_return(nil)
      Event.process(@repo_path, []).should be_false
    end

    it "should not process anything if 'revisions' is empty" do
      Event.process(@repo_path, []).should == []
    end

    describe "finding the action" do
      it "should be :create" do
        Event.send(:find_action, "00000", "1234").should == :create
      end

      it "should be :update" do
        Event.send(:find_action, "1234", "4567").should == :update
      end

      it "should be :delete" do
        Event.send(:find_action, "1234", "00000").should == :delete
      end
    end

    describe "finding the types" do
      describe "when action is :delete" do
        it "should find the type" do
          @git.should_not_receive(:cat_file)
          Event.send(:find_types, "1234", "5678", :delete).should ==
            ["commit", "commit", "1234", "commit"]
        end
      end

      describe "when action is :update" do
        it "should find the type" do
          @git.should_receive(:cat_file).with({:t=>true}, "1234").and_return("new")
          @git.should_receive(:cat_file).with({:t=>true}, "5678").and_return("old")
          Event.send(:find_types, "1234", "5678", :update).should  ==
            ["old", "new", "5678", "commit"]
        end
      end

      describe "when action is :create" do
        it "should find the type" do
          @git.should_receive(:cat_file).with({:t=>true}, "5678").and_return("new")
          @git.should_not_receive(:cat_file).with({:t=>true}, "1234").and_return("old")
          Event.send(:find_types, "1234", "5678", :create).should ==
            ["new", "commit", "5678", "commit"]
        end
      end
    end
  end

end

