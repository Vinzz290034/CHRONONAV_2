// server.js (Node.js API)
// This server is configured to listen on PORT 3000.

// ------------------------------------------------------------------------------
// 1. CONFIGURATION & DEPENDENCIES
// ------------------------------------------------------------------------------
const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const fs = require('fs'); 

const app = express(); // Main Express application instance
const PORT = 3000;
const JWT_SECRET = 'YOUR_SUPER_SECURE_SECRET_KEY_12345'; 

// ------------------------------------------------------------------------------
// 2. UTILITY FUNCTIONS
// ------------------------------------------------------------------------------

/**
 * Utility function to get the base INSERT query for the add_pdf table
 * 🎯 UPDATED: Changed 'location' to 'room' in the query columns.
 */
const getScheduleInsertQuery = () => `
    INSERT INTO add_pdf
    (schedule_code, title, description, schedule_type, start_date, end_date, start_time, end_time, day_of_week, repeat_frequency, room, user_id)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
`;

// Utility function to prepare the values array for a single schedule entry
// 🎯 UPDATED: Changed 'entry.location' to 'entry.room' and 'location || null' to 'room || null'.
const extractScheduleValues = (entry, userId) => [
    entry.schedule_code,
    entry.title,
    entry.description || null,
    entry.schedule_type,
    entry.start_date,
    entry.end_date || null,
    entry.start_time,
    entry.end_time || null,
    entry.day_of_week || null,
    entry.repeat_frequency,
    entry.room || null, // MUST use 'room' now
    userId,
];



/**
 * Placeholder for the actual PDF parsing logic.
 * 🎯 UPDATED: Changed mock data key from 'location' to 'room'.
 */
const extractSchedulesFromPdf = async (filePath) => {
    // Console log the starting point for tracking
    console.log(`⏳ Starting schedule extraction for file: ${filePath}`);
    
    // --- Mock Extracted Data (Return actual extracted data here) ---
    return [
        { 
            schedule_code: 'MOCK-001', 
            title: 'Extracted Class A', 
            schedule_type: 'class', 
            start_date: '2025-12-10', 
            start_time: '09:00:00', 
            repeat_frequency: 'weekly',
            description: 'Section 101 Lecture.',
            room: 'Room 305' // Added mock room
        },
        { 
            schedule_code: 'MOCK-002', 
            title: 'Extracted Final Exam Review', 
            schedule_type: 'meeting', 
            start_date: '2025-12-15', 
            end_date: '2025-12-15',
            start_time: '14:00:00', 
            end_time: '16:00:00',
            repeat_frequency: 'none',
            room: 'Main Auditorium' // Changed key from location to room
        },
    ];
};

/**
 * Standardized function for logging and responding to server errors (500).
 */
const handleServerError = (res, error, message = 'Internal server error.') => {
    // CRITICAL: Log the actual error stack for debugging
    console.error(`❌ ${message}`, error.stack || error); 
    res.status(500).json({ success: false, message: `Server error: ${message}`, error_detail: error.message });
};

/**
 * Converts a database relative path (e.g., 'uploads/profiles/file.png') to a full public URL.
 */
const formatPhotoUrl = (dbPath) => {
    if (!dbPath) return null;
    const cleanPath = dbPath.replace(/\\/g, '/');
    // NOTE: This assumes the client can reach localhost:3000. Use 10.0.2.2 for Android emulator.
    return `http://localhost:${PORT}/${cleanPath}`; 
};

/**
 * Deletes the old profile photo from disk before uploading a new one.
 */
const deleteOldProfilePhoto = async (userId, connection) => {
    try {
        const [results] = await connection.query('SELECT profile_img FROM users WHERE id = ?', [userId]);
        const oldRelativePath = results[0]?.profile_img; 

        if (oldRelativePath && !oldRelativePath.includes('default-avatar.png')) {
            const absolutePath = path.join(__dirname, oldRelativePath); 

            if (fs.existsSync(absolutePath)) {
                fs.unlinkSync(absolutePath);
                console.log(`✅ Deleted old profile photo: ${absolutePath}`);
            } else {
                console.log(`⚠️ Warning: Old profile photo path found in DB, but file does not exist: ${absolutePath}`);
            }
        }
    } catch (error) {
        console.error('Error deleting old profile photo:', error);
    }
};

// ------------------------------------------------------------------------------
// 3. DATABASE CONNECTION POOL
// ------------------------------------------------------------------------------
const pool = mysql.createPool({
    connectionLimit: 10,
    host: 'localhost',
    user: 'root',
    password: '', 
    database: 'chrononav_web_doss',
    waitForConnections: true,
    queueLimit: 0,
});

