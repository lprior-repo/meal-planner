# Tandoor API Monitoring

This directory contains monitoring tools for the Tandoor API. These tools help track errors, performance issues, and system health over a 24-hour period.

## Scripts

### 1. tandoor-monitor.sh
Main monitoring script that runs continuous health checks on the Tandoor API.

**Usage:**
```bash
./tandoor-monitor.sh
```

**What it does:**
- Checks Tandoor health endpoint every 5 minutes
- Tests API endpoints for availability
- Monitors system resources (CPU, memory, disk)
- Logs all errors and warnings
- Runs for 24 hours continuously
- Generates summary reports

**Output:**
- Logs to: `~/.meal-planner/monitoring/tandoor-errors.log`
- Statistics: `~/.meal-planner/monitoring/tandoor-stats.json`

**Example output:**
```
[SUCCESS] Tandoor health check passed (HTTP 200, 125ms)
[ERROR] Tandoor health check failed (HTTP 500)
[INFO] System Resources - CPU: 15.2%, MEM: 42%, DISK: 45%
```

### 2. tandoor-log-analyzer.sh
Analyzes error logs and generates detailed reports.

**Usage:**
```bash
# Generate comprehensive error analysis
./tandoor-log-analyzer.sh analyze

# Show last 20 errors
./tandoor-log-analyzer.sh recent 20

# Watch logs in real-time
./tandoor-log-analyzer.sh watch
```

**Output:**
- Error summaries with frequency counts
- Performance metrics (response times)
- System resource usage statistics
- Error timeline
- Success rate percentage

### 3. tandoor-alert.sh
Alert system that sends notifications when thresholds are exceeded.

**Usage:**
```bash
# Initialize alert configuration
./tandoor-alert.sh init-config

# Run all alert checks
./tandoor-alert.sh check

# Show alert summary
./tandoor-alert.sh summary
```

**Configuration:**
Edit `/var/log/meal-planner-monitoring/alert-config.json` to customize:
- Error threshold (default: 5 errors)
- Error window (default: 1 hour)
- Memory threshold (default: 85%)
- CPU threshold (default: 80%)

## Monitoring Workflow

### Quick Start (24-hour monitoring):

```bash
# 1. Start monitoring in the background
nohup ./tandoor-monitor.sh > /tmp/tandoor-monitor.log 2>&1 &
echo $! > /tmp/tandoor-monitor.pid

# 2. Initialize alerts
./tandoor-alert.sh init-config

# 3. Run periodic checks (add to crontab)
# */5 * * * * /home/lewis/src/meal-planner/scripts/monitoring/tandoor-alert.sh check

# 4. Check status periodically
./tandoor-log-analyzer.sh recent 5
```

### Monitoring Output Files

```
~/.meal-planner/monitoring/
├── tandoor-errors.log       # Main error log
├── tandoor-stats.json       # Statistics (JSON format)
├── tandoor-alerts.log       # Alert events
└── alert-config.json        # Alert configuration
```

## Example Monitoring Session

```bash
# Start 24-hour monitoring
nohup /home/lewis/src/meal-planner/scripts/monitoring/tandoor-monitor.sh &

# Check status after a few minutes
/home/lewis/src/meal-planner/scripts/monitoring/tandoor-log-analyzer.sh analyze

# Initialize alerts
/home/lewis/src/meal-planner/scripts/monitoring/tandoor-alert.sh init-config

# View specific errors
/home/lewis/src/meal-planner/scripts/monitoring/tandoor-log-analyzer.sh recent 10

# Watch live log
tail -f ~/.meal-planner/monitoring/tandoor-errors.log
```

## Understanding the Logs

### Error Log Format
```
2025-12-12 22:45:30 [SUCCESS] Tandoor health check passed (HTTP 200, 125ms)
2025-12-12 22:50:35 [ERROR] Tandoor health check failed (HTTP 500)
2025-12-12 22:55:40 [WARN] API endpoint /recipes returned HTTP 404
2025-12-12 23:00:45 [INFO] System Resources - CPU: 15.2%, MEM: 42%, DISK: 45%
```

### Alert Levels
- **CRITICAL**: API unavailable, too many errors, resource exhaustion
- **WARNING**: High resource usage, some failures
- **INFO**: Normal operation notes

## Interpreting Results

### Healthy Monitoring:
- Success rate > 95%
- Avg response time < 500ms
- CPU < 50%, Memory < 75%
- Error rate < 1 per hour

### Issues to Watch:
- Increased error rate (5+ errors per hour)
- Response time > 1000ms
- Memory usage > 85%
- CPU sustained > 80%
- API unavailable for > 5 minutes

## Integration with Tandoor

The monitoring scripts check:
- Tandoor health endpoint: `http://localhost:8000/health`
- Tandoor API endpoints: `http://localhost:8000/api/v1`, `/api/recipes`
- System resources (CPU, memory, disk)

## Advanced Usage

### Custom Monitoring Duration
Edit the script and change `MONITOR_DURATION=86400` to your desired seconds.

### Custom Health Check Interval
Edit `HEALTH_CHECK_INTERVAL=300` (5 minutes) to check more/less frequently.

### Running Multiple Monitors
Each monitor can track different endpoints or services by customizing the API endpoints checked.

## Troubleshooting

### "Tandoor unreachable"
- Check if Tandoor is running: `./run.sh status`
- Verify URL is correct: `curl http://localhost:8000/health`

### Missing log directories
- The script creates `~/.meal-planner/monitoring/` automatically
- Ensure proper permissions: `ls -la ~/.meal-planner/monitoring/`

### No data in JSON stats
- The JSON file is initialized but may require jq for parsing
- Install jq: `sudo pacman -S jq`

## Next Steps

1. Run `tandoor-monitor.sh` for 24 hours
2. Periodically check with `tandoor-log-analyzer.sh analyze`
3. Set up alerts with `tandoor-alert.sh check`
4. Review results after 24 hours
5. Generate final report with log analyzer
