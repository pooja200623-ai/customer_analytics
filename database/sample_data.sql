-- =============================================================================
-- PROJECT  : Customer Segmentation & Purchase Behavior Analytics Using SQL
-- FILE     : sample_data.sql
-- PURPOSE  : Realistic seed data for the customer_analytics database
-- DATASET  :
--   • 10  Categories
--   • 50  Products   (5 per category)
--   • 30  Customers  (diverse cities, segments, genders, age groups)
--   • 60  Orders     (Jan 2025 – Nov 2026, various statuses)
--   • 110 Order Items (single- and multi-item orders)
--   • 65  Payments   (Credit Card, UPI, EMI, COD, Net Banking, Debit Card)
-- ENGINE   : MySQL 8.0+
-- NOTE     : Run schema.sql FIRST, then this file.
--            All financial values are in Indian Rupees (INR).
--            line_total = ROUND(quantity * unit_price * (1 - discount_pct/100), 2)
-- =============================================================================

USE customer_analytics;

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE            = 'NO_AUTO_VALUE_ON_ZERO';


-- =============================================================================
-- 1. CATEGORIES  (10 rows)
-- =============================================================================
INSERT INTO categories
  (category_id, category_name, description, is_active)
VALUES
( 1, 'Electronics',        'Mobile phones, laptops, tablets, TVs, and accessories',      1),
( 2, 'Clothing',           'Men, women, and kids apparel — casual to formal',            1),
( 3, 'Home & Kitchen',     'Appliances, cookware, furniture, and home décor',            1),
( 4, 'Books & Stationery', 'Academic, fiction, non-fiction, and office supplies',        1),
( 5, 'Sports & Fitness',   'Gym equipment, outdoor gear, yoga, and sportswear',          1),
( 6, 'Beauty & Personal',  'Skincare, haircare, grooming, and wellness products',        1),
( 7, 'Toys & Games',       'Educational toys, board games, and outdoor play items',      1),
( 8, 'Grocery & Food',     'Packaged food, beverages, snacks, and organic produce',      1),
( 9, 'Jewellery',          'Gold, silver, diamond jewellery and fashion accessories',    1),
(10, 'Automotive',         'Car accessories, bike parts, tyres, and tools',              1);


-- =============================================================================
-- 2. PRODUCTS  (50 rows — 5 per category)
-- =============================================================================
INSERT INTO products
  (product_id, category_id, product_name, sku, description,
   unit_price, cost_price, stock_quantity, reorder_level, brand, is_active)
VALUES
-- ── Electronics (category 1) ─────────────────────────────────────────────
( 1,  1, 'Samsung Galaxy S23 Ultra',     'EL-SGS23U',  '256 GB, 12 GB RAM, 200 MP Camera',          109999.00,  85000.00,  45,  5, 'Samsung',    1),
( 2,  1, 'Apple iPhone 15 Pro',          'EL-APL15P',  '128 GB, A17 Pro chip, Titanium frame',      129999.00, 100000.00,  30,  5, 'Apple',      1),
( 3,  1, 'OnePlus Nord CE 3',            'EL-OPNCE3',  '8 GB RAM, 128 GB, 108 MP Camera',            24999.00,  18000.00,  80, 10, 'OnePlus',    1),
( 4,  1, 'Dell XPS 15 Laptop',           'EL-DLXPS15', 'Intel i7, 16 GB RAM, 512 GB SSD, 4K OLED', 149999.00, 115000.00,  20,  3, 'Dell',       1),
( 5,  1, 'HP Pavilion x360',             'EL-HPPX360', 'Intel i5, 8 GB RAM, 256 GB SSD, Touch',      64999.00,  48000.00,  35,  5, 'HP',         1),
-- ── Electronics (extra SKUs for variety) ─────────────────────────────────
( 6,  1, 'Sony WH-1000XM5 Headphones',  'EL-SNYWH5',  'Wireless ANC, 30 hr battery, Hi-Res',        29999.00,  22000.00,  60, 10, 'Sony',       1),
( 7,  1, 'Apple AirPods Pro 2nd Gen',    'EL-APLAP2',  'ANC, Transparency mode, MagSafe',             24999.00,  18500.00,  50,  8, 'Apple',      1),
( 8,  1, 'Samsung 55" QLED 4K TV',       'EL-SGS55Q',  'QLED Smart TV, 120 Hz, Dolby Atmos',         79999.00,  60000.00,  15,  3, 'Samsung',    1),
( 9,  1, 'Canon EOS R50 Camera',         'EL-CNER50',  'Mirrorless, 24.2 MP, 4K Video',               54999.00,  42000.00,  18,  3, 'Canon',      1),
(10,  1, 'Logitech MX Master 3S Mouse',  'EL-LGMX3S',  '8000 DPI, Quiet clicks, USB-C',                7999.00,   5500.00, 100, 15, 'Logitech',   1),

-- ── Clothing (category 2) ─────────────────────────────────────────────────
(11,  2, 'Levi\'s 511 Slim Fit Jeans',   'CL-LV511',   'Stretch denim, slim fit, 5 colours',           4299.00,   2200.00, 200, 20, 'Levi\'s',    1),
(12,  2, 'Peter England Formal Shirt',   'CL-PEFS01',  'Cotton blend, full-sleeve, office wear',       1599.00,    800.00, 300, 30, 'Peter England',1),
(13,  2, 'Fabindia Kurta Set (Women)',   'CL-FBKW01',  'Hand-block print, cotton, XS–3XL',             3299.00,   1700.00, 150, 20, 'Fabindia',   1),
(14,  2, 'Nike Air Zoom Pegasus 40',     'CL-NKPEG40', 'Running shoes, React foam, Unisex',           10795.00,   7500.00,  90, 10, 'Nike',       1),
(15,  2, 'H&M Oversized Hoodie',         'CL-HMOH01',  'Fleece, unisex, 7 colours',                    1999.00,    900.00, 250, 25, 'H&M',        1),

-- ── Home & Kitchen (category 3) ───────────────────────────────────────────
(16,  3, 'Instant Pot Duo 7-in-1',       'HK-IPDUP7',  '6 qt, 7 functions, 10 safety features',        7999.00,   5200.00,  70,  8, 'Instant Pot',1),
(17,  3, 'Dyson V12 Detect Slim',        'HK-DYV12',   'Cordless vacuum, laser dust detect',           47990.00,  36000.00,  25,  3, 'Dyson',      1),
(18,  3, 'IKEA KALLAX Shelf Unit',       'HK-IKKS4X4', '4×4 cubbies, white, 147×147 cm',              18999.00,  12000.00,  20,  3, 'IKEA',       1),
(19,  3, 'Prestige Iris Plus Induction', 'HK-PGIPL',   '2000 W, 7 preset menus, auto shut-off',        3299.00,   1800.00, 120, 15, 'Prestige',   1),
(20,  3, 'Philips Air Purifier AC2887',  'HK-PHPAC28', 'HEPA + activated carbon, 333 sq ft',           14999.00,  10000.00,  40,  5, 'Philips',    1),

-- ── Books & Stationery (category 4) ───────────────────────────────────────
(21,  4, 'Atomic Habits — James Clear',  'BS-AHBOOK',  'Self-help bestseller, paperback',                 499.00,    220.00, 500, 50, 'Penguin',    1),
(22,  4, 'The Psychology of Money',      'BS-POMBOOK', 'Personal finance, Morgan Housel',                 399.00,    180.00, 400, 40, 'Jaico',      1),
(23,  4, 'Staedtler Mars Pencil Set',    'BS-STDPNC',  'B to 8B, 12-piece art pencils',                   499.00,    220.00, 300, 30, 'Staedtler',  1),
(24,  4, 'Moleskine Classic Notebook',   'BS-MOLNB',   'A5, dotted, 240 pages, hardcover',               1299.00,    700.00, 200, 20, 'Moleskine',  1),
(25,  4, 'Parker Jotter Ballpen Set',    'BS-PKJBP',   '4-pen set, blue-black ink, steel body',            999.00,    450.00, 250, 25, 'Parker',     1),

