# Mini Tick Platform – KDB+/Q Simulation Framework

This project simulates a simplified market data tick platform built in **KDB+/Q**. It includes components for generating tick-level price data, broadcasting via a tick plant, subscribing clients, and computing basic real-time analytics.

---

## 🧱 Project Components

| File         | Description |
|--------------|-------------|
| `tick.q`     | Core **Tick Plant** engine that receives and distributes simulated tick data. Optionally logs a connection table to track subscriber metadata (e.g., connection status, timestamps). |
| `feed.q`     | **Price generator** simulating GBM (Geometric Brownian Motion) stock price streams based on user-defined initial price and volatility. Publishes tick data to the tick plant. |
| `newsub.q`   | Mock **subscriber module** that connects to the tick plant and receives tick updates. Can be used to simulate random or generic data consumers. |
| `RTE.q`      | Real-time **analytics engine** computing:  
  - OHLC aggregation  
  - Parkinson intra-day volatility estimator  
  - Total variation over time 
    
 `r.q`, `u.q`, `sym.q`  Supporting utility libraries and configuration files (e.g., symbol management, reusable functions, or routing logic). |

---

## 🔁 Workflow Overview

1. **Start the tick plant**  
   Launch `tick.q` to initialize the messaging and optional subscriber logging framework.

2. **Simulate price feed**  
   Use `feed.q` to stream synthetic GBM price ticks to the platform. Configure price and volatility as desired.

3. **Attach subscribers**  
   Run `newsub.q` to connect simulated clients. Can be extended to represent different strategies or latency profiles.

4. **Run analytics**  
   `RTE.q` consumes tick data and performs intraday calculations for market structure monitoring or signal extraction.

---

## ⚙️ Technical Highlights

- GBM-driven simulation for realistic tick paths
- Real-time calculation of volatility and OHLC
- Modular architecture to plug in additional subscribers or analytics
- Optional tracking of connected clients

---

## 🚀 Getting Started

1. Ensure `tick.q` is running as the central plant
2. Start `feed.q` with user-defined parameters for symbol, price, and vol
3. Launch one or more `newsub.q` processes to simulate consumers
4. Run `RTE.q` to process analytics in parallel

---

## 🧠 Contact

**Paul C. Jin**  
📧 [lestat.jin@gmail.com](mailto:lestat.jin@gmail.com)  
🔗 [www.linkedin.com/in/pjin](https://www.linkedin.com/in/pjin)
