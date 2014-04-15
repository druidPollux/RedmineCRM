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

class InvoiceMailsController < ApplicationController
  unloadable
  helper :invoices
  include InvoicesHelper

  before_filter :find_invoice, :authorize

  def new
  end

  def send_mail
    begin
      params[:message] = invoice_mail_macro(@invoice, params[:"message-content"])
      delivered = InvoicesMailer.invoice(@invoice, params).deliver
    rescue Exception => e
      flash[:error] = l(:notice_email_error, e.message)
    end
    flash[:notice] = l(:notice_email_sent, params[:to].blank? ? @invoice.contact.try(:primary_email).to_s : params[:to].to_s) if delivered

    redirect_back_or_default(invoice_path(@invoice))
  end

  def preview_mail
    @text = invoice_mail_macro(@invoice, params[:"message-content"])
    render :partial => 'common/preview'
  end

private

  def find_invoice
    @invoice = Invoice.find(params[:invoice_id], :include => [:project, :contact])
    @project ||= @invoice.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
