module Dashboard
  module Reports
    class ReproductivePdf
      def initialize(tenant:, user:, params: {})
        @tenant = tenant
        @user = user
        @params = params.to_h.symbolize_keys
      end

      def call
        html_content = html

        File.write(
          Rails.root.join("tmp", "reproductive_report_debug.html"),
          html_content
        )

        raise "HTML do relatório está vazio" if html_content.blank?

        Grover.new(html_content, **grover_options).to_pdf
      end

      private

      attr_reader :tenant, :user, :params

      def html
        ActionController::Base.renderer.render(
          template: "dashboard/reproductive_report",
          layout: false,
          formats: [ :html ],
          assigns: {
            report: report
          }
        )
      end

      def report
        @report ||= Dashboard::Reports::ReproductiveData.new(
          tenant: tenant,
          user: user,
          params: params
        ).call
      end

      def grover_options
        options = {
          format: "A4",
          print_background: true,
          executable_path: ENV.fetch(
            "PUPPETEER_EXECUTABLE_PATH",
            "/usr/bin/chromium"
          ),
          margin: {
            top: "0mm",
            bottom: "0mm",
            left: "0mm",
            right: "0mm"
          }
        }

        if Rails.env.development?
          options[:launch_args] = [
            "--no-sandbox",
            "--disable-setuid-sandbox"
          ]
        end

        options
      end
    end
  end
end
