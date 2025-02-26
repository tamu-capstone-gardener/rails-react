class PlantModulesController < AuthenticatedApplicationController
  def show
    @plant_module = PlantModule.find(params[:id])

    if @plant_module.nil?
      redirect_to plant_modules_path, alert: "Plant module not found."
    elsif @plant_module.user != current_user
      redirect_to plant_modules_path, alert: "You are not authorized to access this plant module."
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
end
