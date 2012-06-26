class Location < ActiveRecord::Base
  geocoded_by :address, :latitude => :lat, :longitude => :lng   # can also be an IP address
  after_validation :geocode    
  attr_accessible :address, :admin_notes, :contact, :donor_type, :hours, :is_donor, :lat, :lng, :name, :public_notes, :recip_category, :website

  # ActiveScaffold CRUD-level restrictions
  def authorized_for_update?
    current_user.admin
  end
  def authorized_for_create?
    current_user.admin
  end
  def authorized_for_delete?
    current_user.admin
  end
end
