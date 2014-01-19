class CmsMenusController < ApplicationController
  unloadable

  layout 'admin'
  before_filter :require_admin
  before_filter :find_menu, :except => [:index, :new, :create]

  helper :cms

  def index
    redirect_to :controller => 'settings', :action => 'plugin', :id => "redmine_cms", :tab => "cms_menus"
  end

  def edit
    
  end

  def new
    @cms_menu = CmsMenu.new
  end

  def update
    @cms_menu.assign_attributes(params[:cms_menu])
    if @cms_menu.save
      flash[:notice] = l(:notice_successful_update)
      @cms_menus = CmsMenu.all
      respond_to do |format|
        format.html { redirect_to :back }  
        format.js {render :action => "change"}
      end    
      # redirect_to :controller => 'pages', :action => 'index', :tab => 'cms_menus'
    else
      render :action => 'edit'
    end
  end

  def create
    @cms_menu = CmsMenu.new(params[:cms_menu])
    if @cms_menu.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'edit', :id => @cms_menu
    else
      render :action => 'new'
    end
  end 

  def destroy
    @cms_menu.destroy
    redirect_to :controller => 'settings', :action => 'plugin', :id => "redmine_cms", :tab => "cms_menus"
  end  

private
 def find_menu
  @cms_menu = CmsMenu.find(params[:id])
 end

end
