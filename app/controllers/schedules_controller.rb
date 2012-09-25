class SchedulesController < ApplicationController
  before_filter :authenticate_volunteer!
  before_filter :admin_only, :only => [:fast_schedule,:today,:tomorrow,:yesterday]

  active_scaffold :schedule do |conf|
    conf.list.sorting = {:day_of_week => 'ASC'}
    conf.list.per_page = 500
    conf.columns = [:region,:day_of_week,:donor,:recipient,:volunteer,:time_start,:time_stop,
                    :irregular,:backup,:transport_type,:food_types,:needs_training,:public_notes,
                    :prior_volunteer,:admin_notes]
    conf.columns[:day_of_week].form_ui = :select
    conf.columns[:day_of_week].options = {:options => [["Unknown/varies",nil],["Sunday",0],
                                                       ["Monday",1],["Tuesday",2],["Wednesday",3],
                                                       ["Thursday",4],["Friday",5],["Saturday",6]]}
    conf.columns[:time_start].description = "e.g., 1400"
    conf.columns[:time_stop].description = "e.g., 1600"
    conf.columns[:donor].form_ui = :select
    conf.columns[:volunteer].form_ui = :select
    conf.columns[:volunteer].clear_link
    conf.columns[:recipient].form_ui = :select
    conf.columns[:food_types].form_ui = :select
    conf.columns[:food_types].clear_link
    conf.columns[:transport_type].form_ui = :select
    conf.columns[:prior_volunteer].form_ui = :select
    conf.columns[:prior_volunteer].clear_link
    conf.columns[:region].form_ui = :select
    conf.columns[:irregular].label = "Irregular"
    conf.columns[:backup].label = "Backup Pickup"
    # if marking isn't enabled it creates errors on delete :(
    conf.actions.add :mark
  end

  # Only admins can change things in the schedule table
  def create_authorized?
    current_volunteer.super_admin? or current_volunteer.region_admin?
  end

  def open
    @open_schedules = Schedule.where("volunteer_id IS NULL AND recipient_id IS NOT NULL and region_id IN (#{current_volunteer.assignments.collect{ |a| a.region_id }.join(",")})")
    render :open
  end
  def open_old
    @conditions = "volunteer_id is NULL AND recipient_id IS NOT NULL and donor_id IS NOT NULL and region_id IN (#{current_volunteer.assignments.collect{ |a| a.region_id }.join(",")})"
    index
  end

  def mine
    @volunteer_schedules = Schedule.where(:volunteer_id => current_volunteer)
  end
  def mine_old
    @conditions = "volunteer_id = '#{current_volunteer.id}'"
    index
  end

  def fast_schedule
    @volunteer_schedules = Schedule.where("region_id IN (#{current_volunteer.assignments.collect{ |a| a.region_id }.join(",")})")
  end
  def today
    @conditions = "day_of_week = #{Date.today.wday}"
    index
  end
  def tomorrow
    @conditions = "day_of_week = #{Date.today.wday + 1 % 6}"
    index
  end
  def yesterday
    @conditions = "day_of_week = #{Date.today.wday - 1 % 6}"
    index
  end

  def conditions_for_collection
    if current_volunteer.assignments.length == 0
      @base_conditions = "1 = 0"
    else
      @base_conditions = "region_id IN (#{current_volunteer.assignments.collect{ |a| a.region_id }.join(",")})"
    end
    @conditions.nil? ? @base_conditions : @base_conditions + " AND " + @conditions
  end

  def take
    s = Schedule.find(params[:id])
    if current_volunteer.regions.collect{ |r| r.id }.include? s.region_id
      s.volunteer = current_volunteer
      s.save
      flash[:notice] = "Successfully took 1 shift."
    else
      flash[:notice] = "Cannot take that pickup since you are not a member of that region."
    end
    open
  end

  def admin_only
    redirect_to(root_path) unless current_volunteer.super_admin? or current_volunteer.region_admin?
  end

end 
