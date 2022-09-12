# Tips and Tricks

* The logfile when creating and starting nodes are stored at  
  `/Library/Logs/Multipass/multipassd.log` and is helpful when debugging why a node
  will for example not start.  
  &nbsp;
* When you create many nodes the assign dynamic ip (192.168.64.xxx) can sometimes need to
  be reset. This is most easily done byt first stopping all instances and then delete the
  file `/var/db/dhcpd_leases`  
  &nbsp;
* Never ever use a `systemctl daemon-reload` in a cloud-init file. This will kill the SSH daemon
  and the multipass connection to the starting node will be lost.  
  &nbsp;
* The list command (`multipass list`) have an undocumented option `--no-ipv4` to exclude the IP
  in the output.  
  &nbsp;
* The cloud instantiation is recorded under `/var/lib/cloud` in the node. If a customized
  node is not working this is a good place to start troubleshooting. For example, in
  `/var/lib/cloud/instance/scripts/runcmd` is the run commands specified in the `RunCmd` extracted
  as shell commands.  
  &nbsp;
* Uninstall multipass by running  
  `sudo sh "/Library/Application Support/com.canonical.multipass/uninstall.sh"`  
  or  
  `brew uninstall --zap multipass`  
  &nbsp;
* Find available images `mp find`

