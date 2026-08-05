class Toxo::SampleEditForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :Lot, :string
  attribute :Level, :string
  attribute :sample_collection_date, :date
  attribute :dispatch_date, :date
  attribute :note, :string

  attr_reader :sample, :contractor, :saved_fields

  def initialize(sample:, contractor:, **attrs)
    @sample = sample
    @contractor = contractor
    @saved_fields = []
    super(attrs)
  end

  # Persists only the fields that pass their own editability/validation check.
  # Fields that fail are recorded in #errors but do not block the others from saving —
  # each field has an independent editability window (see spec Clarifications).
  def save
    errors.clear
    @saved_fields = []
    save_lot_and_level
    save_sample_collection_date
    save_dispatch_date
    save_note
    errors.empty?
  end

  private

  def lot_or_level_changed?
    self.Lot.to_s != sample.Lot.to_s || self.Level.to_s != sample.Level.to_s
  end

  def save_lot_and_level
    return unless lot_or_level_changed?

    unless sample.lot_level_editable?
      errors.add(:Lot, :locked, message: "cannot be changed once a result has been authorized")
      return
    end

    if self.Lot.blank?
      errors.add(:Lot, :blank)
      return
    end
    if self.Lot.length > 20 || self.Level.to_s.length > 20
      errors.add(:Lot, :too_long) if self.Lot.length > 20
      errors.add(:Level, :too_long) if self.Level.to_s.length > 20
      return
    end

    sample.update_columns(Lot: self.Lot, Level: self.Level)
    @saved_fields += [ :Lot, :Level ]
  end

  def save_sample_collection_date
    return if sample_collection_date.blank?

    unless sample.sample_collection_date_editable?(sample_collection_date)
      errors.add(:sample_collection_date, :locked,
        message: "cannot be changed: once the sample is accepted, it can only be set once, before any result has been authorized")
      return
    end

    sample.update_column(:sample_collection_date, sample_collection_date)
    @saved_fields << :sample_collection_date
  end

  def save_dispatch_date
    if dispatch_date.blank?
      errors.add(:dispatch_date, :blank)
      return
    end

    return if dispatch_date == sample.dispatch_date&.to_date

    unless sample.dispatch_date_editable?
      errors.add(:dispatch_date, :locked, message: "cannot be changed once the sample has been accepted")
      return
    end

    sample.update_column(:dispatch_date, dispatch_date)
    @saved_fields << :dispatch_date
  end

  def save_note
    return if note.blank?

    sample.append_comment(note, contractor)
    @saved_fields << :note
  end
end