-- ── Sports & Fitness (category 5) ─────────────────────────────────────────
(26,  5, 'Decathlon 20 kg Dumbbell Set', 'SF-DC20DB',  'Rubber coated hex shape, pair',                 4999.00,   2800.00,  60,  8, 'Decathlon',  1),
(27,  5, 'Yonex Badminton Racket GR303', 'SF-YXGR303', 'Aluminium shaft, beginner to mid-level',         1299.00,    650.00, 150, 20, 'Yonex',      1),
(28,  5, 'Boldfit Yoga Mat 6 mm',        'SF-BFYM6',   'Non-slip, eco-friendly TPE, carry strap',          899.00,    400.00, 200, 20, 'Boldfit',    1),
(29,  5, 'Garmin Forerunner 255',        'SF-GRFR255', 'GPS Running Watch, HRV, Multi-sport',            30999.00,  22000.00,  30,  4, 'Garmin',     1),
(30,  5, 'Nivia Football Size 5',        'SF-NVFB5',   'PU leather, hand-stitched, match quality',        1199.00,    580.00, 180, 20, 'Nivia',      1),

-- ── Beauty & Personal Care (category 6) ───────────────────────────────────
(31,  6, 'L\'Oréal Paris Revitalift Serum','BP-LRRVS', 'Hyaluronic Acid 1.5% Pure, 30 ml',                899.00,    420.00, 250, 25, 'L\'Oréal',   1),
(32,  6, 'Dyson Airwrap Complete',       'BP-DYAWS',   'Curling + straightening + drying, 1300 W',       45900.00,  34000.00,  20,  3, 'Dyson',      1),
(33,  6, 'Mamaearth Vitamin C FaceWash', 'BP-MMVCFW',  '100 ml, Vitamin C + Turmeric, sulphate-free',      299.00,    130.00, 400, 40, 'Mamaearth',  1),
(34,  6, 'Biotique Bio Almond Scrub',    'BP-BQBAS',   '235 g, oil-free, all skin types',                   299.00,    130.00, 350, 35, 'Biotique',   1),
(35,  6, 'Gillette Fusion ProShield',    'BP-GLFPS',   '4-blade razor, lubricating strip',                1099.00,    520.00, 300, 30, 'Gillette',   1),

-- ── Toys & Games (category 7) ─────────────────────────────────────────────
(36,  7, 'LEGO Star Wars Millennium Falcon','TG-LGSWMF','7541 pcs, collector edition UCS',               14999.00,  11000.00,  15,  2, 'LEGO',       1),
(37,  7, 'Funskool Monopoly Classic',    'TG-FKMPCL',  'Board game, 2–8 players, full set',                 899.00,    380.00, 200, 20, 'Funskool',   1),
(38,  7, 'Hot Wheels 20-Car Gift Pack',  'TG-HWGP20',  '1:64 scale die-cast cars, assorted',               999.00,    450.00, 180, 20, 'Hot Wheels', 1),
(39,  7, 'Play-Doh 36-Can Mega Set',     'TG-PDMG36',  '36 colours, 1 oz each, non-toxic',               1799.00,    850.00, 120, 15, 'Play-Doh',   1),
(40,  7, 'Rubik\'s Cube 3×3',            'TG-RBKC3',   'Speed cube, flexible mechanism',                    499.00,    200.00, 300, 30, 'Rubik\'s',   1),

-- ── Grocery & Food (category 8) ───────────────────────────────────────────
(41,  8, 'Tata Salt Lite 1 kg',          'GF-TTSL1',   'Low sodium, iodised, 1 kg pack',                    45.00,     28.00,1000,100, 'Tata',       1),
(42,  8, 'Nescafé Classic 200 g',        'GF-NSCL200', 'Instant coffee, 200 g jar',                         399.00,    220.00, 600, 60, 'Nescafé',    1),
(43,  8, 'Amul Dark Chocolate 150 g',    'GF-AMDC150', '55% cocoa, Belgian-style, 150 g',                   199.00,    100.00, 800, 80, 'Amul',       1),
(44,  8, 'Fortune Sunflower Oil 5 L',    'GF-FSFO5',   'Cold pressed, Vitamin E, 5-litre tin',               799.00,    490.00, 400, 40, 'Fortune',    1),
(45,  8, 'Bagrry\'s Rolled Oats 1 kg',   'GF-BGOTS1',  'Quick cook, gluten-free, 1 kg',                      299.00,    150.00, 700, 70, 'Bagrry\'s',  1),

-- ── Jewellery (category 9) ────────────────────────────────────────────────
(46,  9, '22KT Gold Chain 10 g',         'JW-22KGC10', '916 hallmarked, diamond cut, 18 inch',             57000.00,  52000.00,   5,  1, 'Tanishq',    1),
(47,  9, 'Sterling Silver Earrings',     'JW-SSEARSB', '92.5 purity, floral design, rhodium plated',          999.00,    450.00, 100, 10, 'Mia',        1),
(48,  9, 'Diamond Solitaire Ring 0.25ct','JW-DMSR25',  'IGI certified, 18KT white gold, prong set',         29999.00,  24000.00,   8,  1, 'CaratLane',  1),
(49,  9, 'Rose Gold Bangle Set',         'JW-RGBNG',   'Set of 4, 18KT rose gold plated brass',              2499.00,   1200.00,  60,  8, 'Zaveri Pearls',1),
(50,  9, 'Pearl Pendant Necklace',       'JW-PPLNK',   'Fresh-water pearl, sterling silver chain',           3999.00,   2000.00,  40,  5, 'BlueStone',  1),

-- ── Automotive (category 10) ──────────────────────────────────────────────
(51, 10, 'Bosch Car Battery 55 Ah',      'AU-BSCB55',  'MF maintenance-free, 18-month warranty',             5499.00,   3800.00,  30,  4, 'Bosch',      1),
(52, 10, 'Michelin Pilot Sport 4 Tyre',  'AU-MCPS4',   '205/55 R16, XL, A/A EU-label',                      8999.00,   6500.00,  40,  5, 'Michelin',   1),
(53, 10, '3M Car Interior Cleaner',      'AU-3MCIC',   '400 ml aerosol, dashboard & upholstery',              499.00,    220.00, 150, 20, '3M',         1),
(54, 10, 'Veba Dashboard Camera 4K',     'AU-VBDC4K',  'Loop recording, night vision, wide-angle',           6999.00,   4800.00,  25,  3, 'Veba',       1),
(55, 10, 'Meguiar\'s Ultimate Wax 311g', 'AU-MGUWX',   'Synthetic polymer wax, water-beading',               1299.00,    650.00, 100, 10, 'Meguiar\'s', 1);


-- =============================================================================
-- 3. CUSTOMERS  (30 rows — diverse cities, segments, genders)
-- =============================================================================
INSERT INTO customers
  (customer_id, first_name, last_name, email, phone, gender, date_of_birth,
   segment, address_line1, city, state, country, postal_code,
   is_active, registration_date, last_login)
