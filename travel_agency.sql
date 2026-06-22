-- =====================================================================
--  Travel Agency Management System — Full Database Schema
--  Database Systems Laboratory 2025-2026
--  Run order: tables -> seed data -> procedures -> indexes -> triggers
--  Usage:  mysql -u <user> -p < schema.sql
--      or: open in MySQL Workbench and execute the whole script.
-- =====================================================================

DROP DATABASE IF EXISTS travel_agency;
CREATE DATABASE travel_agency DEFAULT CHARACTER SET utf8mb4;
USE travel_agency;

-- =====================================================================
--  SECTION 1: TABLES
-- =====================================================================

CREATE TABLE language_ref (
    lang_code VARCHAR(5) NOT NULL,
    lang_name VARCHAR(50) NOT NULL,
    PRIMARY KEY (lang_code)
);

CREATE TABLE branch (
    br_code INT NOT NULL,
    br_street VARCHAR(50),
    br_num INT,
    br_city VARCHAR(30),
    br_manager_AT CHAR(10),
    PRIMARY KEY (br_code)
);

CREATE TABLE phones (
    ph_br_code INT NOT NULL,
    ph_number VARCHAR(15) NOT NULL,
    PRIMARY KEY (ph_br_code, ph_number),
    FOREIGN KEY (ph_br_code) REFERENCES branch(br_code) ON DELETE CASCADE
);

CREATE TABLE worker (
    wrk_AT CHAR(10) NOT NULL,
    wrk_name VARCHAR(30) NOT NULL,
    wrk_lname VARCHAR(30) NOT NULL,
    wrk_email VARCHAR(100),
    wrk_salary DECIMAL(10,2),
    wrk_br_code INT,
    PRIMARY KEY (wrk_AT),
    FOREIGN KEY (wrk_br_code) REFERENCES branch(br_code) ON DELETE SET NULL
);

CREATE TABLE admin (
    adm_AT CHAR(10) NOT NULL,
    adm_type ENUM('LOGISTICS', 'ADMINISTRATIVE', 'ACCOUNTING') NOT NULL,
    adm_diploma VARCHAR(200),
    PRIMARY KEY (adm_AT),
    FOREIGN KEY (adm_AT) REFERENCES worker(wrk_AT) ON DELETE CASCADE
);

-- Resolve the circular reference branch <-> admin now that admin exists.
ALTER TABLE branch
    ADD CONSTRAINT fk_branch_manager
    FOREIGN KEY (br_manager_AT) REFERENCES admin(adm_AT) ON DELETE SET NULL;

CREATE TABLE driver (
    drv_AT CHAR(10) NOT NULL,
    drv_license ENUM('A', 'B', 'C', 'D') NOT NULL,
    drv_route ENUM('LOCAL', 'ABROAD') NOT NULL,
    drv_experience TINYINT,
    PRIMARY KEY (drv_AT),
    FOREIGN KEY (drv_AT) REFERENCES worker(wrk_AT) ON DELETE CASCADE
);

CREATE TABLE guide (
    gui_AT CHAR(10) NOT NULL,
    gui_cv TEXT,
    PRIMARY KEY (gui_AT),
    FOREIGN KEY (gui_AT) REFERENCES worker(wrk_AT) ON DELETE CASCADE
);

CREATE TABLE languages (
    lng_gui_AT CHAR(10) NOT NULL,
    lng_language_code VARCHAR(5) NOT NULL,
    PRIMARY KEY (lng_gui_AT, lng_language_code),
    FOREIGN KEY (lng_gui_AT) REFERENCES guide(gui_AT) ON DELETE CASCADE,
    FOREIGN KEY (lng_language_code) REFERENCES language_ref(lang_code) ON DELETE CASCADE
);

CREATE TABLE manages (
    mng_adm_AT CHAR(10) NOT NULL,
    mng_br_code INT NOT NULL,
    PRIMARY KEY (mng_adm_AT, mng_br_code),
    FOREIGN KEY (mng_adm_AT) REFERENCES admin(adm_AT) ON DELETE CASCADE,
    FOREIGN KEY (mng_br_code) REFERENCES branch(br_code) ON DELETE CASCADE
);

CREATE TABLE customer (
    cust_id INT NOT NULL AUTO_INCREMENT,
    cust_name VARCHAR(30) NOT NULL,
    cust_lname VARCHAR(30) NOT NULL,
    cust_email VARCHAR(100),
    cust_phone VARCHAR(15),
    cust_address TEXT,
    cust_birth_date DATE,
    PRIMARY KEY (cust_id)
);

CREATE TABLE destination (
    dst_id INT NOT NULL AUTO_INCREMENT,
    dst_name VARCHAR(100) NOT NULL,
    dst_descr TEXT,
    dst_rtype ENUM('LOCAL', 'ABROAD') NOT NULL,
    dst_language_code VARCHAR(5),
    dst_location INT,
    PRIMARY KEY (dst_id),
    FOREIGN KEY (dst_language_code) REFERENCES language_ref(lang_code) ON DELETE SET NULL,
    FOREIGN KEY (dst_location) REFERENCES destination(dst_id) ON DELETE SET NULL
);

CREATE TABLE trip (
    tr_id INT NOT NULL AUTO_INCREMENT,
    tr_departure DATETIME NOT NULL,
    tr_return DATETIME NOT NULL,
    tr_maxseats TINYINT NOT NULL,
    tr_cost_adult DECIMAL(10,2) NOT NULL,
    tr_cost_child DECIMAL(10,2) NOT NULL,
    tr_status ENUM('PLANNED', 'CONFIRMED', 'ACTIVE', 'COMPLETED', 'CANCELLED') NOT NULL,
    tr_min_participants TINYINT,
    tr_br_code INT,
    tr_gui_AT CHAR(10),
    tr_drv_AT CHAR(10),
    PRIMARY KEY (tr_id),
    FOREIGN KEY (tr_br_code) REFERENCES branch(br_code) ON DELETE CASCADE,
    FOREIGN KEY (tr_gui_AT) REFERENCES guide(gui_AT) ON DELETE SET NULL,
    FOREIGN KEY (tr_drv_AT) REFERENCES driver(drv_AT) ON DELETE SET NULL
);

CREATE TABLE travel_to (
    to_tr_id INT NOT NULL,
    to_dst_id INT NOT NULL,
    to_arrival DATETIME,
    to_departure DATETIME,
    to_sequence TINYINT,
    PRIMARY KEY (to_tr_id, to_dst_id),
    FOREIGN KEY (to_tr_id) REFERENCES trip(tr_id) ON DELETE CASCADE,
    FOREIGN KEY (to_dst_id) REFERENCES destination(dst_id) ON DELETE CASCADE
);

