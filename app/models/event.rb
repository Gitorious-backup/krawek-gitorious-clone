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

class Event < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  belongs_to :target, :polymorphic => true

  attr_reader :git

  def self.process(repository_path, revisions)
    repository = Repository.find_by_path(repository_path)
    return false if repository.blank?

    project = repository.project
    @git = Grit::Git.new(repository_path)

    revisions.each do |oldrev, newrev, revname|
      action = find_action(oldrev, newrev)
      new_type, oldtype, current_rev, current_rev_type = find_types(oldrev, newrev, action)

      # type => heads, tags, remotes
      # name => branch name
      path, type, name = revname.split("/")
      revs, emails = revs_and_emails(action, oldrev, newrev, current_rev, type)

      users = repository.committers.find(:all, :conditions => ["email in (?)", emails])
      user_map = users.inject({}) { |hash, user| hash[user.email] = user; hash }

      revs.each do |sha1|
        info = commit_info(sha1)

        user = user_map[info[:email]]
        if user.nil?
          # TODO: no user should be ok, no need to skip
#           $stdout.puts "** The email '#{info[:email]}' is not registered."
          next
        end

        action_id, ref = action_and_ref(action, sha1, name, type, current_rev_type)
        next unless action_id

        project.create_event(action_id, repository, user, ref, info[:message], info[:date])
        action = :update
      end
    end
  end

  protected
  # action => create, delete, update
  # rev_type => commit, tag
  def self.find_action(oldrev, newrev)
    action = :create
    if oldrev =~ /^0+$/
      action = :create
    else
      if newrev =~ /^0+$/
        action = :delete
      else
        action = :update
      end
    end
    action
  end

  def self.find_types(oldrev, newrev, action)
    newtype = oldtype = current_rev_type = "commit"
    current_rev = newrev

    if action != :delete
      newtype = git.cat_file({:t => true}, newrev)
    end

    if action == :update
      oldtype = git.cat_file({:t => true}, oldrev)
    end

    if action == :delete
      current_rev = oldrev
      current_rev_type = oldtype
    end

    [newtype, oldtype, current_rev, current_rev_type]
  end

  def self.action_and_ref(action, sha1, name, type, current_rev_type)
    action_id = ref = nil
    if current_rev_type == "commit"
      if type == "heads"
        case action
          when :create
            action_id = Action::CREATE_BRANCH
            ref = name
          when :update
            action_id = Action::COMMIT
            ref = sha1
          when :delete
            action_id = Action::DELETE_BRANCH
            ref = name
        end
      elsif type == "tags"
        if action == :create
          action_id = Action::CREATE_TAG
          ref = name
        elsif action == :delete
          action_id = Action::DELETE_TAG
          ref = name
        end
      end
    elsif current_rev_type == "tag"
      if type == "tags"
        if action == :create
          action_id = Action::CREATE_TAG
          ref = name
        elsif action == :delete
          action_id = Action::DELETE_TAG
          ref = name
        end
      end
    end
    [action_id, ref]
  end

  def self.revs_and_emails(action, oldrev, newrev, current_rev, type)
    revs = [ current_rev ]
    emails = [git.show({:pretty => "format:%ce", :s => true}, current_rev)]

    if type == "heads"
      if action == :update
        revs = git.rev_list({}, "#{oldrev}..#{newrev}").split("\n")
        emails = git.log({:pretty => "format:%ce"}, "#{oldrev}..#{newrev}").split("\n")
      elsif action == :create && name == "master"
        revs = git.rev_list({}, current_rev).split("\n")
        emails = git.log({:pretty => "format:%ce"}, current_rev).split("\n")
      end
    end

    [revs, emails]
  end

  def self.commit_info(sha1)
    gitshow = git.show({ :pretty => "format:author: %cn%nemail: %ce%ndate: %ct%nmessage: %s", :s => true}, sha1)

    info = {}
    gitshow.each do |line|
      if line =~ /(\w+):\s(.*)$/
        key = $1.to_sym
        value = $2

        value = Time.at(value.to_i).utc if key == :date

        info[key] = value
      end
    end

    info
  end
end
