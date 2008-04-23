class TreesController < ApplicationController
  before_filter :find_project_and_repository
  before_filter :check_repository_for_commits
  
  def index
    redirect_to(project_repository_tree_path(@project, @repository, 
        @repository.head_candidate.name, []))
  end
  
  def show
    @git = @repository.git
    @commit = @git.commit(params[:id])
    unless @commit
      redirect_to project_repository_tree_path(@project, @repository, "HEAD", params[:path])
      return
    end
    path = params[:path].blank? ? [] : ["#{params[:path].join("/")}/"] # FIXME: meh, this sux
    @tree = @git.tree(@commit.tree.id, path)
    
    respond_to do |format|
      format.html
      format.zip {
        redirect_to project_repository_archive_tree_path(@project, @repository, params[:id], {:format => "zip"})
        return
      }
      format.tgz {
        redirect_to project_repository_archive_tree_path(@project, @repository, params[:id], {:format => "tgz"})
        return
      }
      format.tbz2 {
        redirect_to project_repository_archive_tree_path(@project, @repository, params[:id], {:format => "tbz2"})
        return
      }
    end
  end
  
  def archive
    @git = @repository.git    
    @commit = @git.commit(params[:id])
    
    if @commit
      fmt = params[:format] ? params[:format] : "tgz"
      prefix = "#{@project.slug}-#{@repository.name}"
      
      case fmt
        when "zip"
          data = @git.git.archive({:prefix => prefix + "/", :format => "zip" }, params[:id] )
          send_data(data, :type => 'application/zip', 
            :filename => "#{prefix}.zip")
        when "tbz2"
          data = @git.git.archive({:prefix => prefix + "/", :format => "tar" }, params[:id], "|bzip2" )
          send_data(data, :type => 'application/x-bzip', 
            :filename => "#{prefix}.tar.bz2")
        else
          data = @git.git.archive({:prefix => prefix + "/", :format => "tar" }, params[:id], "|gzip" )
          send_data(data, :type => 'application/x-gzip', 
            :filename => "#{prefix}.tar.gz")
      end
    else
      flash[:error] = "The given repository or sha is invalid"
      redirect_to project_repository_path(@project, @repository) and return
    end
  end
end
