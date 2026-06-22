package gui;

import database.DBConnection;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.sql.*;

public class TripDetailsFrame extends JFrame {
    private JComboBox<ComboItem> tripSelector;
    private JTextArea infoArea;
    private JTable participantsTable;
    private DefaultTableModel participantsModel;
    private JTable accommodationTable;
    private DefaultTableModel accommodationModel;
    private JLabel vehicleLabel;

    public TripDetailsFrame() {
        setTitle("Πλήρης Επισκόπηση Ταξιδιού (Bonus)");
        setSize(800, 600);
        setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
        setLocationRelativeTo(null);
        setLayout(new BorderLayout());

        JPanel topPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        topPanel.add(new JLabel("Επιλογή Ταξιδιού:"));
        tripSelector = new JComboBox<>();
        tripSelector.setPreferredSize(new Dimension(300, 25));
        topPanel.add(tripSelector);
        JButton btnLoad = new JButton("Προβολή");
        topPanel.add(btnLoad);
        add(topPanel, BorderLayout.NORTH);

        JTabbedPane tabbedPane = new JTabbedPane();

        JPanel infoPanel = new JPanel(new BorderLayout());
        infoArea = new JTextArea();
        infoArea.setEditable(false);
        infoArea.setFont(new Font("Monospaced", Font.PLAIN, 14));
        infoPanel.add(new JScrollPane(infoArea), BorderLayout.CENTER);
        tabbedPane.addTab("Γενικές Πληροφορίες", infoPanel);

        JPanel partPanel = new JPanel(new BorderLayout());
        participantsModel = new DefaultTableModel(new String[]{"Όνομα", "Επώνυμο", "Κατάσταση", "Κόστος"}, 0);
        participantsTable = new JTable(participantsModel);
        partPanel.add(new JScrollPane(participantsTable), BorderLayout.CENTER);
        tabbedPane.addTab("Συμμετέχοντες", partPanel);

        JPanel accPanel = new JPanel(new BorderLayout());
        accommodationModel = new DefaultTableModel(new String[]{"Πόλη", "Κατάλυμα", "Check-in", "Check-out"}, 0);
        accommodationTable = new JTable(accommodationModel);
        accPanel.add(new JScrollPane(accommodationTable), BorderLayout.CENTER);
        tabbedPane.addTab("Διαμονή & Πρόγραμμα", accPanel);

        JPanel vehPanel = new JPanel(new GridBagLayout());
        vehicleLabel = new JLabel("Δεν έχει ανατεθεί όχημα.");
        vehicleLabel.setFont(new Font("Arial", Font.BOLD, 16));
        vehPanel.add(vehicleLabel);
        tabbedPane.addTab("Όχημα", vehPanel);

        add(tabbedPane, BorderLayout.CENTER);

        loadTrips();

        btnLoad.addActionListener(e -> {
            ComboItem item = (ComboItem) tripSelector.getSelectedItem();
            if (item != null) {
                loadTripDetails(item.getKey());
            }
        });
    }