CREATE TABLE event (
    ev_tr_id INT NOT NULL,
    ev_start DATETIME NOT NULL,
    ev_end DATETIME NOT NULL,
    ev_descr TEXT,
    PRIMARY KEY (ev_tr_id, ev_start),
    FOREIGN KEY (ev_tr_id) REFERENCES trip(tr_id) ON DELETE CASCADE
);

CREATE TABLE reservation (
    res_tr_id INT NOT NULL,
    res_seatnum TINYINT NOT NULL,
    res_cust_id INT NOT NULL,
    res_status ENUM('PENDING', 'CONFIRMED', 'PAID', 'CANCELLED') DEFAULT 'PENDING',
    res_total_cost DECIMAL(10,2),
    PRIMARY KEY (res_tr_id, res_seatnum),
    FOREIGN KEY (res_tr_id) REFERENCES trip(tr_id) ON DELETE CASCADE,
    FOREIGN KEY (res_cust_id) REFERENCES customer(cust_id) ON DELETE CASCADE
);

CREATE TABLE vehicle (
    veh_id INT NOT NULL AUTO_INCREMENT,
    veh_license_plate VARCHAR(10) NOT NULL UNIQUE,
    veh_brand VARCHAR(20) NOT NULL,
    veh_model VARCHAR(20) NOT NULL,
    veh_seats TINYINT NOT NULL,
    veh_type ENUM('BUS', 'MINIBUS', 'VAN', 'CAR') NOT NULL,
    veh_status ENUM('AVAILABLE', 'IN_USE', 'MAINTENANCE') DEFAULT 'AVAILABLE',
    veh_km INT DEFAULT 0,
    veh_br_code INT,
    PRIMARY KEY (veh_id),
    FOREIGN KEY (veh_br_code) REFERENCES branch(br_code) ON DELETE SET NULL
);

-- Extend trip with the vehicle-assignment fields (Requirement 3.1.2.1).
ALTER TABLE trip
    ADD COLUMN tr_veh_id INT,
    ADD COLUMN tr_start_km INT,
    ADD CONSTRAINT fk_trip_vehicle FOREIGN KEY (tr_veh_id) REFERENCES vehicle(veh_id) ON DELETE SET NULL;

CREATE TABLE amenity (
    am_id INT NOT NULL AUTO_INCREMENT,
    am_name VARCHAR(50) NOT NULL,
    PRIMARY KEY (am_id)
);

CREATE TABLE accommodation (
    acc_id INT NOT NULL AUTO_INCREMENT,
    acc_name VARCHAR(100) NOT NULL,
    acc_dst_id INT NOT NULL,
    acc_type ENUM('HOTEL', 'HOSTEL', 'RESORT', 'APARTMENT', 'ROOMS') NOT NULL,
    acc_stars TINYINT DEFAULT NULL,
    acc_rating DECIMAL(3,2) DEFAULT 0.00,
    acc_total_rooms INT NOT NULL,
    acc_price_per_night DECIMAL(10,2) NOT NULL,
    acc_status ENUM('ACTIVE', 'INACTIVE') DEFAULT 'ACTIVE',
    acc_street VARCHAR(50),
    acc_number VARCHAR(10),
    acc_city VARCHAR(50),
    acc_zip_code VARCHAR(10),
    acc_phone VARCHAR(15),
    acc_email VARCHAR(100),
    PRIMARY KEY (acc_id),
    FOREIGN KEY (acc_dst_id) REFERENCES destination(dst_id) ON DELETE CASCADE,
    CONSTRAINT chk_stars  CHECK (acc_stars IS NULL OR (acc_stars BETWEEN 1 AND 5)),
    CONSTRAINT chk_rating CHECK (acc_rating BETWEEN 0.00 AND 5.00)
);

CREATE TABLE accommodation_amenity (
    aa_acc_id INT NOT NULL,
    aa_am_id INT NOT NULL,
    PRIMARY KEY (aa_acc_id, aa_am_id),
    FOREIGN KEY (aa_acc_id) REFERENCES accommodation(acc_id) ON DELETE CASCADE,
    FOREIGN KEY (aa_am_id) REFERENCES amenity(am_id) ON DELETE CASCADE
);

CREATE TABLE trip_accommodation (
    ta_tr_id INT NOT NULL,
    ta_acc_id INT NOT NULL,
    ta_checkin DATETIME NOT NULL,
    ta_checkout DATETIME NOT NULL,
    ta_rooms_booked TINYINT NOT NULL,
    ta_nights TINYINT,
    ta_cost DECIMAL(10,2),
    PRIMARY KEY (ta_tr_id, ta_acc_id),
    FOREIGN KEY (ta_tr_id) REFERENCES trip(tr_id) ON DELETE CASCADE,
    FOREIGN KEY (ta_acc_id) REFERENCES accommodation(acc_id) ON DELETE CASCADE
);

CREATE TABLE trip_history (
    log_id INT NOT NULL AUTO_INCREMENT,
    log_trip_id INT,
    log_departure DATETIME,
    log_return DATETIME,
    log_dest_count INT,
    log_participants INT,
    log_revenue DECIMAL(10,2),
    PRIMARY KEY (log_id)
);

CREATE TABLE IT_manager (
    it_AT CHAR(10) NOT NULL,
    it_start_date DATE NOT NULL,
    it_end_date DATE,
    PRIMARY KEY (it_AT),
    FOREIGN KEY (it_AT) REFERENCES worker(wrk_AT) ON DELETE CASCADE
);

CREATE TABLE log (
    log_id INT NOT NULL AUTO_INCREMENT,
    log_user VARCHAR(50) NOT NULL,
    log_date DATE NOT NULL,
    log_time TIME NOT NULL,
    log_action ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    log_table VARCHAR(50) NOT NULL,
    PRIMARY KEY (log_id)
);

-- =====================================================================
--  SECTION 2: SEED DATA
-- =====================================================================

INSERT INTO language_ref VALUES ('EL','Greek'),('EN','English'),('FR','French'),('DE','German'),('IT','Italian'),('ES','Spanish'),('RU','Russian'),('CN','Chinese'),('AR','Arabic');

INSERT INTO branch (br_code, br_street, br_num, br_city) VALUES
(1, 'Ermou', 12, 'Athens'), (2, 'Tsimiski', 45, 'Thessaloniki'), (3, 'Maizonos', 10, 'Patra'),
(4, 'Knossou', 5, 'Heraklion'), (5, 'Oxford St', 100, 'London'), (6, 'Champs Elysees', 20, 'Paris'),
(7, 'Via del Corso', 15, 'Rome'), (8, 'Alexanderplatz', 1, 'Berlin'), (9, 'La Rambla', 8, 'Barcelona');

INSERT INTO phones VALUES (1,'2101234567'),(1,'2107654321'),(2,'2310123456'),(2,'2310654321'),(3,'2610123456'),(4,'2810123456'),(5,'+4420123456'),(5,'+4420654321'),(6,'+331123456'),(7,'+3906123456'),(7,'+3906654321'),(8,'+4930123456'),(9,'+3493123456'),(3,'2610987654'),(4,'2810987654');

