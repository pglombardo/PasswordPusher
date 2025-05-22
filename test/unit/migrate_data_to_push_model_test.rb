# frozen_string_literal: true

require "test_helper"
# Explicitly require the migration file
require Rails.root.join("db/migrate/20250519010827_migrate_data_to_push_model.rb")

class MigrateDataToPushModelTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess
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
  end
  
  test "migrate_passwords creates push records correctly" do
    # Create test data in a separate transaction that will be rolled back
    password = nil
    ActiveRecord::Base.transaction do
      password = Password.create!(
        payload: "test_password_payload",
        name: "Test Password",
        expire_after_days: 7,
        expire_after_views: 5,
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
      assert_equal password.expired_on, push.expired_on
      assert_equal password.payload_ciphertext, push.payload_ciphertext
      assert_equal password.note_ciphertext, push.note_ciphertext
      assert_equal password.passphrase_ciphertext, push.passphrase_ciphertext
      assert_equal password.name, push.name
      
      # Check that an audit log was created
      audit_log = AuditLog.find_by(push_id: push.id, kind: "creation")
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
        email: 'test@example.com',
        password: 'password123'
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
      file = fixture_file_upload(Rails.root.join('test', 'fixtures', 'files', 'test-file.txt'), 'text/plain')
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
      assert_equal file_push.expired_on, push.expired_on
      assert_equal file_push.name, push.name
      
      # Check that an audit log was created
      audit_log = AuditLog.find_by(push_id: push.id, kind: "creation")
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
      assert_equal false, push.deletable_by_viewer # URLs cannot be deleted by viewers
      assert_equal url.retrieval_step, push.retrieval_step
      assert_equal url.expired_on, push.expired_on
      assert_equal url.payload_ciphertext, push.payload_ciphertext
      assert_equal url.note_ciphertext, push.note_ciphertext
      assert_equal url.passphrase_ciphertext, push.passphrase_ciphertext
      assert_equal url.name, push.name
      
      # Check that an audit log was created
      audit_log = AuditLog.find_by(push_id: push.id, kind: "creation")
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
        expire_after_days: 7,
        expire_after_views: 5,
        deletable_by_viewer: true,
        retrieval_step: false,
        url_token: "password123"
      )
      
      # Create a view for testing view migration
      view = View.create!(
        password_id: password.id,
        created_at: 1.day.ago,
        ip: "127.0.0.1",
        user_agent: "Test Agent",
        referrer: "https://test.com",
        successful: true,
        kind: 0
      )
      
      # First run the password migration to create the push
      @migration.migrate_passwords
      
      # Count audit logs before migration
      audit_logs_before = AuditLog.count
      
      # Run the views migration
      @migration.migrate_views
      
      # Find the push that was created from the password
      push = Push.find_by(url_token: password.url_token)
      assert_not_nil push
      
      # Verify at least one new audit log was created
      assert AuditLog.count > audit_logs_before, "No new audit logs were created"
      
      # Check that a view audit log was created for the push
      audit_log = AuditLog.where(push_id: push.id).where.not(kind: "creation").first
      assert_not_nil audit_log
      
      # Check that the audit log has the correct attributes
      # Use to_i to compare timestamps to avoid microsecond precision issues
      assert_equal view.created_at.to_i, audit_log.created_at.to_i
      assert_equal view.ip, audit_log.ip
      assert_equal view.user_agent, audit_log.user_agent
      assert_equal view.referrer, audit_log.referrer
      
      # Always rollback to keep test isolated
      raise ActiveRecord::Rollback
    end
  end
  
  test "migration uses find_each for batch processing" do
    # Create test data in a separate transaction that will be rolled back
    ActiveRecord::Base.transaction do
      # Create a large number of test records
      test_count = 10
      test_count.times do |i|
        Password.create!(
          payload: "batch_test_#{i}",
          url_token: "batch_token_#{i}"
        )
      end
      
      # Mock the find_each method to verify it's called
      find_each_called = false
      
      Password.singleton_class.class_eval do
        alias_method :original_find_each, :find_each
        
        define_method(:find_each) do |**options, &block|
          find_each_called = true
          original_find_each(**options, &block)
        end
      end
      
      # Run the migration
      @migration.migrate_passwords
      
      # Restore the original method
      Password.singleton_class.class_eval do
        alias_method :find_each, :original_find_each
        remove_method :original_find_each
      end
      
      # Assert that find_each was called
      assert find_each_called, "find_each should be called for batch processing"
      
      # Verify all passwords were migrated
      assert_equal test_count, Push.where(kind: "text").count
      
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
        expire_after_days: 7,
        expire_after_views: 5,
        deletable_by_viewer: true,
        retrieval_step: false,
        url_token: "password123"
      )
      
      # Create a test user first
      test_user = User.create!(
        email: 'test2@example.com',
        password: 'password123'
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
        password_id: password.id,
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
      # The exact number might vary depending on existing data
      assert Push.count > pushes_before, "No new pushes were created"
      
      # Verify new audit logs were created
      assert AuditLog.count > audit_logs_before, "No new audit logs were created"
      
      # Verify each original record was migrated
      assert_not_nil Push.find_by(url_token: password.url_token)
      assert_not_nil Push.find_by(url_token: file_push.url_token)
      assert_not_nil Push.find_by(url_token: url.url_token)
      
      # Always rollback to keep test isolated
      raise ActiveRecord::Rollback
    end
  end
end