// Database Connection Test
(async () => {
    try {
        const connection = await pool.getConnection();
        console.log(`✅ Connected to chrononav_web_doss as thread id ${connection.threadId}`);
        connection.release();
    } catch (err) {
        console.error('❌ FATAL ERROR: Could not connect to database:', err.stack);
        // Process exit commented out for interactive environments but required for critical production servers
        // process.exit(1); 
    }
})();


// ------------------------------------------------------------------------------
// 4. MIDDLEWARE SETUP (GLOBAL & AUTH)
// ------------------------------------------------------------------------------
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads'))); // Serve static files

/**
 * JWT Authentication Middleware
 */
const verifyToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ message: 'Error: Access token missing.' });
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            // Handle both expired and invalid token errors
            console.error('JWT Verification Failed:', err); // Log JWT error details
            return res.status(403).json({ message: 'Error: Invalid or expired token.' });
        }
        req.user = user;
        next();
    });
};

// --- Multer Storage Configuration for Profile Photos ---
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const dir = 'uploads/profile_photos/';
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }
        cb(null, dir);
    },
    filename: (req, file, cb) => {
        const userId = req.user.id; 
        const fileExtension = path.extname(file.originalname);
        cb(null, `${userId}-${Date.now()}${fileExtension}`); 
    }
});

const upload = multer({ 
    storage: storage,
    limits: { fileSize: 5 * 1024 * 1024 } 
});


// --- NEW: Multer Storage Configuration for Schedule PDFs ---
const schedulePdfStorage = multer.diskStorage({
    destination: (req, file, cb) => {
        const dir = 'uploads/temp_schedules/'; // Temporary directory for PDFs
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }
        cb(null, dir);
    },
    filename: (req, file, cb) => {
        const userId = req.user.id; 
        const fileExtension = path.extname(file.originalname);
        cb(null, `schedule-pdf-${userId}-${Date.now()}${fileExtension}`); 
    }
});
// server.js (Section 4: MIDDLEWARE SETUP)

// server.js (Section 4: MIDDLEWARE SETUP)

const uploadSchedulePdf = multer({ 
    storage: schedulePdfStorage,
    limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
    fileFilter: (req, file, cb) => {
        const mimeTypeAccepted = (
            file.mimetype === 'application/pdf' || 
            file.mimetype.startsWith('image/') // Allows any standard image type (jpg, png, webp, gif, etc.)
        );
        
        // Fallback check using file extension (more reliable on some platforms)
        const fileExtension = path.extname(file.originalname).toLowerCase();
        const extensionAccepted = (
            fileExtension === '.pdf' ||
            fileExtension === '.jpg' ||
            fileExtension === '.jpeg' ||
            fileExtension === '.png' ||
            fileExtension === '.gif' ||
            fileExtension === '.webp'
        );

        if (mimeTypeAccepted || extensionAccepted) {
            cb(null, true);
        } else {
            cb(new Error('Only PDF or common image files (JPG/PNG/GIF/WEBP) are allowed.'), false); 
        }
    }
});

// ------------------------------------------------------------------------------
// 5. API ENDPOINTS
// ------------------------------------------------------------------------------

// POST /api/login: User login endpoint
app.post('/api/login', async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ message: 'Email and password are required.' });
    }

    // ADDED: Input validation for email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
        return res.status(400).json({ message: 'Invalid email format.' });
    }

    try {
        const query = 'SELECT id, name, email, password, role, course, department, profile_img, is_active FROM users WHERE email = ?';
        const [results] = await pool.query(query, [email]);

        if (results.length === 0) {
            // Security: Use a generic error message
            return res.status(401).json({ message: 'Invalid email or password.' });
        }

        const user = results[0];

        if (user.is_active === 0) {
            return res.status(403).json({ message: 'Account is deactivated. Please contact support.' });
        }

        const isPasswordValid = await bcrypt.compare(password, user.password);
        
        if (isPasswordValid) {
            const token = jwt.sign(
                { id: user.id, email: user.email, role: user.role },
                JWT_SECRET,
                { expiresIn: '24h' }
            );

            const photo_url = formatPhotoUrl(user.profile_img);

            const userData = {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                course: user.course,
                department: user.department,
                photo_url: photo_url 
            };

            return res.status(200).json({
                message: 'Login successful',
                token: token,
                user: userData
            });
        } else {
            // Security: Use a generic error message
            return res.status(401).json({ message: 'Invalid email or password.' });
        }
    } catch (error) {
        return handleServerError(res, error, 'Error during login');
    }
});

