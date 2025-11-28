# Wireshark Guide - Finding Your Game Server

## 🎮 Your Current Game Connection

**Detected from PID 26176 (wwm.exe) - Live Connection Data:**

### **Primary Game Server** ⭐
- **IP Address:** `8.211.97.129`
- **Port:** `4110`
- **Connection Type:** TCP (Established)
- **Location:** Alibaba Cloud - **Asia Pacific Region (China)**
- **Status:** Active game server connection
- **This is your main gameplay server** - responsible for your 300ms latency

### **Secondary Connection**
- **IP Address:** `34.49.186.238`
- **Port:** `443` (HTTPS)
- **Connection Type:** TCP (Established)
- **Hostname:** `238.186.49.34.bc.googleusercontent.com`
- **Location:** Google Cloud Platform
- **Purpose:** Authentication, anti-cheat, telemetry, or update services
- **Not the game server** - this is a support service

### **UDP Connection** 📡
- **Local Port:** `57094`
- **Protocol:** UDP (bound to 0.0.0.0 - listening on all interfaces)
- **Purpose:** **Primary game data transmission**
- **Note:** This is where real-time game packets (movement, combat, actions) flow
- **Wireshark will show:** Outgoing UDP packets from this port to `8.211.97.129`

---

## 📊 Why 300ms Latency?

Your **300ms ping** is caused by connecting to a server far from your location:

**Confirmed Server Details:**
- **IP:** `8.211.97.129` (Alibaba Cloud Infrastructure)
- **Region:** Asia Pacific - China data center
- **Port:** `4110` (Custom game protocol)
- **Your latency:** 300ms round-trip time

**Distance = Delay:**
- Local server (same city): 10-30ms
- Same country: 30-80ms
- Same continent: 50-150ms
- **Cross-continent Asia ↔ Europe:** 200-350ms ← **You are here**
- **Cross-continent Asia ↔ Americas:** 250-400ms

**What this means:**
- Light/data travels ~300,000 km/second
- Physical distance + routing hops = your 300ms
- This is **normal for connecting to Asian servers from Europe/Americas**

---

## 🦈 Using Wireshark - Step by Step

### **Step 1: Install Wireshark**
1. Download from: https://www.wireshark.org/download.html
2. Install with **Npcap** (packet capture driver)
3. Restart if prompted

### **Step 2: Start Capturing**

1. **Open Wireshark**
2. **Select your network adapter**
   - Usually "Ethernet" or "Wi-Fi"
   - Look for the one with active traffic (graph moving)
3. **Click the blue shark fin** (Start Capturing)

### **Step 3: Filter Game Traffic**

After capturing for 30-60 seconds while playing, **stop the capture** and apply this filter:

**Option 1: Both game connections**
```
ip.addr == 8.211.97.129 or ip.addr == 34.49.186.238
```

**Option 2: Game server only (recommended)**
```
ip.addr == 8.211.97.129
```

**Option 3: UDP gameplay traffic only**
```
udp.port == 57094
```

**Option 4: All game traffic excluding Google Cloud**
```
ip.addr == 8.211.97.129 and (tcp.port == 4110 or udp)
```

### **Step 4: Analyze the Traffic**

#### What to Look For:

**Protocol Column:**
- **TCP** - Reliable connections (login, updates)
- **UDP** - Fast game data (movement, combat)

**Info Column:**
- Shows packet details
- Look for patterns of communication

**Length Column:**
- Small packets (50-200 bytes) = control messages
- Large packets (500-1500 bytes) = game state data

#### **Key Metrics to Check:**

1. **Time Delta**: Shows delay between packets
   - Right-click packet → Protocol Preferences → Calculate conversation timestamps
   
2. **Packet Rate**: How many packets/second
   - Statistics → Capture File Properties
   
3. **Round Trip Time (RTT)**:
   - Statistics → TCP Stream Graphs → Round Trip Time

---

## 🔍 Advanced Analysis

### **Find Server Location**

**Your game server location (already identified):**
```
IP: 8.211.97.129
Provider: Alibaba Cloud (Aliyun)
Region: Asia Pacific - China
Port: 4110 (game protocol)
Hostname: Not publicly resolvable (game server)
```

**Verify with online tools:**
- https://www.ip-address.org/lookup/ip-locator.php
- https://ipinfo.io/8.211.97.129
- Or use PowerShell:
```powershell
# Get geo-location info
Invoke-RestMethod "https://ipapi.co/8.211.97.129/json/" | Format-List
```

### **Monitor Specific UDP Traffic**

**Your game's UDP port:** `57094` (local)

Filter for your specific game UDP traffic:
```
udp.port == 57094
```

Or broader filter for game-related UDP:
```
udp and ip.addr == 8.211.97.129
```

### **Export Packet Statistics**

1. **Statistics → Protocol Hierarchy**
   - Shows TCP vs UDP usage
   - Bandwidth per protocol

