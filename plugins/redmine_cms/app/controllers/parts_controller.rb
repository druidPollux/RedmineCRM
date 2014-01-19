class PartsController < ApplicationController
  unloadable
  before_filter :require_admin
  before_filter :find_part, :except => [:index, :new, :create]

  helper :attachments
  helper :cms

  def index
    redirect_to :controller => 'settings', :action => 'plugin', :id => "redmine_cms", :tab => "parts"
  end

  def show
  end

  def edit
  end

  def new
    @part = Part.new(:content_type => 'textile')
    @part.copy_from(params[:copy_from]) if params[:copy_from]
  end

  def refresh
    expire_fragment(@part)
  end

  def update
    @part.assign_attributes(params[:part])
    @part.save_attachments(params[:attachments])
    if @part.save
      render_attachment_warning_if_needed(@part)
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html do 
          if params[:unlock] 
            redirect_to :controller => 'settings', :action => 'plugin', :id => "redmine_cms", :tab => "parts"
          else
            redirect_to :action =>"show", :id => @part
          end
        end
        format.js {render :nothing => true}
      end


    else
      render :action => 'edit'
    end
  end

  def create
    @part = Part.new(params[:part])
    @part.save_attachments(params[:attachments])
    if @part.save
      render_attachment_warning_if_needed(@part)
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action =>"show", :id => @part
    else
      render :action => 'new'
    end
  end 

  def destroy
    @part.destroy
    redirect_to :controller => 'settings', :action => 'plugin', :id => "redmine_cms", :tab => "parts"
  end    

private
  def find_part
    @part = Part.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