// POST /api/register: User registration endpoint
app.post('/api/register', async (req, res) => {
    const { fullname, email, password, role, course, department } = req.body;

    // Basic required field check
    if (!fullname || !email || !password || !role || !course || !department) {
        return res.status(400).json({ message: 'All fields are required.' });
    }

    // --- CRITICAL SECURITY & DATA VALIDATION ADDED HERE ---
    
    // Email Format Validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
        return res.status(400).json({ message: 'Invalid email format.' });
    }

    // Role ENUM Validation (Fixes the blank role issue)
    const allowedRoles = ['user', 'faculty', 'admin']; 
    if (!allowedRoles.includes(role.toLowerCase())) {
        return res.status(400).json({ 
            message: `Invalid role specified. Role must be one of: ${allowedRoles.join(', ')}.` 
        });
    }

    // Input Length Validation (Checks against varchar(100) limit)
    const MAX_VARCHAR_LENGTH = 100;
    if (fullname.length > MAX_VARCHAR_LENGTH || course.length > MAX_VARCHAR_LENGTH || department.length > MAX_VARCHAR_LENGTH) {
        return res.status(400).json({ 
            message: `Input fields (Name, Course, Department) must be less than or equal to ${MAX_VARCHAR_LENGTH} characters.` 
        });
    }
    // --- END VALIDATION ---

    try {
        const [checkResults] = await pool.query('SELECT email FROM users WHERE email = ?', [email]);
        
        if (checkResults.length > 0) {
            return res.status(409).json({ message: 'Registration failed. The email is already registered.' });
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        
        const defaultProfileImg = 'uploads/profile_photos/default-avatar.png'; 
        
        // Ensure the role variable being inserted is consistently lowercased to match the ENUM
        const normalizedRole = role.toLowerCase(); 

        const insertQuery = `INSERT INTO users (name, email, password, role, course, department, profile_img, is_active) VALUES (?, ?, ?, ?, ?, ?, ?, 1)`;

        const [results] = await pool.query(insertQuery, 
            [fullname, email, hashedPassword, normalizedRole, course, department, defaultProfileImg]
        );
        
        const userId = results.insertId;
        const token = jwt.sign(
            { id: userId, email: email, role: normalizedRole },
            JWT_SECRET,
            { expiresIn: '24h' }
        );
        
        const photo_url = formatPhotoUrl(defaultProfileImg);

        res.status(201).json({
            message: 'User registered successfully!',
            token: token,
            user: { 
                id: userId, 
                name: fullname, 
                email: email, 
                role: normalizedRole, 
                course: course, 
                department: department,
                photo_url: photo_url 
            }
        });
    } catch (error) {
        return handleServerError(res, error, 'CRITICAL DATABASE ERROR during registration');
    }
});

// GET /api/profile: Fetch user profile
app.get('/api/profile', verifyToken, async (req, res) => {
// ... [Profile logic unchanged]
    try {
        const query = 'SELECT id, name, email, role, course, department, profile_img FROM users WHERE id = ?';
        const [results] = await pool.query(query, [req.user.id]);
        
        if (results.length === 0) {
            return res.status(404).json({ message: 'Profile not found.' });
        }
        
        const user = results[0];
        
        user.photo_url = formatPhotoUrl(user.profile_img);
        delete user.profile_img; 

        res.status(200).json(user);
    } catch (error) {
        return handleServerError(res, error, 'Error fetching profile');
    }
});


// POST /api/profile (Handles update & file upload)
app.post('/api/profile', verifyToken, upload.single('profilePhoto'), async (req, res) => {
// ... [Profile update logic unchanged]
    const userId = req.user.id;
    const { name, course, department } = req.body;
    const file = req.file; 

    const cleanUpFile = (f) => {
        if (f && fs.existsSync(f.path)) { fs.unlinkSync(f.path); }
    };

    if (!name || !course || !department) {
        cleanUpFile(file);
        return res.status(400).json({ message: 'Full Name, Course, and Department are required fields.' });
    }

    let connection;
    try {
        connection = await pool.getConnection();
        await connection.beginTransaction();

        let updateQuery = 'UPDATE users SET name = ?, course = ?, department = ?';
        let queryParams = [name, course, department];
        
        if (file) {
            await deleteOldProfilePhoto(userId, connection);
            
            const profileImgPath = path.join('uploads', 'profile_photos', file.filename).replace(/\\/g, '/');
            
            updateQuery += ', profile_img = ?';
            queryParams.push(profileImgPath);
        }

        updateQuery += ' WHERE id = ?';
        queryParams.push(userId);

        await connection.query(updateQuery, queryParams);
        await connection.commit();

        const [updatedUserResults] = await connection.query(
            'SELECT id, name, email, role, course, department, profile_img FROM users WHERE id = ?', 
            [userId]
        );
        
        const updatedUser = updatedUserResults[0];
        updatedUser.photo_url = formatPhotoUrl(updatedUser.profile_img);
        delete updatedUser.profile_img; 

        return res.status(200).json({ 
            message: 'Profile updated successfully!', 
            user: updatedUser 
        });

    } catch (error) {
        await connection?.rollback();
        cleanUpFile(file);
        return handleServerError(res, error, 'Error during profile update');
    } finally {
        if (connection) connection.release();
    }
});


