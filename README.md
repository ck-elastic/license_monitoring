# license_monitoring
Shell script to call remote clusters for license and node info to be monitored on a central cluster

Requires a monitoring user with create_index and write privilege on the monitoring index (ES_INDEX variable in the script) on central monitoring cluster
Requires a remote user with cluster:monitor privilege on the remote clusters to be monitored.

Any suggestions to improve this are welcomed.
