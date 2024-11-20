# Library Management System
This project demonstrates the implementation of a Library Management System using SQL. It includes creating and managing tables, performing CRUD operations, and executing advanced SQL queries. The goal is to showcase skills in database design, manipulation, and querying.

## Objectives

1. **Set up the Library Management System Database**: Create and populate the database with tables for branches, employees, members, books, issued status, and return status.
2. **CRUD Operations**: Perform Create, Read, Update, and Delete operations on the data.
3. **CTAS (Create Table As Select)**: Utilize CTAS to create new tables based on query results.
4. **Advanced SQL Queries**: Develop complex queries to analyze and retrieve specific data.

## Project Structure

### 1. Database Setup
![ERD](https://github.com/abhikmp/Library-Mgmt-System/blob/main/library_erd.png)

- **Database Creation**: Created a database named `library_db`.
- **Table Creation**: Created tables for branches, employees, members, books, issued status, and return status. Each table includes relevant columns and relationships.

```sql
CREATE DATABASE library_db;

DROP TABLE IF EXISTS branch;
CREATE TABLE branch
(
            branch_id VARCHAR(10) PRIMARY KEY,
            manager_id VARCHAR(10),
            branch_address VARCHAR(30),
            contact_no VARCHAR(15)
);


-- Create table "Employee"
DROP TABLE IF EXISTS employees;
CREATE TABLE employees
(
            emp_id VARCHAR(10) PRIMARY KEY,
            emp_name VARCHAR(30),
            position VARCHAR(30),
            salary DECIMAL(10,2),
            branch_id VARCHAR(10),
            FOREIGN KEY (branch_id) REFERENCES  branch(branch_id)
);


-- Create table "Members"
DROP TABLE IF EXISTS members;
CREATE TABLE members
(
            member_id VARCHAR(10) PRIMARY KEY,
            member_name VARCHAR(30),
            member_address VARCHAR(30),
            reg_date DATE
);



-- Create table "Books"
DROP TABLE IF EXISTS books;
CREATE TABLE books
(
            isbn VARCHAR(50) PRIMARY KEY,
            book_title VARCHAR(80),
            category VARCHAR(30),
            rental_price DECIMAL(10,2),
            status VARCHAR(10),
            author VARCHAR(30),
            publisher VARCHAR(30)
);



-- Create table "IssueStatus"
DROP TABLE IF EXISTS issued_status;
CREATE TABLE issued_status
(
            issued_id VARCHAR(10) PRIMARY KEY,
            issued_member_id VARCHAR(30),
            issued_book_name VARCHAR(80),
            issued_date DATE,
            issued_book_isbn VARCHAR(50),
            issued_emp_id VARCHAR(10),
            FOREIGN KEY (issued_member_id) REFERENCES members(member_id),
            FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id),
            FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn) 
);



-- Create table "ReturnStatus"
DROP TABLE IF EXISTS return_status;
CREATE TABLE return_status
(
            return_id VARCHAR(10) PRIMARY KEY,
            issued_id VARCHAR(30),
            return_book_name VARCHAR(80),
            return_date DATE,
            return_book_isbn VARCHAR(50),
            FOREIGN KEY (return_book_isbn) REFERENCES books(isbn)
);

```

### 2. CRUD Operations

- **Create**: Inserted sample records into the `books` table.
- **Read**: Retrieved and displayed data from various tables.
- **Update**: Updated records in the `employees` table.
- **Delete**: Removed records from the `members` table as needed.

**1. Create a New Book Record**
-- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

```sql
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
```

**2: Update an Existing Member's Address**

```sql
UPDATE members
SET member_address='125 Main St'
WHERE member_id='C101';
```

**3: Delete a Record from the Issued Status Table**
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

```sql
DELETE FROM issued_status WHERE issued_id='IS121';
```

**4: List Members Who Have Issued More Than One Book**
-- Objective: Use GROUP BY to find members who have issued more than one book.

```sql
SELECT DISTINCT issued_member_id
FROM issued_status
GROUP BY issued_member_id
HAVING COUNT(*)>1;
```

### CTAS (Create Table As Select)

- **Create Summary Tables**: Use CTAS to generate new tables with each book and total book_issued_cnt**

```sql
CREATE TABLE books_cnts AS
SELECT b.isbn, b.book_title, COUNT(i.issued_book_name) AS issue_count
FROM books b
LEFT JOIN issued_status i ON b.isbn=i.issued_book_isbn
GROUP BY b.isbn;
```
- here you might think, the query will return an error at b.book_title saying its not mentioned in group by statement or not used in aggregate functions. But it will not, due to functional dependency optimization of PostGres.  If a column (like b.book_title) is functionally dependent on a column in the GROUP BY clause (like b.isbn), PostgreSQL may allow it without explicitly including b.book_title in the GROUP BY.
- Now you might think what is functional dependency, it is nothing but -> If isbn uniquely identifies book_title in the books table (e.g., isbn is a primary key or has a unique constraint), PostgreSQL can infer that b.book_title is always the same for a given b.isbn.
  
### 4. Data Analysis & Findings
 **1. Find Total Rental Income by Category**

 ```sql
SELECT b.category, SUM(b.rental_price) AS total_rental
FROM books b
JOIN issued_status i ON b.isbn=i.issued_book_isbn
GROUP BY 1;
 ```
**2. List Members Who Registered in the Last 180 Days**

```sql
SELECT *
FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 Days';
```

**3. List Employees with Their Branch Manager's Name and their branch details:**

```sql
SELECT e.emp_id, e.emp_name, b.branch_id, e2.emp_name AS branch_manager, b.branch_address
FROM employees e
JOIN branch b ON e.branch_id=b.branch_id
JOIN employees e2 ON b.manager_id=e2.emp_id;
```

**4. Create a Table of Books with Rental Price Above a Certain Threshold, 7**

```sql
CREATE TABLE expensive_books AS
SELECT *
FROM books
WHERE rental_price > 7.00;
```

**5. Retrieve the List of Books Not Yet Returned**

```sql
SELECT i.*
FROM issued_status i
LEFT JOIN return_status r ON r.issued_id=i.issued_id
WHERE r.issued_id IS NULL;
```


## Advanced SQL Operations

**1. Identify Members with Overdue Books**  
Identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.

```sql
WITH overdue_status_cte AS(
	SELECT i.*, CURRENT_DATE-issued_date AS days_overdue
	FROM issued_status i
	LEFT JOIN return_status r ON r.issued_id = i.issued_id
	WHERE r.issued_id IS NULL
)

SELECT c.issued_member_id, m.member_name, c.issued_book_name, c.issued_date, c.days_overdue
FROM overdue_status_cte c
JOIN members m ON m.member_id=c.issued_member_id
WHERE days_overdue > 30;
```

**2. Branch Performance Report**  
Generate a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.

```sql
CREATE TABLE branch_performance_report AS
SELECT 
	e.branch_id, b.branch_address,
	COUNT(i.issued_id) AS number_of_books_issued,
	COUNT(r.return_id ) AS number_of_books_returned,
	SUM(bk.rental_price) AS total_rental
FROM issued_status i
JOIN employees e ON e.emp_id = i.issued_emp_id
JOIN branch b ON b.branch_id = e.branch_id
LEFT JOIN return_status r ON i.issued_id = r.issued_id
JOIN books bk ON bk.isbn = i.issued_book_isbn
GROUP BY 1,2
ORDER BY 1;

SELECT * FROM branch_performance_report;
```

**3. Create a Table of Active Members**  
Create a new table active_members containing members who have issued at least one book in the last 2 months.
Here you can use CTAS to create the new table

```sql
CREATE TABLE active_members AS
SELECT *
FROM members
WHERE member_id IN (
	SELECT issued_member_id
	FROM issued_status
	WHERE issued_date >= CURRENT_DATE - INTERVAL '6 Months'
);

SELECT * FROM active_members;
```

**4. Find Employees with the Most Book Issues Processed**  
Find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.

```sql
SELECT e.emp_name, e.branch_id, COUNT(i.issued_id) AS books_processed
FROM issued_status i
JOIN employees e ON i.issued_emp_id = e.emp_id
GROUP BY 1,2
ORDER BY books_processed DESC
LIMIT 3;
```

### Stored Procedures  
**5. Update Book Status on Return**   
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).

