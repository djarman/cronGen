# Readme: cronGen

## Overview

`cronGen.ps1` is a Windows PowerShell desktop utility for creating seven-field cron expressions. It provides a form for entering each cron field, validates the values, displays the generated expression, and copies it to the clipboard.

## Requirements

- Windows
- Windows PowerShell with access to `System.Windows.Forms` and `System.Drawing`
- Permission to run local PowerShell scripts

## Start the tool

Open PowerShell in the folder containing the script and run:

```powershell
powershell -ExecutionPolicy Bypass -File ".\cronGen.ps1"
```

The generator opens in a desktop window. It generates an initial expression using the default values when the window opens.

## Field order

The tool uses this seven-field format:

```text
seconds minute hour day-of-month month day-of-week year
```

| Field | Valid values | Examples |
|---|---|---|
| Seconds | `0`-`59` | `0`, `30` |
| Minute | `0`-`59` | `0`, `15` |
| Hour | `0`-`23` | `0`, `10`, `23` |
| Day of month | `1`-`31`, `*`, or `?` | `1`, `15`, `*`, `?` |
| Month | `1`-`12`, three-letter names, ranges, or `*` | `1`, `JUN`, `JAN-MAR`, `*` |
| Day of week | `0`-`7`, three-letter names, ranges, comma-separated values, `*`, or `?` | `1-5`, `MON`, `MON-FRI`, `*`, `?` |
| Year | `1970`-`2199`, a range, or `*` | `2026`, `2026-2030`, `*` |

For day of week, `0` and `7` conventionally represent Sunday. Confirm the convention used by the scheduler where the expression will run.

## Using the form

1. Enter a value in each field.
2. Leave the year blank when the job should run every year. A blank year is converted to `*`.
3. Use a hyphen to specify a range. For example, enter `1-5` for Monday through Friday or `2026-2030` for a five-year period.
4. Click **Generate cron**, or press Enter.
5. Click **Copy** to place the generated expression on the clipboard.

Use `?` to specify no specific value in either day-of-month or day-of-week. Only one of these two fields may contain `?` at a time. For example, use `?` for day of month when scheduling by weekday, or use `?` for day of week when scheduling by calendar date.

Month and weekday names are entered using their first three letters, such as `JAN`, `JUN`, `MON`, or `FRI`. Names are case-insensitive. Named ranges such as `MON-FRI` and `JAN-MAR` are also accepted and are converted to numeric values in the output.

## Examples

### Every weekday at 10:15:00, from 2026 through 2030

Inputs:

```text
Seconds: 0
Minute: 15
Hour: 10
Day of month: *
Month: *
Day of week: 1-5
Year: 2026-2030
```

Output:

```text
0 15 10 * * 1-5 2026-2030
```

### Every day at midnight, regardless of year

Inputs:

```text
Seconds: 0
Minute: 0
Hour: 0
Day of month: *
Month: *
Day of week: *
Year: [leave blank]
```

Output:

```text
0 0 0 * * * *
```

### Every Monday at 08:30:00 in 2026

Output:

```text
0 30 8 * * 1 2026
```

## Validation behavior

The tool rejects values that are outside their field range, contain unsupported characters, or use reversed ranges. For example:

- `60` is invalid for seconds or minute.
- `24` is invalid for hour.
- `1-8` is invalid for day of week.
- `2030-2026` is invalid because the range is reversed.
- `2200` is invalid for year.
- `?` cannot be used in both day of month and day of week at the same time.

When an entry is invalid, the error appears below the output field and no expression is produced.

## Troubleshooting

### The script will not run

Use the explicit execution-policy command shown above. If the script is blocked by organizational policy, contact the PowerShell or endpoint-management administrator rather than changing the policy globally.

### The output uses the wrong field order

Verify that the scheduler supports seven-field cron syntax and expects:

```text
seconds minute hour day-of-month month day-of-week year
```

Some cron implementations use five fields and do not support seconds or year. This tool is intended for schedulers that support the seven-field format.

### The generated schedule does not run

Check the target scheduler's documentation for day-of-week numbering, whether `0` or `7` means Sunday, and whether it supports ranges and the year field. Also verify that the selected day-of-month and day-of-week semantics match that scheduler.
