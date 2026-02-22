require 'rails_helper'

RSpec.describe PaginationService, type: :service do
  describe '#call' do
    it "returns default page and per_page when no params provided" do
      result = PaginationService.new({}).call
      expect(result.page).to eq(1)
      expect(result.per_page).to eq(50)
      expect(result.errors).to be_empty
    end

    it "accepts valid page and perPage params" do
      result = PaginationService.new({ 'page' => '2', 'perPage' => '25' }).call
      expect(result.page).to eq(2)
      expect(result.per_page).to eq(25)
      expect(result.errors).to be_empty
    end

    it "rejects non-numeric page" do
      result = PaginationService.new({ 'page' => 'abc' }).call
      expect(result.errors).to include("page must be a positive integer")
    end

    it "rejects page < 1" do
      result = PaginationService.new({ 'page' => '0' }).call
      expect(result.errors).to include("page must be >= 1")
    end

    it "rejects non-numeric perPage" do
      result = PaginationService.new({ 'perPage' => 'xyz' }).call
      expect(result.errors).to include("perPage must be a positive integer")
    end

    it "rejects perPage < 1" do
      result = PaginationService.new({ 'perPage' => '0' }).call
      expect(result.errors).to include(/perPage must be between/)
    end

    it "rejects perPage > 1000" do
      result = PaginationService.new({ 'perPage' => '1001' }).call
      expect(result.errors).to include(/perPage must be between/)
    end

    it "accepts perPage at boundary (1 and 1000)" do
      result1 = PaginationService.new({ 'perPage' => '1' }).call
      expect(result1.per_page).to eq(1)
      expect(result1.errors).to be_empty

      result2 = PaginationService.new({ 'perPage' => '1000' }).call
      expect(result2.per_page).to eq(1000)
      expect(result2.errors).to be_empty
    end

    it "ignores empty string params and uses defaults" do
      result = PaginationService.new({ 'page' => '', 'perPage' => '' }).call
      expect(result.page).to eq(1)
      expect(result.per_page).to eq(50)
      expect(result.errors).to be_empty
    end
  end
end
