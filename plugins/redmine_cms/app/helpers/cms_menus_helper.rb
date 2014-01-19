module CmsMenusHelper

  def change_menu_status_link(cms_menu)
    url = {:controller => 'cms_menus', :action => 'update', :id => cms_menu, :cms_menu => params[:cms_menu], :status => params[:status], :tab => nil}

    if cms_menu.active?
      link_to l(:button_lock), url.merge(:cms_menu => {:status_id => RedmineCms::STATUS_LOCKED}), :method => :put, :class => 'icon icon-lock'
    else
      link_to l(:button_unlock), url.merge(:cms_menu => {:status_id => RedmineCms::STATUS_ACTIVE}), :method => :put, :class => 'icon icon-unlock'
    end
  end

  def menus_options_for_select(menus)
    options = []
    CmsMenu.menu_tree(menus) do |menu, level|
      label = (level > 0 ? '&nbsp;' * 2 * level + '&#187; ' : '').html_safe
      label << menu.name
      options << [label, menu.id]
    end
    options    
  end

  def menu_tree(menus, &block)
    CmsMenu.menu_tree(menus, &block)
  end

end
