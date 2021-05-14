<#
.SYNOPSIS
    This script activates the SAP HANA Backups
.DESCRIPTION
	This script activates the SAP HANA Backups by registering the SAP HANA Instance, 
    enable protection and finally running the backups for the systemdb and tenant db.
	The script requires as prerequesite a successfully finished pre-registration script from here:
.EXAMPLE
    Test the script:
    $SID="MM6"
    $RGV="HANABackups"
    $RSV="hanabackupvault"
    $VM="hanatest06"
    $VMRG="rg-HANA-MM6"
    $POL="Non-PRD"

    ./Scripts/BackupEnable.ps1 -SID $SID -RGV $RGV -RSV $RSV -VM $VM -VMRG $VMRG -POL $POL

    some helpful commands:
    az backup protectable-item list -g HANABackups -v hanabackupvault --workload-type SAPHANA  --output table
    az backup container list -g HANABackups -v hanabackupvault --backup-management-type AzureIaasVM --output tsv
    az backup container list -g HANABackups -v hanabackupvault --backup-management-type AzureWorkload  --output tsv
.LINKs
    https://docs.microsoft.com/en-us/azure/backup/tutorial-sap-hana-backup-cli
	https://docs.microsoft.com/en-us/azure/backup/backup-azure-sap-hana-database 
.NOTES
    v0.1 - Initial version
#>

param(
    [Parameter(Mandatory = $true)][string]$SID,    
    [Parameter(Mandatory = $true)][string]$RGV,
    [Parameter(Mandatory = $true)][string]$RSV,
    [Parameter(Mandatory = $true)][string]$VM,
    [Parameter(Mandatory = $true)][string]$VMRG,
    [Parameter(Mandatory = $true)][string]$POL
)

$CONTAINER1="IaasVMContainer;iaasvmcontainerv2;$VMRG;$VM"
$CONTAINER2="VMAppContainer;Compute;$VMRG;$VM"
$ITEMSYS="saphanadatabase;$SID;systemdb"
$ITEMTEN="saphanadatabase;$SID;$SID"
$HANAPOL="HANA-$POL"
$OSPOL="OS-$POL"

Write-Host "-----------------------------------------------------"
Write-Host "-----------Get VM ID---------------------------------" 
Write-Host "VMID=az vm show -g $VMRG -n $VM --query id --output tsv" 
$VMID=az vm show -g $VMRG -n $VM --query id --output tsv
Write-Host "$VMID" -ForegroundColor Red
Write-Host "-----------------------------------------------------"
Write-Host ""

Write-Host "-----------------------------------------------------"
Write-Host "-----------Check if VM is OS backup enabled----------"  
Write-Host "az backup protection check-vm --vm $VMID" 
$PROTECT1=az backup protection check-vm --vm $VMID
Write-Host "-----------------------------------------------------"
Write-Host ""

    if ([string]::IsNullOrEmpty($PROTECT1)) {
        Write-Host "--------VM Backup will be enabled----------------" 
        Write-Host "az backup protection enable-for-vm -g $RGV -v $RSV --vm $VMID --policy-name $OSPOL"
        az backup protection enable-for-vm -g $RGV -v $RSV --vm $VMID --policy-name $OSPOL
        Write-Host "-----------------------------------------------------"
    }
    else {
        Write-Host ""
        Write-Host "--------VM Backup is already enabled-------------" 
        Write-Host ""
    }

Write-Host "-----------------------------------------------------" 
Write-Host "---------------List protectable HANA items-----------" 
Write-Host "az backup protectable-item  list -c '$CONTAINER2' -g $RGV -v $RSV --workload-type SAPHANA --output tsv" 
$PROTECT2=az backup protectable-item  list -c "$CONTAINER2" -g $RGV -v $RSV --workload-type SAPHANA --output tsv
Write-Host $PROTECT2
Write-Host "-----------------------------------------------------" 
Write-Host ""

Write-Host "-----------------------------------------------------"
Write-Host "-----Register the container if not yet in place -----" 

    if ([string]::IsNullOrEmpty($PROTECT2)) {
        Write-Host "---HANA Backup Container will be registered----------" 
        Write-Host "az backup container register -g $RGV -v $RSV --backup-management-type AzureWorkload --workload-type SAPHanaDatabase --resource-id $VMID" 
        az backup container register -g $RGV -v $RSV --backup-management-type AzureWorkload --workload-type SAPHanaDatabase --resource-id $VMID
        Write-Host "-----------------------------------------------------"
        Write-Host "------------------DB-Discovery-----------------------" 
        Write-Host "az backup protectable-item initialize -g $RGV -v $RSV --workload-type SAPHanaDatabase -c '$CONTAINER2'" 
        az backup protectable-item initialize -g $RGV -v $RSV --workload-type SAPHanaDatabase -c "$CONTAINER2"
        Write-Host "-----------------------------------------------------"
        Write-Host "-----------------------------------------------------"
        Write-Host "------------Enable SYSTEM DB Backups-----------------"  
        Write-Host "az backup protection enable-for-azurewl -g $RGV -v $RSV --policy-name $HANAPOL --protectable-item-name '$ITEMSYS' --protectable-item-type SAPHANADatabase --server-name $VM --workload-type SAPHanaDatabase" 
        az backup protection enable-for-azurewl -g $RGV -v $RSV --policy-name $HANAPOL --protectable-item-name "$ITEMSYS" --protectable-item-type SAPHANADatabase --server-name $VM --workload-type SAPHanaDatabase
        Write-Host ""
        Write-Host "------------Enable TENANT DB Backups-----------------"  
        Write-Host "az backup protection enable-for-azurewl -g $RGV -v $RSV --policy-name $HANAPOL --protectable-item-name '$ITEMTEN' --protectable-item-type SAPHANADatabase --server-name $VM --workload-type SAPHanaDatabase" 
        az backup protection enable-for-azurewl -g $RGV -v $RSV --policy-name $HANAPOL --protectable-item-name "$ITEMTEN" --protectable-item-type SAPHANADatabase --server-name $VM --workload-type SAPHanaDatabase
        Write-Host ""
    }
    else {
        Write-Host ""
        Write-Host "--------HANA Backup Container is already in place----" 
        Write-Host ""
    }

Write-Host "Uncomment following lines to activate immediate initial OS & HANA backups"
Write-Host "-----------------------------------------------------"
Write-Host "-------------------Run OS Backups------------------" 
# az backup protection backup-now -g $RGV -v $RSV -c $CONTAINER1 --item-name $VM
Write-Host ""
Write-Host "-----------------------------------------------------"
Write-Host "-------------------Run HANA Backups------------------" 
Write-Host "az backup protection backup-now -g $RGV -v $RSV --item-name '$ITEMSYS' --container-name '$CONTAINER' --backup-type full" 
# az backup protection backup-now -g $RGV -v $RSV --item-name "$ITEMSYS" --container-name "$CONTAINER" --backup-type full
Write-Host "az backup protection backup-now -g $RGV -v $RSV --item-name '$ITEMTEN' --container-name '$CONTAINER' --backup-type full" 
# az backup protection backup-now -g $RGV -v $RSV --item-name "$ITEMTEN" --container-name "$CONTAINER" --backup-type full
Write-Host ""
