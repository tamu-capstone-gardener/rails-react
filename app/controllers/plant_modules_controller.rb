class PlantModulesController < AuthenticatedApplicationController
  def new
    @plant_module = PlantModule.new(location_type: "indoor")

    filters = {
      max_height: params[:max_height],
      max_width: params[:max_width],
      maintenance: params[:maintenance],
      edibility_rating: params[:edibility_rating],
      page: params[:page]
    }

    @recommendations = PlantRecommendationService.new(
      location_type: @plant_module.location_type,
      filters: filters
    ).recommendations

    if turbo_frame_request? && request.headers["Turbo-Frame"] == "recommendations"
      render partial: "plants/recommendations_frame", locals: { plants: @recommendations }, layout: false
    else
      render :new
    end
  end

  def create
    @plant_module = PlantModule.new(plant_module_params)
    @plant_module.user = current_user
    @plant_module.id = SecureRandom.uuid

    if @plant_module.save
      # Calculate care schedule based on associated plants
      schedule_attrs = CareScheduleCalculator.new(@plant_module.plants).calculate
      CareSchedule.create!(plant_module: @plant_module, **schedule_attrs)

      redirect_to plant_modules_path, notice: "Plant module created successfully."
    else
      flash.now[:alert] = "Error creating plant module."
      render :new
    end
  end

  def show
    @plant_module = PlantModule.find_by(id: params[:id])

    if @plant_module.nil?
      redirect_to plant_modules_path, alert: "Plant module not found." and return
    elsif @plant_module.user != current_user
      redirect_to plant_modules_path, alert: "You are not authorized to access this plant module." and return
    end

    @sensors = @plant_module.sensors.includes(:time_series_data)
    @sensor_data = {}
    @sensors.each do |sensor|
      first_timestamp = sensor.time_series_data.minimum(:timestamp)

      if first_timestamp
        hourly_data = sensor.time_series_data
                            .where("timestamp >= ?", first_timestamp)
                            .group_by_hour(:timestamp)
                            .average(:value)
                            .transform_values { |v| v.nil? ? nil : v.to_f.round(2) }

        @sensor_data[sensor.id] = hourly_data
      else
        @sensor_data[sensor.id] = {}
      end
    end

    if @plant_module.location_type.downcase == "outdoor" && @plant_module.zip_code.present?
      @zone_data = zone_for_zip(@plant_module.zip_code)
    end
  end

  def edit
    @plant_module = current_user.plant_modules.find_by(id: params[:id])
    redirect_to plant_modules_path, alert: "Module not found." unless @plant_module

    filters = {
    max_height: params[:max_height],
    max_width: params[:max_width],
    maintenance: params[:maintenance],
    edibility_rating: params[:edibility_rating],
    page: params[:page]
  }

  @recommendations = PlantRecommendationService.new(
    location_type: @plant_module.location_type,
    filters: filters
  ).recommendations
  end

  def update
    @plant_module = current_user.plant_modules.find_by(id: params[:id])
    unless @plant_module
      redirect_to plant_modules_path, alert: "Module not found." and return
    end

    if @plant_module.update(plant_module_params)
      redirect_to @plant_module, notice: "Module updated successfully."
    else
      flash.now[:alert] = "Error updating module."
      render :edit
    end
  end

  def destroy
    @plant_module = current_user.plant_modules.find_by(id: params[:id])
    if @plant_module
      @plant_module.destroy
      redirect_to plant_modules_path, notice: "Module deleted successfully."
    else
      redirect_to plant_modules_path, alert: "Module not found."
    end
  end


  private

  def plant_module_params
    params.require(:plant_module).permit(:name, :description, :location, :location_type, :zip_code, plant_ids: [])
  end
end
