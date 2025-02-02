class MusicsController < ApplicationController
  def create
    @music = Music.new(music_params)
    @music.exercise = Exercise.find(params[:exercise_id])
    @music.user = current_user
    @music.save
    check_music unless @music.is_question
    authorize @music
    redirect_to exercise_path(@music.exercise)
  end

  def update
    @music = Music.find(params[:id])
    @music.update(music_params)
    check_music unless @music.is_question
    authorize @music
    redirect_to exercise_path(@music.exercise)
  end

  private

  def check_music
    if @music.notes == @music.exercise.question_music.notes
      flash[:success] = true
      flash[:notice] = 'Great job!'
      @music.finished!
    else
      flash[:alert] = 'It was incorrect! Try again!'
    end
  end

  def music_params
    params
      .require(:music)
      .permit(
        :bpm,
        :key_signature,
        :mode,
        :notes,
        :chords,
        :note_values,
        :chord_values,
        :status
      )
  end
end
