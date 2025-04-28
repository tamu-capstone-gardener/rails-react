# Controller for managing control signals for plant modules
#
# This controller handles modification and triggering of control signals
# such as lights, water pumps, and fans for plant modules.
#
# @example Request to edit a control signal
#   GET /plant_modules/123/control_signals/456/edit
#
# @example Request to trigger a control signal
#   POST /control_signals/456/trigger
class ControlSignalsController < AuthenticatedApplicationController
    include ControlSignalsHelper
    before_action :set_plant_module
    before_action :set_control_signal, only: [ :edit, :update ]

    # Displays the form to edit a control signal
    #
    # @param plant_module_id [String] ID of the plant module
    # @param id [String] ID of the control signal to edit
    # @return [void]
    def edit
      @length_unit = @control_signal.length_unit
      @length = @control_signal.length
    end

    # Updates a control signal
    #
    # @param plant_module_id [String] ID of the plant module
    # @param id [String] ID of the control signal to update
    # @param control_signal [Hash] control signal parameters
    # @return [void]
    def update
      # # Combine value and unit to compute length
      # length_unit  = params[:length_unit]

      # # Inject computed length into control_signal params
      # params[:control_signal][:length] = length


      if @control_signal.update(control_signal_params)
        redirect_to plant_module_path(@plant_module), success: "Control signal updated."
      else
        flash.now[:alert] = "Update failed."
        render :edit
      end
    end

    # Triggers a control signal to turn on or off
    #
    # @param id [String] ID of the control signal to trigger
    # @param toggle [String] "true" to toggle state, otherwise maintains current state
    # @return [void]
    def trigger
      control_signal = ControlSignal.find(params[:id])
      last_exec = ControlExecution.where(control_signal_id: control_signal.id)
                                  .order(executed_at: :desc)
                                  .first


      if last_exec.nil?
        flash.now[:alert] = "No previous execution found for this control signal."
        render turbo_stream: turbo_stream.update("flash", partial: "shared/flash"), status: :unprocessable_entity
        return
      end
      MqttListener.publish_control_command(control_signal, toggle: params[:toggle] == "true", mode: "manual", duration: control_signal.length, status: !last_exec.status)

      if !last_exec.status
        flash.now[:success] = "Turned #{control_signal.label || control_signal.signal_type} On for #{format_duration(control_signal.length, control_signal.length_unit)}"
      else
        flash.now[:alert] = "Turned #{control_signal.label || control_signal.signal_type} Off"
      end
      render turbo_stream: [
        turbo_stream.update("flash", partial: "shared/flash"),
        turbo_stream.update("control_execution", partial: "control_executions/control_execution", locals: { control_execution: control_signal.control_executions.order(executed_at: :desc).first }),
        turbo_stream.update("control_toggle_button_#{control_signal.id}", partial: "control_signals/control_toggle_button", locals: { signal: control_signal })
      ]

    rescue => e
      Rails.logger.error "Trigger error: #{e.message}"
      flash.now[:alert] = "Trigger failed: #{e.message}"
      render turbo_stream: turbo_stream.update("flash", partial: "shared/flash"), status: :unprocessable_entity
    end

    private

    # Sets the plant module for the current request
    #
    # @return [void]
    def set_plant_module
      @plant_module = PlantModule.find(params[:plant_module_id])
    end

    # Sets the control signal for the current request
    #
    # @return [void]
    def set_control_signal
      @control_signal = @plant_module.control_signals.find(params[:id])
    end

    # Permits control signal parameters for mass assignment
    #
    # @return [ActionController::Parameters] permitted parameters
    def control_signal_params
      params.require(:control_signal).permit(
      :label, :signal_type, :delay, :length, :length_unit,
      :mode, :sensor_id, :comparison, :threshold_value,
      :frequency, :unit, :enabled, :scheduled_time
    )
    end
end
