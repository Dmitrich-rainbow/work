#region Help
# ----------

<#
	.SYNOPSIS
    
		DiskSpeed is a GUI for the storage performance program diskspd.exe.
        The reporting in done in the GUI, but also in CSV or HTML format.

			
		Requirements:
            
            - Diskspd.exe (https://gallery.technet.microsoft.com/DiskSpd-a-robust-storage-6cd2f223)

    .DESCRIPTION
 
		Diskspd.exe is a storage performance program released by Microsoft.
        Although the program is very robust in storage performance testing, the output is not very user-friendly.
        DiskSpeed will collect all results from the tests and display the results in a nice HTML layout.

		Report details:
		
		o Name
        o Path
        o Block Size
        o Operation
        o Read / Write ratio
        o Outstanding I/O
        o Threads
        o IOPS
        o MB/sec
        o Latency
        o CPU %

        DiskSpeed allows you to save your config to file to import it later and use it over and over again.


	.INPUTS
 
		None
 
	.OUTPUTS
 
		None
 
	.NOTES
 
		Author: Darryl van der Peijl
		Website: http://www.DarrylvanderPeijl.nl/
		Email: DarrylvanderPeijl@outlook.com
		Date created: 07.october.2015
		Last modified: 06.may.2016
		Version: 0.8.4

        Thanks to fellow MVP Serhat AKINCI for the nice HTML report.
 
	.LINK
    
		http://www.DarrylvanderPeijl.nl/
		https://twitter.com/DarrylvdPeijl
#>

#endregion Help
#requires –runasadministrator

[reflection.assembly]::loadwithpartialname("system.windows.forms") | Out-Null
[reflection.assembly]::loadwithpartialname("system.drawing") | Out-Null
$MainForm = New-Object windows.forms.form;
cd $PSScriptRoot


#Default Values
$blocksizes = @("4K","8K","16K","32K","64K","512K","1024K")
$OutstandingIOs = @("1","2","4","8","16","32","64")
$Threads = @("1","2","3","4","5","6","7","8")
$Durations = @("5","10","30","60","120","240","350","500")
$TestFileSizes = @("1","2","3","4","5","6","7","8")

function AddTest{
	if($groupBoxTest2.Visible -eq $false){$groupBoxTest2.Visible = $true;$resultBoxTest2.Visible = $true; Resize -StartDown 50 -HeightIncrease 50}
    elseif($groupBoxTest3.Visible -eq $false){$groupBoxTest3.Visible = $true;$resultBoxTest3.Visible = $true; Resize -StartDown 50 -HeightIncrease 50}
    elseif($groupBoxTest4.Visible -eq $false){$groupBoxTest4.Visible = $true;$resultBoxTest4.Visible = $true; Resize -StartDown 50 -HeightIncrease 50}
    elseif($groupBoxTest5.Visible -eq $false){$groupBoxTest5.Visible = $true;$resultBoxTest5.Visible = $true; Resize -StartDown 50 -HeightIncrease 50}
    elseif($groupBoxTest6.Visible -eq $false){$groupBoxTest6.Visible = $true;$resultBoxTest6.Visible = $true; $FolderTest6.Text = $FolderTest5.Text; Resize -StartDown 50 -HeightIncrease 50}
    elseif($groupBoxTest7.Visible -eq $false){$groupBoxTest7.Visible = $true;$resultBoxTest7.Visible = $true; $FolderTest7.Text = $FolderTest6.Text; Resize -StartDown 50 -HeightIncrease 50}
    elseif($groupBoxTest8.Visible -eq $false){$groupBoxTest8.Visible = $true;$resultBoxTest8.Visible = $true; $FolderTest8.Text = $FolderTest7.Text; Resize -StartDown 50 -HeightIncrease 50}
    elseif($groupBoxTest9.Visible -eq $false){$groupBoxTest9.Visible = $true;$resultBoxTest9.Visible = $true; $FolderTest9.Text = $FolderTest8.Text; Resize -StartDown 50 -HeightIncrease 50}
    elseif($groupBoxTest10.Visible -eq $false){$groupBoxTest10.Visible = $true;$resultBoxTest10.Visible = $true; $FolderTest10.Text = $FolderTest9.Text; Resize -StartDown 50 -HeightIncrease 50}
}

function RemoveTest{
    if($groupBoxTest10.Visible -eq $true){$groupBoxTest10.Visible = $false;$resultBoxTest10.Visible = $false; Resize -HeightDecrease 50 -StartUP 50}
    elseif($groupBoxTest9.Visible -eq $true){$groupBoxTest9.Visible = $false;$resultBoxTest9.Visible = $false; Resize -HeightDecrease 50 -StartUP 50}
    elseif($groupBoxTest8.Visible -eq $true){$groupBoxTest8.Visible = $false;$resultBoxTest8.Visible = $false; Resize -HeightDecrease 50 -StartUP 50}
    elseif($groupBoxTest7.Visible -eq $true){$groupBoxTest7.Visible = $false;$resultBoxTest7.Visible = $false; Resize -HeightDecrease 50 -StartUP 50}
    elseif($groupBoxTest6.Visible -eq $true){$groupBoxTest6.Visible = $false;$resultBoxTest6.Visible = $false; Resize -HeightDecrease 50 -StartUP 50}
    elseif($groupBoxTest5.Visible -eq $true){$groupBoxTest5.Visible = $false;$resultBoxTest5.Visible = $false; Resize -HeightDecrease 50 -StartUP 50}
    elseif($groupBoxTest4.Visible -eq $true){$groupBoxTest4.Visible = $false;$resultBoxTest4.Visible = $false; Resize -HeightDecrease 50 -StartUP 50}
    elseif($groupBoxTest3.Visible -eq $true){$groupBoxTest3.Visible = $false;$resultBoxTest3.Visible = $false; Resize -HeightDecrease 50 -StartUP 50}
    elseif($groupBoxTest2.Visible -eq $true){$groupBoxTest2.Visible = $false;$resultBoxTest2.Visible = $false; Resize -HeightDecrease 50 -StartUP 50}
}

function GetActiveTests{
    $ActiveTests = @()
	if($groupBoxTest1.Visible -eq $True){$ActiveTests+= 1}
    if($groupBoxTest2.Visible -eq $True){$ActiveTests+= 2}
    if($groupBoxTest3.Visible -eq $True){$ActiveTests+= 3}
    if($groupBoxTest4.Visible -eq $True){$ActiveTests+= 4}
    if($groupBoxTest5.Visible -eq $True){$ActiveTests+= 5}
    if($groupBoxTest6.Visible -eq $True){$ActiveTests+= 6}
    if($groupBoxTest7.Visible -eq $True){$ActiveTests+= 7}
    if($groupBoxTest8.Visible -eq $True){$ActiveTests+= 8}
    if($groupBoxTest9.Visible -eq $True){$ActiveTests+= 9}
    if($groupBoxTest10.Visible -eq $True){$ActiveTests+= 10}

    Write-Output $ActiveTests
}

function GetTestDetails{
    $TestDetails = @{}
	if($groupBoxTest1.Visible -eq $True){$TestDetails += @{"NameTest1" = $NameTest1.Text}; $TestDetails += @{"FolderTest1" = $FolderTest1.Text}; $TestDetails += @{"BlocksizeTest1" = $BlocksizeTest1.Text};$TestDetails += @{"ReadPercTest1" = $ReadPercTest1.Text};$TestDetails += @{"WritePercTest1" = $WritePercTest1.Text};$TestDetails += @{"OutstandingIOTest1" = $OutstandingIOTest1.Text};$TestDetails += @{"AccessTypeTest1" = $AccessTypeTest1.Text};$TestDetails += @{"ThreadsTest1" = $ThreadsTest1.Text};$TestDetails += @{"DurationTest1" = $DurationTest1.Text}}
    if($groupBoxTest2.Visible -eq $True){$TestDetails += @{"NameTest2" = $NameTest2.Text}; $TestDetails += @{"FolderTest2" = $FolderTest2.Text}; $TestDetails += @{"BlocksizeTest2" = $BlocksizeTest2.Text};$TestDetails += @{"ReadPercTest2" = $ReadPercTest2.Text};$TestDetails += @{"WritePercTest2" = $WritePercTest2.Text};$TestDetails += @{"OutstandingIOTest2" = $OutstandingIOTest2.Text};$TestDetails += @{"AccessTypeTest2" = $AccessTypeTest2.Text};$TestDetails += @{"ThreadsTest2" = $ThreadsTest2.Text};$TestDetails += @{"DurationTest2" = $DurationTest2.Text}}
    if($groupBoxTest3.Visible -eq $True){$TestDetails += @{"NameTest3" = $NameTest3.Text}; $TestDetails += @{"FolderTest3" = $FolderTest3.Text}; $TestDetails += @{"BlocksizeTest3" = $BlocksizeTest3.Text};$TestDetails += @{"ReadPercTest3" = $ReadPercTest3.Text};$TestDetails += @{"WritePercTest3" = $WritePercTest3.Text};$TestDetails += @{"OutstandingIOTest3" = $OutstandingIOTest3.Text};$TestDetails += @{"AccessTypeTest3" = $AccessTypeTest3.Text};$TestDetails += @{"ThreadsTest3" = $ThreadsTest3.Text};$TestDetails += @{"DurationTest3" = $DurationTest3.Text}}
    if($groupBoxTest4.Visible -eq $True){$TestDetails += @{"NameTest4" = $NameTest4.Text}; $TestDetails += @{"FolderTest4" = $FolderTest4.Text}; $TestDetails += @{"BlocksizeTest4" = $BlocksizeTest4.Text};$TestDetails += @{"ReadPercTest4" = $ReadPercTest4.Text};$TestDetails += @{"WritePercTest4" = $WritePercTest4.Text};$TestDetails += @{"OutstandingIOTest4" = $OutstandingIOTest4.Text};$TestDetails += @{"AccessTypeTest4" = $AccessTypeTest4.Text};$TestDetails += @{"ThreadsTest4" = $ThreadsTest4.Text};$TestDetails += @{"DurationTest4" = $DurationTest4.Text}}
    if($groupBoxTest5.Visible -eq $True){$TestDetails += @{"NameTest5" = $NameTest5.Text}; $TestDetails += @{"FolderTest5" = $FolderTest5.Text}; $TestDetails += @{"BlocksizeTest5" = $BlocksizeTest5.Text};$TestDetails += @{"ReadPercTest5" = $ReadPercTest5.Text};$TestDetails += @{"WritePercTest5" = $WritePercTest5.Text};$TestDetails += @{"OutstandingIOTest5" = $OutstandingIOTest5.Text};$TestDetails += @{"AccessTypeTest5" = $AccessTypeTest5.Text};$TestDetails += @{"ThreadsTest5" = $ThreadsTest5.Text};$TestDetails += @{"DurationTest5" = $DurationTest5.Text}}
    if($groupBoxTest6.Visible -eq $True){$TestDetails += @{"NameTest6" = $NameTest6.Text}; $TestDetails += @{"FolderTest6" = $FolderTest6.Text}; $TestDetails += @{"BlocksizeTest6" = $BlocksizeTest6.Text};$TestDetails += @{"ReadPercTest6" = $ReadPercTest6.Text};$TestDetails += @{"WritePercTest6" = $WritePercTest6.Text};$TestDetails += @{"OutstandingIOTest6" = $OutstandingIOTest6.Text};$TestDetails += @{"AccessTypeTest6" = $AccessTypeTest6.Text};$TestDetails += @{"ThreadsTest6" = $ThreadsTest6.Text};$TestDetails += @{"DurationTest6" = $DurationTest6.Text}}
    if($groupBoxTest7.Visible -eq $True){$TestDetails += @{"NameTest7" = $NameTest7.Text}; $TestDetails += @{"FolderTest7" = $FolderTest7.Text}; $TestDetails += @{"BlocksizeTest7" = $BlocksizeTest7.Text};$TestDetails += @{"ReadPercTest7" = $ReadPercTest7.Text};$TestDetails += @{"WritePercTest7" = $WritePercTest7.Text};$TestDetails += @{"OutstandingIOTest7" = $OutstandingIOTest7.Text};$TestDetails += @{"AccessTypeTest7" = $AccessTypeTest7.Text};$TestDetails += @{"ThreadsTest7" = $ThreadsTest7.Text};$TestDetails += @{"DurationTest7" = $DurationTest7.Text}}
    if($groupBoxTest8.Visible -eq $True){$TestDetails += @{"NameTest8" = $NameTest8.Text}; $TestDetails += @{"FolderTest8" = $FolderTest8.Text}; $TestDetails += @{"BlocksizeTest8" = $BlocksizeTest8.Text};$TestDetails += @{"ReadPercTest8" = $ReadPercTest8.Text};$TestDetails += @{"WritePercTest8" = $WritePercTest8.Text};$TestDetails += @{"OutstandingIOTest8" = $OutstandingIOTest8.Text};$TestDetails += @{"AccessTypeTest8" = $AccessTypeTest8.Text};$TestDetails += @{"ThreadsTest8" = $ThreadsTest8.Text};$TestDetails += @{"DurationTest8" = $DurationTest8.Text}}
    if($groupBoxTest9.Visible -eq $True){$TestDetails += @{"NameTest9" = $NameTest9.Text}; $TestDetails += @{"FolderTest9" = $FolderTest9.Text}; $TestDetails += @{"BlocksizeTest9" = $BlocksizeTest9.Text};$TestDetails += @{"ReadPercTest9" = $ReadPercTest9.Text};$TestDetails += @{"WritePercTest9" = $WritePercTest9.Text};$TestDetails += @{"OutstandingIOTest9" = $OutstandingIOTest9.Text};$TestDetails += @{"AccessTypeTest9" = $AccessTypeTest9.Text};$TestDetails += @{"ThreadsTest9" = $ThreadsTest9.Text};$TestDetails += @{"DurationTest9" = $DurationTest9.Text}}
    if($groupBoxTest10.Visible -eq $True){$TestDetails += @{"NameTest10" = $NameTest10.Text}; $TestDetails += @{"FolderTest10" = $FolderTest10.Text}; $TestDetails += @{"BlocksizeTest10" = $BlocksizeTest10.Text};$TestDetails += @{"ReadPercTest10" = $ReadPercTest10.Text};$TestDetails += @{"WritePercTest10" = $WritePercTest10.Text};$TestDetails += @{"OutstandingIOTest10" = $OutstandingIOTest10.Text};$TestDetails += @{"AccessTypeTest10" = $AccessTypeTest10.Text};$TestDetails += @{"ThreadsTest10" = $ThreadsTest10.Text};$TestDetails += @{"DurationTest10" = $DurationTest10.Text}}
    
    write-output $TestDetails
}

function ExportConfig{

$CSV = $Null
$ActiveTests = GetActiveTests
$TestDetails = GetTestDetails
$CSV += "ID,NameTest,FolderTest,BlocksizeTest,ReadPercTest,WritePercTest,OutstandingIOTest,AccessTypeTest,ThreadsTest,DurationTest`r`n"

$ActiveTests | % {
$NameTest = $TestDetails.Get_item("NameTest$_")
$FolderTest = $TestDetails.Get_item("FolderTest$_")
$BlocksizeTest = $TestDetails.Get_item("BlocksizeTest$_")
$ReadPercTest = $TestDetails.Get_item("ReadPercTest$_")
$WritePercTest = $TestDetails.Get_item("WritePercTest$_")
$OutstandingIOTest = $TestDetails.Get_item("OutstandingIOTest$_")
$AccessTypeTest = $TestDetails.Get_item("AccessTypeTest$_")
$ThreadsTest = $TestDetails.Get_item("ThreadsTest$_")
$DurationTest = $TestDetails.Get_item("DurationTest$_")

$CSV += "$_,$NameTest,$FolderTest,$BlocksizeTest,$ReadPercTest,$WritePercTest,$OutstandingIOTest,$AccessTypeTest,$ThreadsTest,$DurationTest`r`n"
}

$Exportfile = SaveFile
if($Exportfile){
$CSV | Out-File $Exportfile
}
}

function ImportConfig{
cls
$ImportFile = GetFile
If($ImportFile){
$Import = Import-Csv $ImportFile
$Activetests = GetActiveTests
$Import | %{

If ($_.id -gt $Activetests.count){
Addtest
}

#Name
$Nametest = "nametest$($_.id)"
$Nametestbox = Get-Variable $Nametest
$Nametestbox.Value.TEXT = $_.nametest

#Folder
$Foldertest = "foldertest$($_.id)"
$Foldertestbox = Get-Variable $Foldertest
$Foldertestbox.Value.TEXT = $_.foldertest

#Blocksize
$Blocksizetest = "Blocksizetest$($_.id)"
$Blocksizetestbox = Get-Variable $Blocksizetest
$Blocksizetestbox.Value.TEXT = $_.Blocksizetest

#Readperc
$Readperctest = "Readperctest$($_.id)"
$Readperctestbox = Get-Variable $Readperctest
$Readperctestbox.Value.TEXT = $_.Readperctest

#OutstandingIO
$OutstandingIOtest = "OutstandingIOtest$($_.id)"
$OutstandingIOtestbox = Get-Variable $OutstandingIOtest
$OutstandingIOtestbox.Value.TEXT = $_.OutstandingIOtest

#AccessType
$AccessTypetest = "AccessTypetest$($_.id)"
$AccessTypetestbox = Get-Variable $AccessTypetest
$AccessTypetestbox.Value.TEXT = $_.AccessTypetest

#Threads
$Threadstest = "Threadstest$($_.id)"
$Threadstestbox = Get-Variable $Threadstest
$Threadstestbox.Value.TEXT = $_.Threadstest

#Duration
$Durationtest = "Durationtest$($_.id)"
$Durationtestbox = Get-Variable $Durationtest
$Durationtestbox.Value.TEXT = $_.Durationtest

}
}

}

function Resize {
Param ($StartDown,$StartUP,$HeightIncrease,$HeightDecrease)

If($HeightIncrease){
    $width = $MainForm.width
	$height = $MainForm.height
	$height = $height+$HeightIncrease
	$MainForm.Size = New-Object System.Drawing.Size ($width, $height)
}

If($HeightDecrease){
    $width = $MainForm.width
	$height = $MainForm.height
	$height = $height-$HeightDecrease
	$MainForm.Size = New-Object System.Drawing.Size ($width, $height)
}

If($StartDown){

    $width = $groupBoxStart.Location.X
	$height = $groupBoxStart.Location.Y
	$height = $height+$StartDown
	$groupBoxStart.Location = New-Object System.Drawing.Size ($width, $height)
}

If($StartUP){

    $width = $groupBoxStart.Location.X
	$height = $groupBoxStart.Location.Y
	$height = $height-$StartUP
	$groupBoxStart.Location = New-Object System.Drawing.Size ($width, $height)
}
}

function GetFolder($number){
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.rootfolder = "MyComputer"

    if($foldername.ShowDialog() -eq "OK")
    {
        $folder += $foldername.SelectedPath
    }

if ($folder){
$Foldertest = "foldertest$($number)"
$Foldertestbox = Get-Variable $Foldertest
$Foldertestbox.Value.TEXT = $folder
}
}

function GetOutputFolder{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.rootfolder = "MyComputer"

    if($foldername.ShowDialog() -eq "OK")
    {
        $folder += $foldername.SelectedPath
    }

if ($folder){
$outputbox = Get-Variable "FolderOutput"
$outputbox.Value.TEXT = $folder
}
}

function GetFile{
 $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
 $OpenFileDialog.initialDirectory = "MyComputer"
 $OpenFileDialog.filter = "CSV (*.CSV)| *.CSV"
 $OpenFileDialog.ShowDialog() | Out-Null
 Write-output $OpenFileDialog.FileName
 }

Function SaveFile{ 
$SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
$SaveFileDialog.initialDirectory = "MyComputer"
$SaveFileDialog.filter = "CSV (*.CSV)| *.CSV"
$SaveFileDialog.ShowDialog() | Out-Null
Write-output $SaveFileDialog.filename
} 

Function Test-StoragePerformance {
 param(
 [ValidateNotNullOrEmpty()]  
 [String]$Name,
 [ValidateNotNullOrEmpty()]
 [ValidateRange(0,100)]  
 [int]$WritePercentage,
 [ValidateNotNullOrEmpty()] 
 [int]$Duration,
 [ValidateNotNullOrEmpty()] 
 [string]$Blocksize,
 [ValidateNotNullOrEmpty()]
 [ValidateSet('Random','Sequential')]
 [string]$AccessType,
 [ValidateNotNullOrEmpty()]
 [int]$Threads, 
 [ValidateNotNullOrEmpty()] 
 [int]$OutstandingIO,
 [ValidateNotNullOrEmpty()]
 [string]$Path,
 [ValidateNotNullOrEmpty()]
 [string]$TestFileSize
 )

 #TestFileSizeParameter
 $TestFileSizeParameter = ("-c"+$TestFileSize+"G")

#Duration
$DurationParameter = "-d"+$Duration

# Outstanding IOs, Between  8 and 16 is generally fine
$OutstandingIOParameter = "-o"+$OutstandingIO

#Blocksize
$BlockSizeParameter = ("-b"+$Blocksize+"K")
$Blocksize = ($Blocksize+"K")

#Read/Write Percentage
if ($WritePercentage -eq 0){$IO = "100% Read"}
if ($WritePercentage -eq 100){$IO = "100% Write"}
if ($WritePercentage -ne 0 -and $WritePercentage -ne 100 ){$readpercentage = 100-$writepercentage;  $IO = "$readpercentage% Read / $writepercentage% Write"}
$WriteParameter = "-w"+$WritePercentage

#AccessType
if ($AccessType -eq "Random"){$AccessTypeParameter = "-r"}
if ($AccessType -eq "Sequential"){$AccessTypeParameter = "-si"}

#TheadParameter
$ThreadParameter = "-t"+$Threads

#Path
$PathParameter = $Path

$result = .\diskspd.exe $TestFileSizeParameter $DurationParameter $AccessTypeParameter $WriteParameter $ThreadParameter $OutstandingIOParameter $BlockSizeParameter -Sh -L $PathParameter\testfile.dat

#Remove test file
if ($DeleteTestFileCheckbox.Checked -eq $true){
remove-item $PathParameter\testfile.dat  -Force -ErrorAction SilentlyContinue
}



# Now we will break the very verbose output of DiskSpd in a single line with the most important values
if ($result){
foreach ($line in $result) {if ($line -like "total:*") { $total=$line; break } }
foreach ($line in $result) {if ($line -like "avg.*") { $avg=$line; break } }

if ($total){
$mbps = $total.Split("|")[2].Trim() 

$iops = $total.Split("|")[3].Trim()

$latency = $total.Split("|")[4].Trim()
}
else {
$mbps = 0
$iops = 0
$latency = 0
write-host "No results, probably no rights for creating test file in $PathParameter" -ForegroundColor Yellow
}
if ($avg){
$cpu = $avg.Split("|")[1].Trim()
}
else {$cpu = 0}

     
# Create array with output
$TestOutput = @{"Name" = $Name; "Path" = $Path; "IO" = $IO; "AccessType" = $AccessType;"Blocksize" = $Blocksize;"OutstandingIO" = $OutstandingIO;"Threads" = $Threads;"iops" = $iops;"mbps" = $mbps;"latency" = $latency;"CPU" = $cpu}

Write-Output $TestOutput
}
}

Function PerformTests{

ClearResults

[string]$ReportFilePath = $FolderOutput.Text
[string]$ReportFileNamePrefix = "StoragePerformanceReport"
[string]$Hostname = $env:computername
$TestFileSizeGB = $TestFilesizeDropdown.Text
               
# Log and report file/folder
$FileTimeSuffix = ((Get-Date -Format dMMMyy).ToString()) + "-" + ((get-date -Format hhmm).ToString())

If ($HTMLcheckbox.Checked -eq $true){
#region html
# State Colors
[array]$stateBgColors = "", "#ACFA58","#E6E6E6","#FB7171","#FBD95B","#BDD7EE" #0-Null, 1-Online(green), 2-Offline(grey), 3-Failed/Critical(red), 4-Warning(orange), 5-Other(blue)
[array]$stateWordColors = "", "#298A08","#848484","#A40000","#9C6500","#204F7A","#FFFFFF" #0-Null, 1-Online(green), 2-Offline(grey), 3-Failed/Critical(red), 4-Warning(orange), 5-Other(blue), 6-White

# Date and Time
$Date = Get-Date -Format d/MMM/yyyy
$Time = Get-Date -Format "hh:mm:ss tt"

$ReportFile = $ReportFilePath + "\" + $ReportFileNamePrefix + "-" + $FileTimeSuffix + ".html"


$LogFile = $ReportFilePath + "\" + "ScriptLog" + ".txt"

# Logging enabled
[bool]$Logging = $True

# HighlightsOnly Mode String
$hlString = $null
if ($HighlightsOnly)
{
    $hlString = "<center><span style=""padding-top:1px;padding-bottom:1px;font-size:12px;background-color:#FBD95B;color:#FFFFFF"">&nbsp;(HighlightsOnly Mode)&nbsp;</span></center>"
    
}

# HTML Head
$outHtmlStart = "<!DOCTYPE html>
<html>
<head>
<title>Storage Performance Report</title>
<style>
/*Reset CSS*/
html, body, div, span, applet, object, iframe, h1, h2, h3, h4, h5, h6, p, blockquote, pre, a, abbr, acronym, address, big, cite, code, del, dfn, em, img, ins, kbd, q, s, samp,
small, strike, strong, sub, sup, tt, var, b, u, i, center, dl, dt, dd, ol, ul, li, fieldset, form, label, legend, table, caption, tbody, tfoot, thead, tr, th, td,
article, aside, canvas, details, embed, figure, figcaption, footer, header, hgroup, menu, nav, output, ruby, section, summary, 
time, mark, audio, video {margin: 0;padding: 0;border: 0;font-size: 100%;font: inherit;vertical-align: baseline;}
ol, ul {list-style: none;}
blockquote, q {quotes: none;}
blockquote:before, blockquote:after,
q:before, q:after {content: '';content: none;}
table {border-collapse: collapse;border-spacing: 0;}
/*Reset CSS*/

body{
    width:100%;
    min-width:1024px;
    font-family: Verdana, sans-serif;
    font-size:14px;
    /*font-weight:300;*/
    line-height:1.5;
    color:#222222;
    background-color:#fcfcfc;
}

p{
    color:222222;
}

strong{
    font-weight:600;
}

h1{
    font-size:30px;
    font-weight:300;
}

h2{
    font-size:20px;
    font-weight:300;
}

#ReportBody{
    width:95%;
    height:500;
    /*border: 1px solid;*/
    margin: 0 auto;
}

.Overview{
    width:100%;
	min-width:1280px;
    margin-bottom:30px;
}

.OverviewFrame{
    background:#F9F9F9;
    border: 1px solid #CCCCCC;
}

table#Overview-Table{
    width:100%;
    border: 0px solid #CCCCCC;
    background:#F9F9F9;
    margin-top:0px;
}

table#Overview-Table td {
    padding:0px;
    border: 0px solid #CCCCCC;
    text-align:center;
    vertical-align:middle;
}