VALUES
( 1, 'Aarav',     'Sharma',    'aarav.sharma@gmail.com',       '9812345678', 'Male',              '1990-04-15', 'Platinum', '12 MG Road',              'Bengaluru',          'Karnataka',          'India', '560001', 1, '2022-01-05', '2026-11-01 10:22:00'),
( 2, 'Priya',     'Nair',      'priya.nair@outlook.com',       '9823456789', 'Female',            '1994-08-22', 'Gold',     '45 Anna Salai',            'Chennai',            'Tamil Nadu',         'India', '600002', 1, '2022-03-18', '2026-10-28 14:05:00'),
( 3, 'Rohan',     'Verma',     'rohan.verma@yahoo.com',        '9834567890', 'Male',              '1988-11-30', 'Silver',   '7 Sector 18',              'Noida',              'Uttar Pradesh',      'India', '201301', 1, '2022-05-10', '2026-11-03 09:15:00'),
( 4, 'Sneha',     'Kulkarni',  'sneha.kulkarni@gmail.com',     '9845678901', 'Female',            '1996-02-14', 'Platinum', '22 FC Road',               'Pune',               'Maharashtra',        'India', '411004', 1, '2022-06-02', '2026-11-05 18:40:00'),
( 5, 'Amit',      'Patel',     'amit.patel@rediffmail.com',    '9856789012', 'Male',              '1985-07-19', 'Gold',     '33 CG Road',               'Ahmedabad',          'Gujarat',            'India', '380009', 1, '2022-07-14', '2026-10-22 11:00:00'),
( 6, 'Kavya',     'Reddy',     'kavya.reddy@gmail.com',        '9867890123', 'Female',            '1999-12-05', 'Silver',   '8 Jubilee Hills',          'Hyderabad',          'Telangana',          'India', '500033', 1, '2022-09-01', '2026-11-07 20:00:00'),
( 7, 'Vikram',    'Singh',     'vikram.singh@gmail.com',       '9878901234', 'Male',              '1991-03-25', 'Bronze',   '56 Rajouri Garden',        'Delhi',              'Delhi',              'India', '110027', 1, '2022-10-20', '2026-09-15 08:30:00'),
( 8, 'Meera',     'Iyer',      'meera.iyer@gmail.com',         '9889012345', 'Female',            '1993-06-10', 'Platinum', '3 Besant Nagar Beach Rd',  'Chennai',            'Tamil Nadu',         'India', '600090', 1, '2022-11-11', '2026-11-08 16:55:00'),
( 9, 'Arjun',     'Mehta',     'arjun.mehta@gmail.com',        '9890123456', 'Male',              '1987-09-17', 'Gold',     '19 Linking Road',          'Mumbai',             'Maharashtra',        'India', '400050', 1, '2023-01-04', '2026-10-30 13:20:00'),
(10, 'Divya',     'Joshi',     'divya.joshi@hotmail.com',      '9801234567', 'Female',            '1998-01-29', 'Silver',   '44 Gomti Nagar',           'Lucknow',            'Uttar Pradesh',      'India', '226010', 1, '2023-02-15', '2026-10-19 07:45:00'),
(11, 'Rahul',     'Gupta',     'rahul.gupta@gmail.com',        '9802345678', 'Male',              '1992-05-08', 'Bronze',   '11 Salt Lake City',        'Kolkata',            'West Bengal',        'India', '700064', 1, '2023-04-10', '2026-10-02 12:00:00'),
(12, 'Ananya',    'Das',       'ananya.das@gmail.com',         '9803456789', 'Female',            '2000-10-14', 'Bronze',   '27 GS Road',               'Guwahati',           'Assam',              'India', '781007', 1, '2023-05-22', '2026-08-20 10:10:00'),
(13, 'Siddharth', 'Bhatt',     'siddharth.bhatt@gmail.com',    '9804567890', 'Male',              '1989-07-03', 'Gold',     '5 Stadium Circle',         'Rajkot',             'Gujarat',            'India', '360001', 1, '2023-06-11', '2026-11-01 09:50:00'),
(14, 'Pooja',     'Mishra',    'pooja.mishra@gmail.com',       '9805678901', 'Female',            '1997-03-20', 'Silver',   '72 Civil Lines',           'Prayagraj',          'Uttar Pradesh',      'India', '211001', 1, '2023-07-30', '2026-10-25 15:30:00'),
(15, 'Karan',     'Malhotra',  'karan.malhotra@outlook.com',   '9806789012', 'Male',              '1986-11-11', 'Platinum', '88 DLF Phase 3',           'Gurugram',           'Haryana',            'India', '122002', 1, '2023-08-09', '2026-11-09 08:00:00'),
(16, 'Nisha',     'Agarwal',   'nisha.agarwal@gmail.com',      '9807890123', 'Female',            '1995-04-27', 'Silver',   '15 Mansarovar',            'Jaipur',             'Rajasthan',          'India', '302020', 1, '2023-09-18', '2026-10-12 17:22:00'),
(17, 'Suresh',    'Pillai',    'suresh.pillai@gmail.com',      '9808901234', 'Male',              '1983-08-01', 'Bronze',   '9 Pattom',                 'Thiruvananthapuram', 'Kerala',             'India', '695004', 1, '2023-10-05', '2026-07-30 11:40:00'),
(18, 'Riya',      'Chopra',    'riya.chopra@gmail.com',        '9809012345', 'Female',            '2001-02-18', 'Silver',   '34 Khar West',             'Mumbai',             'Maharashtra',        'India', '400052', 1, '2023-11-12', '2026-11-02 19:05:00'),
(19, 'Deepak',    'Kumar',     'deepak.kumar@gmail.com',       '9810123456', 'Male',              '1990-12-24', 'Gold',     '18 Raja Park',             'Jaipur',             'Rajasthan',          'India', '302004', 1, '2023-12-01', '2026-10-28 14:00:00'),
(20, 'Anjali',    'Tiwari',    'anjali.tiwari@gmail.com',      '9811234567', 'Female',            '1994-06-30', 'Silver',   '60 Vikas Nagar',           'Dehradun',           'Uttarakhand',        'India', '248001', 1, '2024-01-20', '2026-09-30 10:35:00'),
(21, 'Harsh',     'Shah',      'harsh.shah@gmail.com',         '9813456789', 'Male',              '1988-01-14', 'Platinum', '25 Navrangpura',           'Ahmedabad',          'Gujarat',            'India', '380009', 1, '2024-02-14', '2026-11-08 20:20:00'),
(22, 'Tanvi',     'Desai',     'tanvi.desai@gmail.com',        '9814567890', 'Female',            '1996-09-09', 'Bronze',   '41 Law Garden',            'Ahmedabad',          'Gujarat',            'India', '380006', 1, '2024-03-05', '2026-08-14 09:00:00'),
(23, 'Nikhil',    'Rao',       'nikhil.rao@gmail.com',         '9815678901', 'Male',              '1992-04-22', 'Silver',   '6 Indiranagar',            'Bengaluru',          'Karnataka',          'India', '560038', 1, '2024-04-18', '2026-10-05 16:45:00'),
(24, 'Shruti',    'Jain',      'shruti.jain@yahoo.com',        '9816789012', 'Female',            '1999-07-16', 'Bronze',   '30 Lajpat Nagar II',       'Delhi',              'Delhi',              'India', '110024', 1, '2024-05-01', '2026-07-21 13:00:00'),
(25, 'Varun',     'Kapoor',    'varun.kapoor@gmail.com',       '9817890123', 'Male',              '1985-10-05', 'Gold',     '14 Powai Lake Road',       'Mumbai',             'Maharashtra',        'India', '400076', 1, '2024-06-10', '2026-11-04 11:30:00'),
(26, 'Ritika',    'Saxena',    'ritika.saxena@gmail.com',      '9818901234', 'Female',            '1993-02-01', 'Silver',   '55 Ashok Vihar',           'Delhi',              'Delhi',              'India', '110052', 1, '2024-07-22', '2026-10-18 08:15:00'),
(27, 'Saurav',    'Ghosh',     'saurav.ghosh@gmail.com',       '9819012345', 'Male',              '1991-08-28', 'Bronze',   '21 Tollygunge',            'Kolkata',            'West Bengal',        'India', '700033', 1, '2024-08-30', '2026-09-22 14:50:00'),
(28, 'Pallavi',   'Nambiar',   'pallavi.nambiar@gmail.com',    '9820123456', 'Female',            '1997-11-11', 'New',      '10 Calicut Road',          'Kozhikode',          'Kerala',             'India', '673001', 1, '2024-09-05', '2026-10-29 17:00:00'),
(29, 'Yash',      'Trivedi',   'yash.trivedi@gmail.com',       '9821234567', 'Male',              '1989-05-19', 'Gold',     '7 Satellite Road',         'Ahmedabad',          'Gujarat',            'India', '380015', 1, '2024-10-12', '2026-11-06 12:45:00'),
(30, 'Lavanya',   'Krishnan',  'lavanya.krishnan@gmail.com',   '9822345678', 'Female',            '2000-03-07', 'Silver',   '38 T. Nagar',              'Chennai',            'Tamil Nadu',         'India', '600017', 1, '2024-11-25', '2026-10-31 20:30:00');


-- =============================================================================
-- 4. ORDERS  (60 rows — Jan 2025 through Nov 2026)
-- Financial formula: total_amount = subtotal - discount_amount + tax_amount + shipping_charge
-- =============================================================================
INSERT INTO orders
  (order_id, customer_id, order_date, status,
   shipping_address, shipping_city, shipping_state, shipping_country, shipping_postal,
   subtotal, discount_amount, tax_amount, shipping_charge, total_amount,
   estimated_delivery, actual_delivery)
