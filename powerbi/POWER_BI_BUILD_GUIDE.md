# Power BI build guide

The finished report is `HR_Attrition_Dashboard.pbix` in this folder. This guide documents how it was built.

Build this report yourself in Power BI Desktop and save it as `powerbi/HR_Attrition_Dashboard.pbix`. The numbers below come from the SQL/Python/Excel analysis, so you can check every visual against them.

## 1. Load data
1. **Get data → Text/CSV →** `data/hr_attrition_clean.csv` → **Transform Data**.
2. In Power Query check that numeric columns are Whole Number and text columns are Text. Rename the query to `employees`. **Close & Apply**.

## 2. Calculated columns (Table tools → New column)
```DAX
Age Band =
SWITCH ( TRUE (),
    employees[age] < 25, "Under 25",
    employees[age] < 35, "25-34",
    employees[age] < 45, "35-44",
    employees[age] < 55, "45-54",
    "55+" )

Age Band Sort =
SWITCH ( TRUE (),
    employees[age] < 25, 1,
    employees[age] < 35, 2,
    employees[age] < 45, 3,
    employees[age] < 55, 4,
    5 )

Tenure Band =
SWITCH ( TRUE (),
    employees[years_at_company] <= 1,  "0-1 yr",
    employees[years_at_company] <= 3,  "2-3 yrs",
    employees[years_at_company] <= 5,  "4-5 yrs",
    employees[years_at_company] <= 10, "6-10 yrs",
    "10+ yrs" )

Tenure Band Sort =
SWITCH ( TRUE (),
    employees[years_at_company] <= 1,  1,
    employees[years_at_company] <= 3,  2,
    employees[years_at_company] <= 5,  3,
    employees[years_at_company] <= 10, 4,
    5 )
```
Select `Age Band` → **Column tools → Sort by column → Age Band Sort**. Do the same for `Tenure Band`. Build each sort column from the raw column (`age`, `years_at_company`), not from the band column, otherwise Power BI reports a circular dependency.

## 3. Measures (New measure)
```DAX
Employees       = COUNTROWS ( employees )
Attrition Count = CALCULATE ( COUNTROWS ( employees ), employees[attrition] = "Yes" )
Active Employees = CALCULATE ( COUNTROWS ( employees ), employees[attrition] = "No" )
Attrition Rate  = DIVIDE ( [Attrition Count], [Employees] )
Avg Age         = AVERAGE ( employees[age] )
Company Rate    = CALCULATE ( [Attrition Rate], ALL ( employees ) )
Rate vs Company = [Attrition Rate] - [Company Rate]
Avg Income Left   = CALCULATE ( AVERAGE ( employees[monthly_income] ), employees[attrition] = "Yes" )
Avg Income Stayed = CALCULATE ( AVERAGE ( employees[monthly_income] ), employees[attrition] = "No" )
```
Format `Attrition Rate`, `Company Rate` as percentage (1 decimal). `Rate vs Company` as percentage.

## 4. Validate before you design anything
Put a card or table for each and compare:

| Measure | Expected |
|---|---:|
| Employees | 1,470 |
| Attrition Count | 237 |
| Attrition Rate | 16.1% |
| Active Employees | 1,233 |
| Avg Age | 36.92 |
| Sales / HR / R&D attrition rate | 20.6% / 19.0% / 13.8% |
| Overtime Yes / No | 30.5% / 10.4% |
| Sales Representative | 39.8% |
| Under 25 | 39.2% |
| Tenure 0-1 yr | 34.9% |

If any number differs, fix the measure before building pages.

## 5. Pages (design it your own way, simple and light)
**Page 1: Overview.** Five cards (Employees, Attrition Count, Attrition Rate, Active, Avg Age). Bar: Attrition Rate by Department. Column: Attrition Rate by Age Band. Slicers: Department, Gender, Business Travel.

**Page 2: Drivers.** Bar: Attrition Rate by Job Role (sorted descending, with `Company Rate` as a constant line). Column: Attrition Rate by Overtime. Column: by Tenure Band. Matrix: Marital Status x Over Time with Attrition Rate and conditional-format background.

**Page 3: People profile.** Employees by Job Role, by Education Field, Gender split, Avg Income Left vs Avg Income Stayed (4,787 vs 6,833).

**Design rules:** white or light grey background, 2-3 colours (blue normal, orange above-average), no background image, titles that say the finding ("Overtime staff leave 3x as often"), data labels on, same font throughout. Use your own layout rather than copying any dashboard you have seen.

## 6. After it works
1. Save as `powerbi/HR_Attrition_Dashboard.pbix`.
2. Export each page: **File → Export → Export to PDF**, and take PNG screenshots into `images/` (`powerbi_overview.png`, `powerbi_drivers.png`, `powerbi_profile.png`).
3. Add this section to `README.md` (only after the files exist):
```markdown
## Power BI dashboard
![Overview](images/powerbi_overview.png)
![Drivers](images/powerbi_drivers.png)
Three pages: Overview, Attrition Drivers, People Profile. DAX measures are listed in `powerbi/POWER_BI_BUILD_GUIDE.md`.
```

## Interview prep: be ready to explain
- Why the rate, not the count, is the right comparison (R&D has the most leavers but the lowest rate).
- What `CALCULATE` and `ALL` do in `Company Rate`.
- Why correlation here is not causation, and why this sample data cannot support real-company claims.

## Known quirk
In recent Power BI Desktop builds a card may show `1K` for 1,470. Use a text measure for display, e.g. `Employees Display = FORMAT ( [Employees], "#,##0" )`, and keep the numeric measures for charts and calculations.
