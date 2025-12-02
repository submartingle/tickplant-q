# Mini Tick Data System – KDB+/Q Simulation Framework

This project simulates a simplified market data tick platform built in **KDB+/Q**. It is based on KDB+ tick architecture by KX Systems with modified features, including components for generating tick-level price data, broadcasting via a tick plant, subscribing clients, and computing basic real-time analytics with comprehensive performance instrumentation.

---

## 🧱 Project Components

| File         | Description |
|--------------|-------------|
| `tick.q`     | Core **Tick Plant** engine that receives and distributes simulated tick data via asynchronous IPC. Logs to disk every 2 seconds and purges in-memory buffer to minimize latency overhead. Optionally tracks subscriber metadata (e.g., connection status, timestamps). |
| `feed.q`     | **Price generator** simulating GBM (Geometric Brownian Motion) stock price streams based on user-defined initial price and volatility. Publishes tick data to the tick plant using async messaging (`neg[h]`). |
| `r.q`        | **Real-Time Database (RDB)** that subscribes to the tick plant and stores incoming tick data in memory. Includes performance monitoring for latency and throughput measurement. |
| `newsub.q`   | **Secondary RDB/subscriber** module that connects to the tick plant and receives tick updates. Can be used to simulate additional data consumers or alternative storage strategies. |
| `RTE.q`      | Real-time **analytics engine** computing:  OHLC aggregation / Parkinson intra-day volatility estimator / Total variation over time |
| `u.q`, `sym.q` | Supporting utility libraries and configuration files (e.g., symbol management, reusable functions, or routing logic). |

---

## 📊 Performance Analysis
### Test Environment

**OS & Software:**
- KDB+ v4.1
- KDB-X (community version)
- Linux Mint

**Hardware:**
- Intel© Core™ i5-8250U CPU @ 1.60GHz × 4, 8G memory, SSD drive
- Development machine, localhost IPC
  
  
### Latency Measurement

The system includes instrumentation to measure end-to-end latency across each hop in the data pipeline. Timestamps are captured at the Feed Handler (FH), Tickerplant (TP), and subscriber endpoints (RDB/RTE).

**Test Configuration:**
- Timer interval: 1-100ms (tested various scenarios, note Windows can only go as high as up to 16ms due to 64Hz limit although there might be ways to circumvent)
- Batch size: 5,000 rows per message
- Message delivery: Asynchronous IPC (tick mode)
- TP log frequency: 2-second intervals (minimizes latency impact)
- Environment: Development hardware, localhost IPC

**Latency Results (microseconds):**

| Component | Route | p50 | p95 | p99 | max | min | avg |
|-----------|-------|-----|-----|-----|-----|-----|-----|
| **RDB** | FH→RDB | 477μs | 1.1ms | 1.5ms | 2.7ms | 348μs | 573μs |
| | TP→RDB | 306μs | 667μs | 937μs | 2.5ms | 207μs | 356μs |
| **RTE** | FH→RTE | 645μs | 1.4ms | 1.9ms | 2.5ms | 484μs | 762μs |
| | TP→RTE | 424μs | 866μs | 1.2ms | 1.6ms | 300μs | 493μs |

**Key Findings:**
- Sub-millisecond median latency (p50) across all paths
- RTE analytics add ~168μs overhead vs baseline RDB insert (645μs vs 477μs)
- Stable performance with p95/p50 ratio of ~2.3x, indicating consistent behavior
- Both FH→TP and TP→Subscriber hops contribute roughly equal latency (~300-450μs each)
- TP log writes occur asynchronously every 2 seconds, preventing disk I/O from blocking message relay

**View Latency Statistics:**
```q
q).latency.report[]  // Display latency percentiles by route
```



### Throughput Measurement

Real-time throughput monitoring tracks message ingestion rate and memory footprint at each subscriber. Throughput tracking is **enabled by default** and can be disabled before starting the data feed.

**Throughput Tracking Features:**
- Instantaneous rows/sec calculation (configurable reporting interval)
- Live memory usage monitoring via `.Q.w[]`
- Per-process resource tracking (RDB/RTE)

**Sample Output:**
```q
Throughput: 10050 rows/sec
Memory used: 660.8833 MB  
Throughput: 10000 rows/sec
Memory used: 660.8833 MB  
Throughput: 10050 rows/sec
Memory used: 660.8833 MB  
Throughput: 10000 rows/sec
Memory used: 660.8833 MB
```

