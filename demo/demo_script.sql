-- ================================
-- 功能演示脚本
-- ================================

USE LibraryDB;

-- 演示1：查看系统初始状态
SELECT '=== 1. 系统初始状态 ===' AS '演示步骤';
SELECT '读者数量：' AS 描述, COUNT(*) AS 数量 FROM Readers
UNION ALL
SELECT '图书数量：', COUNT(*) FROM Books
UNION ALL
SELECT '当前借阅：', COUNT(*) FROM BorrowRecords WHERE status = '借出中';

-- 演示2：读者查询可借图书
SELECT '\n=== 2. 查询可借图书 ===' AS '演示步骤';
SELECT 
    book_id AS '图书ID',
    title AS '书名',
    author AS '作者',
    available_copies AS '可用副本',
    location AS '位置'
FROM Books 
WHERE available_copies > 0 
LIMIT 3;

-- 演示3：办理借阅（完整流程）
SELECT '\n=== 3. 办理借阅流程 ===' AS '演示步骤';

-- 3.1 检查读者资格
SELECT '检查读者张三的借阅资格：' AS 步骤;
SELECT 
    name AS '姓名',
    max_borrow_limit AS '最大借阅数',
    status AS '账户状态'
FROM Readers 
WHERE reader_id = 1;

-- 3.2 检查当前借阅数量
SELECT '当前借阅数量：' AS 步骤;
SELECT COUNT(*) AS '当前借阅数'
FROM BorrowRecords 
WHERE reader_id = 1 AND status = '借出中';

-- 3.3 执行借阅
SELECT '执行借阅操作...' AS 步骤;
INSERT INTO BorrowRecords (reader_id, book_id, due_date, librarian_id) 
VALUES (1, 1, DATE_ADD(CURDATE(), INTERVAL 14 DAY), 1);

-- 3.4 验证借阅结果
SELECT '验证借阅结果：' AS 步骤;
SELECT 
    r.name AS '读者',
    b.title AS '图书',
    br.borrow_date AS '借出时间',
    br.due_date AS '应还时间',
    DATEDIFF(br.due_date, CURDATE()) AS '剩余天数'
FROM BorrowRecords br
JOIN Readers r ON br.reader_id = r.reader_id
JOIN Books b ON br.book_id = b.book_id
WHERE br.record_id = LAST_INSERT_ID();

-- 3.5 查看图书副本数变化
SELECT '图书副本数变化：' AS 步骤;
SELECT 
    title AS '图书',
    total_copies AS '总副本',
    available_copies AS '可用副本'
FROM Books 
WHERE book_id = 1;

-- 演示4：查看当前借阅情况
SELECT '\n=== 4. 查看当前借阅 ===' AS '演示步骤';
SELECT * FROM CurrentBorrows;

-- 演示5：办理归还
SELECT '\n=== 5. 办理归还 ===' AS '演示步骤';

-- 5.1 归还操作
SELECT '执行归还操作...' AS 步骤;
UPDATE BorrowRecords 
SET return_date = NOW(), 
    status = '已归还',
    updated_at = NOW()
WHERE reader_id = 1 AND book_id = 1 AND status = '借出中'
LIMIT 1;

-- 5.2 验证归还
SELECT '验证归还结果：' AS 步骤;
SELECT 
    b.title AS '图书',
    br.borrow_date AS '借出时间',
    br.return_date AS '归还时间',
    br.status AS '状态'
FROM BorrowRecords br
JOIN Books b ON br.book_id = b.book_id
WHERE br.reader_id = 1 AND br.book_id = 1
ORDER BY br.borrow_date DESC
LIMIT 1;

-- 5.3 查看副本数恢复
SELECT '图书副本数恢复：' AS 步骤;
SELECT 
    title AS '图书',
    available_copies AS '归还后可用副本'
FROM Books 
WHERE book_id = 1;

-- 演示6：预约功能
SELECT '\n=== 6. 图书预约功能 ===' AS '演示步骤';

-- 6.1 查询可预约图书
SELECT '查询可预约图书：' AS 步骤;
SELECT 
    book_id,
    title,
    available_copies
FROM Books 
WHERE available_copies > 0 
LIMIT 2;

-- 6.2 执行预约
SELECT '读者李四预约图书...' AS 步骤;
INSERT INTO Reservations (reader_id, book_id, pickup_deadline) 
VALUES (2, 2, DATE_ADD(CURDATE(), INTERVAL 3 DAY));

-- 6.3 查看预约结果
SELECT '查看预约记录：' AS 步骤;
SELECT 
    r.name AS '读者',
    b.title AS '图书',
    rs.reserve_date AS '预约时间',
    rs.pickup_deadline AS '取书截止',
    rs.status AS '状态'
FROM Reservations rs
JOIN Readers r ON rs.reader_id = r.reader_id
JOIN Books b ON rs.book_id = b.book_id
WHERE rs.reservation_id = LAST_INSERT_ID();

-- 演示7：统计查询功能
SELECT '\n=== 7. 统计查询功能 ===' AS '演示步骤';

-- 7.1 热门图书排行
SELECT '热门图书排行：' AS 步骤;
SELECT 
    title AS '图书',
    author AS '作者',
    total_borrow_count AS '借阅次数',
    stock_status AS '库存状态'
FROM PopularBooks 
LIMIT 5;

-- 7.2 读者借阅统计
SELECT '读者借阅统计：' AS 步骤;
SELECT 
    name AS '读者',
    college AS '学院',
    total_borrowed AS '总借阅量',
    current_borrowing AS '当前借阅',
    overdue_count AS '逾期次数'
FROM ReaderStatistics 
ORDER BY total_borrowed DESC 
LIMIT 3;

-- 7.3 月度借阅统计
SELECT '月度借阅统计：' AS 步骤;
SELECT * FROM MonthlyBorrowStats;

-- 7.4 今日座位预约
SELECT '今日座位预约情况：' AS 步骤;
SELECT 
    room_number AS '房间',
    seat_number AS '座位',
    reserved_by AS '预约人',
    TIME(reserve_start) AS '开始时间',
    TIME(reserve_end) AS '结束时间',
    status AS '状态'
FROM TodaySeatReservations;

-- 演示8：触发器效果验证
SELECT '\n=== 8. 触发器效果验证 ===' AS '演示步骤';

-- 8.1 检查借阅限制触发器
SELECT '测试借阅限制：' AS 步骤;
-- 先让读者借满
UPDATE Readers SET max_borrow_limit = 1 WHERE reader_id = 3;

-- 尝试借第一本（应该成功）
INSERT INTO BorrowRecords (reader_id, book_id, due_date) 
VALUES (3, 3, DATE_ADD(CURDATE(), INTERVAL 7 DAY));

SELECT '第一次借阅成功' AS 结果;

-- 尝试借第二本（应该失败）
SELECT '尝试第二次借阅（应触发限制）：' AS 测试;
-- 这里会报错，演示时可以说明

-- 演示9：系统总结
SELECT '\n=== 9. 系统总结 ===' AS '演示步骤';
SELECT '✅ 系统功能演示完成！' AS '总结';
SELECT '共演示功能：' AS 项目, '借阅、归还、预约、统计、触发器等' AS 内容;