.VMHosts{
    width:100%;
    /*height:200px;*/
    /*border: 1px solid;*/
    float:left;
    margin-bottom:30px;
}

table#VMHosts-Table tr:nth-child(odd){
    background:#F9F9F9;
}

table#Disks-Volumes-Table tr:nth-child(odd){
    background:#F9F9F9;
}

.Disks-Volumes{
    width:100%;
    /*height:400px;*/
    /*border: 1px solid;*/
    float:left;
    margin-bottom:30px;
}

.Tests{
    width:100%;
    /*height:200px;*/
    /*border: 1px solid;*/
    float:left;
    margin-bottom:22px;
    line-height:1.5;
}

table{
    width:100%;
    min-width:1280px;
    /*table-layout: fixed;*/
    /*border-collapse: collapse;*/
    border: 1px solid #CCCCCC;
    /*margin-bottom:15px;*/
}

/*Row*/
tr{
    font-size: 12px;
}

/*Column*/
td {
    padding:10px 8px 10px 8px;
    font-size: 12px;
    border: 1px solid #CCCCCC;
    text-align:center;
    vertical-align:middle;
}

/*Table Heading*/
th {
    background: #f3f3f3;
    border: 1px solid #CCCCCC;
    font-size: 14px;
    font-weight:normal;
    padding:12px;
    text-align:center;
    vertical-align:middle;
}
</style>
</head>
<body>
<br><br>
<center><h1>Storage Performance Report - $Hostname</h1></center>
<center><font face=""Verdana,sans-serif"" size=""3"" color=""#222222"">Generated on $($Date) at $($Time)</font></center>
$($hlString)
<br>
<div id=""ReportBody""><!--Start ReportBody-->"
#endregion

#region Gathering Performance Information
#-------------------------------

# Print MSG


$outVMTableStart = "
    <div class=""Tests""><!--Start Tests Class-->
        <h2>Performance Tests</h2><br>
        <table>
        <tbody>
            <tr><!--Header Line-->
                <th><p style=""text-align:left;margin-left:-4px"">Name</p></th>
                <th><p>Path</p></th>
                <th width='80'><p>Block size</p></th>
                <th><p>Operation</p></th>
                <th><p>Read / Write</p></th>
                <th width='20'><p>Outstanding IO</p></th>
                <th width='20'><p>Threads</p></th>
                <th><p>IOPS</p></th>
                <th><p>MB/sec</p></th>
                <th><p>Latency</p></th>
                <th><p>CPU %</p></th>
            </tr>"

# Generate Data Lines
$outVmTable = $null
$cntVM = 0
$vmNoInTable = 0
$ovRunningVm = 0
$ovPausedVm = 0
}
If ($CSVcheckbox.Checked -eq $true){
$CSVReportFile = $ReportFilePath + "\" + $ReportFileNamePrefix + "-" + $FileTimeSuffix + ".csv"
"Test Name, Drive, Operation, Access, Blocks, IOPS, MB/sec, Latency ms, CPU %" | out-file $CSVReportFile -Append
}

$TestDetails = GetTestDetails
$ActiveTests = GetActiveTests
$performancetests = @()
$ActiveTests | % {
$NameTest = $TestDetails.Get_item("NameTest$_")
$FolderTest = $TestDetails.Get_item("FolderTest$_")
$BlocksizeTest = $TestDetails.Get_item("BlocksizeTest$_")
$ReadPercTest = $TestDetails.Get_item("ReadPercTest$_")
$WritePercTest = $TestDetails.Get_item("WritePercTest$_")
$OutstandingIOTest = $TestDetails.Get_item("OutstandingIOTest$_")
$AccessTypeTest = $TestDetails.Get_item("AccessTypeTest$_")
$ThreadsTest = $TestDetails.Get_item("ThreadsTest$_")
$DurationTest = $TestDetails.Get_item("DurationTest$_")

#Strip the "k" for blocksize
$BlocksizeTest = $BlocksizeTest -replace "k" , ""

#Display in progress test
$TestResultMBPS = "TestResultMBPSTest$($_)"
$TestResultMBPSvar = Get-Variable $TestResultMBPS
$TestResultMBPSvar.Value.TEXT = "Test in progress..."
$TestResultMBPSvar.Value.visible = $true

#Dont show IOPS text
$TestResultIOPS = "TestResultIOPSTest$($_)"
$TestResultIOPSvar = Get-Variable $TestResultIOPS
$TestResultIOPSvar.Value.visible = $false

$outcome = Test-StoragePerformance -Name $NameTest -TestFileSize $TestFileSizeGB -WritePercentage $WritePercTest -Duration $DurationTest -Blocksize $BlocksizeTest -AccessType $AccessTypeTest -Threads $ThreadsTest -OutstandingIO $OutstandingIOTest -Path $FolderTest

#Display MBPS result
$TestResultMBPSvar.Value.TEXT = "$($outcome.mbps)"
#Display IOPS result
$TestResultIOPSvar.Value.TEXT = "$($outcome.iops)"
$TestResultIOPSvar.Value.visible = $true


If ($CSVcheckbox.Checked -eq $true)
{
$CSVReportFile = $ReportFilePath + "\" + $ReportFileNamePrefix + "-" + $FileTimeSuffix + ".csv"
"$($outcome.name),$($outcome.path),$($outcome.Accesstype),$($outcome.io),$($outcome.Blocksize),$($outcome.iops),$($outcome.mbps),$($outcome.latency),$($outcome.CPU)" | out-file $CSVReportFile -Append
}
If ($HTMLcheckbox.Checked -eq $true){
$performancetests += $outcome
}
}


