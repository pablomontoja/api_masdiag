FactoryBot.define do
  factory :project, class: Project do
    Id {2}
    Name { "Witamina D" }
    WithCutter { true }
    PlateDimensionX { 8 }
    PlateDimensionY { 12 }
    is_blocked_online { true }
    InjectionVolume { 0 }
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
