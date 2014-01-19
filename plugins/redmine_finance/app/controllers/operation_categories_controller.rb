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

class OperationCategoriesController < ApplicationController
  unloadable

  layout 'admin'

  before_filter :require_admin

  def new
    @category = OperationCategory.new
  end

  def create
    @category = OperationCategory.new(params[:category])
    if @category.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action =>"plugin", :id => "redmine_finance", :controller => "settings", :tab => 'operation_categories'
    else
      render :action => 'new'
    end
  end

  def edit
    @category = OperationCategory.find(params[:id])
  end

  def update
    @category = OperationCategory.find(params[:id])
    if @category.update_attributes(params[:category])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action =>"plugin", :id => "redmine_finance", :controller => "settings", :tab => 'operation_categories'
    else
      render :action => 'edit'
    end
  end

  def destroy
    OperationCategory.find(params[:id]).destroy
    redirect_to :action =>"plugin", :id => "redmine_finance", :controller => "settings", :tab => 'operation_categories'
  rescue
    flash[:error] = l(:label_finance_can_not_delete_category)
    redirect_to :action =>"plugin", :id => "redmine_finance", :controller => "settings", :tab => 'operation_categories'
  end

end
