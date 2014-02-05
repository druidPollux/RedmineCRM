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

class OrdersController < ApplicationController
  unloadable
  before_filter :find_order_project, :only => [:create, :new]
  before_filter :find_order, :only => [:edit, :show, :destroy, :update]
  before_filter :bulk_find_orders, :only => [:bulk_update, :bulk_edit, :bulk_destroy, :context_menu]
  before_filter :authorize, :except => [:index, :edit, :update, :destroy]
  before_filter :find_optional_project, :only => [:index]

  accept_api_auth :index, :show, :create, :update, :destroy

  helper :products
  helper :attachments
  helper :custom_fields
  helper :timelog
  helper :context_menus
  helper :issues
  helper :contacts
  helper :watchers
  helper :sort
  include SortHelper
  include ContactsHelper
  helper :queries
  include QueriesHelper
  helper :products
  include ProductsHelper

  def index
    retrieve_orders_query
    sort_init(@query.sort_criteria.empty? ? [['order_date', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a

    if @query.valid?
      case params[:format]
      when 'csv', 'pdf'
        @limit = Setting.issues_export_limit.to_i
      when 'atom'
        @limit = Setting.feeds_limit.to_i
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        @limit = per_page_option
      end

      @orders_count = orders_scope.count
      @orders_pages = Paginator.new @orders_count, @limit, params['page']
      @offset ||= @orders_pages.offset
      @orders = orders_scope.all(
        :include => [{:contact => [:avatar, :projects, :address]}, :author],
        :limit  =>  @limit,
        :order => sort_clause,
        :offset =>  @offset
      )


      respond_to do |format|
        format.html do
          if request.xhr?
            render :partial => orders_list_style, :layout => false
          else
            @ordered_amount = @query.order_amount
            @order_count_by_group = @query.order_count_by_group
            @today_sum = orders_sum_by_period("today")
            @current_week_sum = orders_sum_by_period("current_week")
            @last_week_sum = orders_sum_by_period("last_week")
            @current_month_sum = orders_sum_by_period("current_month")
            @last_month_sum = orders_sum_by_period("last_month")
            @current_year_sum = orders_sum_by_period("current_year")
          end
        end
        format.api
        format.atom { render_feed(@orders, :title => "#{@project || Setting.app_title}: #{l(:label_order_plural)}") }
        format.csv  { send_data(query_to_csv(@orders, @query, params), :type => 'text/csv; header=present', :filename => 'orders.csv') }
        format.pdf  { send_data(orders_to_pdf(@orders, @project, @query), :type => 'application/pdf', :filename => 'orders.pdf') }
      end
    else
      respond_to do |format|
        format.html { render(:template => 'orders/index', :layout => !request.xhr?) }
        format.any(:atom, :csv, :pdf) { render(:nothing => true) }
        format.api { render_validation_errors(@query) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def edit
  end

  def show
    @current_week_sum = orders_sum_by_period("current_week", @order.contact_id)
    @last_week_sum = orders_sum_by_period("last_week", @order.contact_id)
    @current_month_sum = orders_sum_by_period("current_month", @order.contact_id)
    @last_month_sum = orders_sum_by_period("last_month", @order.contact_id)
    @current_year_sum = orders_sum_by_period("current_year", @order.contact_id)

    @comments = @order.comments
    @comments.reverse! if User.current.wants_comments_in_reverse_order?
  end

  def new
    @order = Order.new
    @last_order_number = Order.last.try(:number)
    @order.assigned_to = User.current
    @order.currency = ContactsSetting.default_currency
    @order.order_date = Date.today
    @order.contact_id = params[:contact_id] if params[:contact_id]
    if params[:product_ids]
      products = Product.visible.find_all_by_id(params[:product_ids])
      products.each do |product|
        @order.lines.new(:product => product, :price => product.price, :quantity => 1)
      end
    end

    @order.lines.build if @order.lines.blank?
  end

  def create
    @order = Order.new
    @order.safe_attributes = params[:order]
    @order.project = @project
    @order.author = User.current
    if @order.save
      attachments = Attachment.attach_files(@order, (params[:attachments] || (params[:order] && params[:order][:uploads])))
      render_attachment_warning_if_needed(@order)

      flash[:notice] = l(:notice_successful_create)

      respond_to do |format|
        format.html { redirect_to order_path(@order) }
        format.api  { render :action => 'show', :status => :created, :location => order_url(@order) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@order) }
      end
    end

  end

  def update
    @order.safe_attributes = params[:order]
    if @order.save
      attachments = Attachment.attach_files(@order, (params[:attachments] || (params[:order] && params[:order][:uploads])))
      render_attachment_warning_if_needed(@order)
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_to order_path(@order) }
        format.api  { head :ok }
      end
    else
      respond_to do |format|
        format.html { render :action => "edit"}
        format.api  { render_validation_errors(@order) }
      end
    end
  end

  def destroy
    if @order.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:notice_unsuccessful_delete)
    end
    respond_to do |format|
      format.html { redirect_to :action => "index", :project_id => @order.project }
      format.api  { head :ok }
    end

  end

  def context_menu
    @order = @orders.first if (@orders.size == 1)
    @can = {:edit =>  @orders.collect{|c| c.editable_by?(User.current)}.inject{|memo,d| memo && d},
            :delete => @orders.collect{|c| c.destroyable_by?(User.current)}.inject{|memo,d| memo && d}
            }

    # @back = back_url
    render :layout => false
  end

  def bulk_update
    unsaved_order_ids = []
    @orders.each do |order|
      unless order.update_attributes(parse_params_for_bulk_order_attributes(params))
        # Keep unsaved order ids to display them in flash error
        unsaved_order_ids << order.id
      end
    end
    set_flash_from_bulk_contact_save(@orders, unsaved_order_ids)
    redirect_back_or_default({:controller => 'orders', :action => 'index', :project_id => @project})

  end

  def bulk_destroy
    @orders.each do |order|
      begin
        order.reload.destroy
      rescue ::ActiveRecord::RecordNotFound # raised by #reload if order no longer exists
        # nothing to do, order was already deleted (eg. by a parent)
      end
    end
    respond_to do |format|
      format.html { redirect_back_or_default(:action => 'index', :project_id => @project) }
      format.api  { head :ok }
    end
  end

  private

  def find_orders(pages=true)
    scope = Order.scoped({})
    scope = scope.by_project(@project.id) if @project
    scope = scope.scoped(:conditions => ["#{Order.table_name}.status_id = ?", params[:status_id]]) unless params[:status_id].blank? || params[:status_id] == 'o'
    scope = scope.open if params[:status_id] == 'o'


    sort_init 'order_date asc'
    sort_update 'status' => 'status_id',
                'number' => 'number',
                'order_date' => 'order_date',
                'contact' => "#{Contact.table_name}.last_name",
                'closed_date' => 'closed_date',
                'amount' => 'currency, amount',
                'created_at' => 'created_at',
                'title' => "#{Order.table_name}.title"

    scope = scope.includes(:contact)
    scope = scope.visible
    scope = scope.scoped(:order => sort_clause) if sort_clause

    @orders_count = scope.count
    @ordered_amount = scope.sum(:amount, :group => :currency)

    if pages
      @limit =  per_page_option
      @orders_pages = Paginator.new(self, @orders_count, @limit, params[:page])
      @offset = @orders_pages.current.offset

      scope = scope.scoped :limit  => @limit, :offset => @offset
      @orders = scope
    end

    scope
  end

  def parse_params_for_bulk_order_attributes(params)
    attributes = (params[:order] || {}).reject {|k,v| v.blank?}
    attributes.keys.each {|k| attributes[k] = '' if attributes[k] == 'none'}
    attributes[:custom_field_values].reject! {|k,v| v.blank?} if attributes[:custom_field_values]
    attributes
  end

  def bulk_find_orders
    @orders = Order.find_all_by_id(params[:id] || params[:ids], :include => :project)
    raise ActiveRecord::RecordNotFound if @orders.empty?
    if @orders.detect {|order| !order.visible?}
      deny_access
      return
    end
    @projects = @orders.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_order_project
    project_id = params[:project_id] || (params[:order] && params[:order][:project_id])
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_order
    @order = Order.find(params[:id], :include => [:project])
    raise Unauthorized unless @order.visible?
    @project ||= @order.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def orders_sum_by_period(peroid, contact_id=nil)
     retrieve_date_range(peroid)
     scope = Order.scoped({})
     scope = scope.visible
     scope = scope.by_project(@project.id) if @project
     scope = scope.scoped(:conditions => ["#{Order.table_name}.order_date >= ? AND #{Order.table_name}.order_date < ?", @from, @to])
     scope = scope.scoped(:conditions => ["#{Order.table_name}.contact_id = ?", contact_id]) unless contact_id.blank?
     # debugger
     scope.sum(:amount, :group => :currency)
  end

  def orders_scope(options={})
    options[:search] = params[:search] unless params[:search].blank?
    @query.results_scope(options)
  end

end
