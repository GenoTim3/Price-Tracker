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
