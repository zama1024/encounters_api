class PaginationService
  Result = Struct.new(:page, :per_page, :errors)

  DEFAULT_PER_PAGE = 50
  MAX_PER_PAGE = 1000

  def initialize(params = {}, page_key: 'page', per_page_key: 'perPage')
    @params = params || {}
    @page_key = page_key
    @per_page_key = per_page_key
    @errors = []
  end

  def call
    page = parse_page
    per_page = parse_per_page
    Result.new(page || 1, per_page || DEFAULT_PER_PAGE, @errors)
  end

  private

  def parse_page
    p = @params[@page_key] || @params[@page_key.to_sym]
    return 1 if p.nil? || p.to_s.strip == ''

    unless p.to_s =~ /\A\d+\z/
      @errors << "page must be a positive integer"
      return nil
    end

    page = p.to_i
    if page < 1
      @errors << "page must be >= 1"
      return nil
    end

    page
  end

  def parse_per_page
    pp = @params[@per_page_key] || @params[@per_page_key.to_sym]
    return DEFAULT_PER_PAGE if pp.nil? || pp.to_s.strip == ''

    unless pp.to_s =~ /\A\d+\z/
      @errors << "perPage must be a positive integer"
      return nil
    end

    per_page = pp.to_i
    if per_page < 1 || per_page > MAX_PER_PAGE
      @errors << "perPage must be between 1 and #{MAX_PER_PAGE}"
      return nil
    end

    per_page
  end
end
