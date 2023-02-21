<#
Storyline: This PowerShell Module file contains functions that are used to Create and Delete Clones on vCenter
Author: Quentin DeGiorgio

TODO:
- Make baseClone() add clones to BASE-VM folder 
- Have fullClone() add clones to DEV folder
#>

function 480Banner() {
    Clear-Host
    $banner = @"
    _______   ___________    ____    ______    .______     _______.
    |       \ |   ____\   \  /   /  /  __  \   |   _  \   /       |
    |  .--.  ||  |__   \   \/   /  |  |  |  |  |  |_)  | |   (----`
    |  |  |  ||   __|   \      /   |  |  |  |  |   ___/   \   \
    |  '--'  ||  |____   \    /    |   `--'  |  |  |   .----)   |
    |_______/ |_______|   \__/      \______/   | _|   |_______/
                                             
"@ 
    Write-Host $banner      
}

function intMenu([string[]] $folder) {
    Write-Host "Select Option"
    Write-Host "[0] Exit"
    Write-Host "[1] Virtual Machine Management" 
    Write-Host "[2] vCenter Network Management"
    Write-Host ""
    $menuInput = Read-Host 'Which index number [x] do you wish to pick?'
    if ($menuInput -eq "1"){
        Clear-Host
        vmMenu
    }elseif($menuInput -eq '2'){
        Clear-Host
        networkMenu
    }elseif($menuInput -eq '0'){
        Clear-Host
        Exit
    }else{
        Write-Host -ForegroundColor "Red" "Invalid Option. Please Select a valid index number [x]."
        Start-Sleep -Seconds 1.5
        Clear-Host
        intMenu
    }

}

function vmMenu([string[]] $folder) {
    Write-Host "Select Option"
    Write-Host "[0] Main Menu"
    Write-Host "[1] Create Clone" 
    Write-Host "[2] Delete VM"
    Write-Host "[3] Retreive VM Networking"
    Write-Host ""
    $menuInput = Read-Host 'Which index number [x] do you wish to pick?'
    if ($menuInput -eq "1"){
        cloneMenu
    }elseif($menuInput -eq '2'){
        selectDelete
    }elseif($menuInput -eq '0'){
        Clear-Host
        intMenu
    }elseif($menuInput -eq '3'){
        Clear-Host
        vmNetworking
    }else{
        Write-Host -ForegroundColor "Red" "Invalid Option. Please Select a valid index number [x]."
        Start-Sleep -Seconds 1.5
        Clear-Host
        vmMenu
    }

}

# vCenter Management Menu
function networkMenu(){
    Write-Host "Select Option"
    Write-Host "[0] Main Menu"
    Write-Host "[1] List Virtual Switches and Portgroups" 
    Write-Host "[2] Create Virtual Switch"
    Write-Host "[3] Create Virtual Portgroup"
    Write-Host "[4] Delete Virtual Switch"
    Write-Host "[5] Delete Virtual Portgroup"
    Write-Host ""
    $menuInput = Read-Host 'Which index number [x] do you wish to pick?'
    if ($menuInput -eq "0"){
        Clear-Host
        intMenu
    }elseif($menuInput -eq '1'){
        $listVS = Get-VirtualSwitch
        $listPG = Get-VirtualPortGroup
        Write-Host ""
        Write-Host "Virtual Switches:"
        foreach ($item in $listVS) {Write-Host $item } 
        Write-Host ""
        Write-Host "Port Groups:"
        foreach ($item in $listPG) {Write-Host $item }
        Write-Host
        networkMenu
    }elseif($menuInput -eq '2'){
        Clear-Host
        newVSwitch
    }elseif($menuInput -eq '3'){
        Clear-Host
        newVPort
    }elseif($menuInput -eq '4'){
        Clear-Host
        delVSwitch
    }elseif($menuInput -eq '5'){
        Clear-Host
        delVPort
    }else{
        Write-Host -ForegroundColor "Red" "Invalid Option. Please Select a valid index number [x]."
        Start-Sleep -Seconds 1.5
        Clear-Host
        networkMenu
    }
}