INSERT INTO worker VALUES
('AT101','Nikos','Papadopoulos','nikos@trave.gr',1500,1), ('AT102','Maria','Georgiou','maria@trave.gr',1400,2),
('AT103','Giorgos','Dimitriou','giorgos@trave.gr',1350,3), ('AT104','Eleni','Nikolaou','eleni@trave.gr',1300,4),
('AT105','John','Smith','john@trave.com',2000,5), ('AT106','Jean','Dupont','jean@trave.fr',1900,6),
('AT107','Paolo','Rossi','paolo@trave.it',1850,7), ('AT108','Hans','Muller','hans@trave.de',1950,8),
('AT109','Carlos','Garcia','carlos@trave.es',1800,9), ('AT110','Anna','Karakosta','anna@trave.gr',1100,1),
('AT111','Kostas','Makris','kostas@trave.gr',1150,2), ('AT112','Sofia','Lymperi','sofia@trave.gr',1200,1),
('AT113','Dimitris','Raptis','dimitris@trave.gr',1250,3), ('AT114','Katerina','Steriou','kat@trave.gr',1100,4),
('AT115','Elena','Vougiouklaki','elena@trave.gr',1300,1),
('DRV01','Spyros','Kouros','spyros@trave.gr',1000,1), ('DRV02','Takis','Fotopoulos','takis@trave.gr',950,2),
('DRV03','Makis','Dimas','makis@trave.gr',980,3), ('DRV04','Giannis','Lagos','giannis@trave.gr',900,4),
('DRV05','Tom','Baker','tom@trave.com',1200,5), ('DRV06','Pierre','Martin','pierre@trave.fr',1150,6),
('DRV07','Luigi','Bianchi','luigi@trave.it',1100,7), ('DRV08','Klaus','Weber','klaus@trave.de',1250,8),
('DRV09','Jose','Fernandez','jose@trave.es',1180,9), ('DRV10','Vasilis','Karras','vasilis@trave.gr',1050,1),
('DRV11','Petros','Filipidis','petros@trave.gr',1020,2), ('DRV12','Babis','Stokas','babis@trave.gr',1080,3),
('GUI01','Marina','Satti','marina@trave.gr',1100,1), ('GUI02','Doretta','Papadimitriou','doretta@trave.gr',1050,2),
('GUI03','Sakis','Rouvas','sakis@trave.gr',1200,3), ('GUI04','Helena','Paparizou','helena@trave.gr',1150,4),
('GUI05','Emma','Watson','emma@trave.com',1400,5), ('GUI06','Sophie','Marceau','sophie@trave.fr',1350,6),
('GUI07','Monica','Bellucci','monica@trave.it',1450,7), ('GUI08','Heidi','Klum','heidi@trave.de',1500,8),
('GUI09','Penelope','Cruz','penelope@trave.es',1380,9), ('GUI10','Alkistis','Protopsalti','alkistis@trave.gr',1250,1),
('GUI11','Natassa','Bofiliou','natassa@trave.gr',1220,2), ('GUI12','Haris','Alexiou','haris@trave.gr',1300,3);

INSERT INTO admin VALUES
('AT101','ADMINISTRATIVE','MBA'), ('AT102','LOGISTICS','BSc Econ'), ('AT103','ACCOUNTING','MSc Finance'),
('AT104','ADMINISTRATIVE','PhD Mgmt'), ('AT105','LOGISTICS','MSc Logistics'), ('AT106','ACCOUNTING','CPA'),
('AT107','ADMINISTRATIVE','MBA'), ('AT108','LOGISTICS','BSc'), ('AT109','ACCOUNTING','MSc'),
('AT110','ADMINISTRATIVE','BSc'), ('AT111','LOGISTICS','MSc'), ('AT112','ACCOUNTING','PhD'),
('AT113','ADMINISTRATIVE','MBA'), ('AT114','LOGISTICS','BSc'), ('AT115','ACCOUNTING','MSc');

INSERT INTO driver VALUES
('DRV01','D','ABROAD',10), ('DRV02','C','LOCAL',5), ('DRV03','D','ABROAD',15), ('DRV04','B','LOCAL',3),
('DRV05','D','ABROAD',12), ('DRV06','D','ABROAD',8), ('DRV07','C','LOCAL',6), ('DRV08','D','ABROAD',20),
('DRV09','B','LOCAL',4), ('DRV10','C','LOCAL',7), ('DRV11','D','ABROAD',9), ('DRV12','B','LOCAL',2);

INSERT INTO guide VALUES
('GUI01','History Expert'), ('GUI02','Art Specialist'), ('GUI03','Music Tours'), ('GUI04','Food Expert'),
('GUI05','Harry Potter Tours'), ('GUI06','Museum Expert'), ('GUI07','Architecture'), ('GUI08','Nature Tours'),
('GUI09','City Walks'), ('GUI10','Ancient Greece'), ('GUI11','Modern Art'), ('GUI12','Folklore');

INSERT INTO languages VALUES ('GUI01','EN'),('GUI02','FR'),('GUI03','DE'),('GUI04','IT'),('GUI05','EN'),('GUI06','FR'),('GUI07','IT'),('GUI08','DE'),('GUI09','ES'),('GUI10','EL'),('GUI11','EL'),('GUI12','EN');

UPDATE branch SET br_manager_AT='AT101' WHERE br_code=1; UPDATE branch SET br_manager_AT='AT102' WHERE br_code=2;
UPDATE branch SET br_manager_AT='AT103' WHERE br_code=3; UPDATE branch SET br_manager_AT='AT104' WHERE br_code=4;
UPDATE branch SET br_manager_AT='AT105' WHERE br_code=5; UPDATE branch SET br_manager_AT='AT106' WHERE br_code=6;
UPDATE branch SET br_manager_AT='AT107' WHERE br_code=7; UPDATE branch SET br_manager_AT='AT108' WHERE br_code=8;
UPDATE branch SET br_manager_AT='AT109' WHERE br_code=9;

INSERT INTO manages VALUES ('AT101',1),('AT102',2),('AT103',3),('AT104',4),('AT105',5),('AT106',6),('AT107',7),('AT108',8),('AT109',9);

INSERT INTO destination (dst_id, dst_name, dst_descr, dst_rtype, dst_language_code, dst_location) VALUES
(1,'Greece','Country','LOCAL','EL',NULL), (2,'Italy','Country','ABROAD','IT',NULL),
(3,'France','Country','ABROAD','FR',NULL), (4,'Germany','Country','ABROAD','DE',NULL), (5,'UK','Country','ABROAD','EN',NULL),
(6,'Athens','Capital','LOCAL','EL',1), (7,'Thessaloniki','City','LOCAL','EL',1), (8,'Rome','City','ABROAD','IT',2),
(9,'Milan','City','ABROAD','IT',2), (10,'Paris','City','ABROAD','FR',3), (11,'Lyon','City','ABROAD','FR',3),
(12,'Berlin','City','ABROAD','DE',4), (13,'Munich','City','ABROAD','DE',4), (14,'London','City','ABROAD','EN',5), (15,'Manchester','City','ABROAD','EN',5);

