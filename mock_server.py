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
