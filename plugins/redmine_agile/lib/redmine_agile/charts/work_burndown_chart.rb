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

module RedmineAgile
  class WorkBurndownChart < BurndownChart

    def initialize(data_scope, options={})
      super data_scope, options
      @style_sheet = "#{Redmine::Utils.relative_url_root}/plugin_assets/redmine_agile/stylesheets/work_burndown.css"
      @y_title = l(:label_agile_charts_number_of_hours)
      @graph_title = l(:label_agile_charts_work_burndown)
    end

    protected

    def calc_burndown_data
      all_issues = @data_scope.
        where("#{Issue.table_name}.rgt - #{Issue.table_name}.lft = 1").
        where("#{Issue.table_name}.estimated_hours IS NOT NULL").
        includes([:journals, :status, {:journals => {:details => :journal}}])
      cumulative_total_hours = @data_scope.where("#{Issue.table_name}.rgt - #{Issue.table_name}.lft = 1").sum("#{Issue.table_name}.estimated_hours").to_f
      data = chart_dates_by_period.select{|d| d <= Date.today}.map do |date|
        issues = all_issues.select {|issue| issue.created_on.to_date <= date }
        cumulative_total_hours_left = 0
        total_hours_left = 0
        issues.each do |issue|
          done_ratio_details = issue.journals.map(&:details).flatten.select {|detail| 'done_ratio' == detail.prop_key }
          details_today_or_earlier = done_ratio_details.select {|a| a.journal.created_on.to_date <= date }

          last_done_ratio_change = details_today_or_earlier.sort_by {|a| a.journal.created_on }.last

          ratio = if issue.closed? && issue.closed_on <= date
            100
          elsif last_done_ratio_change
            last_done_ratio_change.value
          elsif done_ratio_details.size > 0
            0
          else
            issue.done_ratio.to_i
          end

          cumulative_total_hours_left += (issue.estimated_hours.to_f * ratio.to_f / 100.0)
          total_hours_left += (issue.estimated_hours.to_f * (100 - ratio.to_f) / 100.0)

        end
        [total_hours_left, cumulative_total_hours - cumulative_total_hours_left]
      end

      @burndown_data, @cumulative_burndown_data = data.transpose
    end

  end
end
