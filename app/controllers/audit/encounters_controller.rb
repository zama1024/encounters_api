module Audit
  class EncountersController < ApplicationController
    include ApiAuthenticatable

    # GET /audit/encounters
    def index
      result = Audit::EncountersQueryService.new(params: params).call

      unless result.success
        render json: { error: result.errors.join('; ') }, status: :bad_request and return
      end

      render json: { data: result.records, meta: result.meta }, status: :ok
    end
  end
end
