#
# Utility.psm1
#

<#
	.Synopsis
	Create an updated paramter template.

	.ParameterFilePath
	Path of the Parameter file

	.UpdateParameterFilePath
	Path of the update paramter file
#>
function Create-UpdatedParamaterTemplate{
	[CmdletBinding()]
	param(
		[Parameter(ParameterSetName='UpdateParameterTemplate', Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$ParameterFilePath,

		[Parameter(ParameterSetName='UpdateParameterTemplate', Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$UpdateParameterFilePath,

		[Parameter(ParameterSetName='UpdateParameterTemplate', Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[hashtable]
		$ParameterHash
	)

	
	$JsonContent = Get-Content $ParameterFilePath -Raw | ConvertFrom-Json
	$JsonParameters = $JsonContent | Get-Member -Type NoteProperty | Where-Object {$_.Name -eq "parameters"}

	if ($JsonParameters -eq $null) {
		$JsonParameters = $JsonContent
	}
	else {
		$JsonParameters = $JsonContent.parameters
	}

	$JsonParameters | Get-Member -Type NoteProperty | ForEach-Object {
		$ParameterValue = $JsonParameters | Select-Object -ExpandProperty $_.Name

		if ($ParameterHash.ContainsKey($_.Name)) {
			$ParameterValue.value = $ParameterHash[$_.Name]
		}
	}
	$JsonContent | ConvertTo-Json | Out-File $UpdateParameterFilePath

	Write-Output "Created the parameter template at path $UpdateParameterFilePath"
}