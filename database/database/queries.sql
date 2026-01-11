-- ================================
-- 常用查询示例 - 修正版
-- ================================

-- 1. 基础查询：查询所有可借阅的图书
SELECT 
    book_id,
    title,
    author,
    category,
    available_copies,
    location
FROM Books
WHERE available_copies > 0
ORDER BY category, title;

-- 2. 查询特定读者的借阅记录
SELECT 
    b.title AS '书名',
    b.author AS '作者',
    br.borrow_date AS '借出日期',
    br.due_date AS '应还日期',
    CASE 
        WHEN br.return_date IS NOT NULL THEN '已归还'
        WHEN br.due_date < CURDATE() THEN '逾期'
        ELSE '借出中'
    END AS '状态',
    DATEDIFF(IFNULL(br.return_date, CURDATE()), br.borrow_date) AS '借阅天数'
FROM BorrowRecords br
JOIN Books b ON br.book_id = b.book_id
WHERE br.reader_id = 1  -- 替换为具体读者ID
ORDER BY br.borrow_date DESC;

-- 3. 查询逾期未还的图书
SELECT 
    r.name AS '读者姓名',
    r.student_id AS '学号',
    r.college AS '学院',
    b.title AS '图书名称',
    b.isbn AS 'ISBN',
    br.borrow_date AS '借出日期',
    br.due_date AS '应还日期',
    DATEDIFF(CURDATE(), br.due_date) AS '逾期天数',
    DATEDIFF(CURDATE(), br.due_date) * 0.5 AS '罚款金额'
FROM BorrowRecords br
JOIN Readers r ON br.reader_id = r.reader_id
JOIN Books b ON br.book_id = b.book_id
WHERE br.status = '借出中' 
  AND br.due_date < CURDATE()
ORDER BY br.due_date ASC;

-- 4. 统计各学院借阅量（修正版）
SELECT 
    r.college AS '学院',
    COUNT(br.record_id) AS '借阅总数',
    COUNT(DISTINCT r.reader_id) AS '借阅人数',
    ROUND(COUNT(br.record_id) / NULLIF(COUNT(DISTINCT r.reader_id), 0), 2) AS '人均借阅量'
FROM Readers r
LEFT JOIN BorrowRecords br ON r.reader_id = br.reader_id
WHERE r.college IS NOT NULL
GROUP BY r.college
ORDER BY '借阅总数' DESC;

-- 5. 查询热门图书（借阅次数最多）
SELECT 
    b.title AS '图书名称',
    b.author AS '作者',
    b.category AS '类别',
    COUNT(br.record_id) AS '借阅次数',
    b.available_copies AS '可用副本',
    CASE 
        WHEN b.available_copies = 0 THEN '已借完'
        WHEN b.available_copies <= 2 THEN '库存紧张'
        ELSE '库存充足'
    END AS '库存状态'
FROM Books b
LEFT JOIN BorrowRecords br ON b.book_id = br.book_id
GROUP BY b.book_id, b.title, b.author, b.category, b.available_copies
ORDER BY '借阅次数' DESC
LIMIT 10;

-- 6. 查询今日预约情况
SELECT 
    r.name AS '读者姓名',
    b.title AS '图书名称',
    rs.reserve_date AS '预约时间',
    rs.pickup_deadline AS '最晚取书日期',
    rs.status AS '预约状态'
FROM Reservations rs
JOIN Readers r ON rs.reader_id = r.reader_id
JOIN Books b ON rs.book_id = b.book_id
WHERE DATE(rs.reserve_date) = CURDATE()
ORDER BY rs.reserve_date;

-- 7. 查询读者的未支付罚款
SELECT 
    r.name AS '读者姓名',
    r.student_id AS '学号',
    SUM(f.amount) AS '未支付罚款总额',
    COUNT(f.fine_id) AS '未支付罚款数量'
FROM Fines f
JOIN Readers r ON f.reader_id = r.reader_id
WHERE f.status = '未支付'
GROUP BY r.reader_id, r.name, r.student_id
HAVING SUM(f.amount) > 0
ORDER BY '未支付罚款总额' DESC;

-- 8. 查询图书借阅历史
SELECT 
    b.title AS '图书名称',
    b.isbn AS 'ISBN',
    COUNT(br.record_id) AS '总借阅次数',
    MIN(br.borrow_date) AS '首次借阅时间',
    MAX(br.borrow_date) AS '最近借阅时间',
    AVG(DATEDIFF(IFNULL(br.return_date, CURDATE()), br.borrow_date)) AS '平均借阅天数'
FROM Books b
LEFT JOIN BorrowRecords br ON b.book_id = br.book_id
GROUP BY b.book_id, b.title, b.isbn
ORDER BY '总借阅次数' DESC;

-- 9. 查询馆员工作统计
SELECT 
    l.name AS '馆员姓名',
    l.position AS '职位',
    COUNT(br.record_id) AS '办理借阅数量',
    COUNT(DISTINCT br.reader_id) AS '服务读者人数',
    MIN(br.borrow_date) AS '首次办理时间',
    MAX(br.borrow_date) AS '最近办理时间'
FROM Librarians l
LEFT JOIN BorrowRecords br ON l.librarian_id = br.librarian_id
GROUP BY l.librarian_id, l.name, l.position
ORDER BY '办理借阅数量' DESC;

-- 10. 月度借阅趋势分析
SELECT 
    DATE_FORMAT(br.borrow_date, '%Y-%m') AS '月份',
    COUNT(*) AS '借阅次数',
    COUNT(DISTINCT br.reader_id) AS '借阅人数',
    COUNT(DISTINCT br.book_id) AS '借阅图书种类'
FROM BorrowRecords br
WHERE br.borrow_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY DATE_FORMAT(br.borrow_date, '%Y-%m')
ORDER BY '月份' DESC;
