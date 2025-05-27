# frozen_string_literal: true

require "test_helper"
# Explicitly require the migration file
require Rails.root.join("db/migrate/20250519010827_migrate_data_to_push_model.rb")

class MigrateDataToPushModelTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile
  # This is a migration test, so we need to use fixtures
  # to ensure we have consistent data for our tests
  fixtures :all

  setup do
    # Create a migration instance for testing
    @migration = MigrateDataToPushModel.new

    # Make private methods accessible for testing
    @migration.class.send(:public, :migrate_passwords)
    @migration.class.send(:public, :migrate_file_pushes)
    @migration.class.send(:public, :migrate_urls)
    @migration.class.send(:public, :migrate_views)
    @migration.class.send(:public, :determine_audit_log_kind)

    View.delete_all
    Password.delete_all
    FilePush.delete_all
    Url.delete_all

    # Suppress puts output during tests
    suppress_output
  end

  teardown do
    # Restore normal output after each test
    restore_output
  end

  # Method to suppress standard output
  def suppress_output
    # Save the original stdout and stderr
    @original_stdout = $stdout
    @original_stderr = $stderr

    # Redirect stdout and stderr to /dev/null
    $stdout = File.open(File::NULL, "w")
    $stderr = File.open(File::NULL, "w")
  end

  # Method to restore standard output
  def restore_output
    # Restore the original stdout and stderr
    $stdout = @original_stdout if @original_stdout
    $stderr = @original_stderr if @original_stderr
  end

  test "migrate_passwords creates push records correctly" do
    # Create test data in a separate transaction that will be rolled back
    password = nil
    ActiveRecord::Base.transaction do
      password = Password.create!(
        payload: "test_password_payload",
        name: "Test Password",
        expire_after_days: 27,
        expire_after_views: 32,
        deletable_by_viewer: true,
        retrieval_step: false,
        url_token: "password123"
      )

      # Count pushes before migration
      pushes_before = Push.count

      # Run the migration
      @migration.migrate_passwords

      # Verify at least one new push was created
      assert Push.count > pushes_before, "No new pushes were created"

      # Find the push that was created from the password
      push = Push.find_by(url_token: password.url_token)

      # Assert the push was created
      assert_not_nil push

      # Assert the push has the correct attributes
      assert_equal "text", push.kind
      assert_equal password.expire_after_days, push.expire_after_days
      assert_equal password.expire_after_views, push.expire_after_views
      assert_equal password.expired, push.expired
      assert_equal password.url_token, push.url_token
      assert_equal password.deletable_by_viewer, push.deletable_by_viewer
      assert_equal password.retrieval_step, push.retrieval_step
      assert_equal password.payload, push.payload
      assert_equal password.name, push.name
      assert_nil push.expired_on
      assert_nil password.note, push.note
      assert_nil password.passphrase, push.passphrase

      # Check that an audit log was created
      audit_log = push.audit_logs.find_by(kind: "creation")
      assert_not_nil audit_log

      # Always rollback to keep test isolated
      raise ActiveRecord::Rollback
    end
  end

  test "migrate_file_pushes creates push records correctly" do
    # Create test data in a separate transaction that will be rolled back
    file_push = nil
    ActiveRecord::Base.transaction do
      # Create a test user first
      test_user = User.create!(
        email: "test@example.com",
        password: "password123"
      )

      file_push = FilePush.create!(
        name: "Test File Push",
        expire_after_days: 14,
        expire_after_views: 10,
        deletable_by_viewer: true,
        retrieval_step: true,
        url_token: "filepush123",
        user: test_user
      )

      # Attach a test file to the file_push
      file = fixture_file_upload("monkey.png", "image/png")
      file_push.files.attach(file)

      # Count pushes before migration
      pushes_before = Push.count

      # Run the migration
      @migration.migrate_file_pushes

      # Verify at least one new push was created
      assert Push.count > pushes_before, "No new pushes were created"

      # Find the push that was created from the file_push
      push = Push.find_by(url_token: file_push.url_token)

      # Assert the push was created
      assert_not_nil push

      # Assert the push has the correct attributes
      assert_equal "file", push.kind
      assert_equal file_push.expire_after_days, push.expire_after_days
      assert_equal file_push.expire_after_views, push.expire_after_views
      assert_equal file_push.expired, push.expired
      assert_equal file_push.url_token, push.url_token
      assert_equal file_push.deletable_by_viewer, push.deletable_by_viewer
      assert_equal file_push.retrieval_step, push.retrieval_step
      assert_equal file_push.name, push.name
      assert_nil push.expired_on
      assert_nil push.payload
      assert_nil push.note
      assert_nil push.passphrase

      # Check that an audit log was created
      audit_log = push.audit_logs.find_by(kind: "creation")
      assert_not_nil audit_log

      # Check that files were attached
      assert push.files.attached?
      assert_equal file_push.files.count, push.files.count

      # Always rollback to keep test isolated
      raise ActiveRecord::Rollback
    end
  end

  test "migrate_urls creates push records correctly" do
    # Create test data in a separate transaction that will be rolled back
    url = nil
    ActiveRecord::Base.transaction do
      url = Url.create!(
        payload: "https://example.com",
        name: "Test URL",
        expire_after_days: 30,
        expire_after_views: 15,
        url_token: "url123"
      )

      # Count pushes before migration
      pushes_before = Push.count

      # Run the migration
      @migration.migrate_urls

      # Verify at least one new push was created
      assert Push.count > pushes_before, "No new pushes were created"

      # Find the push that was created from the url
      push = Push.find_by(url_token: url.url_token)

      # Assert the push was created
      assert_not_nil push

      # Assert the push has the correct attributes
      assert_equal "url", push.kind
      assert_equal url.expire_after_days, push.expire_after_days
      assert_equal url.expire_after_views, push.expire_after_views
      assert_equal url.expired, push.expired
      assert_equal url.url_token, push.url_token
      assert_equal url.retrieval_step, push.retrieval_step
      assert_equal url.payload, push.payload
      assert_equal url.name, push.name
      assert_nil push.deletable_by_viewer # URLs cannot be deleted by viewers
      assert_nil push.expired_on
      assert_nil push.note
      assert_nil push.passphrase

      # Check that an audit log was created
      audit_log = push.audit_logs.find_by(kind: "creation")
      assert_not_nil audit_log

      # Always rollback to keep test isolated
      raise ActiveRecord::Rollback
    end
  end

  test "migrate_views creates audit logs correctly" do
    # Create test data in a separate transaction that will be rolled back
    password = nil
    view = nil
    ActiveRecord::Base.transaction do
      # Create a password
      password = Password.create!(
        payload: "test_password_payload",
        name: "Test Password",
        expire_after_days: 17,
        expire_after_views: 15,
        deletable_by_viewer: true,
        retrieval_step: false,
        url_token: "password123"
      )

      # Create a view for testing view migration
      view = View.create!(
        password: password,
        created_at: 1.day.ago,
        ip: "127.0.0.1",
        user_agent: "Test Agent",
        referrer: "https://test.com",
        successful: true,
        kind: 0
      )

      # Count audit logs before migration
      audit_logs_before = AuditLog.count

      # First run the password migration to create the push
      @migration.migrate_passwords

      # Find the push that was created from the password
      push = Push.find_by(url_token: password.url_token)
      assert_not_nil push

      # Run the view migration to create the audit logs
      @migration.migrate_views

      # Verify at least one new audit log was created
      assert AuditLog.count == audit_logs_before + 2, "No new audit logs were created"

      # Check that a view audit log was created for the push
      audit_log = push.audit_logs.where.not(kind: "creation").first
      assert_not_nil audit_log
      assert_equal audit_log.push.class.name, Push.name

      # Check that the audit log has the correct attributes
      # Compare timestamps with a small tolerance for database precision differences
      assert_in_delta view.created_at.to_i, audit_log.created_at.to_i, 1
      assert_equal view.ip, audit_log.ip
      assert_equal view.user_agent, audit_log.user_agent
      assert_equal view.referrer, audit_log.referrer

      # Always rollback to keep test isolated
      raise ActiveRecord::Rollback
    end
  end

  test "full migration process works correctly" do
    # Create test data in a separate transaction that will be rolled back
    ActiveRecord::Base.transaction do
      # Create a password
      password = Password.create!(
        payload: "test_password_payload",
        name: "Test Password",
        expire_after_days: 27,
        expire_after_views: 32,
        deletable_by_viewer: true,
        retrieval_step: false,
        url_token: "password123"
      )

      # Create a test user first
      test_user = User.create!(
        email: "test2@example.com",
        password: "password123"
      )

      # Create a file push
      file_push = FilePush.create!(
        name: "Test File Push",
        expire_after_days: 14,
        expire_after_views: 10,
        deletable_by_viewer: true,
        retrieval_step: true,
        url_token: "filepush123",
        user: test_user
      )

      # Attach a test file to the file_push
      file = fixture_file_upload("monkey.png", "image/png")
      file_push.files.attach(file)

      # Create a URL
      url = Url.create!(
        payload: "https://example.com",
        name: "Test URL",
        expire_after_days: 30,
        expire_after_views: 15,
        url_token: "url123"
      )

      # Create a view
      View.create!(
        password: password,
        created_at: 1.day.ago,
        ip: "127.0.0.1",
        user_agent: "Test Agent",
        referrer: "https://test.com",
        successful: true,
        kind: 0
      )

      # Count records before migration
      pushes_before = Push.count
      audit_logs_before = AuditLog.count

      # Run the full migration
      @migration.up

      # Verify new pushes were created
      assert Push.count > pushes_before, "No new pushes were created"

      # Verify new audit logs were created
      assert AuditLog.count > audit_logs_before, "No new audit logs were created"

      # Verify each original record was migrated
      password_push = Push.find_by(url_token: password.url_token)
      assert_not_nil password_push
      assert_equal "text", password_push.kind

      file_push_record = Push.find_by(url_token: file_push.url_token)
      assert_not_nil file_push_record
      assert_equal "file", file_push_record.kind
      assert file_push_record.files.attached?

      url_push = Push.find_by(url_token: url.url_token)
      assert_not_nil url_push
      assert_equal "url", url_push.kind

      # Always rollback to keep test isolated
      raise ActiveRecord::Rollback
    end
  end

  test "expired old records are migrated correctly" do
    ActiveRecord::Base.transaction do
      # Create a test user first
      test_user = User.create!(
        email: "test2@example.com",
        password: "password123"
      )

      password = Password.create!(
        payload: "test_password_payload",
        name: "Test Password",
        expire_after_days: 27,
        expire_after_views: 32,
        deletable_by_viewer: true,
        retrieval_step: false,
        url_token: "password123",
        expired: true
      )

      Url.create!(
        payload: "https://example.com",
        name: "Test URL",
        expire_after_days: 30,
        expire_after_views: 15,
        url_token: "url123",
        user: test_user,
        expired: true
      )

      file_push = FilePush.create!(
        name: "Test File Push",
        expire_after_days: 14,
        expire_after_views: 10,
        deletable_by_viewer: true,
        retrieval_step: true,
        url_token: "filepush123",
        user: test_user,
        expired: true
      )

      # Attach a test file to the file_push
      file = fixture_file_upload("monkey.png", "image/png")
      file_push.files.attach(file)

      View.create!(
        password: password,
        created_at: 1.day.ago,
        ip: "127.0.0.1",
        user_agent: "Test Agent",
        referrer: "https://test.com",
        successful: true,
        kind: 0
      )

      # Count pushes before migration
      pushes_count_before = Push.count

      # Run the migration
      @migration.up

      # Verify at least one new push was created
      assert Push.count == pushes_count_before + 3, "Pushes are not created correctly"
      assert_equal AuditLog.where(kind: :view).count, 1, "View audit logs are not created correctly"
      assert_equal AuditLog.where(kind: :creation).count, 3, "Creation audit logs are not created correctly"

      new_file_push = Push.where(kind: "file").last
      assert new_file_push.files.attached?
      assert_equal 1, new_file_push.files.count, "File was not attached to push"

      # Always rollback to keep test isolated
      raise ActiveRecord::Rollback
    end
  end

  test "down method works correctly" do
    # Create test data in a separate transaction that will be rolled back
    ActiveRecord::Base.transaction do
      # Create a test user
      test_user = User.create!(
        email: "test3@example.com",
        password: "password123"
      )

      # Create a file push record first
      file_push = FilePush.create!(
        name: "Test File Push",
        expire_after_days: 14,
        expire_after_views: 10,
        deletable_by_viewer: true,
        retrieval_step: true,
        url_token: "filepush123",
        user: test_user
      )

      # Attach a test file to the file_push
      file = fixture_file_upload("monkey.png", "image/png")
      file_push.files.attach(file)

      # Create a view
      View.create!(
        file_push: file_push,
        created_at: 1.day.ago,
        ip: "127.0.0.1",
        user_agent: "Test Agent",
        referrer: "https://test.com",
        successful: true,
        kind: 0
      )

      # Run the migration up to create pushes and audit logs
      @migration.class.send(:public, :migrate_file_pushes)
      @migration.migrate_file_pushes

      # Verify pushes and audit logs were created
      push = Push.find_by(url_token: file_push.url_token)
      assert_not_nil push
      assert push.files.attached?
      assert_equal 1, push.files.count, "File was not attached to push"
      assert_not push.audit_logs.empty?

      # Run the migration down
      @migration.down

      # Verify pushes were deleted
      assert_equal 0, Push.count, "Pushes were not deleted"

      # Verify audit logs were deleted
      assert_equal 0, AuditLog.count, "Audit logs were not deleted"

      # Verify files were reattached to the original file_push
      file_push.reload
      assert file_push.files.attached?, "Files were not reattached to the original file_push"
      assert_equal 1, file_push.files.count, "File count doesn't match after reattachment"

      # Always rollback to keep test isolated
      raise ActiveRecord::Rollback
    end
  end
end
