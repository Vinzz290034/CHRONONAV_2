// server.js (Node.js API)
// This server is configured to listen on PORT 3000.
// When testing with a mobile emulator (Android/iOS), the Flutter client 
// MUST use the host machine's IP address (e.g., 10.0.2.2:3000 for Android)
// instead of 'localhost:3000' to connect successfully.

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
const fs = require('fs'); // File System for deleting orphaned files

const app = express();
const PORT = 3000;
// CRITICAL: For production, this MUST be loaded from environment variables!
const JWT_SECRET = 'YOUR_SUPER_SECURE_SECRET_KEY_12345'; 

// ------------------------------------------------------------------------------
// 2. UTILITY FUNCTIONS
// ------------------------------------------------------------------------------

/**
 *  Utility function to get the base INSERT query for the add_pdf table
 */

const getScheduleInsertQuery = () => `
    INSERT INTO add_pdf
    (schedule_code, title, description, schedule_type, start_date, end_date, start_time, end_time, day_of_week, repeat_frequency, location, user_id)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
`;

// Utility function to prepare the values array for a single schedule entry
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
    entry.location || null,
    userId,
];

/**
 * Standardized function for logging and responding to server errors (500).
 */
const handleServerError = (res, error, message = 'Internal server error.') => {
    console.error(`❌ ${message}`, error);
    res.status(500).json({ success: false, message: `Server error: ${message}`, error: error.message });
};

/**
 * Converts a database relative path (e.g., 'uploads/profiles/file.png') to a full public URL.
 */
const formatPhotoUrl = (dbPath) => {
    if (!dbPath) return null;
    // Replace OS-specific path separators with forward slashes for URL consistency
    const cleanPath = dbPath.replace(/\\/g, '/');
    return `http://localhost:${PORT}/${cleanPath}`;
};

/**
 * Deletes the old profile photo from disk before uploading a new one.
 */
const deleteOldProfilePhoto = async (userId, connection) => {
    try {
        // Query the database for the current profile image path
        const [results] = await connection.query('SELECT profile_img FROM users WHERE id = ?', [userId]);
        const oldRelativePath = results[0]?.profile_img; 

        if (oldRelativePath && !oldRelativePath.includes('default-avatar.png')) {
            // Construct the absolute path from the stored relative path
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
        // Do not throw, as profile update should still proceed if file deletion fails
    }
};

// ------------------------------------------------------------------------------
// 3. DATABASE CONNECTION POOL
// ------------------------------------------------------------------------------
const pool = mysql.createPool({
    connectionLimit: 10,
    host: 'localhost',
    user: 'root',
    password: '', // Should be loaded from environment variable
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
        process.exit(1); 
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
            return res.status(403).json({ message: 'Error: Invalid or expired token.' });
        }
        req.user = user;
        next();
    });
};

// Multer Storage Configuration
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        // Ensure this directory path exists
        const dir = 'uploads/profile_photos/';
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }
        cb(null, dir);
    },
    filename: (req, file, cb) => {
        // NOTE: req.user should be available due to the route structure
        const userId = req.user.id; 
        const fileExtension = path.extname(file.originalname);
        cb(null, `${userId}-${Date.now()}${fileExtension}`); 
    }
});

// Define the 'upload' variable for single file uploads
// NOTE: This is used *after* verifyToken in profile routes, so req.user is available.
const upload = multer({ 
    storage: storage,
    limits: { fileSize: 5 * 1024 * 1024 } // Limit file size to 5MB
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

    try {
        const query = 'SELECT id, name, email, password, role, course, department, profile_img, is_active FROM users WHERE email = ?';
        const [results] = await pool.query(query, [email]);

        if (results.length === 0) {
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
            return res.status(401).json({ message: 'Invalid email or password.' });
        }
    } catch (error) {
        return handleServerError(res, error, 'Error during login');
    }
});

