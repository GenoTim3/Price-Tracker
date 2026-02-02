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
