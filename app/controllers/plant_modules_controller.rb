class PlantModulesController < AuthenticatedApplicationController
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
      @sensor_data[sensor.id] = sensor.time_series_data.group("DATE(timestamp)").pluck(Arel.sql("DATE(timestamp), SUM(value)"))
    end
  end

  def index
    @plant_modules = current_user.plant_modules
  end

<<<<<<< HEAD
  def new
    @plant_module = PlantModule.new(location_type: "indoor")

    # Read filter values from params (if present); default values as used in the service.
    filters = {
      max_height: params[:max_height],
      max_width: params[:max_width],
      maintenance: params[:maintenance],
      edible: params[:edible]
    }

    @recommendations = PlantRecommendationService.new(
      location_type: @plant_module.location_type,
      filters: filters
    ).recommendations
  end
  

=======
>>>>>>> 5108ca6 (part 2)
  def create
    @plant_module = PlantModule.new(plant_module_params)
    @plant_module.user = current_user
    @plant_module.id = SecureRandom.uuid
    if @plant_module.save
      redirect_to plant_modules_path, notice: "Plant module created successfully."
    else
      flash.now[:alert] = "Error creating plant module."
      render :new
    end
  end

  def simple_create
    PlantModule.create!(
      id: SecureRandom.uuid,
      user_id: current_user.uid,
      name: "Example Module",
      description: "Module description here",
      location: "Module location"
    )
    redirect_to plant_modules_path, notice: "Module created successfully."
  end

  private

    def plant_module_params
      params.require(:plant_module).permit(:name, :description, :location, :location_type, :zip_code)
    end

end
