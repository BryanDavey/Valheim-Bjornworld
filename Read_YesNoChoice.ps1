Function Read-YesNoChoice {
	<#
        .SYNOPSIS
        Prompt the user for a Yes No choice.

        .DESCRIPTION
        Prompt the user for a Yes No choice and returns 0 for no and 1 for yes.

        .PARAMETER Title
        Title for the prompt

        .PARAMETER Message
        Message for the prompt
		
		.PARAMETER DefaultOption
        Specifies the default option if nothing is selected

        .INPUTS
        None. You cannot pipe objects to Read-YesNoChoice.

        .OUTPUTS
        Int. Read-YesNoChoice returns an Int, 0 for no and 1 for yes.

        .EXAMPLE
        PS> $choice = Read-YesNoChoice -Title "Please Choose" -Message "Yes or No?"
		
		Please Choose
		Yes or No?
		[N] No  [Y] Yes  [?] Help (default is "N"): y
		PS> $choice
        1
		
		.EXAMPLE
        PS> $choice = Read-YesNoChoice -Title "Please Choose" -Message "Yes or No?" -DefaultOption 1
		
		Please Choose
		Yes or No?
		[N] No  [Y] Yes  [?] Help (default is "Y"):
		PS> $choice
        1

        .LINK
        Online version: https://www.chriscolden.net/2024/03/01/yes-no-choice-function-in-powershell/
    #>
	
	Param (
        [Parameter(Mandatory=$true)][String]$Title,
		[Parameter(Mandatory=$true)][String]$Message,
		[Parameter(Mandatory=$false)][Int]$DefaultOption = 0
    )
	
	$No = New-Object System.Management.Automation.Host.ChoiceDescription '&No', 'No'
	$Yes = New-Object System.Management.Automation.Host.ChoiceDescription '&Yes', 'Yes'
	$Options = [System.Management.Automation.Host.ChoiceDescription[]]($No, $Yes)
	
	return $host.ui.PromptForChoice($Title, $Message, $Options, $DefaultOption)
}