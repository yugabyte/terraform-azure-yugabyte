# terraform-azure-yugabyte
A Terraform module to deploy and run YugabyteDB on Microsoft Azure Cloud.

## Config
* First create a terraform file with provider details 
  ```
  provider "azurerm" 
  { 
    # Provide your Azure Creadentilals 
    subscription_id = "AZURE_SUBSCRIPTION_ID"
    client_id       = "AZURE_CLIENT_ID"
    client_secret   = "AZURE_CLIENT_SECRET"
    tenant_id       = "AZURE_TENANT_ID"
  }
  ```
  Note :- To insatll terraform and configure it for Azure follow steps given [here](https://docs.microsoft.com/en-gb/azure/virtual-machines/linux/terraform-install-configure)

* Now add the yugabyte terraform module to your file 
  ```
  module "yugabyte-db-cluster" {
  source = "github.com/YugaByte/terraform-azure-yugabyte.git"

  # The name of the cluster to be created.
  cluster_name = "test-yugabyte"

  # key pair.
  ssh_private_key = "SSH_PRIVATE_KEY_HERE"
  ssh_public_key = "SSH_PUBLIC_KEY_HERE"
  ssh_user = "SSH_USER_NAME_HERE"

  # The region name where the nodes should be spawned.
  region_name = "YOUR VPC REGION"

  # The name of resource  group in which all Azure resource will be created. 
  resource_group = "test-yugabyte"

  # Replication factor.
  replication_factor = "3"

  # The number of nodes in the cluster, this cannot be lower than the replication factor.
  node_count = "3"
  }
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

Once the cluster is created, you can go to the URL `http://<node ip or dns name>:7000` to view the UI. You can find the node's ip or dns by running the following:

```
$ terraform state show azurerm_virtual_machine.YugaByte-Node[0]
```

You can access the cluster UI by going to any of the following URLs.

You can check the state of the nodes at any point by running the following command.

```
$ terraform show
```

To destroy what we just created, you can run the following command.

```
$ terraform destroy
```
`Note:- To make any changes in the created cluster you will need the terraform state files. So don't delete state files of Terraform.`
