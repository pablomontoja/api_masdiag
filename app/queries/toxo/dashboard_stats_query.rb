module Toxo
  class DashboardStatsQuery
    ALLOWED_WINDOWS = [30, 90, 180, 360].freeze
    DEFAULT_WINDOW = 30

    def initialize(user:, window:)
      @user = user
      @window = ALLOWED_WINDOWS.include?(window.to_i) ? window.to_i : DEFAULT_WINDOW
    end

    def call
      {
        window: window,
        orders_count: orders_scope.count,
        authorized_measurements_count: authorized_measurements_scope.count,
        unused_reserved_codes_count: unused_reserved_codes_scope.count,
        orders_series: group_by_day(orders_scope, :RegistrationDate),
        authorized_series: group_by_day(authorized_measurements_scope, :AuthorizedAt),
        analysis_breakdown: analysis_breakdown
      }
    end

    private

    attr_reader :user, :window

    def since
      window.days.ago.beginning_of_day
    end

    def orders_scope
      Toxo::SamplePolicy::Scope.new(user, Toxo::Sample.all).resolve
                                .where(RegistrationDate: since..)
    end

    def measurements_scope
      Toxo::MeasurementPolicy::Scope.new(user, Measurement).resolve
    end

    def authorized_measurements_scope
      measurements_scope.where.not(AuthorizedAt: nil).where(AuthorizedAt: since..)
    end

    def unused_reserved_codes_scope
      ReservedSampleCode.where(InstitutionId: user.institution_id)
                         .where("LENGTH(ReservedSampleCodes.Code) = 7")
                         .joins("LEFT JOIN Samples ON Samples.reserved_sample_code_id = ReservedSampleCodes.Id")
                         .where(Samples: { Id: nil })
    end

    def group_by_day(scope, column)
      scope.group_by_day(column, last: window).count.map { |date, count| [ date.to_s, count ] }
    end

    def analysis_breakdown
      authorized_measurements_scope.group(:ProjectId).count.transform_keys(&:to_s)
    end
  end
end
