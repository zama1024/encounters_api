module Audit
  class EncountersController < ApplicationController
    include ApiAuthenticatable

    # GET /audit/encounters
    # Query params:
    #   startDate, endDate (ISO8601)
    #   userId
    #   encounterId
    #   page (1-based)
    #   perPage
    def index
      start_dt = parse_date_param(params[:startDate]) if params[:startDate].present?
      end_dt   = parse_date_param(params[:endDate], is_end: true) if params[:endDate].present?

      if params[:startDate].present? && !start_dt
        return render_bad_request("startDate must be a valid date (YYYY-MM-DD) or ISO8601 timestamp")
      end
      if params[:endDate].present? && !end_dt
        return render_bad_request("endDate must be a valid date (YYYY-MM-DD) or ISO8601 timestamp")
      end

      # Validate pagination params and return error if invalid
      page, per_page = validate_pagination_params
      return unless page # validate_pagination_params renders error and returns nil on failure

      query = AuditAccess.all
      query = query.where('accessed_at >= ?', start_dt) if start_dt
      query = query.where('accessed_at <= ?', end_dt)   if end_dt

      query = query.for_user(params[:userId]) if params[:userId].present?

      if params[:encounterId].present?
        enc = Encounter.find_by(encounter_id: params[:encounterId])
        return render json: { data: [], meta: pagination_meta(1, per_page, 0) }, status: :ok unless enc
        query = query.where(encounter_id: enc.id)
      end

      offset = (page - 1) * per_page

      total = query.count
      records = query.order(accessed_at: :desc).offset(offset).limit(per_page)

      render json: {
        data: records.map { |r|
          {
            id: r.id,
            encounter_db_id: r.encounter_id,
            accessed_by_user_id: r.accessed_by_user_id,
            accessed_at: r.accessed_at&.iso8601
          }
        },
        meta: pagination_meta(page, per_page, total)
      }, status: :ok
    end

    private

    def validate_pagination_params
      page_param = params[:page]
      per_page_param = params[:perPage]

      if page_param.present?
        unless page_param.to_s =~ /\A\d+\z/
          render_bad_request("page must be a positive integer") and return nil
        end
        page = page_param.to_i
        if page < 1
          render_bad_request("page must be >= 1") and return nil
        end
      else
        page = 1
      end

      if per_page_param.present?
        unless per_page_param.to_s =~ /\A\d+\z/
          render_bad_request("perPage must be a positive integer") and return nil
        end
        per_page = per_page_param.to_i
        if per_page < 1 || per_page > 1000
          render_bad_request("perPage must be between 1 and 1000") and return nil
        end
      else
        per_page = 50
      end

      [page, per_page]
    end

    def pagination_meta(page, per_page, total)
      total_pages = per_page > 0 ? (total.to_f / per_page).ceil : 0
      { page: page, per_page: per_page, total: total, total_pages: total_pages }
    end

    # Accepts either a date "YYYY-MM-DD" or an ISO8601 datetime string.
    # For date-only input, returns beginning_of_day (is_end: false) or end_of_day (is_end: true).
    def parse_date_param(value, is_end: false)
      return nil if value.blank?
      begin
        if value =~ /\A\d{4}-\d{2}-\d{2}\z/
          d = Date.iso8601(value)
          return is_end ? d.end_of_day : d.beginning_of_day
        else
          Time.iso8601(value)
        end
      rescue ArgumentError
        nil
      end
    end

    def render_bad_request(msg)
      render json: { error: msg }, status: :bad_request
    end
  end
end
