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

class InvoiceCommentsController < ApplicationController
  unloadable
  default_search_scope :invoices
  model_object Invoice
  before_filter :find_model_object
  before_filter :find_project_from_association
  before_filter :authorize

  def create
    raise Unauthorized unless @invoice.commentable?

    @comment = Comment.new
    @comment.safe_attributes = params[:comment]
    @comment.author = User.current
    if @invoice.comments << @comment
      flash[:notice] = l(:label_comment_added)
    end

    redirect_to :controller => 'invoices', :action => 'show', :id => @invoice
  end

  def destroy
    @invoice.comments.find(params[:comment_id]).destroy
    redirect_to :controller => 'invoices', :action => 'show', :id => @invoice
  end

  private

  # ApplicationController's find_model_object sets it based on the controller
  # name so it needs to be overriden and set to @invoice instead
  def find_model_object
    super
    @invoice = @object
    @comment = nil
    @invoice
  end
end