# Connect to vCenter
function 480Connect() {
    $config_path= "/home/q/Documents/techJournal/SYS-480-DevOps/480.json"
    $conn = $global:DefaultVIServer
    if ($conn){
        $msg = "Already Connected to: {0}" -f $conn
        Write-Host -ForegroundColor Green $msg 
        Write-Host ""
    }else {
        Write-Host "Login to vCenter"
        $conn = Connect-VIServer -Server "vcenter.quentin.local"
    }

}

# Grab Config from JSON
function get480Config() {
    $config_path= "/home/q/Documents/techJournal/SYS-480-DevOps/480.json"
    if(Test-Path $config_path){
        $conf = (Get-Content -Raw -Path $config_path | ConvertFrom-Json)
        $msg = "Using Configuration from {0}" -f $config_path
        Write-Host -ForegroundColor "Green" $msg
        Write-Host ""
    } else {
        Write-Host -ForegroundColor "Yellow" "No Configuration"
        Write-Host ""
    }
    return $conf
}

# Menu options for clones + Selection
function cloneMenu() {
    Clear-Host 
    Write-Host "Options"
    Write-Host "[0] Main Menu"
    Write-Host "[1] Linked Clone"
    Write-Host "[2] Base Clone (Base Snpshot Required)" 
    Write-Host "[3] Full Clone (Base Clone Required)"
    Write-Host ""
    $menuInput = Read-Host 'Which index number [x] do you wish to pick?'
    if ($menuInput -eq "0"){
        Clear-Host
        intMenu
    }elseif($menuInput -eq '1'){
        linkedClone1
    }elseif($menuInput -eq '2'){
        baseClone
    }elseif($menuInput -eq '3'){
        fullClone
    }else{
        Write-Host -ForegroundColor "Red" "Invalid Option. Please Select a valid index number [x]."
        Start-Sleep -Seconds 1.5
        Clear-Host
        cloneMenu
    }
}

# Used to create Base Clones - Will list ALL VMs excluding BASE-VM Folder
function baseClone() {
    #$config = (Get-Content -Raw -Path "/home/q/Documents/techJournal/SYS-480-DevOps/480.json" | ConvertFrom-Json)
    Clear-Host
    Write-Host "Options"
    Write-Host "[0] Main Menu"
    $selectedVM = $null
        $vms = Get-VM | Where-Object { $_.Name -notlike '*base'} #Get-VM -Location $config.folder 
        $index = 1
        foreach($vm in $vms) {
            Write-Host  "[$index] $($vm.name)"
            $index+=1
        }
        Write-Host ""
        $vmInput = Read-Host 'Which index number [x] do you wish to use to create a Base Clone?'
        # could make check a function
        if ($vmInput -match '^\d+$') {
            $key = [int]$vmInput - 1
            if ($key -lt 0) {
                Clear-Host
                intMenu
            }elseif($key -ge $vms.Count){
                Write-Host -ForegroundColor "Red" "Invalid Index ID. Please select a valid Index ID to create a Base Clone"
                Start-Sleep -Seconds 1.5
                baseClone #-folder $config.folder
            }else {
                $selectedVM = $vms[$key]
                Write-Host ""
                Write-Host "You picked $($selectedVM.name)."
                $confirm = Read-Host -Prompt "Are you sure you want to clone the selected virtual machine (Y/N)? "
                if ($confirm -eq "Y" -or $confirm -eq "y" -or $confirm -eq "yes"-or $confirm -eq "Yes") {
                    Clear-Host
                    createLinkedClone $selectedVM
                } else {
                  Clear-Host
                  Write-Host "Cloning cancelled. Please select a valid Index ID to create a Base Clone"
                  baseClone #-folder $config.folder
                }
            }
        }else{
            Write-Host -ForegroundColor "Red" "Invalid Index ID. Please select a valid Index ID to create a Base Clone"
            Start-Sleep -Seconds 1.5
            baseClone
        }
}