// POST /api/register: User registration endpoint
app.post('/api/register', async (req, res) => {
    const { fullname, email, password, role, course, department } = req.body;

    if (!fullname || !email || !password || !role || !course || !department) {
        return res.status(400).json({ message: 'All fields are required.' });
    }

    try {
        const [checkResults] = await pool.query('SELECT email FROM users WHERE email = ?', [email]);
        
        if (checkResults.length > 0) {
            return res.status(409).json({ message: 'Registration failed. The email is already registered.' });
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        
        // Define default profile image path relative to server root
        const defaultProfileImg = 'uploads/profile_photos/default-avatar.png'; 
        
        const insertQuery = `INSERT INTO users (name, email, password, role, course, department, profile_img, is_active) VALUES (?, ?, ?, ?, ?, ?, ?, 1)`;

        const [results] = await pool.query(insertQuery, 
            [fullname, email, hashedPassword, role, course, department, defaultProfileImg]
        );
        
        const userId = results.insertId;
        const token = jwt.sign(
            { id: userId, email: email, role: role },
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
                role: role, 
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
    try {
        const query = 'SELECT id, name, email, role, course, department, profile_img FROM users WHERE id = ?';
        const [results] = await pool.query(query, [req.user.id]);
        
        if (results.length === 0) {
            return res.status(404).json({ message: 'Profile not found.' });
        }
        
        const user = results[0];
        
        // Construct the public photo_url and clean up the raw path
        user.photo_url = formatPhotoUrl(user.profile_img);
        delete user.profile_img; 

        res.status(200).json(user);
    } catch (error) {
        return handleServerError(res, error, 'Error fetching profile');
    }
});


// POST /api/profile (Handles update & file upload)
app.post('/api/profile', verifyToken, upload.single('profilePhoto'), async (req, res) => {
    const userId = req.user.id;
    const { name, course, department } = req.body;
    const file = req.file; 

    // Utility to clean up file if an error occurs
    const cleanUpFile = (f) => {
        if (f && fs.existsSync(f.path)) { fs.unlinkSync(f.path); }
    };

    // 1. Basic Validation
    if (!name || !course || !department) {
        cleanUpFile(file); // Delete orphaned file
        return res.status(400).json({ message: 'Full Name, Course, and Department are required fields.' });
    }

    let connection;
    try {
        connection = await pool.getConnection();
        await connection.beginTransaction();

        let updateQuery = 'UPDATE users SET name = ?, course = ?, department = ?';
        let queryParams = [name, course, department];
        
        // 2. Handle File Upload
        if (file) {
            await deleteOldProfilePhoto(userId, connection);
            
            // Prepare the new relative path for the database
            const profileImgPath = path.join('uploads', 'profile_photos', file.filename).replace(/\\/g, '/');
            
            updateQuery += ', profile_img = ?';
            queryParams.push(profileImgPath);
        }

        updateQuery += ' WHERE id = ?';
        queryParams.push(userId);

        // 3. Execute the update
        await connection.query(updateQuery, queryParams);
        await connection.commit();

        // 4. Fetch the updated profile data
        const [updatedUserResults] = await connection.query(
            'SELECT id, name, email, role, course, department, profile_img FROM users WHERE id = ?', 
            [userId]
        );
        
        const updatedUser = updatedUserResults[0];
        updatedUser.photo_url = formatPhotoUrl(updatedUser.profile_img);
        delete updatedUser.profile_img; 

        // 5. Success Response
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
    const userId = req.user.id; 
    const { subject, message, feedback_type, rating } = req.body;

    // Check for null/undefined on rating
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

        // Format dates to ISO string for Flutter compatibility
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
    const userId = req.user.id; 

    try {
        const query = 'SELECT id, user_id, subject, message, status, admin_reply, created_at, updated_at FROM tickets WHERE user_id = ? ORDER BY created_at DESC';
        
        const [rows] = await pool.query(query, [userId]);
        
        // Format dates to ISO string for Flutter compatibility
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

        // Process the results: convert date objects to ISO strings
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

// POST /api/upload_schedule: Uploads a single schedule entry (manual form submission)
app.post('/api/upload_schedule', verifyToken, async (req, res) => {
    const userId = req.user.id;
    const entry = req.body;

    // Validate required fields
    if (!entry.schedule_code || !entry.title || !entry.schedule_type || !entry.start_date || !entry.start_time || !entry.repeat_frequency) {
        return res.status(400).json({
            success: false,
            message: 'Missing required schedule fields: schedule_code, title, schedule_type, start_date, start_time, or repeat_frequency.'
        });
    }

    const query = getScheduleInsertQuery();
    const values = extractScheduleValues(entry, userId);

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
    const userId = req.user.id;
    // The data is expected to be under the 'schedules' key as sent by the Flutter app
    const scheduleEntries = req.body.schedules;

    if (!scheduleEntries || !Array.isArray(scheduleEntries) || scheduleEntries.length === 0) {
        return res.status(400).json({
            success: false,
            message: 'Invalid or empty list of schedule entries provided.'
        });
    }

    const insertQuery = getScheduleInsertQuery();
    let connection;
    let insertedCount = 0;
    
    try {
        connection = await pool.getConnection();
        await connection.beginTransaction();

        for (const entry of scheduleEntries) {
            // Basic validation for required fields in each entry
            if (!entry.schedule_code || !entry.title || !entry.schedule_type || !entry.start_date || !entry.start_time || !entry.repeat_frequency) {
                console.warn('Skipping schedule entry due to missing required fields:', entry);
                continue; 
            }

            const values = extractScheduleValues(entry, userId);
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


// GET /api/schedules: Fetch All Uploaded Schedules
app.get('/api/schedules', verifyToken, async (req, res) => {
    try {
        const query = `
            SELECT 
                ap.*, 
                u.name as uploader_name
            FROM add_pdf ap
            JOIN users u ON ap.user_id = u.id
            ORDER BY ap.created_at DESC
        `;
        
        const [schedules] = await pool.query(query.trim());

        // Format dates/times to ISO strings for Flutter compatibility
        const formattedSchedules = schedules.map(schedule => ({
            ...schedule,
            // Format DATE types to YYYY-MM-DD
            created_at: schedule.created_at ? new Date(schedule.created_at).toISOString() : null,
            start_date: schedule.start_date ? new Date(schedule.start_date).toISOString().split('T')[0] : null,
            end_date: schedule.end_date ? new Date(schedule.end_date).toISOString().split('T')[0] : null,
            // Time fields (start_time, end_time) are assumed to be strings and are returned as is.
        }));

        res.status(200).json({
            success: true,
            schedules: formattedSchedules
        });

    } catch (error) {
        return handleServerError(res, error, 'Error fetching schedules');
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

// GET /api/events/personal: Fetch Personal Events Route
app.get('/api/events/personal', verifyToken, async (req, res) => {
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
        
        // Formats the date fields (start_date, end_date) into ISO 8601 strings
        // for consistent parsing by the Flutter client.
        const formattedEvents = events.map(event => ({
            ...event,
            start_date: event.start_date ? new Date(event.start_date).toISOString() : null,
            end_date: event.end_date ? new Date(event.end_date).toISOString() : null,
        }));

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
// 6. START SERVER
// ------------------------------------------------------------------------------
app.listen(PORT, () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
});