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
    const message = isBot ? 'Suspicious bot traffic detected' : 'Hello';
    
    res.render('index', { 
        message,
        isBot,
        title: 'Bot Trapper Demo'
    });
});

app.get('/bot-demo-1-info', (req, res) => {
    res.render('bot-demo-1-info', {
        title: 'Bot Demo 1 Description'
    });
});

app.get('/bot-demo-1', (req, res) => {
    res.render('bot-demo-1', {
        title: 'Bot Demo 1',
        message: 'hello non-bot'
    });
});

app.get('/bot-demo-2-info', (req, res) => {
    res.render('bot-demo-2-info', {
        title: 'Bot Demo 2 Description'
    });
});

app.get('/bot-demo-2', (req, res) => {
    const isBot = isBotRequest(req);
    
    // Query comments based on bot status
    let query = 'SELECT * FROM tbl_comments WHERE silent_discard = 0 ORDER BY created_at DESC';
    if (isBot) {
        query = 'SELECT * FROM tbl_comments ORDER BY created_at DESC';
    }
    
    db.all(query, [], (err, rows) => {
        if (err) {
            console.error(err);
            return res.status(500).send('Database error');
        }
        
        res.render('bot-demo-2', {
            title: 'Bot Demo 2',
            comments: rows,
            isBot
        });
    });
});

app.get('/bot-demo-3-info', (req, res) => {
    res.render('bot-demo-3-info', {
        title: 'Bot Demo 3 Description'
    });
});

app.get('/bot-demo-3', (req, res) => {
    const isBot = isBotRequest(req);
    
    // Generate fake flight data
    const flights = [
        {
            id: 1,
            route: 'New York → London',
            airline: 'SkyWings',
            departure: '10:30 AM',
            arrival: '10:30 PM',
            duration: '7h 0m',
            price: isBot ? 1299 : 899,
            originalPrice: 1299,
            discount: isBot ? 0 : 31,
            available: true,
            botPrice: isBot ? 1299 : null
        },
        {
            id: 2,
            route: 'Los Angeles → Tokyo',
            airline: 'PacificAir',
            departure: '2:15 PM',
            arrival: '5:30 PM (next day)',
            duration: '11h 15m',
            price: isBot ? 1899 : 1299,
            originalPrice: 1899,
            discount: isBot ? 0 : 32,
            available: true,
            botPrice: isBot ? 1899 : null
        },
        {
            id: 3,
            route: 'Chicago → Paris',
            airline: 'EuroConnect',
            departure: '8:45 PM',
            arrival: '11:20 AM (next day)',
            duration: '8h 35m',
            price: isBot ? 1499 : 1099,
            originalPrice: 1499,
            discount: isBot ? 0 : 27,
            available: true,
            botPrice: isBot ? 1499 : null
        },
        {
            id: 4,
            route: 'Miami → Barcelona',
            airline: 'Mediterranean Air',
            departure: '11:20 AM',
            arrival: '5:45 AM (next day)',
            duration: '9h 25m',
            price: isBot ? 1699 : 1199,
            originalPrice: 1699,
            discount: isBot ? 0 : 29,
            available: true,
            botPrice: isBot ? 1699 : null
        },
        {
            id: 5,
            route: 'Seattle → Sydney',
            airline: 'Pacific Rim',
            departure: '10:00 PM',
            arrival: '6:30 AM (2 days later)',
            duration: '16h 30m',
            price: isBot ? 2499 : 1899,
            originalPrice: 2499,
            discount: isBot ? 0 : 24,
            available: true,
            botPrice: isBot ? 2499 : null
        },
        {
            id: 6,
            route: 'Boston → Rome',
            airline: 'Italian Wings',
            departure: '6:30 PM',
            arrival: '9:15 AM (next day)',
            duration: '8h 45m',
            price: isBot ? 1599 : 1199,
            originalPrice: 1599,
            discount: isBot ? 0 : 25,
            available: true,
            botPrice: isBot ? 1599 : null
        }
    ];
    
    res.render('bot-demo-3', {
        title: 'Bot Demo 3: Flight Pricing',
        flights: flights,
        isBot
    });
});

app.post('/bot-demo-2', (req, res) => {
    const { commenter, details } = req.body;
    const isBot = isBotRequest(req);
    const silentDiscard = isBot ? 1 : 0;
    
    if (!commenter || !details) {
        return res.status(400).send('Commenter and details are required');
    }
    
    db.run(
        'INSERT INTO tbl_comments (commenter, details, silent_discard) VALUES (?, ?, ?)',
        [commenter, details, silentDiscard],
        function(err) {
            if (err) {
                console.error('Database error:', err);
                return res.status(500).send('Database error');
            }
            
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

// Serve favicon.ico
app.get('/favicon.ico', (req, res) => {
    res.status(204).end(); // No content response
});

// 404 handler
app.use((req, res) => {
    res.status(404).render('404', {
        title: 'Page Not Found'
    });
});

// Error handler
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).render('error', {
        title: 'Server Error',
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
