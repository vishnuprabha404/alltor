# alltor

Unified Tor routing tool for Linux - routes all system traffic through Tor transparently.

## ⚠️ IMPORTANT CAUTIONS

> **⚠️ This tool is still in active development. Use at your own risk.**

**Before using this tool, please be aware:**

1. **DNS and Network Changes**: The `stop` command modifies your NetworkManager connection settings and may temporarily affect your `/etc/resolv.conf` file. These changes are automatically reverted, but network disruption may occur during the transition.

2. **Sudo Permissions Required**: This tool requires sudo privileges to modify iptables rules, DNS settings, and system network configuration.

3. **Network Interruption**: Starting and stopping Tor routing will briefly interrupt your network connection as it reconfigures DNS and firewall rules.

4. **No Backup on First Run**: The tool saves your current network state, but if something goes wrong before the state file is created, you may need to manually restore your network settings.

5. **IPv6 Disabled**: While Tor routing is active, IPv6 is completely disabled to prevent leaks. This may affect applications that require IPv6.

6. **Not a Complete Anonymity Solution**: This tool routes TCP traffic through Tor, but browser fingerprinting, application-level leaks, and other tracking methods still apply. Use Tor Browser for web browsing anonymity.

7. **UDP Traffic Blocked**: Only TCP traffic is routed through Tor. UDP traffic (like some games, VoIP, or DNS over UDP) will be blocked.

**If you encounter network issues after using the tool:**
```bash
# Manually restore connection
sudo nmcli connection down "Your Connection Name"
sudo nmcli connection up "Your Connection Name"

# Or flush iptables manually
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
```

---

## Features

- ✅ Routes all TCP traffic through Tor transparently
- ✅ Redirects DNS queries through Tor (prevents DNS leaks)
- ✅ Disables IPv6 automatically to prevent leaks
- ✅ Auto-detects active network interface
- ✅ Cross-distribution compatibility (Arch, Debian, Ubuntu, Fedora, etc.)
- ✅ Saves and restores network settings automatically
- ✅ Integrated health diagnostics in status command
- ✅ Handles connection names with spaces correctly
- ✅ Color-coded output with highlighted IPs and DNS
- ✅ Graceful fallbacks for missing dependencies
- ✅ Simple command-line interface

## Requirements

### Required
- **systemd** (systemctl) or compatible init system
- **Tor service** installed and configured
- **iptables** for firewall rules
- **curl** for connectivity testing
- **sudo privileges**

### Recommended
- **NetworkManager** (nmcli) for automatic DNS management
  - Without NetworkManager, DNS must be configured manually

### Installation of Dependencies

**Arch Linux:**
```bash
sudo pacman -S tor iptables curl
sudo systemctl enable tor
```

**Debian/Ubuntu:**
```bash
sudo apt install tor iptables curl
sudo systemctl enable tor
```

**Fedora:**
```bash
sudo dnf install tor iptables curl
sudo systemctl enable tor
```

## Installation

```bash
# Clone the repository
git clone https://github.com/vishnuprabha404/alltor.git
cd alltor

# Make executable
chmod +x alltor

# Optional: Create a system-wide link
sudo ln -s $(pwd)/alltor /usr/local/bin/alltor
```

## Usage

### Basic Commands

```bash
# Start Tor routing (routes all traffic through Tor)
./alltor start

# Stop Tor routing and restore normal connection
./alltor stop

# Check current status with diagnostics
./alltor status

# Show help
./alltor help
```

### If installed system-wide:
```bash
alltor start
alltor stop
alltor status
```

## How It Works

### Start Command
1. Checks for required dependencies
2. Detects active network interface and connection
3. Saves current network configuration
4. Starts Tor service (if not running)
5. Configures DNS to use Tor (127.0.0.1)
6. Sets up iptables rules to redirect all TCP traffic through Tor
7. Disables IPv6 to prevent leaks
8. Tests Tor connectivity and shows exit IP

