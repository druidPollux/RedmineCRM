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

module RedmineFinance
  module Patches
    module NotifiablePatch
      def self.included(base)
        base.extend(ClassMethods)
        base.class_eval do
            unloadable
            class << self
                alias_method_chain :all, :finance
            end
        end
      end


      module ClassMethods
        # include ContactsHelper

        def all_with_finance
          notifications = all_without_finance
          notifications << Redmine::Notifiable.new('finance_account_updated')
          notifications << Redmine::Notifiable.new('finance_operation_comment_added')
          notifications
        end

      end

    end
  end
end

unless Redmine::Notifiable.included_modules.include?(RedmineFinance::Patches::NotifiablePatch)
  Redmine::Notifiable.send(:include, RedmineFinance::Patches::NotifiablePatch)
end
