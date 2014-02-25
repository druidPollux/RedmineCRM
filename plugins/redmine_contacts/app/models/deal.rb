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

class Deal < ActiveRecord::Base
  unloadable
  include ContactsMoneyHelper
  include Redmine::SafeAttributes

  belongs_to :project
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  belongs_to :assigned_to, :class_name => 'User', :foreign_key => 'assigned_to_id'
  belongs_to :category, :class_name => 'DealCategory', :foreign_key => 'category_id'
  belongs_to :contact
  belongs_to :status, :class_name => "DealStatus", :foreign_key => "status_id"
  has_many :deals, :class_name => "deal", :foreign_key => "reference_id"
  has_many :notes, :as => :source, :class_name => 'DealNote', :dependent => :delete_all, :order => "created_on DESC"
  has_many :deal_processes, :dependent => :delete_all
  has_and_belongs_to_many :related_contacts, :class_name => 'Contact', :order => "#{Contact.table_name}.last_name, #{Contact.table_name}.first_name", :uniq => true

  def info
   result = ""
  end

private

  def send_notification
    Mailer.crm_deal_add(self).deliver if Setting.notified_events.include?('crm_deal_added')
  end
end
