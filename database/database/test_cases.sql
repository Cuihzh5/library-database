-- ================================
-- 测试用例和验证脚本
-- ================================

USE LibraryDB;

-- 测试前准备：清空部分表（谨慎使用）
-- DELETE FROM BorrowRecords;
-- DELETE FROM Reservations;
-- DELETE FROM Fines;
-- UPDATE Books SET available_copies = total_copies;

-- ==================== 测试用例组1：基础功能测试 ====================

-- 测试1.1：读者注册功能
-- 预期：成功插入新读者
INSERT INTO Readers (student_id, name, college, phone, email, max_borrow_limit) 
VALUES ('20210009', '测试用户', '测试学院', '13800138009', 'test@test.com', 5);

-- 验证：
SELECT * FROM Readers WHERE student_id = '20210009';

-- 测试1.2：图书信息添加
-- 预期：成功插入新图书
INSERT INTO Books (isbn, title, author, publisher, category, total_copies, available_copies, price) 
VALUES ('978-7-123-45678-9', '测试图书', '测试作者', '测试出版社', '测试类', 3, 3, 50.00);

-- 验证：
SELECT * FROM Books WHERE isbn = '978-7-123-45678-9';

-- ==================== 测试用例组2：借阅流程测试 ====================

-- 测试2.1：正常借书流程
-- 预期：读者借阅成功，图书可用副本减少
SELECT available_copies AS 借阅前副本数 FROM Books WHERE book_id = 1;

INSERT INTO BorrowRecords (reader_id, book_id, due_date, librarian_id) 
VALUES (1, 1, DATE_ADD(CURDATE(), INTERVAL 14 DAY), 1);

SELECT available_copies AS 借阅后副本数 FROM Books WHERE book_id = 1;
SELECT * FROM BorrowRecords WHERE reader_id = 1 AND book_id = 1;

-- 测试2.2：借阅超过限制（应失败）
-- 预期：触发借阅限制触发器，插入失败
-- 先让读者借满限制
INSERT INTO BorrowRecords (reader_id, book_id, due_date) 
VALUES (5, 2, DATE_ADD(CURDATE(), INTERVAL 14 DAY)); -- 读者5最大借3本

INSERT INTO BorrowRecords (reader_id, book_id, due_date) 
VALUES (5, 3, DATE_ADD(CURDATE(), INTERVAL 14 DAY));

INSERT INTO BorrowRecords (reader_id, book_id, due_date) 
VALUES (5, 4, DATE_ADD(CURDATE(), INTERVAL 14 DAY)); -- 应成功（3本满）

-- 尝试借第4本（应失败）
INSERT INTO BorrowRecords (reader_id, book_id, due_date) 
VALUES (5, 5, DATE_ADD(CURDATE(), INTERVAL 14 DAY)); -- 应触发错误

-- 测试2.3：还书流程
-- 预期：还书后状态更新，可用副本恢复
SELECT available_copies AS 还书前副本数 FROM Books WHERE book_id = 2;

UPDATE BorrowRecords 
SET return_date = NOW(), 
    status = '已归还'
WHERE reader_id = 2 AND book_id = 2 AND status = '借出中';

SELECT available_copies AS 还书后副本数 FROM Books WHERE book_id = 2;
SELECT * FROM BorrowRecords WHERE reader_id = 2 AND book_id = 2;

-- ==================== 测试用例组3：预约流程测试 ====================

-- 测试3.1：图书预约
-- 预期：预约成功，可用副本减少
SELECT available_copies AS 预约前副本数 FROM Books WHERE book_id = 3;

INSERT INTO Reservations (reader_id, book_id, pickup_deadline) 
VALUES (2, 3, DATE_ADD(CURDATE(), INTERVAL 3 DAY));

SELECT available_copies AS 预约后副本数 FROM Books WHERE book_id = 3;
SELECT * FROM Reservations WHERE reader_id = 2 AND book_id = 3;

-- 测试3.2：预约取消
-- 预期：取消后可用副本恢复
UPDATE Reservations 
SET status = '已取消' 
WHERE reader_id = 2 AND book_id = 3 AND status = '等待中';

SELECT available_copies AS 取消后副本数 FROM Books WHERE book_id = 3;

-- ==================== 测试用例组4：座位预约测试 ====================

-- 测试4.1：座位预约
-- 预期：成功预约座位
INSERT INTO SeatReservations (reader_id, seat_id, reserve_start, reserve_end) 
VALUES (3, 2, DATE_ADD(NOW(), INTERVAL 1 HOUR), DATE_ADD(NOW(), INTERVAL 3 HOUR));

