# Terraform - Provision AKS Cluster

This repo provides a way to provision an Azure Kubernetes Service (AKS) via HashiCorp Terraform.

## Create an Active Directory service principal account
There are many ways to authenticate to the Azure provider. In this tutorial, you will use an Active Directory service principal account. You can learn how to authenticate using a different method [here](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure).

First, you need to create an Active Directory service principal account using the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli). 

You should see something like the following:

```
$ az ad sp create-for-rbac --skip-assignment
{
  "appId": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "displayName": "azure-cli-2019-04-11-00-46-05",
  "name": "http://azure-cli-2019-04-11-00-46-05",
  "password": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "tenant": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
}
```

## Update your terraform.tfvars file
Replace the values in your `terraform.tfvars` file with your appId and password. Terraform will use these values to authenticate to Azure before provisioning your resources. Your terraform.tfvars file should look like the following.

```
# terraform.tfvars
appId    = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
password = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
```

## Initialize Terraform
After you have saved your customized variables file, initialize your Terraform workspace, which will download the provider and initialize it with the values provided in your terraform.tfvars file.

```
$ terraform init
Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/random from the dependency lock file
- Reusing previous version of hashicorp/azurerm from the dependency lock file
- Installing hashicorp/random v3.0.0...
- Installed hashicorp/random v3.0.0 (signed by HashiCorp)
- Installing hashicorp/azurerm v2.42.0...
- Installed hashicorp/azurerm v2.42.0 (signed by HashiCorp)

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

## Provision the AKS cluster
In your initialized directory, run terraform apply and review the planned actions. Your terminal output should indicate the plan is running and what resources will be created.
```
$ terraform apply
An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create
```
Terraform will perform the following actions:
```
## Output truncated ...

Plan: 3 to add, 0 to change, 0 to destroy.

## Output truncated ...
```
You can see this terraform apply will provision an Azure resource group and an AKS cluster. Confirm the apply with a `yes`.

This process should take approximately 10 minutes. Upon successful application, your terminal prints the outputs defined in `aks-cluster.tf`.

```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

kubernetes_cluster_name = light-eagle-aks
resource_group_name = light-eagle-rg
```

##  Configure kubectl
Now that you've provisioned your AKS cluster, you need to configure `kubectl`.

Run the following command to retrieve the access credentials for your cluster and automatically configure kubectl.
```
$ az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw kubernetes_cluster_name)
Merged "light-eagle-aks" as current context in /Users/dos/.kube/config
```
The [resource group name](https://github.com/hashicorp/learn-terraform-provision-aks-cluster/blob/master/outputs.tf#L1) and [Kubernetes Cluster](https://github.com/hashicorp/learn-terraform-provision-aks-cluster/blob/master/outputs.tf#L5) name correspond to the output variables showed after the successful Terraform run.

»Access Kubernetes Dashboard
To verify that your cluster is configured correctly and running, you will navigate to it in your local browser.

We need to create a `ClusterRoleBinding` to use the Kubernetes dashboard. This gives the `cluster-admin` permission to access the `kubernetes-dashboard`. While you can create this using Terraform, `kubectl` is used in this tutorial so you don't need to configure your Terraform Kubernetes Provider.
```
$ kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard --user=clusterUser
clusterrolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
```
Finally, to access the Kubernetes dashboard, run the following command, customized with your cluster name instead of light-eagle-. This will continue running until you stop the process by pressing CTRL + C.

```$ az aks browse --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw kubernetes_cluster_name)
Merged "light-eagle-aks" as current context in /var/folders/s6/m22_k3p11z104k2vx1jkqr2c0000gp/T/tmpcrh3pjs_
Proxy running on http://127.0.0.1:8001/
Press CTRL+C to close the tunnel...
```
You should be able to access the Kubernetes dashboard at http://127.0.0.1:8001/.

To authenticate to the dashboard, first generate the authorization token in another tab (do not close the previous process).
```
$ kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep service-controller-token | awk '{print $1}')

Name:         service-controller-token-46qlm
Namespace:    kube-system
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: service-controller
              kubernetes.io/service-account.uid: dd1948f3-6234-11ea-bb3f-0a063115cf22

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1765 bytes
namespace:  11 bytes
token:      eyJhbGciOiJSUzI1NiIsImtpZCI6I...
```
Select "Token" on the Dashboard UI then copy and paste the entire token you receive into the [dashboard authentication screen](http://127.0.0.1:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#/login) to sign in. You are now signed in to the dashboard for your Kubernetes cluster.

AKS Dashboard