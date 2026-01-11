-- ================================
-- 高校图书馆管理系统 - 数据库建表语句
-- ================================

-- 创建数据库
CREATE DATABASE IF NOT EXISTS LibraryDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE LibraryDB;

-- 1. 读者表
CREATE TABLE Readers (
    reader_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '读者ID',
    student_id VARCHAR(20) UNIQUE NOT NULL COMMENT '学号',
    name VARCHAR(50) NOT NULL COMMENT '姓名',
    college VARCHAR(100) COMMENT '学院',
    phone VARCHAR(20) COMMENT '联系电话',
    email VARCHAR(100) COMMENT '邮箱',
    max_borrow_limit INT DEFAULT 5 COMMENT '最大借阅数',
    status ENUM('正常', '挂失', '黑名单', '注销') DEFAULT '正常' COMMENT '账户状态',
    register_date DATE DEFAULT (CURRENT_DATE) COMMENT '注册日期',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='读者信息表';

-- 2. 图书表
CREATE TABLE Books (
    book_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '图书ID',
    isbn VARCHAR(20) UNIQUE NOT NULL COMMENT 'ISBN号',
    title VARCHAR(200) NOT NULL COMMENT '书名',
    author VARCHAR(100) COMMENT '作者',
    publisher VARCHAR(100) COMMENT '出版社',
    category VARCHAR(50) COMMENT '分类',
    publish_year YEAR COMMENT '出版年份',
    total_copies INT DEFAULT 1 COMMENT '总副本数',
    available_copies INT DEFAULT 1 COMMENT '可用副本数',
    location VARCHAR(50) COMMENT '书架位置',
    price DECIMAL(10,2) COMMENT '价格',
    description TEXT COMMENT '图书简介',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='图书信息表';

-- 3. 借阅记录表
CREATE TABLE BorrowRecords (
    record_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '记录ID',
    reader_id INT NOT NULL COMMENT '读者ID',
    book_id INT NOT NULL COMMENT '图书ID',
    borrow_date DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '借出时间',
    due_date DATE NOT NULL COMMENT '应还日期',
    return_date DATETIME NULL COMMENT '实际归还时间',
    status ENUM('借出中', '已归还', '逾期', '丢失') DEFAULT '借出中' COMMENT '借阅状态',
    renewal_count INT DEFAULT 0 COMMENT '续借次数',
    librarian_id INT COMMENT '办理馆员ID',
    notes TEXT COMMENT '备注',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (reader_id) REFERENCES Readers(reader_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE,
    INDEX idx_reader_status (reader_id, status),
    INDEX idx_due_date (due_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='借阅记录表';

-- 4. 预约表
CREATE TABLE Reservations (
    reservation_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '预约ID',
    reader_id INT NOT NULL COMMENT '读者ID',
    book_id INT NOT NULL COMMENT '图书ID',
    reserve_date DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '预约时间',
    pickup_deadline DATE NOT NULL COMMENT '最晚取书日期',
    status ENUM('等待中', '已取书', '已取消', '已过期') DEFAULT '等待中' COMMENT '预约状态',
    notes TEXT COMMENT '备注',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (reader_id) REFERENCES Readers(reader_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE,
    INDEX idx_status_book (status, book_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='图书预约表';

-- 5. 座位表
CREATE TABLE Seats (
    seat_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '座位ID',
    room_number VARCHAR(10) NOT NULL COMMENT '房间号',
    seat_number VARCHAR(10) NOT NULL COMMENT '座位号',
    floor INT COMMENT '楼层',
    area VARCHAR(50) COMMENT '区域',
    status ENUM('空闲', '使用中', '维护中') DEFAULT '空闲' COMMENT '座位状态',
    has_power BOOLEAN DEFAULT FALSE COMMENT '是否有电源',
    has_light BOOLEAN DEFAULT TRUE COMMENT '是否有台灯',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_room_seat (room_number, seat_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='座位信息表';

-- 6. 座位预约表
CREATE TABLE SeatReservations (
    seat_res_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '预约记录ID',
    reader_id INT NOT NULL COMMENT '读者ID',
    seat_id INT NOT NULL COMMENT '座位ID',
    reserve_start DATETIME NOT NULL COMMENT '预约开始时间',
    reserve_end DATETIME NOT NULL COMMENT '预约结束时间',
    checkin_time DATETIME NULL COMMENT '签到时间',
    checkout_time DATETIME NULL COMMENT '签退时间',
    status ENUM('预约中', '使用中', '已完成', '已取消', '未签到') DEFAULT '预约中' COMMENT '预约状态',
    notes TEXT COMMENT '备注',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (reader_id) REFERENCES Readers(reader_id) ON DELETE CASCADE,
    FOREIGN KEY (seat_id) REFERENCES Seats(seat_id) ON DELETE CASCADE,
    INDEX idx_reserve_time (reserve_start, reserve_end),
    INDEX idx_reader_status (reader_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='座位预约表';

-- 7. 罚款记录表
CREATE TABLE Fines (
    fine_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '罚款ID',
    reader_id INT NOT NULL COMMENT '读者ID',
    amount DECIMAL(10,2) NOT NULL COMMENT '罚款金额',
    reason ENUM('逾期', '损坏', '丢失') NOT NULL COMMENT '罚款原因',
    related_record_id INT NULL COMMENT '相关借阅记录ID',
    issue_date DATE NOT NULL COMMENT '罚款日期',
    paid_date DATE NULL COMMENT '支付日期',
    status ENUM('未支付', '已支付') DEFAULT '未支付' COMMENT '支付状态',
    payment_method VARCHAR(20) COMMENT '支付方式',
    notes TEXT COMMENT '备注',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (reader_id) REFERENCES Readers(reader_id) ON DELETE CASCADE,
    INDEX idx_reader_status (reader_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='罚款记录表';

-- 8. 图书馆员表
CREATE TABLE Librarians (
    librarian_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '馆员ID',
    employee_id VARCHAR(20) UNIQUE NOT NULL COMMENT '工号',
    name VARCHAR(50) NOT NULL COMMENT '姓名',
    position VARCHAR(50) COMMENT '岗位',
    department VARCHAR(50) COMMENT '所属部门',
    phone VARCHAR(20) COMMENT '联系电话',
    email VARCHAR(100) COMMENT '邮箱',
    work_status ENUM('在岗', '休假', '离职') DEFAULT '在岗' COMMENT '工作状态',
    hire_date DATE COMMENT '入职日期',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='图书馆员表';

-- 9. 采购记录表
CREATE TABLE Purchases (
    purchase_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '采购ID',
    book_id INT NOT NULL COMMENT '图书ID',
    quantity INT NOT NULL COMMENT '采购数量',
    unit_price DECIMAL(10,2) COMMENT '单价',
    total_amount DECIMAL(10,2) COMMENT '总金额',
    purchase_date DATE NOT NULL COMMENT '采购日期',
    purchaser_id INT COMMENT '采购员ID',
    supplier VARCHAR(100) COMMENT '供应商',
    invoice_no VARCHAR(50) COMMENT '发票号',
    notes TEXT COMMENT '备注',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='采购记录表';

-- 10. 系统日志表
CREATE TABLE SystemLogs (
    log_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '日志ID',
    user_type ENUM('读者', '馆员', '系统') COMMENT '用户类型',
    user_id INT COMMENT '用户ID',
    action VARCHAR(100) NOT NULL COMMENT '操作类型',
    description TEXT COMMENT '操作描述',
    ip_address VARCHAR(45) COMMENT 'IP地址',
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间',
    INDEX idx_log_time (log_time),
    INDEX idx_user_action (user_id, action)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统日志表';
