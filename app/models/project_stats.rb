class ProjectStats < ActiveRecord::Base
  belongs_to :project
  
  # This method returns an ordered list of lists with "language" and "count" as elements
  # Example:
  #    ProjectStats.most_used_language.each do |st|
  #      puts "Language: #{st.first}"
  #      puts "Count: #{st.last}"
  #    end
  #
  def self.most_used_language(count = 5)
    ProjectStats.count("primary_language", :group => "primary_language", :order => "count_primary_language desc", :limit => count )
  end
  
  def self.largest_project(count = 5)
    ProjectStats.find(:all, :order => ["loc desc"], :include => [:project], :limit => count ) # NOTE: maybe loc/files ?
  end
  
  def self.most_forked_project(count = 5)
    ProjectStats.find(:all, :order => ["repositories desc"], :include => [:project], :limit => count )
  end
  
  def self.most_active_project(count = 5)
    ProjectStats.find(:all, :order => ["activities_last_week desc"], :include => [:project], :limit => count )
  end
  
  def self.largest_development_team(count = 5)
    ProjectStats.find(:all, :order => ["contributors desc"], :include => [:project], :limit => count )
  end
  
  def self.most_downloaded_project(count = 5)
    ProjectStats.find(:all, :order => ["downloads desc"], :include => [:project], :limit => count )
  end
end
