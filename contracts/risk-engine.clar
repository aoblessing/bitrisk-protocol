;; BitRisk Protocol - Risk Engine Contract
;; Enhanced risk calculation with asset-specific parameters

;; Error codes
(define-constant ERR-UNAUTHORIZED (err u401))
(define-constant ERR-INVALID-PRICE (err u404))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Risk parameters for different assets
(define-map asset-risk-params
  { asset: (string-ascii 10) }
  {
    volatility-factor: uint,    ;; Volatility multiplier
    liquidity-factor: uint,     ;; Liquidity adjustment
    max-ltv: uint              ;; Maximum loan-to-value ratio
  }
)

;; Initialize default asset parameters
(map-set asset-risk-params 
  { asset: "STX" }
  {
    volatility-factor: u1200,  ;; 12% volatility factor
    liquidity-factor: u800,    ;; 8% liquidity discount
    max-ltv: u7000            ;; 70% max LTV
  }
)

(map-set asset-risk-params 
  { asset: "BTC" }
  {
    volatility-factor: u1000,  ;; 10% volatility factor
    liquidity-factor: u100,    ;; 1% liquidity discount
    max-ltv: u8000            ;; 80% max LTV
  }
)

;; Enhanced risk score calculation with asset parameters
(define-public (calculate-risk-score 
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
      (base-risk (if (> collateral-value u0)
                   (/ (* debt-value u10000) collateral-value)
                   u0))
      (volatility-adjustment (/ (* base-risk (get volatility-factor asset-params)) u1000))
      (liquidity-adjustment (/ (* base-risk (get liquidity-factor asset-params)) u1000))
      (final-risk-score (+ base-risk volatility-adjustment liquidity-adjustment))
    )
    (asserts! (> collateral-price u0) ERR-INVALID-PRICE)
    (asserts! (> debt-price u0) ERR-INVALID-PRICE)
    (ok final-risk-score)
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
  (max-ltv uint)
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (map-set asset-risk-params
      { asset: asset }
      {
        volatility-factor: volatility-factor,
        liquidity-factor: liquidity-factor,
        max-ltv: max-ltv
      }
    )
    (ok true)
  )
)

;; Check if position exceeds max LTV
(define-read-only (exceeds-max-ltv 
  (collateral-amount uint)
  (debt-amount uint)
  (collateral-price uint)
  (debt-price uint)
  (asset (string-ascii 10))
)
  (match (map-get? asset-risk-params { asset: asset })
    asset-params (let
      (
        (collateral-value (* collateral-amount collateral-price))
        (debt-value (* debt-amount debt-price))
        (current-ltv (if (> collateral-value u0)
                       (/ (* debt-value u10000) collateral-value)
                       u0))
      )
      (> current-ltv (get max-ltv asset-params))
    )
    false
  )
)