# Used to create Full Clones - Will list ONLY VMs in BASE-VM Folder
function fullClone() {
    $config = (Get-Content -Raw -Path "/home/q/Documents/techJournal/SYS-480-DevOps/480.json" | ConvertFrom-Json)
    Clear-Host
    Write-Host "Options"
    Write-Host "[0] Main Menu"
    $selectedVM = $null
        $vms = Get-VM -Location $config.folder
        $index = 1
        foreach($vm in $vms) {
            Write-Host  "[$index] $($vm.name)"
            $index+=1
        }
        Write-Host ""
        $vmInput = Read-Host 'Which index number [x] do you wish to use to create a Full Clone?'
        # could make check a function
        if ($vmInput -match '^\d+$') {
            $key = [int]$vmInput - 1
            if ($key -lt 0) {
                Clear-Host
                intMenu
            }elseif($key -ge $vms.Count){
                Write-Host -ForegroundColor "Red" "Invalid Index ID. Please select a valid Index ID to create a Full Clone"
                Start-Sleep -Seconds 1.5
                fullClone -folder $config.folder
            }else {
                $selectedVM = $vms[$key]
                Write-Host ""
                Write-Host "You picked $($selectedVM.name)."
                $confirm = Read-Host -Prompt "Are you sure you want to clone the selected virtual machine (Y/N)? "
                if ($confirm -eq "Y" -or $confirm -eq "y" -or $confirm -eq "yes"-or $confirm -eq "Yes") {
                    Clear-Host
                    createLinkedClone $selectedVM
                } else {
                  Clear-Host
                  Write-Host "Cloning cancelled. Please select a valid Index ID to create a Full Clone"
                  fullClone #-folder $config.folder
                }
            }
        }else{
            Write-Host -ForegroundColor "Red" "Invalid Index ID. Please select a valid Index ID to create a Full Clone"
            Start-Sleep -Seconds 1.5
            fullClone
        }
}

# Used to create linked Clones - Will list ALL VMs
function linkedClone1() {
    $config = (Get-Content -Raw -Path "/home/q/Documents/techJournal/SYS-480-DevOps/480.json" | ConvertFrom-Json)
    Clear-Host
    Write-Host "Options"
    Write-Host "[0] Main Menu"
    $selectedVM = $null
        $vms = Get-VM #-Location $config.folder
        $index = 1
        foreach($vm in $vms) {
            Write-Host  "[$index] $($vm.name)"
            $index+=1
        }
        Write-Host ""
        $vmInput = Read-Host 'Which index number [x] do you wish to use to create a Linked Clone?'
        # could make check a function
        if ($vmInput -match '^\d+$') {
            $key = [int]$vmInput - 1
            if ($key -lt 0) {
                Clear-Host
                intMenu
            }elseif($key -ge $vms.Count){
                Write-Host -ForegroundColor "Red" "Invalid Index ID. Please select a valid Index ID to create a Full Clone"
                Start-Sleep -Seconds 1.5
                linkedClone1 #-folder $config.folder
            }else {
                $selectedVM = $vms[$key]
                Write-Host ""
                Write-Host "You picked $($selectedVM.name)."
                $confirm = Read-Host -Prompt "Are you sure you want to clone the selected virtual machine (Y/N)? "
                if ($confirm -eq "Y" -or $confirm -eq "y" -or $confirm -eq "yes"-or $confirm -eq "Yes") {
                    Clear-Host
                    linkedClone $selectedVM
                } else {
                  Clear-Host
                  Write-Host "Cloning cancelled. Please select a valid Index ID to create a Full Clone"
                  linkedClone1 #-folder $config.folder
                }
            }
        }else{
            Write-Host -ForegroundColor "Red" "Invalid Index ID. Please select a valid Index ID to create a Full Clone"
            Start-Sleep -Seconds 1.5
            fullClone
        }
}

