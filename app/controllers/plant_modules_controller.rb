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
                            .transform_values do |v|
                              next nil if v.nil?
                              value = v.to_f
                              if sensor.measurement_type == "light_analog"
                                ((4096 - value).abs / 4096.0 * 100).round(2)
                              else
                                value.round(2)
                              end
                            end

        @sensor_data[sensor.id] = hourly_data
      else
        @sensor_data[sensor.id] = {}
      end
    end

    @control_signals = @plant_module.control_signals.includes(:last_execution).order(:signal_type)

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

  def generate_timelapse
    @plant_module = PlantModule.find_by(id: params[:id])
    TimelapseWorker.perform_async(@plant_module.id)
    redirect_to @plant_module, notice: "Timelapse generation has started and will appear here when ready."
  end


  private

  def plant_module_params
    params.require(:plant_module).permit(:name, :description, :location, :location_type, :zip_code, plant_ids: [])
  end
end
