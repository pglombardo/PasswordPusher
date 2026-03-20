# frozen_string_literal: true

# Tracks in-flight TUS uploads per session so file push create/update can wait for completion.
# Uses upload IDs (not a simple counter) so abandoned or failed uploads can be released via
# DELETE /uploads/:id without leaving a stale positive count.
module TusActiveUploadSession
  extend ActiveSupport::Concern

  MAX_ACTIVE_TUS_SESSION_IDS = 64

  private

  def tus_upload_id_list
    session[:tus_active_upload_ids] ||= []
    session.delete(:tus_upload_count) if session.key?(:tus_upload_count)
    session[:tus_active_upload_ids]
  end

  def register_tus_upload_in_session!(id)
    list = tus_upload_id_list
    return if list.include?(id)
    return if list.size >= MAX_ACTIVE_TUS_SESSION_IDS

    list << id
    session[:tus_active_upload_ids] = list
  end

  def release_tus_upload_from_session!(id)
    list = tus_upload_id_list
    list.delete(id)
    session[:tus_active_upload_ids] = list
  end

  def tus_uploads_in_progress?
    tus_upload_id_list.any?
  end

  def reset_tus_upload_session!
    session.delete(:tus_upload_count)
    session[:tus_active_upload_ids] = []
  end

  def tus_upload_session_tracked?(id)
    tus_upload_id_list.include?(id)
  end
end
