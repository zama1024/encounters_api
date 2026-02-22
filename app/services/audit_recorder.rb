class AuditRecorder
  # Records that an encounter was accessed. Keeps stored fields minimal.
  def self.record_view(encounter:, current_user: nil)
    AuditAccess.create(
      encounter: encounter,
      accessed_by_user_id: current_user&.id,
      accessed_at: Time.current
    )
  end
end
