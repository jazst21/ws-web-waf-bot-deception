const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const bodyParser = require('body-parser');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(express.static('public'));
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Add request logging middleware
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
    if (req.method === 'POST') {
        console.log('POST Body:', req.body);
        console.log('POST Headers:', req.headers);
    }
    next();
});

// EJS layout middleware
app.use((req, res, next) => {
    const originalRender = res.render;
    res.render = function(view, options = {}) {
        if (view === 'layout') {
            return originalRender.call(this, view, options);
        }
        
        // Render the view first
        this.app.render(view, options, (err, html) => {
            if (err) return next(err);
            
            // Then render with layout
            const layoutOptions = {
                ...options,
                body: html
            };
            originalRender.call(this, 'layout', layoutOptions);
        });
    };
    next();
});

// Initialize SQLite database
const db = new sqlite3.Database('./comments.db');

// Create comments table if it doesn't exist
db.serialize(() => {
    db.run(`CREATE TABLE IF NOT EXISTS tbl_comments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        commenter TEXT NOT NULL,
        details TEXT NOT NULL,
        silent_discard BOOLEAN DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);
});

// Helper function to check if request is from bot
function isBotRequest(req) {
    return req.headers['x-amzn-waf-targeted-bot-detected'] === 'true';
}

// Routes
app.get('/', (req, res) => {
    const isBot = isBotRequest(req);
    const message = isBot ? '봇으로 의심되는 트래픽입니다' : '안녕하세요';
    
    res.render('index', { 
        message,
        isBot,
        title: 'Bot Trapper Demo'
    });
});

app.get('/bot-demo-1-info', (req, res) => {
    res.render('bot-demo-1-info', {
        title: '봇 데모 1 설명'
    });
});

app.get('/bot-demo-1', (req, res) => {
    res.render('bot-demo-1', {
        title: '봇 데모 1',
        message: 'hello non-bot'
    });
});

app.get('/bot-demo-2-info', (req, res) => {
    res.render('bot-demo-2-info', {
        title: '봇 데모 2 설명'
    });
});

app.get('/bot-demo-2', (req, res) => {
    console.log('GET /bot-demo-2 received');
    const isBot = isBotRequest(req);
    
    // Query comments based on bot status
    let query = 'SELECT * FROM tbl_comments WHERE silent_discard = 0 ORDER BY created_at DESC';
    if (isBot) {
        query = 'SELECT * FROM tbl_comments ORDER BY created_at DESC';
    }
    
    console.log('Executing query:', query);
    db.all(query, [], (err, rows) => {
        if (err) {
            console.error('Database query error:', err);
            return res.status(500).send('Database error');
        }
        
        console.log('Query result:', rows);
        res.render('bot-demo-2', {
            title: '봇 데모 2',
            comments: rows,
            isBot
        });
    });
});

app.post('/bot-demo-2', (req, res) => {
    console.log('=== POST /bot-demo-2 received ===');
    console.log('Request body:', req.body);
    console.log('Request headers:', req.headers);
    
    const { commenter, details } = req.body;
    const isBot = isBotRequest(req);
    const silentDiscard = isBot ? 1 : 0;
    
    console.log('Parsed data:', { commenter, details, isBot, silentDiscard });
    
    if (!commenter || !details) {
        console.log('Validation failed: missing commenter or details');
        return res.status(400).send('Commenter and details are required');
    }
    
    console.log('Inserting into database...');
    db.run(
        'INSERT INTO tbl_comments (commenter, details, silent_discard) VALUES (?, ?, ?)',
        [commenter, details, silentDiscard],
        function(err) {
            if (err) {
                console.error('Database error:', err);
                return res.status(500).send('Database error');
            }
            
            console.log('Comment inserted successfully, ID:', this.lastID);
            console.log('Redirecting to /bot-demo-2');
            // Redirect back to the same page to show updated comments
            res.redirect('/bot-demo-2');
        }
    );
});

app.get('/aws-edge-services', (req, res) => {
    res.render('aws-edge-services', {
        title: 'AWS Edge Services'
    });
});

// Serve robots.txt
app.get('/robots.txt', (req, res) => {
    res.type('text/plain');
    res.send(`User-agent: *
Disallow: /private/*
Allow: /

Sitemap: https://demo.wadafa.xyz/sitemap.xml`);
});

// 404 handler
app.use((req, res) => {
    res.status(404).render('404', {
        title: '페이지를 찾을 수 없습니다'
    });
});

// Error handler
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).render('error', {
        title: '서버 오류',
        error: err.message
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`Bot Trapper Demo server running on port ${PORT}`);
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('Shutting down server...');
    db.close((err) => {
        if (err) {
            console.error(err.message);
        }
        console.log('Database connection closed.');
        process.exit(0);
    });
});
