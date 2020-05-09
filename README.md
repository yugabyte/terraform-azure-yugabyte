# terraform-azure-yugabyte
A Terraform module to deploy and run YugabyteDB on Microsoft Azure Cloud.

## Configuration
* To insatll terraform and configure it for Azure follow steps given [here](https://docs.microsoft.com/en-gb/azure/virtual-machines/linux/terraform-install-configure)

* Export the required credentials in current shell
  ```sh
  echo "Setting environment variables for Terraform"
  export ARM_SUBSCRIPTION_ID="your_subscription_id"
  export ARM_CLIENT_ID="your_appId"
  export ARM_CLIENT_SECRET="your_password"
  export ARM_TENANT_ID="your_tenant_id"
  ```
  <!-- The above code snippet is from
  https://github.com/MicrosoftDocs/azure-docs/blob/eb381218252a33fb8b63e1163b6a39cd4b1835ef/articles/terraform/terraform-install-configure.md#configure-terraform-environment-variables
  which is licensed under the MIT
  license. https://github.com/MicrosoftDocs/azure-docs/blob/master/LICENSE-CODE
  -->

* Create a new directory along with a terraform file
  ```sh
  $ mkdir yugabytedb-deploy && cd yugabytedb-deploy
  $ touch deploy.tf
  ```
* Open `deploy.tf` in your favorite editor and add following content to
  it
  ```hcl
  module "yugabyte-db-cluster" {
	source = "github.com/yugabyte/terraform-azure-yugabyte.git"

	# The name of the cluster to be created.
	cluster_name = "test-yugabyte"

	# key pair.
	ssh_private_key = "PATH_TO_SSH_PRIVATE_KEY_FILE"
	ssh_public_key  = "PATH_TO_SSH_PUBLIC_KEY_FILE"
	ssh_user        = "SSH_USER_NAME"

	# The region name where the nodes should be spawned.
	region_name = "YOUR VPC REGION"

	# The name of resource  group in which all Azure resource will be created.
	resource_group = "test-yugabyte"

	# Replication factor.
	replication_factor = "3"

	# The number of nodes in the cluster, this cannot be lower than the replication factor.
	node_count = "3"
  }

  output "ui" {
	value = "${module.yugabyte-db-cluster.ui}"
  }

  # You can add other outputs from output.tf here
  ```

## Usage

Init terraform first if you have not already done so.

```
$ terraform init
```

To check what changes are going to happen in the environment run the following 

```
$ terraform plan
```

Now run the following to create the instances and bring up the cluster.

```
$ terraform apply
```

Once the cluster is created, you can go to the URL `http://<node ip or dns name>:7000` to view the UI. You can find the node's public IP by running the following:

```
$ terraform state show module.yugabyte-db-cluster.azurerm_public_ip.YugaByte_Public_IP[0]
```

You can access the cluster UI by going to public IP address of any of the instances at port `7000`. The IP address can be viewed by replacing `0` from above command with desired index.

You can check the state of the nodes at any point by running the following command.

```
$ terraform show
```

To destroy what we just created, you can run the following command.

```
$ terraform destroy
```
`Note:- To make any changes in the created cluster you will need the terraform state files. So don't delete state files of Terraform.`

## Migrating from old versions
### Changes in #6 (terraform 0.12.x and azurerm 2.x)
In order to migrate to the latest revision of this module which uses terraform `0.12.x` and azurerm `2.x`,
* Download [latest version](https://www.terraform.io/downloads.html) of terraform which is >= `0.12`
* Remove the `provider "azurerm" {}` block from your terraform file and set the credentials by following the instructions [here](#configuration).
* Pull the latest code of yugabyte-db-cluster module.
  ```sh
  $ terraform get -update
  ```
* Get the latets versions of the dependencies.
  ```sh
  $ terraform init
  ```
* Download the migration script in same directory as of your terraform files.
  ```sh
  $ curl -O -L https://raw.githubusercontent.com/yugabyte/terraform-azure-yugabyte/master/hack/azurerm_1.x_to_2.x.sh
  $ chmod +x azurerm_1.x_to_2.x.sh
  ```
* Run the script as `./azurerm_1.x_to_2.x.sh <number of nodes>`
  ```console
  $ ./azurerm_1.x_to_2.x.sh 3
  …
  Importing 'module.yugabyte-db-cluster.azurerm_network_interface_security_group_association.YugaByte-NIC-SG-Association[2]'.
  module.yugabyte-db-cluster.azurerm_network_interface_security_group_association.YugaByte-NIC-SG-Association[2]: Importing from ID "<networkInterfaceID>|<networkSecurityGroupId>"...
  module.yugabyte-db-cluster.azurerm_network_interface_security_group_association.YugaByte-NIC-SG-Association[2]: Import prepared!
	Prepared azurerm_network_interface_security_group_association for import
  module.yugabyte-db-cluster.azurerm_network_interface_security_group_association.YugaByte-NIC-SG-Association[2]: Refreshing state... [id=<networkInterfaceID>|<networkSecurityGroupId>]

  Import successful!

  The resources that were imported are shown above. These resources are now in
  your Terraform state and will henceforth be managed by Terraform.
  ```
* Run terraform apply to update the state correctly.
  ```sh
  $ terraform apply
  ```