# Creates linked Clones 
function createLinkedClone($selectedVM) {
    $config = (Get-Content -Raw -Path "/home/q/Documents/techJournal/SYS-480-DevOps/480.json" | ConvertFrom-Json)
    $snapshot = Get-Snapshot -VM $selectedVM.Name -Name "Base" 
    $linkedClone = "{0}.linked" -f $selectedVM.Name
    $linkedVM = New-VM -LinkedClone -Name $linkedClone -VM $selectedVM.Name -ReferenceSnapshot $snapshot -VMHost $config.esxi_host -Datastore $config.default_datastore 
    $linkedVM | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $config.default_network -Confirm:$false
    Write-Host $linkedVM
    Write-Host $selectedVM
    newVM $linkedVM
  }

# Creates linked Clone - does not get deleted
function linkedClone($selectedVM) {
    $config = (Get-Content -Raw -Path "/home/q/Documents/techJournal/SYS-480-DevOps/480.json" | ConvertFrom-Json)
    $snapshot = Get-Snapshot -VM $selectedVM.Name -Name "Base" 
    $linkedClone = "{0}.linked" -f $selectedVM.Name
    $linkedVM = New-VM -LinkedClone -Name $linkedClone -VM $selectedVM.Name -ReferenceSnapshot $snapshot -VMHost $config.esxi_host -Datastore $config.default_datastore 
    $linkedVM | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $config.default_network -Confirm:$false
    Write-Host ""
    Write-Host "$linkedVM has been created"
}

# Uses linkedVM to create a new VM  
function newVM($linkedVM) {
    $config = (Get-Content -Raw -Path "/home/q/Documents/techJournal/SYS-480-DevOps/480.json" | ConvertFrom-Json)
    Clear-Host
    $nameVM = Read-Host -Prompt "Enter the name of the new VM"
    Write-Host ""
    Write-Host "Creating $nameVM and taking initial snapshot"
    Write-Host ""
    $newVM = New-VM -Name $nameVM -VM $linkedVM -VMHost $config.esxi_host -Datastore $config.default_datastore #-Folder $config.folder
    $newVM = $newVM | New-Snapshot -Name "Base" #-Confirm:$false -Description:$false
    Write-Host ""
    Write-Host -ForegroundColor "Green" "$nameVM has been created with a snapshot named 'Based'"
    cleanUp $linkedVM
    }

# Removes linkedVM from instance
function cleanUp($linkedVM) {
    Write-Host ""
    #Write-Host "Deleting $linkedVM"
    $linkedVM | Remove-VM -DeletePermanently -Confirm:$false
    Write-Host "Deleted $linkedVM"
    finishCheck
    }

# Confirms user is done with script
function finishCheck {
    Write-Host ""
    $confirm = Read-Host -Prompt "Would you like to Quit (Y/N)? "
                if ($confirm -eq "Y" -or $confirm -eq "y" -or $confirm -eq "yes"-or $confirm -eq "Yes") {
                    Clear-Host
                    Exit
                } else {
                    Clear-Host
                    intMenu
                }
}

# Used to select VM to Delete
function selectDelete() {
    Clear-Host
    Write-Host "Options"
    Write-Host "[0] Main Menu"
    $selectedVM = $null
        $vms = Get-VM 
        $index = 1
        foreach($vm in $vms) {
            Write-Host  "[$index] $($vm.name)"
            $index+=1
        }
        Write-Host ""
        $vmInput = Read-Host 'Which index number [x] do you wish to delete?'
        # 480 TODO - deal with invalid index (could make check a function)
        if ($vmInput -match '^\d+$') {
            $key = [int]$vmInput - 1
            if ($key -lt 0) {
                Clear-Host
                intMenu
            }elseif($key -ge $vms.Count){
                Write-Host -ForegroundColor "Red" "Invalid Index ID. Please select a valid Index ID"
                Start-Sleep -Seconds 1.5
                selectDelete
            } else {
                $selectedVM = $vms[$key]
                Write-Host ""
                Write-Host "You picked $($selectedVM.name)."
                $confirm = Read-Host -Prompt "Are you sure you want to delete the selected virtual machine (Y/N)? "
                if ($confirm -eq "Y" -or $confirm -eq "y" -or $confirm -eq "yes"-or $confirm -eq "Yes") {
                    Clear-Host
                    cleanUpDel $selectedVM
                } else {
                  Clear-Host
                  Write-Host "Delete cancelled."
                  selectDelete 
                }
            }
        }else{
            Write-Host -ForegroundColor "Red" "Invalid Index ID. Please select a valid Index ID"
            Start-Sleep -Seconds 1.5
            selectDelete
        }
}