```sql
CREATE PROCEDURE add_return_status(p_return_id VARCHAR(10), p_issued_id VARCHAR(10), p_book_quality VARCHAR(15))
LANGUAGE plpgsql
AS $$

DECLARE
	return_book_isbn VARCHAR(20);
	return_book_name VARCHAR(60);

BEGIN
	-- inserting into return_status table
	INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
	VALUES (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

	-- fetching and storing return book isbn
	SELECT issued_book_isbn, issued_book_name
	INTO return_book_isbn, return_book_name
	FROM issued_status
	WHERE issued_id=p_issued_id;

	--updating status in books table
	UPDATE books
	SET status='yes'
	WHERE isbn=return_book_isbn;

	RAISE NOTICE 'Updated record in books and return status for issueid: %, book_name: %', return_book_isbn, return_book_name;

END;
$$;

-- calling function 
CALL add_return_records('RS138', 'IS135', 'Good');

-- calling function 
CALL add_return_records('RS148', 'IS140', 'Good');
```

**6. Issue book if available**  
Create a stored procedure to manage the status of books in a library system.
Description:
Write a stored procedure that updates the status of a book in the library based on its issuance. The procedure should function as follows:
The stored procedure should take the book_id as an input parameter.
The procedure should first check if the book is available (status = 'yes').
If the book is available, it should be issued, and the status in the books table should be updated to 'no'.
If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.

```sql
CREATE OR REPLACE PROCEDURE issue_book(p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(10), p_isbn VARCHAR(20), p_issued_emp_id VARCHAR(10))
LANGUAGE plpgsql
AS $$
DECLARE
	v_status VARCHAR(10);
	v_bookname VARCHAR(60);

BEGIN

	-- checking if book is available
	SELECT status, book_title
	INTO v_status, v_bookname
	FROM books
	WHERE isbn=p_isbn;

	IF v_status='yes' THEN
		-- inserting into issued_status table
		INSERT INTO issued_status
		VALUES (p_issued_id, p_issued_member_id, v_bookname, CURRENT_DATE, p_isbn, p_issued_emp_id);

		-- updating books table
		UPDATE books
		SET status='no'
		WHERE isbn=p_isbn;
		
		RAISE NOTICE 'Book record added successfully, isbn: %',p_isbn;

	ELSE
		RAISE NOTICE 'Book % is currently un-available', p_isbn;
	
	END IF;

END;
$$;

CALL issue_book('IS156', 'C108', '978-0-14-118776-1', 'E104');
```


## Conclusion

This project demonstrates the application of SQL skills in creating and managing a library management system. It includes database setup, data manipulation, and advanced querying, providing a solid foundation for data management and analysis.

## How to Use

1. **Clone the Repository**: Clone this repository to your local machine.
   ```sh
   git clone https://github.com/abhikmp/Library-Mgmt-System.git
   ```

2. **Set Up the Database**: Execute the SQL scripts in the `db_setup.sql` file to create and populate the database.
3. **Run the Queries**: Use the SQL queries in the `data-analysis.sql` file to perform the analysis.
4. **Explore and Modify**: Customize the queries as needed to explore different aspects of the data or answer additional questions.

## Author - Abhijeeth S