VALUES
-- ── 2025 orders (1–25) ───────────────────────────────────────────────────
( 1,  1, '2025-01-10 10:30:00', 'Delivered', '12 MG Road',              'Bengaluru',          'Karnataka',     'India', '560001', 109999.00,  5000.00, 18900.00,     0.00, 123899.00, '2025-01-14', '2025-01-13'),
( 2,  2, '2025-01-18 14:00:00', 'Delivered', '45 Anna Salai',           'Chennai',            'Tamil Nadu',    'India', '600002',  54999.00,  2500.00,  9450.00,     0.00,  61949.00, '2025-01-22', '2025-01-21'),
( 3,  3, '2025-02-05 09:15:00', 'Delivered', '7 Sector 18',             'Noida',              'Uttar Pradesh', 'India', '201301',   7999.00,     0.00,  1440.00,    99.00,   9538.00, '2025-02-09', '2025-02-08'),
( 4,  4, '2025-02-20 16:45:00', 'Delivered', '22 FC Road',              'Pune',               'Maharashtra',   'India', '411004',  47990.00,  2000.00,  8280.00,     0.00,  54270.00, '2025-02-24', '2025-02-23'),
( 5,  5, '2025-03-01 11:00:00', 'Delivered', '33 CG Road',              'Ahmedabad',          'Gujarat',       'India', '380009',  10795.00,   500.00,  1854.00,    99.00,  12248.00, '2025-03-05', '2025-03-04'),
( 6,  6, '2025-03-15 13:30:00', 'Delivered', '8 Jubilee Hills',         'Hyderabad',          'Telangana',     'India', '500033',   4299.00,   200.00,   738.00,    99.00,   4936.00, '2025-03-19', '2025-03-18'),
( 7,  7, '2025-03-22 08:00:00', 'Delivered', '56 Rajouri Garden',       'Delhi',              'Delhi',         'India', '110027',   1599.00,     0.00,   288.00,    99.00,   1986.00, '2025-03-26', '2025-03-25'),
( 8,  8, '2025-04-10 17:20:00', 'Delivered', '3 Besant Nagar Beach Rd', 'Chennai',            'Tamil Nadu',    'India', '600090', 129999.00,  7000.00, 22320.00,     0.00, 145319.00, '2025-04-14', '2025-04-13'),
( 9,  9, '2025-04-25 12:10:00', 'Delivered', '19 Linking Road',         'Mumbai',             'Maharashtra',   'India', '400050',  29999.00,  1500.00,  5130.00,     0.00,  33629.00, '2025-04-29', '2025-04-28'),
(10, 10, '2025-05-05 09:45:00', 'Delivered', '44 Gomti Nagar',          'Lucknow',            'Uttar Pradesh', 'India', '226010',   3299.00,   100.00,   576.00,    99.00,   3874.00, '2025-05-09', '2025-05-08'),
(11, 11, '2025-05-18 15:30:00', 'Delivered', '11 Salt Lake City',       'Kolkata',            'West Bengal',   'India', '700064',    899.00,     0.00,   162.00,    49.00,   1110.00, '2025-05-22', '2025-05-21'),
(12, 12, '2025-05-27 11:00:00', 'Delivered', '27 GS Road',              'Guwahati',           'Assam',         'India', '781007',   1299.00,     0.00,   234.00,    99.00,   1632.00, '2025-06-01', '2025-05-31'),
(13, 13, '2025-06-04 10:00:00', 'Delivered', '5 Stadium Circle',        'Rajkot',             'Gujarat',       'India', '360001',  24999.00,  1000.00,  4320.00,     0.00,  28319.00, '2025-06-08', '2025-06-07'),
(14, 14, '2025-06-19 14:30:00', 'Delivered', '72 Civil Lines',          'Prayagraj',          'Uttar Pradesh', 'India', '211001',   4999.00,   200.00,   864.00,    99.00,   5762.00, '2025-06-23', '2025-06-22'),
(15, 15, '2025-07-01 09:00:00', 'Delivered', '88 DLF Phase 3',          'Gurugram',           'Haryana',       'India', '122002', 149999.00,  8000.00, 25920.00,     0.00, 167919.00, '2025-07-05', '2025-07-04'),
(16, 16, '2025-07-14 11:45:00', 'Delivered', '15 Mansarovar',           'Jaipur',             'Rajasthan',     'India', '302020',    499.00,     0.00,    90.00,    49.00,     638.00, '2025-07-18', '2025-07-17'),
(17, 17, '2025-07-28 13:15:00', 'Delivered', '9 Pattom',                'Thiruvananthapuram', 'Kerala',        'India', '695004',   1299.00,     0.00,   234.00,    99.00,   1632.00, '2025-08-01', '2025-07-31'),
(18, 18, '2025-08-10 16:00:00', 'Delivered', '34 Khar West',            'Mumbai',             'Maharashtra',   'India', '400052',  79999.00,  4000.00, 13680.00,     0.00,  89679.00, '2025-08-14', '2025-08-13'),
(19, 19, '2025-08-20 10:30:00', 'Delivered', '18 Raja Park',            'Jaipur',             'Rajasthan',     'India', '302004',  30999.00,  1500.00,  5346.00,     0.00,  34845.00, '2025-08-24', '2025-08-23'),
(20, 20, '2025-09-05 14:00:00', 'Delivered', '60 Vikas Nagar',          'Dehradun',           'Uttarakhand',   'India', '248001',  14999.00,   500.00,  2610.00,    99.00,  17208.00, '2025-09-09', '2025-09-08'),
(21, 21, '2025-09-15 11:30:00', 'Delivered', '25 Navrangpura',          'Ahmedabad',          'Gujarat',       'India', '380009',  45900.00,  2000.00,  7920.00,     0.00,  51820.00, '2025-09-19', '2025-09-18'),
(22, 22, '2025-09-28 09:00:00', 'Delivered', '41 Law Garden',           'Ahmedabad',          'Gujarat',       'India', '380006',    999.00,     0.00,   180.00,    49.00,   1228.00, '2025-10-02', '2025-10-01'),
(23, 23, '2025-10-10 15:00:00', 'Delivered', '6 Indiranagar',           'Bengaluru',          'Karnataka',     'India', '560038',   7999.00,   300.00,  1386.00,    99.00,   9184.00, '2025-10-14', '2025-10-13'),
(24, 24, '2025-10-20 12:30:00', 'Returned',  '30 Lajpat Nagar II',      'Delhi',              'Delhi',         'India', '110024',   1799.00,     0.00,   324.00,    99.00,   2222.00, '2025-10-24', '2025-10-23'),
(25, 25, '2025-10-30 10:00:00', 'Delivered', '14 Powai Lake Road',      'Mumbai',             'Maharashtra',   'India', '400076',  57000.00,  3000.00,  9720.00,     0.00,  63720.00, '2025-11-03', '2025-11-02'),