INSERT INTO customer (cust_name, cust_lname, cust_email, cust_phone, cust_address, cust_birth_date) VALUES
('Giannis','Antetokounmpo','giannis@nba.com','6900000001','Sepolia','1994-12-06'),
('Thanasis','Antetokounmpo','thanasis@nba.com','6900000002','Sepolia','1992-07-18'),
('Kostas','Sloukas','sloukas@pao.gr','6900000003','Oaka','1990-01-15'),
('Vasilis','Spanoulis','span@coach.gr','6900000004','Pireas','1982-08-07'),
('Nikos','Galis','galis@hof.gr','6900000005','Thessaloniki','1957-07-23'),
('Dimitris','Diamantidis','3d@pao.gr','6900000006','Kastoria','1980-05-06'),
('Giorgos','Printezis','print@oly.gr','6900000007','Syros','1985-02-22'),
('Maria','Sakkari','maria@tennis.gr','6900000008','Athens','1995-07-25'),
('Stefanos','Tsitsipas','stef@tennis.gr','6900000009','Athens','1998-08-12'),
('Miltos','Tentoglou','miltos@jump.gr','6900000010','Grevena','1998-03-18'),
('Katerina','Stefanidi','kat@pole.gr','6900000011','Athens','1990-02-04'),
('Lefteris','Petrounias','lefteris@rings.gr','6900000012','Athens','1990-11-30'),
('Anna','Korakaki','anna@shoot.gr','6900000013','Drama','1996-04-08'),
('Pyrros','Dimas','pyrros@weight.gr','6900000014','Himara','1971-10-13'),
('Voula','Patoulidou','voula@run.gr','6900000015','Florina','1965-04-03'),
('Ioannis','Melissanidis','ioannis@floor.gr','6900000016','Thessaloniki','1977-03-27'),
('Dimosthenis','Tampakos','dimos@rings.gr','6900000017','Thessaloniki','1976-11-12'),
('Ilias','Iliadis','ilias@judo.gr','6900000018','Athens','1986-11-10'),
('Sofia','Bekatorou','sofia@sailing.gr','6900000019','Athens','1977-12-26'),
('Daddy','Tsoulfas','daddytsoul@sailing.gr','6900000020','Athens','2001-05-15'),
('Thomas','Bimis','thomas@dive.gr','6900000021','Athens','1975-06-11'),
('Nikos','Syranidis','nikos@dive.gr','6900000022','Athens','1976-02-26'),
('Fani','Halkia','fani@hurdle.gr','6900000023','Larissa','1979-02-02'),
('Athanasia','Tsoumeleka','athanasia@walk.gr','6900000024','Preveza','1982-01-02'),
('Pigi','Devetzi','pigi@jump.gr','6900000025','Alexandroupoli','1976-01-02'),
('Mirela','Manjani','mirela@javelin.gr','6900000026','Athens','1976-12-21'),
('Niki','Xanthou','niki@long.gr','6900000027','Rhodes','1973-10-11'),
('Periklis','Iakovakis','periklis@hurdle.gr','6900000028','Patra','1979-03-24'),
('Voula','Kozompoli','voula@polo.gr','6900000029','Athens','1974-01-14'),
('Antigoni','Roupbi','antigoni@polo.gr','6900000030','Athens','1978-07-29');

INSERT INTO vehicle (veh_license_plate, veh_brand, veh_model, veh_seats, veh_type, veh_status, veh_km, veh_br_code) VALUES
('ABC-1234', 'Mercedes', 'Tourismo', 50, 'BUS', 'AVAILABLE', 150000, 1),
('BCA-5678', 'Volvo', '9700', 52, 'BUS', 'AVAILABLE', 120000, 1),
('XYZ-9876', 'Mercedes', 'Sprinter', 18, 'MINIBUS', 'AVAILABLE', 80000, 2),
('ZXY-5432', 'Ford', 'Transit', 15, 'MINIBUS', 'MAINTENANCE', 95000, 2),
('QWE-1111', 'Volkswagen', 'Transporter', 9, 'VAN', 'AVAILABLE', 45000, 3),
('ASD-2222', 'Mercedes', 'Vito', 8, 'VAN', 'IN_USE', 30000, 4),
('ZXC-3333', 'Toyota', 'Corolla', 5, 'CAR', 'AVAILABLE', 15000, 5),
('RTY-4444', 'Peugeot', '3008', 5, 'CAR', 'AVAILABLE', 12000, 6),
('FGH-5555', 'Setra', 'S515', 55, 'BUS', 'AVAILABLE', 200000, 7),
('VBN-6666', 'Fiat', 'Ducato', 9, 'VAN', 'AVAILABLE', 50000, 8);

