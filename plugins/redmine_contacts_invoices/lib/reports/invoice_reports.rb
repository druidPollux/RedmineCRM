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

module RedmineInvoices
  module InvoiceReports
    class << self
      include Redmine::I18n
      include InvoicesHelper
      include ContactsMoneyHelper

      def invoice_to_pdf_prawn(invoice, type)
        saved_language = User.current.language
        set_language_if_valid(invoice.language || User.current.language)
        s = invoice_to_pdf_classic(invoice)
        set_language_if_valid(saved_language)
        s
      end

      def invoice_to_pdf_classic(invoice)

        # InvoiceReport.new.to_pdf(invoice)
        pdf = Prawn::Document.new(:info => {
            :Title => "#{l(:label_invoice)} - #{invoice.number}",
            :Author => User.current.name,
            :Producer => InvoicesSettings[:invoices_company_name, invoice.project].to_s,
            :Subject => "Invoice",
            :Keywords => "invoice",
            :Creator => InvoicesSettings[:invoices_company_name, invoice.project].to_s,
            :CreationDate => Time.now,
            :TotalAmount => price_to_currency(invoice.amount, invoice.currency, :converted => false, :symbol => false),
            :TaxAmount => price_to_currency(invoice.tax_amount, invoice.currency, :converted => false, :symbol => false),
            :Discount => price_to_currency(invoice.discount_amount, invoice.currency, :converted => false, :symbol => false)
            },
            :margin => [50, 50, 60, 50])
        contact = invoice.contact || Contact.new(:first_name => '[New client]', :address_attributes => {:street1 => '[New client address]'}, :phone => '[phone]')

        fonts_path = "#{Rails.root}/plugins/redmine_contacts_invoices/lib/fonts/"
        pdf.font_families.update(
               "FreeSans" => { :bold => fonts_path + "FreeSansBold.ttf",
                               :italic => fonts_path + "FreeSansOblique.ttf",
                               :bold_italic => fonts_path + "FreeSansBoldOblique.ttf",
                               :normal => fonts_path + "FreeSans.ttf" })

        # pdf.stroke_bounds
        pdf.font("FreeSans", :size => 9)
        # pdf.font("Times-Roman")
        pdf.default_leading -5
        status_stamp(pdf, invoice)
        # pdf.move_down(10)
        pdf.text InvoicesSettings[:invoices_company_name, invoice.project].to_s, :style => :bold, :size => 18
        # pdf.move_down(5)
        pdf.text InvoicesSettings[:invoices_company_representative, invoice.project].to_s if InvoicesSettings[:invoices_company_representative, invoice.project]
        pdf.text_box "#{InvoicesSettings[:invoices_company_info, invoice.project].to_s}",
          :at => [0, pdf.cursor], :width => 140


        invoice_data = [
          [l(:field_invoice_number) + ":",
          invoice.number],
          [l(:field_invoice_date) + ":",
          format_date(invoice.invoice_date)]]

        invoice_data << [l(:field_invoice_due_date) + ":", format_date(invoice.due_date)] if invoice.due_date
        invoice_data << [l(:field_invoice_order_number) + ":", invoice.order_number] unless invoice.order_number.blank?
        invoice_data << [l(:field_invoice_subject) + ":", invoice.subject] unless invoice.subject.blank?

        invoice.custom_values.each do |custom_value|
          if !custom_value.value.blank? && custom_value.custom_field.is_for_all?
            invoice_data << [custom_value.custom_field.name + ":",
                             RedmineContacts::CSVUtils.csv_custom_value(custom_value)]
          end
        end

        invoice_data << [l(:label_invoice_bill_to) + ":",
                         "#{contact.name}
                         #{contact.address ? contact.post_address : ''}
                         #{get_contact_extra_field(contact)}"]

        # , :borders => []

        pdf.bounding_box [pdf.bounds.width - 250, pdf.bounds.height + 10], :width => 250 do
          # pdf.stroke_bounds
          pdf.fill_color "cccccc"
          pdf.text l(:label_invoice), :align => :right, :style => :bold, :size => 30
          # pdf.text_box l(:label_invoice), :at => [pdf.bounds.width - 100, pdf.bounds.height + 10],
          #              :style => :bold, :size => 30, :color => 'cccccc', :align => :right, :valign => :top,
          #              :width => 100, :height => 50,
          #              :overflow => :shrink_to_fit

          pdf.fill_color "000000"

        # pdf.grid([1,0], [1,1]).bounding_box do
          pdf.table invoice_data, :cell_style => {:padding => [-3, 5, 3, 5], :borders => []} do |t|
            t.columns(0).font_style = :bold
            # t.columns(0).text_color = "990000"
            t.columns(0).width = 100
            t.columns(0).align = :right
            t.columns(1).width = 150
          end
        end
        pdf.move_down(30)
        classic_table(pdf, invoice)
        if InvoicesSettings[:invoices_bill_info, invoice.project]
          pdf.text InvoicesSettings[:invoices_bill_info, invoice.project]
        end
        pdf.move_down(10)
        pdf.text invoice.description
        pdf.number_pages "<page>/<total>", {:at => [pdf.bounds.right - 150, -10], :width => 150,
                  :align => :right} if pdf.page_number > 1
        pdf.repeat(lambda{ |pg| pg > 1}) do
           pdf.draw_text "##{invoice.number}", :at => [0, -20]
        end

        pdf.render
      end

      def status_stamp(pdf, invoice)
        case invoice.status_id
        when Invoice::DRAFT_INVOICE
          stamp_text = "DRAFT"
          stamp_color = "993333"
        when Invoice::PAID_INVOICE
          stamp_text = "PAID"
          stamp_color = "1e9237"
        else
          stamp_text = ""
          stamp_color = "1e9237"
        end

        stamp_text_width = pdf.width_of(stamp_text, :font => "Times-Roman", :style => :bold, :size => 120)
        pdf.create_stamp("draft") do
          pdf.rotate(30, :origin => [0, 50]) do
            pdf.fill_color stamp_color
            pdf.font("Times-Roman", :style => :bold, :size => 120) do
              pdf.transparent(0.08) {pdf.draw_text stamp_text, :at => [0, 0]}
            end
            pdf.fill_color "000000"
          end
        end

        pdf.stamp_at "draft", [(pdf.bounds.width / 2) - stamp_text_width / 2, (pdf.bounds.height / 2) ] unless stamp_text.blank?
      end

      def classic_table(pdf, invoice)
        lines = invoice.lines.map do |line|
          [
            line.position,
            line.description,
            "x#{invoice_number_format(line.quantity)}",
            line.units,
            price_to_currency(line.price, invoice.currency, :converted => false, :symbol => false),
            price_to_currency(line.total, invoice.currency, :converted => false, :symbol => false)
          ]
        end
        lines.insert(0,[l(:field_invoice_line_position),
                       l(:field_invoice_line_description),
                       l(:field_invoice_line_quantity),
                       l(:field_invoice_line_units),
                       label_with_currency(:field_invoice_line_price, invoice.currency),
                       label_with_currency(:label_invoice_total, invoice.currency) ])
        lines << ['']
        lines << ['', '', '', '', l(:label_invoice_sub_amount) + ":", price_to_currency(invoice.subtotal, invoice.currency, :converted => false, :symbol => false)]  if invoice.discount_amount > 0 || (invoice.tax_amount> 0 && !invoice.total_with_tax?)

        invoice.tax_groups.each do |tax_group|
          lines << ['', '', '', '', "#{l(:label_invoice_tax)} (#{invoice_number_format(tax_group[0])}%):", price_to_currency(tax_group[1], invoice.currency, :converted => false, :symbol => false)]
        end if invoice.tax_amount> 0

        lines << ['', '', '', '', discount_label(invoice) + ":", "-" + price_to_currency(invoice.discount_amount, invoice.currency, :converted => false, :symbol => false)] if invoice.discount_amount > 0

        lines << ['', '', '', '', label_with_currency(:label_invoice_total, invoice.currency) + ":", price_to_currency(invoice.amount, invoice.currency, :converted => false, :symbol => false)]

        pdf.table lines, :width => pdf.bounds.width, :cell_style => {:padding => [-3, 5, 3, 5]}, :header => true do |t|
          # t.cells.padding = 405
          t.columns(0).width = 20
          t.columns(2).align = :center
          t.columns(2).width = 40
          t.columns(3).align = :center
          t.columns(3).width = 50
          t.columns(4..5).align = :right
          t.columns(4..5).width = 90
          t.row(0).font_style = :bold
          t.row(0).align = :center
          # t.row(0).background_color = 'cccccc'

          max_width =  t.columns(2).inject(0) { |width, cell| [width, pdf.width_of(cell.content, :style => :bold) + 15].max }
          t.columns(2).width = max_width if max_width < 100

          max_width =  t.columns(3).inject(0) { |width, cell| [width, pdf.width_of(cell.content, :style => :bold) + 15].max }
          t.columns(3).width = max_width if max_width < 100

          max_width =  t.columns(4).inject(0) { |width, cell| [width, pdf.width_of(cell.content, :style => :bold) + 15].max }
          t.columns(4).width = max_width if max_width < 120

          max_width =  t.columns(5).inject(0) { |width, cell| [width, pdf.width_of(cell.content, :style => :bold) + 15].max }
          t.columns(5).width = max_width if max_width < 120


          t.row(invoice.lines.count + 2).padding = [5, 5, 3, 5]

          t.row(invoice.lines.count + 2..invoice.lines.count + 6).borders = []
          t.row(invoice.lines.count + 2..invoice.lines.count + 6).font_style = :bold
        end
      end
    end
  end
end