# Deletes VM
function cleanUpDel($selectedVM) {
    Write-Host ""
    $selectedVM | Remove-VM -DeletePermanently -Confirm:$false
    Clear-Host
    Write-Host "Deleted $selectedVM"
    finishCheck
    }

# Creates New Virtual Switch 
function newVSwitch(){
    $config = (Get-Content -Raw -Path "/home/q/Documents/techJournal/SYS-480-DevOps/480.json" | ConvertFrom-Json)
    Write-Host ""
    $readvSwitch = Read-Host "Provide a name for the new Virtual Switch"
    $vSwitch = New-VirtualSwitch -VMHost $config.esxi_host -Name $readvSwitch
    Write-Host ""
    Write-Host "$vSwitch has been successfully created"
    $userInput = Read-Host "Would you like to create a new Port Group (Y/N)"
    if ($userInput -eq "Y" -or $userInput -eq "y" -or $userInput -eq "yes"-or $userInput -eq "Yes") {
        newVPort $vSwitch
    } else {
        finishCheck
} 
}

# Creates New Virtual Portgroup
function newVPort($vSwitch){
    $config = (Get-Content -Raw -Path "/home/q/Documents/techJournal/SYS-480-DevOps/480.json" | ConvertFrom-Json)
    Write-Host ""
    $readPort = Read-Host "Provide a name for the new Portgroup"
    if ($vSwitch -ne $null){
        $portGroup = New-VirtualPortGroup -VirtualSwitch $vSwitch -Name $readPort
        Write-Host ""
        Write-Host "$portGroup has been successfully created"
        Write-Host ""
        finishCheck
    }elseif ($vSwitch -eq $null){
        $listVS = Get-VirtualSwitch | Where-Object { $_.Name}
        $index=1
        Write-Host "[0] Go Back"
        foreach ($item in $listVS){
            Write-Host "[$index] $item"
            $index+=1
        }
        Write-Host ""
            $vmInput = Read-Host 'Which index number [x] do you wish to delete?'
            if ($vmInput -match '^\d+$') {
                $key = [int]$vmInput - 1
                if ($key -lt 0) {
                    Clear-Host
                    networkMenu
                }elseif($key -ge $listVS.Count){
                    Write-Host -ForegroundColor "Red" "Invalid Index ID. Please select a valid Index ID"
                    Start-Sleep -Seconds 1.5
                    newVPort
                } else {
                    $selected = $listVS[$key]
                    Write-Host ""
                    $confirm = Read-Host -Prompt "Are you sure you want to use the $selected virtual switch to create $readPort (Y/N)? "
                if ($confirm -eq "Y" -or $confirm -eq "y" -or $confirm -eq "yes"-or $confirm -eq "Yes") {
                    Clear-Host
                    $portGroup = New-VirtualPortGroup -VirtualSwitch $selected -Name $readPort
                    Write-Host ""
                    Write-Host "$portGroup has been successfully created"
                    Write-Host ""
                    finishCheck
                } else {
                  Clear-Host
                  Write-Host "Creation cancelled."
                  newVPort 
                }
            }
        }else{
            Write-Host -ForegroundColor "Red" "Invalid Index ID. Please select a valid Index ID"
            Start-Sleep -Seconds 1.5
            delVSwitch
        }
        
    }else{
        finishCheck
    }
    
    
}

