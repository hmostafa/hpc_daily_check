# hpc_daily_check

As an HPC System Engineer, performing daily system health checks is crucial to maintaining cluster performance, availability, and security. Here's a practical and efficient daily checklist you can follow to monitor your HPC environment.

🔍 Daily HPC System Health Check Routine
1. Check Node Availability
Slurm:

bash

sinfo -R                # Show unavailable or drained nodes

sinfo -o "%N %t %E"     # Custom format: Node name, state, reason scontrol show node      
# Detailed per-node status
PBS/LSF (if used):
bash

qnodes                 # PBS
bhosts                 # LSF
2. Monitor Cluster Load & Job Queue
Slurm Job Queue:

bash

squeue                 # Check running/pending jobs
squeue -u <username>   # Check specific user's jobs
sstat -j <jobid>       # Job resource usage (live)
sacct --format=JobID,User,State,Elapsed,Timelimit,NCPUS,NodeList
Job Load Summary:

bash

sreport cluster utilization start=now-1days end=now
3. Check CPU/GPU & Memory Usage
Node-wise (SSH into nodes):

bash

top / htop             # Real-time usage
free -h                # Memory usage
nvidia-smi             # GPU usage (if applicable)
Automated Metrics (Grafana/Prometheus/Nagios):

Check dashboards for:

High load nodes

Idle nodes

Failing services

GPU utilization spikes or thermal warnings

4. Monitor Storage and File Systems
Parallel FS (BeeGFS, Lustre, GPFS, etc.):

bash

df -hT /mnt/beegfs       # Mount health
beegfs-ctl --listtargets --unreachables --state
lfs df -h                # Lustre space
mmlsfs all -L            # GPFS status
Quota & Usage:

bash

beegfs-ctl --getquota    # BeeGFS
lfs quota                # Lustre
5. Log Inspection
System Logs:

bash

journalctl -p 3 -xb      # Critical logs
tail -n 100 /var/log/messages
tail -n 100 /var/log/slurm/slurmctld.log
User Issues or Job Failures:

bash

grep -i "error" /var/log/slurm/job_* | tail
6. Monitor Network Interfaces
Check Network Health:

bash

ifconfig / ip a
ping -c 3 <head/compute node>
ibstat / ibstatus        # Infiniband status
Prometheus Node Exporter helps track:

Network latency

Packet errors or drops

7. Check Services and Daemons
Ensure Daemons Are Alive:
bash
systemctl status slurmctld
systemctl status slurmd
systemctl status munge
systemctl status prometheus
systemctl status grafana-server
Restart any failed ones:

systemctl restart <service>

8. Verify Alerts and Monitoring Dashboards
Open:
Grafana dashboards for trends
Nagios/Zabbix for triggered alerts
Email or Slack notifications from alertmanager

9. Security & Resource Usage Checks
Detect Rogue Processes / Mining:

ps aux | grep -E 'crypto|minerd|rig'
Verify Unusual Activity:

Sudden I/O spikes

Large job bursts

SSH access from unknown IPs:

last -i | head
✅ Optional: Automated Report Script
Write a script that runs checks and logs:

./daily_hpc_check.sh > /var/log/hpc_daily_report_$(date +%F).log
You can include:

uptime

sinfo

squeue

df -h

nvidia-smi