SELECT * FROM SeatReservations WHERE reader_id = 3 AND seat_id = 2;
SELECT status FROM Seats WHERE seat_id = 2;

-- 测试4.2：座位签到
-- 预期：状态变为使用中
UPDATE SeatReservations 
SET checkin_time = NOW(), 
    status = '使用中'
WHERE reader_id = 3 AND seat_id = 2 AND status = '预约中';

UPDATE Seats SET status = '使用中' WHERE seat_id = 2;

SELECT * FROM SeatReservations WHERE reader_id = 3 AND seat_id = 2;
SELECT status FROM Seats WHERE seat_id = 2;

-- ==================== 测试用例组5：罚款系统测试 ====================

-- 测试5.1：逾期罚款自动生成
-- 预期：逾期借阅自动生成罚款记录
-- 先创建一个逾期借阅
INSERT INTO BorrowRecords (reader_id, book_id, borrow_date, due_date, status) 
VALUES (4, 6, DATE_SUB(CURDATE(), INTERVAL 20 DAY), DATE_SUB(CURDATE(), INTERVAL 5 DAY), '逾期');

-- 检查是否生成罚款
SELECT * FROM Fines WHERE reader_id = 4 AND reason = '逾期';

-- 测试5.2：罚款支付
-- 预期：罚款状态更新为已支付
UPDATE Fines 
SET paid_date = CURDATE(), 
    status = '已支付', 
    payment_method = '支付宝'
WHERE fine_id = 2;

SELECT * FROM Fines WHERE fine_id = 2;

-- ==================== 测试用例组6：视图功能测试 ====================

-- 测试6.1：查看当前借阅视图
SELECT * FROM CurrentBorrows WHERE reader_id = 1;

-- 测试6.2：查看热门图书视图
SELECT * FROM PopularBooks LIMIT 5;

-- 测试6.3：查看读者统计视图
SELECT * FROM ReaderStatistics WHERE reader_id = 1;

-- 测试6.4：查看今日座位预约
SELECT * FROM TodaySeatReservations;

-- ==================== 测试用例组7：统计查询测试 ====================

-- 测试7.1：月度借阅统计
SELECT * FROM MonthlyBorrowStats;

-- 测试7.2：图书馆收入统计
SELECT * FROM RevenueStatistics;

-- 测试7.3：图书类别统计
SELECT * FROM CategoryStatistics;

-- 测试7.4：馆员工作统计
SELECT * FROM LibrarianStats;

-- ==================== 测试用例组8：触发器功能验证 ====================

-- 测试8.1：借书触发器验证（可用副本减少）
SELECT '图书1当前可用副本数：' AS 描述, available_copies FROM Books WHERE book_id = 1;

-- 测试8.2：还书触发器验证（可用副本恢复）
-- 先借一本书
INSERT INTO BorrowRecords (reader_id, book_id, due_date) 
VALUES (6, 1, DATE_ADD(CURDATE(), INTERVAL 7 DAY));

SELECT '借书后可用副本数：' AS 描述, available_copies FROM Books WHERE book_id = 1;

-- 然后归还
UPDATE BorrowRecords 
SET return_date = NOW(), 
    status = '已归还'
WHERE reader_id = 6 AND book_id = 1 AND status = '借出中';

SELECT '还书后可用副本数：' AS 描述, available_copies FROM Books WHERE book_id = 1;

-- 测试8.3：借阅限制触发器
-- 设置读者最大借阅数为1
UPDATE Readers SET max_borrow_limit = 1 WHERE reader_id = 7;

-- 先借一本
INSERT INTO BorrowRecords (reader_id, book_id, due_date) 
VALUES (7, 1, DATE_ADD(CURDATE(), INTERVAL 7 DAY));

-- 尝试借第二本（应失败）
INSERT INTO BorrowRecords (reader_id, book_id, due_date) 
VALUES (7, 2, DATE_ADD(CURDATE(), INTERVAL 7 DAY)); -- 应触发错误

-- ==================== 测试用例组9：边界条件测试 ====================

-- 测试9.1：借阅数量为0的图书
INSERT INTO Books (isbn, title, total_copies, available_copies) 
VALUES ('978-7-000-00000-0', '无副本测试书', 0, 0);

-- 尝试借阅（应失败）
INSERT INTO BorrowRecords (reader_id, book_id, due_date) 
VALUES (1, (SELECT book_id FROM Books WHERE isbn = '978-7-000-00000-0'), CURDATE()); -- 应触发错误

-- 测试9.2：重复预约同一本书
INSERT INTO Reservations (reader_id, book_id, pickup_deadline) 
VALUES (1, 1, DATE_ADD(CURDATE(), INTERVAL 2 DAY));

