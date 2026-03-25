# == Schema Information
#
# Table name: Projects
#
#  Id                       :integer          not null, primary key
#  Name                     :text(4294967295) not null
#  Description              :text(4294967295)
#  WithCutter               :boolean          not null
#  PlateDimensionX          :integer          not null
#  PlateDimensionY          :integer          not null
#  Prefix                   :text(4294967295)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  is_blocked_online        :boolean          default(FALSE), not null
#  survey_description       :text(65535)
#  PdfNameOfAnalysis        :text(4294967295)
#  PdfDescription           :text(4294967295)
#  product_name_in_invoice  :text(65535)
#  pkwiu_in_invoice         :string(255)
#  brutto_price             :decimal(6, 2)
#  FinalProtocoleHeader     :text(4294967295)
#  responsible_person_email :string(255)
#  has_selectable_analytes  :boolean
#  InjectionVolume          :decimal(4, 1)    not null
#  eng_name                 :string(255)
#  is_active                :boolean          default(TRUE), not null
#
FactoryBot.define do
  factory :project, class: Project do
    Id {2}
    Name { "Witamina D" }
    WithCutter { true }
    PlateDimensionX { 8 }
    PlateDimensionY { 12 }
    is_blocked_online { true }
    InjectionVolume { 0 }
    eng_name { "Vitamin D" }
    # initialize_with { Project.find_or_create_by(Id: 2, Name: "Witamina D", WithCutter: true, PlateDimensionX: 8, PlateDimensionY: 12, is_blocked_online: true, InjectionVolume: 0, eng_name: "Vitamin D") }
  end

  factory :project2, class: Project do
    Id {3}
    Name { "Aminokwasy" }
    WithCutter { true }
    PlateDimensionX { 8 }
    PlateDimensionY { 12 }
    is_blocked_online { true }
    InjectionVolume { 0 }
    eng_name { "Amino acids" }
    # initialize_with { Project.find_or_create_by(Id: 3, Name: "Aminokwasy", WithCutter: true, PlateDimensionX: 8, PlateDimensionY: 12, is_blocked_online: true, InjectionVolume: 0, eng_name: "Amino acids") }
  end

  factory :project_without_fixed_id, class: Project do
    Name { "Aminokwasy" }
    WithCutter { true }
    PlateDimensionX { 8 }
    PlateDimensionY { 12 }
    is_blocked_online { true }
    InjectionVolume { 0 }
    eng_name { "Amino acids" }
    # initialize_with { Project.find_or_create_by(Id: 3, Name: "Aminokwasy", WithCutter: true, PlateDimensionX: 8, PlateDimensionY: 12, is_blocked_online: true, InjectionVolume: 0, eng_name: "Amino acids") }
  end

  factory :toxo_project_igg, class: Project do
    Id { 39 }
    Name { "Toxo IgG" }
    WithCutter { false }
    PlateDimensionX { 8 }
    PlateDimensionY { 12 }
    is_blocked_online { false }
    InjectionVolume { 0 }
    eng_name { "Toxo IgG" }
    initialize_with { Project.find_or_create_by(Id: 39) { |p| p.assign_attributes(Name: "Toxo IgG", WithCutter: false, PlateDimensionX: 8, PlateDimensionY: 12, is_blocked_online: false, InjectionVolume: 0, eng_name: "Toxo IgG") } }
  end

  factory :toxo_project_igm, class: Project do
    Id { 40 }
    Name { "Toxo IgM" }
    WithCutter { false }
    PlateDimensionX { 8 }
    PlateDimensionY { 12 }
    is_blocked_online { false }
    InjectionVolume { 0 }
    eng_name { "Toxo IgM" }
    initialize_with { Project.find_or_create_by(Id: 40) { |p| p.assign_attributes(Name: "Toxo IgM", WithCutter: false, PlateDimensionX: 8, PlateDimensionY: 12, is_blocked_online: false, InjectionVolume: 0, eng_name: "Toxo IgM") } }
  end
end


# "Id":"2"
# "Name":"Witamina D"
# "Description":"Profil metabolitów witaminy D zawierający całkowite stężenie 25(OH)D z procentowym udziałem form 25(OH)D3 i 25(OH)D2 oraz stężenie 24,25(OH)2D3 i stosunek 25(OH)D3 : 24,25(OH)2D3"
# "WithCutter":"1"
# "PlateDimensionX":"8"
# "PlateDimensionY":"12"
# "Prefix":null
# "created_at":"0000-00-00 00:00:00"
# "updated_at":"2017-12-04 10:51:34"
# "is_blocked_online":"0"
# "survey_description":"Dziękujemy za wypełnienie poniższej ankiety. Dane udostępnione za jej pośrednictwem pozwolą na uzyskanie unikalnej wiedzy na temat wpływu diety i suplementacji na poziomy poszczególnych metabolitów witaminy D w obrębie wysoce reprezentatywnej grupy badanej. Dane będą udostępniane okresowo dla współpracujących z Nami ośrodków celem ciągłego polepszania jakości Naszych usług oraz dzielenia się wiedzą na temat wpływu diety oraz suplementacji na metabolizm witaminy D."
# "PdfNameOfAnalysis":"Całkowite stężenie 25(OH)D"
# "PdfDescription":"Badanie wykonane metodą wysokosprawnej chromatografii cieczowej sprzężonej z tandemową spektrometrią mas (LC-MS\/MS) z suchej kropli krwi."
# "product_name_in_invoice":"Oznaczenie poziomu witaminy D z suchej kropli krwi techniką LC-MS\/MS zgodnie z umową"
# "pkwiu_in_invoice":"86.90.15"
# "brutto_price":"50.00"
# "FinalProtocoleHeader":null
# "responsible_person_email":"renata.halak@masdiag.pl"
# "has_selectable_analytes":"0"
# "InjectionVolume":"22.0"
