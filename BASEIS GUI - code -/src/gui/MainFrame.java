package gui;

import javax.swing.*;
import java.awt.*;

public class MainFrame extends JFrame {

    public MainFrame() {
        setTitle("Travel Agency Manager - Dashboard");
        setSize(650, 550);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLocationRelativeTo(null);
        setLayout(new BorderLayout());

        JLabel titleLabel = new JLabel("Διαχείριση Ταξιδιωτικού Γραφείου", SwingConstants.CENTER);
        titleLabel.setFont(new Font("Arial", Font.BOLD, 24));
        titleLabel.setBorder(BorderFactory.createEmptyBorder(20, 10, 20, 10));
        add(titleLabel, BorderLayout.NORTH);

        JPanel buttonPanel = new JPanel();
        buttonPanel.setLayout(new GridLayout(0, 2, 15, 15));
        buttonPanel.setBorder(BorderFactory.createEmptyBorder(20, 40, 20, 40));

        addButton(buttonPanel, "Διαχείριση Πελατών", "customer");
        addButton(buttonPanel, "Διαχείριση Ταξιδιών", "trip");
        addButton(buttonPanel, "Διαχείριση Οχημάτων", "vehicle");
        addButton(buttonPanel, "Διαχείριση Καταλυμάτων", "accommodation");
        addButton(buttonPanel, "Διαχείριση Κρατήσεων", "reservation");
        addButton(buttonPanel, "Διαχείριση Οδηγών", "driver");
        addButton(buttonPanel, "Διαχείριση Ξεναγών", "guide");
        addButton(buttonPanel, "Διαχείριση Υποκαταστημάτων", "branch");

        JButton btnBonus = new JButton("Επισκόπηση Ταξιδιού (Bonus)");
        btnBonus.setFont(new Font("Arial", Font.BOLD, 14));
        btnBonus.setBackground(new Color(255, 215, 0));
        btnBonus.addActionListener(e -> new TripDetailsFrame().setVisible(true));
        buttonPanel.add(btnBonus);

        add(new JScrollPane(buttonPanel), BorderLayout.CENTER);

        JButton exitBtn = new JButton("Έξοδος");
        exitBtn.setBackground(Color.RED);
        exitBtn.setForeground(Color.WHITE);
        exitBtn.setFont(new Font("Arial", Font.BOLD, 14));
        exitBtn.addActionListener(e -> System.exit(0));

        JPanel bottomPanel = new JPanel();
        bottomPanel.setBorder(BorderFactory.createEmptyBorder(10, 0, 10, 0));
        bottomPanel.add(exitBtn);
        add(bottomPanel, BorderLayout.SOUTH);
    }

    private void addButton(JPanel panel, String label, String tableName) {
        JButton btn = new JButton(label);
        btn.setFont(new Font("Arial", Font.PLAIN, 14));
        btn.addActionListener(e -> new TableManagerFrame(tableName).setVisible(true));
        panel.add(btn);
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> new MainFrame().setVisible(true));
    }
}