// POST /api/user/change-password: Change user password
app.post('/api/user/change-password', verifyToken, async (req, res) => {
// ... [Password change logic unchanged]
    const userId = req.user.id; 
    const { currentPassword, newPassword } = req.body; 

    if (!currentPassword || !newPassword) {
        return res.status(400).json({ message: 'Current and new passwords are required.' });
    }
    if (newPassword.length < 6) {
        return res.status(400).json({ message: 'New password must be at least 6 characters.' });
    }

    try {
        const [users] = await pool.query('SELECT password FROM users WHERE id = ?', [userId]);

        if (users.length === 0) {
            return res.status(404).json({ message: 'User not found.' });
        }

        const user = users[0];
        const isPasswordValid = await bcrypt.compare(currentPassword, user.password);

        if (!isPasswordValid) {
            return res.status(401).json({ message: 'Incorrect current password.' }); 
        }
        
        const newPasswordHash = await bcrypt.hash(newPassword, 10);
        const updateQuery = 'UPDATE users SET password = ? WHERE id = ?';
        await pool.query(updateQuery, [newPasswordHash, userId]);

        return res.status(200).json({ message: 'Password updated successfully.' }); 

    } catch (error) {
        return handleServerError(res, error, 'Error during secure password change');
    }
});

// POST /api/user/deactivate: Logically deactivate user account
app.post('/api/user/deactivate', verifyToken, async (req, res) => {
// ... [Deactivate logic unchanged]
    const userId = req.user.id; 
    const { currentPassword } = req.body; 

    if (!currentPassword) {
        return res.status(400).json({ message: 'Current password is required to deactivate the account.' });
    }

    try {
        const [users] = await pool.query('SELECT password, is_active FROM users WHERE id = ?', [userId]);

        if (users.length === 0) {
            return res.status(404).json({ message: 'User not found.' });
        }

        const user = users[0];
        const isPasswordValid = await bcrypt.compare(currentPassword, user.password);

        if (!isPasswordValid) {
            return res.status(401).json({ message: 'Incorrect current password.' }); 
        }

        if (user.is_active === 0) {
            return res.status(400).json({ message: 'Account is already deactivated.' });
        }
        
        const updateQuery = 'UPDATE users SET is_active = 0, status = "inactive" WHERE id = ?';
        await pool.query(updateQuery, [userId]);

        return res.status(200).json({ message: 'Account deactivated successfully. You are now logged out.' });

    } catch (error) {
        return handleServerError(res, error, 'Error during account deactivation');
    }
});

// POST /api/feedback: Handles user feedback submission
app.post('/api/feedback', verifyToken, async (req, res) => {
// ... [Feedback logic unchanged]
    const userId = req.user.id; 
    const { subject, message, feedback_type, rating } = req.body;

    if (!subject || !message || !feedback_type || rating == null) { 
        return res.status(400).json({ message: 'Subject, message, feedback type, and rating are required.' });
    }

    const insertQuery = `
        INSERT INTO feedback (user_id, feedback_type, subject, message, rating) 
        VALUES (?, ?, ?, ?, ?)
    `;
    
    try {
        await pool.query(insertQuery, [userId, feedback_type, subject, message, rating]);
        console.log(`✅ Feedback received from user ${userId}. Type: ${feedback_type}, Subject: ${subject}`);
        
        return res.status(201).json({ message: 'Feedback submitted successfully.' });
    } catch (error) {
        return handleServerError(res, error, 'Error saving feedback to database');
    }
});

// ------------------------------------------------------------------------------
// TICKET ROUTES
// ------------------------------------------------------------------------------

/**
 * POST /api/tickets: Creates a new support ticket.
 */
app.post('/api/tickets', verifyToken, async (req, res) => {
// ... [Ticket creation logic unchanged]
    const userId = req.user.id; 
    const { subject, message } = req.body;

    if (!subject || !message) {
        return res.status(400).json({ message: 'Subject and message are required to create a ticket.' });
    }

    const insertQuery = 'INSERT INTO tickets (user_id, subject, message, status) VALUES (?, ?, ?, ?)';
    
    try {
        const [result] = await pool.query(
            insertQuery,
            [userId, subject, message, 'open']
        );
        
        const [rows] = await pool.query(
            'SELECT id, user_id, subject, message, status, admin_reply, created_at, updated_at FROM tickets WHERE id = ?',
            [result.insertId]
        );
        
        const newTicket = rows[0];

        if (newTicket.created_at) newTicket.created_at = new Date(newTicket.created_at).toISOString();
        if (newTicket.updated_at) newTicket.updated_at = new Date(newTicket.updated_at).toISOString();

        res.status(201).json({ 
            message: 'Ticket created successfully!', 
            ticket: newTicket 
        });

    } catch (error) {
        return handleServerError(res, error, 'Error creating ticket');
    }
});

