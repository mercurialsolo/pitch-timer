# Testing Guide

## Testing CLI Mode

### Basic CLI Test
```bash
cd PitchTimer
.build/release/PitchTimer --cli
```

### CLI with Custom Duration
```bash
.build/release/PitchTimer --cli -d 120  # 2 minute timer
```

### CLI Controls
- Press `[space]` to start/stop the timer
- Press `r` to reset
- Press `+` to add 1 minute
- Press `-` to subtract 1 minute
- Press `q` to quit

### Expected Behavior
- Timer should display in format `MM:SS`
- When timer reaches zero, it should show `🔔 Timer complete!`
- Timer continues counting into negative/overtime (shown with 🔴 emoji)
- All keyboard inputs should respond immediately (raw mode)

## Testing Perfect Time Sync

### Setup (Requires 2 Machines on Same Network)

**Machine 1 (Host):**
1. Launch PitchTimer
2. Click menu bar icon → "Network Sync..."
3. Click "Start Hosting"
4. Note the 6-digit code (e.g., `542791`)

**Machine 2 (Client):**
1. Launch PitchTimer
2. Click menu bar icon → "Network Sync..."
3. Enter the 6-digit code from Machine 1
4. Click "Join Session"
5. Wait for "Connected" status

### Testing Perfect Sync

**Test 1: Start/Stop Sync**
- From Machine 1: Start the timer (press `Cmd+Shift+T` or click "Start Timer")
- **Expected**: Both timers start at exactly the same time
- **Verify**: Watch both screens - they should tick down in perfect sync
- From Machine 2: Stop the timer
- **Expected**: Both timers stop at the exact same time

**Test 2: Time Accuracy**
- Start timer from either machine
- Let it run for 30+ seconds
- **Expected**: Both displays show exactly the same time (within 100ms)
- Take a photo/video of both screens simultaneously
- **Verify**: Time should match precisely, no visible difference

**Test 3: Reset Sync**
- Press `Cmd+Shift+R` on either machine
- **Expected**: Both timers reset to initial duration immediately

**Test 4: Duration Change Sync**
- Press `Cmd+Shift+↑` on either machine to increase duration
- **Expected**: Both timers update to new duration

**Test 5: Overtime Sync**
- Set timer to 5 seconds (`Cmd+Shift+D`)
- Start timer
- Let it reach zero and go into overtime
- **Expected**: Both timers show red background at exactly the same time
- **Expected**: Overtime counts continue in perfect sync

### Technical Details

**How Perfect Sync Works:**
1. Host broadcasts timer state 10 times per second (every 100ms)
2. Each broadcast contains: `{currentTime, isRunning}`
3. Clients receive updates and directly set their timer to match host
4. No accumulated drift - each update is absolute, not relative
5. Maximum possible desync: <100ms (one broadcast interval)

**UDP Discovery:**
- Host broadcasts session code on UDP port 59100
- Broadcast message format: `"{6-digit-code}:{tcp-port}"`
- Clients listen for matching code
- Fallback to Bonjour if UDP fails

**Network Requirements:**
- Same local network (WiFi or Ethernet)
- UDP port 59100 must be open (for discovery)
- TCP ports 59000-60000 range must be open (for timer sync)
- Firewall should allow PitchTimer or disable for testing

### Troubleshooting Sync Issues

**If connection fails:**
1. Check both machines are on same WiFi network
2. Temporarily disable firewall on both machines
3. Check Network dialog shows connection status
4. Try disconnecting and rejoining

**If times drift apart:**
- This should NOT happen with the new implementation
- If you see drift, it indicates a bug - please report
- Expected: <100ms difference at all times

**If one timer updates but other doesn't:**
- Check network connection status
- Verify both machines still show "Connected"
- Try triggering from the other machine

## Expected Performance

### CLI Mode
- Immediate keyboard response
- Smooth 1-second countdown
- Clean terminal output
- Proper exit on 'q'

### Time Sync
- Connection within 2-3 seconds
- Zero visible time difference between machines
- Instant response to commands from any machine
- Sync maintained indefinitely while connected

## Development Testing

### Build and Test
```bash
cd PitchTimer
swift build -c release
.build/release/PitchTimer --cli -d 10
```

### Test Time Sync Locally (Single Machine)
1. Start host: `.build/release/PitchTimer`
2. Start client in CLI: `.build/release/PitchTimer --cli`
   - Note: CLI mode doesn't have network sync (GUI only)
3. Use GUI for both host and client to test sync

### Performance Monitoring
- Watch CPU usage (should be minimal)
- Monitor network traffic (10 packets/sec when running)
- Check memory usage (should be <50MB per instance)
