;; BitRisk Protocol - Risk Engine Contract (v3.0)
;; Enhanced risk calculation with position tracking integration

;; Error codes
(define-constant ERR-UNAUTHORIZED (err u401))
(define-constant ERR-POSITION-NOT-FOUND (err u403))
(define-constant ERR-INVALID-PRICE (err u404))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Risk levels (basis points: 10000 = 100%)
(define-constant RISK-LEVEL-LOW u500)      ;; 5%
(define-constant RISK-LEVEL-MEDIUM u1500)  ;; 15%
(define-constant RISK-LEVEL-HIGH u3000)    ;; 30%
(define-constant RISK-LEVEL-CRITICAL u5000) ;; 50%

;; Risk score data structure
(define-map risk-scores
  { user: principal, position-id: uint }
  {
    risk-score: uint,           ;; Risk score in basis points
    collateral-ratio: uint,     ;; Current collateral ratio
    liquidation-threshold: uint, ;; Liquidation threshold
    last-updated: uint,         ;; Block height of last update
    risk-level: (string-ascii 10) ;; "low", "medium", "high", "critical"
  }
)

;; Risk parameters for different assets
(define-map asset-risk-params
  { asset: (string-ascii 10) }
  {
    volatility-factor: uint,    ;; Volatility multiplier
    liquidity-factor: uint,     ;; Liquidity adjustment
    correlation-factor: uint,   ;; Correlation with BTC
    max-ltv: uint              ;; Maximum loan-to-value ratio
  }
)

;; Global risk settings
(define-data-var liquidation-bonus uint u500) ;; 5% liquidation bonus
(define-data-var max-risk-score uint u9000)   ;; 90% max risk before forced liquidation

;; Initialize default asset parameters
(map-set asset-risk-params 
  { asset: "STX" }
  {
    volatility-factor: u1200,  ;; 12% volatility factor
    liquidity-factor: u800,    ;; 8% liquidity discount
    correlation-factor: u700,  ;; 70% correlation with BTC
    max-ltv: u7000            ;; 70% max LTV
  }
)

(map-set asset-risk-params 
  { asset: "BTC" }
  {
    volatility-factor: u1000,  ;; 10% volatility factor
    liquidity-factor: u100,    ;; 1% liquidity discount
    correlation-factor: u10000, ;; 100% correlation with BTC
    max-ltv: u8000            ;; 80% max LTV
  }
)

;; Calculate and store risk score for a position
(define-public (calculate-risk-score 
  (user principal) 
  (position-id uint)
  (collateral-amount uint)
  (debt-amount uint)
  (collateral-price uint)
  (debt-price uint)
  (asset (string-ascii 10))
)
  (let
    (
      (asset-params (unwrap! (map-get? asset-risk-params { asset: asset }) ERR-INVALID-PRICE))
      (collateral-value (* collateral-amount collateral-price))
      (debt-value (* debt-amount debt-price))
      (current-ratio (if (> debt-value u0) 
                       (/ (* collateral-value u10000) debt-value) 
                       u10000))
      (base-risk (if (> current-ratio u0)
                   (/ (* debt-value u10000) collateral-value)
                   u0))
      (volatility-adjustment (/ (* base-risk (get volatility-factor asset-params)) u1000))
      (liquidity-adjustment (/ (* base-risk (get liquidity-factor asset-params)) u1000))
      (final-risk-score (+ base-risk volatility-adjustment liquidity-adjustment))
      (risk-level (determine-risk-level final-risk-score))
    )
    ;; Store the calculated risk score
    (map-set risk-scores
      { user: user, position-id: position-id }
      {
        risk-score: final-risk-score,
        collateral-ratio: current-ratio,
        liquidation-threshold: (get max-ltv asset-params),
        last-updated: stacks-block-height,
        risk-level: risk-level
      }
    )
    (ok final-risk-score)
  )
)

;; Determine risk level based on score
(define-private (determine-risk-level (risk-score uint))
  (if (<= risk-score RISK-LEVEL-LOW)
    "low"
    (if (<= risk-score RISK-LEVEL-MEDIUM)
      "medium"
      (if (<= risk-score RISK-LEVEL-HIGH)
        "high"
        "critical"
      )
    )
  )
)

;; Get risk score for a position
(define-read-only (get-risk-score (user principal) (position-id uint))
  (map-get? risk-scores { user: user, position-id: position-id })
)

;; Check if position needs liquidation
(define-read-only (needs-liquidation (user principal) (position-id uint))
  (match (map-get? risk-scores { user: user, position-id: position-id })
    risk-data (>= (get risk-score risk-data) (var-get max-risk-score))
    false
  )
)

;; Get asset risk parameters
(define-read-only (get-asset-risk-params (asset (string-ascii 10)))
  (map-get? asset-risk-params { asset: asset })
)

;; Update asset risk parameters (admin only)
(define-public (update-asset-risk-params 
  (asset (string-ascii 10))
  (volatility-factor uint)
  (liquidity-factor uint)
  (correlation-factor uint)
  (max-ltv uint)
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (map-set asset-risk-params
      { asset: asset }
      {
        volatility-factor: volatility-factor,
        liquidity-factor: liquidity-factor,
        correlation-factor: correlation-factor,
        max-ltv: max-ltv
      }
    )
    (ok true)
  )
)

;; Get current risk settings
(define-read-only (get-risk-settings)
  {
    liquidation-bonus: (var-get liquidation-bonus),
    max-risk-score: (var-get max-risk-score)
  }
)
