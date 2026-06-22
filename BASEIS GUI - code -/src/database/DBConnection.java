package database;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBConnection {
    private static final String URL =  "jdbc:mysql://localhost:3306/travel_agency";
    private static final String USER = "root";
    private static final String PASSWORD = "MUST BE FILLED";

    public static Connection getConnection() {
        Connection conn = null;
        try {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
            } catch (ClassNotFoundException e) {
                Class.forName("com.mysql.jdbc.Driver");
            }

            conn = DriverManager.getConnection(URL, USER, PASSWORD);
            System.out.println("DEBUG: Επιτυχής σύνδεση στη βάση!");
        } catch (ClassNotFoundException | SQLException e) {
            System.err.println("ΣΦΑΛΜΑ ΣΥΝΔΕΣΗΣ: " + e.getMessage());
        }
        return conn;
    }
}
