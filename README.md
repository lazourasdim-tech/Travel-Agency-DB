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
   cd travel-agency-management-system
   ```
2. Run the schema file against MySQL:
   ```bash
   mysql -u root -p < travel_agency.sql
   ```
3. Open `src/database/DBConnection.java` and set `URL`, `USER`, `PASSWORD`.
4. Add the MySQL Connector/J `.jar` to the project classpath.
5. Run `MainFrame.main()` (package `gui`).
