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

require 'svg/graph/agile_time_series'

module RedmineAgile
  class BurndownChart < AgileChart

    attr_accessor :burndown_data, :cumulative_burndown_data

    def initialize(data_scope, options={})
      @date_from = options[:date_from] && options[:date_from].to_date ||
                    [data_scope.minimum("#{Issue.table_name}.created_on"),
                    data_scope.minimum("#{Issue.table_name}.start_date")].compact.map(&:to_date).min
      @date_to = options[:date_to] && options[:date_to].to_date ||
                  [options[:due_date],
                  data_scope.maximum("#{Issue.table_name}.updated_on")].compact.map(&:to_date).max
      @due_date = options[:due_date].to_date if options[:due_date]

      @show_ideal_effort = options[:date_from] && options[:date_to]
      @show_weighed_ideal_effort = options[:show_weighed_ideal_effort]

      @style_sheet = "#{Redmine::Utils.relative_url_root}/plugin_assets/redmine_agile/stylesheets/burndown.css"
      @y_title = l(:label_agile_charts_number_of_issues)
      @graph_title = l(:label_agile_charts_issues_burndown)

      super data_scope, options
    end

    def render

      graph = SVG::Graph::AgileTimeSeries.new({
        :height => 400,
        :width => 800,
        :fields => @fields,
        :step_x_labels => @step_x_labels,
        :stagger_x_labels => true,
        :scale_x_divisions => 1,
        :show_x_guidelines => true,
        :scale_x_integers => true,
        :scale_y_integers => true,
        :show_data_values => false,
        :show_data_points => true,
        :show_y_title => true,
        :y_title => @y_title,
        :add_popups => true,
        :min_scale_value => 0,
        :area_fill => true,
        :no_css => true,
        :style_sheet => @style_sheet,
        :graph_title => @graph_title,
        :show_graph_title => true
      })

      if calc_burndown_data.any?
        graph.add_data({
            :data => data_points(@burndown_data),
            :title => l(:label_agile_actual_work_remaining)
        })

        graph.add_data({
            :data => [0, @cumulative_burndown_data.first, due_date_period, 0],
            :title => l(:label_agile_ideal_work_remaining)
        }) if @show_ideal_effort

        graph.add_data({
            :data => data_points(@cumulative_burndown_data),
            :title => l(:label_agile_total_work_remaining)
        }) if @show_ideal_effort && (@cumulative_burndown_data != @burndown_data)

        graph.add_data({
            :data => data_points(weighed_ideal_effort),
            :title => l(:label_agile_weighed_ideal_work_remaining)
        }) if @show_weighed_ideal_effort
      end

      graph.burn
    end

    protected

    def calc_burndown_data
      created_by_period = issues_count_by_period(scope_by_created_date)
      closed_by_period = issues_count_by_period(scope_by_closed_date)

      total_issues = @data_scope.count
      total_issues_before = @data_scope.where("#{Issue.table_name}.created_on < ?", @date_from).count
      total_closed_before = @data_scope.open(false).where("#{Issue.table_name}.closed_on < ?", @date_from).count

      cumulative_created_by_period = created_by_period.map{|x| total_issues_before += x}
      cumulative_closed_by_period = closed_by_period.map{|x| total_closed_before += x}

      burndown_by_period = [0] * @period_count
      cumulative_created_by_period.each_with_index{|e, i| burndown_by_period[i] = e - cumulative_closed_by_period[i]}

      @cumulative_burndown_data = cumulative_closed_by_period.map{|c| total_issues - c}
      @burndown_data = burndown_by_period
    end

    def due_date_period
      @due_date_period ||= @due_date ? @period_count - (@date_to - @due_date).to_i / @scale_division - 1: @period_count - 1
    end

    def weighed_ideal_effort
      data = [0] * @burndown_data.count
      data[0] = @burndown_data[0]
      for i in 1..[due_date_period, @burndown_data.count].min - 1
        remaining_velocity = @burndown_data[i].to_f / (due_date_period - i).to_f
        data[i] = @burndown_data[i] - remaining_velocity
      end
      data
    end

  end
end
