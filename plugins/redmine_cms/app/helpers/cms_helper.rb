module CmsHelper
  def cms_change_status_link(obj_name, obj)
    return unless obj.respond_to?(:status_id) 
    url = {:controller => "#{obj_name}s", :action => 'update', :id => obj, obj_name.to_sym => params[obj_name.to_sym], :status => params[:status], :tab => nil}

    if obj.active?
      link_to l(:button_lock), url.merge(obj_name.to_sym => {:status_id => RedmineCms::STATUS_LOCKED}, :unlock => true), :method => :put, :remote => :true, :class => 'icon icon-lock'
    else
      link_to l(:button_unlock), url.merge(obj_name.to_sym => {:status_id => RedmineCms::STATUS_ACTIVE}, :unlock => true), :method => :put, :remote => :true, :class => 'icon icon-unlock'
    end
  end 

  def cms_reorder_links(name, url, method = :post)
    link_to(image_tag('2uparrow.png', :alt => l(:label_sort_highest)),
            url.merge({"#{name}[move_to]" => 'highest'}),
            :remote => true,
            :method => method, :title => l(:label_sort_highest)) +
    link_to(image_tag('1uparrow.png',   :alt => l(:label_sort_higher)),
            url.merge({"#{name}[move_to]" => 'higher'}),
            :remote => true,
            :method => method, :title => l(:label_sort_higher)) +
    link_to(image_tag('1downarrow.png', :alt => l(:label_sort_lower)),
            url.merge({"#{name}[move_to]" => 'lower'}),
            :remote => true,
            :method => method, :title => l(:label_sort_lower)) +
    link_to(image_tag('2downarrow.png', :alt => l(:label_sort_lowest)),
            url.merge({"#{name}[move_to]" => 'lowest'}),
            :remote => true,
            :method => method, :title => l(:label_sort_lowest))
  end  
end