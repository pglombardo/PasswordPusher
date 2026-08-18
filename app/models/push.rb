# frozen_string_literal: true

require "addressable/uri"

class Push < ApplicationRecord
  include Pwpush::NotifiableByEmail

  # Result of an atomic retrieval claim (see #claim_view!).
  # +expire_after_response+ is true when the caller should expire the push after
  # rendering (preserves legacy last-view JSON where expired is still false).
  ViewClaim = Data.define(:status, :payload, :kind, :expire_after_response) do
    def ok? = status == :ok

    def expired? = status == :expired
  end

  enum :kind, [:text, :file, :url, :qr], validate: true

  validate :check_enabled_push_kinds, on: :create
  validates :url_token, presence: true, uniqueness: true

  validate :check_payload_for_text, if: :text?
  validate :check_files_for_file, if: :file?
  validate :check_payload_for_url, if: :url?
  validate :check_payload_for_qr, if: :qr?

  with_options on: :create do |create|
    create.before_validation :set_expire_limits
    create.before_validation :set_url_token
    create.before_validation :set_default_attributes
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

  # Expire this push, delete the content and save the record.
  # Active Storage purge runs after the DB save so callers holding a row lock
  # can use #expire_record! and purge outside the lock instead.
  def expire
    expire_record
    save
    files.purge
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
    if files.attached? && files.count { |file| !(file.is_a?(String) && file.empty?) } > settings_for_kind.max_file_uploads
      errors.add(:files, I18n._("You can only attach up to %{count} files per push.") % {count: settings_for_kind.max_file_uploads})
    end
  end

  def check_payload_for_text
    # Allow nil payload when expired
    return if expired?

    if payload.blank?
      errors.add(:payload, I18n._("Payload is required."))
      return
    end

    unless payload.is_a?(String) && payload.length.between?(1, 1.megabyte)
      errors.add(:payload, I18n._("The payload is too large.  You can only push up to %{count} bytes.") % {count: 1.megabyte})
    end
  end

  def check_payload_for_url
    # Allow nil payload when expired
    return if expired?

    if payload.present?
      if !valid_url?(payload)
        errors.add(:payload, I18n._("must be a valid HTTP or HTTPS URL."))
      end
    else
      errors.add(:payload, I18n._("Payload is required."))
    end
  end

  def check_payload_for_qr
    # Allow nil payload when expired
    return if expired?

    if payload.present?
      # If the push is a QR code, max payload length is 1024 characters
      if payload.length > 1024
        errors.add(:payload, I18n._("The QR code payload is too large.  You can only push up to %{count} bytes.") % {count: 1024})
      end
    else
      errors.add(:payload, I18n._("Payload is required."))
    end
  end

  def set_expire_limits
    self.expire_after_days ||= settings_for_kind.expire_after_days_default
    self.expire_after_views ||= settings_for_kind.expire_after_views_default

    # MIGRATE - ask
    # Are these assignments needed?
    unless expire_after_days.between?(settings_for_kind.expire_after_days_min, settings_for_kind.expire_after_days_max)
      self.expire_after_days = settings_for_kind.expire_after_days_default
    end

    unless expire_after_views.between?(settings_for_kind.expire_after_views_min, settings_for_kind.expire_after_views_max)
      self.expire_after_views = settings_for_kind.expire_after_views_default
    end
  end

  def check_limits
    expire if !expired? && (!days_remaining.positive? || !views_remaining.positive?)
  end

  def set_url_token
    self.url_token = SecureRandom.urlsafe_base64(rand(8..14)).downcase
  end

  # Clears secret fields and marks the push expired in memory (no save, no purge).
  def expire_record
    self.payload = nil
    self.passphrase = nil
    self.expired = true
    self.expired_on = Time.current.utc
  end

  # Persists #expire_record without purging attachments.
  def expire_record!
    expire_record
    save!
  end

  def expire!
    expire_record!
    files.purge
  end

  # Atomically check limits, log a view, and snapshot the payload. Serializes
  # concurrent retrievals so expire_after_views cannot be bypassed by racing
  # requests. When this counting view exhausts the limit for a non-file push,
  # returns +expire_after_response+ so the caller can expire after render
  # (legacy API shape: last successful view still reports expired=false).
  #
  # +viewer+ is the signed-in user (or nil). +admin+ must be true for admin
  # non-counting views. Request metadata is stored on the audit log.
  def claim_view!(viewer: nil, admin: false, ip: nil, user_agent: nil, referrer: nil)
    should_purge_files = false
    result = nil

    with_lock do
      reload

      if !expired? && (!days_remaining.positive? || !views_remaining.positive?)
        expire_record!
        should_purge_files = true
      end

      if expired?
        # Best-effort audit; payload is already gone
        create_retrieval_audit_log!(kind: :failed_view, viewer:, ip:, user_agent:, referrer:)
        result = ViewClaim.new(status: :expired, payload: nil, kind: :failed_view, expire_after_response: false)
      else
        kind = if admin
          :admin_view
        elsif owned_by?(viewer)
          :owner_view
        else
          :view
        end

        logged = create_retrieval_audit_log!(kind:, viewer:, ip:, user_agent:, referrer:)

        # Counting views must be persisted or expire_after_views can be bypassed
        # once the per-push audit log cap is hit. Fail closed: clear the secret.
        if kind == :view && !logged
          expire_record!
          should_purge_files = true
          result = ViewClaim.new(status: :expired, payload: nil, kind: :view, expire_after_response: false)
        else
          audit_logs.reset if logged

          # File pushes defer expire so the viewer can still download attachments.
          expire_after_response = kind == :view && !views_remaining.positive? && !files.attached?

          result = ViewClaim.new(
            status: :ok,
            payload: payload,
            kind: kind,
            expire_after_response: expire_after_response
          )
        end
      end
    end

    files.purge if should_purge_files

    result
  end

  # True when +user+ is the authenticated owner of this push.
  # Require a real owner id on both sides so nil == nil (anonymous push /
  # non-persisted User.new) never counts as ownership.
  def owned_by?(user)
    user_id.present? && user.present? && user_id == user.id
  end

  # True when +user+ is the authenticated owner, or when viewer deletion is
  # explicitly enabled.
  def deletable_by?(user)
    owned_by?(user) || deletable_by_viewer == true
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
    if kind == "file" && !Settings.enable_file_pushes
      errors.add(:kind, I18n._("File pushes are disabled."))
    end

    if kind == "url" && !Settings.enable_url_pushes
      errors.add(:kind, I18n._("URL pushes are disabled."))
    end

    if kind == "qr" && !Settings.enable_qr_pushes
      errors.add(:kind, I18n._("QR code pushes are disabled."))
    end
  end

  def set_default_attributes
    self.note ||= ""
    self.passphrase ||= ""
    self.name ||= ""
  end

  def valid_url?(url)
    scheme = Addressable::URI.parse(url)&.scheme&.downcase
    %w[http https].include?(scheme)
  rescue Addressable::URI::InvalidURIError
    false
  end

  def deleted
    audit_logs.where(kind: AuditLog.kinds[:expire]).exists?
  end

  private

  # Returns true when an audit log row was persisted; false when skipped (cap)
  # or the insert did not persist.
  def create_retrieval_audit_log!(kind:, viewer:, ip:, user_agent:, referrer:)
    return false if retrieval_audit_log_limit_reached?

    audit_logs.create(
      kind: kind,
      user: viewer,
      ip: ip,
      user_agent: user_agent.to_s[0, 255],
      referrer: referrer.to_s[0, 255]
    ).persisted?
  end

  def retrieval_audit_log_limit_reached?
    audit_logs.reorder(nil).limit(1).offset(AuditLog::MAX_AUDIT_LOGS_PER_PUSH_OR_PULL - 1).exists?
  end

  def notify_by_email_custom_validations
    if expired?
      errors.add(:notify_emails_to, _("are not available for expired pushes")) if notify_emails_to.present?
      errors.add(:notify_emails_to_locale, _("is not available for expired pushes")) if notify_emails_to_locale.present?
    end
  end
end
