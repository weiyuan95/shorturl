require "test_helper"

class HashedUrlVisitTest < ActiveSupport::TestCase
  test "should not be able to create with no params" do
    hashed_url_visit = HashedUrlVisit.new()
    assert_not hashed_url_visit.save
  end

  test "should be able to create only if all params are present" do
    hashed_url_visit = HashedUrlVisit.new(hashed_url: "1234", ip: "0.0.0.0", country: "Singapore")
    assert hashed_url_visit.save
  end

  [
    "rubbish",
    nil,
    true,
    false,
    1234,
    # Invalid IP addresses generated with chatgpt
    # ipv4
    "256.256.256.256", # Values exceed the valid range (0-255)
    "192.168.1.999", # Last octet exceeds valid range
    "123.456.78.90", # Second octet exceeds valid range
    "192.168.1", # Missing octet
    "192.168.1.1.1", # Too many octets
    "192.168.01.1", # Leading zeros in octet
    "192.168.1.-1", # Negative number in octet
    "300.168.1.1", # Octet value exceeds valid range
    "192.168..1", # Missing value between dots
    "abc.def.ghi.jkl", # Non-numeric characters
    "192.168.1.256", # Octet exceeds 255
    "192.168.1.1 ", # Trailing whitespace
    # ipv6
    "2001:db8:85a3::8a2e:370g:7334", # Contains invalid character 'g'
    "2001:0db8:85a3:::7334", # Too many colons (:: used multiple times)
    "12345::abcd", # Too many characters in a group
    "2001::85a3::8a2e:0370:7334", # Multiple sets of double colons (::)
    "1:2:3:4:5:6:7:8:9", # Too many sections
    "2001:db8:85a3:8d3:1319:8a2e:370:73344", # Group exceeds the 4-hex character limit
    "2001:db8:::7334", # Invalid placement of multiple colons
    ":1:2:3:4:5:6:7", # Leading colon without another colon
    "1:2:3:4:5:6:7:", # Trailing colon without another colon
    "fe80:::1ff:fe23:4567:890a", # Improper use of double colons
    "1200::AB00:1234::2552:7777:1313" # Multiple double colons
  ].each do |invalid_ip|
    test "should not save if with invalid ip -> #{invalid_ip}" do
      hashed_url_visit = HashedUrlVisit.new(hashed_url: "1234", ip: invalid_ip, country: "Singapore")
      assert_not hashed_url_visit.save
    end
  end

  # Valid ipv4 and v6 addresses generated with chatgpt
  [
    # ipv4
    "192.168.1.1", # Common private network address
    "10.0.0.1", # Private network address
    "172.16.0.1", # Private network address
    "8.8.8.8", # Public DNS address (Google DNS)
    "127.0.0.1", # Loopback address
    "255.255.255.255", # Broadcast address
    "0.0.0.0", # Unspecified address
    "169.254.0.1", # Link-local address
    # ipv6
    "2001:0db8:85a3:0000:0000:8a2e:0370:7334", # Global unicast address
    "fe80::1ff:fe23:4567:890a", # Link-local address
    "::1", # Loopback address
    "::", # Unspecified address
    "2001:4860:4860::8888", # Public DNS (Google DNS)
    "ff02::1", # Multicast address (all nodes)
    "2001:0db8::", # Documentation (RFC 3849)
    "3ffe:1900:4545:3:200:f8ff:fe21:67cf" # Another global unicast address
  ].each do |valid_ip|
    test "should save with valid ip -> #{valid_ip}" do
      hashed_url_visit = HashedUrlVisit.new(hashed_url: "1234", ip: valid_ip, country: "Singapore")
      assert hashed_url_visit.save
    end
  end
end
