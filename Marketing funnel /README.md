![A4 - 1](https://user-images.githubusercontent.com/119155885/205064527-8a58fd4b-09ee-4bee-8777-843e0ee56d29.png)
 
### Marketing agency data vizualization
 
**Data description:**  
Data of customer registrations, connected advertising accounts and transaction history of transfers to advertising systems.
Detalization by marketing system, user country, currency, registration date, etc.
 
**Task:**  
Develop dashboards with the following indicators:
* Amount of revenue (total + structure)
* Number of users
* Average check
* Churn rate (method chooses author by themselves)
* Cohort by user registration date by revenue
* Cohort by user registration date by number of users  
 
Dashboard sgoul provide ability to display in months / quarters / years, and in advertising systems / user country / segment by revenue (method chooses author by themselves) / currency / utm tags
 
**Instruments:**  
Data marts and churn rate calculation is made using **Postgre SQL**.  
Revenue segmentation is made in **Jupyter Notebbok**, using pandas, numpy and psycopg2.    
Vizualization of data and cohort analysis are made in **Power BI**, dashboard is presented in PDF format.
 
**Study content:**  
1. Bulding data marts
2. Revenue segmentation by ABC-XYZ analysis
3. Vizualization
