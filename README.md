# Remote User Profile Deletion Tool

## Overview
The Remote User Profile Deletion Tool is a powerful script designed for IT and technical support teams to easily and selectively delete user profiles remotely. The tool supports operations on both individual and groups of computers. The script simplifies profile management, saving time and effort for administrators.

## Features
- **Delete Profiles on Individual PCs:**
  - Displays a list of user profiles from the target computer.
  - Identifies users currently signed in.
  - Allows selective deletion of profiles with a user-friendly GUI.
  - Includes options to select/deselect all users and filter users via a search bar.

- **Delete Profiles on Groups of PCs:**
  - Accepts a list of computer names in TXT, CSV, or Excel format.
  - Deletes all user profiles except for system users (e.g., Administrator, Default User, Public).

- **Automatic Module Management:**
  - Uses `PsExec` for remote execution.
  - Copies required executables and modules (e.g., `PsExec` and `Import-Excel`) to the `System32` folder of the executing computer if they are not already present.

- **Progress Monitoring:**
  - Displays a progress bar during the deletion process.
  - Automatically closes the window upon completion.

## Requirements
1. **Administrator Permissions:**
   - The script requires administrator privileges on the computer executing the program.
2. **Dependencies:**
   - `PsExec` for remote command execution.
   - `Import-Excel` PowerShell module for reading Excel files (bundled in the `modules` folder).
3. **Supported Input Formats:**
   - Computer names can be supplied directly or via files in TXT, CSV, or Excel formats.
4. **Execution Environment:**
   - Windows-based environment.

## Usage
### 1. Execution
The script is run using an executable (`.exe`) file that wraps the batch script. Ensure you have the `PsExec` and `Import-Excel` modules available in the `modules` folder.

### 2. Steps for Individual Computers:
1. Launch the script.
2. Enter the target computer name in the search bar.
3. A GUI will appear with:
   - A list of user profiles found on the computer.
   - Indicators for signed-in users.
   - Options to select/deselect users and search by name.
4. Click **OK** to initiate the deletion process.
5. Monitor the progress bar. The window will close automatically upon completion.

### 3. Steps for Groups of Computers:
1. Launch the script.
2. Select a file containing the list of computer names (TXT, CSV, or Excel).
3. The script will process each computer, deleting all user profiles except for system users.
4. Progress will be displayed, and the process will conclude automatically.

## Additional Information
1. **System Users Excluded from Deletion:**
   - Administrator
   - Default User
   - Public

2. **Error Handling:**
   - Ensure all computer names in the input file are accessible on the network.
   - Verify that the executing user has administrator privileges on all target computers.

3. **Modules Folder:**
   - Ensure the `modules` folder is in the same directory as the script. It contains necessary tools such as `PsExec` and `Import-Excel`.

4. **Execution Environment:**
   - The script automatically handles transferring required modules to `System32` for execution.

## Notes
- This tool is designed for streamlined and efficient user profile management. Use with caution to avoid unintended deletions.
- If additional features or modifications are needed, feel free to contact the development team.

Developed by: Netanel Azuz (netanelazuz) , Alon Salton, Alon Shapira. 2024.