If ($HTMLcheckbox.Checked -eq $true){
$counter = 1


ForEach ($performancetest in $performancetests) {
   
            
            $counter++
            # Table TR Color
            if([bool]!($counter%2))
            {
               #Even or Zero
               $vmTableTrBgColor = ""
            }
            else
            {
               #Odd
               $vmTableTrBgColor = "#F9F9F9"
            }



            # Data Line
            $chargerVmTable +="
            <tr style=""background:$($vmTableTrBgColor)""><!--Data Line-->
                <!--Name-->
                <td rowspan=""$($rowSpanCount)""><p style=""text-align:left"">$($performancetest.name)</span></p></td>
                <!--Path-->
                <td rowspan=""$($rowSpanCount)""><p>$($performancetest.path)</p></td>
                <!--Blocksize Size-->
                <td rowspan=""$($rowSpanCount)""><p>$($performancetest.blocksize)</p></td>
                <!--Operation-->
                <td rowspan=""$($rowSpanCount)""><p>$($performancetest.Accesstype)</p></td>
                <!--Write Percentage-->
                <td rowspan=""$($rowSpanCount)""><p>$($performancetest.IO)</p></td>
                <!--Outstanding IO-->
                <td rowspan=""$($rowSpanCount)""><p>$($performancetest.outstandingio)</p></td>
                <!--Threads-->
                <td rowspan=""$($rowSpanCount)""><p>$($performancetest.threads)</p></td>
                <!--IOPS-->
                <td rowspan=""$($rowSpanCount)""><p>$($performancetest.IOPS)</p></td>
                 <!--MB/sec-->
                <td rowspan=""$($rowSpanCount)""><p>$($performancetest.mbps)</p></td>
                <!--Latency-->
                <td rowspan=""$($rowSpanCount)""><p>$($performancetest.latency)</p></td>
                <!--CPU-->
                <td rowspan=""$($rowSpanCount)""><p>$($performancetest.cpu)</p></td>
                "

		      

            # Output Data
            if ($HighlightsOnly -eq $false)
            {
                $outVMTable += $chargerVmTable
                $vmNoInTable = $vmNoInTable + 1
            }
            elseif (($HighlightsOnly -eq $true) -and ($highL -eq $true))
            {      
                $outVMTable += $chargerVmTable
                $vmNoInTable = $vmNoInTable + 1
            }
            else
            {
                # Blank
            }
        }
    

    $outVMTable += $chargerVmTable



# VMs Table - End
$outVMTableEnd ="
        </tbody>
        </table>
    </div><!--End VMs Class-->"

#endregion

#region HTML End
#---------------

$outHtmlEnd ="
</div><!--End ReportBody-->
<center><p style=""font-size:12px;color:#BDBDBD"">ScriptVersion: 0.9 | Created By: Darryl van der Peijl - Hyper-V MVP - @DarrylvdPeijl | Feedback: DarrylvanderPeijl@outlook.com</p></center>
<br>
</body>
</html>"

# Print MSG
$outFullHTML = $outHtmlStart + $outVMHostTableStart + $outVMHostTable + $outVMHostTableEnd + $outVolumeTableStart + $outVolumeTable + $outVolumeTableEnd + $outVMTableStart + $outVMTable + $outVMTableEnd + $outHtmlEnd

$outFullHTML | Out-File $ReportFile



#endregion
}
#Display Popup
If ($HTMLcheckbox.Checked -eq $true -or $CSVcheckbox.Checked -eq $true){
[Windows.Forms.MessageBox]::Show(“Tests completed.`nReports are placed in $ReportFilePath”, “DiskSpeed”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
}
else {
[Windows.Forms.MessageBox]::Show(“Tests completed.”, “DiskSpeed”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
}
}

Function CheckFordiskspd{
        if (!(Test-Path $PSScriptRoot\diskspd.exe)){
           do{
           $result = [Windows.Forms.MessageBox]::Show("Diskspd.exe not present!`nDownload and place in same directory as Diskspeed.”, “DiskSpeed", [Windows.Forms.MessageBoxButtons]::RetryCancel , [Windows.Forms.MessageBoxIcon]::Error)
           if ($result -eq "Cancel"){exit}
           }
           while (!(Test-Path $PSScriptRoot\diskspd.exe))
              }              
           }

Function ClearResults{
1,2,3,4,5,6,7,8,9,10 | % {
$TestResultMBPS = "TestResultMBPSTest$($_)"
$TestResultMBPSvar = Get-Variable $TestResultMBPS
$TestResultMBPSvar.Value.visible = $false
$TestResultMBPSvar.Value.TEXT = ""

$TestResultIOPS = "TestResultIOPSTest$($_)"
$TestResultIOPSvar = Get-Variable $TestResultIOPS
$TestResultIOPSvar.Value.visible = $false
$TestResultMBPSvar.Value.TEXT = ""
}

}

#region MenuLabels

$TestNameLabel = New-Object windows.Forms.Label
$TestNameLabel.Location = New-Object System.Drawing.Size(60,170) 
$TestNameLabel.AutoSize = $true
$TestNameLabel.Text = "Test Name"

$TestLocationLabel = New-Object windows.Forms.Label
$TestLocationLabel.Location = New-Object System.Drawing.Size(210,170) 
$TestLocationLabel.AutoSize = $true
$TestLocationLabel.Text = "Location"

$TestBlocksizeLabel = New-Object windows.Forms.Label
$TestBlocksizeLabel.Location = New-Object System.Drawing.Size(435,170) 
$TestBlocksizeLabel.AutoSize = $true
$TestBlocksizeLabel.Text = "Blocksize"

$TestReadWriteLabel = New-Object windows.Forms.Label
$TestReadWriteLabel.Location = New-Object System.Drawing.Size(507,170) 
$TestReadWriteLabel.AutoSize = $true
$TestReadWriteLabel.Text = "Read/Write"

$TestOutstandingIOLabel = New-Object windows.Forms.Label
$TestOutstandingIOLabel.Location = New-Object System.Drawing.Size(595,160) 
$TestOutstandingIOLabel.AutoSize = $true
$TestOutstandingIOLabel.Text = "Out.`n I/O"
$TestOutstandingIOLabel.MaximumSize = New-Object System.Drawing.Size(50,0) 
$TestOutstandingIOLabel.AutoSize = $true

$TestAccessTypeLabel = New-Object windows.Forms.Label
$TestAccessTypeLabel.Location = New-Object System.Drawing.Size(635,170) 
$TestAccessTypeLabel.AutoSize = $true
$TestAccessTypeLabel.Text = "Access Type"

$TestWorkersLabel = New-Object windows.Forms.Label
$TestWorkersLabel.Location = New-Object System.Drawing.Size(724,170) 
$TestWorkersLabel.AutoSize = $true
$TestWorkersLabel.Text = "Workers"


$TestDurationLabel = New-Object windows.Forms.Label
$TestDurationLabel.Location = New-Object System.Drawing.Size(783,160) 
$TestDurationLabel.AutoSize = $true
$TestDurationLabel.Text = "Duration`n  Sec."

$TestResultMBpsLabel = New-Object windows.Forms.Label
$TestResultMBpsLabel.Location = New-Object System.Drawing.Size(863,170) 
$TestResultMBpsLabel.AutoSize = $true
$TestResultMBpsLabel.Text = "MBps"

$TestResultIOPSLabel = New-Object windows.Forms.Label
$TestResultIOPSLabel.Location = New-Object System.Drawing.Size(940,170) 
$TestResultIOPSLabel.AutoSize = $true
$TestResultIOPSLabel.Text = "IOPS"




#endregion

#region Menu
$groupBoxMenu = New-Object System.Windows.Forms.GroupBox #create the group box
$groupBoxMenu.Location = New-Object System.Drawing.Size(400,30) #location of the group box (px) in relation to the primary window's edges (length, height)
$groupBoxMenu.size = New-Object System.Drawing.Size(400,50) #the size in px of the group box (length, height)

$GroupBoxTests = New-Object System.Windows.Forms.GroupBox #create the group box
$GroupBoxTests.Location = New-Object System.Drawing.Size(50,15) #location of the group box (px) in relation to the primary window's edges (length, height)
$GroupBoxTests.size = New-Object System.Drawing.Size(150,110) #the size in px of the group box (length, height)
$GroupBoxTests.text = "Tests"

$GroupBoxImpExp = New-Object System.Windows.Forms.GroupBox #create the group box
$GroupBoxImpExp.Location = New-Object System.Drawing.Size(230,15) #location of the group box (px) in relation to the primary window's edges (length, height)
$GroupBoxImpExp.size = New-Object System.Drawing.Size(150,110) #the size in px of the group box (length, height)
$GroupBoxImpExp.text = "Config"

$GroupBoxOutput = New-Object System.Windows.Forms.GroupBox #create the group box
$GroupBoxOutput.Location = New-Object System.Drawing.Size(410,15) #location of the group box (px) in relation to the primary window's edges (length, height)
$GroupBoxOutput.size = New-Object System.Drawing.Size(200,110) #the size in px of the group box (length, height)
$GroupBoxOutput.text = "Output"

$GroupBoxSettings = New-Object System.Windows.Forms.GroupBox #create the group box
$GroupBoxSettings.Location = New-Object System.Drawing.Size(645,15) #location of the group box (px) in relation to the primary window's edges (length, height)
$GroupBoxSettings.size = New-Object System.Drawing.Size(200,110) #the size in px of the group box (length, height)
$GroupBoxSettings.text = "Settings"



# Add button
$Addbutton = new-Object windows.Forms.Button;
$Addbutton.Text = "Add Test"
$Addbutton.Location = New-Object System.Drawing.Size(20,25) 
$Addbutton.Size = New-Object System.Drawing.Size(100,30)
$Addbutton.add_click($function:AddTest);
$GroupBoxTests.Controls.Add($Addbutton) 

# Remove button
$Removebutton = new-Object windows.Forms.Button;
$Removebutton.Text = "Remove Test"
$Removebutton.Location = New-Object System.Drawing.Size(20,70) 
$Removebutton.Size = New-Object System.Drawing.Size(100,30)
$Removebutton.add_click($function:RemoveTest);
$GroupBoxTests.Controls.Add($Removebutton) 

# Export button
$ExportButton = new-Object windows.Forms.Button;
$ExportButton.Text = "Export"
$ExportButton.Size = New-Object System.Drawing.Size(100,30)
$ExportButton.Location = New-Object System.Drawing.Size(20,70) 
$ExportButton.add_click($function:ExportConfig);
$GroupBoxImpExp.Controls.Add($ExportButton) 

# Import button
$ImportButton = new-Object windows.Forms.Button;
$ImportButton.Text = "Import"
$ImportButton.Size = New-Object System.Drawing.Size(100,30)
$ImportButton.Location = New-Object System.Drawing.Size(20,25) 
$ImportButton.add_click($function:ImportConfig);
$GroupBoxImpExp.Controls.Add($ImportButton) 

# HTML output checkbox
$HTMLcheckbox = new-Object windows.Forms.checkbox;
$HTMLcheckbox.Location = New-Object System.Drawing.Size(170,20) 
$HTMLcheckbox.Size = New-Object System.Drawing.Size(20,30)
$groupBoxOutput.Controls.Add($HTMLcheckbox) 

# CSV output checkbox
$CSVcheckbox = new-Object windows.Forms.checkbox;
$CSVcheckbox.Location = New-Object System.Drawing.Size(170,47) 
$CSVcheckbox.Size = New-Object System.Drawing.Size(20,30)
$groupBoxOutput.Controls.Add($CSVcheckbox)

#HTML Report Label
$HTMLReportLabel = New-Object windows.Forms.Label
$HTMLReportLabel.Location = New-Object System.Drawing.Size(10,24) 
$HTMLReportLabel.AutoSize = $true
$HTMLReportLabel.Text = "HTML Report"
$groupBoxOutput.Controls.Add($HTMLReportLabel)

#CSV Report Label
$CSVReportLabel = New-Object windows.Forms.Label
$CSVReportLabel.Location = New-Object System.Drawing.Size(10,52) 
$CSVReportLabel.AutoSize = $true
$CSVReportLabel.Text = "CSV Report"
$groupBoxOutput.Controls.Add($CSVReportLabel)

$FolderOutput = New-Object System.Windows.Forms.TextBox 
$FolderOutput.Location = New-Object System.Drawing.Size(12,80) 
$FolderOutput.Size = New-Object System.Drawing.Size(140,20) 
$FolderOutput.Text = (Get-Location).path
$groupBoxOutput.Controls.Add($FolderOutput) 

# Folder button
$FolderbuttonOutput = new-Object windows.Forms.Button;
$FolderbuttonOutput.Text = ".."
$FolderbuttonOutput.Location = New-Object System.Drawing.Size(167,80) 
$FolderbuttonOutput.Size = New-Object System.Drawing.Size(24,20) 
$FolderbuttonOutput.add_click({GetOutputFolder});
$groupBoxOutput.Controls.Add($FolderbuttonOutput) 

#Test File Size Label
$TestFileSizeLabel = New-Object windows.Forms.Label
$TestFileSizeLabel.Location = New-Object System.Drawing.Size(10,24) 
$TestFileSizeLabel.AutoSize = $true
$TestFileSizeLabel.Text = "Test File Size (GB)"
$groupBoxSettings.Controls.Add($TestFileSizeLabel)

#Test File Size Dropdown
$TestFilesizeDropdown = new-object System.Windows.Forms.ComboBox
$TestFilesizeDropdown.Location = new-object System.Drawing.Size(150,22) 
$TestFilesizeDropdown.Size = new-object System.Drawing.Size(40,30)
$TestFilesizeDropdown.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropdown
foreach ($TestFileSize in $TestFileSizes) {$TestFilesizeDropdown.Items.Add($TestFileSize) | out-null}
$groupBoxSettings.Controls.Add($TestFilesizeDropdown) 
$TestFilesizeDropdown.SelectedItem = $TestFilesizeDropdown.Items[0]

#Test File Delete Label
$DeleteTestFileLabel = New-Object windows.Forms.Label
$DeleteTestFileLabel.Location = New-Object System.Drawing.Size(10,54) 
$DeleteTestFileLabel.AutoSize = $true
$DeleteTestFileLabel.Text = "Delete Test File"
$groupBoxSettings.Controls.Add($DeleteTestFileLabel)

#Test File Delete checkbox
$DeleteTestFileCheckbox = new-Object windows.Forms.checkbox;
$DeleteTestFileCheckbox.Location = New-Object System.Drawing.Size(150,49) 
$DeleteTestFileCheckbox.Size = New-Object System.Drawing.Size(20,30)
$DeleteTestFileCheckbox.Checked = $true
$groupBoxSettings.Controls.Add($DeleteTestFileCheckbox) 

#endregion

#region Start
$groupBoxStart = New-Object System.Windows.Forms.GroupBox #create the group box
$groupBoxStart.Location = New-Object System.Drawing.Size(50,440) #location of the group box (px) in relation to the primary window's edges (length, height)
$groupBoxStart.size = New-Object System.Drawing.Size(790,50) #the size in px of the group box (length, height)

# Start button
$Startbutton = new-Object windows.Forms.Button;
$Startbutton.Text = "Start Tests"
$Startbutton.Location = New-Object System.Drawing.Size(10,13) 
$Startbutton.Size = New-Object System.Drawing.Size(100,30)
$Startbutton.add_click($function:PerformTests);
$groupBoxStart.Controls.Add($Startbutton) 

# Test button
$TestButton = new-Object windows.Forms.Button;
$TestButton.Text = "Test"
$TestButton.visible = $false
$TestButton.Size = New-Object System.Drawing.Size(100,30)
$TestButton.Location = New-Object System.Drawing.Size(170,13) 
$TestButton.add_click($function:CheckFordiskspd);
$groupBoxStart.Controls.Add($TestButton) 

#endregion

#region Test1
$groupBoxTest1 = New-Object System.Windows.Forms.GroupBox #create the group box
$groupBoxTest1.Location = New-Object System.Drawing.Size(50,190) #location of the group box (px) in relation to the primary window's edges (length, height)
$groupBoxTest1.size = New-Object System.Drawing.Size(790,50) #the size in px of the group box (length, height)

$NameTest1 = New-Object System.Windows.Forms.TextBox 
$NameTest1.Location = New-Object System.Drawing.Size(10,20) 
$NameTest1.Size = New-Object System.Drawing.Size(140,20) 
$NameTest1.Text = "Database Server"
$groupBoxTest1.Controls.Add($NameTest1) 

