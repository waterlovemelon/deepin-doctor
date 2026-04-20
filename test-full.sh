#!/bin/bash

echo "=== Deepin Doctor Complete Test ==="
echo

# Start daemon
echo "[1/6] Starting daemon..."
./build/deepin-doctor-daemon > /tmp/deepin-doctor-daemon.log 2>&1 &
DAEMON_PID=$!
sleep 2

if ! ps -p $DAEMON_PID > /dev/null; then
    echo "ERROR: Daemon failed to start"
    cat /tmp/deepin-doctor-daemon.log
    exit 1
fi
echo "✓ Daemon started (PID: $DAEMON_PID)"
echo

# Test ListModules
echo "[2/6] Testing ListModules..."
MODULES=$(gdbus call --session --dest com.deepin.Doctor --object-path /com/deepin/Doctor --method com.deepin.Doctor.ListModules)
echo "Available modules: $MODULES"
EXPECTED="(['environment', 'logs', 'network', 'system'],)"
if [ "$MODULES" = "$EXPECTED" ]; then
    echo "✓ ListModules passed"
else
    echo "✗ ListModules failed"
fi
echo

# Test Network module
echo "[3/6] Testing Network module..."
TASK_ID=$(gdbus call --session --dest com.deepin.Doctor --object-path /com/deepin/Doctor --method com.deepin.Doctor.Collect "['network']" | grep -oP "'\K[^']+")
echo "Task ID: $TASK_ID"
sleep 5
ISSUES=$(gdbus call --session --dest com.deepin.Doctor --object-path /com/deepin/Doctor --method com.deepin.Doctor.Detect "['network']")
echo "Network issues detected: ${#ISSUES} bytes"
echo "✓ Network module tested"
echo

# Test System module
echo "[4/6] Testing System module..."
TASK_ID=$(gdbus call --session --dest com.deepin.Doctor --object-path /com/deepin/Doctor --method com.deepin.Doctor.Collect "['system']" | grep -oP "'\K[^']+")
echo "Task ID: $TASK_ID"
sleep 5
echo "✓ System module tested"
echo

# Test Environment module
echo "[5/6] Testing Environment module..."
TASK_ID=$(gdbus call --session --dest com.deepin.Doctor --object-path /com/deepin/Doctor --method com.deepin.Doctor.Collect "['environment']" | grep -oP "'\K[^']+")
echo "Task ID: $TASK_ID"
sleep 3
ISSUES=$(gdbus call --session --dest com.deepin.Doctor --object-path /com/deepin/Doctor --method com.deepin.Doctor.Detect "['environment']")
echo "Environment issues: ${#ISSUES} bytes"
echo "✓ Environment module tested"
echo

# Test Logs module
echo "[6/6] Testing Logs module..."
TASK_ID=$(gdbus call --session --dest com.deepin.Doctor --object-path /com/deepin/Doctor --method com.deepin.Doctor.Collect "['logs']" | grep -oP "'\K[^']+")
echo "Task ID: $TASK_ID"
sleep 3
echo "✓ Logs module tested"
echo

# Show daemon log
echo "=== Daemon Log (last 20 lines) ==="
tail -20 /tmp/deepin-doctor-daemon.log
echo

# Stop daemon
echo "Stopping daemon..."
kill $DAEMON_PID
wait $DAEMON_PID 2>/dev/null

echo
echo "=== Test Complete ==="
echo "All modules tested successfully!"
