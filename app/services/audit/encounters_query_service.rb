module Audit
  class EncountersQueryService
    Result = Struct.new(:success, :records, :meta, :errors)

    DEFAULT_PER_PAGE = 50
    MAX_PER_PAGE = 1000

    def initialize(params: {})
      @params = params || {}
      @errors = []
    end

    def call
      pagination = PaginationService.new(@params).call
      if pagination.errors.any?
        return Result.new(false, [], {}, pagination.errors)
      end
      page = pagination.page
      per_page = pagination.per_page

      start_dt = parse_date_param(@params[:startDate]) if present?('startDate')
      end_dt   = parse_date_param(@params[:endDate], is_end: true) if present?('endDate')

      if present?('startDate') && !start_dt
        @errors << "startDate must be a valid date (YYYY-MM-DD) or ISO8601 timestamp"
      end
      if present?('endDate') && !end_dt
        @errors << "endDate must be a valid date (YYYY-MM-DD) or ISO8601 timestamp"
      end
      return Result.new(false, [], {}, @errors) if @errors.any?

      query = AuditAccess.all
      query = query.where('accessed_at >= ?', start_dt) if start_dt
      query = query.where('accessed_at <= ?', end_dt)   if end_dt
      query = query.for_user(@params[:userId]) if present?('userId')

      if present?('encounterId')
        enc = Encounter.find_by(encounter_id: @params[:encounterId])
        return Result.new(true, [], pagination_meta(1, per_page, 0), []) unless enc
        query = query.where(encounter_id: enc.id)
      end

      total = query.count
      offset = (page - 1) * per_page
      records = query.order(accessed_at: :desc).offset(offset).limit(per_page).map do |r|
        {
          id: r.id,
          encounter_db_id: r.encounter_id,
          accessed_by_user_id: r.accessed_by_user_id,
          accessed_at: r.accessed_at&.iso8601
        }
      end

      Result.new(true, records, pagination_meta(page, per_page, total), [])
    end

    private

    def present?(key)
      v = @params[key]
      !(v.nil? || (v.respond_to?(:empty?) && v.empty?))
    end

    def parse_date_param(value, is_end: false)
      return nil if value.nil? || value.to_s.strip.empty?
      begin
        if value.to_s =~ /\A\d{4}-\d{2}-\d{2}\z/
          d = Date.iso8601(value.to_s)
          is_end ? d.end_of_day : d.beginning_of_day
        else
          Time.iso8601(value.to_s)
        end
      rescue ArgumentError
        nil
      end
    end

    def pagination_meta(page, per_page, total)
      total_pages = per_page > 0 ? (total.to_f / per_page).ceil : 0
      { page: page, perPage: per_page, total: total, totalPages: total_pages }
    end
  end
end
