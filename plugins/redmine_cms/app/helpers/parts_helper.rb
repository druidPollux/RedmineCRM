module PartsHelper
  def change_part_status_link(part)
    url = {:controller => 'parts', :action => 'update', :id => part, :part => params[:part], :status => params[:status], :tab => nil}

    if part.active?
      link_to l(:button_lock), url.merge(:part => {:status_id => RedmineCms::STATUS_LOCKED}, :unlock => true), :method => :put, :class => 'icon icon-lock'
    else
      link_to l(:button_unlock), url.merge(:part => {:status_id => RedmineCms::STATUS_ACTIVE}, :unlock => true), :method => :put, :class => 'icon icon-unlock'
    end
  end  

  def parts_type_collection
    [["Content", "content"], ["Sidebar", "sidebar"], ["Header", "header"], ["Footer", "footer"], ["Header tags", "header_tags"]]
  end

  def parts_option_for_select
    parts = Part.order(:part_type).order(:content_type)
    return "" unless parts.any?
    previous_group = parts.first.part_type 
    s = "<optgroup label=\"#{ERB::Util.html_escape(parts.first.part_type)}\">".html_safe
    parts.each do |part|
      if part.part_type != previous_group
        reset_cycle
        s << '</optgroup>'.html_safe
        s << "<optgroup label=\"#{ERB::Util.html_escape(part.part_type)}\">".html_safe
        previous_group = part.part_type
      end
      s << %Q(<option value="#{ERB::Util.html_escape(part.id)}">#{ERB::Util.html_escape(part.name)} (#{part.content_type})</option>).html_safe
    end
    s << '</optgroup>'
    s.html_safe
  end 
end
