#### AUTO UPGRADER FOR TABLEAU SERVER ####

Thanks for downloading the Tableau Server auto upgrade script.

INSTALLATION

1. Open the UpgradeTableau.ps1 file with your favourite text editor.
2. Set the location of your Tableau Installation as $tabDir (this is the folder currently containing 9.0, 9.1, etc.)
3. Just in case something goes wrong the script will backup your Tableau Server before anything is uninstalled. Set the folder location where this backup should be stored as $backupDir
4. You're probably wanting to install 64 bit Tableau Server, if you want 32-bit simply change $bit to 32 ($bit = 32).
5. Save and exit

ONE OFF UPGRADE

If you'd just like to upgrade your Server to the latest version as a one off event simply run UpgradeTableau.bat or right click on UpgradeTableau.ps1 and click 'Run with Powershell'.

All outputs from your upgrade will be saved to $tabDir\UpgradeLog.txt

SCHEDULED UPGRADE

Want to make your upgrade more automated?

1. Open 'Task Scheduler' and in the Task Scheduler Library click 'Create Task'.
2. Under security options set to 'Run whether user is logged on or not' and tick 'Run with highest privileges'
3. If needed change the run as user account with the 'Change User or Group' button.
4. On the triggers tab create a 'New' trigger. This can be a one off event out of business hours or if you'd like your environment to always be up to date schedule the script to run every day (not recommended for production environments but great for dev/test)
5. On the actions tab create a 'New' action.
6. In the Program/script box enter: Powershell.exe
7. In the Add arguments (optional) box enter: -ExecutionPolicy Bypass D:\UpgradeTableau.ps1 (changing this last parameter to point to the location where you've extracted the UpgradeTableau.ps1 file
8. Click OK, set any other task options as necessary and click OK to save the task. You should be asked to enter the run as user's password.

All outputs from your upgrade will be saved to $tabDir\UpgradeLog.txt

That's it!

If you'd like to keep up to date with everything Tableau from The Information Lab UK simply visit
http://www.theinformationlab.co.uk/blog

To signup for our newsletter go to
http://theinformationlab.us2.list-manage.com/subscribe/post?u=8954cfd70761b8c7fd5d8b528&id=fc1dab699f