$FolderTest1 = New-Object System.Windows.Forms.TextBox 
$FolderTest1.Location = New-Object System.Drawing.Size(155,20) 
$FolderTest1.Size = New-Object System.Drawing.Size(200,20) 
$FolderTest1.Text = "C:\ClusterStorage\Volume1"
$groupBoxTest1.Controls.Add($FolderTest1) 

# Folder button
$FolderbuttonTest1 = new-Object windows.Forms.Button;
$FolderbuttonTest1.Text = "..."
$FolderbuttonTest1.Location = New-Object System.Drawing.Size(355,20) 
$FolderbuttonTest1.Size = New-Object System.Drawing.Size(30,20) 
$FolderbuttonTest1.add_click({GetFolder "1"});
$groupBoxTest1.Controls.Add($FolderbuttonTest1) 

#Blocksize Dropdown
$BlocksizeTest1 = new-object System.Windows.Forms.ComboBox
$BlocksizeTest1.Location = new-object System.Drawing.Size(390,20) 
$BlocksizeTest1.Size = new-object System.Drawing.Size(60,30)
$BlocksizeTest1.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropdown
foreach ($blocksize in $blocksizes) {$BlocksizeTest1.Items.Add($blocksize) | out-null}
$groupBoxTest1.Controls.Add($BlocksizeTest1) 
$BlocksizeTest1.SelectedItem = $BlocksizeTest1.Items[1]

#Read / Write 
$ReadPercTest1 = New-Object System.Windows.Forms.TextBox 
$ReadPercTest1.Location = New-Object System.Drawing.Size(460,20) 
$ReadPercTest1.Size = New-Object System.Drawing.Size(30,20) 
$ReadPercTest1.Text = "70"
$ReadPercTest1.MaxLength = 3
$ReadPercTest1.Add_TextChanged({
$WritePercTest1.Text = (100 - $ReadPercTest1.Text)
})
$groupBoxTest1.Controls.Add($ReadPercTest1) 

$WritePercTest1 = New-Object System.Windows.Forms.TextBox 
$WritePercTest1.Location = New-Object System.Drawing.Size(495,20) 
$WritePercTest1.Size = New-Object System.Drawing.Size(30,20) 
$WritePercTest1.Text = "30"
$WritePercTest1.Enabled = $false
$groupBoxTest1.Controls.Add($WritePercTest1) 

#OutstandingIO Dropdown
$OutstandingIOTest1 = new-object System.Windows.Forms.ComboBox
$OutstandingIOTest1.Location = new-object System.Drawing.Size(540,20) 
$OutstandingIOTest1.Size = new-object System.Drawing.Size(40,30)
$OutstandingIOTest1.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropdown
foreach ($OutstandingIO in $OutstandingIOs) {$OutstandingIOTest1.Items.Add($OutstandingIO) | out-null}
$OutstandingIOTest1.Add_TextChanged({if ($OutstandingIOTest1.text -eq 0) {$OutstandingIOTest1.SelectedItem = $OutstandingIOTest1.Items[0]}})
$groupBoxTest1.Controls.Add($OutstandingIOTest1)
$OutstandingIOTest1.SelectedItem = $OutstandingIOTest1.Items[3]

#AccessType Dropdown
$AccessTypeTest1 = new-object System.Windows.Forms.ComboBox
$AccessTypeTest1.Location = new-object System.Drawing.Size(590,20) 
$AccessTypeTest1.Size = new-object System.Drawing.Size(80,30)
$AccessTypeTest1.BackColor = 'White'
$AccessTypeTest1.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$AccessTypeTest1.Items.Add("Random") | out-null
$AccessTypeTest1.Items.Add("Sequential") | out-null
$AccessTypeTest1.SelectedItem = $AccessTypeTest1.Items[0]
$groupBoxTest1.Controls.Add($AccessTypeTest1) 

#threads Dropdown
$ThreadsTest1 = new-object System.Windows.Forms.ComboBox
$ThreadsTest1.Location = new-object System.Drawing.Size(680,20) 
$ThreadsTest1.Size = new-object System.Drawing.Size(40,30)
$ThreadsTest1.BackColor = 'White'
$ThreadsTest1.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
$ThreadsTest1.Text = "1"
$ThreadsTest1.SelectedItem
foreach ($Thread in $Threads) {$ThreadsTest1.Items.Add($Thread) | out-null}
$groupBoxTest1.Controls.Add($ThreadsTest1) 

#Duration Dropdown
$DurationTest1 = new-object System.Windows.Forms.ComboBox
$DurationTest1.Location = new-object System.Drawing.Size(730,20) 
$DurationTest1.Size = new-object System.Drawing.Size(48,30)
$DurationTest1.BackColor = 'White'
$DurationTest1.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
$DurationTest1.Text = "30"
$DurationTest1.SelectedItem
foreach ($Duration in $Durations) {$DurationTest1.Items.Add($Duration) | out-null}
$groupBoxTest1.Controls.Add($DurationTest1) 

$ResultBoxTest1 = New-Object System.Windows.Forms.GroupBox #create the group box
$ResultBoxTest1.Location = New-Object System.Drawing.Size(850,190) #location of the group box (px) in relation to the primary window's edges (length, height)
$ResultBoxTest1.size = New-Object System.Drawing.Size(150,50) #the size in px of the group box (length, height)

#Test Result MBps Label
$TestResultMBPSTest1 = New-Object windows.Forms.Label
$TestResultMBPSTest1.Location = New-Object System.Drawing.Size(15,18) 
$TestResultMBPSTest1.AutoSize = $true
$TestResultMBPSTest1.visible = $false
$ResultBoxTest1.Controls.Add($TestResultMBPSTest1)

#Test Result IOPS Label
$TestResultIOPSTest1 = New-Object windows.Forms.Label
$TestResultIOPSTest1.Location = New-Object System.Drawing.Size(90,18) 
$TestResultIOPSTest1.AutoSize = $true
$TestResultIOPSTest1.visible = $false
$ResultBoxTest1.Controls.Add($TestResultIOPSTest1)

#endregion 

#region Test2
$groupBoxTest2 = New-Object System.Windows.Forms.GroupBox #create the group box
$groupBoxTest2.Location = New-Object System.Drawing.Size(50,240) #location of the group box (px) in relation to the primary window's edges (length, height)
$groupBoxTest2.size = New-Object System.Drawing.Size(790,50) #the size in px of the group box (length, height)

$NameTest2 = New-Object System.Windows.Forms.TextBox 
$NameTest2.Location = New-Object System.Drawing.Size(10,20) 
$NameTest2.Size = New-Object System.Drawing.Size(140,20) 
$NameTest2.Text = "Email Server"
$groupBoxTest2.Controls.Add($NameTest2) 

$FolderTest2 = New-Object System.Windows.Forms.TextBox 
$FolderTest2.Location = New-Object System.Drawing.Size(155,20) 
$FolderTest2.Size = New-Object System.Drawing.Size(200,20) 
$FolderTest2.Text = "\\SOFS01\Share1"
$groupBoxTest2.Controls.Add($FolderTest2) 

# Folder button
$FolderbuttonTest2 = new-Object windows.Forms.Button;
$FolderbuttonTest2.Text = "..."
$FolderbuttonTest2.Location = New-Object System.Drawing.Size(355,20) 
$FolderbuttonTest2.Size = New-Object System.Drawing.Size(30,20) 
$FolderbuttonTest2.add_click({GetFolder "2"});
$groupBoxTest2.Controls.Add($FolderbuttonTest2) 

#Blocksize Dropdown
$BlocksizeTest2 = new-object System.Windows.Forms.ComboBox
$BlocksizeTest2.Location = new-object System.Drawing.Size(390,20) 
$BlocksizeTest2.Size = new-object System.Drawing.Size(60,30)
$BlocksizeTest2.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropdown
foreach ($blocksize in $blocksizes) {$BlocksizeTest2.Items.Add($blocksize) | out-null}
$groupBoxTest2.Controls.Add($BlocksizeTest2) 
$BlocksizeTest2.SelectedItem = $BlocksizeTest2.Items[0]

#Read / Write 
$ReadPercTest2 = New-Object System.Windows.Forms.TextBox 
$ReadPercTest2.Location = New-Object System.Drawing.Size(460,20) 
$ReadPercTest2.Size = New-Object System.Drawing.Size(30,20) 
$ReadPercTest2.Text = "60"
$ReadPercTest2.MaxLength = 3
$ReadPercTest2.Add_TextChanged({
$WritePercTest2.Text = (100 - $ReadPercTest2.Text)

})
$groupBoxTest2.Controls.Add($ReadPercTest2) 

$WritePercTest2 = New-Object System.Windows.Forms.TextBox 
$WritePercTest2.Location = New-Object System.Drawing.Size(495,20) 
$WritePercTest2.Size = New-Object System.Drawing.Size(30,20) 
$WritePercTest2.Text = "40"
$WritePercTest2.Enabled = $false
$groupBoxTest2.Controls.Add($WritePercTest2) 

#OutstandingIO Dropdown
$OutstandingIOTest2 = new-object System.Windows.Forms.ComboBox
$OutstandingIOTest2.Location = new-object System.Drawing.Size(540,20) 
$OutstandingIOTest2.Size = new-object System.Drawing.Size(40,30)
$OutstandingIOTest2.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropdown
foreach ($OutstandingIO in $OutstandingIOs) {$OutstandingIOTest2.Items.Add($OutstandingIO) | out-null}
$OutstandingIOTest2.Add_TextChanged({if ($OutstandingIOTest2.text -eq 0) {$OutstandingIOTest2.SelectedItem = $OutstandingIOTest2.Items[0]}})
$groupBoxTest2.Controls.Add($OutstandingIOTest2)
$OutstandingIOTest2.SelectedItem = $OutstandingIOTest2.Items[3]

#AccessType Dropdown
$AccessTypeTest2 = new-object System.Windows.Forms.ComboBox
$AccessTypeTest2.Location = new-object System.Drawing.Size(590,20) 
$AccessTypeTest2.Size = new-object System.Drawing.Size(80,30)
$AccessTypeTest2.BackColor = 'White'
$AccessTypeTest2.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$AccessTypeTest2.Items.Add("Random") | out-null
$AccessTypeTest2.Items.Add("Sequential") | out-null
$AccessTypeTest2.SelectedItem = $AccessTypeTest2.Items[0]
$groupBoxTest2.Controls.Add($AccessTypeTest2) 

#threads Dropdown
$ThreadsTest2 = new-object System.Windows.Forms.ComboBox
$ThreadsTest2.Location = new-object System.Drawing.Size(680,20) 
$ThreadsTest2.Size = new-object System.Drawing.Size(40,30)
$ThreadsTest2.BackColor = 'White'
$ThreadsTest2.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
$ThreadsTest2.Text = "1"
$ThreadsTest2.SelectedItem
foreach ($Thread in $Threads) {$ThreadsTest2.Items.Add($Thread) | out-null}
$groupBoxTest2.Controls.Add($ThreadsTest2) 

#Duration Dropdown
$DurationTest2 = new-object System.Windows.Forms.ComboBox
$DurationTest2.Location = new-object System.Drawing.Size(730,20) 
$DurationTest2.Size = new-object System.Drawing.Size(48,30)
$DurationTest2.BackColor = 'White'
$DurationTest2.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
$DurationTest2.Text = "30"
$DurationTest2.SelectedItem
foreach ($Duration in $Durations) {$DurationTest2.Items.Add($Duration) | out-null}
$groupBoxTest2.Controls.Add($DurationTest2) 

$ResultBoxTest2 = New-Object System.Windows.Forms.GroupBox #create the group box
$ResultBoxTest2.Location = New-Object System.Drawing.Size(850,240) #location of the group box (px) in relation to the primary window's edges (length, height)
$ResultBoxTest2.size = New-Object System.Drawing.Size(150,50) #the size in px of the group box (length, height)

#Test Result MBps Label
$TestResultMBPSTest2 = New-Object windows.Forms.Label
$TestResultMBPSTest2.Location = New-Object System.Drawing.Size(15,18) 
$TestResultMBPSTest2.AutoSize = $true
$TestResultMBPSTest2.visible = $false
$ResultBoxTest2.Controls.Add($TestResultMBPSTest2)

#Test Result IOPS Label
$TestResultIOPSTest2 = New-Object windows.Forms.Label
$TestResultIOPSTest2.Location = New-Object System.Drawing.Size(90,18) 
$TestResultIOPSTest2.AutoSize = $true
$TestResultIOPSTest2.visible = $false
$ResultBoxTest2.Controls.Add($TestResultIOPSTest2)

#endregion 

#region Test3
$groupBoxTest3 = New-Object System.Windows.Forms.GroupBox #create the group box
$groupBoxTest3.Location = New-Object System.Drawing.Size(50,290) #location of the group box (px) in relation to the primary window's edges (length, height)
$groupBoxTest3.size = New-Object System.Drawing.Size(790,50) #the size in px of the group box (length, height)

$NameTest3 = New-Object System.Windows.Forms.TextBox 
$NameTest3.Location = New-Object System.Drawing.Size(10,20) 
$NameTest3.Size = New-Object System.Drawing.Size(140,20) 
$NameTest3.Text = "Archical FileServer"
$groupBoxTest3.Controls.Add($NameTest3) 

$FolderTest3 = New-Object System.Windows.Forms.TextBox 
$FolderTest3.Location = New-Object System.Drawing.Size(155,20) 
$FolderTest3.Size = New-Object System.Drawing.Size(200,20) 
$FolderTest3.Text = "C:\ClusterStorage\Volume1"
$groupBoxTest3.Controls.Add($FolderTest3) 

# Folder button
$FolderbuttonTest3 = new-Object windows.Forms.Button;
$FolderbuttonTest3.Text = "..."
$FolderbuttonTest3.Location = New-Object System.Drawing.Size(355,20) 
$FolderbuttonTest3.Size = New-Object System.Drawing.Size(30,20) 
$FolderbuttonTest3.add_click({GetFolder "3"});
$groupBoxTest3.Controls.Add($FolderbuttonTest3) 

#Blocksize Dropdown
$BlocksizeTest3 = new-object System.Windows.Forms.ComboBox
$BlocksizeTest3.Location = new-object System.Drawing.Size(390,20) 
$BlocksizeTest3.Size = new-object System.Drawing.Size(60,30)
$BlocksizeTest3.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropdown
foreach ($blocksize in $blocksizes) {$BlocksizeTest3.Items.Add($blocksize) | out-null}
$groupBoxTest3.Controls.Add($BlocksizeTest3) 
$BlocksizeTest3.SelectedItem = $BlocksizeTest3.Items[4]

#Read / Write 
$ReadPercTest3 = New-Object System.Windows.Forms.TextBox 
$ReadPercTest3.Location = New-Object System.Drawing.Size(460,20) 
$ReadPercTest3.Size = New-Object System.Drawing.Size(30,20) 
$ReadPercTest3.Text = "90"
$ReadPercTest3.MaxLength = 3
$ReadPercTest3.Add_TextChanged({
$WritePercTest3.Text = (100 - $ReadPercTest3.Text)

})
$groupBoxTest3.Controls.Add($ReadPercTest3) 

$WritePercTest3 = New-Object System.Windows.Forms.TextBox 
$WritePercTest3.Location = New-Object System.Drawing.Size(495,20) 
$WritePercTest3.Size = New-Object System.Drawing.Size(30,20) 
$WritePercTest3.Text = "10"
$WritePercTest3.Enabled = $false
$groupBoxTest3.Controls.Add($WritePercTest3) 

#OutstandingIO Dropdown
$OutstandingIOTest3 = new-object System.Windows.Forms.ComboBox
$OutstandingIOTest3.Location = new-object System.Drawing.Size(540,20) 
$OutstandingIOTest3.Size = new-object System.Drawing.Size(40,30)
$OutstandingIOTest3.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropdown
foreach ($OutstandingIO in $OutstandingIOs) {$OutstandingIOTest3.Items.Add($OutstandingIO) | out-null}
$OutstandingIOTest3.Add_TextChanged({if ($OutstandingIOTest3.text -eq 0) {$OutstandingIOTest3.SelectedItem = $OutstandingIOTest3.Items[0]}})
$groupBoxTest3.Controls.Add($OutstandingIOTest3)
$OutstandingIOTest3.SelectedItem = $OutstandingIOTest3.Items[3]

