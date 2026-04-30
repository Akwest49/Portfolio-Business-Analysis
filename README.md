# Online Retail — Small Store Sales Analysis

[![SQL Server](https://img.shields.io/badge/SQL%20Server-16.x-blue)](https://www.microsoft.com/sql-server)
[![Dataset](https://img.shields.io/badge/data-Kaggle-orange)](https://www.kaggle.com/datasets/tunguz/online-retail)
[![Repo](https://img.shields.io/badge/repo-Portfolio--Business--Analysis-lightgrey)](https://github.com/Akwest49/Portfolio-Business-Analysis)

Short project summary
- Cleaned and transformed one year of online retail sales.
- Produced cleaned table, error/cancellation tables, and business projections (monthly/annual sales, time-of-day, top products/customers, cancellations).
-Data visualizations can be found on this Tableau Dashboard: ________

Repository
- CSV: `Online_Retail.csv`
- SQL script: `Online_Retail_Querry.sql`
- Repo: https://github.com/Akwest49/Portfolio-Business-Analysis
- Original dataset: https://www.kaggle.com/datasets/tunguz/online-retail?select=Online_Retail.csv

Cleaning Notes:
- Pre-SQL Python cleaning performed on the CSV from Kaggle (not included).
- Download the CSV from the repo for the SQL file.

Environment
- Microsoft SQL Server Express (64-bit), Version 16.0.x
- SQL client: SQL Server Management Studio (SSMS) or `sqlcmd`

Schema (original table)
- Database: `Portfolio`  
- Table: `Online_Retail`
  - InvoiceNo NVARCHAR(50)
  - StockCode NVARCHAR(50)
  - Description NVARCHAR(50)
  - Quantity INT
  - InvoiceDate NVARCHAR(50)
  - UnitPrice DECIMAL(18,10)
  - CustomerID NVARCHAR(50)
  - Country NVARCHAR(50)

Quick start
1. Download `Online_Retail.csv`.
2. Create a database with the name "Portfolio"
3. Import the csv as a flat file and use the above schema for the column types.
4. Open `Online_Retail_Querry.sql` in SSMS.
5. Read the introduction.
6. Read each comment and then run the accompanying script.
7. Run the script in batches according to the comments.

Author
- Repository owner: Akwest49
