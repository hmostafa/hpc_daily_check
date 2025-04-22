#!/bin/bash

# === Daily HPC Health Check Script with BeeGFS ===
# Author: HPC System Engineer
# ===============================================

LOG_DIR="/var/log/hpc-daily-check"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/hpc_report_$(date +'%Y-%m-%d_%H-%M-%S').log"

echo "=== HPC Daily System Health Check ===" | tee -a "$LOG_FILE"
echo "Generated on: $(date)" | tee -a "$LOG_FILE"
echo "=====================================" | tee -a "$LOG_FILE"

# 1. Node Status
echo -e "\n>>> Node Status (SLURM)" | tee -a "$LOG_FILE"
sinfo -o "%N %t %E" | tee -a "$LOG_FILE"

# 2. Drained/Down Nodes
echo -e "\n>>> Drained or Down Nodes" | tee -a "$LOG_FILE"
sinfo -R | tee -a "$LOG_FILE"

# 3. SLURM Queue Summary
echo -e "\n>>> Job Queue (squeue)" | tee -a "$LOG_FILE"
squeue -o "%.18i %.9P %.8j %.8u %.2t %.10M %.6D %R" | tee -a "$LOG_FILE"

# 4. Cluster Utilization
echo -e "\n>>> SLURM Cluster Utilization (Last 24h)" | tee -a "$LOG_FILE"
sreport cluster utilization start=now-1days end=now | tee -a "$LOG_FILE"

# 5. GPU Status
echo -e "\n>>> NVIDIA GPU Status" | tee -a "$LOG_FILE"
which nvidia-smi &>/dev/null && nvidia-smi | tee -a "$LOG_FILE" || echo "No NVIDIA GPUs found" | tee -a "$LOG_FILE"

# 6. Memory and Load
echo -e "\n>>> Memory Usage (free -h)" | tee -a "$LOG_FILE"
free -h | tee -a "$LOG_FILE"

echo -e "\n>>> Load Average (uptime)" | tee -a "$LOG_FILE"
uptime | tee -a "$LOG_FILE"

# 7. Disk Usage
echo -e "\n>>> Filesystem Usage (df -hT)" | tee -a "$LOG_FILE"
df -hT | tee -a "$LOG_FILE"

# 8. BeeGFS Health Check
if command -v beegfs-ctl &>/dev/null; then
  echo -e "\n>>> BeeGFS Target Status" | tee -a "$LOG_FILE"
  beegfs-ctl --listtargets --state | tee -a "$LOG_FILE"

  echo -e "\n>>> BeeGFS Unreachable Targets" | tee -a "$LOG_FILE"
  beegfs-ctl --listtargets --unreachables | tee -a "$LOG_FILE"

  echo -e "\n>>> BeeGFS Metadata Nodes" | tee -a "$LOG_FILE"
  beegfs-ctl --listnodes --nodetype=meta | tee -a "$LOG_FILE"

  echo -e "\n>>> BeeGFS Storage Nodes" | tee -a "$LOG_FILE"
  beegfs-ctl --listnodes --nodetype=storage | tee -a "$LOG_FILE"

  echo -e "\n>>> BeeGFS Disk Usage (df -h on /mnt/beegfs*)" | tee -a "$LOG_FILE"
  df -h | grep beegfs | tee -a "$LOG_FILE"

  echo -e "\n>>> BeeGFS Quota (if enabled)" | tee -a "$LOG_FILE"
  beegfs-ctl --getquota --type uid 2>/dev/null | tee -a "$LOG_FILE"
else
  echo -e "\n>>> BeeGFS not detected on this system." | tee -a "$LOG_FILE"
fi

# 9. Log Errors
echo -e "\n>>> Critical Logs (journalctl -p 3)" | tee -a "$LOG_FILE"
journalctl -p 3 -xb | head -n 30 | tee -a "$LOG_FILE"

# 10. Suspicious Processes
echo -e "\n>>> Suspicious Process Scan (crypto/miner)" | tee -a "$LOG_FILE"
ps aux | grep -E 'crypto|minerd|rig' | grep -v grep | tee -a "$LOG_FILE"

# 11. Active Services
echo -e "\n>>> Critical Service Status" | tee -a "$LOG_FILE"
for service in slurmctld slurmd munge; do
  echo -e "\n-- $service --" | tee -a "$LOG_FILE"
  systemctl is-active "$service" | tee -a "$LOG_FILE"
done

echo -e "\n=== End of Report ===" | tee -a "$LOG_FILE"
