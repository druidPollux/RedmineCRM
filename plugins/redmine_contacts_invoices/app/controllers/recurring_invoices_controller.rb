# This file is a part of Redmine Invoices (redmine_contacts_invoices) plugin,
# invoicing plugin for Redmine
#
# Copyright (C) 2011-2013 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_contacts_invoices is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts_invoices is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts_invoices.  If not, see <http://www.gnu.org/licenses/>.

class RecurringInvoicesController < ApplicationController
  unloadable

  before_filter :find_invoice_project, :only => [:create, :new]
  before_filter :find_invoice, :only => [:edit, :show, :destroy, :update, :client_view]
  before_filter :bulk_find_invoices, :only => [:bulk_update, :bulk_edit, :bulk_destroy, :context_menu]
  before_filter :authorize, :except => [:index, :edit, :update, :destroy, :auto_complete, :client_view]
  before_filter :find_optional_project, :only => [:index]

  accept_api_auth :index, :show, :create, :update, :destroy

  helper :attachments
  helper :contacts
  helper :issues
  helper :timelog
  helper :watchers
  helper :custom_fields
  helper :sort
  helper :context_menus
  include SortHelper
  include RedmineInvoices::InvoiceReports
  include ContactsHelper
  include InvoicesHelper

  def index
    # retrieve_invoices_query

    respond_to do |format|
      format.html do
         params[:status_id] = "o" unless params.has_key?(:status_id)
         @invoices = find_invoices
         request.xhr? ? render( :partial => RedmineRecurringInvoices.settings[:invoices_excerpt_invoice_list] ? 'excerpt_list' : 'list', :layout => false, :locals => {:invoices => @invoices}) : last_comments
      end
      format.api { @invoices = find_invoices }
    end
  end

  def show

    @invoice_lines = @recurring_invoice.lines || []
    respond_to do |format|
      format.html
      format.api
      format.pdf do
        send_data(invoice_to_pdf(@recurring_invoice), :type => 'application/pdf', :filename => "invoice-#{@recurring_invoice.number}.pdf", :disposition => 'inline')
      end
    end
  end

  def new
    @recurring_invoice = RecurringInvoice.new
    @recurring_invoice.number = RecurringInvoice.generate_invoice_number(@project)
    @recurring_invoice.invoice_date = Date.today
    @recurring_invoice.contact = Contact.find_by_id(params[:contact_id]) if params[:contact_id]
    @recurring_invoice.assigned_to = User.current
    @recurring_invoice.currency ||= ContactsSetting.default_currency

    @recurring_invoice.lines.build if @recurring_invoice.lines.blank?

    @last_invoice_number = RecurringInvoice.last.try(:number)
  end

  def create
    @recurring_invoice = RecurringInvoice.new(params[:invoice])
    @recurring_invoice.project ||= @project
    @recurring_invoice.author = User.current
    if @recurring_invoice.save
      flash[:notice] = l(:notice_successful_create)
      respond_to do |format|
        format.html { redirect_to :action => "show", :id => @recurring_invoice }
        format.api  { render :action => 'show', :status => :created, :location => invoice_url(@invoice) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@invoice) }
      end
    end
  end

  def edit
    (render_403; return false) unless @recurring_invoice.editable_by?(User.current)
    @invoice_lines = @recurring_invoice.lines || []
    respond_to do |format|
      format.html { }
      format.xml  { }
    end
  end

  def update
    (render_403; return false) unless @recurring_invoice.editable_by?(User.current)
    if @recurring_invoice.update_attributes(params[:invoice])
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_to :action => "show", :id => @recurring_invoice }
        format.api  { head :ok }
      end
    else
      respond_to do |format|
        format.html { render :action => "edit"}
        format.api  { render_validation_errors(@invoice) }
      end
    end
  end

  def destroy
    (render_403; return false) unless @recurring_invoice.destroyable_by?(User.current)
    if @recurring_invoice.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:notice_unsuccessful_save)
    end
    respond_to do |format|
      format.html { redirect_to :action => "index", :project_id => @project }
      format.api  { head :ok }
    end

  end

  def send_mail
  end

  def context_menu
    @recurring_invoice = @invoices.first if (@invoices.size == 1)
    @can = {:edit =>  @invoices.collect{|c| c.editable_by?(User.current)}.inject{|memo,d| memo && d},
            :delete => @invoices.collect{|c| c.destroyable_by?(User.current)}.inject{|memo,d| memo && d},
            :create => User.current.allowed_to?(:edit_invoices, @projects) || User.current.allowed_to?(:edit_own_invoices, @projects),
            :change_status => @invoices.collect{|c| !c.is_paid? }.inject{|memo,d| memo && d},
            :pdf => User.current.allowed_to?(:view_invoices, @projects)
            }
    @back = back_url
    render :layout => false
  end

  def bulk_destroy
    @invoices.each do |invoice|
      begin
        invoice.reload.destroy
      rescue ::ActiveRecord::RecordNotFound # raised by #reload if issue no longer exists
        # nothing to do, issue was already deleted (eg. by a parent)
      end
    end
    respond_to do |format|
      format.html { redirect_back_or_default({:action => "index", :project_id => params[:project_id]}) }
      format.api  { head :ok }
    end
  end

  def bulk_update
    unsaved_invoice_ids = []
    @invoices.each do |invoice|
      unless invoice.update_attributes(parse_params_for_bulk_invoice_attributes(params))
        # Keep unsaved issue ids to display them in flash error
        unsaved_invoice_ids << invoice.id
      end
    end
    set_flash_from_bulk_contact_save(@invoices, unsaved_invoice_ids)
    redirect_back_or_default({:controller => 'invoices', :action => 'index', :project_id => @project})

  end

  def auto_complete
    @invoices = []
    q = (params[:q] || params[:term]).to_s.strip
    scope = RecurringInvoice.visible
    scope = scope.limit(params[:limit] || 10)
    scope = scope.where(:currency => params[:currency]) if params[:currency]
    scope = scope.where(:status_id => params[:status_id]) if params[:status_id]
    scope = scope.where(:project_id => params[:project_id]) if params[:project_id]
    scope = scope.live_search(q) unless q.blank?
    @invoices = scope.order(:number)

    render :text => @invoices.map{|invoice| {
                                          'id' => invoice.id,
                                          'label' => "##{invoice.number} - #{format_date(invoice.invoice_date)}: (#{invoice.amount_to_s})",
                                          'value' => invoice.id
                                          }
                                 }.to_json
  end

  private

  def last_comments
    @last_comments = []
  end

  def find_invoice_project
    project_id = params[:project_id] || (params[:invoice] && params[:invoice][:project_id])
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_invoices(pages=true)
    scope = RecurringInvoice.scoped({})
    scope = scope.by_project(@project.id) if @project
    scope = scope.scoped(:conditions => ["#{RecurringInvoice.table_name}.status_id = ?", params[:status_id]]) if (!params[:status_id].blank? && params[:status_id] != "o" && params[:status_id] != "d")
    scope = scope.open if (params[:status_id] == "o") || (params[:status_id] == "d")
    scope = scope.scoped(:conditions => ["#{RecurringInvoice.table_name}.contact_id = ?", params[:contact_id]]) if !params[:contact_id].blank?
    scope = scope.scoped(:conditions => ["#{RecurringInvoice.table_name}.assigned_to_id = ?", params[:assigned_to_id]]) if !params[:assigned_to_id].blank?
    scope = scope.scoped(:conditions => ["#{RecurringInvoice.table_name}.due_date <= ? AND #{RecurringInvoice.table_name}.status_id = ?", Date.today, RecurringInvoice::SENT_INVOICE]) if (params[:status_id] == "d")
    scope = scope.scoped(:conditions => ["#{RecurringInvoice.table_name}.due_date <= ?", params[:due_date].to_date]) if (!params[:due_date].blank? && is_date?(params[:due_date]))

    sort_init 'status', 'number'
    sort_update 'invoice_date' => 'invoice_date',
                'status' => 'status_id',
                'amount' => 'currency, amount',
                'due_date' => 'due_date',
                'updated_at' => "#{RecurringInvoice.table_name}.updated_at",
                'number' => 'number'

    scope = scope.visible

    @invoices_count = scope.count
    @paid_amount = scope.sent_or_paid.sum(:balance, :group => :currency)
    @invoiced_amount = scope.sum(:amount, :group => :currency)
    @due_amount = scope.sent_or_paid.sum("#{RecurringInvoice.table_name}.amount - #{RecurringInvoice.table_name}.balance", :group => :currency)
    scope = scope.scoped(:order => sort_clause) if sort_clause
    if pages
      @limit =  per_page_option
      @invoices_pages = Paginator.new(self, @invoices_count,  @limit, params[:page])
      @offset = @invoices_pages.current.offset

      scope = scope.scoped :limit  => @limit, :offset => @offset
      @invoices = scope

      fake_name = @invoices.first.amount if @invoices.length > 0 #without this patch paging does not work
    end

    scope
  end

  # Filter for bulk issue invoices
  def bulk_find_invoices
    @invoices = RecurringInvoice.find_all_by_id(params[:id] || params[:ids], :include => :project)
    raise ActiveRecord::RecordNotFound if @invoices.empty?
    raise Unauthorized unless @invoices.all?(&:visible?)
    @projects = @invoices.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_invoice
    @recurring_invoice = RecurringInvoice.find(params[:id], :include => [:project, :contact])
    @project ||= @recurring_invoice.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def parse_params_for_bulk_invoice_attributes(params)
    attributes = (params[:invoice] || {}).reject {|k,v| v.blank?}
    attributes.keys.each {|k| attributes[k] = '' if attributes[k] == 'none'}
    attributes[:custom_field_values].reject! {|k,v| v.blank?} if attributes[:custom_field_values]
    attributes
  end

end


