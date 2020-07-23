 #region VARIABLE BLOCK

$vcenterServer = "vcva.far-away.galaxy"
$targetDatastore = "Scarif-Flash1"
$cluster = "Raxus Prime"
$targetVMCount = 3
$baseVM = "photon_minimal_template"

# Fake array of systems
$vmtarget = 3
# Maximum Number Of Threads
$maxthreads = 1
#endregion
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()
Write-host "Start time: " $date
#Run this one time to store passord
#$vCenterUser="administrator@vsphere.local"
#Get-Credential -Message "Enter $vcenterUser password to store." -UserName $vCenterUser |export-clixml -path "c:\temp\credential.xml"

#Create script block
$scriptblock = { 
    function deployVM ($vcenterServer, $Cluster, $targetDatastore, $baseVM, $mycount)
    {
        Write-host "Loading subscript, Loop $mycount" -ForegroundColor Green
        $myCredential = import-clixml -Path "C:\temp\credential.xml"
        Write-host "Connecting to vCenter...." -ForegroundColor Green
        $vConnection = connect-viserver -server $vcenterServer -Credential $myCredential -ErrorAction Continue
        Write-host "Deploying VM...." -ForegroundColor Green
        #$myVM = New-VM -ContentLibraryItem 'centos7Template' -Name "fullclone-$pid" -ResourcePool (Get-Cluster -name 'Cluster 1') -DiskStorageFormat Thin -Datastore (Get-Datastore -Name 'vsanDatastore') -ErrorAction Continue
        $myVM = New-VM -Template $baseVM -Name "fullclone-$pid" -ResourcePool (Get-Cluster -name $Cluster) -DiskStorageFormat Thin -Datastore (Get-Datastore -Name $targetDatastore) -ErrorAction Continue
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
    write-host "Starting Loop: $count"
    Start-Process PowerShell.exe -ArgumentList "-Command",$scriptblock,"deployVM '$vcenterServer' '$Cluster' '$targetDatastore' '$baseVM' $mycount"
   $count++
}
$stopwatch
write-host "Stop time: " $date
$stopwatch.stop()