#AccessType Dropdown
$AccessTypeTest3 = new-object System.Windows.Forms.ComboBox
$AccessTypeTest3.Location = new-object System.Drawing.Size(590,20) 
$AccessTypeTest3.Size = new-object System.Drawing.Size(80,30)
$AccessTypeTest3.BackColor = 'White'
$AccessTypeTest3.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$AccessTypeTest3.Items.Add("Random") | out-null
$AccessTypeTest3.Items.Add("Sequential") | out-null
$AccessTypeTest3.SelectedItem = $AccessTypeTest3.Items[1]
$groupBoxTest3.Controls.Add($AccessTypeTest3) 

#threads Dropdown
$ThreadsTest3 = new-object System.Windows.Forms.ComboBox
$ThreadsTest3.Location = new-object System.Drawing.Size(680,20) 
$ThreadsTest3.Size = new-object System.Drawing.Size(40,30)
$ThreadsTest3.BackColor = 'White'
$ThreadsTest3.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
$ThreadsTest3.Text = "1"
$ThreadsTest3.SelectedItem
foreach ($Thread in $Threads) {$ThreadsTest3.Items.Add($Thread) | out-null}
$groupBoxTest3.Controls.Add($ThreadsTest3) 

#Duration Dropdown
$DurationTest3 = new-object System.Windows.Forms.ComboBox
$DurationTest3.Location = new-object System.Drawing.Size(730,20) 
$DurationTest3.Size = new-object System.Drawing.Size(48,30)
$DurationTest3.BackColor = 'White'
$DurationTest3.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
$DurationTest3.Text = "30"
$DurationTest3.SelectedItem
foreach ($Duration in $Durations) {$DurationTest3.Items.Add($Duration) | out-null}
$groupBoxTest3.Controls.Add($DurationTest3) 

$ResultBoxTest3 = New-Object System.Windows.Forms.GroupBox #create the group box
$ResultBoxTest3.Location = New-Object System.Drawing.Size(850,290) #location of the group box (px) in relation to the primary window's edges (length, height)
$ResultBoxTest3.size = New-Object System.Drawing.Size(150,50) #the size in px of the group box (length, height)

#Test Result MBps Label
$TestResultMBPSTest3 = New-Object windows.Forms.Label
$TestResultMBPSTest3.Location = New-Object System.Drawing.Size(15,18) 
$TestResultMBPSTest3.AutoSize = $true
$TestResultMBPSTest3.visible = $false
$ResultBoxTest3.Controls.Add($TestResultMBPSTest3)

#Test Result IOPS Label
$TestResultIOPSTest3 = New-Object windows.Forms.Label
$TestResultIOPSTest3.Location = New-Object System.Drawing.Size(90,18) 
$TestResultIOPSTest3.AutoSize = $true
$TestResultIOPSTest3.visible = $false
$ResultBoxTest3.Controls.Add($TestResultIOPSTest3)


#endregion 

#region Test4
$groupBoxTest4 = New-Object System.Windows.Forms.GroupBox #create the group box
$groupBoxTest4.Location = New-Object System.Drawing.Size(50,340) #location of the group box (px) in relation to the primary window's edges (length, height)
$groupBoxTest4.size = New-Object System.Drawing.Size(790,50) #the size in px of the group box (length, height)

$NameTest4 = New-Object System.Windows.Forms.TextBox 
$NameTest4.Location = New-Object System.Drawing.Size(10,20) 
$NameTest4.Size = New-Object System.Drawing.Size(140,20) 
$NameTest4.Text = "Streaming Media Server"
$groupBoxTest4.Controls.Add($NameTest4) 

$FolderTest4 = New-Object System.Windows.Forms.TextBox 
$FolderTest4.Location = New-Object System.Drawing.Size(155,20) 
$FolderTest4.Size = New-Object System.Drawing.Size(200,20) 
$FolderTest4.Text = "\\SOFS02\Share1"
$groupBoxTest4.Controls.Add($FolderTest4) 

# Folder button
$FolderbuttonTest4 = new-Object windows.Forms.Button;
$FolderbuttonTest4.Text = "..."
$FolderbuttonTest4.Location = New-Object System.Drawing.Size(355,20) 
$FolderbuttonTest4.Size = New-Object System.Drawing.Size(30,20) 
$FolderbuttonTest4.add_click({GetFolder "4"});
$groupBoxTest4.Controls.Add($FolderbuttonTest4) 

#Blocksize Dropdown
$BlocksizeTest4 = new-object System.Windows.Forms.ComboBox
$BlocksizeTest4.Location = new-object System.Drawing.Size(390,20) 
$BlocksizeTest4.Size = new-object System.Drawing.Size(60,30)
$BlocksizeTest4.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropdown
foreach ($blocksize in $blocksizes) {$BlocksizeTest4.Items.Add($blocksize) | out-null}
$groupBoxTest4.Controls.Add($BlocksizeTest4) 
$BlocksizeTest4.text = "5120K"

#Read / Write 
$ReadPercTest4 = New-Object System.Windows.Forms.TextBox 
$ReadPercTest4.Location = New-Object System.Drawing.Size(460,20) 
$ReadPercTest4.Size = New-Object System.Drawing.Size(30,20) 
$ReadPercTest4.Text = "80"
$ReadPercTest4.MaxLength = 3
$ReadPercTest4.Add_TextChanged({
$WritePercTest4.Text = (100 - $ReadPercTest4.Text)

})
$groupBoxTest4.Controls.Add($ReadPercTest4) 

$WritePercTest4 = New-Object System.Windows.Forms.TextBox 
$WritePercTest4.Location = New-Object System.Drawing.Size(495,20) 
$WritePercTest4.Size = New-Object System.Drawing.Size(30,20) 
$WritePercTest4.Text = "20"
$WritePercTest4.Enabled = $false
$groupBoxTest4.Controls.Add($WritePercTest4) 

#OutstandingIO Dropdown
$OutstandingIOTest4 = new-object System.Windows.Forms.ComboBox
$OutstandingIOTest4.Location = new-object System.Drawing.Size(540,20) 
$OutstandingIOTest4.Size = new-object System.Drawing.Size(40,30)
$OutstandingIOTest4.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropdown
foreach ($OutstandingIO in $OutstandingIOs) {$OutstandingIOTest4.Items.Add($OutstandingIO) | out-null}
$OutstandingIOTest4.Add_TextChanged({if ($OutstandingIOTest4.text -eq 0) {$OutstandingIOTest4.SelectedItem = $OutstandingIOTest4.Items[0]}})
$groupBoxTest4.Controls.Add($OutstandingIOTest4)
$OutstandingIOTest4.SelectedItem = $OutstandingIOTest4.Items[3]

#AccessType Dropdown
$AccessTypeTest4 = new-object System.Windows.Forms.ComboBox
$AccessTypeTest4.Location = new-object System.Drawing.Size(590,20) 
$AccessTypeTest4.Size = new-object System.Drawing.Size(80,30)
$AccessTypeTest4.BackColor = 'White'
$AccessTypeTest4.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$AccessTypeTest4.Items.Add("Random") | out-null
$AccessTypeTest4.Items.Add("Sequential") | out-null
$AccessTypeTest4.SelectedItem = $AccessTypeTest4.Items[0]
$groupBoxTest4.Controls.Add($AccessTypeTest4) 

#threads Dropdown
$ThreadsTest4 = new-object System.Windows.Forms.ComboBox
$ThreadsTest4.Location = new-object System.Drawing.Size(680,20) 
$ThreadsTest4.Size = new-object System.Drawing.Size(40,30)
$ThreadsTest4.BackColor = 'White'
$ThreadsTest4.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
$ThreadsTest4.Text = "1"
$ThreadsTest4.SelectedItem
foreach ($Thread in $Threads) {$ThreadsTest4.Items.Add($Thread) | out-null}
$groupBoxTest4.Controls.Add($ThreadsTest4) 

#Duration Dropdown
$DurationTest4 = new-object System.Windows.Forms.ComboBox
$DurationTest4.Location = new-object System.Drawing.Size(730,20) 
$DurationTest4.Size = new-object System.Drawing.Size(48,30)
$DurationTest4.BackColor = 'White'
$DurationTest4.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
$DurationTest4.Text = "30"
$DurationTest4.SelectedItem
foreach ($Duration in $Durations) {$DurationTest4.Items.Add($Duration) | out-null}
$groupBoxTest4.Controls.Add($DurationTest4) 

$ResultBoxTest4 = New-Object System.Windows.Forms.GroupBox #create the group box
$ResultBoxTest4.Location = New-Object System.Drawing.Size(850,340) #location of the group box (px) in relation to the primary window's edges (length, height)
$ResultBoxTest4.size = New-Object System.Drawing.Size(150,50) #the size in px of the group box (length, height)

#Test Result MBps Label
$TestResultMBPSTest4 = New-Object windows.Forms.Label
$TestResultMBPSTest4.Location = New-Object System.Drawing.Size(15,18) 
$TestResultMBPSTest4.AutoSize = $true
$TestResultMBPSTest4.visible = $false
$ResultBoxTest4.Controls.Add($TestResultMBPSTest4)

#Test Result IOPS Label
$TestResultIOPSTest4 = New-Object windows.Forms.Label
$TestResultIOPSTest4.Location = New-Object System.Drawing.Size(90,18) 
$TestResultIOPSTest4.AutoSize = $true
$TestResultIOPSTest4.visible = $false
$ResultBoxTest4.Controls.Add($TestResultIOPSTest4)


#endregion 

#region Test5
$groupBoxTest5 = New-Object System.Windows.Forms.GroupBox #create the group box
$groupBoxTest5.Location = New-Object System.Drawing.Size(50,390) #location of the group box (px) in relation to the primary window's edges (length, height)
$groupBoxTest5.size = New-Object System.Drawing.Size(790,50) #the size in px of the group box (length, height)

$NameTest5 = New-Object System.Windows.Forms.TextBox 
$NameTest5.Location = New-Object System.Drawing.Size(10,20) 
$NameTest5.Size = New-Object System.Drawing.Size(140,20) 
$NameTest5.Text = "VDI workload"
$groupBoxTest5.Controls.Add($NameTest5) 

$FolderTest5 = New-Object System.Windows.Forms.TextBox 
$FolderTest5.Location = New-Object System.Drawing.Size(155,20) 
$FolderTest5.Size = New-Object System.Drawing.Size(200,20) 
$FolderTest5.Text = "C:\ClusterStorage\Volume1"
$groupBoxTest5.Controls.Add($FolderTest5) 

# Folder button
$FolderbuttonTest5 = new-Object windows.Forms.Button;
$FolderbuttonTest5.Text = "..."
$FolderbuttonTest5.Location = New-Object System.Drawing.Size(355,20) 
$FolderbuttonTest5.Size = New-Object System.Drawing.Size(30,20) 
$FolderbuttonTest5.add_click({GetFolder "5"});
$groupBoxTest5.Controls.Add($FolderbuttonTest5) 

#Blocksize Dropdown
$BlocksizeTest5 = new-object System.Windows.Forms.ComboBox
$BlocksizeTest5.Location = new-object System.Drawing.Size(390,20) 
$BlocksizeTest5.Size = new-object System.Drawing.Size(60,30)
$BlocksizeTest5.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropdown
foreach ($blocksize in $blocksizes) {$BlocksizeTest5.Items.Add($blocksize) | out-null}
$groupBoxTest5.Controls.Add($BlocksizeTest5) 
$BlocksizeTest5.SelectedItem = $BlocksizeTest5.Items[0]



#Read / Write 
$ReadPercTest5 = New-Object System.Windows.Forms.TextBox 
$ReadPercTest5.Location = New-Object System.Drawing.Size(460,20) 
$ReadPercTest5.Size = New-Object System.Drawing.Size(30,20) 
$ReadPercTest5.Text = "20"
$ReadPercTest5.MaxLength = 3
$ReadPercTest5.Add_TextChanged({
$WritePercTest5.Text = (100 - $ReadPercTest5.Text)

})
$groupBoxTest5.Controls.Add($ReadPercTest5) 

$WritePercTest5 = New-Object System.Windows.Forms.TextBox 
$WritePercTest5.Location = New-Object System.Drawing.Size(495,20) 
$WritePercTest5.Size = New-Object System.Drawing.Size(30,20) 
$WritePercTest5.Text = "80"
$WritePercTest5.Enabled = $false
$groupBoxTest5.Controls.Add($WritePercTest5) 



#OutstandingIO Dropdown
$OutstandingIOTest5 = new-object System.Windows.Forms.ComboBox
$OutstandingIOTest5.Location = new-object System.Drawing.Size(540,20) 
$OutstandingIOTest5.Size = new-object System.Drawing.Size(40,30)
$OutstandingIOTest5.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropdown
foreach ($OutstandingIO in $OutstandingIOs) {$OutstandingIOTest5.Items.Add($OutstandingIO) | out-null}
$OutstandingIOTest5.Add_TextChanged({if ($OutstandingIOTest5.text -eq 0) {$OutstandingIOTest5.SelectedItem = $OutstandingIOTest5.Items[0]}})
$groupBoxTest5.Controls.Add($OutstandingIOTest5)
$OutstandingIOTest5.SelectedItem = $OutstandingIOTest5.Items[3]

#AccessType Dropdown
$AccessTypeTest5 = new-object System.Windows.Forms.ComboBox
$AccessTypeTest5.Location = new-object System.Drawing.Size(590,20) 
$AccessTypeTest5.Size = new-object System.Drawing.Size(80,30)
$AccessTypeTest5.BackColor = 'White'
$AccessTypeTest5.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$AccessTypeTest5.Items.Add("Random") | out-null
$AccessTypeTest5.Items.Add("Sequential") | out-null
$AccessTypeTest5.SelectedItem = $AccessTypeTest5.Items[0]
$groupBoxTest5.Controls.Add($AccessTypeTest5) 

#threads Dropdown
$ThreadsTest5 = new-object System.Windows.Forms.ComboBox
$ThreadsTest5.Location = new-object System.Drawing.Size(680,20) 
$ThreadsTest5.Size = new-object System.Drawing.Size(40,30)
$ThreadsTest5.BackColor = 'White'
$ThreadsTest5.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
$ThreadsTest5.Text = "1"
$ThreadsTest5.SelectedItem
foreach ($Thread in $Threads) {$ThreadsTest5.Items.Add($Thread) | out-null}
$groupBoxTest5.Controls.Add($ThreadsTest5) 

#Duration Dropdown
$DurationTest5 = new-object System.Windows.Forms.ComboBox
$DurationTest5.Location = new-object System.Drawing.Size(730,20) 
$DurationTest5.Size = new-object System.Drawing.Size(48,30)
$DurationTest5.BackColor = 'White'
$DurationTest5.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
$DurationTest5.Text = "30"
$DurationTest5.SelectedItem
foreach ($Duration in $Durations) {$DurationTest5.Items.Add($Duration) | out-null}
$groupBoxTest5.Controls.Add($DurationTest5) 


$ResultBoxTest5 = New-Object System.Windows.Forms.GroupBox #create the group box
$ResultBoxTest5.Location = New-Object System.Drawing.Size(850,390) #location of the group box (px) in relation to the primary window's edges (length, height)
$ResultBoxTest5.size = New-Object System.Drawing.Size(150,50) #the size in px of the group box (length, height)

#Test Result MBps Label
$TestResultMBPSTest5 = New-Object windows.Forms.Label
$TestResultMBPSTest5.Location = New-Object System.Drawing.Size(15,18) 
$TestResultMBPSTest5.AutoSize = $true
$TestResultMBPSTest5.visible = $false
$ResultBoxTest5.Controls.Add($TestResultMBPSTest5)

#Test Result IOPS Label
$TestResultIOPSTest5 = New-Object windows.Forms.Label
$TestResultIOPSTest5.Location = New-Object System.Drawing.Size(90,18) 
$TestResultIOPSTest5.AutoSize = $true
$TestResultIOPSTest5.visible = $false
$ResultBoxTest5.Controls.Add($TestResultIOPSTest5)


#endregion 

#region Test6
$groupBoxTest6 = New-Object System.Windows.Forms.GroupBox #create the group box
$groupBoxTest6.Location = New-Object System.Drawing.Size(50,440) #location of the group box (px) in relation to the primary window's edges (length, height)
$groupBoxTest6.size = New-Object System.Drawing.Size(790,50) #the size in px of the group box (length, height)
$groupBoxTest6.visible = $false

