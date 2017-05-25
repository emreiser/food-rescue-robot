class Date
  def week_of_year(mondays = false)
    # Use %U for weeks starting on Sunday
    # Use %W for weeks starting on Monday
    strftime(mondays ? "%W" : "%U").to_i + 1
  end

  def week_of_month(mondays = false)
    week_of_year(mondays) - beginning_of_month.week_of_year(mondays) + 1
  end
end