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

class FinanceMailer < Mailer
  helper :deals

  def account_edit(operation)
    @account = operation.account.reload
    redmine_headers 'Project' => @account.project.identifier,
                    'Account-Id' => @account.id
    redmine_headers 'Account-Assignee' => @account.assigned_to.login if @account.assigned_to
    message_id operation
    references @account
    @author = User.current
    recipients = @account.recipients
    # Watchers in cc
    cc = @account.watcher_recipients - recipients
    s = "[#{@account.project.name} - #{@account.name}] - #{@account.amount_to_s}"
    @operation = operation
    @account_amount_was = @account.account_amount_was
    @operation_url = url_for(:controller => 'operations', :action => 'show', :id => @operation)
    mail :to => recipients,
      :cc => cc,
      :subject => s
  end

  def operation_comment_added(comment)
    operation = comment.commented
    redmine_headers 'Project' => operation.project.identifier
    @author = comment.author
    message_id comment
    @operation = operation
    @comment = comment
    mail :to => operation.recipients,
     :cc => operation.watcher_recipients,
     :subject => "Re: [#{operation.project.name}] #{l(:label_operation)}: #{operation.to_s}"
  end
end