$NameTest6 = New-Object System.Windows.Forms.TextBox 
$NameTest6.Location = New-Object System.Drawing.Size(10,20) 
$NameTest6.Size = New-Object System.Drawing.Size(140,20) 
$NameTest6.Text = "Name"
$groupBoxTest6.Controls.Add($NameTest6) 

$FolderTest6 = New-Object System.Windows.Forms.TextBox 
$FolderTest6.Location = New-Object System.Drawing.Size(155,20) 
$FolderTest6.Size = New-Object System.Drawing.Size(200,20) 
$FolderTest6.Text = "C:\ClusterStorage\Volume1"
$groupBoxTest6.Controls.Add($FolderTest6) 

# Folder button
$FolderbuttonTest6 = new-Object windows.Forms.Button;
$FolderbuttonTest6.Text = "..."
$FolderbuttonTest6.Location = New-Object System.Drawing.Size(355,20) 
$FolderbuttonTest6.Size = New-Object System.Drawing.Size(30,20) 
$FolderbuttonTest6.add_click({GetFolder "6"});
$groupBoxTest6.Controls.Add($FolderbuttonTest6) 

#Blocksize Dropdown
$BlocksizeTest6 = new-object System.Windows.Forms.ComboBox
$BlocksizeTest6.Location = new-object System.Drawing.Size(390,20) 
$BlocksizeTest6.Size = new-object System.Drawing.Size(60,30)
$BlocksizeTest6.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropdown
foreach ($blocksize in $blocksizes) {$BlocksizeTest6.Items.Add($blocksize) | out-null}
$groupBoxTest6.Controls.Add($BlocksizeTest6) 
$BlocksizeTest6.SelectedItem = $BlocksizeTest6.Items[0]

#Read / Write 
$ReadPercTest6 = New-Object System.Windows.Forms.TextBox 
$ReadPercTest6.Location = New-Object System.Drawing.Size(460,20) 
$ReadPercTest6.Size = New-Object System.Drawing.Size(30,20) 
$ReadPercTest6.Text = "100"
$ReadPercTest6.MaxLength = 3
$ReadPercTest6.Add_TextChanged({
$WritePercTest6.Text = (100 - $ReadPercTest6.Text)

})
$groupBoxTest6.Controls.Add($ReadPercTest6) 

$WritePercTest6 = New-Object System.Windows.Forms.TextBox 
$WritePercTest6.Location = New-Object System.Drawing.Size(495,20) 
$WritePercTest6.Size = New-Object System.Drawing.Size(30,20) 
$WritePercTest6.Text = "0"
$WritePercTest6.Enabled = $false
$groupBoxTest6.Controls.Add($WritePercTest6) 

#OutstandingIO Dropdown
$OutstandingIOTest6 = new-object System.Windows.Forms.ComboBox
$OutstandingIOTest6.Location = new-object System.Drawing.Size(540,20) 
$OutstandingIOTest6.Size = new-object System.Drawing.Size(40,30)
$OutstandingIOTest6.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropdown
foreach ($OutstandingIO in $OutstandingIOs) {$OutstandingIOTest6.Items.Add($OutstandingIO) | out-null}
$OutstandingIOTest6.Add_TextChanged({if ($OutstandingIOTest6.text -eq 0) {$OutstandingIOTest6.SelectedItem = $OutstandingIOTest6.Items[0]}})
$groupBoxTest6.Controls.Add($OutstandingIOTest6)
$OutstandingIOTest6.SelectedItem = $OutstandingIOTest6.Items[0]

#AccessType Dropdown
$AccessTypeTest6 = new-object System.Windows.Forms.ComboBox
$AccessTypeTest6.Location = new-object System.Drawing.Size(590,20) 
$AccessTypeTest6.Size = new-object System.Drawing.Size(80,30)
$AccessTypeTest6.BackColor = 'White'
$AccessTypeTest6.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$AccessTypeTest6.Items.Add("Random") | out-null
$AccessTypeTest6.Items.Add("Sequential") | out-null
$AccessTypeTest6.SelectedItem = $AccessTypeTest6.Items[0]
$groupBoxTest6.Controls.Add($AccessTypeTest6) 

#threads Dropdown
$ThreadsTest6 = new-object System.Windows.Forms.ComboBox
$ThreadsTest6.Location = new-object System.Drawing.Size(680,20) 
$ThreadsTest6.Size = new-object System.Drawing.Size(40,30)
$ThreadsTest6.BackColor = 'White'
$ThreadsTest6.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
$ThreadsTest6.Text = "1"
$ThreadsTest6.SelectedItem
foreach ($Thread in $Threads) {$ThreadsTest6.Items.Add($Thread) | out-null}
$groupBoxTest6.Controls.Add($ThreadsTest6) 

#Duration Dropdown
$DurationTest6 = new-object System.Windows.Forms.ComboBox
$DurationTest6.Location = new-object System.Drawing.Size(730,20) 
$DurationTest6.Size = new-object System.Drawing.Size(48,30)
$DurationTest6.BackColor = 'White'
$DurationTest6.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
$DurationTest6.Text = "30"
$DurationTest6.SelectedItem
foreach ($Duration in $Durations) {$DurationTest6.Items.Add($Duration) | out-null}
$groupBoxTest6.Controls.Add($DurationTest6) 

$ResultBoxTest6 = New-Object System.Windows.Forms.GroupBox #create the group box
$ResultBoxTest6.Location = New-Object System.Drawing.Size(850,440) #location of the group box (px) in relation to the primary window's edges (length, height)
$ResultBoxTest6.size = New-Object System.Drawing.Size(150,50) #the size in px of the group box (length, height)
$ResultBoxTest6.visible = $false

#Test Result MBps Label
$TestResultMBPSTest6 = New-Object windows.Forms.Label
$TestResultMBPSTest6.Location = New-Object System.Drawing.Size(15,18) 
$TestResultMBPSTest6.AutoSize = $true
$TestResultMBPSTest6.visible = $false
$ResultBoxTest6.Controls.Add($TestResultMBPSTest6)

#Test Result IOPS Label
$TestResultIOPSTest6 = New-Object windows.Forms.Label
$TestResultIOPSTest6.Location = New-Object System.Drawing.Size(90,18) 
$TestResultIOPSTest6.AutoSize = $true
$TestResultIOPSTest6.visible = $false
$ResultBoxTest6.Controls.Add($TestResultIOPSTest6)


#endregion 

#region Test7
$groupBoxTest7 = New-Object System.Windows.Forms.GroupBox #create the group box
$groupBoxTest7.Location = New-Object System.Drawing.Size(50,490) #location of the group box (px) in relation to the primary window's edges (length, height)
$groupBoxTest7.size = New-Object System.Drawing.Size(790,50) #the size in px of the group box (length, height)
$groupBoxTest7.visible = $false

$NameTest7 = New-Object System.Windows.Forms.TextBox 
$NameTest7.Location = New-Object System.Drawing.Size(10,20) 
$NameTest7.Size = New-Object System.Drawing.Size(140,20) 
$NameTest7.Text = "Name"
$groupBoxTest7.Controls.Add($NameTest7) 

$FolderTest7 = New-Object System.Windows.Forms.TextBox 
$FolderTest7.Location = New-Object System.Drawing.Size(155,20) 
$FolderTest7.Size = New-Object System.Drawing.Size(200,20) 
$FolderTest7.Text = "C:\ClusterStorage\Volume1"
$groupBoxTest7.Controls.Add($FolderTest7) 

# Folder button
$FolderbuttonTest7 = new-Object windows.Forms.Button;
$FolderbuttonTest7.Text = "..."
$FolderbuttonTest7.Location = New-Object System.Drawing.Size(355,20) 
$FolderbuttonTest7.Size = New-Object System.Drawing.Size(30,20) 
$FolderbuttonTest7.add_click({GetFolder "7"});
$groupBoxTest7.Controls.Add($FolderbuttonTest7) 

#Blocksize Dropdown
$BlocksizeTest7 = new-object System.Windows.Forms.ComboBox
$BlocksizeTest7.Location = new-object System.Drawing.Size(390,20) 
$BlocksizeTest7.Size = new-object System.Drawing.Size(60,30)
$BlocksizeTest7.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropdown
foreach ($blocksize in $blocksizes) {$BlocksizeTest7.Items.Add($blocksize) | out-null}
$groupBoxTest7.Controls.Add($BlocksizeTest7) 
$BlocksizeTest7.SelectedItem = $BlocksizeTest7.Items[0]

#Read / Write 
$ReadPercTest7 = New-Object System.Windows.Forms.TextBox 
$ReadPercTest7.Location = New-Object System.Drawing.Size(460,20) 
$ReadPercTest7.Size = New-Object System.Drawing.Size(30,20) 
$ReadPercTest7.Text = "100"
$ReadPercTest7.MaxLength = 3
$ReadPercTest7.Add_TextChanged({
$WritePercTest7.Text = (100 - $ReadPercTest7.Text)

})
$groupBoxTest7.Controls.Add($ReadPercTest7) 

$WritePercTest7 = New-Object System.Windows.Forms.TextBox 
$WritePercTest7.Location = New-Object System.Drawing.Size(495,20) 
$WritePercTest7.Size = New-Object System.Drawing.Size(30,20) 
$WritePercTest7.Text = "0"
$WritePercTest7.Enabled = $false
$groupBoxTest7.Controls.Add($WritePercTest7) 

#OutstandingIO Dropdown
$OutstandingIOTest7 = new-object System.Windows.Forms.ComboBox
$OutstandingIOTest7.Location = new-object System.Drawing.Size(540,20) 
$OutstandingIOTest7.Size = new-object System.Drawing.Size(40,30)
$OutstandingIOTest7.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropdown
foreach ($OutstandingIO in $OutstandingIOs) {$OutstandingIOTest7.Items.Add($OutstandingIO) | out-null}
$OutstandingIOTest7.Add_TextChanged({if ($OutstandingIOTest7.text -eq 0) {$OutstandingIOTest7.SelectedItem = $OutstandingIOTest7.Items[0]}})
$groupBoxTest7.Controls.Add($OutstandingIOTest7)
$OutstandingIOTest7.SelectedItem = $OutstandingIOTest7.Items[0]

#AccessType Dropdown
$AccessTypeTest7 = new-object System.Windows.Forms.ComboBox
$AccessTypeTest7.Location = new-object System.Drawing.Size(590,20) 
$AccessTypeTest7.Size = new-object System.Drawing.Size(80,30)
$AccessTypeTest7.BackColor = 'White'
$AccessTypeTest7.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$AccessTypeTest7.Items.Add("Random") | out-null
$AccessTypeTest7.Items.Add("Sequential") | out-null
$AccessTypeTest7.SelectedItem = $AccessTypeTest7.Items[0]
$groupBoxTest7.Controls.Add($AccessTypeTest7) 

#threads Dropdown
$ThreadsTest7 = new-object System.Windows.Forms.ComboBox
$ThreadsTest7.Location = new-object System.Drawing.Size(680,20) 
$ThreadsTest7.Size = new-object System.Drawing.Size(40,30)
$ThreadsTest7.BackColor = 'White'
$ThreadsTest7.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
$ThreadsTest7.Text = "1"
$ThreadsTest7.SelectedItem
foreach ($Thread in $Threads) {$ThreadsTest7.Items.Add($Thread) | out-null}
$groupBoxTest7.Controls.Add($ThreadsTest7) 

#Duration Dropdown
$DurationTest7 = new-object System.Windows.Forms.ComboBox
$DurationTest7.Location = new-object System.Drawing.Size(730,20) 
$DurationTest7.Size = new-object System.Drawing.Size(48,30)
$DurationTest7.BackColor = 'White'
$DurationTest7.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
$DurationTest7.Text = "30"
$DurationTest7.SelectedItem
foreach ($Duration in $Durations) {$DurationTest7.Items.Add($Duration) | out-null}
$groupBoxTest7.Controls.Add($DurationTest7) 

$ResultBoxTest7 = New-Object System.Windows.Forms.GroupBox #create the group box
$ResultBoxTest7.Location = New-Object System.Drawing.Size(850,490) #location of the group box (px) in relation to the primary window's edges (length, height)
$ResultBoxTest7.size = New-Object System.Drawing.Size(150,50) #the size in px of the group box (length, height)
$ResultBoxTest7.visible = $false

#Test Result MBps Label
$TestResultMBPSTest7 = New-Object windows.Forms.Label
$TestResultMBPSTest7.Location = New-Object System.Drawing.Size(15,18) 
$TestResultMBPSTest7.AutoSize = $true
$TestResultMBPSTest7.visible = $false
$ResultBoxTest7.Controls.Add($TestResultMBPSTest7)

#Test Result IOPS Label
$TestResultIOPSTest7 = New-Object windows.Forms.Label
$TestResultIOPSTest7.Location = New-Object System.Drawing.Size(90,18) 
$TestResultIOPSTest7.AutoSize = $true
$TestResultIOPSTest7.visible = $false
$ResultBoxTest7.Controls.Add($TestResultIOPSTest7)


#endregion 

#region Test8
$groupBoxTest8 = New-Object System.Windows.Forms.GroupBox #create the group box
$groupBoxTest8.Location = New-Object System.Drawing.Size(50,540) #location of the group box (px) in relation to the primary window's edges (length, height)
$groupBoxTest8.size = New-Object System.Drawing.Size(790,50) #the size in px of the group box (length, height)
$groupBoxTest8.visible = $false

$NameTest8 = New-Object System.Windows.Forms.TextBox 
$NameTest8.Location = New-Object System.Drawing.Size(10,20) 
$NameTest8.Size = New-Object System.Drawing.Size(140,20) 
$NameTest8.Text = "Name"
$groupBoxTest8.Controls.Add($NameTest8) 

$FolderTest8 = New-Object System.Windows.Forms.TextBox 
$FolderTest8.Location = New-Object System.Drawing.Size(155,20) 
$FolderTest8.Size = New-Object System.Drawing.Size(200,20) 
$FolderTest8.Text = "C:\ClusterStorage\Volume1"
$groupBoxTest8.Controls.Add($FolderTest8) 

# Folder button
$FolderbuttonTest8 = new-Object windows.Forms.Button;
$FolderbuttonTest8.Text = "..."
$FolderbuttonTest8.Location = New-Object System.Drawing.Size(355,20) 
$FolderbuttonTest8.Size = New-Object System.Drawing.Size(30,20) 
$FolderbuttonTest8.add_click({GetFolder "8"});
$groupBoxTest8.Controls.Add($FolderbuttonTest8) 

#Blocksize Dropdown
$BlocksizeTest8 = new-object System.Windows.Forms.ComboBox
$BlocksizeTest8.Location = new-object System.Drawing.Size(390,20) 
$BlocksizeTest8.Size = new-object System.Drawing.Size(60,30)
$BlocksizeTest8.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropdown
foreach ($blocksize in $blocksizes) {$BlocksizeTest8.Items.Add($blocksize) | out-null}
$groupBoxTest8.Controls.Add($BlocksizeTest8) 
$BlocksizeTest8.SelectedItem = $BlocksizeTest8.Items[0]

#Read / Write 
$ReadPercTest8 = New-Object System.Windows.Forms.TextBox 
$ReadPercTest8.Location = New-Object System.Drawing.Size(460,20) 
$ReadPercTest8.Size = New-Object System.Drawing.Size(30,20) 
$ReadPercTest8.Text = "100"
$ReadPercTest8.MaxLength = 3
$ReadPercTest8.Add_TextChanged({
$WritePercTest8.Text = (100 - $ReadPercTest8.Text)

})
$groupBoxTest8.Controls.Add($ReadPercTest8) 

$WritePercTest8 = New-Object System.Windows.Forms.TextBox 
$WritePercTest8.Location = New-Object System.Drawing.Size(495,20) 
$WritePercTest8.Size = New-Object System.Drawing.Size(30,20) 
$WritePercTest8.Text = "0"
$WritePercTest8.Enabled = $false
$groupBoxTest8.Controls.Add($WritePercTest8) 

