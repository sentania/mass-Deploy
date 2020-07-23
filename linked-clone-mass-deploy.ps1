 #region VARIABLE BLOCK

$vcenterServer = "vcenter.int.sentania.net"
$targetDatastore = "vsanDatastore"
$cluster = "Cluster 1"
$targetVMCount = 100
$baseVM = "centOS7-template"
# Fake array of systems
$vmtarget = 150
# Maximum Number Of Threads
$maxthreads = 15
#endregion

$scriptblock = { 
Function New-VMLinkedClone ($vcenterServer, $targetVM, $baseVM, $targetDatastore, $resourcePool, $basesnapshot) {
        
    
    ### Connect vSphere
    $myCredential = import-clixml -Path "C:\temp\credential.xml"
    Connect-VIServer -server $vCenterserver -Credential $myCredential
    $LinkedClone = New-VM -Name "linked-clone-$pid" -VM $BaseVM -Datastore $TargetDatastore -ResourcePool $ResourcePool -LinkedClone -ReferenceSnapshot $basesnapshot
    write-host "Linked clone $TargetVM created" -ForegroundColor Green
    $linkedClone | start-vm
    $link
    
}

}



#$credential = get-credential
#$credential | Export-Clixml -Path "C:\temp\credential.xml"




# For This Example, Display the Parent Windows Process ID
write-host "Parent Window Process Id: $pid"

    ### Check if there is already a linkedclone snapshot for the clone and delete it
    $SnapshotExists = Get-Snapshot -VM $BaseVM
 
    if ($SnapshotExists.Name -eq "Linked-Snapshot-for-Mass-Deploy") {
        Write-Host "Linked-Snapshot-for-$TargetVMs already exists" -ForegroundColor red
        Read-Host -Prompt "Press any key to delete the snapshot and continue or CTRL+C to quit"
 
        $ExistingSnapshot = Get-Snapshot -VM $BaseVM -Name "Linked-Snapshot-for-Mass-Deploy"
        Remove-Snapshot -Snapshot $ExistingSnapshot -Confirm:$false
        sleep 10
        write-host "Old snapshot deleted" -ForegroundColor Green
    }
     ### Create Master Snapshot
    $SnapShot = New-Snapshot -VM $BaseVM -Name "Linked-Snapshot-for-Mass-Deploy" -Description "Snapshot for linked clones for Mass Deploy" -Memory -Quiesce
    Write-Host "Snapshot create on $BaseVM" -ForegroundColor Green
 

#loop through each of the systems in the $allsystems array.
$count = 1
while ($count -le $vmtarget) {
    
    # Determine how many active child processes there are
    $activescripts = get-wmiobject win32_process | Where {$_.ParentProcessID -eq $pid} | Select Name
    
    # If the number of active processes is greater or equal to $maxthreads, wait 15 secs, reevaluate
    while ($activescripts.count -ge $maxthreads) {
        
        # Pause for 5 seconds before rechecking
        start-sleep -Seconds 5

        # Wait for Queue to Open - Query the current script Process ID ($pid) to see if any of the child scripts are still running.
        $activescripts = get-wmiobject win32_process | Where {$_.ParentProcessID -eq $pid } | Select Name
        
    }

    Start-Process PowerShell.exe -ArgumentList "-Command",$scriptblock,"New-VMLinkedClone $vCenterServer $count $baseVM $targetDatastore '$cluster' $SnapShot"
    $count++
}