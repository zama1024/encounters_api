class EncounterFilterService
  attr_reader :errors, :filters

  ENCOUNTER_TYPES = (defined?(Encounter) && Encounter.const_defined?(:ENCOUNTER_TYPES)) ? Encounter::ENCOUNTER_TYPES : %w[initial_assessment follow_up treatment_session]

  def initialize(params = {})
    @params = params || {}
    @errors = []
    @filters = {}
    build_filters
  end

  def valid?
    errors.empty?
  end

  # Returns true if the given encounter matches all provided filters
  def matches?(encounter)
    return false unless encounter
    filters.all? do |key, value|
      case key
      when :encounter_id     then encounter.encounter_id == value
      when :patient_id       then encounter.patient_id == value
      when :provider_id      then encounter.provider_id == value
      when :encounter_type   then encounter.encounter_type == value
      when :encounter_date_before then encounter.encounter_date && encounter.encounter_date <= value
      when :encounter_date_after  then encounter.encounter_date && encounter.encounter_date >= value
      else true
      end
    end
  end

  private

  def build_filters
    add_string_filter(:encounterId,    :encounter_id)
    add_string_filter(:patientId,      :patient_id)
    add_string_filter(:providerId,     :provider_id)
    add_string_filter(:encounterType,  :encounter_type) { |v| validate_encounter_type(v) }

    add_date_filter(:encounterDateBefore, :encounter_date_before)
    add_date_filter(:encounterDateAfter,  :encounter_date_after)
  end

  def add_string_filter(param_key, filter_key)
    return unless present_param?(param_key)
    val = @params[param_key].to_s
    if block_given?
      yield(val)
    end
    @filters[filter_key] = val
  end

  def add_date_filter(param_key, filter_key)
    return unless present_param?(param_key)
    dt = parse_datetime(@params[param_key])
    if dt
      @filters[filter_key] = dt
    else
      @errors << "#{param_key} must be a valid ISO8601 timestamp"
    end
  end

  def validate_encounter_type(value)
    unless ENCOUNTER_TYPES.include?(value)
      @errors << "encounterType must be one of: #{ENCOUNTER_TYPES.join(', ')}"
    end
  end

  def parse_datetime(value)
    return nil if value.nil? || value.to_s.strip.empty?
    Time.iso8601(value) rescue nil
  end

  def present_param?(key)
    v = @params[key]
    !(v.nil? || (v.respond_to?(:empty?) && v.empty?))
  end
end
