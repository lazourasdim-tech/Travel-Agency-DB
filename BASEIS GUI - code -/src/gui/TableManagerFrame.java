package gui;

import database.DBConnection;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.sql.*;
import java.util.HashMap;
import java.util.Map;
import java.util.Vector;

public class TableManagerFrame extends JFrame {
    private String tableName;
    private JTable table;
    private DefaultTableModel model;

    public TableManagerFrame(String tableName) {
        this.tableName = tableName;

        setTitle("Διαχείριση Πίνακα: " + tableName.toUpperCase());
        setSize(900, 600);
        setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
        setLocationRelativeTo(null);
        setLayout(new BorderLayout());

        table = new JTable();
        model = new DefaultTableModel() {
            @Override
            public boolean isCellEditable(int row, int column) { return false; }
        };
        table.setModel(model);
        add(new JScrollPane(table), BorderLayout.CENTER);

        JPanel buttonPanel = new JPanel();
        JButton btnAdd = new JButton("Προσθήκη");
        JButton btnEdit = new JButton("Επεξεργασία");
        JButton btnDelete = new JButton("Διαγραφή");
        JButton btnRefresh = new JButton("Ανανέωση");

        btnAdd.setBackground(new Color(200, 255, 200));
        btnDelete.setBackground(new Color(255, 200, 200));

        buttonPanel.add(btnAdd);
        buttonPanel.add(btnEdit);
        buttonPanel.add(btnDelete);
        buttonPanel.add(btnRefresh);
        add(buttonPanel, BorderLayout.SOUTH);

        loadData();

        btnRefresh.addActionListener(e -> loadData());
        btnDelete.addActionListener(e -> deleteRecord());
        btnAdd.addActionListener(e -> showFormDialog(null));

        btnEdit.addActionListener(e -> {
            int selectedRow = table.getSelectedRow();
            if (selectedRow == -1) {
                JOptionPane.showMessageDialog(this, "Επιλέξτε μια γραμμή.");
                return;
            }
            Vector<Object> rowData = (Vector<Object>) model.getDataVector().elementAt(selectedRow);
            showFormDialog(rowData);
        });
    }

    private void loadData() {
        model.setRowCount(0);
        model.setColumnCount(0);
        try (Connection conn = DBConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT * FROM " + tableName)) {

            ResultSetMetaData metaData = rs.getMetaData();
            for (int i = 1; i <= metaData.getColumnCount(); i++) model.addColumn(metaData.getColumnName(i));
            while (rs.next()) {
                Vector<Object> row = new Vector<>();
                for (int i = 1; i <= metaData.getColumnCount(); i++) row.add(rs.getObject(i));
                model.addRow(row);
            }
        } catch (SQLException e) { JOptionPane.showMessageDialog(this, "Error: " + e.getMessage()); }
    }

    private void deleteRecord() {
        int selectedRow = table.getSelectedRow();
        if (selectedRow == -1) return;
        String idVal = table.getValueAt(selectedRow, 0).toString();
        String idCol = table.getColumnName(0);

        if (JOptionPane.showConfirmDialog(this, "Διαγραφή ID: " + idVal + ";", "Confirm", JOptionPane.YES_NO_OPTION) == JOptionPane.YES_OPTION) {
            try (Connection conn = DBConnection.getConnection(); Statement stmt = conn.createStatement()) {
                stmt.executeUpdate("DELETE FROM " + tableName + " WHERE " + idCol + " = '" + idVal + "'");
                loadData();
            } catch (SQLException e) { JOptionPane.showMessageDialog(this, "Error: " + e.getMessage()); }
        }
    }

    private JComboBox<ComboItem> getComboBoxForColumn(String colName) {
        String query = null;

        if (colName.equals("veh_br_code") || colName.equals("tr_br_code") || colName.equals("wrk_br_code") || colName.equals("mng_br_code")) {
            query = "SELECT br_code, br_city FROM branch";
        }
        else if (colName.equals("tr_veh_id")) {
            query = "SELECT veh_id, CONCAT(veh_brand, ' ', veh_model, ' (', veh_license_plate, ')') FROM vehicle WHERE veh_status='AVAILABLE'";
        }
        else if (colName.equals("tr_drv_AT")) {
            query = "SELECT d.drv_AT, CONCAT(w.wrk_name, ' ', w.wrk_lname) FROM driver d JOIN worker w ON d.drv_AT = w.wrk_AT";
        }
        else if (colName.equals("tr_gui_AT")) {
            query = "SELECT g.gui_AT, CONCAT(w.wrk_name, ' ', w.wrk_lname) FROM guide g JOIN worker w ON g.gui_AT = w.wrk_AT";
        }
        else if (colName.equals("acc_dst_id") || colName.equals("to_dst_id")) {
            query = "SELECT dst_id, dst_name FROM destination";
        }
        else if (colName.equals("veh_type")) {
            JComboBox<ComboItem> cb = new JComboBox<>();
            cb.addItem(new ComboItem("BUS", "BUS"));
            cb.addItem(new ComboItem("MINIBUS", "MINIBUS"));
            cb.addItem(new ComboItem("VAN", "VAN"));
            cb.addItem(new ComboItem("CAR", "CAR"));
            return cb;
        }

        if (query != null) {
            JComboBox<ComboItem> cb = new JComboBox<>();
            try (Connection conn = DBConnection.getConnection();
                 Statement stmt = conn.createStatement();
                 ResultSet rs = stmt.executeQuery(query)) {
                while (rs.next()) {
                    cb.addItem(new ComboItem(rs.getString(1), rs.getString(2)));
                }
            } catch (SQLException e) { e.printStackTrace(); }
            return cb;
        }
        return null;
    }

