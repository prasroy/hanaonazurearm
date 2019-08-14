# HANA on Azure with ARM Depoloyment

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fprasroy%2Fhanaonazurearm%2Fmaster%2Fazuredeploy.json)

## Machine Info
The template currently deploys HANA on one of the machines listed in the table below with the noted disk configuration.  The deployment takes advantage of Managed Disks, for more information on Managed Disks or the sizes of the noted disks can be found on [this](https://docs.microsoft.com/en-us/azure/storage/storage-managed-disks-overview#pricing-and-billing) page.

Machine Size | RAM | Data and Log Disks | /hana/shared | /root | /usr/sap | hana/backup
------------ | --- | ------------------ | ------------ | ----- | -------- | -----------
E16 | 64 GB | 4 x P10 | 1 x P6 | 1 x P4 | 1 x P6 | 1 x P10
E16 | 128 GB | 4 x P10 | 1 x P10 | 1 x P4 | 1 x P6 | 1 x P10
E32 | 256 GB | 4 x P15 | 1 x P15 | 1 x P4 | 1 x P6 | 1 x P15
E64 | 432 GB | 4 x P20 | 1 x P20 | 1 x P4 | 1 x P6 | 1 x P20

### Deploy from Powershell

```powershell
New-AzureRmResourceGroup -Name HANADeploymentRG -Location "Central US"
New-AzureRmResourceGroupDeployment -Name HANADeployment -ResourceGroupName HANADeploymentRG `
  -TemplateUri https://raw.githubusercontent.com/prasroy/hanaonazurearm/master/azuredeploy.json `
  -VMName HANAtestVM -HANAJumpbox yes -VMPassword AweS0me@PW
```

### Deploy from CLI
```
az login

az group create --name HANADeploymentRG --location "Central US"
az group deployment create \
    --name HANADeployment \
    --resource-group HANADeploymentRG \
    --template-uri "https://raw.githubusercontent.com/prasroy/hanaonazurearm/master/azuredeploy.json" \
    --parameters VMName=HANAtestVM HANAJumpbox=yes VMPassword=AweS0me@PW
```

## To remove a particular host key from SSH's known_hosts file
ssh-keygen -R 'hostname'.westeurope.cloudapp.azure.com

