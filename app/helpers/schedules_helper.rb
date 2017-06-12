module SchedulesHelper

  def display_week_assignment(week_assignment)
    if week_assignment.blank?
      "Every week"
    else
      week_assignment.map { |a| ScheduleVolunteer::WEEK_OPTIONS[a] }.join(", ")
    end
  end

end
