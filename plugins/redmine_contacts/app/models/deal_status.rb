# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2014 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

class DealStatus < ActiveRecord::Base
  unloadable

  OPEN_STATUS = 0
  WON_STATUS = 1
  LOST_STATUS = 2

  before_destroy :check_integrity

  has_and_belongs_to_many :projects
  has_many :deals, :foreign_key => 'status_id', :dependent => :nullify
  has_many :deal_processes_from, :class_name => 'DealProcess',:foreign_key => 'old_value', :dependent => :delete_all
  has_many :deal_processes_to, :class_name => 'DealProcess', :foreign_key => 'value', :dependent => :delete_all
end
