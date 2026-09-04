Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$fields = @(
    @{ Name = 'Seconds'; Label = 'Seconds'; Default = '0'; Hint = '0-59' }
    @{ Name = 'Minute'; Label = 'Minute'; Default = '0'; Hint = '0-59' }
    @{ Name = 'Hour'; Label = 'Hour'; Default = '0'; Hint = '0-23' }
    @{ Name = 'DayOfMonth'; Label = 'Day of month'; Default = '*'; Hint = '1-31 or *' }
    @{ Name = 'Month'; Label = 'Month'; Default = '*'; Hint = '1-12 or *' }
    @{ Name = 'DayOfWeek'; Label = 'Day of week'; Default = '*'; Hint = '1-5, 0 or *' }
    @{ Name = 'Year'; Label = 'Year'; Default = '*'; Hint = '2026-2030 or *' }
)

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Cronjob Generator'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(560, 500)
$form.MinimumSize = New-Object System.Drawing.Size(560, 500)
$form.BackColor = [System.Drawing.Color]::FromArgb(20, 29, 43)
$form.ForeColor = [System.Drawing.Color]::White

$title = New-Object System.Windows.Forms.Label
$title.Text = 'Cronjob Generator'
$title.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 20)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(28, 20)
$form.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = 'Enter each field to create a 7-field cron expression.'
$subtitle.ForeColor = [System.Drawing.Color]::LightGray
$subtitle.AutoSize = $true
$subtitle.Location = New-Object System.Drawing.Point(31, 58)
$form.Controls.Add($subtitle)

$inputs = @{}
for ($index = 0; $index -lt $fields.Count; $index++) {
    $field = $fields[$index]
    $column = $index % 4
    $row = [Math]::Floor($index / 4)
    $x = 28 + ($column * 128)
    $y = 100 + ($row * 92)

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $field.Label
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point($x, $y)
    $form.Controls.Add($label)

    $input = New-Object System.Windows.Forms.TextBox
    $input.Text = $field.Default
    $input.Tag = $field.Hint
    $input.Size = New-Object System.Drawing.Size(108, 25)
    $input.Location = New-Object System.Drawing.Point($x, ($y + 25))
    $input.BackColor = [System.Drawing.Color]::FromArgb(36, 49, 68)
    $input.ForeColor = [System.Drawing.Color]::White
    $input.BorderStyle = 'FixedSingle'
    $form.Controls.Add($input)
    $inputs[$field.Name] = $input
}

$formatLabel = New-Object System.Windows.Forms.Label
$formatLabel.Text = 'Format: seconds minute hour day-of-month month day-of-week year'
$formatLabel.ForeColor = [System.Drawing.Color]::LightGray
$formatLabel.AutoSize = $true
$formatLabel.Location = New-Object System.Drawing.Point(28, 286)
$form.Controls.Add($formatLabel)

$generate = New-Object System.Windows.Forms.Button
$generate.Text = 'Generate cron'
$generate.Size = New-Object System.Drawing.Size(140, 34)
$generate.Location = New-Object System.Drawing.Point(28, 315)
$generate.BackColor = [System.Drawing.Color]::FromArgb(45, 160, 150)
$generate.ForeColor = [System.Drawing.Color]::White
$generate.FlatStyle = 'Flat'
$form.Controls.Add($generate)

$copy = New-Object System.Windows.Forms.Button
$copy.Text = 'Copy'
$copy.Size = New-Object System.Drawing.Size(90, 34)
$copy.Location = New-Object System.Drawing.Point(178, 315)
$copy.BackColor = [System.Drawing.Color]::FromArgb(52, 73, 94)
$copy.ForeColor = [System.Drawing.Color]::White
$copy.FlatStyle = 'Flat'
$form.Controls.Add($copy)

$output = New-Object System.Windows.Forms.TextBox
$output.ReadOnly = $true
$output.Font = New-Object System.Drawing.Font('Consolas', 14)
$output.Size = New-Object System.Drawing.Size(480, 32)
$output.Location = New-Object System.Drawing.Point(28, 375)
$output.BackColor = [System.Drawing.Color]::FromArgb(11, 18, 29)
$output.ForeColor = [System.Drawing.Color]::FromArgb(166, 240, 196)
$output.BorderStyle = 'FixedSingle'
$form.Controls.Add($output)

$status = New-Object System.Windows.Forms.Label
$status.AutoSize = $false
$status.Size = New-Object System.Drawing.Size(480, 42)
$status.Location = New-Object System.Drawing.Point(28, 417)
$status.ForeColor = [System.Drawing.Color]::LightGray
$form.Controls.Add($status)