/**
 * GET /api/tickets: Fetches all tickets submitted by the authenticated user.
 */
app.get('/api/tickets', verifyToken, async (req, res) => {
// ... [Ticket fetch logic unchanged]
    const userId = req.user.id; 

    try {
        const query = 'SELECT id, user_id, subject, message, status, admin_reply, created_at, updated_at FROM tickets WHERE user_id = ? ORDER BY created_at DESC';
        
        const [rows] = await pool.query(query, [userId]);
        
        const tickets = rows.map(ticket => ({
            ...ticket,
            created_at: ticket.created_at ? new Date(ticket.created_at).toISOString() : null,
            updated_at: ticket.updated_at ? new Date(ticket.updated_at).toISOString() : null,
        }));

        res.status(200).json(tickets);
    } catch (error) {
        return handleServerError(res, error, 'Error fetching tickets');
    }
});


// ------------------------------------------------------------------------------
// ANNOUNCEMENT ROUTES
// ------------------------------------------------------------------------------
app.get('/api/announcements', async (req, res) => {
// ... [Announcement logic unchanged]
    try {
        const query = `
            SELECT 
                a.id, 
                a.title, 
                a.content, 
                a.published_at, 
                u.name AS author_name
            FROM announcements a
            JOIN users u ON a.user_id = u.id
            ORDER BY a.published_at DESC
        `;
        
        const [rows] = await pool.query(query.trim());

        const announcements = rows.map(announcement => {
            const publishedAtISO = announcement.published_at 
                ? new Date(announcement.published_at).toISOString() 
                : null;

            return {
                id: announcement.id,
                title: announcement.title,
                content: announcement.content,
                published_at: publishedAtISO, 
                author_name: announcement.author_name,
            };
        });
        
        res.status(200).json({ 
            success: true, 
            message: "Announcements fetched successfully.",
            announcements: announcements 
        });
    } catch (error) {
        return handleServerError(res, error, 'Error fetching announcements');
    }
});


// ------------------------------------------------------------------------------
// SCHEDULE ROUTES (add_pdf table)
// ------------------------------------------------------------------------------

// POST /api/upload/schedule_file: NEW ROUTE to handle PDF upload and extraction
app.post('/api/upload/schedule_file', verifyToken, uploadSchedulePdf.single('schedule_file'), async (req, res) => {
    const userId = req.user.id;

    if (!req.file) {
        // Check if Multer threw an error (e.g., file size or type)
        if (req.fileValidationError) {
            return res.status(400).json({ success: false, message: req.fileValidationError });
        }
        return res.status(400).json({ success: false, message: 'No PDF file was uploaded or file type is invalid (must be PDF).' });
    }

    const filePath = req.file.path;

    // Helper to remove the temp file
    const cleanupFile = () => {
        if (fs.existsSync(filePath)) {
            fs.unlinkSync(filePath);
            console.log(`🗑️ Cleaned up temporary file: ${filePath}`);
        }
    };

    try {
        // 1. Extract data from the PDF
        const extractedSchedules = await extractSchedulesFromPdf(filePath);
        
        // 2. Cleanup the temporary PDF file immediately after processing
        cleanupFile();

        if (extractedSchedules.length === 0) {
             return res.status(200).json({ 
                success: true, 
                message: 'PDF processed, but no schedules were extracted.',
                extracted_count: 0,
                schedules: []
            });
        }
        
        // 3. Return the extracted data to the client (for review before bulk_save)
        return res.status(200).json({ 
            success: true, 
            message: `${extractedSchedules.length} schedules extracted successfully. Ready for saving.`, 
            extracted_count: extractedSchedules.length,
            // The JSON returned here will automatically use 'room' if extractSchedulesFromPdf does.
            schedules: extractedSchedules 
        });

    } catch (error) {
        cleanupFile(); // Ensure cleanup on error
        // Check for Multer file filter error specifically
        if (error.message === 'Only PDF files are allowed.') {
            return res.status(400).json({ success: false, message: error.message });
        }
        return handleServerError(res, error, 'Schedule PDF Processing Error');
    }
});

