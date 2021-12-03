# Virtualize scripts

```bash
sudo su - 

# 1. Ensure /dev/sda exists and is not partitioned
# 2. Ensure livecd has functional network
# 3. Ensure livecd can connect to remote server
## ssh-keygen -t rsa 
## ssh-copy-id -i /root/id_rsa.pub root@source.example.com

# 4. Clone scripts
git clone git@github.com:lukasic/linux-virtualize-scripts.git migr
cd migr

# 5. Run migration
./migr source.example.com

# 6. shutdown old server
# 7. reboot new server
```