function New-CronResult {
    $limits = @{
        Seconds = @(0, 59)
        Minute = @(0, 59)
        Hour = @(0, 23)
        DayOfMonth = @(1, 31)
        Month = @(1, 12)
        Year = @(1970, 2199)
    }

    $monthNames = @{
        JAN = 1; FEB = 2; MAR = 3; APR = 4; MAY = 5; JUN = 6
        JUL = 7; AUG = 8; SEP = 9; OCT = 10; NOV = 11; DEC = 12
    }
    $dayOfWeekNames = @{
        SUN = 0; MON = 1; TUE = 2; WED = 3; THU = 4; FRI = 5; SAT = 6
    }
    $normalizedValues = @{}
    $normalizePart = {
        param([string]$Part, [hashtable]$Names)
        $segments = $Part.ToUpperInvariant() -split '-'
        $converted = foreach ($segment in $segments) {
            if ($Names.ContainsKey($segment)) { $Names[$segment] }
            elseif ($segment -match '^\d+$') { $segment }
            else { throw "Use a three-letter name or numeric value in '$Part'." }
        }
        return ($converted -join '-')
    }

    $dayOfMonthValue = $inputs.DayOfMonth.Text.Trim()
    $dayOfWeekValue = $inputs.DayOfWeek.Text.Trim()
    if ($dayOfMonthValue -eq '?' -and $dayOfWeekValue -eq '?') {
        throw 'Use ? in day of month or day of week, but not both.'
    }

    foreach ($field in $fields) {
        $value = $inputs[$field.Name].Text.Trim()
        $normalizedValues[$field.Name] = $value
        if ($field.Name -eq 'Year' -and [string]::IsNullOrWhiteSpace($value)) { continue }
        if ($field.Name -in @('DayOfMonth', 'DayOfWeek') -and $value -eq '?') { continue }
        if ($field.Name -eq 'DayOfWeek' -and $value -eq '*') { continue }
        if ($field.Name -in @('DayOfMonth', 'Month', 'Year') -and $value -eq '*') { continue }
        if ($field.Name -eq 'DayOfWeek') {
            $value = (($value -split ',') | ForEach-Object { & $normalizePart $_ $dayOfWeekNames }) -join ','
        }
        if ($field.Name -eq 'Month' -and $value -ne '*') {
            $value = & $normalizePart $value $monthNames
        }
        $normalizedValues[$field.Name] = $value
        if ($field.Name -eq 'DayOfWeek') {
            if ($value -notmatch '^[0-7](?:-[0-7])?(?:,[0-7](?:-[0-7])?)*$') {
                throw 'Day of week must be *, a value, or a hyphenated range from 0 to 7.'
            }
            foreach ($part in $value -split ',') {
                if ($part -match '-') {
                    $range = $part -split '-'
                    if ([int]$range[0] -gt [int]$range[1]) { throw 'Day of week ranges must start with the smaller value.' }
                }
            }
            continue
        }
        if ($field.Name -eq 'Month' -and $value -match '^\d+(?:-\d+)?$') {
            $range = $value -split '-'
            foreach ($rangeValue in $range) {
                $number = [int]$rangeValue
                if ($number -lt $limits.Month[0] -or $number -gt $limits.Month[1]) {
                    throw 'Month values must be between 1 and 12.'
                }
            }
            if ($range.Count -eq 2 -and [int]$range[0] -gt [int]$range[1]) { throw 'Month ranges must start with the smaller month.' }
            continue
        }
        if ($field.Name -eq 'Year' -and $value -match '^\d+-\d+$') {
            $range = $value -split '-'
            foreach ($rangeValue in $range) {
                $number = [int]$rangeValue
                if ($number -lt $limits.Year[0] -or $number -gt $limits.Year[1]) {
                    throw 'Year values must be between 1970 and 2199.'
                }
            }
            if ([int]$range[0] -gt [int]$range[1]) { throw 'Year ranges must start with the smaller year.' }
            continue
        }
        if ($value -notmatch '^\d+$') { throw "$($field.Label) must be a number or *." }
        $number = [int]$value
        if ($number -lt $limits[$field.Name][0] -or $number -gt $limits[$field.Name][1]) {
            throw "$($field.Label) must be between $($limits[$field.Name][0]) and $($limits[$field.Name][1])."
        }
    }

    $values = $fields | ForEach-Object {
        $value = $normalizedValues[$_.Name]
        if ($_.Name -eq 'Year' -and [string]::IsNullOrWhiteSpace($value)) { return '*' }
        return $value
    }
    return ($values -join ' ')
}

$generate.Add_Click({
    try {
        $output.Text = New-CronResult
        $status.Text = 'Valid 7-field cron expression. Fields run from left to right as shown above.'
        $status.ForeColor = [System.Drawing.Color]::LightGray
    }
    catch {
        $output.Text = ''
        $status.Text = $_.Exception.Message
        $status.ForeColor = [System.Drawing.Color]::Salmon
    }
})

$copy.Add_Click({
    if ($output.Text) {
        [System.Windows.Forms.Clipboard]::SetText($output.Text)
        $status.Text = 'Cron expression copied to the clipboard.'
        $status.ForeColor = [System.Drawing.Color]::FromArgb(166, 240, 196)
    }
})

$form.AcceptButton = $generate
$form.Add_Shown({ $generate.PerformClick() })
[void]$form.ShowDialog()