// POST /api/upload_schedule: Uploads a single schedule entry (manual form submission)
app.post('/api/upload_schedule', verifyToken, async (req, res) => {
// ... [Upload schedule logic unchanged]
    const userId = req.user.id;
    const entry = req.body; // Expects 'room' field from client

    if (!entry.schedule_code || !entry.title || !entry.schedule_type || !entry.start_date || !entry.start_time || !entry.repeat_frequency) {
        return res.status(400).json({
            success: false,
            message: 'Missing required schedule fields: schedule_code, title, schedule_type, start_date, start_time, or repeat_frequency.'
        });
    }

    const query = getScheduleInsertQuery();
    const values = extractScheduleValues(entry, userId); // Uses updated values function

    try {
        const [results] = await pool.execute(query, values);

        if (results.affectedRows === 1) {
            return res.status(201).json({ success: true, message: 'Schedule data uploaded successfully!', id: results.insertId });
        } else {
            return res.status(500).json({ success: false, message: 'Failed to insert data into the database.' });
        }
    } catch (error) {
        return handleServerError(res, error, 'Database insertion error for upload_schedule');
    }
});

// POST /api/schedules/bulk_save: Bulk save schedules extracted from PDF
app.post('/api/schedules/bulk_save', verifyToken, async (req, res) => {
// ... [Bulk save logic unchanged]
    const userId = req.user.id;
    const scheduleEntries = req.body.schedules; // Each entry must contain 'room'

    if (!scheduleEntries || !Array.isArray(scheduleEntries) || scheduleEntries.length === 0) {
        return res.status(400).json({
            success: false,
            message: 'Invalid or empty list of schedule entries provided.'
        });
    }

    const insertQuery = getScheduleInsertQuery(); // Uses query with 'room'
    let connection;
    let insertedCount = 0;
    
    try {
        connection = await pool.getConnection();
        await connection.beginTransaction();

        for (const entry of scheduleEntries) {
            if (!entry.schedule_code || !entry.title || !entry.schedule_type || !entry.start_date || !entry.start_time || !entry.repeat_frequency) {
                console.warn('Skipping schedule entry due to missing required fields:', entry);
                continue; 
            }

            const values = extractScheduleValues(entry, userId); // Uses updated values function
            const [results] = await connection.execute(insertQuery, values);
            
            if (results.affectedRows === 1) {
                insertedCount++;
            }
        }

        await connection.commit();
        
        if (insertedCount === 0) {
            return res.status(200).json({ success: true, message: 'No valid schedules were found to save.', count: 0 });
        }

        return res.status(201).json({ 
            success: true, 
            message: `${insertedCount} schedules saved successfully!`, 
            count: insertedCount 
        });
    } catch (error) {
        if (connection) await connection.rollback();
        return handleServerError(res, error, 'Bulk schedule insertion failed during transaction');
    } finally {
        if (connection) connection.release();
    }
});


// GET /api/schedules: Fetch All Uploaded Schedules for the current user
app.get('/api/schedules', verifyToken, async (req, res) => {
    // 🎯 CRITICAL FIX: Get the authenticated user ID
    const userId = req.user.id; 

    try {
        const query = `
            SELECT 
                ap.id, ap.schedule_code, ap.title, ap.description, ap.schedule_type, ap.start_date, ap.end_date, ap.start_time, ap.end_time, ap.day_of_week, ap.repeat_frequency, ap.room, ap.user_id, ap.is_active, ap.created_at, ap.updated_at,
                u.name as uploader_name
            FROM add_pdf ap
            JOIN users u ON ap.user_id = u.id
            WHERE ap.user_id = ?  /* <--- CRITICAL FILTER: ONLY FETCH USER'S SCHEDULES */
            ORDER BY ap.created_at DESC
        `;
        
        // Pass the userId to the query executor
        const [schedules] = await pool.query(query.trim(), [userId]); 

        const formattedSchedules = schedules.map(schedule => ({
            ...schedule,
            created_at: schedule.created_at ? new Date(schedule.created_at).toISOString() : null,
            start_date: schedule.start_date ? new Date(schedule.start_date).toISOString().split('T')[0] : null,
            end_date: schedule.end_date ? new Date(schedule.end_date).toISOString().split('T')[0] : null,
        }));

        res.status(200).json({
            success: true,
            schedules: formattedSchedules
        });

    } catch (error) {
        return handleServerError(res, error, 'Error fetching schedules');
    }
});

