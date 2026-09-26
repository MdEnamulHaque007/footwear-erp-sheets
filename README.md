# footwear-erp-sheets
# Footwear ERP Sheets

Flutter application for reading public Google Sheets data.

## Cutting

Open the drawer and select **Cutting**. Enter the spreadsheet URL or ID,
the exact tab name, a one-row header range (for example `A1:H1`), and a data
range in the same columns below it (for example `A2:H`). Press **Read Cutting
Data** to display the rows. The last successful settings are remembered in
the browser or device.

The spreadsheet must be shared for public viewing. The app reads data only;
it does not modify the Google Sheet.
