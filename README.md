# BitRisk Protocol

> **Institutional-grade risk management for Bitcoin DeFi on Stacks**

BitRisk Protocol is a comprehensive risk management system built on the Stacks blockchain that provides real-time monitoring, analysis, and protection for Bitcoin DeFi positions. By leveraging smart contracts and blockchain technology, BitRisk creates a transparent, automated, and efficient risk management ecosystem for institutional and retail participants in Bitcoin DeFi.

[![Clarity](https://img.shields.io/badge/Clarity-Smart%20Contracts-blue)](https://clarity-lang.org/)
[![Stacks](https://img.shields.io/badge/Built%20on-Stacks-orange)](https://stacks.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🚀 Features

### **Real-Time Risk Monitoring**
- **Cross-Protocol Position Tracking**: Monitor positions across Arkadiko, Alex, Zest, and StackSwap
- **Dynamic Risk Scoring**: Asset-specific risk calculations with volatility and liquidity adjustments
- **Portfolio-Wide Analysis**: Comprehensive risk assessment across multiple positions
- **Automated Health Monitoring**: Real-time portfolio health status with early warning systems

### **Institutional-Grade Risk Management**
- **Liquidation Threshold Monitoring**: Automated alerts when positions approach liquidation
- **Risk Level Categorization**: Clear classification (Low, Medium, High, Critical)
- **Batch Operations**: Efficient bulk position updates for protocol integrations
- **Bitcoin Settlement Integration**: Leverage Stacks' Bitcoin security for risk calculations

## 🏗️ Architecture

BitRisk Protocol consists of two core smart contracts:

### **Risk Engine Contract** (`risk-engine.clar`)
- **Risk Score Calculation**: Advanced algorithms for position risk assessment
- **Asset Risk Parameters**: Configurable parameters for different assets (STX, BTC, etc.)
- **Portfolio Risk Analysis**: Aggregate risk calculations across multiple positions
- **Liquidation Logic**: Automated determination of liquidation requirements

### **Portfolio Tracker Contract** (`portfolio-tracker.clar`)
- **Position Management**: Create, update, and monitor DeFi positions
- **Multi-Protocol Support**: Track positions across major Stacks DeFi protocols
- **Portfolio Health Monitoring**: Real-time health factor calculations
- **Batch Processing**: Efficient bulk operations for protocol integrations

## 🛠️ Installation & Setup

### **Prerequisites**
- [Clarinet CLI](https://github.com/hirosystems/clarinet) installed
- [Node.js](https://nodejs.org/) v16+ (for frontend development)
- [Git](https://git-scm.com/)

### **Clone the Repository**
```bash
git clone https://github.com/aoblessing/bitrisk-protocol.git
cd bitrisk-protocol
```

### **Verify Smart Contracts**
```bash
# Check contract syntax and run tests
clarinet check

# Run contract tests
clarinet test
```

### **Deploy to Testnet**
```bash
# Deploy contracts to Stacks testnet
clarinet deploy --testnet
```

## 📖 Usage Examples

### **Adding a Position**
```clarity
;; Add a new lending position on Arkadiko
(contract-call? .portfolio-tracker add-position 
  "arkadiko" 
  "lending" 
  "STX" 
  "USDA" 
  u1000000 ;; 1000 STX collateral
  u500000  ;; 500 USDA debt
  "Arkadiko vault #123"
)
```

### **Calculate Risk Score**
```clarity
;; Calculate risk for a position
(contract-call? .risk-engine calculate-risk-score 
  'SP1ABC...  ;; user address
  u1          ;; position ID
  u1000000    ;; collateral amount
  u500000     ;; debt amount
  u120000     ;; STX price (in micro-cents)
  u100000000  ;; USDA price (in micro-cents)
  "STX"       ;; collateral asset
)
```

### **Monitor Portfolio Health**
```clarity
;; Get portfolio health status
(contract-call? .portfolio-tracker get-portfolio-health 'SP1ABC...)

;; Returns: { health-factor: u15000, status: "safe", collateral-value: u1200000, debt-value: u500000 }
```

## 🔧 API Reference

### **Risk Engine Functions**

#### **Public Functions**
- `calculate-risk-score`: Calculate and store risk score for a position
- `update-asset-risk-params`: Update risk parameters for an asset (admin only)
- `update-risk-settings`: Update global risk settings (admin only)

#### **Read-Only Functions**
- `get-risk-score`: Retrieve stored risk score for a position
- `needs-liquidation`: Check if position requires liquidation
- `get-asset-risk-params`: Get risk parameters for an asset
- `calculate-portfolio-risk`: Calculate portfolio-wide risk score

### **Portfolio Tracker Functions**

#### **Public Functions**
- `add-position`: Create a new position
- `update-position`: Update existing position data
- `close-position`: Deactivate a position
- `update-portfolio-summary`: Update portfolio value summary
- `batch-update-positions`: Bulk update multiple positions

#### **Read-Only Functions**
- `get-position`: Retrieve position details
- `get-portfolio-health`: Get portfolio health status
- `get-user-position-count`: Get number of positions for a user
- `get-protocol-positions`: Get positions by protocol

## 🎯 Roadmap

### **Phase 1: Foundation** ✅
- [x] Core smart contracts development
- [x] Basic risk calculation engine
- [x] Portfolio position tracking
- [x] Testnet deployment

### **Phase 2: Integration** (In Progress)
- [ ] Frontend dashboard development
- [ ] Price oracle integration
- [ ] Protocol adapter development
- [ ] Real-time monitoring system

### **Phase 3: Advanced Features**
- [ ] Machine learning risk models
- [ ] Cross-chain position tracking
- [ ] Automated liquidation protection
- [ ] Institutional API development

## 🔐 Security

BitRisk Protocol takes security seriously. Our smart contracts have been:

- **Thoroughly tested** with comprehensive unit tests
- **Designed with fail-safes** to prevent catastrophic failures
- **Built using Clarity** for enhanced security and predictability

### **Audit Status**
- [ ] Internal security review (Completed)
- [ ] External security audit (Planned)
- [ ] Bug bounty program (Planned)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🌟 Why BitRisk Protocol?

### **For Individual Users**
- **Peace of Mind**: Automated monitoring of your DeFi positions
- **Early Warnings**: Get alerted before liquidation risks materialize
- **Portfolio Overview**: Comprehensive view of your Bitcoin DeFi exposure

### **For Institutions**
- **Risk Compliance**: Meet institutional risk management requirements
- **Automated Reporting**: Generate risk reports for stakeholders
- **Portfolio Scale**: Manage risk across large, complex portfolios

### **For Protocols**
- **Integration Ready**: Easy-to-integrate risk assessment APIs
- **Enhanced Security**: Provide better risk information to users
- **Competitive Advantage**: Offer superior risk management tools

## 📞 Support & Community

- **Documentation**: [docs.bitrisk.xyz](https://docs.bitrisk.xyz) (Coming Soon)
- **Discord**: [Join our community](https://discord.gg/bitrisk) (Coming Soon)
- **Twitter**: [@BitRiskProtocol](https://twitter.com/bitriskprotocol) (Coming Soon)
- **Email**: hello@bitrisk.xyz

## 🏆 Acknowledgments

- **Stacks Foundation** for the amazing blockchain infrastructure
- **Code for STX Program** for supporting Bitcoin builders
- **Clarity Community** for the excellent developer resources
- **Bitcoin DeFi Protocols** for building the ecosystem we're helping secure

---

**Built with ❤️ for the Bitcoin DeFi ecosystem on Stacks**

*BitRisk Protocol is committed to making Bitcoin DeFi safer, more transparent, and more accessible for everyone.*