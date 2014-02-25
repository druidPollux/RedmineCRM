# encoding: utf-8
#
# This file is a part of Redmine Invoices (redmine_contacts_invoices) plugin,
# invoicing plugin for Redmine
#
# Copyright (C) 2011-2013 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_contacts_invoices is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts_invoices is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts_invoices.  If not, see <http://www.gnu.org/licenses/>.

module InvoicesHelper
  include RedmineInvoices::InvoiceReports
  include Redmine::I18n

  def invoices_contacts_for_select(project, options={})
    scope = Contact.scoped({})
    scope = scope.joins(:projects).uniq.where(Contact.visible_condition(User.current))
    scope = scope.joins(:invoices)
    scope = scope.where("(#{Project.table_name}.id <> -1)")
    scope = scope.where(:invoices => {:project_id => project}) if project
    scope.limit(options[:limit] || 500).map{|c| [c.name, c.id.to_s]}
  end

  def invoice_status_tag(invoice)
    status_tag = content_tag(:span, invoice_status_name(invoice.status_id))
    content_tag(:span, status_tag, :class => "tag-label-color invoice-status #{invoice_status_name(invoice.status_id, true).to_s}")
  end

  def invoice_tag(invoice)
    invoice_title = "##{invoice.number} - #{format_date(invoice.invoice_date)}"
    s = ''
    if invoice.visible?
      s << link_to(invoice_title, invoice_path(invoice), :class => 'icon icon-invoice', :download => true)
      s << " " + link_to(image_tag('page_white_acrobat_context.png', :plugin => "redmine_contacts_invoices"), invoice_path(invoice, :format => 'pdf'))
      s << " " + content_tag(:span, content_tag(:strong, invoice.amount_to_s), :class => "amount")
    else
      s << content_tag(:span, invoice_title, :class => 'icon icon-invoice')
    end
    s << " - #{invoice.subject}" unless invoice.subject.blank?
    s << " " + content_tag(:span, '(' + invoice.contact.name + ')', :class => 'contact') if invoice.contact
    s
  end

  def contact_custom_fields
    if "ContactCustomField".is_a_defined_class?
      ContactCustomField.find(:all, :conditions => ["#{ContactCustomField.table_name}.field_format = 'string' OR #{ContactCustomField.table_name}.field_format = 'text'"]).map{|f| [f.name, f.id.to_s]}
    else
      []
    end
  end

  def invoices_list_style
    list_styles = ['list_excerpt', 'list']
    if params[:invoices_list_style].blank?
      list_style = list_styles.include?(session[:invoices_list_style]) ? session[:invoices_list_style] : InvoicesSettings.default_list_style
    else
      list_style = list_styles.include?(params[:invoices_list_style]) ? params[:invoices_list_style] : InvoicesSettings.default_list_style
    end
    session[:invoices_list_style] = list_style
  end

  def expenses_list_style
    list_styles = ['list_excerpt', 'list']
    if params[:expenses_list_style].blank?
      list_style = list_styles.include?(session[:expenses_list_style]) ? session[:expenses_list_style] : InvoicesSettings.default_list_style
    else
      list_style = list_styles.include?(params[:expenses_list_style]) ? params[:expenses_list_style] : InvoicesSettings.default_list_style
    end
    session[:expenses_list_style] = list_style
  end


  def invoice_lang_options_for_select(has_blank=true)
    (has_blank ? [["(auto)", ""]] : []) +
      RedmineInvoices.available_locales.collect{|lang| [ ll(lang.to_s, :general_lang_name), lang.to_s]}.sort{|x,y| x.last <=> y.last }
  end

  def invoice_avaliable_locales_hash
    Hash[*invoice_lang_options_for_select.collect{|k, v| [v.blank? ? "default" : v, k]}.flatten]
  end

  def collection_invoice_templates_for_select
    [[l(:label_invoice_template_classic), RedmineInvoices::TEMPLATE_CLASSIC ],
     [l(:label_invoice_template_modern), RedmineInvoices::TEMPLATE_MODERN ],
     [l(:label_invoice_template_left), RedmineInvoices::TEMPLATE_MODERN_LEFT ],
     [l(:label_invoice_template_blank_header), RedmineInvoices::TEMPLATE_BLANK_HEADER ],
     [l(:label_invoice_template_custom), RedmineInvoices::TEMPLATE_CUSTOM ]]
  end

  def collection_invoice_status_names
    [[:draft, Invoice::DRAFT_INVOICE],
     [:estimate, Invoice::ESTIMATE_INVOICE],
     [:sent, Invoice::SENT_INVOICE],
     [:paid, Invoice::PAID_INVOICE],
     [:canceled, Invoice::CANCELED_INVOICE]]
  end

  def invoice_number_format(number)
    ActionController::Base.helpers.number_with_delimiter(number,
        :separator => ContactsSetting.decimal_separator,
        :delimiter => ContactsSetting.thousands_delimiter)
  end

  def collection_invoice_statuses
    Invoice::STATUSES.map{|k, v| [l(v), k]}
  end

  def collection_invoice_statuses_for_select
    collection_invoice_statuses.select{|s| s[1] != Invoice::PAID_INVOICE}
  end

  def collection_invoice_statuses_for_filter(status_id)
    collection = collection_invoice_statuses.map{|s| [s[0], s[1].to_s]}
    collection.push [l(:label_invoice_overdue), "d"]
    collection.insert 0, [l(:label_open_issues), "o"]
    collection.insert 0, [l(:label_all), ""]

    options_for_select(collection, status_id)

  end

  def label_with_currency(label, currency)
    l(label).mb_chars.capitalize.to_s + (currency.blank? ? '' : " (#{currency})")
  end

  def invoice_status_name(status, code=false)
    return (code ? "draft" : l(:label_invoice_status_draft)) unless collection_invoice_statuses.map{|v| v[1]}.include?(status)

    status_data = collection_invoice_statuses.select{|s| s[1] == status }.first[0]
    status_name = collection_invoice_status_names.select{|s| s[1] == status}.first[0]
    return (code ? status_name : status_data)
  end

  def collection_for_discount_types_select
    [:percent, :amount].each_with_index.collect{|l, index| [l("label_invoice_#{l.to_s}".to_sym), index]}
  end

  def link_to_remove_invoice_fields(name, f, options={})
    f.hidden_field(:_destroy) + link_to_function(name, "remove_invoice_fields(this)", options)
  end

  def discount_label(invoice)
    "#{l(:field_invoice_discount)}#{' (' + "%2.f" % invoice.discount_rate.to_f + '%)' if invoice.discount_type == 0 }"
  end

  def link_to_add_invoice_fields(name, f, association, options={})
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    link_to_function(name, "add_invoice_fields(this, '#{association}', '#{escape_javascript(fields)}')", options={})
  end

  def retrieve_invoices_query
    # debugger
    # params.merge!(session[:deals_query])
    # session[:deals_query] = {:project_id => @project.id, :status_id => params[:status_id], :category_id => params[:category_id], :assigned_to_id => params[:assigned_to_id]}

    if  params[:status_id] || !params[:contact_id].blank? || !params[:assigned_to_id].blank? || !params[:period].blank?
      session[:invoices_query] = {:project_id => (@project ? @project.id : nil),
                                  :status_id => params[:status_id],
                                  :contact_id => params[:contact_id],
                                  :period => params[:period],
                                  :assigned_to_id => params[:assigned_to_id]}
    else
      if api_request? || params[:set_filter] || session[:invoices_query].nil? || session[:invoices_query][:project_id] != (@project ? @project.id : nil)
        session[:invoices_query] = {}
      else
        params.merge!(session[:invoices_query])
      end
    end
  end

  def is_no_filters
    (params[:status_id] == 'o' && params[:assigned_to_id].blank? && (params[:period].blank? || params[:period] == 'all') && (params[:paid_period].blank? || params[:paid_period] == 'all') && (params[:due_date].blank? || params[:due_date] == 'all') && params[:contact_id].blank?)
  end

  def is_date?(str)
    temp = str.gsub(/[-.\/]/, '')
    ['%m%d%Y','%m%d%y','%M%D%Y','%M%D%y'].each do |f|
      begin
        return true if Date.strptime(temp, f)
      rescue
           #do nothing
      end
    end
  end

  def due_days(invoice)
    return "" if invoice.due_date.blank? || invoice.status_id != Invoice::SENT_INVOICE
    if invoice.due_date.to_date >= Date.today
      content_tag(:span, " (#{l(:label_invoice_days_due, :days => (invoice.due_date.to_date - Date.today).to_s)})", :class => "due-days")
    else
      content_tag(:span, " (#{l(:label_invoice_days_late, :days => (Date.today - invoice.due_date.to_date).to_s)})", :class => "overdue-days")
    end
  end

  def get_contact_extra_field(contact)
    field_id = InvoicesSettings[:invoices_contact_extra_field, @project]
    return "" if field_id.blank?
    return "" unless contact.respond_to?(:custom_values)
    contact.custom_values.find_by_custom_field_id(field_id)
  end

  def invoice_to_pdf(invoice)
    RedmineInvoices::InvoiceReports.invoice_to_pdf_prawn(invoice, RedmineInvoices::TEMPLATE_CLASSIC)
  end

end
