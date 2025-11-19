#!/bin/bash
# Set your central monitoring cluster and credentials
ES_URL="https://central-coe-cluster"

# Requires create_index and write privilege on ES_INDEX on central monitoring cluster
ES_USER="write_license"
ES_PASS="P@ssw0rd"
ES_INDEX="cluster_license_summary"

#Requires cluster:monitor privilege on remote cluster
REMOTE_USER="get_license"
REMOTE_PASS="P@ssw0rd"

# Check for dependencies
if ! command -v curl &> /dev/null; then
    echo "Error: 'curl' is not installed. Please install it to run this script." >&2
    exit 1
fi
if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' is not installed. Please install it to run this script." >&2
    echo "e.g., 'sudo yum install jq' or 'sudo dnf install jq'" >&2
    exit 1
fi
# List of remote clusters
CLUSTERS=(
    "remote1" 
	"remote2" 
	"remote3" 
	"remote4"
)


for CLUSTER in "${CLUSTERS[@]}"; do
  # Get cluster stats
  CLUSTER_STATS=$(curl -s -u "$REMOTE_USER:$REMOTE_PASS" "$CLUSTER/_cluster/stats")
  # Get license info
  LICENSE=$(curl -s -u "$REMOTE_USER:$REMOTE_PASS" "$CLUSTER/_license")
  # Get node stats
  NODE_STATS=$(curl -s -u "$REMOTE_USER:$REMOTE_PASS" "$CLUSTER/_nodes/stats")
  # Parse required fields using jq
  CLUSTER_NAME=$(echo "$CLUSTER_STATS" | jq -r '.cluster_name')
  LICENSE_TYPE=$(echo "$LICENSE" | jq -r '.license.type')
  RESOURCE_UNIT=$(echo "$LICENSE" | jq -r '.license.max_resource_units')
  TOTAL_RAM=$(echo "$NODE_STATS" | jq '[.nodes[].os.mem.total_in_bytes] | add')
  NO_OF_NODES=$(echo "$NODE_STATS" | jq '.nodes | length')
  # Convert total_ram to gigabytes (rounded up)
  TOTAL_RAM_GB=$(( (TOTAL_RAM + 1073741823) / 1073741824 ))
  # Calculate ERU
  if [[ "$LICENSE_TYPE" == "enterprise" ]]; then
    ERU=$(( (TOTAL_RAM_GB + 63) / 64 ))
  else
    ERU=0
  fi
  # Prepare the document
  DOC=$(jq -n \
    --arg cluster_name "$CLUSTER_NAME" \
    --arg license_type "$LICENSE_TYPE" \
    --arg resource_unit "$RESOURCE_UNIT" \
    --argjson total_ram "$TOTAL_RAM" \
    --argjson total_ram_gb "$TOTAL_RAM_GB" \
    --argjson ERU "$ERU" \
    --argjson no_of_nodes "$NO_OF_NODES" \
    --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    '{
      cluster_name: $cluster_name,
      license_type: $license_type,
      resource_unit: $resource_unit,
      total_ram: $total_ram,
      total_ram_gb: $total_ram_gb,
      ERU: $ERU,
      no_of_nodes: $no_of_nodes,
      "@timestamp": $timestamp
    }')
  # Index the document into Elasticsearch
  curl -s -u "$ES_USER:$ES_PASS" -H "Content-Type: application/json" \
    -XPOST "$ES_URL/$ES_INDEX/_doc" -d "$DOC"

done