INSERT INTO trip (tr_departure, tr_return, tr_maxseats, tr_cost_adult, tr_cost_child, tr_status, tr_min_participants, tr_br_code, tr_gui_AT, tr_drv_AT) VALUES
('2024-06-01 08:00:00', '2024-06-05 20:00:00', 50, 500.00, 250.00, 'CONFIRMED', 10, 1, 'GUI01', 'DRV01'),
('2024-07-10 09:00:00', '2024-07-15 18:00:00', 40, 600.00, 300.00, 'PLANNED', 15, 2, 'GUI02', 'DRV02'),
('2024-08-20 07:00:00', '2024-08-25 22:00:00', 45, 450.00, 225.00, 'COMPLETED', 20, 3, 'GUI03', 'DRV03'),
('2024-09-05 10:00:00', '2024-09-10 15:00:00', 30, 800.00, 400.00, 'ACTIVE', 5, 4, 'GUI04', 'DRV04'),
('2024-10-01 08:00:00', '2024-10-04 20:00:00', 50, 300.00, 150.00, 'CANCELLED', 10, 5, 'GUI05', 'DRV05'),
('2024-11-15 09:00:00', '2024-11-20 18:00:00', 55, 700.00, 350.00, 'CONFIRMED', 12, 6, 'GUI06', 'DRV06'),
('2024-12-22 07:00:00', '2024-12-27 22:00:00', 40, 900.00, 450.00, 'PLANNED', 15, 7, 'GUI07', 'DRV07'),
('2025-01-05 10:00:00', '2025-01-10 15:00:00', 35, 550.00, 275.00, 'CONFIRMED', 8, 8, 'GUI08', 'DRV08'),
('2025-02-14 08:00:00', '2025-02-18 20:00:00', 45, 650.00, 325.00, 'PLANNED', 10, 9, 'GUI09', 'DRV09'),
('2025-03-25 09:00:00', '2025-03-30 18:00:00', 50, 400.00, 200.00, 'CONFIRMED', 20, 1, 'GUI10', 'DRV10'),
('2025-04-10 07:00:00', '2025-04-15 22:00:00', 42, 750.00, 375.00, 'PLANNED', 12, 2, 'GUI11', 'DRV11'),
('2025-05-01 10:00:00', '2025-05-05 15:00:00', 38, 500.00, 250.00, 'CONFIRMED', 15, 3, 'GUI12', 'DRV12'),
('2025-06-15 08:00:00', '2025-06-20 20:00:00', 48, 850.00, 425.00, 'PLANNED', 10, 4, 'GUI01', 'DRV01'),
('2025-07-20 09:00:00', '2025-07-25 18:00:00', 52, 600.00, 300.00, 'CONFIRMED', 18, 5, 'GUI02', 'DRV02'),
('2025-08-15 07:00:00', '2025-08-20 22:00:00', 44, 450.00, 225.00, 'PLANNED', 20, 6, 'GUI03', 'DRV03'),
('2025-09-10 10:00:00', '2025-09-15 15:00:00', 36, 950.00, 475.00, 'CONFIRMED', 10, 7, 'GUI04', 'DRV04'),
('2025-10-28 08:00:00', '2025-11-01 20:00:00', 50, 350.00, 175.00, 'PLANNED', 15, 8, 'GUI05', 'DRV05'),
('2025-11-20 09:00:00', '2025-11-25 18:00:00', 40, 700.00, 350.00, 'CONFIRMED', 12, 9, 'GUI06', 'DRV06'),
('2025-12-24 07:00:00', '2025-12-29 22:00:00', 46, 1000.00, 500.00, 'PLANNED', 10, 1, 'GUI07', 'DRV07'),
('2026-01-02 10:00:00', '2026-01-07 15:00:00', 34, 550.00, 275.00, 'CONFIRMED', 14, 2, 'GUI08', 'DRV08'),
('2026-02-14 08:00:00', '2026-02-18 20:00:00', 45, 650.00, 325.00, 'PLANNED', 10, 3, 'GUI09', 'DRV09');

INSERT INTO travel_to (to_tr_id, to_dst_id, to_arrival, to_departure, to_sequence) VALUES
(1, 6, '2024-06-01 08:00:00', '2024-06-05 20:00:00', 1), (2, 7, '2024-07-10 09:00:00', '2024-07-15 18:00:00', 1),
(3, 8, '2024-08-20 10:00:00', '2024-08-22 10:00:00', 1), (4, 10, '2024-09-05 12:00:00', '2024-09-10 15:00:00', 1),
(5, 14, '2024-10-01 10:00:00', '2024-10-04 20:00:00', 1), (6, 12, '2024-11-15 11:00:00', '2024-11-20 18:00:00', 1),
(7, 9, '2024-12-22 09:00:00', '2024-12-27 22:00:00', 1), (8, 13, '2025-01-05 12:00:00', '2025-01-10 15:00:00', 1),
(9, 15, '2025-02-14 10:00:00', '2025-02-18 20:00:00', 1), (10, 6, '2025-03-25 09:00:00', '2025-03-30 18:00:00', 1),
(11, 7, '2025-04-10 07:00:00', '2025-04-15 22:00:00', 1), (12, 11, '2025-05-01 12:00:00', '2025-05-05 15:00:00', 1),
(13, 14, '2025-06-15 10:00:00', '2025-06-20 20:00:00', 1), (14, 10, '2025-07-20 11:00:00', '2025-07-25 18:00:00', 1),
(15, 8, '2025-08-15 09:00:00', '2025-08-20 22:00:00', 1), (16, 12, '2025-09-10 12:00:00', '2025-09-15 15:00:00', 1),
(17, 6, '2025-10-28 08:00:00', '2025-11-01 20:00:00', 1), (18, 9, '2025-11-20 11:00:00', '2025-11-25 18:00:00', 1),
(19, 14, '2025-12-24 09:00:00', '2025-12-29 22:00:00', 1), (20, 13, '2026-01-02 12:00:00', '2026-01-07 15:00:00', 1),
(21, 15, '2026-02-14 10:00:00', '2026-02-18 20:00:00', 1);

INSERT INTO event (ev_tr_id, ev_start, ev_end, ev_descr) VALUES
(1,'2024-06-02 10:00:00','2024-06-02 12:00:00','Acropolis'),(1,'2024-06-03 20:00:00','2024-06-03 23:00:00','Plaka Dinner'),
(2,'2024-07-11 10:00:00','2024-07-11 13:00:00','White Tower'),(3,'2024-08-21 09:00:00','2024-08-21 12:00:00','Vatican'),
(4,'2024-09-06 10:00:00','2024-09-06 14:00:00','Louvre'),(4,'2024-09-07 19:00:00','2024-09-07 22:00:00','Seine Cruise'),
(5,'2024-10-02 11:00:00','2024-10-02 13:00:00','British Museum'),(6,'2024-11-16 10:00:00','2024-11-16 12:00:00','Brandenburg'),
(7,'2024-12-23 09:00:00','2024-12-23 18:00:00','Duomo'),(8,'2025-01-06 18:00:00','2025-01-06 23:00:00','Beer Hall'),
(9,'2025-02-15 15:00:00','2025-02-15 17:00:00','Old Trafford'),(10,'2025-03-26 10:00:00','2025-03-26 12:00:00','Parliament'),
(11,'2025-04-11 11:00:00','2025-04-11 14:00:00','Archeological Museum'),(12,'2025-05-02 12:00:00','2025-05-02 15:00:00','Food Tour'),
(13,'2025-06-16 10:00:00','2025-06-16 12:00:00','Buckingham'),(14,'2025-07-21 09:00:00','2025-07-21 12:00:00','Eiffel'),
(15,'2025-08-16 10:00:00','2025-08-16 13:00:00','Colosseum'),(16,'2025-09-11 11:00:00','2025-09-11 14:00:00','Reichstag'),
(17,'2025-10-29 10:00:00','2025-10-29 12:00:00','National Garden'),(18,'2025-11-21 09:00:00','2025-11-21 18:00:00','Fashion District'),
(19,'2025-12-25 12:00:00','2025-12-25 15:00:00','Christmas Lunch'),(20,'2026-01-03 18:00:00','2026-01-03 22:00:00','Bavarian Night'),
(21,'2026-02-15 15:00:00','2026-02-15 17:00:00','Stadium'),(1,'2024-06-04 10:00:00','2024-06-04 13:00:00','Cape Sounio'),
(2,'2024-07-12 19:00:00','2024-07-12 22:00:00','Ladadika'),(3,'2024-08-23 10:00:00','2024-08-23 13:00:00','Trevi'),
(4,'2024-09-08 10:00:00','2024-09-08 12:00:00','Notre Dame'),(5,'2024-10-03 15:00:00','2024-10-03 17:00:00','Hyde Park'),
(13,'2025-06-17 19:00:00','2025-06-17 21:00:00','West End'),(14,'2025-07-22 20:00:00','2025-07-22 23:00:00','Moulin Rouge');

INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status, res_total_cost) VALUES
(1,1,1,'PAID',500),(1,2,2,'PAID',500),(1,3,3,'CONFIRMED',500),(2,1,4,'PAID',600),(2,2,5,'PENDING',600),
(3,1,6,'PAID',450),(3,2,7,'PAID',450),(3,3,8,'CANCELLED',0),(4,1,9,'PAID',800),(6,1,10,'CONFIRMED',700),
(6,2,11,'CONFIRMED',700),(7,1,12,'PAID',900),(8,1,13,'PAID',550),(8,2,14,'PENDING',550),(10,1,15,'PAID',400),
(12,1,16,'CONFIRMED',500),(12,2,17,'PAID',500),(13,1,18,'PENDING',850),(14,1,19,'PAID',600),(14,2,20,'PAID',600),
(14,3,21,'CONFIRMED',600),(15,1,22,'PAID',450),(16,1,23,'CANCELLED',0),(18,1,24,'PAID',700),(18,2,25,'PAID',700),
(19,1,26,'PAID',1000),(20,1,27,'PENDING',550),(21,1,28,'CONFIRMED',650),(21,2,29,'PAID',650),(21,3,30,'PAID',650),
(1,4,10,'PAID',500),(2,3,11,'PENDING',600),(3,4,12,'PAID',450),(14,4,15,'CONFIRMED',600),(15,2,16,'PAID',450),(19,2,20,'PAID',1000);

INSERT INTO amenity (am_id, am_name) VALUES (1, 'Free WiFi'), (2, 'Restaurant / Bar'), (3, 'Air Conditioning'), (4, 'Accessibility (AmEA)');

INSERT INTO accommodation (acc_name, acc_dst_id, acc_type, acc_stars, acc_rating, acc_total_rooms, acc_price_per_night, acc_status, acc_street, acc_number, acc_city, acc_zip_code, acc_phone, acc_email) VALUES
('Grand Bretagne', 6, 'HOTEL', 5, 4.90, 320, 450.00, 'ACTIVE', 'Syntagma Sq', '1', 'Athens', '10564', '2103330000', 'info@gb.gr'),
('Coco-Mat Athens', 6, 'HOTEL', 4, 4.50, 100, 180.00, 'ACTIVE', 'Patriarchou Ioakim', '36', 'Athens', '10675', '2107230000', 'stay@cocomat.gr'),
('Mykonos Blu', 1, 'RESORT', 5, 4.80, 80, 600.00, 'ACTIVE', 'Psarou Beach', '', 'Mykonos', '84600', '2289020000', 'blu@grecotel.com'),
('City Center Hostel', 7, 'HOSTEL', NULL, 3.50, 20, 40.00, 'ACTIVE', 'Athinas', '12', 'Thessaloniki', '54625', '2310555555', 'sleep@hostel.gr'),
('Sunset Apartments', 1, 'APARTMENT', NULL, 4.20, 10, 120.00, 'ACTIVE', 'Main Street', '45', 'Santorini', '84700', '2286012345', 'sun@santorini.gr'),
('Mountain View Rooms', 1, 'ROOMS', NULL, 3.80, 5, 60.00, 'INACTIVE', 'Central Road', '10', 'Arachova', '32004', '2267012345', 'rooms@arachova.gr'),
('Costa Navarino', 1, 'RESORT', 5, 5.00, 400, 750.00, 'ACTIVE', 'Navarino Dunes', '', 'Messinia', '24001', '2723090000', 'info@costanavarino.com'),
('Plaka Cozy Studio', 6, 'APARTMENT', NULL, 4.00, 1, 90.00, 'ACTIVE', 'Kydathineon', '5', 'Athens', '10558', '6900000000', 'plaka@bnb.gr'),
('London Royal', 14, 'HOTEL', 5, 4.70, 200, 300.00, 'ACTIVE', 'Oxford St', '10', 'London', 'W1D 1BS', '+44207123456', 'royal@london.uk'),
('Paris Louie', 10, 'HOTEL', 3, 3.20, 50, 110.00, 'INACTIVE', 'Rue de Rivoli', '88', 'Paris', '75001', '+33142345678', 'louie@paris.fr');

INSERT INTO accommodation_amenity VALUES (1,1),(1,2),(1,3),(1,4),(2,1),(2,3),(3,1),(3,2),(3,3),(4,1),(7,1),(7,2),(7,3),(7,4),(9,1),(9,2),(9,3);

-- =====================================================================
--  SECTION 3: STORED PROCEDURES
-- =====================================================================

DELIMITER $$

-- 3.1.3.1 — Assign a vehicle to a trip with full validation.
CREATE PROCEDURE TP_ASSIGN_VEHICLE(IN p_trip_id INT, IN p_vehicle_id INT, IN p_current_km INT)
BEGIN
    DECLARE v_seats TINYINT;
    DECLARE v_status VARCHAR(20);
    DECLARE v_reservations INT;
    DECLARE v_driver_license ENUM('A','B','C','D');
    DECLARE v_trip_start DATETIME;
    DECLARE v_trip_end DATETIME;
    DECLARE v_overlap_count INT;

    SELECT veh_seats, veh_status INTO v_seats, v_status FROM vehicle WHERE veh_id = p_vehicle_id;

    SELECT t.tr_departure, t.tr_return, d.drv_license,
           (SELECT COUNT(*) FROM reservation r WHERE r.res_tr_id = p_trip_id AND r.res_status IN ('CONFIRMED', 'PAID'))
    INTO v_trip_start, v_trip_end, v_driver_license, v_reservations
    FROM trip t JOIN driver d ON t.tr_drv_AT = d.drv_AT WHERE t.tr_id = p_trip_id;

    IF v_status != 'AVAILABLE' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: The vehicle is not AVAILABLE.'; END IF;
    IF v_reservations > v_seats THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Vehicle capacity insufficient.'; END IF;
    IF v_seats > 9 AND v_driver_license NOT IN ('C', 'D') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Invalid driver license.'; END IF;

    SELECT COUNT(*) INTO v_overlap_count FROM trip
    WHERE tr_veh_id = p_vehicle_id AND tr_id != p_trip_id AND tr_status != 'CANCELLED'
      AND ((tr_departure <= v_trip_end AND tr_return >= v_trip_start));
    IF v_overlap_count > 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Vehicle overlap.'; END IF;

    START TRANSACTION;
    UPDATE trip SET tr_veh_id = p_vehicle_id, tr_start_km = p_current_km, tr_status = 'ACTIVE' WHERE tr_id = p_trip_id;
    UPDATE vehicle SET veh_status = 'IN_USE', veh_km = p_current_km WHERE veh_id = p_vehicle_id;
    COMMIT;

    SELECT CONCAT('Success: Vehicle ', p_vehicle_id, ' assigned to Trip ', p_trip_id) AS Result;