#OutstandingIO Dropdown
$OutstandingIOTest8 = new-object System.Windows.Forms.ComboBox
$OutstandingIOTest8.Location = new-object System.Drawing.Size(540,20) 
$OutstandingIOTest8.Size = new-object System.Drawing.Size(40,30)
$OutstandingIOTest8.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropdown
foreach ($OutstandingIO in $OutstandingIOs) {$OutstandingIOTest8.Items.Add($OutstandingIO) | out-null}
$OutstandingIOTest8.Add_TextChanged({if ($OutstandingIOTest8.text -eq 0) {$OutstandingIOTest8.SelectedItem = $OutstandingIOTest8.Items[0]}})
$groupBoxTest8.Controls.Add($OutstandingIOTest8)
$OutstandingIOTest8.SelectedItem = $OutstandingIOTest8.Items[0]

#AccessType Dropdown
$AccessTypeTest8 = new-object System.Windows.Forms.ComboBox
$AccessTypeTest8.Location = new-object System.Drawing.Size(590,20) 
$AccessTypeTest8.Size = new-object System.Drawing.Size(80,30)
$AccessTypeTest8.BackColor = 'White'
$AccessTypeTest8.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$AccessTypeTest8.Items.Add("Random") | out-null
$AccessTypeTest8.Items.Add("Sequential") | out-null
$AccessTypeTest8.SelectedItem = $AccessTypeTest8.Items[0]
$groupBoxTest8.Controls.Add($AccessTypeTest8) 

#threads Dropdown
$ThreadsTest8 = new-object System.Windows.Forms.ComboBox
$ThreadsTest8.Location = new-object System.Drawing.Size(680,20) 
$ThreadsTest8.Size = new-object System.Drawing.Size(40,30)
$ThreadsTest8.BackColor = 'White'
$ThreadsTest8.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
$ThreadsTest8.Text = "1"
$ThreadsTest8.SelectedItem
foreach ($Thread in $Threads) {$ThreadsTest8.Items.Add($Thread) | out-null}
$groupBoxTest8.Controls.Add($ThreadsTest8) 

#Duration Dropdown
$DurationTest8 = new-object System.Windows.Forms.ComboBox
$DurationTest8.Location = new-object System.Drawing.Size(730,20) 
$DurationTest8.Size = new-object System.Drawing.Size(48,30)
$DurationTest8.BackColor = 'White'
$DurationTest8.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
$DurationTest8.Text = "30"
$DurationTest8.SelectedItem
foreach ($Duration in $Durations) {$DurationTest8.Items.Add($Duration) | out-null}
$groupBoxTest8.Controls.Add($DurationTest8) 

$ResultBoxTest8 = New-Object System.Windows.Forms.GroupBox #create the group box
$ResultBoxTest8.Location = New-Object System.Drawing.Size(850,540) #location of the group box (px) in relation to the primary window's edges (length, height)
$ResultBoxTest8.size = New-Object System.Drawing.Size(150,50) #the size in px of the group box (length, height)
$ResultBoxTest8.visible = $false

#Test Result MBps Label
$TestResultMBPSTest8 = New-Object windows.Forms.Label
$TestResultMBPSTest8.Location = New-Object System.Drawing.Size(15,18) 
$TestResultMBPSTest8.AutoSize = $true
$TestResultMBPSTest8.visible = $false
$ResultBoxTest8.Controls.Add($TestResultMBPSTest8)

#Test Result IOPS Label
$TestResultIOPSTest8 = New-Object windows.Forms.Label
$TestResultIOPSTest8.Location = New-Object System.Drawing.Size(90,18) 
$TestResultIOPSTest8.AutoSize = $true
$TestResultIOPSTest8.visible = $false
$ResultBoxTest8.Controls.Add($TestResultIOPSTest8)

#endregion 

#region Test9
$groupBoxTest9 = New-Object System.Windows.Forms.GroupBox #create the group box
$groupBoxTest9.Location = New-Object System.Drawing.Size(50,590) #location of the group box (px) in relation to the primary window's edges (length, height)
$groupBoxTest9.size = New-Object System.Drawing.Size(790,50) #the size in px of the group box (length, height)
$groupBoxTest9.visible = $false

$NameTest9 = New-Object System.Windows.Forms.TextBox 
$NameTest9.Location = New-Object System.Drawing.Size(10,20) 
$NameTest9.Size = New-Object System.Drawing.Size(140,20) 
$NameTest9.Text = "Name"
$groupBoxTest9.Controls.Add($NameTest9) 

$FolderTest9 = New-Object System.Windows.Forms.TextBox 
$FolderTest9.Location = New-Object System.Drawing.Size(155,20) 
$FolderTest9.Size = New-Object System.Drawing.Size(200,20) 
$FolderTest9.Text = "C:\ClusterStorage\Volume1"
$groupBoxTest9.Controls.Add($FolderTest9) 

# Folder button
$FolderbuttonTest9 = new-Object windows.Forms.Button;
$FolderbuttonTest9.Text = "..."
$FolderbuttonTest9.Location = New-Object System.Drawing.Size(355,20) 
$FolderbuttonTest9.Size = New-Object System.Drawing.Size(30,20) 
$FolderbuttonTest9.add_click({GetFolder "9"});
$groupBoxTest9.Controls.Add($FolderbuttonTest9) 

#Blocksize Dropdown
$BlocksizeTest9 = new-object System.Windows.Forms.ComboBox
$BlocksizeTest9.Location = new-object System.Drawing.Size(390,20) 
$BlocksizeTest9.Size = new-object System.Drawing.Size(60,30)
$BlocksizeTest9.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropdown
foreach ($blocksize in $blocksizes) {$BlocksizeTest9.Items.Add($blocksize) | out-null}
$groupBoxTest9.Controls.Add($BlocksizeTest9) 
$BlocksizeTest9.SelectedItem = $BlocksizeTest9.Items[0]

#Read / Write 
$ReadPercTest9 = New-Object System.Windows.Forms.TextBox 
$ReadPercTest9.Location = New-Object System.Drawing.Size(460,20) 
$ReadPercTest9.Size = New-Object System.Drawing.Size(30,20) 
$ReadPercTest9.Text = "100"
$ReadPercTest9.MaxLength = 3
$ReadPercTest9.Add_TextChanged({
$WritePercTest9.Text = (100 - $ReadPercTest9.Text)

})
$groupBoxTest9.Controls.Add($ReadPercTest9) 

$WritePercTest9 = New-Object System.Windows.Forms.TextBox 
$WritePercTest9.Location = New-Object System.Drawing.Size(495,20) 
$WritePercTest9.Size = New-Object System.Drawing.Size(30,20) 
$WritePercTest9.Text = "0"
$WritePercTest9.Enabled = $false
$groupBoxTest9.Controls.Add($WritePercTest9) 

#OutstandingIO Dropdown
$OutstandingIOTest9 = new-object System.Windows.Forms.ComboBox
$OutstandingIOTest9.Location = new-object System.Drawing.Size(540,20) 
$OutstandingIOTest9.Size = new-object System.Drawing.Size(40,30)
$OutstandingIOTest9.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropdown
foreach ($OutstandingIO in $OutstandingIOs) {$OutstandingIOTest9.Items.Add($OutstandingIO) | out-null}
$OutstandingIOTest9.Add_TextChanged({if ($OutstandingIOTest9.text -eq 0) {$OutstandingIOTest9.SelectedItem = $OutstandingIOTest9.Items[0]}})
$groupBoxTest9.Controls.Add($OutstandingIOTest9)
$OutstandingIOTest9.SelectedItem = $OutstandingIOTest9.Items[0]

#AccessType Dropdown
$AccessTypeTest9 = new-object System.Windows.Forms.ComboBox
$AccessTypeTest9.Location = new-object System.Drawing.Size(590,20) 
$AccessTypeTest9.Size = new-object System.Drawing.Size(80,30)
$AccessTypeTest9.BackColor = 'White'
$AccessTypeTest9.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$AccessTypeTest9.Items.Add("Random") | out-null
$AccessTypeTest9.Items.Add("Sequential") | out-null
$AccessTypeTest9.SelectedItem = $AccessTypeTest9.Items[0]
$groupBoxTest9.Controls.Add($AccessTypeTest9) 

#threads Dropdown
$ThreadsTest9 = new-object System.Windows.Forms.ComboBox
$ThreadsTest9.Location = new-object System.Drawing.Size(680,20) 
$ThreadsTest9.Size = new-object System.Drawing.Size(40,30)
$ThreadsTest9.BackColor = 'White'
$ThreadsTest9.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
$ThreadsTest9.Text = "1"
$ThreadsTest9.SelectedItem
foreach ($Thread in $Threads) {$ThreadsTest9.Items.Add($Thread) | out-null}
$groupBoxTest9.Controls.Add($ThreadsTest9) 

#Duration Dropdown
$DurationTest9 = new-object System.Windows.Forms.ComboBox
$DurationTest9.Location = new-object System.Drawing.Size(730,20) 
$DurationTest9.Size = new-object System.Drawing.Size(48,30)
$DurationTest9.BackColor = 'White'
$DurationTest9.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
$DurationTest9.Text = "30"
$DurationTest9.SelectedItem
foreach ($Duration in $Durations) {$DurationTest9.Items.Add($Duration) | out-null}
$groupBoxTest9.Controls.Add($DurationTest9) 

$ResultBoxTest9 = New-Object System.Windows.Forms.GroupBox #create the group box
$ResultBoxTest9.Location = New-Object System.Drawing.Size(850,590) #location of the group box (px) in relation to the primary window's edges (length, height)
$ResultBoxTest9.size = New-Object System.Drawing.Size(150,50) #the size in px of the group box (length, height)
$ResultBoxTest9.visible = $false

#Test Result MBps Label
$TestResultMBPSTest9 = New-Object windows.Forms.Label
$TestResultMBPSTest9.Location = New-Object System.Drawing.Size(15,18) 
$TestResultMBPSTest9.AutoSize = $true
$TestResultMBPSTest9.visible = $false
$ResultBoxTest9.Controls.Add($TestResultMBPSTest9)

#Test Result IOPS Label
$TestResultIOPSTest9 = New-Object windows.Forms.Label
$TestResultIOPSTest9.Location = New-Object System.Drawing.Size(90,18) 
$TestResultIOPSTest9.AutoSize = $true
$TestResultIOPSTest9.visible = $false
$ResultBoxTest9.Controls.Add($TestResultIOPSTest9)
#endregion 

#region Test10
$groupBoxTest10 = New-Object System.Windows.Forms.GroupBox #create the group box
$groupBoxTest10.Location = New-Object System.Drawing.Size(50,640) #location of the group box (px) in relation to the primary window's edges (length, height)
$groupBoxTest10.size = New-Object System.Drawing.Size(790,50) #the size in px of the group box (length, height)
$groupBoxTest10.visible = $false

$NameTest10 = New-Object System.Windows.Forms.TextBox 
$NameTest10.Location = New-Object System.Drawing.Size(10,20) 
$NameTest10.Size = New-Object System.Drawing.Size(140,20) 
$NameTest10.Text = "Name"
$groupBoxTest10.Controls.Add($NameTest10) 

$FolderTest10 = New-Object System.Windows.Forms.TextBox 
$FolderTest10.Location = New-Object System.Drawing.Size(155,20) 
$FolderTest10.Size = New-Object System.Drawing.Size(200,20) 
$FolderTest10.Text = "C:\ClusterStorage\Volume1"
$groupBoxTest10.Controls.Add($FolderTest10) 

# Folder button
$FolderbuttonTest10 = new-Object windows.Forms.Button;
$FolderbuttonTest10.Text = "..."
$FolderbuttonTest10.Location = New-Object System.Drawing.Size(355,20) 
$FolderbuttonTest10.Size = New-Object System.Drawing.Size(30,20) 
$FolderbuttonTest10.add_click({GetFolder "10"});
$groupBoxTest10.Controls.Add($FolderbuttonTest10) 

#Blocksize Dropdown
$BlocksizeTest10 = new-object System.Windows.Forms.ComboBox
$BlocksizeTest10.Location = new-object System.Drawing.Size(390,20) 
$BlocksizeTest10.Size = new-object System.Drawing.Size(60,30)
$BlocksizeTest10.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropdown
foreach ($blocksize in $blocksizes) {$BlocksizeTest10.Items.Add($blocksize) | out-null}
$groupBoxTest10.Controls.Add($BlocksizeTest10) 
$BlocksizeTest10.SelectedItem = $BlocksizeTest10.Items[0]



#Read / Write 
$ReadPercTest10 = New-Object System.Windows.Forms.TextBox 
$ReadPercTest10.Location = New-Object System.Drawing.Size(460,20) 
$ReadPercTest10.Size = New-Object System.Drawing.Size(30,20) 
$ReadPercTest10.Text = "100"
$ReadPercTest10.MaxLength = 3
$ReadPercTest10.Add_TextChanged({
$WritePercTest10.Text = (100 - $ReadPercTest10.Text)

})
$groupBoxTest10.Controls.Add($ReadPercTest10) 

$WritePercTest10 = New-Object System.Windows.Forms.TextBox 
$WritePercTest10.Location = New-Object System.Drawing.Size(495,20) 
$WritePercTest10.Size = New-Object System.Drawing.Size(30,20) 
$WritePercTest10.Text = "0"
$WritePercTest10.Enabled = $false
$groupBoxTest10.Controls.Add($WritePercTest10) 

#OutstandingIO Dropdown
$OutstandingIOTest10 = new-object System.Windows.Forms.ComboBox
$OutstandingIOTest10.Location = new-object System.Drawing.Size(540,20) 
$OutstandingIOTest10.Size = new-object System.Drawing.Size(40,30)
$OutstandingIOTest10.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropdown
foreach ($OutstandingIO in $OutstandingIOs) {$OutstandingIOTest10.Items.Add($OutstandingIO) | out-null}
$OutstandingIOTest10.Add_TextChanged({if ($OutstandingIOTest10.text -eq 0) {$OutstandingIOTest10.SelectedItem = $OutstandingIOTest10.Items[0]}})
$groupBoxTest10.Controls.Add($OutstandingIOTest10)
$OutstandingIOTest10.SelectedItem = $OutstandingIOTest10.Items[0]

#AccessType Dropdown
$AccessTypeTest10 = new-object System.Windows.Forms.ComboBox
$AccessTypeTest10.Location = new-object System.Drawing.Size(590,20) 
$AccessTypeTest10.Size = new-object System.Drawing.Size(80,30)
$AccessTypeTest10.BackColor = 'White'
$AccessTypeTest10.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$AccessTypeTest10.Items.Add("Random") | out-null
$AccessTypeTest10.Items.Add("Sequential") | out-null
$AccessTypeTest10.SelectedItem = $AccessTypeTest10.Items[0]
$groupBoxTest10.Controls.Add($AccessTypeTest10) 

#threads Dropdown
$ThreadsTest10 = new-object System.Windows.Forms.ComboBox
$ThreadsTest10.Location = new-object System.Drawing.Size(680,20) 
$ThreadsTest10.Size = new-object System.Drawing.Size(40,30)
$ThreadsTest10.BackColor = 'White'
$ThreadsTest10.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
$ThreadsTest10.Text = "1"
$ThreadsTest10.SelectedItem
foreach ($Thread in $Threads) {$ThreadsTest10.Items.Add($Thread) | out-null}
$groupBoxTest10.Controls.Add($ThreadsTest10) 

#Duration Dropdown
$DurationTest10 = new-object System.Windows.Forms.ComboBox
$DurationTest10.Location = new-object System.Drawing.Size(730,20) 
$DurationTest10.Size = new-object System.Drawing.Size(48,30)
$DurationTest10.BackColor = 'White'
$DurationTest10.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
$DurationTest10.Text = "30"
$DurationTest10.SelectedItem
foreach ($Duration in $Durations) {$DurationTest10.Items.Add($Duration) | out-null}
$groupBoxTest10.Controls.Add($DurationTest10) 

$ResultBoxTest10 = New-Object System.Windows.Forms.GroupBox #create the group box
$ResultBoxTest10.Location = New-Object System.Drawing.Size(850,640) #location of the group box (px) in relation to the primary window's edges (length, height)
$ResultBoxTest10.size = New-Object System.Drawing.Size(150,50) #the size in px of the group box (length, height)
$ResultBoxTest10.visible = $false

#Test Result MBps Label
$TestResultMBPSTest10 = New-Object windows.Forms.Label
$TestResultMBPSTest10.Location = New-Object System.Drawing.Size(15,18) 
$TestResultMBPSTest10.AutoSize = $true
$TestResultMBPSTest10.visible = $false
$ResultBoxTest10.Controls.Add($TestResultMBPSTest10)

