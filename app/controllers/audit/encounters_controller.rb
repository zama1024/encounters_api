module Audit
  class EncountersController < ApplicationController
    include ApiAuthenticatable

    # GET /audit/encounters
    # Query params:
    #   start_date, end_date (ISO8601)
    #   user_id
    #   encounterId
    #   page (1-based)
    #   per_page
    def index
      start_dt = parse_datetime(params[:start_date]) if params[:start_date].present?
      end_dt   = parse_datetime(params[:end_date])   if params[:end_date].present?

      if params[:start_date].present? && !start_dt
        return render_bad_request("start_date must be a valid ISO8601 timestamp")
      end
      if params[:end_date].present? && !end_dt
        return render_bad_request("end_date must be a valid ISO8601 timestamp")
      end

      # Validate pagination params and return error if invalid
      page, per_page = validate_pagination_params
      return unless page # validate_pagination_params renders error and returns nil on failure

      query = AuditAccess.all
      query = query.where('accessed_at >= ?', start_dt) if start_dt
      query = query.where('accessed_at <= ?', end_dt)   if end_dt

      query = query.for_user(params[:user_id]) if params[:user_id].present?

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
      per_page_param = params[:per_page]

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
          render_bad_request("per_page must be a positive integer") and return nil
        end
        per_page = per_page_param.to_i
        if per_page < 1 || per_page > 1000
          render_bad_request("per_page must be between 1 and 1000") and return nil
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

    def parse_datetime(value)
      return nil if value.blank?
      Time.iso8601(value) rescue nil
    end

    def render_bad_request(msg)
      render json: { error: msg }, status: :bad_request
    end
  end
end