-- ── 2026 orders (26–60) ───────────────────────────────────────────────────
(26,  1, '2026-01-05 09:30:00', 'Delivered', '12 MG Road',              'Bengaluru',          'Karnataka',     'India', '560001',  24999.00,  1000.00,  4320.00,     0.00,  28319.00, '2026-01-09', '2026-01-08'),
(27,  4, '2026-01-18 14:00:00', 'Delivered', '22 FC Road',              'Pune',               'Maharashtra',   'India', '411004',  29999.00,  1500.00,  5130.00,     0.00,  33629.00, '2026-01-22', '2026-01-21'),
(28,  8, '2026-02-02 10:15:00', 'Delivered', '3 Besant Nagar Beach Rd', 'Chennai',            'Tamil Nadu',    'India', '600090',   7999.00,     0.00,  1440.00,     0.00,   9439.00, '2026-02-06', '2026-02-05'),
(29, 15, '2026-02-14 16:00:00', 'Delivered', '88 DLF Phase 3',          'Gurugram',           'Haryana',       'India', '122002',  64999.00,  3000.00, 11160.00,     0.00,  73159.00, '2026-02-18', '2026-02-17'),
(30,  9, '2026-02-25 11:30:00', 'Delivered', '19 Linking Road',         'Mumbai',             'Maharashtra',   'India', '400050',   4299.00,   100.00,   756.00,    99.00,   5054.00, '2026-03-01', '2026-02-28'),
(31, 21, '2026-03-10 13:00:00', 'Delivered', '25 Navrangpura',          'Ahmedabad',          'Gujarat',       'India', '380009', 109999.00,  6000.00, 18720.00,     0.00, 122719.00, '2026-03-14', '2026-03-13'),
(32, 29, '2026-03-22 09:45:00', 'Delivered', '7 Satellite Road',        'Ahmedabad',          'Gujarat',       'India', '380015',  10795.00,   500.00,  1854.00,    99.00,  12248.00, '2026-03-26', '2026-03-25'),
(33, 13, '2026-04-05 14:30:00', 'Delivered', '5 Stadium Circle',        'Rajkot',             'Gujarat',       'India', '360001',  29999.00,  1500.00,  5130.00,     0.00,  33629.00, '2026-04-09', '2026-04-08'),
(34,  2, '2026-04-18 10:00:00', 'Delivered', '45 Anna Salai',           'Chennai',            'Tamil Nadu',    'India', '600002',   3299.00,   100.00,   576.00,    99.00,   3874.00, '2026-04-22', '2026-04-21'),
(35, 25, '2026-04-30 15:45:00', 'Delivered', '14 Powai Lake Road',      'Mumbai',             'Maharashtra',   'India', '400076',  47990.00,  2000.00,  8280.00,     0.00,  54270.00, '2026-05-04', '2026-05-03'),
(36,  5, '2026-05-10 09:00:00', 'Delivered', '33 CG Road',              'Ahmedabad',          'Gujarat',       'India', '380009',  14999.00,   500.00,  2610.00,    99.00,  17208.00, '2026-05-14', '2026-05-13'),
(37,  1, '2026-05-22 11:30:00', 'Delivered', '12 MG Road',              'Bengaluru',          'Karnataka',     'India', '560001',   8999.00,     0.00,  1620.00,    99.00,  10718.00, '2026-05-26', '2026-05-25'),
(38, 30, '2026-05-30 16:00:00', 'Delivered', '38 T. Nagar',             'Chennai',            'Tamil Nadu',    'India', '600017',    499.00,     0.00,    90.00,    49.00,     638.00, '2026-06-03', '2026-06-02'),
(39, 19, '2026-06-08 14:00:00', 'Delivered', '18 Raja Park',            'Jaipur',             'Rajasthan',     'India', '302004',  24999.00,  1000.00,  4320.00,     0.00,  28319.00, '2026-06-12', '2026-06-11'),
(40,  4, '2026-06-20 10:30:00', 'Delivered', '22 FC Road',              'Pune',               'Maharashtra',   'India', '411004',   1999.00,     0.00,   360.00,    99.00,   2458.00, '2026-06-24', '2026-06-23'),
(41, 15, '2026-07-01 09:00:00', 'Delivered', '88 DLF Phase 3',          'Gurugram',           'Haryana',       'India', '122002',  54999.00,  2500.00,  9450.00,     0.00,  61949.00, '2026-07-05', '2026-07-04'),
(42,  8, '2026-07-14 13:30:00', 'Delivered', '3 Besant Nagar Beach Rd', 'Chennai',            'Tamil Nadu',    'India', '600090',  14999.00,   700.00,  2574.00,     0.00,  16873.00, '2026-07-18', '2026-07-17'),
(43, 26, '2026-07-25 11:00:00', 'Delivered', '55 Ashok Vihar',          'Delhi',              'Delhi',         'India', '110052',   1599.00,     0.00,   288.00,    99.00,   1986.00, '2026-07-29', '2026-07-28'),
(44, 21, '2026-08-05 15:00:00', 'Delivered', '25 Navrangpura',          'Ahmedabad',          'Gujarat',       'India', '380009',  29999.00,  1500.00,  5130.00,     0.00,  33629.00, '2026-08-09', '2026-08-08'),
(45,  9, '2026-08-18 10:45:00', 'Shipped',   '19 Linking Road',         'Mumbai',             'Maharashtra',   'India', '400050',   7999.00,   300.00,  1386.00,     0.00,   9085.00, '2026-08-22', NULL),
(46, 29, '2026-08-28 14:00:00', 'Delivered', '7 Satellite Road',        'Ahmedabad',          'Gujarat',       'India', '380015',   4299.00,     0.00,   774.00,    99.00,   5172.00, '2026-09-01', '2026-09-01'),
(47, 13, '2026-09-05 09:30:00', 'Delivered', '5 Stadium Circle',        'Rajkot',             'Gujarat',       'India', '360001',  57000.00,  3000.00,  9720.00,     0.00,  63720.00, '2026-09-09', '2026-09-08'),
(48,  2, '2026-09-20 15:30:00', 'Delivered', '45 Anna Salai',           'Chennai',            'Tamil Nadu',    'India', '600002',   4999.00,   200.00,   864.00,    99.00,   5762.00, '2026-09-24', '2026-09-23'),
(49, 25, '2026-09-30 11:00:00', 'Delivered', '14 Powai Lake Road',      'Mumbai',             'Maharashtra',   'India', '400076', 109999.00,  5000.00, 18900.00,     0.00, 123899.00, '2026-10-04', '2026-10-03'),
(50, 15, '2026-10-05 10:00:00', 'Shipped',   '88 DLF Phase 3',          'Gurugram',           'Haryana',       'India', '122002',  45900.00,  2000.00,  7920.00,     0.00,  51820.00, '2026-10-09', NULL),
(51, 23, '2026-10-12 14:00:00', 'Delivered', '6 Indiranagar',           'Bengaluru',          'Karnataka',     'India', '560038',  30999.00,  1500.00,  5346.00,     0.00,  34845.00, '2026-10-16', '2026-10-15'),
(52,  6, '2026-10-18 09:30:00', 'Processing','8 Jubilee Hills',          'Hyderabad',          'Telangana',     'India', '500033',  24999.00,  1000.00,  4320.00,    99.00,  28418.00, '2026-10-22', NULL),
(53, 16, '2026-10-25 13:00:00', 'Delivered', '15 Mansarovar',           'Jaipur',             'Rajasthan',     'India', '302020',    899.00,     0.00,   162.00,    49.00,   1110.00, '2026-10-29', '2026-10-28'),
(54, 20, '2026-10-28 16:45:00', 'Confirmed', '60 Vikas Nagar',          'Dehradun',           'Uttarakhand',   'India', '248001',  14999.00,   500.00,  2610.00,    99.00,  17208.00, '2026-11-01', NULL),
(55,  1, '2026-11-01 11:00:00', 'Confirmed', '12 MG Road',              'Bengaluru',          'Karnataka',     'India', '560001',  29999.00,  1500.00,  5130.00,     0.00,  33629.00, '2026-11-05', NULL),
(56, 21, '2026-11-02 14:30:00', 'Pending',   '25 Navrangpura',          'Ahmedabad',          'Gujarat',       'India', '380009',   7999.00,     0.00,  1440.00,    99.00,   9538.00, '2026-11-06', NULL),
(57, 28, '2026-11-03 10:00:00', 'Pending',   '10 Calicut Road',         'Kozhikode',          'Kerala',        'India', '673001',    499.00,     0.00,    90.00,    49.00,     638.00, '2026-11-07', NULL),
(58, 11, '2026-11-04 09:00:00', 'Pending',   '11 Salt Lake City',       'Kolkata',            'West Bengal',   'India', '700064',   1799.00,     0.00,   324.00,    99.00,   2222.00, '2026-11-08', NULL),
(59, 18, '2026-11-05 15:00:00', 'Pending',   '34 Khar West',            'Mumbai',             'Maharashtra',   'India', '400052',   3299.00,   100.00,   576.00,    99.00,   3874.00, '2026-11-09', NULL),
(60, 30, '2026-11-07 11:30:00', 'Pending',   '38 T. Nagar',             'Chennai',            'Tamil Nadu',    'India', '600017',  10795.00,   500.00,  1854.00,    99.00,  12248.00, '2026-11-11', NULL);


-- =============================================================================
-- 5. ORDER ITEMS  (110 rows)
-- line_total = ROUND(quantity * unit_price * (1 - discount_pct / 100), 2)
-- =============================================================================
INSERT INTO order_items
  (order_item_id, order_id, product_id, quantity, unit_price, discount_pct, line_total)
VALUES
-- Order 1  — customer 1 | Electronics (Samsung S23 Ultra + AirPods Pro)
( 1,  1,  1, 1, 109999.00, 4.55, 104999.00),  -- Samsung Galaxy S23 Ultra
( 2,  1,  7, 1,  24999.00, 0.00,  24999.00),  -- Apple AirPods Pro 2nd Gen

-- Order 2  — customer 2 | Electronics + Books
( 3,  2,  9, 1,  54999.00, 4.55,  52499.00),  -- Canon EOS R50
( 4,  2, 21, 2,    499.00, 0.00,    998.00),  -- Atomic Habits x2

-- Order 3  — customer 3 | Electronics
( 5,  3, 10, 1,   7999.00, 0.00,   7999.00),  -- Logitech MX Master 3S

-- Order 4  — customer 4 | Home & Kitchen
( 6,  4, 17, 1,  47990.00, 4.17,  45990.00),  -- Dyson V12 Detect Slim

-- Order 5  — customer 5 | Clothing
( 7,  5, 14, 1,  10795.00, 4.63,  10295.00),  -- Nike Air Zoom Pegasus 40

-- Order 6  — customer 6 | Clothing
( 8,  6, 11, 1,   4299.00, 4.65,   4099.00),  -- Levi's 511 Slim Fit Jeans

-- Order 7  — customer 7 | Clothing
( 9,  7, 12, 1,   1599.00, 0.00,   1599.00),  -- Peter England Formal Shirt