#Test Result IOPS Label
$TestResultIOPSTest10 = New-Object windows.Forms.Label
$TestResultIOPSTest10.Location = New-Object System.Drawing.Size(90,18) 
$TestResultIOPSTest10.AutoSize = $true
$TestResultIOPSTest10.visible = $false
$ResultBoxTest10.Controls.Add($TestResultIOPSTest10)

#endregion 

#region Visual


$MainForm.Controls.Add($TestNameLabel);
$MainForm.Controls.Add($TestLocationLabel);
$MainForm.Controls.Add($TestBlocksizeLabel);
$MainForm.Controls.Add($TestReadWriteLabel);
$MainForm.Controls.Add($TestOutstandingIOLabel);
$MainForm.Controls.Add($TestAccessTypeLabel);
$MainForm.Controls.Add($TestWorkersLabel);
$MainForm.Controls.Add($TestDurationLabel);
$MainForm.Controls.Add($TestResultMBpsLabel);
$MainForm.Controls.Add($TestResultIOPSLabel);
$MainForm.Controls.Add($groupBoxTest1);
$MainForm.Controls.Add($ResultBoxTest1);
$MainForm.Controls.Add($groupBoxTest2);
$MainForm.Controls.Add($ResultBoxTest2);
$MainForm.Controls.Add($groupBoxTest3);
$MainForm.Controls.Add($ResultBoxTest3);
$MainForm.Controls.Add($groupBoxTest4);
$MainForm.Controls.Add($ResultBoxTest4);
$MainForm.Controls.Add($groupBoxTest5);
$MainForm.Controls.Add($ResultBoxTest5);
$MainForm.Controls.Add($groupBoxTest6);
$MainForm.Controls.Add($ResultBoxTest6);
$MainForm.Controls.Add($groupBoxTest7);
$MainForm.Controls.Add($ResultBoxTest7);
$MainForm.Controls.Add($groupBoxTest8);
$MainForm.Controls.Add($ResultBoxTest8);
$MainForm.Controls.Add($groupBoxTest9);
$MainForm.Controls.Add($ResultBoxTest9);
$MainForm.Controls.Add($groupBoxTest10);
$MainForm.Controls.Add($ResultBoxTest10);
$MainForm.Controls.Add($GroupBoxTests);
$MainForm.Controls.Add($GroupBoxImpExp);
$MainForm.Controls.Add($GroupBoxOutput);
$MainForm.Controls.Add($groupBoxStart);
$MainForm.Controls.Add($groupBoxSettings);

$base64 = "iVBORw0KGgoAAAANSUhEUgAAAU4AAADwCAMAAABYOn3qAAAA4VBMVEUAAACPwNDn6Orn6Orn6Orn6Oo7 `
vurn6Orn6Oo7vurn6Oo7vuo7vurn6Oo7vurn6OqIiIjn6Oo8vuk9vujn6Orn6Orn6Orn6Orn6Orn6Orn6Oo7vuo7vuq `
IiIg7vurn6Orn6Oo7vurGjlrn6Oo7vuo7vuo7vuqIiIiIiIg7vuqIi4k7vuqIiIjn6OqIi4qIiInmmT/Ln1r+kyeFjY3 `
8lCmppnyOrJf/kyf9lCj2lTD3lS/8lCmOrJippn1ftsbNnljUnVE7vuqIiIj/kybn6OpgrcD0ljFLudl3o6bSnVO+oWj `
gqWRLAAAAQXRSTlMADPRgEsQs55aTbx7siF+1MCp/b1PRonsaM9tJPdOjIkbcGzzGu9GaXq6HVrurb+v82YhHM/78aciq `
UOm1zs2beVbQi7QAAA7+SURBVHja7JrpjqpAEIW72UGxg7JrAIOaGMNDdML7P9PN5N65zozSCzTQDfP9n8VjVZ1TBUBKYFl `
Xuuc7yIxsu31i25GJYj/xwrqE4BcaZaX7sam1LGhmnOh1CX55g1F5TtT2IXK82gC/fJKGPrUg6aXqhylYPYEXa60o7FgP `
wGop9UZrRaM1+grHKawcux0L26nW5PuGjtqxQfo67ImgpWDMxSsKQ9ROCdIX3PV13E5PXIMlYnh2Ow+5t7imr5p2TpoKLA`
fYszC13ERN7Ph/cZy4aZCZ2/3C01KmaOpzfvCP00aVkU5GaVDpiYNyvi8nWUDPBw67jsjX6xTwkNa6j9jL1VF8B80QY0R09`
Kx/M8JMZ71GoQwoS4bY7hZiPmLmxTaLoIpWaIAYlmvBV7U0ZDgFNAoKGjQ0Z4j1FIxBqjfUaK+YoGlMSdZ+Dcak9nOKKSnk`
8jAh+45XgvEpPbI7Jark0JB0FI68FExFSlRUC4ECBCbBepISTEvp24Q2kX6EQp8wr2owLfQ7li93x1d2Z5PPeMs1vLyzXyQ`
+3xmdddDM/V/XSDmP77QgX4Yn4KWvlCWlqKOdPFnmU+edEMlXoGHHyJTrqw9zJQq0Y2qa8h3Bq+j9BJWlhT7I7LeVKZ+Y3Y`
La8lzukrdr+VAxoXV6HPZucb/cbtt/nG+Xa+HuD4+jtRHd8h6QAsNsX7EHTKPN8eBez5jK9lLsd6deXaprsjrS20b3YF8hi`
zPmZHvdPyzI7fJyNrwuKBnD0+G+xf25uQ++9jec9hUdzAp0RBwW4HF/wQLYFjuLp69MyRw+jYZHOIssJb+kDzhkhEYpmItM`
G3iigUd3i8VzOWz6d7w21wANX8NRxqPl445H48aqaP0amkIwB6/emAB2jgUmMKGiMJEigfovUydgD0T7LZ6Cyw4COkH+Ykh`
gYiDqXZpwd8HT4Vp91jo0rcEbUd+pabl4Ym47yL+LmAaYDiPvGdeOVzwHe8gdoPMJH7j+/C4rxi4/47lwN7w5xS7BNJQ/1`
IxKJjEPWzwnd4v2sX60nDaNnoHWo9HhAc/O9cTX8Bo9qohfhUJFxPzgSqlQnU9P8bWZs3TEbotl4b6hRFCyniOr2UAGNz9j`
mXAh+RY+5fwsNd7obl2xbBwACWc6PVONc2xCF0vI+cg+QO3x8qdhc16ydlhSiCO0/u4OBhgHI+JbGzYXLC8H5mAdQTAG0ORba`
vdYai4Wa+EgMAYxl6Vbcvk55yYP0dj3Op/rD0iS28mcLcbiScAA6H7nqzw1v7JnLJ8Q9Ibudomqhv7KZcN2U86ASEqN/VEKv`
GOVeDDpqaUiTT3/qqbyHvQdF3ThjRSXmvaJvphGfzY8i57xKC8cegoulVROLHp6QAwV8+/cqNbonxxY9KyF3j3onn7CylJ`
AQl4Sakcma3p/YIW5begHO1PsNhSrvKPT2Fr0/SgRmd9NSDKhAqvOkb6/1+JOnJFBUlOVtZLEruOzRc/xaYhKnDZRzRteAg`
dqTTWCDh9aucSAxHgSCcS8PV+yvTdjyfPgdyguNXqXIjKSR1ITL4iCFudNAe8XO2tRs1PPeHC7l18i0mrUxLig2Xs6sNVtY0`
VqdulpaIR253L1gODpy3Ehmh9lg9rdeP70ytTs0lMfEuZjBhuCy1QT4z1Fkv67eg671VxKemfcN2He+0lc/j+2LntP7+JE3I`
4i7shJH5zq35BIWHRZ+H0oXux9k8Z2A96APt0IAg6c/x62zNs7C2dISp8+6IA0I6olPhdi5QreEFJ2I1JJ+2sLnN/Zk9JSwx`
2SbLhKU3/yILQ7e1iKqE9G1Hw7QYy9V4TVnTQenPXaENGO4qexsJDTssAGr4aC0O4RV3GGC3/O9oe9M11qIoii8O2ErJM9SI`
wZMbFIIHEBF1DLpWpmiBDe/4F0DNqB2z0d50w6HeX7IWWVVZLLOX2XXkjfbeaZPM3ifPXfL5xLPOIU1pfnvqmuGgT/FZOEu`
ny4tjirDwtnQvVZT5QnLwNKpMO9O5abxieGKCWVknxZGP5Dp4tRakK7JBbWa4iaD1ZfoaKXXX+tM0ntB6sb7N5f54zm49t+`
6MHqxuboFSuAtBlrj9SIwBqjyXg6rcQcTqfjCTrAyj67PzPPPQU7ZGt7O2M0rXQHRUEc4fkvOpXxluJaVEjPOJbPy39hf2R8`
tN4TxsLvVux3uUfaDaB902SuShpGAQD0yi6PaQdNivjos2eolfpSnBYvVU+7RUqF30FUihefIpdcBZWlOG3locOBIADRAEQK`
Z6NqYhkkmDgNgyQ8lrRkJyLq6eQpkhJR1dLJw7HxBW3HHqudEqOXlIwKUpxAPwQ8AAngWziS4muSeyHhsHHPQpE0aghi4BIN`
UgAWS3V9Z9RLbIiOsvuu0qyYTrwQOtDIs6qdG5c3PYIf+5SWrb/FOCJGWTdFbicWUZNdCOZPxEYDOtBE7ZnG64WNinME23zL`
T6+ONPm7p/H6cJPibFAmgM8yzueBBJfnULqdqba0QXFWBGUE8Gjo1TwMA4AJMUpKt/dYisq05pwUyQKGOff8OgzDeYDgqzvN`
qnKYJDbVEHXJNuKQCzPmOoAYq2ulgmpXo7yhqfGRR1tgULsvzJgAhLvsQFGu5xO25bydk+YSMZXC/M08AKmoN3/z/Lzxk43cK`
RgVaWs0VoQprY4heDLiO5oJiUjsTELneJN5uMpVANNRV+xcsHsJP2LXa00l4uRpKJFWh6ipd9P79wPczH74USvS9mjNQom0Os`
xA2Rn17pdJ+5lXSWPY6LgwzVbHx8j5e6WSSCg6K3AStE/rOJSYrI4no7174RsmnDbevfqICdNgdfyDNe+eTawzr+Pt+gvCwYXJ`
rY4z4m6/u3gW9F6fIs0tDi5Ms9Xxzmjv7uKpz+sC+B8BUGFyToPsqChzuzz9ob+g3diVaEphqmllOFWuKd3eln/R1vDj3YimFK`
aGmUEZ4Er2eFWQB9pdDbEL0WTC5DxlTkOYV1SH5cor+xo98PIlEE1cmGZaGZ5Zu15Ec9WG+6OVIr4PTjqBnA4L08wsu/c25oso`
ii581ZROZqJcdjX8gDBwYXKrC7jFk8GMWfCxksxFeTmuw0/SNAgDFyanBaRWHsyYb6rGKP/nJEM+q369Qxi4MDkz5LYzD2bMha`
fYgav/qUEfk5Ja8JdMCQMXJudUZPHO2/wmWmHBTNj+0wnlLksZbRKNBGHgwuS8QweOMpiSQ5LcjeKeLJnQlsgjDFyYnGP4U8l`
gSq5VG5riNsfngTIJSuq4MM1WBzNCHEzOeVHRZ7Zvvz4Dlk5raUi8XgoTsHqKdHR1E6k46yoWz/3lPlEOXzr54dztCzPmGPtg`
PJj6Uul2K/jgsgkunXzhdEKYS6sDn+zqPNJyoRjS1ZdfetDSyafvbghTWp1zCAUz5tzjbXtzeYhhiNwZ5A8OuSFMZnVWfRqC+`
T1K4qzBH2B4svT8Hjqck3fs3BFmjCAdAyiYMRXFzPPXnyW0YZc1kjvCjDkhPYdAMDWLZy7WZf+yidxolc2lW8L8yUtKQCDBj`
DlX5KJ2bPk6nok814QZ8zzVb6a7YMFUsyjyXDSMq/h9OBN1XRMmtzpnbAimge8N3hfl4yq+jWaiUaaxnElhYlY3UASCGdPhzwF`
UY4kK9KiXT1nx/PVpqAa3urF3vziL/oYv/PBCneighJ6mmWYWTGZyxOpGBBBMZS7KlYmacGL3KBPELGQgVjfTTRFMyY1gqf0VU`
aEMbmxUKBNOdDbHrW7sja55MM2csdReLhA9qZKSI6viFC/DLHlNa9HQB9PMd9a69B4RlTR1Us2mOFuoNPmhj/XkqQ+mmS7r2p8`
Q5cA6ySOcd2G2tGhNGteLKC08tfdLRJoBSNGiOE/C0IrVOR8jgK/8yW6iS6xO8tyL5lNam7cRgKJSIipBo/ipe06XVjfzPAK44`
W8CEBWgm4M+noXCjJkR2ZHngs+UiA6QsnNCKOJ0S1bH5XnG6vgmiTJyxaBBKC+tWp3zCYgnr+NJ1JEqXriWhpjVTbwHwsk29up`
EVeAxlQps9VALuBNso1ZiBVmVKA8Mj4sEcmzb6pwPUWqYE/JEw/Q95gieyFm3OkdEaeFt0ZCon/4Yd8c1cUqrW6mVeJdJ9Cx9O`
D3XVk6ZG2wkI95lPiYSpELYKDpfh9lyTKn4nFk4hVY4NvYvTx2wOuL2N8A7bpyiY+2ltDrodjycHM/UF9UIZOaE1aXboXCa8Se`
breGfOmF16XYwnGZeJFWfvlt53WB13O14OEl0Ai3CqaXzmADgcOI56cit6YcggE9oOPG3RTtOZaITQvhgIZySwSjg+C51mC/B2`
QEaTvyxVuHS4PhHe2fQ0zgMROHnS6UVlwiOEKSNOESpFUoSWtpll0poI8H//0EIejCgQHE8sZ8jfz/hyW/mzdhtCrjRO8rp3JN`
+M+3hSziy9SwncHL56ZcaPLFTw5WNdzmBxdX7gZ3odBZwpZOV0z7WX/DIWcPgNXk+yH0yQIGls2sIsAoip4n1AEvuzGDw24v2`
cMOsmq4AkuWxsbr3XrSDG2bV9IvlbVIOg+9e1EGI5RLguGM3Vvc/FxVgIqex+si5SIGJisbqI1s7qGhprA7gxl7NHlxcuz/6C`
CnnClxU7tdDYjzYy3kDLjKWPgRgby/nFmRo1wsNOXb2cu5BRsZSOUfl+B3Y0CyHcyDHR5biXylIKufAM8/YYucbNUGCPxB9Tn`
ojD5/gD/TRN3YXu5cILWcDRtqRb2iCy8nX2EeXTw1xVvE39rGzZq6A6eWMawFiqAjUtDb7HWix87tWkEe9lzPeTnSgdOlC8jE`
+4k50IMuDJCTD4tEQdSey+lMqXWAaWks1/4CcTB/fF5eYivrREO1M9JH2iONrhcmoLOXcIAJa/XU6KhUm5H5WpdPM8LUe0rLK`
MC1/Z1Y6Daqt9LWpl7oqC0zO7XxS5yBF9oo3Tz3PKHWG5+Tpg1qRvaeh47yfy8BOwdkMY1JA7mcZk4KxTl4XRN0mrwty8ZS8L`
shpn7wuyL/kdUnWyeuCLJ6T1wU5XaV5fYrSGevLOSrUeta7Od8srUpnh8S3XPYWa/gI7tzCov7/QMW7bbPZdSkiHef8m4E9qWj`
NWT9wGJtmk1QcRffZ0unmwoVGrjC+AOoGFOg1DCDZAAAAAElFTkSuQmCC"

$Iconstream = [System.IO.MemoryStream][System.Convert]::FromBase64String($base64)
$Iconbmp    = [System.Drawing.Bitmap][System.Drawing.Image]::FromStream($Iconstream)
$Iconhandle = $Iconbmp.GetHicon()
$Icon       = [System.Drawing.Icon]::FromHandle($Iconhandle)

CheckFordiskspd
$MainForm.Size = New-Object system.drawing.size @(1060,600);
$MainForm.Text = "DiskSpeed v0.8.2"
$MainForm.Icon = $icon
$MainForm.ShowDialog();
#endregion


