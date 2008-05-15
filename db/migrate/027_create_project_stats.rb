class CreateProjectStats < ActiveRecord::Migration
  def self.up
    create_table :project_stats do |t|
      t.integer :project_id, :null => false
      t.string :primary_language
      t.integer :loc, :default => 0
      t.integer :contributors, :default => 1
      t.integer :activities, :default => 0
      t.integer :activities_last_week, :default => 0
      t.integer :files, :default => 0
      t.integer :repositories, :default => 1

      t.timestamps
    end
    
    add_index :project_stats, :project_id, :unique => true
    
    Project.find(:all).each do |project|
      project.create_stats
    end
  end

  def self.down
    drop_table :project_stats
  end
end
