class ExercisesController < ApplicationController
  before_action :set_exercise, only: %i[edit update show destroy]
  before_action :skip_authorization, only: :index
  def index
    if params[:status].blank? && params[:difficulty].blank?
      @exercises = policy_scope(Exercise).includes(:musics)
    else
      handle_queries
      policy_scope(Exercise)
    end
    @daily_stat = Music.daily_completion_stat(current_user)
    @weekly_stat = Music.weekly_completion_stat(current_user)
    @exercise_pie = Exercise.user_exercise_pie(current_user)
    # raise
  end

  def new
    @exercise = current_user.exercises.new
    @exercise.musics.build
    authorize @exercise
  end

  def create
    @exercise = current_user.exercises.new(exercise_params)
    authorize @exercise

    if @exercise.save
      redirect_to exercises_path
    else
      render :new
    end
  end

  def edit; end

  def show
    authorize @exercise
    @question_music = @exercise.question_music
    @attempt_music =
      current_user.musics.find_or_initialize_by(
        exercise: @exercise,
        is_question: false
      )
    @review =
      Review.find_or_initialize_by(user: current_user, exercise: @exercise)
    @action =
      if @attempt_music.id
        { path: music_path(@attempt_music), method: :patch }
      else
        { path: exercise_musics_path(@exercise), method: :post }
      end
  end

  def update
    @exercise.update(exercise_params)

    if @exercise.save
      redirect_to exercises_path
    else
      render :edit
    end
  end

  def destroy
    @exercise.destroy
    redirect_to exercises_path
  end

  private

  def handle_queries
    @query = true

    if !params[:status].blank? && !params[:difficulty].blank?
      @results = current_user.musics
                             .user_exercises_with_attempt_search(params[:status].to_i)
                             .select { |k, v| k.select_by_difficulty(params[:difficulty].to_i) }
    elsif !params[:status].blank? && params[:difficulty].blank?
      @results = current_user.musics.user_exercises_with_attempt_search(params[:status].to_i)
    else
      @exercises = policy_scope(Exercise).includes(:musics).search_by_difficulty(params[:difficulty].to_i)
    end
  end

  def exercise_params
    params
      .require(:exercise)
      .permit(:name, :description, :chord_progression, :user_id, :difficulty, musics_attributes: %i[bpm key_signature
                                                                                                    mode notes chords])
  end

  def set_exercise
    @exercise = Exercise.find(params[:id])
    authorize @exercise
  end
end
