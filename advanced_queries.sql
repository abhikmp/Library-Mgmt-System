-- ADVANCED QUERIES
SELECT * FROM books;
SELECT * FROM members;
SELECT * FROM employees;
SELECT * FROM branch;
SELECT * FROM issued_status;
SELECT * FROM return_status;


/* 
Identify members who have overdue books (assume a 30-day return period). 
Display the member's_id, member's name, book title, issue date, and days overdue.
*/

WITH overdue_status_cte AS(
	SELECT i.*, CURRENT_DATE-issued_date AS days_overdue
	FROM issued_status i
	LEFT JOIN return_status r ON r.issued_id = i.issued_id
	WHERE r.issued_id IS NULL
)

SELECT c.issued_member_id, m.member_name, c.issued_book_name, c.issued_date, c.days_overdue
FROM overdue_status_cte c
JOIN members m ON m.member_id=c.issued_member_id
WHERE days_overdue > 30


/*
-------------------------
STORED PROCEDURES
-------------------------
Write a query to update the status of books in the books table to "Yes" 
when they are returned (based on entries in the return_status table).
*/

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

-- calling the function
CALL add_return_status('RS138', 'IS135', 'Good');
CALL add_return_status('RS148', 'IS140', 'Good');


/*
BRANCH PERFORMANCE REPORT
Generate a performance report for each branch, showing the number of books issued, 
the number of books returned, and the total revenue generated from book rentals.
*/
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


/*
create a new table 'active_members'
containing members who have issued at least one book in the last 2 months.
*/
CREATE TABLE active_members AS
SELECT *
FROM members
WHERE member_id IN (
	SELECT issued_member_id
	FROM issued_status
	WHERE issued_date >= CURRENT_DATE - INTERVAL '6 Months'
);


/*
Write a query to find the top 3 employees who have processed the most book issues.
Display the employee name, number of books processed, and their branch.
*/
SELECT e.emp_name, e.branch_id, COUNT(i.issued_id) AS books_processed
FROM issued_status i
JOIN employees e ON i.issued_emp_id = e.emp_id
GROUP BY 1,2
ORDER BY books_processed DESC
LIMIT 3


/*
-----------------------------------
STORED PROCEDURE
-----------------------------------
Write a stored procedure that updates the status of a book in the library based on its issuance. 
The procedure should function as follows: 
The stored procedure should take the book_id as an input parameter. 
The procedure should first check if the book is available (status = 'yes'). 
If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available
*/
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