    private void showFormDialog(Vector<Object> existingData) {
        boolean isUpdate = (existingData != null);
        JDialog dialog = new JDialog(this, isUpdate ? "Επεξεργασία" : "Προσθήκη", true);
        dialog.setSize(450, 600);
        dialog.setLocationRelativeTo(this);

        JPanel panel = new JPanel(new GridLayout(0, 2, 10, 10));
        panel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        Map<String, JComponent> inputs = new HashMap<>();
        java.util.List<String> columnNames = new java.util.ArrayList<>();

        for (int i = 0; i < table.getColumnCount(); i++) {
            String colName = table.getColumnName(i);
            columnNames.add(colName);
            panel.add(new JLabel(colName + ":"));

            JComboBox<ComboItem> cb = getComboBoxForColumn(colName);
            JComponent inputField;

            if (cb != null) {
                inputField = cb;
                if (isUpdate) {
                    Object val = existingData.get(i);
                    String targetId = (val != null) ? val.toString() : null;

                    if (targetId != null) {
                        for (int k = 0; k < cb.getItemCount(); k++) {
                            if (cb.getItemAt(k).getKey().equals(targetId)) {
                                cb.setSelectedIndex(k);
                                break;
                            }
                        }
                    }
                }
            } else {
                JTextField tf = new JTextField();
                if (isUpdate) {
                    Object val = existingData.get(i);
                    tf.setText(val != null ? val.toString() : "");
                    if (i == 0) tf.setEditable(false);
                }
                inputField = tf;
            }

            inputs.put(colName, inputField);
            panel.add(inputField);
        }

        JButton btnSave = new JButton("Αποθήκευση");
        panel.add(new JLabel(""));
        panel.add(btnSave);

        btnSave.addActionListener(e -> {
            saveRecord(inputs, columnNames, isUpdate);
            dialog.dispose();
        });

        dialog.add(new JScrollPane(panel));
        dialog.setVisible(true);
    }

    private void saveRecord(Map<String, JComponent> inputs, java.util.List<String> columns, boolean isUpdate) {
        try (Connection conn = DBConnection.getConnection(); Statement stmt = conn.createStatement()) {
            StringBuilder sql = new StringBuilder();

            if (isUpdate) {
                sql.append("UPDATE ").append(tableName).append(" SET ");
                String idCol = columns.get(0);
                String idVal = ((JTextField) inputs.get(idCol)).getText();

                for (int i = 1; i < columns.size(); i++) {
                    String col = columns.get(i);
                    String val = getComponentValue(inputs.get(col));

                    sql.append(col).append("='").append(val).append("'");
                    if (i < columns.size() - 1) sql.append(", ");
                }
                sql.append(" WHERE ").append(idCol).append("='").append(idVal).append("'");
            } else {
                sql.append("INSERT INTO ").append(tableName).append(" (");
                boolean skipId = ((JTextField) inputs.get(columns.get(0))).getText().isEmpty();
                int start = skipId ? 1 : 0;

                for (int i = start; i < columns.size(); i++) {
                    sql.append(columns.get(i));
                    if (i < columns.size() - 1) sql.append(", ");
                }
                sql.append(") VALUES (");
                for (int i = start; i < columns.size(); i++) {
                    String val = getComponentValue(inputs.get(columns.get(i)));
                    sql.append("'").append(val).append("'");
                    if (i < columns.size() - 1) sql.append(", ");
                }
                sql.append(")");
            }
            stmt.executeUpdate(sql.toString());
            JOptionPane.showMessageDialog(this, "Αποθηκεύτηκε!");
            loadData();
        } catch (SQLException ex) { JOptionPane.showMessageDialog(this, "SQL Error: " + ex.getMessage()); }
    }

    private String getComponentValue(JComponent comp) {
        if (comp instanceof JTextField) {
            return ((JTextField) comp).getText();
        } else if (comp instanceof JComboBox) {
            ComboItem item = (ComboItem) ((JComboBox<?>) comp).getSelectedItem();
            return item != null ? item.getKey() : "";
        }
        return "";
    }
}
