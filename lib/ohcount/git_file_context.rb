
module Ohcount

class GitFileContext
  attr_reader :filename, :branch, :git_dir, :file_location
  attr_accessor :filenames
  
  def initialize(git_dir, filename, filenames = [], branch = "HEAD")
    @git_dir = git_dir
    @branch = branch
    @filenames = filenames
    @filename = filename
    @file_location = @filename
  end
  
  def filenames
    if @filenames.empty?
      @filenames = `git --git-dir=#{@git_dir} ls-tree -r --name-only --full-name #{@branch}`.split('\n')
    end
    @filenames
  end
  
  def contents
    @cached_contents ||= `git --git-dir=#{@git_dir} show #{@branch}:#{@filename}`
  end
end

end
