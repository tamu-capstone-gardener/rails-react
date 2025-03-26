class PlantModulesController < AuthenticatedApplicationController
<<<<<<< HEAD
=======
  def new
    @plant_module = PlantModule.new(location_type: "indoor")
    
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

  def create
    @plant_module = PlantModule.new(plant_module_params)
    @plant_module.user = current_user
    @plant_module.id = SecureRandom.uuid  # Optional if you add a similar before_create in PlantModule
  
    if @plant_module.save   
      CareSchedule.create!(
        plant_module_id: @plant_module.id,
        watering_frequency: 7,
        fertilizer_frequency: 30,
        light_hours: 8,
        soil_moisture_pref: "medium"
      )
  
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
      @sensor_data[sensor.id] = sensor.time_series_data.group("DATE(timestamp)").pluck(Arel.sql("DATE(timestamp), SUM(value)"))
    end
  end

  def index
    @plant_modules = current_user.plant_modules
  end


>>>>>>> 123468a (made creating modules work as well as fully integrating plant recommendations upon creation.)
  def new
    @plant_module = PlantModule.new(location_type: "indoor")

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

  def create
    @plant_module = PlantModule.new(plant_module_params)
    @plant_module.user = current_user
    @plant_module.id = SecureRandom.uuid  # Optional if you add a similar before_create in PlantModule

    if @plant_module.save
      CareSchedule.create!(
        plant_module_id: @plant_module.id,
        watering_frequency: 7,
        fertilizer_frequency: 30,
        light_hours: 8,
        soil_moisture_pref: "medium"
      )

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
      @sensor_data[sensor.id] = sensor.time_series_data.group("DATE(timestamp)").pluck(Arel.sql("DATE(timestamp), SUM(value)"))
    end
  end

  def index
    @plant_modules = current_user.plant_modules
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
    params.require(:plant_module).permit(:name, :description, :location, :location_type, :zip_code, plant_ids: [])
  end
end
