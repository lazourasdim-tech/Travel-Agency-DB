# Travel Agency Management System

## Overview

A university project where we designed a MySQL database for a multi-branch travel
agency — branches, staff, customers, vehicles, trips, destinations, accommodations,
and reservations — and built the logic for the agency's actual day-to-day needs:
assigning vehicles to trips, booking accommodation, and logging changes. A small
Java desktop app sits on top so the database admin can manage all the data from there.

## Team

* Academic project developed by a team of 3 students.

## Tech Stack

* Language: Java (Swing) · SQL
* Database: MySQL
* Connectivity: JDBC (MySQL Connector/J)
* Tools: IntelliJ IDEA, MySQL Workbench, Git

## My Contributions

I was mainly responsible for the database design and for testing and documentation. On the design side, I worked out the EER diagram and schema. Moreover, I designed and ran the test cases for the stored procedures and triggers.

## How to Run

Prerequisites: MySQL 8+, JDK 8+, MySQL Connector/J driver.

1. Clone the repository:
   ```bash
   git clone https://github.com/lazourasdim-tech/Travel-Agency-DB.git
   cd Travel-Agency-DB
   ```
2. Run the schema file against MySQL:
   ```bash
   mysql -u root -p < travel_agency.sql
   ```
3. Open `BASEIS GUI - code -/src/database/DBConnection.java` and replace the placeholder password with your own.
4. Open the project
- Open the `BASEIS GUI - code -` folder as the project.
- If `src` is not already marked as sources, right-click it and choose **Mark Directory as → Sources Root**.
- Add the bundled driver as a library: **File → Project Structure → Libraries → + → Java**, then select `lib/mysql-connector-j-9.6.0.jar`.
5. Run the main method in gui.MainFrame (src/gui/MainFrame.java)