# Deletes Virtual Switch 
function delVSwitch(){
    Write-Host ""
    Write-Host "Virtual Switches:"
    Write-Host "[0] Go back"
    $listVS = Get-VirtualSwitch | Where-Object { $_.Name}
    $index=1
    foreach ($item in $listVS){
        Write-Host "[$index] $item"
        $index+=1
    }
    Write-Host ""
        $vmInput = Read-Host 'Which index number [x] do you wish to delete?'
        if ($vmInput -match '^\d+$') {
            $key = [int]$vmInput - 1
            if ($key -lt 0) {
                Clear-Host
                networkMenu
            }elseif($key -ge $listVS.Count){
                Write-Host -ForegroundColor "Red" "Invalid Index ID. Please select a valid Index ID"
                Start-Sleep -Seconds 1.5
                delVSwitch
            } else {
                $selected = $listVS[$key]
                Write-Host ""
                Write-Host "You picked $($selected)."
                $confirm = Read-Host -Prompt "Are you sure you want to delete the selected virtual switch and associate portgroup (Y/N)? "
                if ($confirm -eq "Y" -or $confirm -eq "y" -or $confirm -eq "yes"-or $confirm -eq "Yes") {
                    Clear-Host
                    Remove-VirtualSwitch -VirtualSwitch $selected -Confirm:$false
                    Write-Host "$selected has been deleted"
                    finishCheck
                } else {
                  Clear-Host
                  Write-Host "Delete cancelled."
                  delVSwitch 
                }
            }
        }else{
            Write-Host -ForegroundColor "Red" "Invalid Index ID. Please select a valid Index ID"
            Start-Sleep -Seconds 1.5
            delVSwitch
        }
    
}

# Deletes Virtual Portgroup
function delVPort(){
    Write-Host ""
    Write-Host "Virtual Portgroups:"
    Write-Host "[0] Go back"
    $listVP = Get-VirtualPortGroup | Where-Object { $_.Name}
    $index+=1
    foreach ($item in $listVP){
        Write-Host "[$index] $item"
        $index+=1
    } 
    Write-Host ""
    $vmInput = Read-Host 'Which index number [x] do you wish to delete?'
    if ($vmInput -match '^\d+$') {
        $key = [int]$vmInput - 1
        if ($key -lt 0) {
            Clear-Host
            networkMenu
        }elseif($key -ge $listVP.Count){
            Write-Host -ForegroundColor "Red" "Invalid Index ID. Please select a valid Index ID"
            Start-Sleep -Seconds 1.5
            delVPort
        } else {
            $selected = $listVP[$key]
            Write-Host ""
            Write-Host "You picked $($selected)."
            $confirm = Read-Host -Prompt "Are you sure you want to delete the selected virtual portgroup (Y/N)? "
            if ($confirm -eq "Y" -or $confirm -eq "y" -or $confirm -eq "yes"-or $confirm -eq "Yes") {
                Clear-Host
                Remove-VirtualPortGroup -VirtualPortGroup $selected -Confirm:$false
                Write-Host "$selected has been deleted"
                finishCheck
            } else {
              Clear-Host
              Write-Host "Delete cancelled."
              delVPort 
            }
        }
    }else{
        Write-Host -ForegroundColor "Red" "Invalid Index ID. Please select a valid Index ID"
        Start-Sleep -Seconds 1.5
        delVPort
    }

}


<# Not Needed was used to create individual functions for different use-cases.
function selectVM() {
    Clear-Host
    Write-Host "Options"
    Write-Host "[0] Main Menu"
    $selectedVM = $null
        $vms = Get-VM #-Location $folder
        $index = 1
        foreach($vm in $vms) {
            Write-Host  "[$index] $($vm.name)"
            $index+=1
        }
        Write-Host ""
        $vmInput = Read-Host 'Which index number [x] do you wish to clone?'
        # could make check a function
        if ($vmInput -match '^\d+$') {
            $key = [int]$vmInput - 1
            if ($key -lt 0) {
                Clear-Host
                intMenu
            }elseif($key -ge $vms.Count){
                Write-Host -ForegroundColor "Red" "Invalid Index ID. Please select a valid Index ID"
                Start-Sleep -Seconds 1.5
                selectVM #-folder $folder
            }else {
                $selectedVM = $vms[$key]
                Write-Host ""
                Write-Host "You picked $($selectedVM.name)."
                $confirm = Read-Host -Prompt "Are you sure you want to clone the selected virtual machine (Y/N)? "
                if ($confirm -eq "Y" -or $confirm -eq "y" -or $confirm -eq "yes"-or $confirm -eq "Yes") {
                    Clear-Host
                    createLinkedClone #-folder $folder
                } else {
                  Clear-Host
                  Write-Host "Cloning cancelled."
                  selectVM #-folder $folder
                }
            }
        }else{
            Write-Host -ForegroundColor "Red" "Invalid Index ID. Please select a valid Index ID"
            Start-Sleep -Seconds 1.5
            selectVM
        }
}


