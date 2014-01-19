Redmine::Plugin.register :redmine_cms do
  name 'Redmine CMS plugin'
  author 'RedmineCRM'
  description 'This is a CMS plugin for Redmine'
  version '0.0.3'
  url 'http://redminecrm.com/projects/cms'

  requires_redmine :version_or_higher => '2.1.2'   

  settings :default => {
    :use_localization => true,
    :base_layout => 'base'
  }, :partial => 'settings/cms'  

  project_module :project_tab do
    permission :view_project_tabs, { 
      :project_tabs => [:show]
    }    
    permission :manage_project_tabs, {
      :contacts_settings => :save
    }
  end

  Redmine::MenuManager.map :footer_menu do |menu|
    #empty
  end  

  Redmine::MenuManager.map :top_menu do |menu|
    #empty
  end  

  delete_menu_item(:top_menu, :home) 
  delete_menu_item(:top_menu, :"my_page")
  delete_menu_item(:top_menu, :projects)
  delete_menu_item(:top_menu, :help)
  delete_menu_item(:account_menu, :register)  

  delete_menu_item(:project_menu, :activity)
  delete_menu_item(:project_menu, :overview)

  10.downto(1) do |index|
    tab = "project_tab_#{index}".to_sym
    menu :project_menu, tab, {:controller => 'project_tabs', :action => 'show', :tab => index}, 
                             :first => :true,
                             :param => :project_id,
                             :caption => Proc.new{|p| ContactsSetting["project_tab_#{index}_caption".to_sym, p.id] || tab.to_s },
                             :if => Proc.new{|p| !ContactsSetting["project_tab_#{index}_caption".to_sym, p.id].blank? }

  end

  menu :top_menu, :cms, {:controller => 'settings', :action => 'plugin', :id => "redmine_cms"}, :first => true, :caption => :label_cms, :parent => :administration

  menu :admin_menu, :cms, {:controller => 'settings', :action => 'plugin', :id => "redmine_cms"}, :caption => :label_cms

end

require 'redmine_cms'
require 'redmine/menu'

CmsMenu.rebuild if ActiveRecord::Base.connection.table_exists?(:cms_menus)

