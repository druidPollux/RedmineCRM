# encoding: utf-8
#
# This file is a part of Redmine Products (redmine_products) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2014 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_products is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_products is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_products.  If not, see <http://www.gnu.org/licenses/>.

module ProductsHelper

  def product_tag(product, options={})
    image_size = options.delete(:size) || 16
    if product.visible? && !options[:no_link]
      image = link_to(product_image_tag(product, :size => image_size), product_path(product), :class => "avatar")
      product_name = link_to product.name, product_path(product)
    else
      image = product_image_tag(product, :size => image_size)
      product_name = product.name
    end

    case options.delete(:type).to_s
    when "image"
      image.html_safe
    when "plain"
      product_name.html_safe
    else
      content_tag(:span, "#{image} #{product_name}".html_safe, :class => "product")
    end
  end

  def products_check_box_tags(name, products)
    s = ''
    products.each do |product|
      s << "<label>#{ check_box_tag name, product.id, false, :id => nil } #{product_tag(product, :no_link => true)}#{' (' + product.price_to_s + ')' unless product.price.blank?}</label>\n"
    end
    s.html_safe
  end


  def label_with_currency(label, currency)
    l(label).mb_chars.capitalize.to_s + (currency.blank? ? '' : " (#{currency})")
  end

  def products_list_style
    'list_excerpt'
  end

  def collection_product_status_names
    [[:active, Product::ACTIVE_PRODUCT],
     [:inactive, Product::INACTIVE_PRODUCT]]
  end

  def collection_product_statuses
    [[l(:label_products_status_active), Product::ACTIVE_PRODUCT],
     [l(:label_products_status_inactive), Product::INACTIVE_PRODUCT]]
  end

  def collection_for_product_status_for_select(status_id)
    collection = collection_product_statuses.map{|s| [s[0], s[1].to_s]}
    collection.insert 0, [l(:label_all), ""]
    options_for_select(collection, status_id)

  end

  def products_is_no_filters
    (params[:status_id] == 'o' && (params[:period].blank? || params[:period] == 'all') && params[:contact_id].blank?)
  end

  def product_tag_url(tag_name, options={})
    {:controller => 'products',
     :action => 'index',
     :set_filter => 1,
     :project_id => @project,
     :tag => tag_name}.merge(options)
  end

  def product_tag_link(tag_name, options={})
    style = ContactsSetting.monochrome_tags? ? {} : {:style => "background-color: #{tag_color(tag_name)}"}
    tag_count = options.delete(:count)
    tag_title = tag_count ? "#{tag_name} (#{tag_count})" : tag_name
    link = link_to tag_title, product_tag_url(tag_name), options
    content_tag(:span, link, {:class => "tag-label-color"}.merge(style))
  end

  def product_tag_links(tag_list, options={})
    content_tag(
              :span,
              tag_list.map{|tag| product_tag_link(tag, options)}.join(' ').html_safe,
              :class => "tag_list") if tag_list
  end

  def product_image_tag(product, options = { })
    options[:size] ||= "64"
    options[:width] ||= options[:size]
    options[:height] ||= options[:size]
    options.merge!({:class => "gravatar"})

    product_icon = "product.png"

    if (image = product.image) && image.readable?
      product_image_url = url_for :controller => "attachments", :action => "contacts_thumbnail", :id => image, :size => options[:size]
      if options[:full_size]
        link_to(image_tag(product_image_url, options), :controller => 'attachments', :action => 'download', :id => image, :filename => image.filename)
      else
        image_tag(product_image_url, options)
      end
    else
      image_tag(product_icon, options.merge({:plugin => "redmine_products"}))
    end

  end

  def product_line_to_s(line)
    "#{line.product ? line.product.name : line.description} - #{line.price_to_s} x #{line.quantity}#{' - ' + "%.2f" % line.discount.to_f + '%' unless line.discount.blank? || line.discount == 0} = #{line.total_to_s}"
  end

  def order_status_tag(order_status)
    return '' unless order_status
    status_tag = content_tag(:span, order_status.name)
    content_tag(:span, status_tag, :class => "tag-label-color order-status", :style => "background-color:#{order_status.color_name};color:white;")
  end

  def collection_for_order_status_for_select
    OrderStatus.all.collect{|s| [s.name, s.id.to_s]}
  end

  def orders_list_style
    'list_excerpt'
  end

  def orders_link_to_remove_fields(name, f, options={})
    f.hidden_field(:_destroy) + link_to_function(name, "remove_order_fields(this);", options)
  end

  def orders_link_to_add_fields(name, f, association, options={})
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    link_to_function(name, "add_fields(this, '#{association}', '#{escape_javascript(fields)}')", options={})
  end

  def retrieve_orders_query
    if !params[:order_query_id].blank?
      cond = "project_id IS NULL"
      cond << " OR project_id = #{@project.id}" if @project
      @query = OrderQuery.find(params[:order_query_id], :conditions => cond)
      raise ::Unauthorized unless @query.visible?
      @query.project = @project
      session[:orders_query] = {:id => @query.id, :project_id => @query.project_id}
      sort_clear
    elsif api_request? || params[:set_filter] || session[:orders_query].nil? || session[:orders_query][:project_id] != (@project ? @project.id : nil)
      # Give it a name, required to be valid
      @query = OrderQuery.new(:name => "_")
      @query.project = @project
      @query.build_from_params(params)
      session[:orders_query] = {:project_id => @query.project_id, :filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names}
    else
      # retrieve from session
      @query = OrderQuery.find_by_id(session[:orders_query][:id]) if session[:orders_query][:id]
      @query ||= OrderQuery.new(:name => "_", :filters => session[:orders_query][:filters], :group_by => session[:orders_query][:group_by], :column_names => session[:orders_query][:column_names])
      @query.project = @project
    end
  end

end
