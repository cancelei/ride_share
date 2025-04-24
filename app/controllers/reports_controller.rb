class ReportsController < ApplicationController
  before_action :authenticate_user!

  PDF_OPTIONS = {
    format: "A4",
    wait_until: "networkidle0"
  }.freeze

  def new
    @form_url = report_path
    @report_title = "Tax Report"
    # Form for selecting date range (tax report)
  end

  def new_managerial
    @form_url = managerial_report_path
    @report_title = "Managerial Report"
    # Form for selecting date range (managerial report)
    render :new
  end

  def show
    prepare_report_data(Reports::TaxReport)
    respond_to do |format|
      format.html
      format.pdf { render_pdf("reports/show", "tax_report") }
    end
  end

  def managerial
    prepare_report_data(Reports::ManagerialReport)
    respond_to do |format|
      format.html
      format.pdf { render_pdf("reports/managerial", "managerial_report") }
    end
  end

  private

  def prepare_report_data(report_class)
    @start_date = params[:start_date].to_date
    @end_date = params[:end_date].to_date
    @user = current_user
    @report_data = report_class.new(@user, @start_date, @end_date).data
  end

  def render_pdf(template, filename_prefix)
    html = render_to_string(template: template, formats: [ :html ], layout: "application")
    # Fix: Grover.new expects HTML as first argument and options as keyword arguments, not a second positional argument
    options = PDF_OPTIONS.merge(display_url: request.original_url)
    grover = Grover.new(html, **options)

    begin
      pdf_data = grover.to_pdf
      send_data pdf_data,
                filename: "#{filename_prefix}_#{@start_date}_to_#{@end_date}.pdf",
                type: "application/pdf",
                disposition: "inline"
    rescue => e
      Rails.logger.error("PDF generation failed: #{e.message}")
      flash[:error] = "Could not generate PDF. Please try again."
      redirect_to request.referrer || root_path
    end
  end
end
