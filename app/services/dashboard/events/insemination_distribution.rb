module Dashboard
  module Events
    class InseminationDistribution
      DEFAULT_COMPANY_NAME = "unknown"

      def initialize(tenant:, range: nil)
        @tenant = tenant
        @range = range
      end

      def call
        {
          total: total_count,
          method: by_method,
          bull: by_bull,
          company: by_company
        }
      end

      private

      attr_reader :tenant, :range

      def by_method
        ::Events::Insemination::VALID_METHODS.map do |method|
          count = method_counts[method] || 0

          {
            method: method,
            total: count,
            rate: percentage(count, total_count)
          }
        end
      end

      def by_bull
        bull_counts.map do |bull_id, count|
          bull = bulls_by_id[bull_id]

          {
            bull_id: bull_id,
            bull_name: bull&.name,
            total: count,
            rate: percentage(count, total_count)
          }
        end
      end

      def by_company
        artificial_company_counts.map do |company, count|
          {
            company: company,
            total: count,
            rate: percentage(count, artificial_insemination_count)
          }
        end
      end

      def method_counts
        @method_counts ||= inseminations
          .group("data ->> 'method'")
          .count
      end

      def bull_counts
        @bull_counts ||= inseminations
          .group("data ->> 'bull_id'")
          .count
      end

      def artificial_bull_counts
        @artificial_bull_counts ||= artificial_inseminations
          .group("data ->> 'bull_id'")
          .count
      end

      def artificial_company_counts
        @artificial_company_counts ||= artificial_bull_counts.each_with_object(Hash.new(0)) do |(bull_id, count), counts|
          bull = bulls_by_id[bull_id]

          next unless bull&.company?

          counts[company_name_for(bull)] += count
        end
      end

      def bulls_by_id
        @bulls_by_id ||= tenant
          .bulls
          .where(id: bull_ids)
          .index_by { |bull| bull.id.to_s }
      end

      def bull_ids
        (bull_counts.keys + artificial_bull_counts.keys).uniq
      end

      def company_name_for(bull)
        return bull.company_name if bull.respond_to?(:company_name) && bull.company_name.present?
        return bull.company.name if bull.respond_to?(:company) && bull.company.respond_to?(:name) && bull.company.name.present?

        DEFAULT_COMPANY_NAME
      end

      def total_count
        @total_count ||= inseminations.count
      end

      def artificial_insemination_count
        @artificial_insemination_count ||= artificial_inseminations.count
      end

      def percentage(value, total)
        return 0.0 if total.zero?

        ((value.to_f / total) * 100).round(2)
      end

      def artificial_inseminations
        @artificial_inseminations ||= inseminations.where(
          "data ->> 'method' = ?",
          "artificial_insemination"
        )
      end

      def inseminations
        @inseminations ||= begin
          scope = Event.where(
            tenant: tenant,
            event_type: "insemination"
          )

          range ? scope.where(occurred_at: range) : scope
        end
      end
    end
  end
end