    private void loadTrips() {
        try (Connection conn = DBConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT tr_id, tr_departure, tr_return FROM trip ORDER BY tr_departure DESC")) {

            while (rs.next()) {
                String label = "Trip " + rs.getInt("tr_id") + " (" + rs.getString("tr_departure") + ")";
                tripSelector.addItem(new ComboItem(String.valueOf(rs.getInt("tr_id")), label));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    private void loadTripDetails(String tripId) {
        try (Connection conn = DBConnection.getConnection()) {

            String sqlInfo = "SELECT t.*, b.br_city, g.gui_AT, d.drv_AT FROM trip t " +
                    "JOIN branch b ON t.tr_br_code = b.br_code " +
                    "LEFT JOIN guide g ON t.tr_gui_AT = g.gui_AT " +
                    "LEFT JOIN driver d ON t.tr_drv_AT = d.drv_AT " +
                    "WHERE t.tr_id = ?";
            try (PreparedStatement pstmt = conn.prepareStatement(sqlInfo)) {
                pstmt.setInt(1, Integer.parseInt(tripId));
                ResultSet rs = pstmt.executeQuery();
                if (rs.next()) {
                    StringBuilder sb = new StringBuilder();
                    sb.append("Κωδικός Ταξιδιού: ").append(rs.getInt("tr_id")).append("\n\n");
                    sb.append("Αναχώρηση: ").append(rs.getString("tr_departure")).append("\n");
                    sb.append("Επιστροφή: ").append(rs.getString("tr_return")).append("\n");
                    sb.append("Κόστος (Ενήλικες): ").append(rs.getDouble("tr_cost_adult")).append(" €\n");
                    sb.append("Κόστος (Παιδιά):   ").append(rs.getDouble("tr_cost_child")).append(" €\n");
                    sb.append("Θέσεις: ").append(rs.getInt("tr_maxseats")).append("\n");
                    sb.append("Κατάσταση: ").append(rs.getString("tr_status")).append("\n\n");
                    sb.append("Οργάνωση: Υποκατάστημα ").append(rs.getString("br_city")).append("\n");
                    sb.append("Ξεναγός (AT): ").append(rs.getString("tr_gui_AT")).append("\n");
                    sb.append("Οδηγός (AT):  ").append(rs.getString("tr_drv_AT")).append("\n");
                    infoArea.setText(sb.toString());
                }
            }

            participantsModel.setRowCount(0);
            String sqlPart = "SELECT c.cust_name, c.cust_lname, r.res_status, r.res_total_cost " +
                    "FROM reservation r JOIN customer c ON r.res_cust_id = c.cust_id " +
                    "WHERE r.res_tr_id = ?";
            try (PreparedStatement pstmt = conn.prepareStatement(sqlPart)) {
                pstmt.setInt(1, Integer.parseInt(tripId));
                ResultSet rs = pstmt.executeQuery();
                while (rs.next()) {
                    participantsModel.addRow(new Object[]{
                            rs.getString("cust_name"),
                            rs.getString("cust_lname"),
                            rs.getString("res_status"),
                            rs.getDouble("res_total_cost") + " €"
                    });
                }
            }

            accommodationModel.setRowCount(0);
            String sqlAcc = "SELECT d.dst_name, a.acc_name, ta.ta_checkin, ta.ta_checkout " +
                    "FROM trip_accommodation ta " +
                    "JOIN accommodation a ON ta.ta_acc_id = a.acc_id " +
                    "JOIN destination d ON a.acc_dst_id = d.dst_id " +
                    "WHERE ta.ta_tr_id = ?";
            try (PreparedStatement pstmt = conn.prepareStatement(sqlAcc)) {
                pstmt.setInt(1, Integer.parseInt(tripId));
                ResultSet rs = pstmt.executeQuery();
                while (rs.next()) {
                    accommodationModel.addRow(new Object[]{
                            rs.getString("dst_name"),
                            rs.getString("acc_name"),
                            rs.getString("ta_checkin"),
                            rs.getString("ta_checkout")
                    });
                }
            }

            String sqlVeh = "SELECT v.veh_brand, v.veh_model, v.veh_license_plate, v.veh_type " +
                    "FROM trip t JOIN vehicle v ON t.tr_veh_id = v.veh_id " +
                    "WHERE t.tr_id = ?";
            try (PreparedStatement pstmt = conn.prepareStatement(sqlVeh)) {
                pstmt.setInt(1, Integer.parseInt(tripId));
                ResultSet rs = pstmt.executeQuery();
                if (rs.next()) {
                    String info = "<html><center><h2>" + rs.getString("veh_brand") + " " + rs.getString("veh_model") + "</h2>" +
                            "<h3>" + rs.getString("veh_license_plate") + " (" + rs.getString("veh_type") + ")</h3></center></html>";
                    vehicleLabel.setText(info);
                    vehicleLabel.setForeground(new Color(0, 100, 0));
                } else {
                    vehicleLabel.setText("Δεν έχει ανατεθεί όχημα.");
                    vehicleLabel.setForeground(Color.RED);
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
            JOptionPane.showMessageDialog(this, "Σφάλμα ανάκτησης δεδομένων: " + e.getMessage());
        }
    }
}