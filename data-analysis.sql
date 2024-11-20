SELECT * FROM issued_status;


----------------------------------------------------------
-- CRUD OPERATIONS
----------------------------------------------------------
-- 1. INSERT NEW RECORD  "'978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher) VALUES (
	'978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.'
)

-- 2. UPDATE AN EXISTING MEMBERS ADDRESS - c101's address to 125 main st
UPDATE members
SET member_address='125 Main St'
WHERE member_id='C101';

--3 . Delete the record with issued_id = 'IS121' from the issued_status table.
DELETE FROM issued_status WHERE issued_id='IS121';

--4. Select all books issued by the employee with emp_id = 'E101'.
SELECT *
FROM issued_status
WHERE issued_emp_id='E101';

--5.  List Members Who Have Issued More Than One Book
SELECT DISTINCT issued_member_id
FROM issued_status
GROUP BY issued_member_id
HAVING COUNT(*)>1;

-- CTAS - Use CTAS to generate new tables based on query results - each book and number of times it has been issued
CREATE TABLE books_cnts AS
SELECT b.isbn, b.book_title, COUNT(i.issued_book_name) AS issue_count
FROM books b
LEFT JOIN issued_status i ON b.isbn=i.issued_book_isbn
GROUP BY b.isbn;


---------------------------------------------------------------------
-- DATA ANALYSIS
---------------------------------------------
-- Retrieve books from a specific category
SELECT *
FROM books
WHERE category='Classic';

-- Find Total Rental Income by Category:
SELECT b.category, SUM(b.rental_price) AS total_rental
FROM books b
JOIN issued_status i ON b.isbn=i.issued_book_isbn
GROUP BY 1;

-- List Members Who Registered in the Last 180 Days:
SELECT *
FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 Days'


-- List Employees with Their Branch Manager's Name and their branch details:
SELECT e.emp_id, e.emp_name, b.branch_id, e2.emp_name AS branch_manager, b.branch_address
FROM employees e
JOIN branch b ON e.branch_id=b.branch_id
JOIN employees e2 ON b.manager_id=e2.emp_id

--  Create a Table of Books with Rental Price Above a Certain Threshold, 7:
CREATE TABLE expensive_books AS
SELECT *
FROM books
WHERE rental_price > 7.00

-- Retrieve the List of Books Not Yet Returned
SELECT i.*
FROM issued_status i
LEFT JOIN return_status r ON r.issued_id=i.issued_id
WHERE r.issued_id IS NULL
