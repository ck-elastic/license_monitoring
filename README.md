# license_monitoring
Shell script to call remote clusters for license and node info to be monitored on a central cluster
# Credentials
1. Requires a monitoring user with create_index and write privilege on the monitoring index (ES_INDEX variable in the script) on central monitoring cluster
2. Requires a remote user with cluster:monitor privilege on the remote clusters to be monitored.

Secrets management to be handled by customer with their tool of choice.

Any suggestions to improve this are welcomed.
