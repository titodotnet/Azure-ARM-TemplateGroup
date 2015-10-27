#
# Manage_ResourceDeployment.ps1
#

Import-Module (Join-Path $PSScriptRoot "Common\Parameter.psm1") -DisableNameChecking

Login-AzureRmAccount
Select-AzureSubscription -SubscriptionId $SubscriptionId

$SqlServerInstanceParameterName = "SQLServerInstanceName"
$SqlDbAdminUserParameterName = "SQLServerInstanceAdminLogin"
$SqlDbAdminPasswordParameterName = "SQLServerInstanceAdminLoginPassword"
$SqlServerLocationName = "SQLServerInstanceLocation"

$TemplateFile = '..\Templates\DeploymentTemplate.json'
$TemplateParametersFile = '..\Templates\DeploymentTemplate.param.dev.json'
$UpdatedTemplateParametersFile = '..\Templates\DeploymentTemplateUpdated.param.dev.json'
$DynamicParameters = New-Object -TypeName Hashtable

# Get DB credentials
$DbServerAdminCredentials = Get-Credential -Message "Please enter OSE database credential"
$SqlDbAdminPasswordSecureString = $DbServerAdminCredentials.GetNetworkCredential().Password

# Add dynamic details to hash table
$DynamicParameters.Add($SqlDbAdminUserParameterName, $DbServerAdminCredentials.UserName)
$DynamicParameters.Add($SqlDbAdminPasswordParameterName, $SqlDbAdminPasswordSecureString)
$DynamicParameters.Add($SqlServerLocationName, $Location)
$DynamicParameters.Add($SqlServerInstanceParameterName, $SqlServerName)

$TemplateFile = [System.IO.Path]::Combine($PSScriptRoot, $TemplateFile)
$TemplateParametersFile = [System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile)
$UpdatedTemplateParametersFile = [System.IO.Path]::Combine($PSScriptRoot, $UpdatedTemplateParametersFile)

$JsonContent = Get-Content $TemplateParametersFile -Raw | ConvertFrom-Json
$JsonParameters = $JsonContent | Get-Member -Type NoteProperty | Where-Object {$_.Name -eq "parameters"}

if ($JsonParameters -eq $null) {
    $JsonParameters = $JsonContent
}
else {
    $JsonParameters = $JsonContent.parameters
}

$JsonParameters | Get-Member -Type NoteProperty | ForEach-Object {
    $ParameterValue = $JsonParameters | Select-Object -ExpandProperty $_.Name

    if ($DynamicParameters.ContainsKey($_.Name)) {
        $ParameterValue.value = $DynamicParameters[$_.Name]
    }
}
$JsonContent | ConvertTo-Json | Out-File $UpdatedTemplateParametersFile


# Create or update the resource group using the specified template file and template parameters file
#Switch-AzureMode AzureResourceManager
New-AzureRmResourceGroup -Name $DBResourceGroupName `
                       -Location $Location `
                        -Force -Verbose

New-AzureRmResourceGroupDeployment -ResourceGroupName $DBResourceGroupName -Name "titotestdbdeploymenttest1" -TemplateFile $TemplateFile -TemplateParameterFile $UpdatedTemplateParametersFile 