# Used to create linked Clones - Will list ALL VMs
function linkedClone1() {
    $config = (Get-Content -Raw -Path "/home/q/Documents/techJournal/SYS-480-DevOps/480.json" | ConvertFrom-Json)
    Clear-Host
    Write-Host "Options"
    Write-Host "[0] Main Menu"
    $selectedVM = $null
        $vms = Get-VM #-Location $config.folder
        $index = 1
        foreach($vm in $vms) {
            Write-Host  "[$index] $($vm.name)"
            $index+=1
        }
        Write-Host ""
        $vmInput = Read-Host 'Which index number [x] do you wish to use to create a Linked Clone?'
        # could make check a function
        if ($vmInput -match '^\d+$') {
            $key = [int]$vmInput - 1
            if ($key -lt 0) {
                Clear-Host
                intMenu
            }elseif($key -ge $vms.Count){
                Write-Host -ForegroundColor "Red" "Invalid Index ID. Please select a valid Index ID to create a Full Clone"
                Start-Sleep -Seconds 1.5
                linkedClone1 #-folder $config.folder
            }else {
                $selectedVM = $vms[$key]
                Write-Host ""
                Write-Host "You picked $($selectedVM.name)."
                $confirm = Read-Host -Prompt "Are you sure you want to clone the selected virtual machine (Y/N)? "
                if ($confirm -eq "Y" -or $confirm -eq "y" -or $confirm -eq "yes"-or $confirm -eq "Yes") {
                    Clear-Host
                    linkedClone $selectedVM
                } else {
                  Clear-Host
                  Write-Host "Cloning cancelled. Please select a valid Index ID to create a Full Clone"
                  linkedClone1 #-folder $config.folder
                }
            }
        }else{
            Write-Host -ForegroundColor "Red" "Invalid Index ID. Please select a valid Index ID to create a Full Clone"
            Start-Sleep -Seconds 1.5
            fullClone
        }
}
#>


function vmNetworking() {
    $selectedVM = $null
        $vms = Get-VM #-Location $config.folder
        $index = 1
        Write-Host "[0] Go Back"
        foreach($vm in $vms) {
            Write-Host  "[$index] $($vm.name)"
            $index+=1
        }
        Write-Host ""
        $vmInput = Read-Host "Which index number [x] do you wish to use to retireve the VM's network information?"
        if ($vmInput -match '^\d+$') {
            $key = [int]$vmInput - 1
            if ($key -lt 0) {
                Clear-Host
                vmMenu
            }elseif($key -ge $vms.Count){
                Write-Host -ForegroundColor "Red" "Invalid Index ID. Please select a valid Index ID to create a Full Clone"
                Start-Sleep -Seconds 1.5
                vmNetworking
            }else {
                $selectedVM = $vms[$key]
                $net2 = Get-VM -name $selectedVM | Select Name, @{N="IP Address";E={@($_.guest.IPAddress[0])}}
                $net = Get-VM -name $selectedVM | Get-NetworkAdapter
                Write-Host ""
                Write-Host "VM Name: "$net2.Name
                Write-Host "Network: "$net.NetworkName
                Write-Host "IP Address: "$net2.'IP Address'
                Write-Host "Mac Address: "$net.MacAddress
                Write-Host ""
                finishCheck
            }
        }else{
            Write-Host -ForegroundColor "Red" "Invalid Index ID. Please select a valid Index ID"
            Start-Sleep -Seconds 1.5
            vmNetworking
        }
}
