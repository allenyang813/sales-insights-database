-- CustomerType table
CREATE TABLE CustomerType (
    customerTypeID INT PRIMARY KEY,
    customerTypeName VARCHAR(45) NOT NULL,
    customerTypeDescription TEXT
);

-- Customer table
CREATE TABLE Customer (
    customerID INT PRIMARY KEY,
    customerName VARCHAR(300) NOT NULL,
    contactName VARCHAR(300),
    customerPhoneNumber VARCHAR(20),
    customerAddress VARCHAR(500),
    customerTypeID INT NOT NULL,
    FOREIGN KEY (customerTypeID) REFERENCES CustomerType(customerTypeID)
);

-- StaffMember table
CREATE TABLE StaffMember (
    staffID INT PRIMARY KEY,
    staffName VARCHAR(300) NOT NULL,
    staffRole VARCHAR(30) NOT NULL,
    staffCurrentEmployeeType VARCHAR(20) NOT NULL
);

-- Order table
CREATE TABLE `Order` (
    orderID INT PRIMARY KEY,
    orderDate DATE NOT NULL,
    orderTime TIME NOT NULL,
    orderDeliveryInstructions TEXT,
    customerID INT NOT NULL,
    createdByStaffID INT NOT NULL,
    FOREIGN KEY (customerID) REFERENCES Customer(customerID),
    FOREIGN KEY (createdByStaffID) REFERENCES StaffMember(staffID)
);

-- OrderItem table (composite PK)
CREATE TABLE OrderItem (
    orderID INT NOT NULL,
    itemSequenceNumber INT NOT NULL,
    quantity INT NOT NULL,
    salePricePerItem DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (orderID, itemSequenceNumber),
    FOREIGN KEY (orderID) REFERENCES `Order`(orderID)
);

-- Payment table
CREATE TABLE Payment (
    paymentID INT PRIMARY KEY,
    paymentAmount DECIMAL(10,2) NOT NULL,
    paymentDateTime DATETIME NOT NULL,
    paymentMethod VARCHAR(20) NOT NULL,
    paymentSystemReferenceNumber VARCHAR(256)
);

-- PaymentPortion table (associative entity for Order–Payment)
CREATE TABLE PaymentPortion (
    paymentID INT NOT NULL,
    orderID INT NOT NULL,
    paymentPortionAmount DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (paymentID, orderID),
    FOREIGN KEY (paymentID) REFERENCES Payment(paymentID),
    FOREIGN KEY (orderID) REFERENCES `Order`(orderID)
);

-- Customer Types
INSERT INTO CustomerType VALUES 
(1, 'Individual', 'Private person purchasing furniture'),
(2, 'Company', 'Corporate client making bulk orders'),
(3, 'Other', 'Other entity type (assistant, group, etc.)');

-- Customers
INSERT INTO Customer VALUES 
(101, 'Alice Brown', 'Alice Brown', '0412345678', '12 Main St, Sydney', 1),
(102, 'Green Office Supplies', 'John Green', '0298765432', '34 George St, Sydney', 2),
(103, 'Tom Lee', 'Tom Lee', '0412555666', '55 King St, Sydney', 1);

-- Staff Members
INSERT INTO StaffMember VALUES 
(201, 'Mary Smith', 'Sales Rep', 'Full-time'),
(202, 'James White', 'Manager', 'Part-time');

-- Orders
INSERT INTO `Order` VALUES 
(301, '2025-09-10', '14:00:00', 'Leave at front door', 101, 201),
(302, '2025-09-12', '10:30:00', 'Deliver to reception', 102, 202),
(303, '2025-09-13', '09:00:00', 'Ring bell on arrival', 103, 201);

-- Order Items
INSERT INTO OrderItem VALUES 
(301, 1, 1, 799.99),   -- 1 Oak Dining Table
(301, 2, 4, 99.99),   -- 4 Dining Chairs
(302, 1, 2, 299.00),  -- 2 Office Desks
(303, 1, 1, 450.00);  -- 1 Couch

-- Payments
INSERT INTO Payment VALUES 
(401, 500.00, '2025-09-10 14:30:00', 'Credit Card', 'CC123'),
(402, 1199.00, '2025-09-12 11:00:00', 'PayPal', 'PP456'),
(403, 450.00, '2025-09-13 09:15:00', 'Bank Transfer', 'BT789');

-- Payment Portions (split/join payments to orders)
INSERT INTO PaymentPortion VALUES 
(401, 301, 500.00),   -- Payment 401 covers part of Order 301
(402, 302, 1199.00),  -- Payment 402 fully covers Order 302
(403, 303, 450.00);   -- Payment 403 fully covers Order 303

-- Query 1
SELECT customerID, customerName, customerPhoneNumber, customerAddress
FROM Customer
WHERE customerName LIKE '%a%' OR customerName LIKE '%z%'
ORDER BY customerName DESC;

-- Query 2
SELECT c.customerID, c.customerName, MIN(o.orderDate) AS firstOrderDate
FROM Customer c
LEFT JOIN `Order` o ON c.customerID = o.customerID
GROUP BY c.customerID, c.customerName;

-- Query 3
SELECT o.orderID, o.orderDate, o.orderTime, c.customerName, c.contactName,
       SUM(oi.quantity * oi.salePricePerItem) AS totalOrderAmount
FROM `Order` o
JOIN Customer c ON o.customerID = c.customerID
JOIN OrderItem oi ON o.orderID = oi.orderID
GROUP BY o.orderID, o.orderDate, o.orderTime, c.customerName, c.contactName
ORDER BY o.orderDate ASC, o.customerID DESC;

-- Query 4
SELECT o.orderID, 
       COALESCE(SUM(pp.paymentPortionAmount), 0) AS totalPaid
FROM `Order` o
LEFT JOIN PaymentPortion pp ON o.orderID = pp.orderID
GROUP BY o.orderID;

-- Query 5
SELECT s.staffID, s.staffName,
       y.year,
       COALESCE(COUNT(o.orderID), 0) AS numberOfOrders
FROM StaffMember s
CROSS JOIN (
    SELECT 2021 AS year UNION
    SELECT 2022 UNION
    SELECT 2023 UNION
    SELECT 2024 UNION
    SELECT 2025
) y
LEFT JOIN `Order` o 
    ON s.staffID = o.createdByStaffID 
   AND YEAR(o.orderDate) = y.year
GROUP BY s.staffID, s.staffName, y.year
ORDER BY s.staffID, y.year;

-- Query 6
SELECT o.orderID,
       SUM(oi.quantity * oi.salePricePerItem) AS totalOrderAmount,
       COALESCE(SUM(pp.paymentPortionAmount), 0) AS totalPaid,
       SUM(oi.quantity * oi.salePricePerItem) 
         - COALESCE(SUM(pp.paymentPortionAmount), 0) AS totalOwing
FROM `Order` o
JOIN OrderItem oi ON o.orderID = oi.orderID
LEFT JOIN PaymentPortion pp ON o.orderID = pp.orderID
GROUP BY o.orderID;

