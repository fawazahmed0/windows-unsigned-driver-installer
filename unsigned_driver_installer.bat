@echo off

:: Initial message
echo ====================================================
echo Do not despair of the mercy of God
echo ====================================================
echo Unsigned Driver Installer Tool For Windows
echo By fawazahmed0 @ GitHub
echo ====================================================
:: echo. is newline
echo.


:: Source: https://stackoverflow.com/questions/23735282/if-not-exist-command-in-batch-file/23736306
:: Check for .inf file exists or not
if not exist *.inf (
echo Please paste this .bat file in driver folder where .inf file is located
echo Press any key to exit
pause > NUL
exit
)

:: Source: https://stackoverflow.com/questions/1894967/how-to-request-administrator-access-inside-a-batch-file
:: Source: https://stackoverflow.com/questions/4051883/batch-script-how-to-check-for-admin-rights
:: batch code to request admin previleges, if no admin previleges
net session >nul 2>&1
if NOT %errorLevel% == 0 (
powershell start -verb runas '%0' am_admin & exit /b
)

:: Source: https://stackoverflow.com/questions/672693/windows-batch-file-starting-directory-when-run-as-admin
:: Going back to script directory
cd %~dp0


:: Source: https://stackoverflow.com/questions/4619088/windows-batch-file-file-download-from-a-url
:: Fetching the binaries required for signing the driver
echo Downloading files required for signing the driver
PowerShell -Command "(New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/fawazahmed0/windows-unsigned-driver-installer/master/files.zip', 'files.zip')"


:: Source: https://stackoverflow.com/questions/37814037/how-to-unzip-a-zip-file-with-powershell-version-2-0
:: Source: https://www.microsoft.com/en-us/download/details.aspx?id=11800
:: These files were take from Windows Driver Kit Version 7.1.0
:: Extracting the .zip file
PowerShell -Command "& {$shell_app=new-object -com shell.application; $filename = \"files.zip\"; $zip_file = $shell_app.namespace((Get-Location).Path + \"\$filename\"); $destination = $shell_app.namespace((Get-Location).Path); $destination.Copyhere($zip_file.items());}"

:: Source: http://woshub.com/how-to-sign-an-unsigned-driver-for-windows-7-x64/
:: Signing the Drivers
echo Signing the drivers
files\inf2cat.exe /driver:. /os:7_X64 > nul 2>&1
files\inf2cat.exe /driver:. /os:7_X86 > nul 2>&1
files\SignTool.exe sign /f files\myDrivers.pfx /p testabc /t http://timestamp.verisign.com/scripts/timstamp.dll /v *.cat > nul 2>&1

:: Adding the Certificates
files\CertMgr.exe -add files\myDrivers.cer -s -r localMachine ROOT > nul 2>&1
files\CertMgr.exe -add files\myDrivers.cer -s -r localMachine TRUSTEDPUBLISHER > nul 2>&1


:: Source: https://stackoverflow.com/questions/22496847/installing-a-driver-inf-file-from-command-line
:: If the bat file is launched from 32 bit program i.e firefox etc, the cmd will start as 32 bit with directory as syswow64 in 64bit pc.
:: pnputil is not accessible directly from 32 bit cmd and will throw error saying no internal or external command ..
:: In that case, it should be accessed from here %WinDir%\Sysnative\
:: I assume, the cmd changes to syswow64, after requesting for admin previleges
:: Source: https://stackoverflow.com/questions/8253713/what-is-pnputil-exe-location-in-64bit-systems
:: Source: https://stackoverflow.com/questions/23933888/pnputil-exe-is-not-recognized-as-an-internal-or-external-command
:: Installing Drivers
pnputil -i -a *.inf > nul 2>&1
if NOT %errorLevel% == 0 (
%WinDir%\Sysnative\pnputil.exe -i -a *.inf > nul 2>&1
)

:: Source: https://social.technet.microsoft.com/Forums/en-US/d109719c-ca97-41e1-a529-0113e23ff5b0/deleting-a-certificate-using-certmgrexe?forum=winserversecurity
:: Removing the Certificates
files\CertMgr.exe -del -c -n "Fawaz Ahmed" -s -r localMachine ROOT > nul 2>&1
files\CertMgr.exe -del -c -n "Fawaz Ahmed" -s -r localMachine TrustedPublisher > nul 2>&1

:: Deleting the temporary items
echo Deleting the temporary files and folders
rmdir /Q /S files > nul 2>&1
del /f files.zip > nul 2>&1

:: Installation done
echo.
echo Driver Installation complete, press any key to exit
pause > NUL
