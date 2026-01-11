-- ================================
-- 视图定义
-- ================================

-- 视图1：当前借阅情况
CREATE OR REPLACE VIEW CurrentBorrows AS
SELECT 
    r.reader_id,
    r.student_id,
    r.name AS reader_name,
    r.college,
    b.book_id,
    b.title AS book_title,
    b.author,
    br.borrow_date,
    br.due_date,
    DATEDIFF(br.due_date, CURDATE()) AS days_remaining,
    br.status,
    br.renewal_count
FROM BorrowRecords br
JOIN Readers r ON br.reader_id = r.reader_id
JOIN Books b ON br.book_id = b.book_id
WHERE br.status IN ('借出中', '逾期')
ORDER BY br.due_date ASC;

-- 视图2：热门图书排行
CREATE OR REPLACE VIEW PopularBooks AS
SELECT 
    b.book_id,
    b.isbn,
    b.title,
    b.author,
    b.category,
    b.publisher,
    COUNT(br.record_id) AS total_borrow_count,
    b.total_copies,
    b.available_copies,
    ROUND(COUNT(br.record_id) / NULLIF(b.total_copies, 0), 2) AS borrow_rate,
    CASE 
        WHEN b.available_copies = 0 THEN '已借完'
        WHEN b.available_copies <= 2 THEN '紧张'
        ELSE '充足'
    END AS stock_status
FROM Books b
LEFT JOIN BorrowRecords br ON b.book_id = br.book_id
GROUP BY b.book_id, b.isbn, b.title, b.author, b.category, b.publisher, b.total_copies, b.available_copies
ORDER BY total_borrow_count DESC, b.title ASC;

-- 视图3：读者借阅统计
CREATE OR REPLACE VIEW ReaderStatistics AS
SELECT 
    r.reader_id,
    r.student_id,
    r.name,
    r.college,
    r.register_date,
    r.status AS reader_status,
    COUNT(br.record_id) AS total_borrowed,
    COUNT(CASE WHEN br.status = '借出中' THEN 1 END) AS current_borrowing,
    COUNT(CASE WHEN br.status = '逾期' THEN 1 END) AS overdue_count,
    COUNT(CASE WHEN br.status = '已归还' THEN 1 END) AS returned_count,
    MAX(br.borrow_date) AS last_borrow_date,
    COALESCE(SUM(f.amount), 0) AS total_fine_amount,
    COALESCE(SUM(CASE WHEN f.status = '未支付' THEN f.amount ELSE 0 END), 0) AS unpaid_fine_amount
FROM Readers r
LEFT JOIN BorrowRecords br ON r.reader_id = br.reader_id
LEFT JOIN Fines f ON r.reader_id = f.reader_id
GROUP BY r.reader_id, r.student_id, r.name, r.college, r.register_date, r.status
ORDER BY total_borrowed DESC;

-- 视图4：月度借阅统计
CREATE OR REPLACE VIEW MonthlyBorrowStats AS
SELECT 
    DATE_FORMAT(br.borrow_date, '%Y-%m') AS month,
    COUNT(*) AS total_borrows,
    COUNT(DISTINCT br.reader_id) AS unique_readers,
    COUNT(DISTINCT br.book_id) AS unique_books,
    SUM(CASE WHEN br.status = '逾期' THEN 1 ELSE 0 END) AS overdue_count,
    AVG(DATEDIFF(br.return_date, br.borrow_date)) AS avg_borrow_days
FROM BorrowRecords br
WHERE br.borrow_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(br.borrow_date, '%Y-%m')
ORDER BY month DESC;

-- 视图5：今日座位预约情况
CREATE OR REPLACE VIEW TodaySeatReservations AS
SELECT 
    s.room_number,
    s.seat_number,
    s.floor,
    s.area,
    r.name AS reserved_by,
    sr.reserve_start,
    sr.reserve_end,
    sr.status,
    CASE 
        WHEN sr.reserve_start <= NOW() AND sr.reserve_end >= NOW() AND sr.checkin_time IS NOT NULL THEN '使用中'
        WHEN sr.reserve_start <= NOW() AND sr.reserve_end >= NOW() AND sr.checkin_time IS NULL THEN '未签到'
        WHEN sr.reserve_start > NOW() THEN '待开始'
        ELSE '已结束'
    END AS current_status,
    TIMESTAMPDIFF(MINUTE, NOW(), sr.reserve_start) AS minutes_until_start
FROM SeatReservations sr
JOIN Seats s ON sr.seat_id = s.seat_id
JOIN Readers r ON sr.reader_id = r.reader_id
WHERE DATE(sr.reserve_start) = CURDATE() OR DATE(sr.reserve_end) = CURDATE()
ORDER BY s.room_number, s.seat_number, sr.reserve_start;

-- 视图6：图书馆收入统计
CREATE OR REPLACE VIEW RevenueStatistics AS
SELECT 
    DATE_FORMAT(f.issue_date, '%Y-%m') AS month,
    COUNT(*) AS fine_count,
    SUM(f.amount) AS total_revenue,
    SUM(CASE WHEN f.status = '已支付' THEN f.amount ELSE 0 END) AS paid_revenue,
    SUM(CASE WHEN f.status = '未支付' THEN f.amount ELSE 0 END) AS unpaid_revenue,
    AVG(f.amount) AS avg_fine_amount
FROM Fines f
WHERE f.issue_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(f.issue_date, '%Y-%m')
ORDER BY month DESC;

-- 视图7：图书类别统计
CREATE OR REPLACE VIEW CategoryStatistics AS
SELECT 
    b.category,
    COUNT(*) AS book_count,
    SUM(b.total_copies) AS total_copies,
    SUM(b.available_copies) AS available_copies,
    COUNT(DISTINCT b.author) AS author_count,
    AVG(b.price) AS avg_price,
    COUNT(br.record_id) AS total_borrows,
    ROUND(COUNT(br.record_id) / NULLIF(COUNT(*), 0), 2) AS avg_borrow_per_book
FROM Books b
LEFT JOIN BorrowRecords br ON b.book_id = br.book_id
GROUP BY b.category
ORDER BY total_borrows DESC;

-- 视图8：馆员工作统计
CREATE OR REPLACE VIEW LibrarianStats AS
SELECT 
    l.librarian_id,
    l.employee_id,
    l.name,
    l.position,
    l.department,
    COUNT(br.record_id) AS processed_borrows,
    COUNT(DISTINCT br.reader_id) AS served_readers,
    MIN(br.borrow_date) AS first_process_date,
    MAX(br.borrow_date) AS last_process_date,
    l.work_status
FROM Librarians l
LEFT JOIN BorrowRecords br ON l.librarian_id = br.librarian_id
GROUP BY l.librarian_id, l.employee_id, l.name, l.position, l.department, l.work_status;
