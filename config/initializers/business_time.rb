# Konfiguracja dni roboczych (gem business_time) z uwzględnieniem polskich
# świąt państwowych — używana m.in. do liczenia 7 dni roboczych od daty
# przyjęcia próbki (Notifications::RegistrationRemindersFinder).
#
# Uwzględnia święta stałe oraz ruchome (zależne od Wielkanocy: Poniedziałek
# Wielkanocny, Zielone Świątki, Boże Ciało). Świąt nie liczymy jako dni robocze.

module PolishHolidays
  module_function

  # Data Wielkanocy (niedziela) dla danego roku — algorytm Meeusa/Jonesa/Butchera.
  def easter_sunday(year)
    a = year % 19
    b = year / 100
    c = year % 100
    d = b / 4
    e = b % 4
    f = (b + 8) / 25
    g = (b - f + 1) / 3
    h = (19 * a + b - d - g + 15) % 30
    i = c / 4
    k = c % 4
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 22 * l) / 451
    month = (h + l - 7 * m + 114) / 31
    day = ((h + l - 7 * m + 114) % 31) + 1
    Date.new(year, month, day)
  end

  # Wszystkie polskie dni wolne (stałe + ruchome) dla danego roku.
  def for_year(year)
    easter = easter_sunday(year)
    [
      Date.new(year, 1, 1),    # Nowy Rok
      Date.new(year, 1, 6),    # Trzech Króli
      easter,                  # Wielkanoc (niedziela)
      easter + 1,              # Poniedziałek Wielkanocny
      Date.new(year, 5, 1),    # Święto Pracy
      Date.new(year, 5, 3),    # Święto Konstytucji 3 Maja
      easter + 49,             # Zielone Świątki (niedziela)
      easter + 60,             # Boże Ciało
      Date.new(year, 8, 15),   # Wniebowzięcie NMP
      Date.new(year, 11, 1),   # Wszystkich Świętych
      Date.new(year, 11, 11),  # Święto Niepodległości
      Date.new(year, 12, 25),  # Boże Narodzenie (pierwszy dzień)
      Date.new(year, 12, 26)   # Boże Narodzenie (drugi dzień)
    ]
  end

  # Święta dla zakresu lat wokół bieżącego roku.
  def around(base_year = Date.current.year, span: 3)
    ((base_year - span)..(base_year + span)).flat_map { |y| for_year(y) }
  end
end

BusinessTime::Config.holidays.replace(PolishHolidays.around)
