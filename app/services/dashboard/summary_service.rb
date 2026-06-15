module Dashboard
  class SummaryService
    def initialize(tenant:)
      @tenant = tenant
    end

    def call
      active_counts = @tenant.cows.group(:active).count

      active_cows = active_counts[true] || 0
      inactive_cows = active_counts[false] || 0

      reproductive_counts = @tenant
        .cows
        .where(active: true)
        .group(:reproductive_status)
        .count

      counts = {
        total: active_cows + inactive_cows,
        active: active_cows,
        inactive: inactive_cows
      }

      Cow.reproductive_statuses.keys.each do |status|
        counts[status.to_sym] = reproductive_counts[status] || 0
      end

      alerts = []

      @tenant.cows.where(active: true).find_each do |cow|
        cow_alerts = Cows::Insights::ReproductiveStatus
          .new(cow: cow)
          .alerts

        cow_alerts.each do |alert|
          alerts << {
            cow_id: cow.id,
            cow_name: cow.name,
            ear_tag: cow.ear_tag,
            level: alert[:level],
            code: alert[:code],
            message: alert[:message]
          }
        end

        priority = {
          "danger" => 0,
          "warning" => 1
        }

        alerts.sort_by! do |alert|
          priority[alert[:level]] || 99
        end
      end

      {
        cows: counts,
        alerts: alerts
      }
    end
  end
end
