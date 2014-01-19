class PagesPartsController < ApplicationController
  before_filter :find_page_and_part, :only => :create
  before_filter :find_pages_part, :only => [:destroy, :update]

  helper :cms
  helper :parts

  def create
    PagesPart.create(:page => @page, :part => @part)
    respond_to do |format|
      format.html { redirect_to :back }  
      format.js {render :action => "change"}
    end
  end

  def destroy
    @pages_part.destroy
    respond_to do |format|
      format.html { redirect_to :back }  
      format.js {render :action => "change"}
    end
  end  

  def update
    @pages_part.update_attributes(params[:pages_part])
    @pages_part.save
    respond_to do |format|
      format.html { redirect_to :back }  
      format.js {render :action => "change"}
    end    
  end

  def add
    @page.parts << @part
    @page.save
    respond_to do |format|
      format.html { redirect_to :back }  
      format.js {render :action => "change"}
    end
  end

  # def update
  #   @pages_part = PagesPart.find_by_part_id_and_page_id(@part, @page)
  #   @pages_part.update_attributes(params[:pages_part])
  #   @pages_part.save
  #   respond_to do |format|
  #     format.html { redirect_to :back }  
  #     format.js {render :action => "change"}
  #   end    
  # end

  def delete  
    @page.parts.delete(@part) if request.delete?
    respond_to do |format|
      format.html { redirect_to :back }
      format.js {render :action => "change"}
    end   
  end

private
  def find_pages_part
    @pages_part = PagesPart.find(params[:id])
    @part = @pages_part.part
    @page = @pages_part.page
    @pages_parts = @page.pages_parts.order_by_type
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_page_and_part
    @page = Page.find_by_name(params[:page_id])
    @part = Part.find(params[:part_id])
    @pages_parts = @page.pages_parts.order_by_type 
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
