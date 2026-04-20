#!/bin/bash

echo "=== Deepin Doctor Test Script ==="
echo

# Start daemon
echo "Starting daemon..."
./build/deepin-doctor-daemon &
DAEMON_PID=$!
sleep 2

# Check if daemon is running
if ! ps -p $DAEMON_PID > /dev/null; then
    echo "ERROR: Daemon failed to start"
    exit 1
fi

echo "Daemon started (PID: $DAEMON_PID)"
echo

# Test ListModules
echo "Testing ListModules..."
MODULES=$(gdbus call --session --dest com.deepin.Doctor --object-path /com/deepin/Doctor --method com.deepin.Doctor.ListModules)
echo "Available modules: $MODULES"
echo

# Test Collect (network)
echo "Testing Collect (network module)..."
TASK_ID=$(gdbus call --session --dest com.deepin.Doctor --object-path /com/deepin/Doctor --method com.deepin.Doctor.Collect "['network']" | grep -oP "'\K[^']+")
echo "Task ID: $TASK_ID"
echo "Waiting for collection to finish..."
sleep 5
echo

# Test Detect
echo "Testing Detect (network module)..."
ISSUES=$(gdbus call --session --dest com.deepin.Doctor --object-path /com/deepin/Doctor --method com.deepin.Doctor.Detect "['network']")
echo "Issues detected: $ISSUES"
echo

# Test Collect (system)
echo "Testing Collect (system module)..."
TASK_ID2=$(gdbus call --session --dest com.deepin.Doctor --object-path /com/deepin/Doctor --method com.deepin.Doctor.Collect "['system']" | grep -oP "'\K[^']+")
echo "Task ID: $TASK_ID2"
echo "Waiting for collection to finish..."
sleep 5
echo

# Stop daemon
echo "Stopping daemon..."
kill $DAEMON_PID
wait $DAEMON_PID 2>/dev/null

echo
echo "=== Test Complete ==="