-- Order 8  — customer 8 | Electronics (iPhone 15 Pro + 2x Logitech Mouse)
(10,  8,  2, 1, 129999.00, 5.38, 122999.00),  -- Apple iPhone 15 Pro
(11,  8, 10, 2,   7999.00, 0.00,  15998.00),  -- Logitech MX Master 3S x2

-- Order 9  — customer 9 | Electronics + Beauty
(12,  9,  6, 1,  29999.00, 5.00,  28499.00),  -- Sony WH-1000XM5
(13,  9, 31, 1,    899.00, 0.00,    899.00),  -- L'Oréal Revitalift Serum

-- Order 10 — customer 10 | Clothing + Beauty
(14, 10, 13, 1,   3299.00, 3.03,   3199.00),  -- Fabindia Kurta Set
(15, 10, 33, 2,    299.00, 0.00,    598.00),  -- Mamaearth FaceWash x2

-- Order 11 — customer 11 | Toys + Books
(16, 11, 37, 1,    899.00, 0.00,    899.00),  -- Funskool Monopoly
(17, 11, 22, 1,    399.00, 0.00,    399.00),  -- The Psychology of Money

-- Order 12 — customer 12 | Books + Stationery
(18, 12, 24, 1,   1299.00, 0.00,   1299.00),  -- Moleskine Classic Notebook
(19, 12, 23, 1,    499.00, 0.00,    499.00),  -- Staedtler Mars Pencil Set

-- Order 13 — customer 13 | Electronics + Grocery
(20, 13,  3, 1,  24999.00, 4.00,  23999.00),  -- OnePlus Nord CE 3
(21, 13, 43, 3,    199.00, 0.00,    597.00),  -- Amul Dark Chocolate x3

-- Order 14 — customer 14 | Sports
(22, 14, 26, 1,   4999.00, 4.00,   4799.00),  -- Decathlon Dumbbell Set
(23, 14, 28, 1,    899.00, 0.00,    899.00),  -- Boldfit Yoga Mat

-- Order 15 — customer 15 | Electronics + Audio
(24, 15,  4, 1, 149999.00, 5.33, 141999.00),  -- Dell XPS 15 Laptop
(25, 15,  6, 1,  29999.00, 0.00,  29999.00),  -- Sony WH-1000XM5

-- Order 16 — customer 16 | Books + Stationery
(26, 16, 21, 1,    499.00, 0.00,    499.00),  -- Atomic Habits
(27, 16, 25, 1,    999.00, 0.00,    999.00),  -- Parker Jotter Ballpen Set

-- Order 17 — customer 17 | Books
(28, 17, 24, 1,   1299.00, 0.00,   1299.00),  -- Moleskine Classic Notebook

-- Order 18 — customer 18 | Electronics + Grocery
(29, 18,  8, 1,  79999.00, 5.00,  75999.00),  -- Samsung QLED 4K TV
(30, 18, 42, 3,    399.00, 0.00,   1197.00),  -- Nescafé Classic x3

-- Order 19 — customer 19 | Sports + Stationery
(31, 19, 29, 1,  30999.00, 4.84,  29499.00),  -- Garmin Forerunner 255
(32, 19, 23, 1,    499.00, 0.00,    499.00),  -- Staedtler Mars Pencil Set

-- Order 20 — customer 20 | Home + Grocery
(33, 20, 20, 1,  14999.00, 3.33,  14499.00),  -- Philips Air Purifier
(34, 20, 42, 2,    399.00, 0.00,    798.00),  -- Nescafé Classic x2

-- Order 21 — customer 21 | Beauty + Books
(35, 21, 32, 1,  45900.00, 4.36,  43900.00),  -- Dyson Airwrap Complete
(36, 21, 21, 1,    499.00, 0.00,    499.00),  -- Atomic Habits

-- Order 22 — customer 22 | Stationery + Grocery
(37, 22, 25, 1,    999.00, 0.00,    999.00),  -- Parker Jotter Ballpen Set
(38, 22, 41, 5,     45.00, 0.00,    225.00),  -- Tata Salt Lite x5

-- Order 23 — customer 23 | Electronics + Grocery
(39, 23, 10, 1,   7999.00, 3.75,   7699.00),  -- Logitech MX Master 3S
(40, 23, 42, 2,    399.00, 0.00,    798.00),  -- Nescafé Classic x2

-- Order 24 — customer 24 | Toys (Returned)
(41, 24, 39, 1,   1799.00, 0.00,   1799.00),  -- Play-Doh 36-Can Mega Set

-- Order 25 — customer 25 | Jewellery (Gold Chain + Diamond Ring)
(42, 25, 46, 1,  57000.00, 5.26,  54000.00),  -- 22KT Gold Chain 10 g
(43, 25, 48, 1,  29999.00, 0.00,  29999.00),  -- Diamond Solitaire Ring

-- Order 26 — customer 1 | Electronics + Beauty
(44, 26,  3, 1,  24999.00, 4.00,  23999.00),  -- OnePlus Nord CE 3
(45, 26, 31, 1,    899.00, 0.00,    899.00),  -- L'Oréal Revitalift Serum

-- Order 27 — customer 4 | Electronics + Books
(46, 27,  6, 1,  29999.00, 5.00,  28499.00),  -- Sony WH-1000XM5
(47, 27, 24, 1,   1299.00, 0.00,   1299.00),  -- Moleskine Classic Notebook

-- Order 28 — customer 8 | Electronics
(48, 28, 10, 1,   7999.00, 0.00,   7999.00),  -- Logitech MX Master 3S

-- Order 29 — customer 15 | Electronics
(49, 29,  5, 1,  64999.00, 4.62,  61999.00),  -- HP Pavilion x360

-- Order 30 — customer 9 | Clothing + Books
(50, 30, 11, 1,   4299.00, 2.33,   4199.00),  -- Levi's 511 Slim Fit Jeans
(51, 30, 22, 1,    399.00, 0.00,    399.00),  -- The Psychology of Money

-- Order 31 — customer 21 | Electronics (Samsung + AirPods)
(52, 31,  1, 1, 109999.00, 5.45, 103999.00),  -- Samsung Galaxy S23 Ultra
(53, 31,  7, 1,  24999.00, 0.00,  24999.00),  -- Apple AirPods Pro 2nd Gen

-- Order 32 — customer 29 | Clothing + Grocery
(54, 32, 14, 1,  10795.00, 4.63,  10295.00),  -- Nike Air Zoom Pegasus 40
(55, 32, 43, 3,    199.00, 0.00,    597.00),  -- Amul Dark Chocolate x3

-- Order 33 — customer 13 | Electronics + Books
(56, 33,  6, 1,  29999.00, 5.00,  28499.00),  -- Sony WH-1000XM5
(57, 33, 21, 1,    499.00, 0.00,    499.00),  -- Atomic Habits

-- Order 34 — customer 2 | Clothing + Beauty
(58, 34, 13, 1,   3299.00, 3.03,   3199.00),  -- Fabindia Kurta Set
(59, 34, 31, 1,    899.00, 0.00,    899.00),  -- L'Oréal Revitalift Serum

-- Order 35 — customer 25 | Home & Kitchen
(60, 35, 17, 1,  47990.00, 4.17,  45990.00),  -- Dyson V12 Detect Slim

-- Order 36 — customer 5 | Home + Sports
(61, 36, 20, 1,  14999.00, 3.33,  14499.00),  -- Philips Air Purifier
(62, 36, 28, 2,    899.00, 0.00,   1798.00),  -- Boldfit Yoga Mat x2

-- Order 37 — customer 1 | Automotive
(63, 37, 52, 1,   8999.00, 0.00,   8999.00),  -- Michelin Pilot Sport 4 Tyre
(64, 37, 51, 1,   5499.00, 0.00,   5499.00),  -- Bosch Car Battery 55 Ah

-- Order 38 — customer 30 | Books + Grocery
(65, 38, 21, 1,    499.00, 0.00,    499.00),  -- Atomic Habits
(66, 38, 43, 2,    199.00, 0.00,    398.00),  -- Amul Dark Chocolate x2

-- Order 39 — customer 19 | Electronics + Books
(67, 39,  3, 1,  24999.00, 4.00,  23999.00),  -- OnePlus Nord CE 3
(68, 39, 22, 1,    399.00, 0.00,    399.00),  -- The Psychology of Money

-- Order 40 — customer 4 | Clothing + Beauty
(69, 40, 15, 1,   1999.00, 0.00,   1999.00),  -- H&M Oversized Hoodie
(70, 40, 33, 2,    299.00, 0.00,    598.00),  -- Mamaearth FaceWash x2

