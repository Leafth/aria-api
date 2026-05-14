module Events
  class ExpireHeatsJob < ActiveJob::Base
    queue_as :default

    HEAT_VALIDITY_WINDOW = 24.hours

    def perform
      Cow
        .where(reproductive_status: :in_heat)
        .where("last_heat_at < ?", HEAT_VALIDITY_WINDOW.ago)
        .find_each do |cow|
          cow.update!(reproductive_status: :open)
        end
    end
  end
end
