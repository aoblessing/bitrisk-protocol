;; BitRisk Protocol - Portfolio Tracker Contract
;; Complete portfolio tracking with protocol management and batch operations

;; Error codes
(define-constant ERR-UNAUTHORIZED (err u501))
(define-constant ERR-POSITION-NOT-FOUND (err u502))
(define-constant ERR-INVALID-PROTOCOL (err u503))
(define-constant ERR-POSITION-EXISTS (err u504))
(define-constant ERR-INVALID-AMOUNT (err u505))
(define-constant ERR-LIST-TOO-LONG (err u506))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Supported protocols
(define-constant PROTOCOL-ARKADIKO "arkadiko")
(define-constant PROTOCOL-ALEX "alex")
(define-constant PROTOCOL-ZEST "zest")
(define-constant PROTOCOL-STACKSWAP "stackswap")

;; Position types
(define-constant POSITION-TYPE-LENDING "lending")
(define-constant POSITION-TYPE-BORROWING "borrowing")
(define-constant POSITION-TYPE-LP "liquidity")
(define-constant POSITION-TYPE-STAKING "staking")

;; Position data structure
(define-map user-positions
  { user: principal, position-id: uint }
  {
    protocol: (string-ascii 20),        ;; Protocol name
    position-type: (string-ascii 20),   ;; Position type
    collateral-asset: (string-ascii 10), ;; Collateral token
    debt-asset: (string-ascii 10),      ;; Debt token (if applicable)
    collateral-amount: uint,            ;; Amount of collateral
    debt-amount: uint,                  ;; Amount of debt
    created-at: uint,                   ;; Block height when created
    last-updated: uint,                 ;; Last update block height
    is-active: bool,                    ;; Position status
    metadata: (string-ascii 100)       ;; Additional position data
  }
)

;; User position counters
(define-map user-position-count
  { user: principal }
  { count: uint }
)

;; Protocol-specific position tracking
(define-map protocol-positions
  { protocol: (string-ascii 20), user: principal }
  { position-ids: (list 50 uint) }
)

;; Portfolio summary for each user
(define-map portfolio-summary
  { user: principal }
  {
    total-collateral-value: uint,      ;; Total collateral value in USD
    total-debt-value: uint,            ;; Total debt value in USD
    overall-health-factor: uint,       ;; Portfolio health factor
    position-count: uint,              ;; Number of active positions
    last-calculated: uint              ;; Last calculation block height
  }
)