**Throughput Control:**
```q
.stats.throughput:1b  // Enable throughput monitoring (default)
.stats.throughput:0b  // Disable before starting feed to eliminate overhead
```

**Typical Performance:**
- Sustained throughput: 6,000-10,000 rows/sec per subscriber
- Memory growth: ~40MB per 1M rows in RDB
- Stable operation: 1-2 minutes continuous load without degradation

---

## 🔄 Workflow Overview

1. **Start the tick plant**  
   Launch `tick.q` to initialize the messaging and optional subscriber logging framework. TP logs to disk every 2 seconds and purges buffer to maintain low latency.
```bash
   q tick.q sym . -p 5010
```

2. **Start the Real-Time Database (RDB)**  
   Launch `r.q` to subscribe to the tick plant and store incoming data in memory.
```bash
   q tick/r.q :5010 -p 5011
```
   
   Optional: Disable throughput monitoring before data starts flowing:
```q
   q).stats.throughput:0b  // Run this in RDB console before starting feed
```

3. **Start additional subscribers (optional)**  
   - **Secondary RDB**: 
```bash
     q newsub.q
```
   - **Real-Time Engine (RTE)** for analytics:
```bash
     q RTE.q :5010
```

4. **Simulate price feed**  
   Use `feed.q` to stream synthetic GBM price ticks to the platform. Configure price, volatility, and timer interval as desired.
```bash
   q feed.q
```

5. **Monitor performance**  
   Use `.latency.report[]` in any subscriber (RDB/RTE) to analyze system latency in real-time. Throughput metrics are displayed automatically when enabled.
```q
   q).latency.report[]  // View latency statistics by route
```

---

## ⚙️ Technical Highlights

- **Asynchronous IPC**: All message passing uses `neg[h]` for non-blocking, low-latency communication
- **Optimized TP logging**: 2-second batch writes with memory purge to prevent disk I/O from impacting message relay latency
- **GBM-driven simulation**: Realistic price paths with configurable drift and volatility
- **Real-time analytics**: OHLC, Parkinson volatility, and total variation calculations
- **Performance instrumentation**: Comprehensive latency and throughput tracking with toggleable overhead
- **Modular architecture**: Easy to plug in additional subscribers or analytics modules
- **Tick mode relay**: Immediate message forwarding (no batching at TP) for true latency measurement

---

## 🚀 Getting Started

**Quick Start Commands:**
```bash
# Terminal 1: Start Tickerplant
q tick.q sym . -p 5010

# Terminal 2: Start RDB
q tick/r.q :5010 -p 5011

# Terminal 3: Start RTE (optional)
q RTE.q :5010

# Terminal 4: Start secondary RDB (optional)
q newsub.q

# Terminal 5: Start Feed Handler
q feed.q
```

**Configuration Options:**

Disable throughput monitoring in subscribers (before starting feed):
```q
q).stats.throughput:0b
```

View latency statistics:
```q
q).latency.report[]
```

---

## 📈 Performance Optimization Notes

**Latency Optimization:**
- Async IPC reduced end-to-end latency by ~53% vs synchronous messaging
- Tick mode (immediate relay) eliminates batching delays at TP
- Enable latency sampling (1-10%) to minimize monitoring overhead
- TP log writes every 2 seconds (vs per-message) prevent disk I/O blocking
- Localhost IPC achieves sub-millisecond p50 latencies
- for max throughput set timer to 1ms (kdb timer limit), although this means higher latency at the same time

**Production Considerations:**
- Performance benchmarks conducted on both KDB+ v4.1 and KDB-X on Linux
- For sustained 24/7 operation, implement periodic HDB writes (every 30-60 minutes) at RDB/RTE
- Disable throughput monitoring (`.stats.throughput:0b`) in production if metrics collection not required
- Typical production systems on optimized Linux achieve 200-600μs latencies
- Memory-bound performance: Without HDB writes, expect gradual latency degradation after 10M+ rows

---

## 🧠 Contact

**Paul C. Jin**  
📧 [lestat.jin@gmail.com](mailto:lestat.jin@gmail.com)  
🔗 [www.linkedin.com/in/pjin](https://www.linkedin.com/in/pjin)