-- 同一读者再次预约（应该可以，但要检查业务逻辑）
INSERT INTO Reservations (reader_id, book_id, pickup_deadline) 
VALUES (1, 1, DATE_ADD(CURDATE(), INTERVAL 3 DAY));

SELECT * FROM Reservations WHERE reader_id = 1 AND book_id = 1;

-- ==================== 测试用例组10：数据完整性测试 ====================

-- 测试10.1：外键约束测试
-- 尝试插入不存在的读者ID（应失败）
INSERT INTO BorrowRecords (reader_id, book_id, due_date) 
VALUES (9999, 1, CURDATE()); -- 应触发外键约束错误

-- 测试10.2：唯一约束测试
-- 尝试插入重复学号（应失败）
INSERT INTO Readers (student_id, name) 
VALUES ('20210001', '重复学号测试'); -- 应触发唯一约束错误

-- 测试10.3：非空约束测试
-- 尝试插入无书名的图书（应失败）
INSERT INTO Books (isbn) 
VALUES ('978-7-111-22222-2'); -- 应触发非空约束错误

-- ==================== 测试用例组11：性能测试 ====================

-- 测试11.1：大量数据查询性能
EXPLAIN SELECT * FROM BorrowRecords WHERE reader_id = 1;

-- 测试11.2：索引使用情况
SHOW INDEX FROM BorrowRecords;
SHOW INDEX FROM Books;
SHOW INDEX FROM Readers;

-- 测试11.3：连接查询性能
EXPLAIN 
SELECT r.name, b.title, br.borrow_date, br.due_date
FROM BorrowRecords br
JOIN Readers r ON br.reader_id = r.reader_id
JOIN Books b ON br.book_id = b.book_id
WHERE br.status = '借出中'
ORDER BY br.due_date;

-- ==================== 测试用例组12：业务逻辑验证 ====================

-- 测试12.1：续借功能
-- 预期：续借次数增加，应还日期延后
SELECT renewal_count, due_date AS 原应还日期 
FROM BorrowRecords 
WHERE record_id = 1;

UPDATE BorrowRecords 
SET due_date = DATE_ADD(due_date, INTERVAL 7 DAY),
    renewal_count = renewal_count + 1
WHERE record_id = 1;

SELECT renewal_count, due_date AS 新应还日期 
FROM BorrowRecords 
WHERE record_id = 1;

-- 测试12.2：读者状态更新
-- 预期：当有大量逾期罚款时，读者状态变为黑名单
-- 为读者4添加多条逾期罚款
INSERT INTO Fines (reader_id, amount, reason, issue_date, status) VALUES
(4, 10.00, '逾期', DATE_SUB(CURDATE(), INTERVAL 45 DAY), '未支付'),
(4, 15.00, '逾期', DATE_SUB(CURDATE(), INTERVAL 40 DAY), '未支付'),
(4, 20.00, '逾期', DATE_SUB(CURDATE(), INTERVAL 35 DAY), '未支付');

SELECT status FROM Readers WHERE reader_id = 4; -- 应变为'黑名单'

-- ==================== 测试结果总结 ====================

-- 查看所有测试数据
SELECT '读者表记录数' AS 表名, COUNT(*) AS 数量 FROM Readers
UNION ALL
SELECT '图书表记录数', COUNT(*) FROM Books
UNION ALL
SELECT '借阅记录数', COUNT(*) FROM BorrowRecords
UNION ALL
SELECT '预约记录数', COUNT(*) FROM Reservations
UNION ALL
SELECT '座位预约数', COUNT(*) FROM SeatReservations
UNION ALL
SELECT '罚款记录数', COUNT(*) FROM Fines
UNION ALL
SELECT '采购记录数', COUNT(*) FROM Purchases;

-- 查看系统日志
SELECT action, COUNT(*) AS 次数, MAX(log_time) AS 最近时间
FROM SystemLogs
GROUP BY action
ORDER BY 次数 DESC;

-- 清理测试数据（可选）
/*
DELETE FROM BorrowRecords WHERE reader_id IN (5, 6, 7);
DELETE FROM Reservations WHERE reader_id IN (2, 3);
DELETE FROM Fines WHERE reader_id = 4 AND issue_date > '2024-05-01';
DELETE FROM Books WHERE isbn = '978-7-123-45678-9' OR isbn = '978-7-000-00000-0';
DELETE FROM Readers WHERE student_id = '20210009';
*/

-- 测试完成输出
SELECT '✅ 数据库测试用例执行完成！' AS 测试结果;
