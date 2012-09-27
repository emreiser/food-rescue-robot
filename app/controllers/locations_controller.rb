class LocationsController < ApplicationController
  before_filter :authenticate_volunteer!

  def donors
    index("is_donor")
  end

  def recipients
    index("NOT is_donor")
  end

  def index(filter=nil,header="All Locations")
    filter = filter.nil? ? "" : " AND #{filter}"
    @locations = Location.where("region_id IN (#{current_volunteer.region_ids.join(",")})#{filter}")
    @header = header
    @regions = Region.all
    if current_volunteer.super_admin?
      @my_admin_regions = @regions
    else
      @my_admin_regions = current_volunteer.assignments.collect{ |a| a.admin ? a.region : nil }.compact
    end
    render :index
  end

  def show
    @loc = Location.find(params[:id])
    unless current_volunteer.super_admin? or (current_volunteer.region_ids.include? @loc.region_id)
      flash[:notice] = "Can't view location for a region you're not assigned to..."
      redirect_to(root_path)
      return
    end
    @json = @loc.to_gmaps4rails
  end

  def destroy
    @l = Location.find(params[:id])
    return unless check_permissions(@l)
    @l.destroy
    redirect_to(request.referrer)
  end

  def new
    @location = Location.new
    @location.is_donor = params[:is_donor]
    @location.region_id = params[:region_id]
    return unless check_permissions(@location)
    @action = "create"
    session[:my_return_to] = request.referer
    render :new
  end

  def check_permissions(l)
    unless current_volunteer.super_admin? or (current_volunteer.admin_region_ids.include? l.region_id) or
      flash[:notice] = "Not authorized to create/edit locations for that region"
      redirect_to(root_path)
      return false
    end
    return true
  end

  def create
    @location = Location.new(params[:location])
    return unless check_permissions(@location)
    # can't set admin bits from CRUD controls
    if @location.save
      flash[:notice] = "Created successfully."
      unless session[:my_return_to].nil?
        redirect_to(session[:my_return_to])
      else
        index
      end
    else
      flash[:notice] = "Didn't save successfully :("
      render :new
    end
  end

  def edit
    @location = Location.find(params[:id])
    return unless check_permissions(@location)
    @action = "update"
    session[:my_return_to] = request.referer
    render :edit
  end

  def update
    @location = Location.find(params[:id])
    return unless check_permissions(@location)
    # can't set admin bits from CRUD controls
    if @location.update_attributes(params[:location])
      flash[:notice] = "Updated Successfully."
      unless session[:my_return_to].nil?
        redirect_to(session[:my_return_to])
      else
        index
      end
    else
      flash[:notice] = "Update failed :("
      render :edit
    end
  end

  #  conf.columns[:donor_type].options = {:options => [["",nil],["Grocer","Grocer"],["Bakery","Bakery"],["Caterer","Caterer"],["Restaurant","Restaurant"],["Cafeteria","Cafeteria"],["Cafe","Cafe"],["Market","Market"],["Farm","Farm"],["Community Garden","Community Garden"],["Individual","Individual"],["Other","Other"]]}

end 