END$$

-- 3.1.3.2 — Search available accommodations for a destination + date range.
CREATE PROCEDURE TP_SEARCH_ACCOMMODATION(IN p_dst_id INT, IN p_checkin DATETIME, IN p_checkout DATETIME, IN p_required_rooms INT, OUT p_first_acc_id INT)
BEGIN
    DROP TEMPORARY TABLE IF EXISTS temp_search_results;
    CREATE TEMPORARY TABLE temp_search_results AS
    SELECT a.acc_id, a.acc_name, a.acc_type, CONCAT(a.acc_street, ' ', a.acc_number, ', ', a.acc_city) AS address,
           a.acc_phone, a.acc_stars, a.acc_rating, a.acc_price_per_night,
           (a.acc_total_rooms - IFNULL(SUM(ta.ta_rooms_booked), 0)) AS available_rooms,
           GROUP_CONCAT(DISTINCT am.am_name SEPARATOR ', ') AS amenities_list
    FROM accommodation a
    LEFT JOIN accommodation_amenity aa ON a.acc_id = aa.aa_acc_id
    LEFT JOIN amenity am ON aa.aa_am_id = am.am_id
    LEFT JOIN trip_accommodation ta ON a.acc_id = ta.ta_acc_id AND (ta.ta_checkin < p_checkout AND ta.ta_checkout > p_checkin)
    WHERE a.acc_dst_id = p_dst_id AND a.acc_status = 'ACTIVE'
    GROUP BY a.acc_id HAVING available_rooms >= p_required_rooms
    ORDER BY a.acc_price_per_night ASC, a.acc_stars DESC, a.acc_rating DESC;

    SET p_first_acc_id = (SELECT acc_id FROM temp_search_results LIMIT 1);
    SELECT * FROM temp_search_results;
    DROP TEMPORARY TABLE IF EXISTS temp_search_results;
END$$

-- 3.1.3.3 — Auto-book accommodation for every destination of a trip (all-or-nothing).
CREATE PROCEDURE TP_BOOK_TRIP_ACCOMMODATION(IN p_trip_id INT)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_dst_id INT;
    DECLARE v_arrival, v_departure DATETIME;
    DECLARE v_maxseats, v_rooms_needed, v_found_acc_id INT;

    DECLARE cur_destinations CURSOR FOR
        SELECT t.to_dst_id, t.to_arrival, t.to_departure FROM travel_to t JOIN destination d ON t.to_dst_id = d.dst_id
        WHERE t.to_tr_id = p_trip_id AND d.dst_location IS NOT NULL ORDER BY t.to_sequence ASC;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; SELECT 'Transaction Failed.' AS Error_Message; END;

    SELECT tr_maxseats INTO v_maxseats FROM trip WHERE tr_id = p_trip_id;
    SET v_rooms_needed = CEILING(v_maxseats / 2);

    START TRANSACTION;
    OPEN cur_destinations;
    read_loop: LOOP
        FETCH cur_destinations INTO v_dst_id, v_arrival, v_departure;
        IF done THEN LEAVE read_loop; END IF;

        SET v_found_acc_id = 0;
        CALL TP_SEARCH_ACCOMMODATION(v_dst_id, v_arrival, v_departure, v_rooms_needed, v_found_acc_id);

        IF v_found_acc_id IS NULL OR v_found_acc_id = 0 THEN ROLLBACK; SELECT CONCAT('FAILED for City ID: ', v_dst_id) AS Error_Message; LEAVE read_loop; END IF;

        INSERT INTO trip_accommodation (ta_tr_id, ta_acc_id, ta_checkin, ta_checkout, ta_rooms_booked)
        VALUES (p_trip_id, v_found_acc_id, v_arrival, v_departure, v_rooms_needed);
    END LOOP;
    CLOSE cur_destinations;
    IF v_found_acc_id IS NOT NULL AND v_found_acc_id != 0 THEN COMMIT; SELECT * FROM trip_accommodation WHERE ta_tr_id = p_trip_id; END IF;
END$$

-- 3.1.3.4 — Populate trip_history with 100,000 rows for performance testing.
CREATE PROCEDURE TP_GENERATE_HISTORY_DATA()
BEGIN
    DECLARE i INT DEFAULT 0;
    START TRANSACTION;
    WHILE i < 100000 DO
        INSERT INTO trip_history (log_trip_id, log_departure, log_return, log_dest_count, log_participants, log_revenue)
        VALUES (FLOOR(1+RAND()*1000),
                DATE_ADD('2020-01-01', INTERVAL FLOOR(RAND()*1800) DAY),
                DATE_ADD('2020-01-01', INTERVAL FLOOR(RAND()*1800)+5 DAY),
                FLOOR(1+RAND()*5), FLOOR(10+RAND()*40), FLOOR(1000+RAND()*20000));
        SET i = i + 1;
    END WHILE;
    COMMIT;
END$$

-- 3.1.3.4 (a) — Total revenue within a date range.
CREATE PROCEDURE TP_STATS_REVENUE(IN p_date_from DATETIME, IN p_date_to DATETIME)
BEGIN
    SELECT SUM(log_revenue) AS 'Total Revenue' FROM trip_history WHERE log_departure BETWEEN p_date_from AND p_date_to;
END$$

-- 3.1.3.4 (b) — Trips filtered by number of destinations.
CREATE PROCEDURE TP_STATS_DESTINATIONS(IN p_dest_count INT)
BEGIN
    SELECT log_departure, log_return FROM trip_history WHERE log_dest_count = p_dest_count;
END$$

DELIMITER ;

-- =====================================================================
--  SECTION 4: INDEXES (query optimization over the history table)
-- =====================================================================

CREATE INDEX idx_history_departure  ON trip_history(log_departure);   -- range queries on date
CREATE INDEX idx_history_dest_count ON trip_history(log_dest_count);  -- equality lookups

-- =====================================================================
--  SECTION 5: TRIGGERS
-- =====================================================================

-- 3.1.4.2 — Auto-compute nights & total cost on accommodation booking.
DELIMITER $$
CREATE TRIGGER trg_calc_accommodation_cost
BEFORE INSERT ON trip_accommodation
FOR EACH ROW
BEGIN
    DECLARE v_price DECIMAL(10,2);
    SELECT acc_price_per_night INTO v_price FROM accommodation WHERE acc_id = NEW.ta_acc_id;
    SET NEW.ta_nights = DATEDIFF(NEW.ta_checkout, NEW.ta_checkin);
    SET NEW.ta_cost   = NEW.ta_rooms_booked * NEW.ta_nights * v_price;
END$$
DELIMITER ;

