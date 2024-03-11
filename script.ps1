# Check if the script is running with administrator privilege
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))  
{  
  $arguments = "& '" +$myinvocation.mycommand.definition + "'"
  Start-Process powershell -Verb runAs -ArgumentList $arguments
  Break
}

# Get the current username
$currentUsername = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty UserName).Split("\")[1]

# Get list of user profiles on the local machine (excluding system profiles)    
$usernames = Get-ChildItem -Path "$env:SystemDrive\Users" | Where-Object { $_.PSIsContainer -and $_.Name -notin @("Administrator", "Default", "Public", "$currentUsername", "All Users") } | Select-Object -ExpandProperty Name

# Initialize $selectedUsers
$selectedUsers = $null

# Define a custom object to store user data
$userData = @()

# Populate user data
foreach ($username in $usernames) {
    $sessionInfo = quser | Where-Object { $_ -match $username }
    if ($sessionInfo) {
        $status = "Signed In"
    } 
    else {
        $status = ""
    }

    $userData += [PSCustomObject]@{
        Username = $username
        Status = $status
        IsSelected = $false
    }
}

# Function to log off a user
function Logoff-User($sessionId) {
    Invoke-Command -ScriptBlock { logoff $sessionId }
}

# Function to delete user profile
function Remove-UserProfile($username) {
    $userPath = Join-Path -Path $env:SystemDrive -ChildPath "Users\$username"
    Remove-Item -Path $userPath -Recurse -Force -ErrorAction SilentlyContinue
}

# Function to delete user from registry
function Remove-UserFromRegistry($username) {
    $sid = (New-Object System.Security.Principal.NTAccount($username)).Translate([System.Security.Principal.SecurityIdentifier]).Value
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$sid"
    
    Remove-Item -LiteralPath $registryPath -Force
}


function Operation($selectedUsers) {
     
     foreach ($selectedUser in $selectedUsers) {
        # Check the selected user's session ID
        $sessionInfo = quser | Where-Object { $_ -match $selectedUser }
        if ($sessionInfo) {
            $sessionId = ($sessionInfo -split ' +')[-6]
            if ($sessionId) {
                Write-Host "Session ID for user $selectedUser : $sessionId"
                Logoff-User $sessionId #Logging-off selected user
            } 
            else {
                Write-Host "Unable to determine session ID for user $selectedUser" #Didn't split correctly 'quser' command.
            }
        }
        else {
            Write-Host "Session ID not found for user $selectedUser" #User missing in 'quser' command (User probebly already logged-off)
        }
        Remove-UserProfile $selectedUser #Remove users from 'C:\Users'
        Remove-UserFromRegistry $selectedUser #Remove users from regeistry editor
    }
}
    



# Create GUI
function Gui() {

    # Create a GUI for user selection
    $mainForm = [System.Windows.Forms.Form] @{
        Text = "Select Users to Delete"
        Size = [System.Drawing.Size]::new(450, 350)
        StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    }

    # Label for the current user
    $currentLabel = [System.Windows.Forms.Label] @{
       Text = "Current User:"
       Location = [System.Drawing.Point]::new(10, 10)
       Font = [System.Drawing.Font]::new("Arial", 10)
    }

    # Add current user's label.
    $mainForm.Controls.Add($currentLabel)

    # Display current username after current user's label.
    $currentUsernameLabel = [System.Windows.Forms.Label] @{
        Text = $currentUsername
        Location = [System.Drawing.Point]::new(10 + $currentLabel.Width, 10)
        Font = [System.Drawing.Font]::new("Arial", 10)
        ForeColor = [System.Drawing.Color]::Black
    }

    # Add current username to main form.
    $mainForm.Controls.Add($currentUsernameLabel)

    # ListView for selected users with checkboxes.
    $listView = [System.Windows.Forms.ListView] @{
        Location = [System.Drawing.Point]::new(10, 40)
        Size = [System.Drawing.Size]::new(300, 200)
        CheckBoxes = $true
        View = [System.Windows.Forms.View]::Details
        Font = [System.Drawing.Font]::new("Arial", 10)
        FullRowSelect = $true
        MultiSelect = $false
    }

    # Add columns for usernames and status
    [void]$listView.Columns.Add("Usernames", 150)

    # Add column for status
    [void]$listView.Columns.Add("Status", 100) 

    # Add listview to mainform
    $mainForm.Controls.Add($listView)

    # Button to check all users
    $checkAllButton = [System.Windows.Forms.Button] @{
        Text = "Check All"
        Location = [System.Drawing.Point]::new(320, 40)
        Size = [System.Drawing.Size]::new(100, 30)
    }

    # Check-All Button event handler
    $checkAllButton.Add_Click({ HandleCheckAllButtonClick })
    $mainForm.Controls.Add($checkAllButton)

    # Button event handler for Check All button
    function HandleCheckAllButtonClick {
        $selectAll = $checkAllButton.Text -eq "Check All"
        $userData | ForEach-Object { $_.IsSelected = $selectAll }
        UpdateListView
        
    }

    # OK button to proceed
    $okButton = [System.Windows.Forms.Button] @{
        Text = "OK"
        Location = [System.Drawing.Point]::new(320, 80)
        Size = [System.Drawing.Size]::new(100, 30)
        Enabled = $false
    }

    # OK Button event handler
    $okButton.Add_Click({ HandleOKButtonClick })
    $mainForm.Controls.Add($okButton)

    # Button event handler for OK button
    function HandleOKButtonClick {
        $selectedUsers = $userData | Where-Object { $_.IsSelected } | Select-Object -ExpandProperty Username
        Operation $selectedUsers
        $mainForm.Close()
    }

    # Cancel button to stop the operation
    $cancelButton = [System.Windows.Forms.Button] @{
        Text = "Cancel"
        Location = [System.Drawing.Point]::new(320, 120)
        Size = [System.Drawing.Size]::new(100, 30)
    }
    $cancelButton.Add_Click({
        $mainForm.Close()
    })
    $mainForm.Controls.Add($cancelButton)

    

    foreach ($user in $userData) {
        if (-not $listView.Items.ContainsKey.($user.Username)) {
            $item = New-Object System.Windows.Forms.ListViewItem($user.Username)
            $subItem = $item.SubItems.Add($user.Status)
            $item.Checked = $user.IsSelected
            $listView.Items.Add($item)
        }
    }
    
    # Event handler for individual user checkbox state change
    $listView.Add_ItemCheck({
        $userData[$_.Index].IsSelected = $_.NewValue -eq [System.Windows.Forms.CheckState]::Checked
    })

   
    
    # Search bar textbox
    $searchTextbox = [System.Windows.Forms.TextBox] @{
      Location = [System.Drawing.Point]::new(350, 10)
      Size = [System.Drawing.Size]::new(60, 20)
    }

    # Search bar label
    $searchLabel = [System.Windows.Forms.Label] @{
        Text = "Search.."
        ForeColor = [System.Drawing.Color]::Gray
        Location = [System.Drawing.Point]::new(300, 10)
    }

    # Event handler for search bar text changed
    $searchTextbox.Add_TextChanged({
        if ($searchTextbox.Text -eq "") {
           $searchLabel.Visible = $true
        } 
        else {
            $searchLabel.Visible = $false
        }

        # Clear the ListView items only if there are changes to search criteria
        $listView.Items.Clear()

        # Determine if the search bar is empty
        $isSearchEmpty = $searchTextbox.Text -eq ""

        # Update ListView with user data matching the search criteria
        foreach ($user in $userData) {
            if ($isSearchEmpty -or $user.Username -like "*$($searchTextbox.Text)*") {
                # Add item to ListView only if it's not already present
                if (-not $listView.Items.ContainsKey.($user.Username)) {
                    $item = New-Object System.Windows.Forms.ListViewItem($user.Username)
                    $subItem = $item.SubItems.Add($user.Status)
                    $item.Checked = $user.IsSelected
                    $listView.Items.Add($item)
                }
            }
        }
    })

    $mainForm.Controls.Add($searchTextbox)
    $mainForm.Controls.Add($searchLabel)
    
    
    function UpdateListView {
        # Clear the list view
        $listView.Items.Clear()

        # Populate the list view with updated data from $userData
        foreach ($user in $userData) {
            $item = New-Object System.Windows.Forms.ListViewItem($user.Username)
            $subItem = $item.SubItems.Add($user.Status)
            $item.Checked = $user.IsSelected
            $listView.Items.Add($item)
        }
    }

    # Timer to periodically update GUI
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 100  # Set the interval (in milliseconds)
    $timer.Add_Tick({
        
        # Update Check All button text
        $checkAllButton.Text = if ($userData.IsSelected -contains $false) { "Check All" } else { "Uncheck All" }


        # Update OK button
        $okButton.Enabled = $userData | Where-Object { $_.IsSelected } | Select-Object -First 1
    })
    $timer.Start()

    # Event handler to stop the timer when the form is closed
    $mainForm.Add_FormClosed({
        $timer.Stop()
        $timer.Dispose()
    })

    # Show the form
    $mainForm.ShowDialog() | Out-Null
}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             

function Main() {
    Gui
    Pause #Press Enter to finish (stopping the window from closing).
}

Main
