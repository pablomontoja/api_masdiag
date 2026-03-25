FactoryBot.define do
  factory :toxo_sample, class: Toxo::Sample do
    sequence(:Code) { |n| "TX#{n.to_s.rjust(3, '0')}A" }
    MaterialType { :dbs }
    SampleState { 1 }
    SampleStatus { 1 }
    WasWrongRegistration { false }
    IsWrongRegistration { false }
    WrongRegistrationStatus { 0 }
    RegistrationDate { Time.current }
    association :patient, factory: :toxo_patient

    to_create { |instance| instance.save!(validate: false) }
  end
end
