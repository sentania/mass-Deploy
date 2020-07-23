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

$credential = get-credential
$credential | Export-Clixml -Path "C:\temp\credential.xml"

#Create script block
$scriptblock = { 
function deployVM ($mycount)
{
Write-host "Loading subscript, Loop $mycount" -ForegroundColor Green
$myCredential = import-clixml -Path "C:\temp\credential.xml"

Write-host "Connecting to vCenter...." -ForegroundColor Green

$vConnection = connect-viserver -server vcenter.int.sentania.net -Credential $myCredential -ErrorAction Continue ####CHANGE ME

Write-host "Deploying VM...." -ForegroundColor Green
$myVM = New-VM -ContentLibraryItem 'centos7Template' -Name "fullclone-$pid" -ResourcePool (Get-Cluster -name 'Cluster 1') -DiskStorageFormat Thin -Datastore (Get-Datastore -Name 'vsanDatastore') -ErrorAction Continue

Write-host "Starting VM..." -ForegroundColor Green
$myVM | Start-VM -ErrorAction Continue
}

}




$count = 1

# For This Example, Display the Parent Windows Process ID
write-host "Parent Window Process Id: $pid"

#loop through each of the systems in the $allsystems array.
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

    Start-Process PowerShell.exe -ArgumentList "-Command",$scriptblock,"deployVM($count)"
   $count++
}