$ProgressPreference = "SilentlyContinue"

mkdir -Path "C:\WAC"

## Download the MSI file
Invoke-WebRequest -UseBasicParsing -Uri 'https://aka.ms/WACDownload' -OutFile "C:\WAC\WindowsAdminCenter.msi"
#Invoke-WebRequest -UseBasicParsing -Uri 'https://download.microsoft.com/download/1/0/5/1059800B-F375-451C-B37E-758FFC7C8C8B/WindowsAdminCenter2009.msi' -OutFile "C:\WAC\WindowsAdminCenter.msi"

## install Windows Admin Center
$msiArgs = @("/i", "C:\WAC\WindowsAdminCenter.msi", "/qn", "/L*v", "log.txt", "SME_PORT=443", "SSL_CERTIFICATE_OPTION=generate")
Start-Process msiexec.exe -Wait -ArgumentList $msiArgs