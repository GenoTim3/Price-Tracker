# Price Tracker

A web scraper that monitors product prices and alerts you when they drop.

Remember to have 2 terminals open for use

Still needs work to fully complete itself, needs some file maintenance as well

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
