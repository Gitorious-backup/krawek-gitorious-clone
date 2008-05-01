class RepositoriesController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :writable_by]
  before_filter :find_project
  before_filter :require_adminship, :only => [:edit, :update]
  before_filter :require_user_has_ssh_keys, :only => [:new, :create]
  session :off, :only => [:writable_by]
  
  def index
    @repositories = @project.repositories.find(:all, :include => [:user, :events, :project])
  end
    
  def show
    @repository = @project.repositories.find_by_name!(params[:id])
    @events = @repository.events.paginate(:all, :page => params[:page], 
      :order => "created_at desc")
    
    @atom_auto_discovery_url = formatted_project_repository_path(@project, @repository, :atom)
    respond_to do |format|
      format.html
      format.xml  { render :xml => @repository }
      format.atom {  }
    end
  end
  
  # note the #new+#create actions are members in the routes, hence they require
  # an id (of the repos to clone).
  def new
    @repository_to_clone = @project.repositories.find_by_name!(params[:id])
    unless @repository_to_clone.has_commits?
      flash[:error] = "Sorry, can't clone an empty repository"
      redirect_to project_repository_path(@project, @repository_to_clone)
      return
    end
    @repository = Repository.new_by_cloning(@repository_to_clone, current_user.login)
  end
  
  def create
    @repository_to_clone = @project.repositories.find_by_name!(params[:id])
    unless @repository_to_clone.has_commits?
      target_path = project_repository_path(@project, @repository_to_clone)
      respond_to do |format|
        format.html do
          flash[:error] = "Sorry, can't clone an empty repository"
          redirect_to target_path
        end
        format.xml do 
          render :text => "Sorry, can't clone an empty repository", 
            :location => target_path, :status => :unprocessable_entity
        end
      end
      return
    end
    @repository = Repository.new_by_cloning(@repository_to_clone)
    @repository.name = params[:repository][:name]
    @repository.user = current_user
    
    respond_to do |format|
      if @repository.save
        @project.create_event(Action::CLONE_REPOSITORY, @repository, current_user, @repository_to_clone.id)
        
        location = project_repository_path(@project, @repository)
        format.html { redirect_to location }
        format.xml  { render :xml => @repository, :status => :created, :location => location }        
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @repository.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # Used internally to check write permissions by gitorious
  def writable_by
    @repository = @project.repositories.find_by_name!(params[:id])
    user = User.find_by_login(params[:username])
    if user && user.can_write_to?(@repository)
      render :text => "true"
    else
      render :text => "false"
    end
  end
  
  def confirm_delete
    @repository = @project.repositories.find_by_name!(params[:id])
  end
  
  def destroy
    @repository = @project.repositories.find_by_name!(params[:id])
    if @repository.can_be_deleted_by?(current_user)
      repo_name = @repository.name
      flash[:notice] = "The repository was deleted"
      @repository.destroy
      @project.create_event(Action::DELETE_REPOSITORY, @project, current_user, repo_name)
    else
      flash[:error] = "You're not the owner of this repository"
    end
    redirect_to project_path(@project)
  end
  
  private    
    def require_adminship
      unless @project.admin?(current_user)
        respond_to do |format|
          flash[:error] = "Sorry, only project admins are allowed to do that"
          format.html { redirect_to(project_path(@project)) }
          format.xml  { render :text => "Sorry, only project admins are allowed to do that", :status => :forbidden }
        end
        return
      end
    end
end
