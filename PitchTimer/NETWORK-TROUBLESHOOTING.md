# Network Sync Troubleshooting

## Common Issues

### "Failed to Connect" Error

If joining a session fails, try these steps:

#### 1. Verify Same Network
Both machines MUST be on the same WiFi/Ethernet network:
```bash
# On both machines, run:
ifconfig | grep "inet "

# Look for matching 192.168.x.x or 10.0.x.x addresses
```

**Example - Good:**
- Machine 1: `192.168.1.100`
- Machine 2: `192.168.1.105` ✅ Same subnet

**Example - Bad:**
- Machine 1: `192.168.1.100`
- Machine 2: `192.168.2.105` ❌ Different subnets

---

#### 2. Check Firewall Settings

macOS Firewall may block connections:

1. **System Preferences** → **Security & Privacy** → **Firewall**
2. Click **Firewall Options**
3. Make sure **"Block all incoming connections"** is OFF
4. Or add PitchTimer to allowed apps

---

#### 3. Verify Code Entry

- Code must be **exactly 6 digits**
- No spaces or dashes
- Case doesn't matter (all numbers)

**Example:**
- Good: `482915`
- Bad: `48 29 15` or `482-915`

---

#### 4. Restart Both Apps

Sometimes helps to:
1. Quit PitchTimer on both machines
2. Relaunch
3. Try connection again

---

#### 5. Check Network Type

**Will work:**
- Same WiFi network
- Same Ethernet network
- WiFi + Ethernet on same router

**Won't work:**
- Different WiFi networks
- VPN connections
- Cellular/hotspot to WiFi
- Guest WiFi (often isolated)

---

## Advanced Troubleshooting

### Test Network Connectivity

On **host machine**, find IP:
```bash
ifconfig en0 | grep "inet "
# Example output: inet 192.168.1.100
```

On **joining machine**, test connection:
```bash
ping 192.168.1.100
# Should see replies if network is good
```

---

### Check if Ports are Blocked

```bash
# On host, after starting hosting:
lsof -i :59000-60000
# Should show PitchTimer listening
```

---

### Verbose Logging

PitchTimer logs to Console. To view:
1. Open **Console.app**
2. Search for "PitchTimer"
3. Look for connection errors

---

## How It Works

### Connection Process

```
Host:
1. Generates 6-digit code
2. Starts TCP listener on port 59000-60000
3. Broadcasts code:port via UDP (port 59100)
4. Waits for incoming connections

Join:
1. Listens for UDP broadcasts on port 59100
2. Finds broadcast matching entered code
3. Connects to host's TCP port
4. Establishes sync connection
```

### Network Requirements

- **Protocol**: TCP for data, UDP for discovery
- **Ports**: 59000-60100 range
- **Firewall**: Must allow incoming connections
- **Network**: Same local subnet required

---

## Quick Fixes Checklist

- [ ] Both machines on same WiFi/network?
- [ ] Firewall not blocking PitchTimer?
- [ ] Code entered correctly (6 digits)?
- [ ] Host clicked "Start Hosting" first?
- [ ] Guest network not isolated?
- [ ] VPN disabled on both machines?
- [ ] Restarted PitchTimer on both?

---

## Still Not Working?

### Fallback: Manual IP Entry

If auto-discovery fails, you can try manual connection (requires code update):

1. On host machine, get IP:
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```

2. Share IP and code with joining machine

3. Manual connection would require app update

---

## Common Network Scenarios

### ✅ Home WiFi
- **Works**: All devices on same WiFi
- **Tip**: Make sure not on guest network

### ✅ Office Network
- **Works**: If firewall permits
- **Tip**: May need IT to allow ports 59000-59100

### ❌ Public WiFi
- **Usually blocked**: Client isolation enabled
- **Fix**: Use personal hotspot instead

### ⚠️ Corporate Network
- **May work**: Depends on security policies
- **Tip**: Test on same floor/building first

---

## Performance Tips

- **Latency**: < 100ms on same WiFi
- **Range**: Typical WiFi range limits
- **Peers**: Tested with 2-5 machines
- **Reliability**: Best on 5GHz WiFi