-- Order 41 — customer 15 | Electronics
(71, 41,  9, 1,  54999.00, 4.55,  52499.00),  -- Canon EOS R50

-- Order 42 — customer 8 | Home + Beauty
(72, 42, 20, 1,  14999.00, 4.67,  14299.00),  -- Philips Air Purifier
(73, 42, 35, 2,   1099.00, 0.00,   2198.00),  -- Gillette Fusion ProShield x2

-- Order 43 — customer 26 | Clothing + Books
(74, 43, 12, 1,   1599.00, 0.00,   1599.00),  -- Peter England Formal Shirt
(75, 43, 23, 1,    499.00, 0.00,    499.00),  -- Staedtler Mars Pencil Set

-- Order 44 — customer 21 | Electronics + Books
(76, 44,  6, 1,  29999.00, 5.00,  28499.00),  -- Sony WH-1000XM5
(77, 44, 24, 1,   1299.00, 0.00,   1299.00),  -- Moleskine Classic Notebook

-- Order 45 — customer 9 | Electronics
(78, 45, 10, 1,   7999.00, 3.75,   7699.00),  -- Logitech MX Master 3S

-- Order 46 — customer 29 | Clothing
(79, 46, 11, 1,   4299.00, 0.00,   4299.00),  -- Levi's 511 Slim Fit Jeans
(80, 46, 15, 1,   1999.00, 0.00,   1999.00),  -- H&M Oversized Hoodie

-- Order 47 — customer 13 | Jewellery
(81, 47, 46, 1,  57000.00, 5.26,  54000.00),  -- 22KT Gold Chain 10 g

-- Order 48 — customer 2 | Sports
(82, 48, 26, 1,   4999.00, 4.00,   4799.00),  -- Decathlon Dumbbell Set
(83, 48, 28, 1,    899.00, 0.00,    899.00),  -- Boldfit Yoga Mat

-- Order 49 — customer 25 | Electronics (Samsung + AirPods)
(84, 49,  1, 1, 109999.00, 4.55, 104999.00),  -- Samsung Galaxy S23 Ultra
(85, 49,  7, 1,  24999.00, 0.00,  24999.00),  -- Apple AirPods Pro 2nd Gen

-- Order 50 — customer 15 | Beauty
(86, 50, 32, 1,  45900.00, 4.36,  43900.00),  -- Dyson Airwrap Complete
(87, 50, 31, 1,    899.00, 0.00,    899.00),  -- L'Oréal Revitalift Serum

-- Order 51 — customer 23 | Sports + Books
(88, 51, 29, 1,  30999.00, 4.84,  29499.00),  -- Garmin Forerunner 255
(89, 51, 22, 1,    399.00, 0.00,    399.00),  -- The Psychology of Money

-- Order 52 — customer 6 | Electronics + Beauty
(90, 52,  3, 1,  24999.00, 4.00,  23999.00),  -- OnePlus Nord CE 3
(91, 52, 33, 2,    299.00, 0.00,    598.00),  -- Mamaearth FaceWash x2

-- Order 53 — customer 16 | Beauty
(92, 53, 33, 3,    299.00, 0.00,    897.00),  -- Mamaearth FaceWash x3
(93, 53, 34, 2,    299.00, 0.00,    598.00),  -- Biotique Bio Almond Scrub x2

-- Order 54 — customer 20 | Home + Grocery
(94, 54, 20, 1,  14999.00, 3.33,  14499.00),  -- Philips Air Purifier
(95, 54, 45, 2,    299.00, 0.00,    598.00),  -- Bagrry's Rolled Oats x2

-- Order 55 — customer 1 | Electronics + Books
(96, 55,  6, 1,  29999.00, 5.00,  28499.00),  -- Sony WH-1000XM5
(97, 55, 21, 1,    499.00, 0.00,    499.00),  -- Atomic Habits

-- Order 56 — customer 21 | Electronics + Grocery
(98, 56, 10, 1,   7999.00, 0.00,   7999.00),  -- Logitech MX Master 3S
(99, 56, 42, 1,    399.00, 0.00,    399.00),  -- Nescafé Classic

-- Order 57 — customer 28 | Books + Grocery + Sports
(100,57, 22, 1,    399.00, 0.00,    399.00),  -- The Psychology of Money
(101,57, 41, 2,     45.00, 0.00,     90.00),  -- Tata Salt Lite x2
(102,57, 30, 1,   1199.00, 0.00,   1199.00),  -- Nivia Football Size 5

-- Order 58 — customer 11 | Toys + Books
(103,58, 39, 1,   1799.00, 0.00,   1799.00),  -- Play-Doh 36-Can Mega Set
(104,58, 40, 1,    499.00, 0.00,    499.00),  -- Rubik's Cube 3×3

-- Order 59 — customer 18 | Clothing + Beauty
(105,59, 13, 1,   3299.00, 3.03,   3199.00),  -- Fabindia Kurta Set
(106,59, 31, 1,    899.00, 0.00,    899.00),  -- L'Oréal Revitalift Serum

-- Order 60 — customer 30 | Clothing + Grocery
(107,60, 14, 1,  10795.00, 4.63,  10295.00),  -- Nike Air Zoom Pegasus 40
(108,60, 44, 1,    799.00, 0.00,    799.00),  -- Fortune Sunflower Oil 5 L

-- ── Extra items to reach 110 total ───────────────────────────────────────
(109,47, 50, 1,   3999.00, 0.00,   3999.00),  -- Pearl Pendant Necklace (order 47 add-on)
(110,25, 47, 2,    999.00, 0.00,   1998.00);  -- Sterling Silver Earrings x2 (order 25 add-on)


-- =============================================================================
-- 6. PAYMENTS  (65 rows — one primary + split/EMI/refund rows)
-- =============================================================================
INSERT INTO payments
  (payment_id, order_id, payment_date, method, amount, currency, status, transaction_ref, gateway)
VALUES
-- ── Orders 1–25 (primary payments) ───────────────────────────────────────
( 1,  1, '2025-01-10 10:35:00', 'Credit Card',      123899.00, 'INR', 'Captured',           'TXN2501101001', 'Razorpay'),
( 2,  2, '2025-01-18 14:05:00', 'UPI',               61949.00, 'INR', 'Captured',           'TXN2501181401', 'Razorpay'),
( 3,  3, '2025-02-05 09:20:00', 'Debit Card',         9538.00, 'INR', 'Captured',           'TXN2502050901', 'PayU'),
( 4,  4, '2025-02-20 16:50:00', 'Net Banking',       54270.00, 'INR', 'Captured',           'TXN2502201601', 'HDFC'),
( 5,  5, '2025-03-01 11:05:00', 'UPI',               12248.00, 'INR', 'Captured',           'TXN2503011101', 'PhonePe'),
( 6,  6, '2025-03-15 13:35:00', 'Cash on Delivery',   4936.00, 'INR', 'Captured',           NULL,            NULL),
( 7,  7, '2025-03-22 08:05:00', 'Cash on Delivery',   1986.00, 'INR', 'Captured',           NULL,            NULL),
( 8,  8, '2025-04-10 17:25:00', 'EMI',              145319.00, 'INR', 'Captured',           'TXN2504101701', 'Razorpay'),
( 9,  9, '2025-04-25 12:15:00', 'Credit Card',       33629.00, 'INR', 'Captured',           'TXN2504251201', 'Paytm'),
(10, 10, '2025-05-05 09:50:00', 'UPI',                3874.00, 'INR', 'Captured',           'TXN2505050901', 'GPay'),
(11, 11, '2025-05-18 15:35:00', 'Cash on Delivery',   1110.00, 'INR', 'Captured',           NULL,            NULL),
(12, 12, '2025-05-27 11:05:00', 'UPI',                1632.00, 'INR', 'Captured',           'TXN2505271101', 'PhonePe'),
(13, 13, '2025-06-04 10:05:00', 'Credit Card',       28319.00, 'INR', 'Captured',           'TXN2506041001', 'Razorpay'),
(14, 14, '2025-06-19 14:35:00', 'UPI',                5762.00, 'INR', 'Captured',           'TXN2506191401', 'GPay'),
(15, 15, '2025-07-01 09:05:00', 'EMI',              167919.00, 'INR', 'Captured',           'TXN2507010901', 'Bajaj Finance'),
(16, 16, '2025-07-14 11:50:00', 'UPI',                  638.00,'INR', 'Captured',           'TXN2507141101', 'PhonePe'),
(17, 17, '2025-07-28 13:20:00', 'Cash on Delivery',   1632.00, 'INR', 'Captured',           NULL,            NULL),
(18, 18, '2025-08-10 16:05:00', 'EMI',               89679.00, 'INR', 'Captured',           'TXN2508101601', 'Razorpay'),
(19, 19, '2025-08-20 10:35:00', 'Credit Card',       34845.00, 'INR', 'Captured',           'TXN2508201001', 'Razorpay'),
(20, 20, '2025-09-05 14:05:00', 'Net Banking',       17208.00, 'INR', 'Captured',           'TXN2509051401', 'SBI'),
(21, 21, '2025-09-15 11:35:00', 'Credit Card',       51820.00, 'INR', 'Captured',           'TXN2509151101', 'ICICI'),
(22, 22, '2025-09-28 09:05:00', 'UPI',                1228.00, 'INR', 'Captured',           'TXN2509280901', 'GPay'),
(23, 23, '2025-10-10 15:05:00', 'Debit Card',         9184.00, 'INR', 'Captured',           'TXN2510101501', 'PayU'),
(24, 24, '2025-10-20 12:35:00', 'Cash on Delivery',   2222.00, 'INR', 'Refunded',           NULL,            NULL),
(25, 25, '2025-10-30 10:05:00', 'Credit Card',       63720.00, 'INR', 'Captured',           'TXN2510301001', 'Razorpay'),

