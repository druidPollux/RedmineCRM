module PagesHelper
   def page_breadcrumb(page)
    return unless page.parent
    pages = page.ancestors.reverse
    pages << page
    links = pages.map {|ancestor| link_to(h(ancestor.title), page_path(ancestor))}
    breadcrumb links
  end

  def pages_options_for_select(pages)
    options = []
    Page.page_tree(pages) do |page, level|
      label = (level > 0 ? '&nbsp;' * 2 * level + '&#187; ' : '').html_safe
      label << page.name
      options << [label, page.id]
    end
    options
  end 

  def pages_name_options_for_select(pages)
    options = []
    Page.page_tree(pages) do |page, level|
      label = (level > 0 ? '&nbsp;' * 2 * level + '&#187; ' : '').html_safe
      label << page.title
      options << [label, page.name]
    end
    options
  end   

  def change_page_status_link(page)
    url = {:controller => 'pages', :action => 'update', :id => page, :page => params[:page], :status => params[:status], :tab => nil}

    if page.active?
      link_to l(:button_lock), url.merge(:page => {:status_id => RedmineCms::STATUS_LOCKED}), :method => :put, :class => 'icon icon-lock'
    else
      link_to l(:button_unlock), url.merge(:page => {:status_id => RedmineCms::STATUS_ACTIVE}), :method => :put, :class => 'icon icon-unlock'
    end
  end

  def page_tree(pages, &block)
    Page.page_tree(pages, &block)
  end  

end
