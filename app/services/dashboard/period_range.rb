module Dashboard
  class PeriodRange
    VALID_PERIODS = %w[
      week
      month
      semester
      year
    ].freeze

    def initialize(tenant:, params: {})
      @tenant = tenant
      @params = params.to_h.symbolize_keys
    end

    def current
      @current ||= begin
        return custom_range if custom_range?

        case period
        when "week"
          today.beginning_of_week.beginning_of_day..today.end_of_week.end_of_day
        when "month"
          today.beginning_of_month.beginning_of_day..today.end_of_month.end_of_day
        when "semester"
          semester_range_for(today)
        when "year"
          today.beginning_of_year.beginning_of_day..today.end_of_year.end_of_day
        else
          nil
        end
      end
    end

    def previous
      return nil unless current

      @previous ||= begin
        return previous_custom_range if custom_range?

        case period
        when "week"
          previous_week
        when "month"
          previous_month
        when "semester"
          previous_semester
        when "year"
          previous_year
        end
      end
    end

    private

    attr_reader :tenant, :params

    def period
      value = params[:period].to_s.presence

      return nil unless value

      unless VALID_PERIODS.include?(value)
        raise Dashboard::Error, I18n.t!("dashboard.errors.invalid_period")
      end

      value
    end

    def custom_range?
      params[:date_from].present? || params[:date_to].present?
    end

    def custom_range
      from = if params[:date_from].present?
               parse_date(params[:date_from]).beginning_of_day
      else
               first_event_date
      end

      to = if params[:date_to].present?
             parse_date(params[:date_to]).end_of_day
      else
             Time.current
      end

      if from > to
        raise Dashboard::Error, I18n.t!("dashboard.errors.invalid_date_range")
      end

      from..to
    end

    def previous_custom_range
      duration = current.end - current.begin

      previous_end = current.begin - 1.second
      previous_begin = previous_end - duration

      previous_begin..previous_end
    end

    def previous_week
      date = today - 1.week

      date.beginning_of_week.beginning_of_day..date.end_of_week.end_of_day
    end

    def previous_month
      date = today - 1.month

      date.beginning_of_month.beginning_of_day..date.end_of_month.end_of_day
    end

    def previous_semester
      previous_date = semester_range_for(today).begin.to_date - 1.day

      semester_range_for(previous_date)
    end

    def previous_year
      date = today - 1.year

      date.beginning_of_year.beginning_of_day..date.end_of_year.end_of_day
    end

    def semester_range_for(date)
      start_month = date.month <= 6 ? 1 : 7
      start_date = Date.new(date.year, start_month, 1)
      end_date = start_date.next_month(6).prev_day

      start_date.beginning_of_day..end_date.end_of_day
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      raise Dashboard::Error, I18n.t!("dashboard.errors.invalid_date", value: value)
    end

    def first_event_date
      Event.where(tenant: tenant).minimum(:occurred_at) || Time.zone.at(0)
    end

    def today
      Time.zone.today
    end
  end
end
