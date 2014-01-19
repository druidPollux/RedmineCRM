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

class InvoiceTimeEntriesController < ApplicationController
  unloadable
  
  before_filter :find_project_by_project_id, :only => [:create, :new]
  
  include InvoicesHelper
  
  def new
    invoice = Invoice.new
    total_time = TimeEntry.sum(:hours, :conditions => {:issue_id => params[:issues_ids]}, :group => :activity_id)
    total_time.first
    total_time.each do |k, v|
      scope = Issue.scoped(:include => :time_entries,  :conditions => {:id => params[:issues_ids]})
      scope = scope.scoped(:conditions => ["#{TimeEntry.table_name}.activity_id = ?", k])
      issues = scope.all
      invoice.lines << invoice.lines.new(:description => issues.map(&:subject).join("\n"), :quantity => total_time[k])
    end  
    redirect_to :controller => "invoices", :action => "new", :copy_from => invoice, :project_id => @project    
  end

end
