module Dashboard
  module Reports
    class ReproductiveData
      INDICATOR_LABELS = {
        "insemination_success" => {
          title: "Sucesso de Inseminações",
          success: "Confirmadas",
          failure: "Negadas",
          total: "Exames"
        },
        "heat_coverage" => {
          title: "Cios com Cobertura",
          success: "Com Cobertura",
          failure: "Sem Cobertura",
          total: "Cios"
        },
        "pregnancy_success" => {
          title: "Sucesso de Prenhez",
          success: "Partos",
          failure: "Interrupções",
          total: "Encerradas"
        }
      }.freeze

      METHOD_LABELS = {
        "natural_mating" => "Monta natural",
        "artificial_insemination" => "Inseminação artificial"
      }.freeze

      def initialize(tenant:, user:, params: {})
        @tenant = tenant
        @user = user
        @params = params.to_h.symbolize_keys
      end

      def call
        {
          meta: meta,
          indicators: indicators,
          inseminations_by_method: inseminations_by_method,
          inseminations_by_bull: inseminations_by_bull,
          inseminations_by_company: inseminations_by_company,
          funnel: funnel,
          rate_evolution: rate_evolution
        }
      end

      private

      attr_reader :tenant, :user, :params

      def meta
        {
          period: period_label,
          generated_at: generated_at,
          responsible: user_name
        }
      end

      def indicators
        reproductive_indicators.map do |indicator|
          labels = INDICATOR_LABELS.fetch(indicator[:indicator])

          {
            title: labels[:title],
            success_label: "#{indicator[:successes]} #{labels[:success]}",
            failure_label: "#{indicator[:failures]} #{labels[:failure]}",
            total_label: "#{indicator[:total]} #{labels[:total]}",
            rate: indicator[:rate],
            variation: indicator[:variation] || 0.0
          }
        end
      end

      def inseminations_by_method
        insemination_distribution[:method].map do |item|
          {
            name: METHOD_LABELS.fetch(item[:method], item[:method]),
            coverings: item[:total],
            proportion: item[:rate]
          }
        end
      end

      def inseminations_by_bull
        insemination_distribution[:bull].map do |item|
          {
            name: item[:bull_name].presence || "Touro não identificado",
            coverings: item[:total],
            proportion: item[:rate]
          }
        end
      end

      def inseminations_by_company
        insemination_distribution[:company].map do |item|
          {
            name: item[:company].presence || "Empresa não identificada",
            coverings: item[:total],
            proportion: item[:rate]
          }
        end
      end

      def funnel
        [
          {
            step: "Cios",
            value: event_counts["heat_detection"],
            bar_class: "bar-heats"
          },
          {
            step: "Coberturas",
            value: event_counts["insemination"],
            bar_class: "bar-coverages"
          },
          {
            step: "Diagnósticos",
            value: event_counts["pregnancy_check"],
            bar_class: "bar-diagnoses"
          },
          {
            step: "Confirmações",
            value: event_counts["pregnancy_check_positive"],
            bar_class: "bar-confirmations"
          },
          {
            step: "Partos",
            value: event_counts["calving"],
            bar_class: "bar-calvings"
          },
          {
            step: "Interrupções",
            value: event_counts["pregnancy_interruption"],
            bar_class: "bar-interruptions"
          }
        ]
      end

      def rate_evolution
        monthly_rate_evolution.map do |month|
          {
            period: format_month(month[:month]),
            insemination: month[:insemination_success],
            coverage: month[:heat_coverage],
            pregnancy: month[:pregnancy_success]
          }
        end
      end

      def reproductive_indicators
        @reproductive_indicators ||= Dashboard::Events::ReproductiveIndicators.new(
          tenant: tenant,
          params: params
        ).call
      end

      def event_counts
        @event_counts ||= Dashboard::Events::CountSummary.new(
          tenant: tenant,
          range: period_range.current
        ).call
      end

      def insemination_distribution
        @insemination_distribution ||= Dashboard::Events::InseminationDistribution.new(
          tenant: tenant,
          range: period_range.current
        ).call
      end

      def monthly_rate_evolution
        @monthly_rate_evolution ||= Dashboard::Events::MonthlyRateEvolution.new(
          tenant: tenant,
        ).call
      end

      def period_range
        @period_range ||= Dashboard::PeriodRange.new(
          tenant: tenant,
          params: params
        )
      end

      def period_label
        range = period_range.current

        return "Todo o período" unless range

        "#{I18n.l(range.begin.to_date, format: :default)} - #{I18n.l(range.end.to_date, format: :default)}"
      end

      def format_month(value)
        date = Date.strptime(value, "%Y-%m")

        I18n.l(date, format: "%B %Y").capitalize
      end

      def generated_at
        Time.current.strftime("%d/%m/%Y, %H:%M")
      end

      def user_name
        return user.name if user.respond_to?(:name) && user.name.present?
        return user.email if user.respond_to?(:email) && user.email.present?

        "Sistema ARIA"
      end
    end
  end
end
