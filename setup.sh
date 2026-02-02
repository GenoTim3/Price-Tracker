#!/bin/bash

# Price Tracker - Project Setup Script
# Run: chmod +x setup.sh && ./setup.sh

PROJECT_NAME="price-tracker"

echo "🚀 Setting up $PROJECT_NAME..."

# Create project directory
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# Create mock_server.py
cat > mock_server.py << 'EOF'
from flask import Flask
import random

app = Flask(__name__)

PRODUCTS = {
    "1": {"name": "Wireless Headphones", "base_price": 149.99},
    "2": {"name": "Mechanical Keyboard", "base_price": 89.99},
    "3": {"name": "USB-C Monitor", "base_price": 299.99},
}

@app.route("/product/<product_id>")
def product_page(product_id):
    if product_id not in PRODUCTS:
        return "Product not found", 404
    
    product = PRODUCTS[product_id]
    price = product["base_price"] * random.uniform(0.8, 1.1)
    price = round(price, 2)
    
    return f"""
    <html>
    <head><title>{product["name"]}</title></head>
    <body>
        <h1 class="product-title">{product["name"]}</h1>
        <div class="price-box">
            <span class="current-price" data-price="{price}">${price}</span>
        </div>
        <p class="stock-status">In Stock</p>
    </body>
    </html>
    """

if __name__ == "__main__":
    app.run(port=5000, debug=True)
EOF

# Create scraper.py
cat > scraper.py << 'EOF'
import requests
from bs4 import BeautifulSoup
import sqlite3
from datetime import datetime

DB_NAME = "prices.db"

def init_db():
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute("""
        CREATE TABLE IF NOT EXISTS products (
            id TEXT PRIMARY KEY,
            name TEXT,
            url TEXT,
            target_price REAL
        )
    """)
    c.execute("""
        CREATE TABLE IF NOT EXISTS price_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id TEXT,
            price REAL,
            timestamp TEXT,
            FOREIGN KEY (product_id) REFERENCES products(id)
        )
    """)
    conn.commit()
    conn.close()

def add_product(product_id, name, url, target_price):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute(
        "INSERT OR REPLACE INTO products VALUES (?, ?, ?, ?)",
        (product_id, name, url, target_price)
    )
    conn.commit()
    conn.close()

def scrape_price(url):
    resp = requests.get(url)
    resp.raise_for_status()
    soup = BeautifulSoup(resp.text, "html.parser")
    price_el = soup.select_one(".current-price")
    if not price_el:
        raise ValueError("Could not find price element")
    price_str = price_el.get("data-price") or price_el.text
    return float(price_str.replace("$", ""))

def save_price(product_id, price):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute(
        "INSERT INTO price_history (product_id, price, timestamp) VALUES (?, ?, ?)",
        (product_id, price, datetime.now().isoformat())
    )
    conn.commit()
    conn.close()

def check_price(product_id):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute("SELECT name, url, target_price FROM products WHERE id = ?", (product_id,))
    row = c.fetchone()
    conn.close()
    
    if not row:
        print(f"Product {product_id} not found")
        return
    
    name, url, target = row
    price = scrape_price(url)
    save_price(product_id, price)
    
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {name}: ${price:.2f} (target: ${target:.2f})")
    
    if price <= target:
        send_alert(name, price, target)

def send_alert(name, price, target):
    print(f"🚨 ALERT: {name} dropped to ${price:.2f} (target was ${target:.2f})")
EOF

# Create main.py
cat > main.py << 'EOF'
import time
from scraper import init_db, add_product, check_price

def main():
    init_db()
    
    add_product("1", "Wireless Headphones", "http://localhost:5000/product/1", 130.00)
    add_product("2", "Mechanical Keyboard", "http://localhost:5000/product/2", 75.00)
    
    print("Starting price tracker... (Ctrl+C to stop)\n")
    
    while True:
        check_price("1")
        check_price("2")
        print("-" * 40)
        time.sleep(10)

if __name__ == "__main__":
    main()
EOF

# Create requirements.txt
cat > requirements.txt << 'EOF'
flask
requests
beautifulsoup4
EOF

# Create README
cat > README.md << 'EOF'
# Price Tracker

A web scraper that monitors product prices and alerts you when they drop.

## Setup

```bash
pip install -r requirements.txt
```

## Usage

1. Start the mock server:
```bash
python mock_server.py
```

2. In a new terminal, run the tracker:
```bash
python main.py
```

## Project Structure

- `mock_server.py` - Fake product pages with randomized prices
- `scraper.py` - Core scraping and database logic
- `main.py` - Entry point that runs the tracking loop
- `prices.db` - SQLite database (created on first run)
EOF

echo ""
echo "✅ Project created in ./$PROJECT_NAME"
echo ""
echo "Next steps:"
echo "  cd $PROJECT_NAME"
echo "  pip install -r requirements.txt"
echo "  python mock_server.py  (in one terminal)"
echo "  python main.py         (in another terminal)"