-- ── Orders 26–60 (primary payments) ───────────────────────────────────────
(26, 26, '2026-01-05 09:35:00', 'UPI',               28319.00, 'INR', 'Captured',           'TXN2601050901', 'PhonePe'),
(27, 27, '2026-01-18 14:05:00', 'Credit Card',       33629.00, 'INR', 'Captured',           'TXN2601181401', 'Razorpay'),
(28, 28, '2026-02-02 10:20:00', 'UPI',                9439.00, 'INR', 'Captured',           'TXN2602021001', 'GPay'),
(29, 29, '2026-02-14 16:05:00', 'EMI',               73159.00, 'INR', 'Captured',           'TXN2602141601', 'Bajaj Finance'),
(30, 30, '2026-02-25 11:35:00', 'Cash on Delivery',   5054.00, 'INR', 'Captured',           NULL,            NULL),
(31, 31, '2026-03-10 13:05:00', 'Credit Card',      122719.00, 'INR', 'Captured',           'TXN2603101301', 'HDFC'),
(32, 32, '2026-03-22 09:50:00', 'UPI',               12248.00, 'INR', 'Captured',           'TXN2603220901', 'GPay'),
(33, 33, '2026-04-05 14:35:00', 'Debit Card',        33629.00, 'INR', 'Captured',           'TXN2604051401', 'PayU'),
(34, 34, '2026-04-18 10:05:00', 'Cash on Delivery',   3874.00, 'INR', 'Captured',           NULL,            NULL),
(35, 35, '2026-04-30 15:50:00', 'Net Banking',       54270.00, 'INR', 'Captured',           'TXN2604301501', 'HDFC'),
(36, 36, '2026-05-10 09:05:00', 'UPI',               17208.00, 'INR', 'Captured',           'TXN2605100901', 'PhonePe'),
(37, 37, '2026-05-22 11:35:00', 'Cash on Delivery',  10718.00, 'INR', 'Captured',           NULL,            NULL),
(38, 38, '2026-05-30 16:05:00', 'UPI',                  638.00,'INR', 'Captured',           'TXN2605301601', 'GPay'),
(39, 39, '2026-06-08 14:05:00', 'Credit Card',       28319.00, 'INR', 'Captured',           'TXN2606081401', 'Razorpay'),
(40, 40, '2026-06-20 10:35:00', 'Cash on Delivery',   2458.00, 'INR', 'Captured',           NULL,            NULL),
(41, 41, '2026-07-01 09:05:00', 'EMI',               61949.00, 'INR', 'Captured',           'TXN2607010901', 'Bajaj Finance'),
(42, 42, '2026-07-14 13:35:00', 'UPI',               16873.00, 'INR', 'Captured',           'TXN2607141301', 'PhonePe'),
(43, 43, '2026-07-25 11:05:00', 'Cash on Delivery',   1986.00, 'INR', 'Captured',           NULL,            NULL),
(44, 44, '2026-08-05 15:05:00', 'Credit Card',       33629.00, 'INR', 'Captured',           'TXN2608051501', 'ICICI'),
(45, 45, '2026-08-18 10:50:00', 'UPI',                9085.00, 'INR', 'Authorized',         'TXN2608181001', 'GPay'),
(46, 46, '2026-08-28 14:05:00', 'Cash on Delivery',   5172.00, 'INR', 'Captured',           NULL,            NULL),
(47, 47, '2026-09-05 09:35:00', 'Credit Card',       63720.00, 'INR', 'Captured',           'TXN2609050901', 'Razorpay'),
(48, 48, '2026-09-20 15:35:00', 'UPI',                5762.00, 'INR', 'Captured',           'TXN2609201501', 'PhonePe'),
(49, 49, '2026-09-30 11:05:00', 'EMI',              123899.00, 'INR', 'Captured',           'TXN2609301101', 'Bajaj Finance'),
(50, 50, '2026-10-05 10:05:00', 'Credit Card',       51820.00, 'INR', 'Authorized',         'TXN2610051001', 'HDFC'),
(51, 51, '2026-10-12 14:05:00', 'Net Banking',       34845.00, 'INR', 'Captured',           'TXN2610121401', 'SBI'),
(52, 52, '2026-10-18 09:35:00', 'UPI',               28418.00, 'INR', 'Authorized',         'TXN2610180901', 'GPay'),
(53, 53, '2026-10-25 13:05:00', 'Cash on Delivery',   1110.00, 'INR', 'Captured',           NULL,            NULL),
(54, 54, '2026-10-28 16:50:00', 'UPI',               17208.00, 'INR', 'Authorized',         'TXN2610281601', 'PhonePe'),
(55, 55, '2026-11-01 11:05:00', 'Credit Card',       33629.00, 'INR', 'Authorized',         'TXN2611011101', 'Razorpay'),
(56, 56, '2026-11-02 14:35:00', 'UPI',                9538.00, 'INR', 'Pending',            'TXN2611021401', 'GPay'),
(57, 57, '2026-11-03 10:05:00', 'Cash on Delivery',     638.00,'INR', 'Pending',            NULL,            NULL),
(58, 58, '2026-11-04 09:05:00', 'Cash on Delivery',   2222.00, 'INR', 'Pending',            NULL,            NULL),
(59, 59, '2026-11-05 15:05:00', 'UPI',                3874.00, 'INR', 'Pending',            'TXN2611051501', 'PhonePe'),
(60, 60, '2026-11-07 11:35:00', 'Credit Card',       12248.00, 'INR', 'Pending',            'TXN2611071101', 'Razorpay'),

-- ── Supplemental: EMI instalments & refund rows ───────────────────────────
(61,  8, '2025-05-10 10:00:00', 'EMI',           12109.92, 'INR', 'Captured',   'TXN2505101001', 'Razorpay'),       -- Order 8  — instalment 2
(62, 15, '2025-08-01 09:00:00', 'EMI',           13993.25, 'INR', 'Captured',   'TXN2508010901', 'Bajaj Finance'),  -- Order 15 — instalment 2
(63, 49, '2026-10-30 11:00:00', 'EMI',           10324.92, 'INR', 'Captured',   'TXN2610301101', 'Bajaj Finance'),  -- Order 49 — instalment 2
(64, 24, '2025-10-28 14:00:00', 'Credit Card',    2222.00, 'INR', 'Refunded',   'TXN2510281401', 'Razorpay'),       -- Refund for returned order 24
(65, 29, '2026-03-14 10:00:00', 'EMI',            6096.58, 'INR', 'Captured',   'TXN2603141001', 'Bajaj Finance');  -- Order 29 — instalment 2


-- ---------------------------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 1;
-- ---------------------------------------------------------------------------

-- =============================================================================
-- DATA SUMMARY
-- =============================================================================
-- Table          Rows   Notes
-- ─────────────────────────────────────────────────────────────────────────────
-- categories      10    One per product category
-- products        55    5+ per category (10 Electronics SKUs for variety)
-- customers       30    Diverse cities, segments (New→Platinum), genders, ages
-- orders          60    Jan 2025 – Nov 2026; statuses: Pending→Delivered+Returned
-- order_items    110    Single- and multi-item orders; covers all categories
-- payments        65    7 methods; EMI split & refund rows included
-- =============================================================================
