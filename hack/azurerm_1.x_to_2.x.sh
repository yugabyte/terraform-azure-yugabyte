#!/usr/bin/env bash

# This script can be used to migrate from azurerm version 1.x to 2.x.
# To check if you have 1.x, run the following command.
#
# $ terraform version
# Terraform v0.11.14
# + provider.azurerm v1.44.0
# + provider.null v2.1.2
#
# Make sure you update to a terraform version which is >= 0.12.0
#
# Pull the latest code of yugabyte-db-cluster module.
#
# $ terraform get -update
#
# Get the latets versions of the dependencies
#
# $ terraform init
#
# Now put this script in same directory as of your terraform files,
# and execute it
#
# ./azurerm_1.x_to_2.x.sh
#
# Run terraform apply to update the state correctly
#
# $ terraform apply

node_count="${1:-3}"

if [[ -z "$(which jq 2>/dev/null)" ]]; then
  echo "jq: command not found. This script depends on jq." 1>&2
  exit 1
fi

security_group_id="$(terraform show -json \
  | jq -r '.values.root_module.child_modules[0].resources[]
    | select(.address == "azurerm_network_security_group.YugaByte-SG")
    | .values.id')"

for ((index=0; index < $((node_count)); index++)); do
  interface_id="$(terraform show -json \
    | jq --arg index "${index}" -r \
      '.values.root_module.child_modules[0].resources[]
      | select(.address == "azurerm_network_interface.YugaByte-NIC" and .index == ($index|tonumber))
      | .values.id')"
  resoure_address="module.yugabyte-db-cluster.azurerm_network_interface_security_group_association.YugaByte-NIC-SG-Association[${index}]"
  echo "Importing '${resoure_address}'."
  terraform import \
    "${resoure_address}" \
    "${interface_id}|${security_group_id}"
done
