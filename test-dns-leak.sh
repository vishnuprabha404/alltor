#!/bin/bash

# DNS Leak Test Script
# Tests for various types of DNS leaks when using Tor

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}           DNS LEAK TEST FOR TOR${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

# Test 1: Check resolv.conf
echo -e "${YELLOW}[1] Checking /etc/resolv.conf${NC}"
nameserver=$(grep "^nameserver" /etc/resolv.conf | head -n1 | awk '{print $2}')
echo "   Nameserver: $nameserver"
if [[ "$nameserver" == "127.0.0.53" ]] || [[ "$nameserver" == "127.0.0.1" ]]; then
    echo -e "   ${GREEN}✓ Using local resolver${NC}"
else
    echo -e "   ${RED}✗ WARNING: Using external resolver!${NC}"
fi
echo ""

# Test 2: Check resolvectl status
echo -e "${YELLOW}[2] Checking systemd-resolved status${NC}"
current_dns=$(resolvectl status | grep "Current DNS Server" | awk '{print $4}')
echo "   Current DNS Server: $current_dns"
if [[ "$current_dns" == "127.0.0.1" ]]; then
    echo -e "   ${GREEN}✓ DNS pointing to Tor${NC}"
else
    echo -e "   ${YELLOW}⚠ DNS: $current_dns (Expected: 127.0.0.1)${NC}"
fi
echo ""

# Test 3: Check for fallback DNS
echo -e "${YELLOW}[3] Checking for fallback DNS servers${NC}"
fallback=$(resolvectl status | grep "Fallback DNS")
if [[ -z "$fallback" ]]; then
    echo -e "   ${GREEN}✓ No fallback DNS servers configured${NC}"
else
    echo -e "   ${RED}✗ WARNING: Fallback DNS servers present!${NC}"
    echo "$fallback"
fi
echo ""

# Test 4: Check LLMNR and mDNS
echo -e "${YELLOW}[4] Checking LLMNR/mDNS (potential leak vectors)${NC}"
llmnr_status=$(resolvectl status | grep -m1 "LLMNR" | grep -o "LLMNR=[^ ]*")
mdns_status=$(resolvectl status | grep -m1 "mDNS" | grep -o "mDNS=[^ ]*")
echo "   $llmnr_status"
echo "   $mdns_status"
if [[ "$llmnr_status" == *"no"* ]] && [[ "$mdns_status" == *"no"* ]]; then
    echo -e "   ${GREEN}✓ LLMNR and mDNS disabled${NC}"
else
    echo -e "   ${YELLOW}⚠ LLMNR/mDNS enabled (may cause leaks)${NC}"
fi
echo ""

# Test 5: Check IPv6
echo -e "${YELLOW}[5] Checking IPv6 status${NC}"
ipv6_disabled=$(sysctl -n net.ipv6.conf.all.disable_ipv6 2>/dev/null)
if [[ "$ipv6_disabled" == "1" ]]; then
    echo -e "   ${GREEN}✓ IPv6 is disabled${NC}"
else
    echo -e "   ${RED}✗ WARNING: IPv6 is enabled (can leak!)${NC}"
fi
echo ""

# Test 6: Check iptables rules
echo -e "${YELLOW}[6] Checking iptables DNS redirect rules${NC}"
dns_rules=$(sudo iptables -t nat -L OUTPUT -n 2>/dev/null | grep -c "dpt:53")
if [[ "$dns_rules" -gt 0 ]]; then
    echo -e "   ${GREEN}✓ DNS redirect rules present ($dns_rules rules)${NC}"
else
    echo -e "   ${RED}✗ WARNING: No DNS redirect rules found!${NC}"
fi
echo ""

# Test 7: Actual DNS leak test
echo -e "${YELLOW}[7] Performing DNS leak test${NC}"
echo "   Testing DNS resolution..."

# Try to resolve a domain and see which DNS server is used
test_domain="check.torproject.org"
echo "   Resolving: $test_domain"

# Method 1: Using dig if available
if command -v dig &> /dev/null; then
    dig_result=$(dig +short $test_domain 2>/dev/null | head -n1)
    echo "   Result: $dig_result"
fi

# Method 2: Check with nslookup if available
if command -v nslookup &> /dev/null; then
    ns_server=$(nslookup $test_domain 2>/dev/null | grep "Server:" | awk '{print $2}')
    echo "   DNS Server used: $ns_server"
    if [[ "$ns_server" == "127.0.0.1" ]] || [[ "$ns_server" == "127.0.0.53" ]]; then
        echo -e "   ${GREEN}✓ Using local DNS resolver${NC}"
    else
        echo -e "   ${RED}✗ WARNING: Using external DNS server!${NC}"
    fi
fi
echo ""

# Test 8: Check Tor status
echo -e "${YELLOW}[8] Checking Tor connectivity${NC}"
if systemctl is-active --quiet tor 2>/dev/null; then
    echo -e "   ${GREEN}✓ Tor service is running${NC}"
    
    # Test if we're actually using Tor
    echo "   Testing Tor connection..."
    tor_check=$(curl -s --max-time 10 https://check.torproject.org/ 2>/dev/null || echo "")
    if echo "$tor_check" | grep -q "Congratulations"; then
        tor_ip=$(curl -s --max-time 10 https://ifconfig.me 2>/dev/null || echo "Unknown")
        echo -e "   ${GREEN}✓ Successfully connected through Tor${NC}"
        echo -e "   ${GREEN}  Exit IP: ${YELLOW}$tor_ip${NC}"
    else
        echo -e "   ${RED}✗ Tor connectivity test failed${NC}"
    fi
else
    echo -e "   ${RED}✗ Tor service is not running${NC}"
fi
echo ""

# Test 9: DNS leak test via external service
echo -e "${YELLOW}[9] External DNS leak test${NC}"
echo "   Checking DNS via dnsleaktest.com..."
dns_leak=$(curl -s --max-time 10 "https://bash.ws/dnsleak" 2>/dev/null || echo "")
if [[ -n "$dns_leak" ]]; then
    echo "$dns_leak" | head -n 5
    if echo "$dns_leak" | grep -qi "tor\|proxy"; then
        echo -e "   ${GREEN}✓ DNS appears to be routed through Tor${NC}"
    else
        echo -e "   ${YELLOW}⚠ Check results above for your ISP's DNS${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠ Could not perform external DNS leak test${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    SUMMARY${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "For complete DNS leak protection, verify:"
echo -e "  1. ${GREEN}✓${NC} DNS set to 127.0.0.1"
echo -e "  2. ${GREEN}✓${NC} No fallback DNS servers"
echo -e "  3. ${GREEN}✓${NC} LLMNR/mDNS disabled"
echo -e "  4. ${GREEN}✓${NC} IPv6 disabled"
echo -e "  5. ${GREEN}✓${NC} iptables rules active"
echo -e "  6. ${GREEN}✓${NC} Tor connectivity verified"
echo ""
echo -e "${YELLOW}Additional online tests:${NC}"
echo -e "  • https://dnsleaktest.com/"
echo -e "  • https://ipleak.net/"
echo -e "  • https://www.doileak.com/"
echo ""

