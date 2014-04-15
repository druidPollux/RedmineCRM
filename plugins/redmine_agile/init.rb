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

AGILE_VERSION_NUMBER = '1.1.2'

Redmine::Plugin.register :redmine_agile do
  name 'Redmine Agile plugin'
  author 'RedmineCRM'
  description 'Scrum and Agile project management plugin for redmine'
  version AGILE_VERSION_NUMBER + '-light'
  url 'http://redminecrm.com'
  author_url 'mailto:support@redminecrm.com'

  requires_redmine :version_or_higher => '2.3'

  settings :default => {
    'issues_per_column' => "10",
    'default_columns' => %w(tracker assigned_to)
                       },
           :partial => 'settings/agile_board/agile_board'

  menu :project_menu, :agile, {:controller => 'agile_board', :action => 'index' },
                              :caption => :label_agile,
                              :after => :gantt,
                              :param => :project_id

  menu :admin_menu, :agile, {:controller => 'settings', :action => 'plugin', :id => "redmine_agile"}, :caption => :label_agile

  project_module :agile do
    permission :manage_public_agile_queries, {:agile_queries => [:new, :create, :edit, :update, :destroy]}, :require => :member
    permission :add_agile_queries, {:agile_queries => [:new, :create, :edit, :update, :destroy]}, :require => :loggedin
    permission :view_agile_queries, {:agile_board => [:index, :load_more], :agile_queries => :index}
    permission :view_agile_charts, {:agile_charts => [:show, :render_chart, :render_version_chart, :select_version_chart]}
  end
end

require 'redmine_agile'