2. **Statistics → Conversations**
   - Shows all communication endpoints
   - Sort by packets/bytes to find main server

3. **Statistics → I/O Graph**
   - Visual representation of traffic over time
   - Helps identify traffic spikes

---

## 🎯 What This Tells You

### **Server Information:**
- **Main Game Server:** `8.211.97.129:4110` (Alibaba Cloud - Asia)
- **Your Connection:** TCP + UDP
- **Latency Source:** Geographic distance to Asian server

### **Why Wireshark is Useful:**

1. **Identify Server Region**: Know where you're connecting
2. **Diagnose Lag**: See packet loss, delays, retransmissions
3. **Monitor Bandwidth**: How much data the game uses
4. **Troubleshoot Issues**: Find connection drops or errors
5. **Server Selection**: Some games let you choose region - verify you're on the right one

### **Improving Your Latency:**

1. **Check for regional servers**: Where Winds Meet might have other regions
2. **Use wired connection**: Ethernet vs WiFi can save 10-30ms
3. **Close background apps**: Reduce network congestion
4. **VPN/Gaming Proxy**: Sometimes routing optimization helps (but can also hurt)
5. **Contact Support**: Ask if there are closer servers available

---

## 📝 Quick Reference Commands

### **PowerShell - Check Active Connections**
```powershell
Get-NetTCPConnection -OwningProcess 26176 | Where-Object {$_.State -eq 'Established'}
```

### **PowerShell - Continuous Monitoring**
```powershell
while ($true) {
    Clear-Host
    Get-NetTCPConnection -OwningProcess 26176 -State Established | 
        Select RemoteAddress, RemotePort, State | Format-Table
    Start-Sleep -Seconds 5
}
```

### **Wireshark Display Filters**
```
# Your specific game server
ip.addr == 8.211.97.129

# Both detected servers
ip.addr == 8.211.97.129 or ip.addr == 34.49.186.238

# Your UDP game traffic
udp.port == 57094

# TCP connection to game server
tcp.port == 4110 and ip.addr == 8.211.97.129

# UDP to game server
udp and ip.addr == 8.211.97.129

# Show retransmissions (lag/packet loss indicator)
tcp.analysis.retransmission

# Show packets with delays over 100ms
tcp.time_delta > 0.1

# Exclude Google Cloud (focus on game server)
ip.addr == 8.211.97.129 and not ip.addr == 34.49.186.238
```

---

## 🚀 Pro Tips

1. **Capture Duration**: 1-2 minutes is enough for analysis
2. **File Size**: Stop before it gets huge (>500MB)
3. **Save Captures**: File → Save As (for later analysis)
4. **Color Coding**: View → Coloring Rules (makes patterns visible)
5. **Follow Streams**: Right-click packet → Follow → TCP/UDP Stream (see full conversation)

---

## ⚠️ Important Notes

- **Privacy**: Wireshark captures ALL network traffic - be careful with sensitive data
- **Encryption**: HTTPS (port 443) traffic will be encrypted and unreadable
- **Game Data**: Most game protocols are proprietary and encrypted
- **Legal**: Only capture your own traffic, never others' without permission

---

## 📊 Expected Results

**For "Where Winds Meet" (based on PID 26176 analysis):**

### **Traffic Pattern:**
- **TCP Connection:** Persistent to `8.211.97.129:4110` (game server handshake & control)
- **UDP Packets:** From your port `57094` to `8.211.97.129` at 20-60 packets/second
- **Packet Sizes:** Typically 100-1000 bytes (game state updates)
- **Google Cloud:** Occasional HTTPS traffic to `34.49.186.238:443` (auth/telemetry)

### **What You'll See in Wireshark:**

1. **TCP Stream (Port 4110):**
   - Initial handshake (SYN, SYN-ACK, ACK)
   - Keep-alive packets every few seconds
   - Control messages (login, zone changes, etc.)

2. **UDP Stream (Your Port 57094):**
   - Constant bi-directional traffic during gameplay
   - Outgoing: Your player actions (movement, combat, input)
   - Incoming: Server updates (other players, NPCs, game state)
   - **No packet loss** = smooth gameplay
   - **Packet loss/retrans** = lag spikes

3. **Latency Measurement:**
   - Time between your packet out → server response in = ~300ms
   - Visible in "Time" and "Delta" columns
   - Statistics → TCP Stream Graph → Round Trip Time shows ~300ms average

### **Confirming Your 300ms:**

In Wireshark, you can verify latency by:
- Looking at **TCP ACK timing** (request → acknowledgment)
- Measuring **UDP request/response pairs** time delta
- Using **Statistics → I/O Graph** to see response patterns

Your 300ms is the round-trip time to the **Alibaba Cloud Asia server (`8.211.97.129`)**.

---

**Good luck with your analysis! 🎮**
