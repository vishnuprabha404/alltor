#!/bin/bash

echo "🧭 Stopping Tor routing and restoring normal connection..."

# Auto-detect the active network interface
IFACE=$(nmcli -t -f DEVICE connection show --active | head -n1)
ACTIVE_CONN=$(nmcli -t -f NAME,DEVICE connection show --active | grep "$IFACE" | cut -d: -f1)

if [ -n "$ACTIVE_CONN" ]; then
    echo "→ Active connection detected: $ACTIVE_CONN ($IFACE)"

    echo "→ Resetting DNS to automatic mode..."
    # Clear manual DNS and re-enable automatic DNS
    nmcli connection modify "$ACTIVE_CONN" ipv4.dns ""
    nmcli connection modify "$ACTIVE_CONN" ipv4.ignore-auto-dns no
    nmcli connection modify "$ACTIVE_CONN" ipv4.dns-search ""
    nmcli connection modify "$ACTIVE_CONN" ipv6.dns ""
    nmcli connection modify "$ACTIVE_CONN" ipv6.ignore-auto-dns no
    nmcli connection modify "$ACTIVE_CONN" ipv6.dns-search ""

    echo "→ Bringing connection down and up..."
    nmcli connection down "$ACTIVE_CONN" >/dev/null 2>&1
    nmcli connection up "$ACTIVE_CONN" >/dev/null 2>&1

    echo "✓ Network connection reset to default DNS and routing."
else
    echo "⚠ No active connection found! Check your network manually."
fi

echo ""
echo "→ Flushing firewall rules..."

# Prefer firewalld if active, otherwise fallback to iptables
if systemctl is-active --quiet firewalld; then
    firewall-cmd --reload >/dev/null 2>&1
    echo "✓ Firewalld rules reloaded."
else
    iptables -F
    iptables -t nat -F
    iptables -t mangle -F
    iptables -X
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    echo "✓ iptables rules flushed."
fi

echo ""
echo "→ Re-enabling IPv6..."
sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null 2>&1
sysctl -w net.ipv6.conf.default.disable_ipv6=0 >/dev/null 2>&1
sysctl -w net.ipv6.conf."$IFACE".disable_ipv6=0 >/dev/null 2>&1
echo "✓ IPv6 re-enabled."

echo ""
echo "→ Waiting for network to stabilize..."
sleep 3

echo "🌐 Testing connectivity..."
if ping -c 2 8.8.8.8 >/dev/null 2>&1; then
    echo "✓ Internet connectivity verified."
    REAL_IP=$(curl -s --max-time 5 https://ifconfig.me)
    [ -n "$REAL_IP" ] && echo "✓ Current IP: $REAL_IP"
else
    echo "⚠ Ping test failed. Try reconnecting manually:"
    echo "  nmcli connection up \"$ACTIVE_CONN\""
fi

echo ""
echo "🧾 Current DNS servers:"
nmcli device show "$IFACE" | grep -E 'IP[46]\.DNS'
echo ""
echo "✅ Normal (non-Tor) routing restored successfully!"
