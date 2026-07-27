require "rails_helper"

RSpec.describe "business_time Polish holidays configuration" do
  it "computes Easter Sunday correctly (known values)" do
    expect(PolishHolidays.easter_sunday(2026)).to eq(Date.new(2026, 4, 5))
    expect(PolishHolidays.easter_sunday(2024)).to eq(Date.new(2024, 3, 31))
  end

  it "treats a weekend day as a non-business day" do
    saturday = Date.new(2026, 7, 18)
    expect(saturday.workday?).to be(false)
  end

  it "treats a fixed Polish holiday as a non-business day" do
    constitution_day = Date.new(2026, 5, 3) # Święto Konstytucji 3 Maja
    expect(BusinessTime::Config.holidays).to include(constitution_day)
    expect(constitution_day.workday?).to be(false)
  end

  it "treats a movable (Easter-based) Polish holiday as a non-business day" do
    easter_monday = PolishHolidays.easter_sunday(2026) + 1 # Poniedziałek Wielkanocny
    corpus_christi = PolishHolidays.easter_sunday(2026) + 60 # Boże Ciało
    expect(BusinessTime::Config.holidays).to include(easter_monday, corpus_christi)
    expect(easter_monday.workday?).to be(false)
    expect(corpus_christi.workday?).to be(false)
  end

  it "excludes weekends and holidays when adding business days" do
    # Wed 2026-04-01 + 7 business days must skip the weekend, Easter Monday
    # (2026-04-06), and land beyond a naive +7 calendar days.
    start = Date.new(2026, 4, 1)
    deadline = 7.business_days.after(start)
    expect(deadline).to be > (start + 7)
  end
end