// PUT /api/schedules/update/:id: Update a single schedule entry
app.put('/api/schedules/update/:id', verifyToken, async (req, res) => {
    const userId = req.user.id;
    const scheduleId = req.params.id; // Get the ID from the URL parameter
    const entry = req.body;

    // Minimal validation to ensure essential fields exist
    // NOTE: This validation is fine, assuming the Flutter app ensures these fields are present/non-null.
    if (!entry.schedule_code || !entry.title || !entry.schedule_type || !entry.start_date || !entry.start_time || !entry.repeat_frequency) {
        return res.status(400).json({
            success: false,
            message: 'Missing required schedule fields for update.'
        });
    }

    const updateQuery = `
        UPDATE add_pdf
        SET 
            schedule_code = ?, title = ?, description = ?, schedule_type = ?, 
            start_date = ?, end_date = ?, start_time = ?, end_time = ?, 
            day_of_week = ?, repeat_frequency = ?, room = ?
        WHERE id = ? AND user_id = ?
    `;

    // CRITICAL: Ensure values match the DB column definitions (NULL or actual value)
    const values = [
        entry.schedule_code,
        entry.title,
        entry.description || null, // Handles optional description
        entry.schedule_type,
        entry.start_date,
        entry.end_date || null,      // Handles optional end_date
        entry.start_time,
        entry.end_time || null,      // Handles optional end_time
        entry.day_of_week || null,   // Handles optional day_of_week
        entry.repeat_frequency,
        entry.room || null,          // Handles optional room
        scheduleId, // The ID from the URL
        userId // Ensure the user owns this record
    ];

    try {
        const [results] = await pool.execute(updateQuery, values);

        if (results.affectedRows === 0) {
            // This is the line returning the 404. It means (ID or USER_ID) mismatch.
            return res.status(404).json({ success: false, message: 'Schedule entry not found or unauthorized to update.' });
        }

        return res.status(200).json({ success: true, message: 'Schedule updated successfully!' });
    } catch (error) {
        // Ensure you use the robust error handler
        return handleServerError(res, error, 'Database update error for edit_schedule');
    }
});


// server.js (Inside SCHEDULE ROUTES section)

// DELETE /api/schedules/delete/:id: Delete a single schedule entry
app.delete('/api/schedules/delete/:id', verifyToken, async (req, res) => {
    const userId = req.user.id;
    const scheduleId = req.params.id; // Get the ID from the URL parameter

    // CRITICAL: Ensure we delete only the user's record
    const deleteQuery = `
        DELETE FROM add_pdf
        WHERE id = ? AND user_id = ?
    `;

    try {
        const [results] = await pool.execute(deleteQuery, [scheduleId, userId]);

        if (results.affectedRows === 0) {
            return res.status(404).json({ success: false, message: 'Schedule entry not found or unauthorized to delete.' });
        }

        return res.status(200).json({ success: true, message: 'Schedule deleted successfully!' });
    } catch (error) {
        return handleServerError(res, error, 'Database deletion error for delete_schedule');
    }
});


// ------------------------------------------------------------------------------
// PERSONAL CALENDAR EVENT ROUTES (user_calendar_events table)
// ------------------------------------------------------------------------------

// POST /api/events/personal: Create Personal Event Route
app.post('/api/events/personal', verifyToken, async (req, res) => {
    const userId = req.user.id; 
    const { event_name, description, start_date, end_date, location, event_type } = req.body;

    if (!event_name || !start_date) {
        return res.status(400).json({ message: 'Event name and start date are required.' });
    }
    
    const insertQuery = `
        INSERT INTO user_calendar_events 
        (user_id, event_name, description, start_date, end_date, location, event_type, is_personal)
        VALUES (?, ?, ?, ?, ?, ?, ?, 1)
    `;

    const insertValues = [
        userId, event_name, description || null, start_date, end_date || null, 
        location || null, event_type || 'Personal', 
    ];
    
    try {
        const [results] = await pool.query(insertQuery, insertValues);

        const [rows] = await pool.query('SELECT * FROM user_calendar_events WHERE id = ?', [results.insertId]);
        const newEvent = rows[0];

        res.status(201).json({
            message: 'Personal event created successfully.',
            event: newEvent
        });
    } catch (error) {
        return handleServerError(res, error, 'Error creating personal event');
    }
});

