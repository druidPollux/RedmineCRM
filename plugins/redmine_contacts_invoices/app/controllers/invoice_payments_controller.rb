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

class InvoicePaymentsController < ApplicationController
  unloadable

  before_filter :find_invoice_payment_invoice, :only => [:create, :new]
  before_filter :find_invoice_payment, :only => [:edit, :show, :destroy, :update]  
  before_filter :bulk_find_payments, :only => [:bulk_update, :bulk_edit, :bulk_destroy, :context_menu]
  before_filter :authorize, :except => [:index, :edit, :update, :destroy]
  before_filter :find_optional_project, :only => [:index] 

  accept_api_auth :index, :show, :create, :update, :destroy

  def new
    @invoice_payment = InvoicePayment.new(:amount => @invoice.remaining_balance, :payment_date => Date.today)
  end

  def create
    @invoice_payment = InvoicePayment.new(params[:invoice_payment])  
    # @invoice.contacts = [Contact.find(params[:contacts])]
    @invoice_payment.invoice = @invoice 
    @invoice_payment.author = User.current  
    if @invoice_payment.save
      attachments = Attachment.attach_files(@invoice_payment, (params[:attachments] || (params[:invoice_payment] && params[:invoice_payment][:uploads])))
      render_attachment_warning_if_needed(@invoice_payment)

      flash[:notice] = l(:notice_successful_create)
      
      respond_to do |format|
        format.html { redirect_to invoice_path(@invoice) }
        format.api  { render :action => 'show', :status => :created, :location => invoice_payment_url(@invoice_payment) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@invoice_payment) }
      end
    end
  end

  def destroy  
    if @invoice_payment.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:notice_unsuccessful_save)
    end
    respond_to do |format|
      format.html { redirect_to invoice_path(@invoice) }
      format.api  { head :ok }
    end
  end

  private

  def find_invoice_payment_invoice
    invoice_id = params[:invoice_id] || (params[:invoice_payment] && params[:invoice_payment][:invoice_id])
    @invoice = Invoice.find(invoice_id)
    @project = @invoice.project
    project_id = params[:project_id] || (params[:invoice_payment] && params[:invoice_payment][:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def find_invoice_payment
    @invoice_payment = InvoicePayment.find(params[:id], :include => {:invoice => :project})
    @project ||= @invoice_payment.project
    @invoice ||= @invoice_payment.invoice
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
