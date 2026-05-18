---
name: Rails Model
description: Create well-structured Rails models with validations, associations, and tests
triggers:
  - create model
  - add model
  - model for
---

# Rails Model Creation

## Model Structure Pattern

```ruby
class ModelName < ApplicationRecord
  # Constants
  STATUSES = %w[draft published archived].freeze

  # Enums
  enum :status, { draft: 0, published: 1, archived: 2 }

  # Validations (alphabetical)
  validates :name, presence: true, length: { maximum: 255 }
  validates :status, inclusion: { in: STATUSES }

  # Associations (alphabetical)
  belongs_to :user
  has_many :comments, dependent: :destroy

  # Scopes (alphabetical)
  scope :active, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def display_name
    name.titleize
  end
end
```

## Test Pattern

```ruby
# test/models/model_name_test.rb
require "test_helper"

class ModelNameTest < ActiveSupport::TestCase
  test "requires name" do
    record = ModelName.new(name: nil)
    assert_not record.valid?
    assert_includes record.errors[:name], "can't be blank"
  end

  test ".recent returns records ordered by created_at desc" do
    results = ModelName.recent
    assert results.first.created_at >= results.last.created_at
  end
end
```

## Checklist
- [ ] Migration with proper column types and indexes
- [ ] Validations for required fields
- [ ] Associations with dependent options
- [ ] Scopes for common queries
- [ ] Tests for validations and methods
- [ ] Fixtures for test data
