# frozen_string_literal: true

require "addressable/uri"

class Push < ApplicationRecord
  enum :kind, [:text, :file, :url, :qr], validate: true

  validate :check_enabled_push_kinds
  validates :url_token, presence: true, uniqueness: true

  with_options on: :create do |create|
    create.before_validation :set_expire_limits
    create.before_validation :set_url_token
    create.before_validation :set_default_attributes

    create.after_validation :check_payload_for_text, if: :text?
    create.after_validation :check_files_for_file, if: :file?
    create.after_validation :check_payload_for_url, if: :url?
    create.after_validation :check_payload_for_qr, if: :qr?
  end

  belongs_to :user, optional: true

  has_encrypted :payload, :note, :passphrase

  has_many :audit_logs, -> { order(created_at: :asc) }, dependent: :destroy
  has_many_attached :files, dependent: :destroy

  def to_param
    url_token.to_s
  end

  def days_old
    (Time.zone.now.to_datetime - created_at.to_datetime).to_i
  end

  def days_remaining
    [(expire_after_days - days_old), 0].max
  end

  def views_remaining
    [(expire_after_views - view_count), 0].max
  end

  def view_count
    audit_logs.where(kind: %i[view failed_view]).size
  end

  def successful_views
    audit_logs.where(kind: :view).order(:created_at)
  end

  def failed_views
    audit_logs.where(kind: :failed_view).order(:created_at)
  end

  # Expire this push, delete the content and save the record
  def expire
    # Delete content
    self.payload = nil
    self.passphrase = nil
    files.purge

    # Mark as expired
    self.expired = true
    self.expired_on = Time.current.utc
    save
  end

  # Override to_json so that we can add in <days_remaining>, <views_remaining>
  # and show the clear push
  def to_json(*args)
    # def to_json(owner: false, payload: false)
    attr_hash = attributes

    owner = false
    payload = false

    owner = args.first[:owner] if args.first.key?(:owner)
    payload = args.first[:payload] if args.first.key?(:payload)

    attr_hash["days_remaining"] = days_remaining
    attr_hash["views_remaining"] = views_remaining
    attr_hash["deleted"] = audit_logs.any?(&:expire?)

    if file?
      file_list = {}
      files.each do |file|
        # FIXME: default host?
        file_list[file.filename] = Rails.application.routes.url_helpers.rails_blob_url(file, only_path: true)
      end
      attr_hash["files"] = file_list.to_json
    end

    # Remove unnecessary fields
    attr_hash.delete("kind")
    attr_hash.delete("payload_ciphertext")
    attr_hash.delete("note_ciphertext")
    attr_hash.delete("passphrase_ciphertext")
    attr_hash.delete("user_id")
    attr_hash.delete("id")

    attr_hash.delete("passphrase")
    attr_hash.delete("name") unless owner
    attr_hash.delete("note") unless owner
    attr_hash.delete("payload") unless payload
    attr_hash.delete("deletable_by_viewer") if url?

    Oj.dump attr_hash
  end

  def check_files_for_file
    if files.attached? && files.reject { |file| file.is_a?(String) && file.empty? }.size > settings_for_kind.max_file_uploads
      errors.add(:files, I18n.t("pushes.too_many_files", count: settings_for_kind.max_file_uploads))
    end
  end

  def check_payload_for_text
    if payload.blank?
      errors.add(:payload, I18n.t("pushes.create.payload_required"))
      return
    end

    unless payload.is_a?(String) && payload.length.between?(1, 1.megabyte)
      errors.add(:payload, I18n.t("pushes.payload_too_large"))
    end
  end

  def check_payload_for_url
    if payload.present?
      if !valid_url?(payload)
        errors.add(:payload, I18n.t("pushes.create.invalid_url"))
      end
    else
      errors.add(:payload, I18n.t("pushes.create.payload_required"))
    end
  end

  def check_payload_for_qr
    if payload.present?
      # If the push is a QR code, max payload length is 1024 characters
      if payload.length > 1024
        errors.add(:payload, t("pushes.create.qr_max_length", count: 1024))
      end
    else
      errors.add(:payload, I18n.t("pushes.create.payload_required"))
    end
  end

  def set_expire_limits
    self.expire_after_days ||= settings_for_kind.expire_after_days_default
    self.expire_after_views ||= settings_for_kind.expire_after_views_default

    # MIGRATE - ask
    # Are these assignments needed?
    unless self.expire_after_days.between?(settings_for_kind.expire_after_days_min, settings_for_kind.expire_after_days_max)
      self.expire_after_days = settings_for_kind.expire_after_days_default
    end

    unless self.expire_after_views.between?(settings_for_kind.expire_after_views_min, settings_for_kind.expire_after_views_max)
      self.expire_after_views = settings_for_kind.expire_after_views_default
    end
  end

  def check_limits
    expire if !expired? && (!days_remaining.positive? || !views_remaining.positive?)
  end

  def set_url_token
    self.url_token = SecureRandom.urlsafe_base64(rand(8..14)).downcase
  end

  def expire!
    # Delete content
    self.payload = nil
    self.passphrase = nil
    files.purge

    # Mark as expired
    self.expired = true
    self.expired_on = Time.current.utc
    save!
  end

  def settings_for_kind
    if text?
      Settings.pw
    elsif url?
      Settings.url
    elsif file?
      Settings.files
    elsif qr?
      Settings.qr
    end
  end

  def check_enabled_push_kinds
    if kind == "file" && !(Settings.enable_logins && Settings.enable_file_pushes)
      errors.add(:kind, I18n.t("pushes.file_pushes_disabled"))
    end

    if kind == "url" && !(Settings.enable_logins && Settings.enable_url_pushes)
      errors.add(:kind, I18n.t("pushes.url_pushes_disabled"))
    end

    if kind == "qr" && !(Settings.enable_logins && Settings.enable_qr_pushes)
      errors.add(:kind, I18n.t("pushes.qr_pushes_disabled"))
    end
  end

  def set_default_attributes
    self.note ||= ""
    self.passphrase ||= ""
    self.name ||= ""
  end

  def valid_url?(url)
    !Addressable::URI.parse(url).scheme.nil?
  rescue Addressable::URI::InvalidURIError
    false
  end

  def deleted
    audit_logs.where(kind: AuditLog.kinds[:expire]).exists?
  end
end