### Stop Command
1. Auto-detects current active network connection
2. Resets DNS to automatic (DHCP)
3. Restarts network connection to apply changes
4. Flushes all iptables rules
5. Re-enables IPv6
6. Tests internet connectivity
7. Shows current real IP and DNS servers
8. Cleans up state file

### Status Command
1. Checks if Tor routing is active
2. Verifies Tor service is running
3. Shows current network interface
4. Displays DNS configuration
5. Checks IPv6 status
6. Tests Tor connectivity (if active)
7. Shows current IP (Tor exit IP or real IP)
8. Shows current DNS configuration
9. Reports any issues or warnings

## Examples

### Quick Start

```bash
# Start Tor routing
./alltor start

# Verify Tor is working
curl https://check.torproject.org/

# Check your Tor exit IP
curl https://ifconfig.me

# Check detailed status
./alltor status

# Stop when done
./alltor stop
```

### Status Output Examples

**When Tor is Active:**
```
✓ Tor routing is ACTIVE

✓ Tor service is running
✓ Network interface: wlo1
✓ DNS: 127.0.0.1 (Tor DNS)
✓ IPv6 is disabled

ℹ Testing Tor connectivity...
✓ Tor connectivity verified
  Tor exit IP: 107.189.13.253

✓ ✅ All checks passed - Tor is working properly
```

**When Tor is Inactive:**
```
ℹ Tor routing is INACTIVE

✓ Normal routing active
  Current IP: 142.188.2.75
  Current DNS: automatic
```

### DNS Leak Testing

A comprehensive DNS leak test script is included: `test-dns-leak.sh`

```bash
# Run the DNS leak test
./test-dns-leak.sh

# The test checks:
# - /etc/resolv.conf configuration
# - systemd-resolved status
# - Fallback DNS servers
# - LLMNR/mDNS status (leak vectors)
# - IPv6 status
# - iptables DNS rules
# - Actual DNS resolution
# - Tor connectivity
# - External DNS leak test
```

This tool is useful for:
- Verifying your Tor setup has no DNS leaks
- Checking your general system for DNS privacy issues
- Confirming VPN DNS configuration

## Troubleshooting

### Tor routing not working?

```bash
# Check detailed status
./alltor status

# Try restarting
./alltor stop
sleep 2
./alltor start
```

### Network issues after stopping?

```bash
# The stop command should restore everything automatically
# If issues persist, manually restart your connection:
sudo nmcli connection down "Your Connection Name"
sudo nmcli connection up "Your Connection Name"

# Or restart NetworkManager
sudo systemctl restart NetworkManager
```

### Can't start Tor?

```bash
# Check if Tor service is installed
systemctl status tor

# Start Tor manually
sudo systemctl start tor

# Check Tor logs
sudo journalctl -u tor -n 50
```

### Missing dependencies?

The tool will automatically detect and list missing dependencies when you try to start it.

## Files Created

### Temporary Files
- `/tmp/alltor-state` - Saved network configuration (cleaned up on stop)
- `/tmp/alltor.lock` - Lock file to prevent concurrent execution
- `/tmp/alltor-saved-fallback.conf` - Backup of fallback DNS config (if it exists)

### System Configuration Files (while Tor is active)
- `/etc/systemd/resolved.conf.d/tor-dns.conf` - Tor DNS configuration (auto-created on start, auto-removed on stop)

### Optional Permanent Configuration
- `/etc/systemd/resolved.conf.d/no-fallback.conf` - Disables fallback DNS permanently (if you create it manually)

## Cross-Distribution Compatibility

The tool automatically detects and adapts to:
- Different Tor usernames (`tor`, `debian-tor`, `_tor`)
- systemd vs. traditional init systems
- NetworkManager availability
- Process management differences

Tested on:
- Arch Linux
- Debian/Ubuntu
- Fedora
- Other systemd-based distributions

## DNS Privacy & Fallback DNS

### Understanding DNS Fallback (Important for All Users)