// GET /api/events/personal: Fetch Personal Events Route (REVERTED to PROTECTED with DATE FIX)
app.get('/api/events/personal', verifyToken, async (req, res) => {
    // Requires a valid JWT token to proceed.
    const userId = req.user.id; 
    
    // Selects all relevant fields from the user_calendar_events table
    const fetchQuery = `
        SELECT id, event_name, description, start_date, end_date, location, event_type, is_personal
        FROM user_calendar_events 
        WHERE user_id = ? AND is_personal = 1
        ORDER BY start_date ASC
    `;
    
    try {
        const [events] = await pool.query(fetchQuery, [userId]);
        
        // Robust Date Formatting
        const formattedEvents = events.map(event => {
            const rawStartDate = event.start_date;
            const rawEndDate = event.end_date;

            const safeToISO = (rawDateValue) => {
                if (!rawDateValue) return null;
                const dateObj = new Date(rawDateValue);
                // Check if the object is a Date and is not "Invalid Date"
                return dateObj instanceof Date && !isNaN(dateObj.getTime()) 
                    ? dateObj.toISOString() 
                    : null;
            };

            return {
                ...event,
                start_date: safeToISO(rawStartDate),
                end_date: safeToISO(rawEndDate),
            };
        });

        // Returns the array of formatted events
        res.json(formattedEvents);

    } catch (error) {
        // Uses the centralized error handler
        return handleServerError(res, error, 'Error fetching personal events');
    }
});

// PUT /api/events/personal/:id: Update Personal Event Route
app.put('/api/events/personal/:id', verifyToken, async (req, res) => {
    const userId = req.user.id;
    const eventId = req.params.id;
    const { event_name, description, start_date, end_date, location, event_type } = req.body;
    
    if (!event_name || !start_date) {
        return res.status(400).json({ message: 'Event name and start date are required for update.' });
    }

    const updateQuery = `
        UPDATE user_calendar_events
        SET event_name = ?, description = ?, start_date = ?, end_date = ?, location = ?, event_type = ?
        WHERE id = ? AND user_id = ? AND is_personal = 1
    `;

    const updateValues = [
        event_name, description || null, start_date, end_date || null, location || null, 
        event_type || 'Personal', eventId, userId
    ];
    
    try {
        const [results] = await pool.query(updateQuery, updateValues);

        if (results.affectedRows === 0) {
            return res.status(404).json({ message: 'Event not found or unauthorized to update.' });
        }
        
        const [rows] = await pool.query('SELECT * FROM user_calendar_events WHERE id = ?', [eventId]);

        res.status(200).json({
            message: 'Personal event updated successfully.',
            event: rows[0]
        });

    } catch (error) {
        return handleServerError(res, error, 'Error updating personal event');
    }
});

// DELETE /api/events/personal/:id: Delete Personal Event Route
app.delete('/api/events/personal/:id', verifyToken, async (req, res) => {
    const userId = req.user.id;
    const eventId = req.params.id;

    const deleteQuery = 'DELETE FROM user_calendar_events WHERE id = ? AND user_id = ? AND is_personal = 1';
    
    try {
        const [results] = await pool.query(deleteQuery, [eventId, userId]);

        if (results.affectedRows === 0) {
            return res.status(404).json({ message: 'Event not found or unauthorized to delete.' });
        }

        res.status(200).json({ message: 'Personal event deleted successfully.' });

    } catch (error) {
        return handleServerError(res, error, 'Error deleting personal event');
    }
});

// ------------------------------------------------------------------------------
// 🚀 NEW: CALENDAR EVENTS ROUTES (calendar_events table)
// ------------------------------------------------------------------------------

/**
 * Helper function to map calendar_events data structure from DB to a clean JSON response.
 * @param {object} event - The raw database row.
 */
const formatCalendarEvent = (event) => ({
    id: event.id,
    userId: event.user_id,
    eventName: event.event_name,
    description: event.description,
    startDate: event.start_date ? new Date(event.start_date).toISOString() : null, // Convert datetime to ISO string
    endDate: event.end_date ? new Date(event.end_date).toISOString() : null, // Convert datetime to ISO string
    location: event.location,
    eventType: event.event_type,
    createdAt: event.created_at ? new Date(event.created_at).toISOString() : null,
    updatedAt: event.updated_at ? new Date(event.updated_at).toISOString() : null,
});


// GET /api/events/calendar: Fetch all calendar events for the authenticated user
app.get('/api/events/calendar', verifyToken, async (req, res) => {
    // Get the authenticated user ID from the JWT token
    const userId = req.user.id;

    try {
        const query = `
            SELECT *
            FROM calendar_events
            WHERE user_id = ?
            ORDER BY start_date ASC, start_time ASC
        `;
        
        // 1. Execute query, filtering by user_id
        const [events] = await pool.query(query.trim(), [userId]); 

        // 2. Format the output to match the client model structure
        const formattedEvents = events.map(formatCalendarEvent);

        res.status(200).json({
            success: true,
            message: `Fetched ${formattedEvents.length} calendar events.`,
            list: formattedEvents // Matches the client's expectation: responseBody['list']
        });

    } catch (error) {
        return handleServerError(res, error, 'Error fetching calendar events');
    }
});

// ------------------------------------------------------------------------------
// 6. START SERVER
// ------------------------------------------------------------------------------
app.listen(PORT, () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
});