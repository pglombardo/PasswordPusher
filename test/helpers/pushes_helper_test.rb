# frozen_string_literal: true

require "test_helper"

class PushesHelperTest < ActionView::TestCase
  include PushesHelper

  test "filesize returns 0.0 B for zero size" do
    assert_equal "0.0 B", filesize(0)
  end

  test "filesize formats bytes correctly" do
    assert_equal "1.0 B", filesize(1)
    assert_equal "100.0 B", filesize(100)
    assert_equal "512.0 B", filesize(512)
    assert_equal "1023.0 B", filesize(1023)
  end

  test "filesize formats kilobytes correctly" do
    assert_equal "1.0 KiB", filesize(1024)
    assert_equal "1.5 KiB", filesize(1536)
    assert_equal "10.0 KiB", filesize(10 * 1024)
    assert_equal "1023.0 KiB", filesize(1023 * 1024)
  end

  test "filesize formats megabytes correctly" do
    assert_equal "1.0 MiB", filesize(1024 * 1024)
    assert_equal "1.5 MiB", filesize(1.5 * 1024 * 1024)
    assert_equal "10.0 MiB", filesize(10 * 1024 * 1024)
    assert_equal "1023.0 MiB", filesize(1023 * 1024 * 1024)
  end

  test "filesize formats gigabytes correctly" do
    assert_equal "1.0 GiB", filesize(1024 * 1024 * 1024)
    assert_equal "1.5 GiB", filesize(1.5 * 1024 * 1024 * 1024)
    assert_equal "10.0 GiB", filesize(10 * 1024 * 1024 * 1024)
  end

  test "filesize formats terabytes correctly" do
    assert_equal "1.0 TiB", filesize(1024 * 1024 * 1024 * 1024)
    assert_equal "2.5 TiB", filesize(2.5 * 1024 * 1024 * 1024 * 1024)
  end

  test "filesize handles edge case near unit boundary" do
    # Test the boundary logic: exp += 1 if size.to_f / (1024**exp) >= 1024 - 0.05
    # At 1023.95 KiB, it should still show as KiB, not MiB
    size_just_below = (1024 - 0.1) * 1024
    result = filesize(size_just_below)
    assert_match(/KiB/, result, "Should still be KiB when just below boundary")

    # At exactly 1024 KiB, it should be 1.0 MiB
    size_exactly = 1024 * 1024
    result = filesize(size_exactly)
    assert_match(/MiB/, result, "Should be MiB when exactly at boundary")
  end

  test "filesize handles very large sizes" do
    # Test that it doesn't crash on very large numbers
    large_size = 1024**6 # PiB
    result = filesize(large_size)
    assert result.is_a?(String)
    assert_not_empty result
  end

  test "filesize handles maximum unit" do
    # Test with a size that would exceed the available units
    # Units are: B, KiB, MiB, GiB, TiB, Pib, EiB, ZiB (8 units)
    # So max exp should be capped at 7 (0-indexed)
    huge_size = 1024**10 # Way beyond ZiB
    result = filesize(huge_size)
    # Should not crash and should return a formatted string
    assert result.is_a?(String)
    assert_match(/ZiB/, result, "Should cap at the highest unit (ZiB)")
  end

  test "filesize formats with one decimal place" do
    # Test that all results have exactly one decimal place
    sizes = [100, 1024, 1536, 2048, 1024 * 1024]
    sizes.each do |size|
      result = filesize(size)
      # Match pattern: number.number unit (e.g., "1.5 MiB")
      assert_match(/\d+\.\d+ \w+/, result, "Result should have one decimal place: #{result}")
    end
  end

  test "filesize handles fractional sizes correctly" do
    # Test various fractional sizes
    assert_equal "512.0 B", filesize(512) # 512 bytes is less than 1 KiB
    assert_equal "1.5 KiB", filesize(1536) # 1.5 KiB
    assert_equal "2.3 MiB", filesize(2.3 * 1024 * 1024) # 2.3 MiB
  end

  test "filesize handles real-world file sizes" do
    # Common file sizes
    assert_equal "4.0 KiB", filesize(4096) # Typical page size
    assert_equal "1.0 MiB", filesize(1024 * 1024) # 1 MB
    assert_equal "5.0 MiB", filesize(5 * 1024 * 1024) # 5 MB
    assert_equal "100.0 MiB", filesize(100 * 1024 * 1024) # 100 MB
    assert_equal "1.0 GiB", filesize(1024 * 1024 * 1024) # 1 GB
  end
end