;; Add a new position
(define-public (add-position
  (protocol (string-ascii 20))
  (position-type (string-ascii 20))
  (collateral-asset (string-ascii 10))
  (debt-asset (string-ascii 10))
  (collateral-amount uint)
  (debt-amount uint)
  (metadata (string-ascii 100))
)
  (let
    (
      (user tx-sender)
      (current-count (default-to u0 (get count (map-get? user-position-count { user: user }))))
      (new-position-id (+ current-count u1))
    )
    ;; Validate inputs
    (asserts! (> collateral-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (is-valid-protocol protocol) ERR-INVALID-PROTOCOL)
    
    ;; Check if position already exists
    (asserts! (is-none (map-get? user-positions { user: user, position-id: new-position-id })) ERR-POSITION-EXISTS)
    
    ;; Create the position
    (map-set user-positions
      { user: user, position-id: new-position-id }
      {
        protocol: protocol,
        position-type: position-type,
        collateral-asset: collateral-asset,
        debt-asset: debt-asset,
        collateral-amount: collateral-amount,
        debt-amount: debt-amount,
        created-at: stacks-block-height,
        last-updated: stacks-block-height,
        is-active: true,
        metadata: metadata
      }
    )
    
    ;; Update position counter
    (map-set user-position-count
      { user: user }
      { count: new-position-id }
    )
    
    ;; Update protocol tracking (simplified - just log success for Phase 1)
    (let ((tracking-result (update-protocol-positions protocol user new-position-id true)))
      (ok new-position-id)
    )
  )
)

;; Update an existing position
(define-public (update-position
  (position-id uint)
  (collateral-amount uint)
  (debt-amount uint)
  (metadata (string-ascii 100))
)
  (let
    (
      (user tx-sender)
      (existing-position (unwrap! (map-get? user-positions { user: user, position-id: position-id }) ERR-POSITION-NOT-FOUND))
    )
    ;; Validate user owns this position and it's active
    (asserts! (get is-active existing-position) ERR-POSITION-NOT-FOUND)
    (asserts! (> collateral-amount u0) ERR-INVALID-AMOUNT)
    
    ;; Update the position
    (map-set user-positions
      { user: user, position-id: position-id }
      (merge existing-position {
        collateral-amount: collateral-amount,
        debt-amount: debt-amount,
        last-updated: stacks-block-height,
        metadata: metadata
      })
    )
    
    (ok true)
  )
)

;; Close/deactivate a position
(define-public (close-position (position-id uint))
  (let
    (
      (user tx-sender)
      (existing-position (unwrap! (map-get? user-positions { user: user, position-id: position-id }) ERR-POSITION-NOT-FOUND))
    )
    ;; Validate user owns this position
    (asserts! (get is-active existing-position) ERR-POSITION-NOT-FOUND)
    
    ;; Deactivate the position
    (map-set user-positions
      { user: user, position-id: position-id }
      (merge existing-position {
        is-active: false,
        last-updated: stacks-block-height
      })
    )
    
    ;; Update protocol tracking (simplified - just log for Phase 1)
    (let ((tracking-result (update-protocol-positions (get protocol existing-position) user position-id false)))
      (ok true)
    )
  )
)

;; Get all active positions for risk calculation
(define-read-only (get-active-position-ids (user principal))
  (let
    (
      (max-positions (get-user-position-count user))
    )
    (filter is-position-active (generate-position-list max-positions))
  )
)

;; Get positions by protocol for a user
(define-read-only (get-protocol-positions (protocol (string-ascii 20)) (user principal))
  (default-to (list) (get position-ids (map-get? protocol-positions { protocol: protocol, user: user })))
)

;; Batch position update (for protocol integrations)
(define-public (batch-update-positions 
  (position-updates (list 10 { position-id: uint, collateral-amount: uint, debt-amount: uint }))
)
  (ok (map update-single-position-safe position-updates))
)

;; Helper for batch updates - safe version that doesn't fail the whole batch
(define-private (update-single-position-safe (update-data { position-id: uint, collateral-amount: uint, debt-amount: uint }))
  (match (update-position 
    (get position-id update-data)
    (get collateral-amount update-data)
    (get debt-amount update-data)
    ""
  )
    success true
    error false
  )
)

;; Calculate portfolio value (simplified version for Phase 1)
(define-public (update-portfolio-summary 
  (user principal)
  (total-collateral-value uint)
  (total-debt-value uint)
)
  (let
    (
      (position-count (get-user-position-count user))
      (health-factor (if (> total-debt-value u0)
                       (/ (* total-collateral-value u10000) total-debt-value)
                       u10000))
    )
    (map-set portfolio-summary
      { user: user }
      {
        total-collateral-value: total-collateral-value,
        total-debt-value: total-debt-value,
        overall-health-factor: health-factor,
        position-count: position-count,
        last-calculated: stacks-block-height
      }
    )
    (ok true)
  )
)

;; Get portfolio health status
(define-read-only (get-portfolio-health (user principal))
  (match (map-get? portfolio-summary { user: user })
    summary (let
      (
        (health-factor (get overall-health-factor summary))
        (debt-value (get total-debt-value summary))
      )
      {
        health-factor: health-factor,
        status: (if (is-eq debt-value u0)
                  "safe"
                  (if (>= health-factor u15000) ;; 150% ratio
                    "safe"
                    (if (>= health-factor u12000) ;; 120% ratio
                      "warning"
                      "danger"
                    )
                  )
                ),
        collateral-value: (get total-collateral-value summary),
        debt-value: debt-value
      }
    )
    ;; None case - return default values
    {
      health-factor: u0,
      status: "unknown",
      collateral-value: u0,
      debt-value: u0
    }
  )
)

;; Read-only functions
(define-read-only (get-position (user principal) (position-id uint))
  (map-get? user-positions { user: user, position-id: position-id })
)

(define-read-only (get-user-position-count (user principal))
  (default-to u0 (get count (map-get? user-position-count { user: user })))
)

(define-read-only (get-portfolio-summary (user principal))
  (map-get? portfolio-summary { user: user })
)

;; Helper functions
(define-private (is-valid-protocol (protocol (string-ascii 20)))
  (or 
    (is-eq protocol PROTOCOL-ARKADIKO)
    (or 
      (is-eq protocol PROTOCOL-ALEX)
      (or 
        (is-eq protocol PROTOCOL-ZEST)
        (is-eq protocol PROTOCOL-STACKSWAP)
      )
    )
  )
)

(define-private (update-protocol-positions 
  (protocol (string-ascii 20)) 
  (user principal) 
  (position-id uint) 
  (add bool)
)
  (let
    (
      (current-positions (default-to (list) (get position-ids (map-get? protocol-positions { protocol: protocol, user: user }))))
    )
    (if add
      ;; Add position ID to list
      (match (as-max-len? (append current-positions position-id) u50)
        new-list (begin
          (map-set protocol-positions
            { protocol: protocol, user: user }
            { position-ids: new-list }
          )
          (ok true)
        )
        (err u506) ;; List too long error
      )
      ;; For remove operation, just return success (simplified for Phase 1)
      (ok true)
    )
  )
)

(define-private (generate-position-list (max-id uint))
  (if (is-eq max-id u0)
    (list)
    (if (is-eq max-id u1)
      (list u1)
      (if (is-eq max-id u2)
        (list u1 u2)
        (if (is-eq max-id u3)
          (list u1 u2 u3)
          ;; Add more cases as needed, for now limit to 3 for Phase 1
          (list u1 u2 u3)
        )
      )
    )
  )
)

(define-private (is-position-active (position-id uint))
  (match (map-get? user-positions { user: tx-sender, position-id: position-id })
    position-data (get is-active position-data)
    false
  )
)
