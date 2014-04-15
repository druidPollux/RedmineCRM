# encoding: utf-8
#
# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2014 RedmineCRM
# http://www.redminecrm.com/
#
# redmine_agile is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_agile is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_agile.  If not, see <http://www.gnu.org/licenses/>.

module AgileBoardHelper

  def retrieve_agile_query
    if !params[:query_id].blank?
      cond = "project_id IS NULL"
      cond << " OR project_id = #{@project.id}" if @project
      @query = AgileQuery.where(cond).find(params[:query_id])
      raise ::Unauthorized unless @query.visible?
      @query.project = @project
      session[:agile_query] = {:id => @query.id, :project_id => @query.project_id}
      sort_clear
    elsif api_request? || params[:set_filter] || session[:agile_query].nil? || session[:agile_query][:project_id] != (@project ? @project.id : nil)
      @query = AgileQuery.new(:name => "_")
      @query.project = @project
      @query.build_from_params(params)
      session[:agile_query] = {:project_id => @query.project_id, :filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names}
    else
      # retrieve from session
      @query = nil
      @query = AgileQuery.find_by_id(session[:agile_query][:id]) if session[:agile_query][:id]
      @query ||= AgileQuery.new(:name => "_", :filters => session[:agile_query][:filters], :group_by => session[:agile_query][:group_by], :column_names => session[:agile_query][:column_names])
      @query.project = @project
    end
  end

  def retrieve_agile_query_from_session
    if session[:agile_query]
      if session[:agile_query][:id]
        @query = AgileQuery.find_by_id(session[:agile_query][:id])
        return unless @query
      else
        @query = AgileQuery.new(:name => "_", :filters => session[:agile_query][:filters], :group_by => session[:agile_query][:group_by], :column_names => session[:agile_query][:column_names])
      end
      if session[:agile_query].has_key?(:project_id)
        @query.project_id = session[:agile_query][:project_id]
      else
        @query.project = @project
      end
      @query
    end
  end

  def color_by_name(name)
    "##{"%06x" % (name.unpack('H*').first.hex % 0xffffff)}"
  end

  def render_issue_card_hours(query, issue)
    hours = []
    hours << "%.2f" % issue.total_spent_hours.to_f if issue.total_spent_hours > 0 && query.has_column_name?(:spent_hours)
    hours << "%.2f" % issue.estimated_hours.to_f if issue.estimated_hours && query.has_column_name?(:estimated_hours)
    content_tag(:span, "(#{hours.join('/')}h)", :class => 'hours') unless hours.blank?
  end

end
