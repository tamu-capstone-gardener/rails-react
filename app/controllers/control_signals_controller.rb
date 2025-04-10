class ControlSignalsController < AuthenticatedApplicationController
    before_action :set_plant_module
    before_action :set_control_signal, only: [ :edit, :update ]

    def edit
      ms = @control_signal.length_ms

      if ms.nil? || ms.zero?
        @length_value = nil
        @length_unit = "seconds"
      else
        if ms % 86_400_000 == 0
          @length_value = ms / 86_400_000
          @length_unit = "days"
        elsif ms % 3_600_000 == 0
          @length_value = ms / 3_600_000
          @length_unit = "hours"
        elsif ms % 60_000 == 0
          @length_value = ms / 60_000
          @length_unit = "minutes"
        elsif ms % 1_000 == 0
          @length_value = ms / 1_000
          @length_unit = "seconds"
        else
          @length_value = ms
          @length_unit = "milliseconds"
        end
      end
    end


    def update
      # Combine value and unit to compute length_ms
      length_value = params[:length_value].to_i
      length_unit  = params[:length_unit]

      length_ms = case length_unit
      when "days" then length_value * 86_400_000
      when "hours" then length_value * 3_600_000
      when "minutes" then length_value * 60_000
      when "seconds" then length_value * 1_000
      else length_value
      end

      # Inject computed length_ms into control_signal params
      params[:control_signal][:length_ms] = length_ms

      if @control_signal.update(control_signal_params)
        redirect_to plant_module_path(@plant_module), notice: "Control signal updated."
      else
        flash.now[:alert] = "Update failed."
        render :edit
      end
    end


    def trigger
      control_signal = ControlSignal.find(params[:id])

      MqttListener.publish_control_command(control_signal, toggle: params[:toggle] == "true", mode: "manual")

      sleep(1)

      last_exec = ControlExecution.where(control_signal_id: control_signal.id, source: "manual")
      .order(executed_at: :desc)
      .first


      if Time.now - last_exec.executed_at < 120
        flash[:success] = "Trigger succeeded"
      else
        flash[:alert] = "Trigger failed"
      end

      redirect_to plant_module_path(@plant_module)
    rescue => e
      Rails.logger.error "Trigger error: #{e.message}"
      render json: { error: "Trigger failed: #{e.message}" }, status: :unprocessable_entity
    end




    private

    def set_plant_module
      @plant_module = PlantModule.find(params[:plant_module_id])
    end

    def set_control_signal
      @control_signal = @plant_module.control_signals.find(params[:id])
    end

    def control_signal_params
      params.require(:control_signal).permit(
      :label, :signal_type, :delay, :length_ms,
      :mode, :sensor_id, :comparison, :threshold_value,
      :frequency, :unit, :enabled, :scheduled_time
    )
    end
end