-- 3.1.4.1 — Audit-log triggers (INSERT / UPDATE / DELETE) on the core tables.
DELIMITER $$
CREATE TRIGGER trg_log_trip_insert AFTER INSERT ON trip
FOR EACH ROW
BEGIN
    INSERT INTO log (log_user, log_date, log_time, log_action, log_table)
    VALUES (USER(), CURDATE(), CURTIME(), 'INSERT', 'trip');
END$$

CREATE TRIGGER trg_log_trip_update AFTER UPDATE ON trip
FOR EACH ROW
BEGIN
    INSERT INTO log (log_user, log_date, log_time, log_action, log_table)
    VALUES (USER(), CURDATE(), CURTIME(), 'UPDATE', 'trip');
END$$

CREATE TRIGGER trg_log_trip_delete AFTER DELETE ON trip
FOR EACH ROW
BEGIN
    INSERT INTO log (log_user, log_date, log_time, log_action, log_table)
    VALUES (USER(), CURDATE(), CURTIME(), 'DELETE', 'trip');
END$$

CREATE TRIGGER trg_log_reservation_insert AFTER INSERT ON reservation
FOR EACH ROW
BEGIN
    INSERT INTO log (log_user, log_date, log_time, log_action, log_table)
    VALUES (USER(), CURDATE(), CURTIME(), 'INSERT', 'reservation');
END$$

CREATE TRIGGER trg_log_reservation_update AFTER UPDATE ON reservation
FOR EACH ROW
BEGIN
    INSERT INTO log (log_user, log_date, log_time, log_action, log_table)
    VALUES (USER(), CURDATE(), CURTIME(), 'UPDATE', 'reservation');
END$$

CREATE TRIGGER trg_log_reservation_delete AFTER DELETE ON reservation
FOR EACH ROW
BEGIN
    INSERT INTO log (log_user, log_date, log_time, log_action, log_table)
    VALUES (USER(), CURDATE(), CURTIME(), 'DELETE', 'reservation');
END$$

CREATE TRIGGER trg_log_customer_insert AFTER INSERT ON customer
FOR EACH ROW
BEGIN
    INSERT INTO log (log_user, log_date, log_time, log_action, log_table)
    VALUES (USER(), CURDATE(), CURTIME(), 'INSERT', 'customer');
END$$

CREATE TRIGGER trg_log_customer_update AFTER UPDATE ON customer
FOR EACH ROW
BEGIN
    INSERT INTO log (log_user, log_date, log_time, log_action, log_table)
    VALUES (USER(), CURDATE(), CURTIME(), 'UPDATE', 'customer');
END$$

CREATE TRIGGER trg_log_customer_delete AFTER DELETE ON customer
FOR EACH ROW
BEGIN
    INSERT INTO log (log_user, log_date, log_time, log_action, log_table)
    VALUES (USER(), CURDATE(), CURTIME(), 'DELETE', 'customer');
END$$

CREATE TRIGGER trg_log_destination_insert AFTER INSERT ON destination
FOR EACH ROW
BEGIN
    INSERT INTO log (log_user, log_date, log_time, log_action, log_table)
    VALUES (USER(), CURDATE(), CURTIME(), 'INSERT', 'destination');
END$$

CREATE TRIGGER trg_log_destination_update AFTER UPDATE ON destination
FOR EACH ROW
BEGIN
    INSERT INTO log (log_user, log_date, log_time, log_action, log_table)
    VALUES (USER(), CURDATE(), CURTIME(), 'UPDATE', 'destination');
END$$

CREATE TRIGGER trg_log_destination_delete AFTER DELETE ON destination
FOR EACH ROW
BEGIN
    INSERT INTO log (log_user, log_date, log_time, log_action, log_table)
    VALUES (USER(), CURDATE(), CURTIME(), 'DELETE', 'destination');
END$$

CREATE TRIGGER trg_log_vehicle_insert AFTER INSERT ON vehicle
FOR EACH ROW
BEGIN
    INSERT INTO log (log_user, log_date, log_time, log_action, log_table)
    VALUES (USER(), CURDATE(), CURTIME(), 'INSERT', 'vehicle');
END$$

CREATE TRIGGER trg_log_vehicle_update AFTER UPDATE ON vehicle
FOR EACH ROW
BEGIN
    INSERT INTO log (log_user, log_date, log_time, log_action, log_table)
    VALUES (USER(), CURDATE(), CURTIME(), 'UPDATE', 'vehicle');
END$$

CREATE TRIGGER trg_log_vehicle_delete AFTER DELETE ON vehicle
FOR EACH ROW
BEGIN
    INSERT INTO log (log_user, log_date, log_time, log_action, log_table)
    VALUES (USER(), CURDATE(), CURTIME(), 'DELETE', 'vehicle');
END$$

CREATE TRIGGER trg_log_accommodation_insert AFTER INSERT ON accommodation
FOR EACH ROW
BEGIN
    INSERT INTO log (log_user, log_date, log_time, log_action, log_table)
    VALUES (USER(), CURDATE(), CURTIME(), 'INSERT', 'accommodation');
END$$

CREATE TRIGGER trg_log_accommodation_update AFTER UPDATE ON accommodation
FOR EACH ROW
BEGIN
    INSERT INTO log (log_user, log_date, log_time, log_action, log_table)
    VALUES (USER(), CURDATE(), CURTIME(), 'UPDATE', 'accommodation');
END$$

CREATE TRIGGER trg_log_accommodation_delete AFTER DELETE ON accommodation
FOR EACH ROW
BEGIN
    INSERT INTO log (log_user, log_date, log_time, log_action, log_table)
    VALUES (USER(), CURDATE(), CURTIME(), 'DELETE', 'accommodation');
END$$

CREATE TRIGGER trg_log_trip_accommodation_insert AFTER INSERT ON trip_accommodation
FOR EACH ROW
BEGIN
    INSERT INTO log (log_user, log_date, log_time, log_action, log_table)
    VALUES (USER(), CURDATE(), CURTIME(), 'INSERT', 'trip_accommodation');
END$$

CREATE TRIGGER trg_log_trip_accommodation_update AFTER UPDATE ON trip_accommodation
FOR EACH ROW
BEGIN
    INSERT INTO log (log_user, log_date, log_time, log_action, log_table)
    VALUES (USER(), CURDATE(), CURTIME(), 'UPDATE', 'trip_accommodation');
END$$

CREATE TRIGGER trg_log_trip_accommodation_delete AFTER DELETE ON trip_accommodation
FOR EACH ROW
BEGIN
    INSERT INTO log (log_user, log_date, log_time, log_action, log_table)
    VALUES (USER(), CURDATE(), CURTIME(), 'DELETE', 'trip_accommodation');
END$$

DELIMITER ;

-- =====================================================================
--  OPTIONAL: load 100k history rows (needed to demo the index speed-up)
--  Uncomment to run — takes a few seconds.
-- =====================================================================
-- CALL TP_GENERATE_HISTORY_DATA();