By default, systemd-resolved (used by most modern Linux distributions) includes fallback DNS servers from Google (8.8.8.8), Cloudflare (1.1.1.1), and Quad9 (9.9.9.9). While this seems helpful, it's actually a **privacy concern for all users**, not just Tor users.

#### The Privacy Problem

When your primary DNS server has even a brief hiccup:
1. Your system silently switches to fallback DNS (Google/Cloudflare)
2. **All your DNS queries are now logged by these companies**
3. They can see: which websites you visit, when, and how often
4. This happens **without your knowledge or consent**

#### Who Should Disable Fallback DNS?

✅ **VPN Users** - Fallback DNS queries can leak outside your VPN tunnel  
✅ **Privacy-Conscious Users** - Avoid silent logging by Google/Cloudflare  
✅ **Tor Users** - Essential for preventing DNS leaks  
✅ **Corporate/Institutional Users** - Prevent bypassing DNS policies

#### Disable Fallback DNS (Recommended)

**Option 1: Permanently disable (most secure)**
```bash
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/no-fallback.conf > /dev/null << 'EOF'
[Resolve]
FallbackDNS=
EOF
sudo systemctl restart systemd-resolved
```

**Option 2: Let alltor manage it (automatic)**  
The `alltor` tool automatically disables fallback DNS when starting Tor routing and can restore it when stopping. Just use `alltor start` and `alltor stop`.

#### To Re-enable Fallback DNS (if needed)
```bash
sudo rm -f /etc/systemd/resolved.conf.d/no-fallback.conf
sudo systemctl restart systemd-resolved
```

#### The Trade-off

| With Fallback DNS | Without Fallback DNS |
|-------------------|---------------------|
| ✅ Slightly more resilient to DNS outages | ⚠️ If primary DNS fails, no resolution |
| ❌ Privacy leak to Google/Cloudflare | ✅ Your DNS provider choice is respected |
| ❌ Potential VPN/Tor DNS leaks | ✅ No unexpected DNS leaks |
| ❌ Can bypass security policies | ✅ Fail-secure behavior |

**Our Recommendation**: Disable fallback DNS. DNS failures are rare, but privacy leaks are constant. You'll notice if DNS breaks and can fix it, but you won't notice silent logging.

## Security Notes

### What This Tool Does
- Routes all TCP traffic through Tor network
- Prevents DNS leaks by routing DNS through Tor
- Disables IPv6 to prevent leak vectors
- Blocks UDP traffic (not supported by Tor)
- Disables systemd-resolved fallback DNS when active
- Disables LLMNR and mDNS to prevent DNS leaks

### What This Tool Does NOT Do
- **Does not provide complete anonymity** - Use Tor Browser for web browsing
- **Does not protect against browser fingerprinting**
- **Does not route UDP traffic** (only TCP)
- **Does not protect against application-level leaks**
- **Does not protect against time-based correlation attacks**

### Best Practices
1. Use Tor Browser for web browsing (don't rely solely on this tool)
2. Avoid logging into personal accounts while using Tor
3. Be aware that your ISP can see you're using Tor (but not what you're doing)
4. Some websites may block Tor exit nodes
5. Tor routing will be slower than direct connections

## Known Limitations

1. **UDP Not Supported**: Applications requiring UDP (some games, VoIP) won't work
2. **NetworkManager Dependency**: Without NetworkManager, DNS configuration is manual
3. **Connection Interruption**: Starting/stopping causes brief network interruption
4. **Tor Service Required**: Tor must be installed and properly configured
5. **Root Privileges**: Requires sudo for all operations

## Development Status

This tool is in **active development**. Features may change, and bugs may exist. Always test in a non-critical environment first.

**Contributions and bug reports are welcome!**

## License

Use freely at your own risk. No warranties provided.

## Credits

Based on transparent Tor proxy configuration techniques and inspired by various Tor routing implementations.

---

**Remember: This is a development tool. Always verify your anonymity setup and use Tor Browser for sensitive web browsing.**
