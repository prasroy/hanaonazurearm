#!/bin/bash
#   VMSize="Standard_E16s_v3 (128 GB)" \
#set -x
echo "Reading config...." >&2
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi

#hanavmsize="Standard_E16s_v3 (128 GB)"
#hanavmsize="Standard_M128s (2 TB, Certified)"

az group create --name $rgname  --location "${location}"
echo "creating hana server"
az group deployment create \
--name HANADeployment \
--resource-group $rgname \
   --template-uri "https://raw.githubusercontent.com/prasroy/hanaonazurearm/master/azuredeploy.json" \
   --parameters \
   VMName="hanadev" \
   HANAJumpbox="no" \
   VMSize="Standard_E16s_v3 (128 GB)" \
   VMUserName=$vmusername \
   VMPassword=$vmpassword \
   OperatingSystem="SLES for SAP 12 SP3" \
   IPAllocationMethod="Static" \