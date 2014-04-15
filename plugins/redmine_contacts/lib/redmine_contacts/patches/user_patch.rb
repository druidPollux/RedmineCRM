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

module RedmineContacts
  module Patches
    module UserPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          alias_method_chain :notify_about?, :contacts
        end
      end


      module InstanceMethods
        def notify_about_with_contacts?(object)
          is_notify = notify_about_without_contacts?(object)

          unless is_notify
            is_notify = case object
            when Contact
              case mail_notification
              when 'selected', 'only_my_events'
                object.author == self || is_or_belongs_to?(object.assigned_to)
              when 'only_assigned'
                is_or_belongs_to?(object.assigned_to)
              when 'only_owner'
                object.author == self
              end
            end
          end
          is_notify
        end

      end

    end
  end
end

unless User.included_modules.include?(RedmineContacts::Patches::UserPatch)
  User.send(:include, RedmineContacts::Patches::UserPatch)
end
