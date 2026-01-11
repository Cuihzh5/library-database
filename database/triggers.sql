-- ================================
-- 触发器定义 - 修正版
-- ================================

-- 注意：在MySQL命令行或某些工具中，需要单独执行每个触发器
-- 如果一次执行全部，需要正确使用DELIMITER

-- 1. 借书时减少可用副本数
DELIMITER $$
CREATE TRIGGER trg_after_borrow_insert
AFTER INSERT ON BorrowRecords
FOR EACH ROW
BEGIN
    IF NEW.status = '借出中' THEN
        UPDATE Books 
        SET available_copies = available_copies - 1,
            updated_at = NOW()
        WHERE book_id = NEW.book_id;
    END IF;
END$$
DELIMITER ;

-- 2. 还书时增加可用副本数
DELIMITER $$
CREATE TRIGGER trg_after_borrow_update
AFTER UPDATE ON BorrowRecords
FOR EACH ROW
BEGIN
    IF OLD.status = '借出中' AND NEW.status = '已归还' THEN
        UPDATE Books 
        SET available_copies = available_copies + 1,
            updated_at = NOW()
        WHERE book_id = NEW.book_id;
    END IF;
END$$
DELIMITER ;

-- 3. 预约时减少可用副本数
DELIMITER $$
CREATE TRIGGER trg_after_reservation_insert
AFTER INSERT ON Reservations
FOR EACH ROW
BEGIN
    IF NEW.status = '等待中' THEN
        UPDATE Books 
        SET available_copies = available_copies - 1,
            updated_at = NOW()
        WHERE book_id = NEW.book_id;
    END IF;
END$$
DELIMITER ;

-- 4. 预约取消或过期时恢复副本数
DELIMITER $$
CREATE TRIGGER trg_after_reservation_update
AFTER UPDATE ON Reservations
FOR EACH ROW
BEGIN
    IF OLD.status = '等待中' AND NEW.status IN ('已取消', '已过期') THEN
        UPDATE Books 
        SET available_copies = available_copies + 1,
            updated_at = NOW()
        WHERE book_id = NEW.book_id;
    END IF;
END$$
DELIMITER ;

-- 5. 检查借阅数量限制
DELIMITER $$
CREATE TRIGGER trg_before_borrow_insert
BEFORE INSERT ON BorrowRecords
FOR EACH ROW
BEGIN
    DECLARE current_borrow_count INT;
    DECLARE max_limit INT;
    
    -- 获取当前借阅数量
    SELECT COUNT(*) INTO current_borrow_count
    FROM BorrowRecords
    WHERE reader_id = NEW.reader_id AND status = '借出中';
    
    -- 获取最大借阅限制
    SELECT max_borrow_limit INTO max_limit
    FROM Readers
    WHERE reader_id = NEW.reader_id;
    
    -- 检查是否超过限制
    IF current_borrow_count >= max_limit THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = CONCAT('借阅数量已达上限（', max_limit, '本），请先归还部分图书');
    END IF;
END$$
DELIMITER ;

-- 6. 自动生成逾期罚款
DELIMITER $$
CREATE TRIGGER trg_generate_overdue_fine
AFTER UPDATE ON BorrowRecords
FOR EACH ROW
BEGIN
    DECLARE overdue_days INT;
    
    -- 当借阅状态变为逾期时
    IF NEW.status = '逾期' AND OLD.status != '逾期' THEN
        SET overdue_days = DATEDIFF(CURDATE(), NEW.due_date);
        
        -- 只有逾期天数大于0才生成罚款
        IF overdue_days > 0 THEN
            INSERT INTO Fines (reader_id, amount, reason, related_record_id, issue_date)
            VALUES (
                NEW.reader_id,
                overdue_days * 0.5, -- 每天0.5元罚款
                '逾期',
                NEW.record_id,
                CURDATE()
            );
        END IF;
    END IF;
END$$
DELIMITER ;
