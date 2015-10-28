#
# SQLServerPreparation.psm1
#

Import-Module (Join-Path $PSScriptRoot "..\Common\Utility.psm1") -DisableNameChecking

$SQLServerParameterHash = New-Object -TypeName Hashtable

<#
	.Synopsis
	Add SQL Server dynamic parameters.

	.ParameterFilePath
	Path of the Parameter file

	.UpdateParameterFilePath
	Path of the update paramter file
#>
function Add-SQLServerDynamicParams{
	[CmdletBinding()]
	param(
		[Parameter(ParameterSetName='SQLServerpreperaation', Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$ParameterFilePath,

		[Parameter(ParameterSetName='SQLServerpreperaation', Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$UpdateParameterFilePath	
	)
	
	$SqlServerInstanceParameterName = "SQLServerInstanceName"
	$SqlDbAdminUserParameterName = "SQLServerInstanceAdminLogin"
	$SqlDbAdminPasswordParameterName = "SQLServerInstanceAdminLoginPassword"
	$SqlServerLocationName = "SQLServerInstanceLocation"

	# Get DB credentials
	$DbServerAdminCredentials = Get-Credential -Message "Please enter OSE database credential"
	$SqlDbAdminPasswordSecureString = $DbServerAdminCredentials.GetNetworkCredential().Password
	
	# Add dynamic details to hash table
	$SQLServerParameterHash.Add($SqlDbAdminUserParameterName, $DbServerAdminCredentials.UserName)
	$SQLServerParameterHash.Add($SqlDbAdminPasswordParameterName, $SqlDbAdminPasswordSecureString)
	$SQLServerParameterHash.Add($SqlServerLocationName, $Location)
	$SQLServerParameterHash.Add($SqlServerInstanceParameterName, $SqlServerName)
}

<#
	.Synopsis
	Create DB resourcegroup.
	
	.ParameterFilePath
	Path of the Parameter file

	.UpdateParameterFilePath
	Path of the update paramter file

	.TemplateFilePath
	Path of the template file
#>
function Create-SQLServerDeployment{
	[CmdletBinding()]
	param(
		[Parameter(ParameterSetName='SQLServerPreparation', Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$ParameterFilePath,

		[Parameter(ParameterSetName='SQLServerPreparation', Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$UpdateParameterFilePath,
		
		[Parameter(ParameterSetName='SQLServerPreparation', Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$TemplateFilePath	
	)
	
	# Prepare SQL server dynamic parameter hash
	Add-SQLServerDynamicParams -ParameterFilePath $ParameterFilePath -UpdateParameterFilePath $UpdateParameterFilePath

	# Create the paramter file with updated value
	Create-UpdatedParamaterTemplate -ParameterFilePath $ParameterFilePath -UpdateParameterFilePath $UpdateParameterFilePath -ParameterHash $SQLServerParameterHash

	# Perform new DBResourceGroup deployment
	New-AzureRmResourceGroupDeployment -ResourceGroupName $DBResourceGroupName -Name "titotestdbdeploymenttest1" -TemplateFile $TemplateFilePath -TemplateParameterFile $UpdateParameterFilePath 
}