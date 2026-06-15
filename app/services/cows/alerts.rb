module Cows
  class Alerts
    def initialize(tenant:)
      @tenant = tenant
    end

    def call
      alerts.sort_by do |alert|
        priority[alert[:level]] || 99
      end
    end

    private

    attr_reader :tenant

    def alerts
      items = []

      tenant.cows.where(active: true).find_each do |cow|
        cow_alerts(cow).each do |alert|
          items << {
            cow_id: cow.id,
            cow_name: cow.name,
            ear_tag: cow.ear_tag,
            level: alert[:level],
            code: alert[:code],
            message: alert[:message]
          }
        end
      end

      items
    end

    def cow_alerts(cow)
      Cows::Insights::ReproductiveStatus
        .new(cow: cow)
        .call[:alerts]
    end

    def priority
      {
        "danger" => 0,
        "warning" => 1
      }
    end
  end
end
