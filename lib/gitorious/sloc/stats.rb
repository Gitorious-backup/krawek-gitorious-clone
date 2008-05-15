
require 'ohcount'

module Gitorious
module Sloc

class Stats
  attr_reader :filenames
  
  def initialize(git_dir)
    @git_dir = git_dir
    @filenames = []
  end
  
  def parse!(branch = "HEAD")
    @filenames = `git --git-dir=#{@git_dir} ls-tree -r --name-only --full-name #{branch}`.split
    
    counts = {}
    
    @filenames.each do |file|
      file.strip!
      
      languages_found = Set.new
      sfc = Ohcount::GitFileContext.new(@git_dir, file, @filenames, branch)
      polyglot = Ohcount::Detector.detect(sfc)
      
      if polyglot
        Ohcount::parse(sfc.contents, polyglot) do |language_name, semantic, line|
          counts[language_name] ||= {:code => 0, :comment => 0, :blank => 0}
          counts[language_name][semantic] += 1
          languages_found << language_name
        end
      end
      
      languages_found.each { |l| counts[l][:files] = (counts[l][:files] || 0) + 1 }
    end
    
    counts
  end
end

end
end
