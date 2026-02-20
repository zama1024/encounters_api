class AuditAccess < ApplicationRecord
  belongs_to :encounter
  belongs_to :accessed_by_user, class_name: "User", foreign_key: "accessed_by_user_id", optional: true

  validates :encounter_id, presence: true
  validates :accessed_at, presence: true

  scope :between, ->(from, to) { where(accessed_at: from..to) }
  scope :for_user, ->(user_id) { where(accessed_by_user_id: user_id) if user_id.present? }
end
