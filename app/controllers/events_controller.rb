class EventsController < ApplicationController
  before_action :set_event, only: [:show, :edit, :update, :destroy, :join, :accept_request, :reject_request]
  before_action :authenticate_user!, except: [:index]
  before_action :event_owner!, only: [:edit, :update, :destroy]
  respond_to :html

  # GET /events
  # GET /events.json
  def index
    if params[:tag] 
      @events = Event.tagged_with(params[:tag])
    else
      @events = Event.all
    end
  end

  # GET /events/1
  # GET /events/1.json
  def show
    @event_owner = User.find(@event.organizer_id)
    @pending_requests = Event.pending_requests(@event)
  end

  # GET /events/new
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit
  end

  # POST /events
  # POST /events.json
  def create
    @event = current_user.organized_events.new(event_params)

    respond_to do |format|
      if @event.save
        format.html { redirect_to @event, notice: 'Event was successfully created.' }
        format.json { render :show, status: :created, location: @event }
      else
        format.html { render :new }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /events/1
  # PATCH/PUT /events/1.json
  def update
    respond_to do |format|
      if @event.update(event_params)
        format.html { redirect_to @event, notice: 'Event was successfully updated.' }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1
  # DELETE /events/1.json
  def destroy
    @event.destroy
    respond_to do |format|
      format.html { redirect_to events_url, notice: 'Event was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def join
    if current_user.id == @event.organizer_id
      flash[:notice] = 'You can\'t join your own event!'
      redirect_to @event
    elsif current_user.attendances.find_by(:event_id => @event.id)
      flash[:notice] = 'You have already sent a request'
      redirect_to @event
    else
      @attendance = Attendance.join_event(current_user.id, @event.id, 'request_sent')
      flash[:notice] = 'Request sent' if @attendance.save
      respond_with @attendance
    end
  end

  def accept_request
    @attendance = Attendance.find(params[:attendance_id]) rescue nil
    @attendance.accept!
    flash[:notice] = 'Applicant accepted' if @attendance.save
    redirect_to @event
  end

  def reject_request
    @attendance = Attendance.find(params[:attendance_id]) rescue nil
    @attendance.reject!
    flash[:notice] = 'Applicant rejected' if @attendance.save
    redirect_to @event
  end

  def my_events
    @events = current_user.organized_events
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.friendly.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def event_params
      params.require(:event).permit(:title, :start_date, :end_date, :location, :agenda, :address, :organizer_id, :all_tags)
    end

    def event_owner!
      authenticate_user!
      if current_user.id != @event.organizer_id
        redirect_to events_path
        flash[:notice] = 'Unauthorized Access'
      end
    end

    
end
