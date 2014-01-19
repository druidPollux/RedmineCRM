class ProjectTabsController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id, :authorize
  before_filter :find_page

  helper :pages

  def show
    render_403 if @page.page_project && @page.page_project != @project 
  end

private

  def find_page
    tab_name = "project_tab_#{params[:tab]}".to_sym
    menu_items[:project_tabs][:actions][:show] = tab_name
    @page = Page.find_by_name(ContactsSetting["project_tab_#{params[:tab]}_page", @project.id])
    render_404 if @page.blank?   
  end

end
