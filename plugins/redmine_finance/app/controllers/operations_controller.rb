# This file is a part of Redmine Finance (redmine_finance) plugin,
# simple accounting plugin for Redmine
#
# Copyright (C) 2011-2013 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_finance is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_finance is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_finance.  If not, see <http://www.gnu.org/licenses/>.

class OperationsController < ApplicationController
  unloadable

  before_filter :find_operation, :only => [:show, :edit, :update, :destroy]
  before_filter :find_operation_project, :only => [:new, :create]
  before_filter :find_optional_project, :only => :index
  before_filter :bulk_find_operations, :only => [:bulk_update, :bulk_edit, :bulk_destroy, :context_menu]
  before_filter :authorize, :except => [:index, :auto_complete]
  before_filter :find_project_by_project_id, :only => :auto_complete

  accept_api_auth :index, :show, :create, :update, :destroy

  helper :contacts
  helper :watchers
  helper :custom_fields
  helper :timelog
  helper :operations
  helper :attachments
  helper :issues
  helper :context_menus
  include OperationsHelper
  include ContactsHelper
  include AttachmentsHelper

  def index
    @operations = find_operations
    @acconts = @project ? @project.accounts.visible : Account.visible
    respond_to do |format|
      format.html do
        @operations_debit = operations_sum_by_currency
        @operations_credit = operations_sum_by_currency(false)
      end
      format.api
      format.csv { send_data(operations_to_csv(find_operations(false)), :type => 'text/csv; header=present', :filename => 'operations.csv') }
    end
  end

  def new
    @operation = Operation.new
    @operation.account_id = params[:account_id]
    @operation.contact_id = params[:contact_id]
    @operation.operation_date = Time.now
    @operation.copy_from(params[:copy_from]) if params[:copy_from]
  end

  def create
    @operation = Operation.new(params[:operation])
    @operation.author = User.current
    update_operation_time

    if @operation.save
      flash[:notice] = l(:notice_successful_create)

      respond_to do |format|
        format.html { redirect_to :action => "show", :id => @operation }
        format.api  { render :action => 'show', :status => :created, :location => operation_url(@operation, :project_id => @project) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@operation) }
      end
    end
  end

  def update
    (render_403; return false) unless @operation.editable_by?(User.current)
    @operation.attributes = params[:operation]
    update_operation_time
    if @operation.save
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_to :action => "show", :id => @operation }
        format.api  { head :ok }
      end
    else
      respond_to do |format|
        format.html { render :action => "edit"}
        format.api  { render_validation_errors(@operation) }
      end
    end
  end

  def destroy
    (render_403; return false) unless @operation.destroyable_by?(User.current)
    if @operation.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:notice_unsuccessful_save)
    end
    respond_to do |format|
      format.html { redirect_to :action => "index", :project_id => @operation.project }
      format.api  { head :ok }
    end

  end

  def context_menu
    @operation = @operations.first if (@operations.size == 1)
    @can = {:edit =>  @operations.collect{|c| c.editable_by?(User.current)}.inject{|memo,d| memo && d},
            :delete => @operations.collect{|c| c.destroyable_by?(User.current)}.inject{|memo,d| memo && d}
            }

    # @back = back_url
    render :layout => false
  end

  def edit
  end

  def show
    @comments = @operation.comments
    @comments.reverse! if User.current.wants_comments_in_reverse_order?
  end

  def bulk_destroy
    @operations.each do |operation|
      begin
        operation.reload.destroy
      rescue ::ActiveRecord::RecordNotFound # raised by #reload if issue no longer exists
        # nothing to do, issue was already deleted (eg. by a parent)
      end
    end
    respond_to do |format|
      format.html { redirect_back_or_default(:action => 'index', :project_id => @project) }
      format.api  { head :ok }
    end
  end

  def auto_complete
    @operations = []
    q = (params[:q] || params[:term]).to_s.strip
    scope = Operation.visible
    scope = scope.scoped.limit(params[:limit] || 10)
    scope = scope.live_search(q) unless q.blank?
    scope = scope.joins(:account).where(:accounts => {:project_id => @project}) if @project
    @operations = scope.sort!{|x, y| x.operation_date <=> y.operation_date }

    render :text => @operations.map{|operation| {
                                          'id' => operation.id,
                                          'label' => "#{operation.category.name} ##{operation.id} - #{format_date(operation.operation_date)}: (#{operation.amount_to_s})",
                                          'value' => operation.id
                                          }
                                 }.to_json
  end

  private

  def operations_sum_by_currency(is_income = true, options = {})
    scope = find_operations(false, false)
    scope = is_income ? scope.income : scope.outcome
    scope.sum(:amount, :group => "#{Account.table_name}.currency")
  end

  def find_operation
    @operation = Operation.find(params[:id], :include => [{:account => :project}, :contact])
    raise Unauthorized unless @operation.visible?
    @project ||= @operation.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_operations(pages=true, sort=true)
    from, to = RedmineContacts::DateUtils.retrieve_date_range(params[:period].to_s)
    scope = Operation.scoped({})
    scope = scope.joins(:account => :project).where(:accounts => {:project_id => @project}) if @project
    scope = scope.includes(:contact, :category)

    scope = scope.where(:category_id => params[:category_id]) unless params[:category_id].blank?
    scope = scope.where(:account_id => params[:account_id]) unless params[:account_id].blank?
    scope = scope.where(:contact_id => params[:contact_id]) unless params[:contact_id].blank?
    scope = scope.where(["#{Operation.table_name}.operation_date BETWEEN ? AND ?", from, to]) if from && to

    scope = scope.order("#{Operation.table_name}.operation_date DESC") if sort
    scope = scope.visible

    @operations_count = scope.count

    if pages
      @limit =  per_page_option
      @operations_pages = Paginator.new(self, @operations_count, @limit, params[:page])
      @offset = @operations_pages.current.offset

      scope = scope.scoped :limit  => @limit, :offset => @offset
      @operations = scope

      # fake_name = @operations.first.price if @operations.length > 0 #without this patch paging does not work
    end

    scope
  end

  def find_operation_project
    project_id = params[:project_id] || (params[:operation] && params[:operation][:project_id])
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def bulk_find_operations
    @operations = Operation.find_all_by_id(params[:id] || params[:ids], :include => {:account => :project})
    raise ActiveRecord::RecordNotFound if @operations.empty?
    if @operations.detect {|operation| !operation.visible?}
      deny_access
      return
    end
    @projects = @operations.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def update_operation_time
    if params[:operation_time] && params[:operation_time].to_s.gsub(/\s/, "").match(/^(\d{1,2}):(\d{1,2})$/)
      @operation.operation_date = @operation.operation_date.change({:hour => $1.to_i % 24, :min => $2.to_i % 60})
    end
  end

end
