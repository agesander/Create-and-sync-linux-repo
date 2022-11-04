# Create-and-sync-linux-repo
Script that create and synchronize Linux local repositories

You can use script `rsync_repo.sh` for creating your own local linux repositories.

For regular updating downloaded repositories, add this script to cron:
```
# Update repo every Sunday
0 1 * * sun /root/scripts/rsync_repo.sh >> /dev/null 2>&1
```
